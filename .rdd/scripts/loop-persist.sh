#!/bin/bash
#
# RDD Loop Persistence Script
# Fine-grained atomic persistence for multi-stage loop execution.
#
# Extends checkpoint.sh with loop-specific state tracking:
#   - loop-state.yaml: canonical source of truth for loop execution
#   - checkpoints.json: backward compat for single-stage operations
#
# Usage: loop-persist.sh <command> [args]
#
# Commands:
#   gate-enter <stage_id> <gate>         - Persist gate entry
#   gate-exit <stage_id> <gate> <result> - Persist gate completion
#   decision <id> <title> ...            - Write ADR immediately
#   debt <id> <title> <priority> ...     - Write tech debt immediately
#   test-result <results_json>           - Persist test results
#   heartbeat                             - Full snapshot save
#   init <total_stages>                   - Initialize loop state
#   stage-start <stage_id> <name>        - Mark stage as in-progress
#   stage-complete <stage_id>            - Mark stage as complete
#   stage-fail <stage_id> <reason>       - Mark stage as failed
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LOOP_STATE_FILE="${RDD_DIR}/cache/loop-state.yaml"
ADR_FILE="${RDD_DIR}/../docs/08-autonomous-decisions.md"
DEBT_FILE="${RDD_DIR}/../docs/12-technical-debt.md"
HEARTBEAT_DIR="${RDD_DIR}/cache/heartbeat"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
get_readable_ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_info() { echo -e "${GREEN}[LOOP]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[LOOP]${NC} $*"; }
log_error() { echo -e "${RED}[LOOP]${NC} $*"; }

# Atomic write: write to .tmp then mv (prevents corruption on crash)
atomic_write() {
  local file="$1" content="$2" tmp="${file}.tmp"
  echo "$content" >"$tmp" && mv "$tmp" "$file"
}

# Atomic append with fsync
atomic_append() {
  local file="$1" entry="$2"
  printf "%s\n" "$entry" >>"$file"
}

# ==========================================
# Initialize loop state
# ==========================================

init_loop_state() {
  local total_stages="${1:-0}" session_id ts
  session_id="loop-$(date +%Y%m%d-%H%M%S)"
  ts=$(get_timestamp)
  local readable_ts
  readable_ts=$(get_readable_ts)

  mkdir -p "$(dirname "$LOOP_STATE_FILE")"
  mkdir -p "$HEARTBEAT_DIR"

  cat >"$LOOP_STATE_FILE" <<EOF
# RDD Loop State — canonical source for multi-stage execution
# Generated: ${readable_ts}
version: "1.0"
session_id: "${session_id}"
started_at: "${ts}"
target: "auto"
status: "running"
total_stages: ${total_stages}
completed_count: 0
failed_count: 0
last_checkpoint: "${ts}"
stages: []
test_results: {}
recovery_count: 0
EOF
  log_info "Loop state initialized: ${session_id}"
  echo "$session_id"
}

# ==========================================
# Stage tracking
# ==========================================

stage_start() {
  local stage_id="$1" stage_name="$2" ts
  ts=$(get_timestamp)

  if yq eval ".stages[] | select(.id == ${stage_id})" "$LOOP_STATE_FILE" >/dev/null 2>&1; then
    # Update existing
    yq -i ".stages[] |= select(.id == ${stage_id}).status = \"in_progress\"" "$LOOP_STATE_FILE"
    yq -i ".stages[] |= select(.id == ${stage_id}).started_at = \"${ts}\"" "$LOOP_STATE_FILE"
  else
    # Add new
    yq -i ".stages += [{\"id\": ${stage_id}, \"name\": \"${stage_name}\", \"status\": \"in_progress\", \"started_at\": \"${ts}\", \"gates\": [\"pending\",\"pending\",\"pending\",\"pending\",\"pending\"]}]" "$LOOP_STATE_FILE"
  fi
  persist_timestamp
  log_info "Stage ${stage_id} started: ${stage_name}"
}

stage_complete() {
  local stage_id="$1" ts
  ts=$(get_timestamp)

  yq -i ".stages[] |= select(.id == ${stage_id}).status = \"complete\"" "$LOOP_STATE_FILE"
  yq -i ".stages[] |= select(.id == ${stage_id}).completed_at = \"${ts}\"" "$LOOP_STATE_FILE"
  yq -i ".completed_count = (.completed_count + 1)" "$LOOP_STATE_FILE"
  persist_timestamp
  log_info "Stage ${stage_id} complete"
}

stage_fail() {
  local stage_id="$1" reason="${2:-unknown}" ts
  ts=$(get_timestamp)

  yq -i ".stages[] |= select(.id == ${stage_id}).status = \"failed\"" "$LOOP_STATE_FILE"
  yq -i ".stages[] |= select(.id == ${stage_id}).failure_reason = \"${reason}\"" "$LOOP_STATE_FILE"
  yq -i ".failed_count = (.failed_count + 1)" "$LOOP_STATE_FILE"
  persist_timestamp
  log_error "Stage ${stage_id} failed: ${reason}"
}

# ==========================================
# Gate tracking
# ==========================================

gate_enter() {
  local stage_id="$1" gate="${2//[^0-9]/}" # strip non-numeric
  local gate_idx=$((gate - 1))             # 0-indexed

  yq -i ".stages[] |= select(.id == ${stage_id}).current_gate = ${gate}" "$LOOP_STATE_FILE"
  yq -i ".stages[] |= select(.id == ${stage_id}).gates[${gate_idx}] = \"in_progress\"" "$LOOP_STATE_FILE"
  persist_timestamp
  log_info "Stage ${stage_id} Gate ${gate}: in_progress"

  # Also update traditional checkpoint for backward compat
  if [ -f "${RDD_DIR}/scripts/checkpoint.sh" ]; then
    bash "${RDD_DIR}/scripts/checkpoint.sh" gate "$gate" "in_progress" || true
  fi
}

