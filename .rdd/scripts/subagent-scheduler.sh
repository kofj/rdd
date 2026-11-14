#!/bin/bash
#
# RDD Subagent Scheduler
# Orchestrates parallel/sequential execution of stages in worktrees.
#
# Usage: subagent-scheduler.sh <command> [args]
#
# Commands:
#   execute <stage_id> <worktree_path>    - Queue rdd-stage-auto for the active host
#   parallel <stage_ids>                  - Queue requests for multiple stages
#   sequential <stage_ids>                - Queue the first stage; host must verify before requesting the next
#   status                                - Show scheduler status
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
RDD_DIR="${RDD_DIR:-${PROJECT_ROOT}/.rdd}"
SCHEDULER_STATE="${RDD_DIR}/cache/scheduler-state.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[SCHEDULER]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[SCHEDULER]${NC} $*"; }
log_error() { echo -e "${RED}[SCHEDULER]${NC} $*"; }

get_timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ==========================================
# Execute a single stage in its worktree
# ==========================================

execute_stage() {
  local stage_id="$1"
  [[ "$stage_id" =~ ^[0-9]+$ ]] || {
    log_error "Numeric stage id required"
    return 2
  }
  local worktree_path="$2"

  log_info "Scheduling Stage ${stage_id} in ${worktree_path}..."

  if [ ! -d "$worktree_path" ]; then
    log_error "Worktree not found: ${worktree_path}"
    return 1
  fi

  # Execute rdd-stage-auto in the worktree
  # The active Claude Code or Codex host must consume this pending request.
  # For script-based execution, we write a trigger file
  mkdir -p "${worktree_path}/.rdd"
  local trigger_file="${worktree_path}/.rdd/trigger-stage-${stage_id}"
  cat >"$trigger_file" <<EOF
# RDD Subagent Trigger
# Stage: ${stage_id}
# Worktree: ${worktree_path}
# Generated: $(get_timestamp)
#
# Status: pending (not executed)
# Execute with the active host: rdd-stage-auto ${stage_id}
# Then: merge back to main
EOF

  log_info "Stage ${stage_id} trigger written: ${trigger_file}"
  echo "trigger:${trigger_file}"
}

# ==========================================
# Parallel execution plan
# ==========================================

parallel_execute() {
  local stage_ids="$*"

  log_info "Parallel execution plan for stages: ${stage_ids}"

  for stage_id in $stage_ids; do
    # Allocate worktree
    local wt_path
    if ! wt_path=$(bash "${RDD_DIR}/scripts/worktree-pool.sh" allocate "$stage_id"); then
      log_error "Failed to allocate worktree for Stage ${stage_id}"
      continue
    fi

    # Queue requests serially; the host owns actual parallel execution
    execute_stage "$stage_id" "$wt_path"
    log_info "Stage ${stage_id} request pending; host execution required"
  done

  log_info "Parallel requests queued; execution pending"
}

# ==========================================
# Sequential execution plan
# ==========================================

sequential_execute() {
  local stage_ids="$*"

  for stage_id in $stage_ids; do
    log_info "Sequential: Stage ${stage_id}"

    # Allocate worktree
    local wt_path
    if ! wt_path=$(bash "${RDD_DIR}/scripts/worktree-pool.sh" allocate "$stage_id"); then
      log_error "Failed to allocate worktree for Stage ${stage_id}"
      return 1
    fi

    # Execute (foreground)
    execute_stage "$stage_id" "$wt_path"

    # Only the first request is queued. The host must verify completion
    # before requesting the next stage; never release a pending worktree.
    log_info "Stage ${stage_id} pending; continue in the active host"
    return 0
  done

  log_info "No sequential requests queued"
}

# ==========================================
# Status
# ==========================================

status() {
  echo "Subagent Scheduler Status"
  echo "=========================="
  echo ""

  bash "${RDD_DIR}/scripts/worktree-pool.sh" list 2>/dev/null || echo "  Worktree pool unavailable"

  if [ -f "$SCHEDULER_STATE" ]; then
    echo ""
    echo "Scheduler State:"
    cat "$SCHEDULER_STATE"
  fi
}

# ==========================================
# Usage
# ==========================================

show_usage() {
  cat <<'EOF'
RDD Subagent Scheduler

Usage: subagent-scheduler.sh <command> [args]

Commands:
  execute <stage_id> <worktree_path>     Trigger stage execution in worktree
  parallel <stage_id1> <stage_id2> ...   Queue pending stage requests
  sequential <stage_id1> <stage_id2> ... Queue the first stage; host must verify before requesting the next
  status                                 Show scheduler status

EOF
}

# ==========================================
# Main
# ==========================================

main() {
  if [ $# -lt 1 ]; then
    show_usage
    exit 1
  fi

  local cmd="$1"
  shift
  case "$cmd" in
    execute) execute_stage "$@" ;;
    parallel) parallel_execute "$@" ;;
    sequential) sequential_execute "$@" ;;
    status) status ;;
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