gate_exit() {
  local stage_id="$1" gate="${2//[^0-9]/}" result="${3:-completed}"
  local gate_idx=$((gate - 1))

  yq -i ".stages[] |= select(.id == ${stage_id}).gates[${gate_idx}] = \"${result}\"" "$LOOP_STATE_FILE"
  persist_timestamp
  log_info "Stage ${stage_id} Gate ${gate}: ${result}"

  # Backward compat
  if [ -f "${RDD_DIR}/scripts/checkpoint.sh" ]; then
    bash "${RDD_DIR}/scripts/checkpoint.sh" gate "$gate" "$result" || true
  fi
}

# ==========================================
# ADR: written immediately on decision
# ==========================================

write_adr() {
  local id="$1" title="$2" background="$3" decision="$4" \
    rationale="$5" impact="$6" stage="$7"

  local entry="
### Decision ${id}: ${title}

**Background**: ${background}

**Decision**: ${decision}

**Rationale**: ${rationale}

**Impact on Subsequent Stages**: ${impact}

**Date**: $(date +%Y-%m-%d)
**Related Stage**: Stage ${stage}
"
  atomic_append "$ADR_FILE" "$entry"
  log_info "ADR ${id} recorded: ${title}"
}

# ==========================================
# Tech debt: written immediately on discovery
# ==========================================

write_debt() {
  local id="$1" title="$2" priority="$3" stage="$4" \
    description="$5" source_file="$6" source_line="$7" suggested_stage="$8"

  local entry="
### TD-${id}: ${title}

- **Priority**: ${priority}
- **Source**: Stage ${stage} (Stage 22: Multi-stage)
- **Original Description**: \"${description}\"
- **Source File**: ${source_file}:${source_line}
- **Suggested Stage**: Stage ${suggested_stage}
"
  atomic_append "$DEBT_FILE" "$entry"
  log_warn "Tech debt TD-${id} recorded: ${title}"
}

# ==========================================
# Test result persistence
# ==========================================

test_result() {
  local results="$1" # JSON string with test outcomes
  yq -i ".last_test_results = ${results}" "$LOOP_STATE_FILE"
  persist_timestamp
  log_info "Test results saved"
}

# ==========================================
# Heartbeat: full snapshot every 5 minutes
# ==========================================

heartbeat() {
  mkdir -p "$HEARTBEAT_DIR"
  local ts
  ts=$(date -u +"%Y%m%d-%H%M%S")
  cp "$LOOP_STATE_FILE" "${HEARTBEAT_DIR}/${ts}.yaml"
  persist_timestamp
  # Keep only last 20 heartbeats
  ls -t "${HEARTBEAT_DIR}/" 2>/dev/null | tail -n +21 | while read -r f; do
    rm -f "${HEARTBEAT_DIR}/${f}"
  done
  log_info "Heartbeat: ${ts}"
}

# ==========================================
# Helpers
# ==========================================

persist_timestamp() {
  local ts
  ts=$(get_timestamp)
  yq -i ".last_checkpoint = \"${ts}\"" "$LOOP_STATE_FILE" 2>/dev/null || true
}

show_state() {
  if [ ! -f "$LOOP_STATE_FILE" ]; then
    echo "No loop state found. Run 'loop-persist.sh init <N>' first."
    return 1
  fi
  cat "$LOOP_STATE_FILE"
}

needs_recovery() {
  if [ -f "$LOOP_STATE_FILE" ] && grep -q "in_progress" "$LOOP_STATE_FILE" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# ==========================================
# Main
# ==========================================

show_usage() {
  cat <<'EOF'
RDD Loop Persistence Script

Usage: loop-persist.sh <command> [args]

Commands:
  init <total_stages>                    Initialize loop state
  stage-start <id> <name>                Mark stage in_progress
  stage-complete <id>                    Mark stage complete
  stage-fail <id> <reason>               Mark stage failed
  gate-enter <id> <gate>                 Persist gate entry
  gate-exit <id> <gate> [result]         Persist gate completion
  decision <id> <title> <bg> <dec> <rat> <impact> <stage>
                                         Write ADR immediately
  debt <id> <title> <pri> <stage> <desc> <file> <line> <sug-stage>
                                         Write tech debt immediately
  test-result <json>                     Persist test results
  heartbeat                              Full snapshot
  show                                   Display loop state
  needs-recovery                         Check if recovery needed (true/false)

EOF
}

main() {
  if [ $# -lt 1 ]; then
    show_usage
    exit 1
  fi

  local cmd="$1"
  shift
  case "$cmd" in
    init) init_loop_state "$@" ;;
    stage-start) stage_start "$@" ;;
    stage-complete) stage_complete "$@" ;;
    stage-fail) stage_fail "$@" ;;
    gate-enter) gate_enter "$@" ;;
    gate-exit) gate_exit "$@" ;;
    decision) write_adr "$@" ;;
    debt) write_debt "$@" ;;
    test-result) test_result "$@" ;;
    heartbeat) heartbeat ;;
    show) show_state ;;
    needs-recovery) needs_recovery ;;
    -h | --help | help) show_usage ;;
    *)
      log_error "Unknown command: $cmd"
      show_usage
      exit 1
      ;;
  esac
}

if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
  main "$@"
fi
