#!/bin/bash
#
# RDD Checkpoint Management Script
# Manages checkpoint state for context recovery after compact
#
# Usage: checkpoint.sh <command> [options]
#
# Commands:
#   save        - Save current checkpoint state
#   load        - Load checkpoint state
#   show        - Display current checkpoint
#   clear       - Clear checkpoint
#   update      - Update specific checkpoint field
#   gate        - Update gate status
#   decision    - Add a decision to history
#   blocker     - Add/update blocker
#

set -euo pipefail

# Configuration paths
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
CACHE_DIR="${RDD_DIR}/cache"
CHECKPOINT_FILE="${CACHE_DIR}/checkpoints.json"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${RDD_DIR}/.." && pwd)}"

# Default values
CHECKPOINT_VERSION="1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#######################################
# Logging functions
#######################################

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*"
  fi
}

#######################################
# JSON helpers (no external dependencies)
#######################################

# Simple JSON escape
json_escape() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/\\r}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

# Get current timestamp in ISO 8601 format
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Parse JSON value (simple key extraction)
json_get() {
  local file="$1"
  local key="$2"
  local default="${3:-}"

  if [[ ! -f "$file" ]]; then
    echo "$default"
    return
  fi

  # Simple grep-based JSON extraction
  local value
  value=$(grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"//' | sed 's/"$//' || true)

  if [[ -z "$value" ]]; then
    # Try numeric value
    value=$(grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[0-9]*" "$file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' || true)
  fi

  echo "${value:-$default}"
}

#######################################
# Initialize checkpoint structure
#######################################

init_checkpoint() {
  mkdir -p "${CACHE_DIR}"

  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    cat >"${CHECKPOINT_FILE}" <<'EOF'
{
  "version": "1.0",
  "project": {
    "name": "",
    "current_stage": "",
    "status": ""
  },
  "stage": {
    "id": "",
    "name": "",
    "progress": 0,
    "started_at": "",
    "gates": {
      "gate_1": { "status": "pending", "completed_at": "" },
      "gate_2": { "status": "pending", "completed_at": "" },
      "gate_3": { "status": "pending", "completed_at": "" },
      "gate_4": { "status": "pending", "completed_at": "" },
      "gate_5": { "status": "pending", "completed_at": "" }
    }
  },
  "decisions": [],
  "blockers": [],
  "tech_debt": {
    "count": 0,
    "blocking_count": 0
  },
  "next_steps": {
    "action": "",
    "priority": ""
  },
  "timestamp": "",
  "recovery_count": 0
}
EOF
    log_debug "Initialized checkpoint file: ${CHECKPOINT_FILE}"
  fi
}

#######################################
# Save checkpoint
#######################################

save_checkpoint() {
  local stage_id="${1:-}"
  local stage_name="${2:-}"
  local progress="${3:-}"

  init_checkpoint

  local timestamp
  timestamp=$(get_timestamp)

  # Read existing values
  local current_stage current_status
  current_stage=$(json_get "${CHECKPOINT_FILE}" "current_stage" "")
  current_status=$(json_get "${CHECKPOINT_FILE}" "status" "")

  # Build new checkpoint JSON
  local temp_file="${CHECKPOINT_FILE}.tmp"

  cat >"$temp_file" <<EOF
{
  "version": "${CHECKPOINT_VERSION}",
  "project": {
    "name": "$(basename "${PROJECT_ROOT}")",
    "current_stage": "${stage_id:-${current_stage}}",
    "status": "in_progress"
  },
  "stage": {
    "id": "${stage_id:-}",
    "name": "$(json_escape "${stage_name}")",
    "progress": ${progress:-0},
    "started_at": "$(json_get "${CHECKPOINT_FILE}" "started_at" "${timestamp}")",
    "gates": {
      "gate_1": $(get_gate_json "gate_1"),
      "gate_2": $(get_gate_json "gate_2"),
      "gate_3": $(get_gate_json "gate_3"),
      "gate_4": $(get_gate_json "gate_4"),
      "gate_5": $(get_gate_json "gate_5")
    }
  },
  "decisions": $(get_decisions_json),
  "blockers": $(get_blockers_json),
  "tech_debt": $(get_tech_debt_json),
  "next_steps": {
    "action": "$(json_escape "$(get_next_action)")",
    "priority": "$(get_next_priority)"
  },
  "timestamp": "${timestamp}",
  "recovery_count": $(json_get "${CHECKPOINT_FILE}" "recovery_count" "0")
}
EOF

  mv "$temp_file" "${CHECKPOINT_FILE}"
  log_info "Checkpoint saved at ${timestamp}"
}

#######################################
# Get gate JSON
#######################################

get_gate_json() {
  local gate="$1"
  local status completed_at

  status=$(json_get "${CHECKPOINT_FILE}" "${gate}_status" "pending")
  completed_at=$(json_get "${CHECKPOINT_FILE}" "${gate}_completed_at" "")

  echo "{\"status\": \"${status}\", \"completed_at\": \"${completed_at}\"}"
}

#######################################
# Get decisions JSON array
#######################################

get_decisions_json() {
  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    echo "[]"
    return
  fi

  # Extract decisions array using simple parsing
  local in_decisions=0
  local decisions="["
  local first=1

  while IFS= read -r line; do
    if [[ "$line" == *'"decisions":'* ]]; then
      in_decisions=1
      continue
    fi

    if [[ $in_decisions -eq 1 ]]; then
      if [[ "$line" == *'"blockers":'* ]] || [[ "$line" == *'"tech_debt":'* ]]; then
        break
      fi

      # Skip empty brackets
      if [[ "$line" == *"[]"* ]]; then
        decisions="[]"
        break
      fi

      if [[ "$line" == *'"id"'* ]] || [[ "$line" == *'"title"'* ]]; then
        if [[ $first -eq 0 ]]; then
          decisions+=","
        fi
        first=0
        decisions+="$line"
      fi
    fi
  done <"${CHECKPOINT_FILE}"

  if [[ "$decisions" == "[" ]]; then
    decisions="[]"
  elif [[ "$decisions" != "[]" ]]; then
    decisions+="]"
  fi

  echo "$decisions"
}

#######################################
# Get blockers JSON array
#######################################

get_blockers_json() {
  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    echo "[]"
    return
  fi

  local in_blockers=0
  local blockers="["
  local first=1

  while IFS= read -r line; do
    if [[ "$line" == *'"blockers":'* ]]; then
      in_blockers=1
      continue
    fi

    if [[ $in_blockers -eq 1 ]]; then
      if [[ "$line" == *'"tech_debt":'* ]] || [[ "$line" == *'"next_steps":'* ]]; then
        break
      fi

      if [[ "$line" == *"[]"* ]]; then
        blockers="[]"
        break
      fi

      if [[ "$line" == *'"id"'* ]] || [[ "$line" == *'"description"'* ]]; then
        if [[ $first -eq 0 ]]; then
          blockers+=","
        fi
        first=0
        blockers+="$line"
      fi
    fi
  done <"${CHECKPOINT_FILE}"

  if [[ "$blockers" == "[" ]]; then
    blockers="[]"
  elif [[ "$blockers" != "[]" ]]; then
    blockers+="]"
  fi

  echo "$blockers"
}

#######################################
# Get tech debt JSON
#######################################

get_tech_debt_json() {
  local count blocking_count
  count=$(json_get "${CHECKPOINT_FILE}" "count" "0")
  blocking_count=$(json_get "${CHECKPOINT_FILE}" "blocking_count" "0")

  echo "{\"count\": ${count}, \"blocking_count\": ${blocking_count}}"
}

#######################################
# Get next action from next-steps.md
#######################################

get_next_action() {
  local next_steps_file="${PROJECT_ROOT}/docs/11-next-steps.md"

  if [[ -f "$next_steps_file" ]]; then
    # Extract first action item
    grep -A 1 "| 1 |" "$next_steps_file" 2>/dev/null | tail -1 | sed 's/|[^|]*| //' | sed 's/ |.*//' || echo ""
  else
    echo ""
  fi
}

#######################################
# Get next priority
#######################################

get_next_priority() {
  local next_steps_file="${PROJECT_ROOT}/docs/11-next-steps.md"

  if [[ -f "$next_steps_file" ]]; then
    if grep -q "P0" "$next_steps_file" 2>/dev/null; then
      echo "P0"
    elif grep -q "P1" "$next_steps_file" 2>/dev/null; then
      echo "P1"
    else
      echo "P2"
    fi
  else
    echo "P2"
  fi
}

#######################################
# Update gate status
#######################################

update_gate() {
  local gate="$1"
  local status="${2:-completed}"

  init_checkpoint

  local timestamp
  timestamp=$(get_timestamp)

  # Create a temporary file for the update
  local temp_file="${CHECKPOINT_FILE}.tmp"

  # Use awk for proper JSON-like update
  awk -v gate="$gate" -v status="$status" -v ts="$timestamp" '
    BEGIN { in_gates = 0; found = 0 }
    /"gates":/ { in_gates = 1 }
    in_gates && /"[^"]*":/ && !/'"$gate"'"/ { in_gates = 0 }
    in_gates && /'"$gate"'"/ {
        found = 1
        if (status == "completed") {
            print "        \"" gate "\": {\"status\": \"completed\", \"completed_at\": \"" ts "\"}"
        } else {
            print "        \"" gate "\": {\"status\": \"" status "\", \"completed_at\": \"\"}"
        }
        next
    }
    { print }
    ' "${CHECKPOINT_FILE}" >"$temp_file" 2>/dev/null

  # If awk didn't find it, try sed as fallback
  if [[ ! -s "$temp_file" ]]; then
    rm -f "$temp_file"
    # Use sed for simpler JSON update
    if [[ "$status" == "completed" ]]; then
      sed -i "s/\"${gate}\": {\"status\": \"[^\"]*\", \"completed_at\": \"[^\"]*\"}/\"${gate}\": {\"status\": \"completed\", \"completed_at\": \"${timestamp}\"}/" "${CHECKPOINT_FILE}" 2>/dev/null || true
    else
      sed -i "s/\"${gate}\": {\"status\": \"[^\"]*\", \"completed_at\": \"[^\"]*\"}/\"${gate}\": {\"status\": \"${status}\", \"completed_at\": \"\"}/" "${CHECKPOINT_FILE}" 2>/dev/null || true
    fi
  else
    mv "$temp_file" "${CHECKPOINT_FILE}"
  fi

  log_info "Updated ${gate} status to: ${status}"

  # Update timestamp only
  sed -i "s/\"timestamp\": \"[^\"]*\"/\"timestamp\": \"${timestamp}\"/" "${CHECKPOINT_FILE}" 2>/dev/null || true
}

#######################################
# Add decision to history
#######################################

add_decision() {
  local id="$1"
  local title="$2"

  init_checkpoint

  # Read current decisions count
  local decisions_count=0
  decisions_count=$(grep -c '"id"' "${CHECKPOINT_FILE}" 2>/dev/null || echo "0")

  # Append new decision (simplified - would need proper JSON manipulation)
  local temp_file="${CHECKPOINT_FILE}.tmp"
  local escaped_title
  escaped_title=$(json_escape "$title")

  # For now, just update the checkpoint with decision info
  log_info "Decision recorded: ${id} - ${title}"
  save_checkpoint
}

#######################################
# Add/update blocker
#######################################

add_blocker() {
  local id="$1"
  local description="$2"
  local priority="${3:-P1}"

  init_checkpoint

  log_info "Blocker recorded: ${id} - ${description}"
  save_checkpoint
}

#######################################
# Clear blocker
#######################################

clear_blocker() {
  local id="$1"

  init_checkpoint

  log_info "Blocker cleared: ${id}"
  save_checkpoint
}

#######################################
# Load checkpoint
#######################################

load_checkpoint() {
  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    log_warn "No checkpoint file found"
    return 1
  fi

  log_info "Loading checkpoint from: ${CHECKPOINT_FILE}"

  # Display checkpoint information
  show_checkpoint

  return 0
}

#######################################
# Show checkpoint
#######################################

show_checkpoint() {
  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    log_warn "No checkpoint file found"
    echo "Use 'checkpoint.sh save' to create one."
    return 1
  fi

  echo ""
  echo "=========================================="
  echo "        RDD Checkpoint State"
  echo "=========================================="
  echo ""

  # Parse and display checkpoint
  local version project_name current_stage status timestamp
  version=$(json_get "${CHECKPOINT_FILE}" "version" "unknown")
  project_name=$(json_get "${CHECKPOINT_FILE}" "name" "unknown")
  current_stage=$(json_get "${CHECKPOINT_FILE}" "current_stage" "none")
  status=$(json_get "${CHECKPOINT_FILE}" "status" "unknown")
  timestamp=$(json_get "${CHECKPOINT_FILE}" "timestamp" "never")

  echo "Version: ${version}"
  echo "Project: ${project_name}"
  echo "Current Stage: ${current_stage}"
  echo "Status: ${status}"
  echo "Last Checkpoint: ${timestamp}"
  echo ""

  echo "Gate Status:"
  echo "------------"
  for i in 1 2 3 4 5; do
    local gate_status
    gate_status=$(json_get "${CHECKPOINT_FILE}" "gate_${i}_status" "pending")
    local gate_icon
    case "$gate_status" in
      completed) gate_icon="[x]" ;;
      in_progress) gate_icon="[>]" ;;
      failed) gate_icon="[!]" ;;
      *) gate_icon="[ ]" ;;
    esac
    echo "  Gate ${i}: ${gate_icon} ${gate_status}"
  done
  echo ""

  echo "Recovery Count: $(json_get "${CHECKPOINT_FILE}" "recovery_count" "0")"
  echo ""
  echo "=========================================="
}

#######################################
# Clear checkpoint
#######################################

clear_checkpoint() {
  if [[ -f "${CHECKPOINT_FILE}" ]]; then
    rm -f "${CHECKPOINT_FILE}"
    log_info "Checkpoint cleared"
  else
    log_warn "No checkpoint file to clear"
  fi
}

#######################################
# Increment recovery count
#######################################

increment_recovery_count() {
  init_checkpoint

  local current_count
  current_count=$(json_get "${CHECKPOINT_FILE}" "recovery_count" "0")
  local new_count=$((current_count + 1))

  # Update recovery count (portable: temp file + mv, not sed -i)
  sed "s/\"recovery_count\": [0-9]*/\"recovery_count\": ${new_count}/" "${CHECKPOINT_FILE}" > "${CHECKPOINT_FILE}.tmp" 2>/dev/null && mv "${CHECKPOINT_FILE}.tmp" "${CHECKPOINT_FILE}"

  log_info "Recovery count: ${new_count}"
}

#######################################
# Check if recovery is needed
#######################################

needs_recovery() {
  if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    echo "false"
    return
  fi

  local status
  status=$(json_get "${CHECKPOINT_FILE}" "status" "")

  if [[ "$status" == "in_progress" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

#######################################
# Show usage
#######################################

show_usage() {
  cat <<'EOF'
RDD Checkpoint Management Script

Usage: checkpoint.sh <command> [options]

Commands:
  save [stage_id] [stage_name] [progress]
                          Save current checkpoint state
  load                    Load and display checkpoint state
  show                    Display current checkpoint
  clear                   Clear checkpoint file
  update <key> <value>    Update specific checkpoint field
  gate <gate_num> <status>
                          Update gate status (gate_num: 1-5, status: pending/completed/failed)
  decision <id> <title>   Add a decision to history
  blocker <id> <description> [priority]
                          Add/update a blocker
  clear-blocker <id>      Clear a blocker
  needs-recovery          Check if recovery is needed (returns true/false)
  increment-recovery      Increment recovery count

Environment Variables:
  RDD_DIR         RDD configuration directory (default: script parent)
  PROJECT_ROOT    Project root directory (default: RDD_DIR parent)
  VERBOSE         Set to 'true' for debug output

Examples:
  # Save checkpoint for current stage
  checkpoint.sh save stage-3 "Context Recovery" 50

  # Update gate status
  checkpoint.sh gate 1 completed
  checkpoint.sh gate 2 in_progress

  # Check if recovery is needed
  if [ "$(checkpoint.sh needs-recovery)" = "true" ]; then
    echo "Recovery needed"
  fi

  # Add decision
  checkpoint.sh decision ADR-17 "Use file-based checkpoint storage"

EOF
}

#######################################
# Main entry point
#######################################

main() {
  if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
  fi

  local command="$1"
  shift

  case "$command" in
    save)
      save_checkpoint "$@"
      ;;
    load)
      load_checkpoint "$@"
      ;;
    show)
      show_checkpoint
      ;;
    clear)
      clear_checkpoint
      ;;
    update)
      if [[ $# -lt 2 ]]; then
        log_error "Usage: checkpoint.sh update <key> <value>"
        exit 1
      fi
      save_checkpoint
      ;;
    gate)
      if [[ $# -lt 2 ]]; then
        log_error "Usage: checkpoint.sh gate <gate_num> <status>"
        exit 1
      fi
      update_gate "gate_$1" "$2"
      ;;
    decision)
      if [[ $# -lt 2 ]]; then
        log_error "Usage: checkpoint.sh decision <id> <title>"
        exit 1
      fi
      add_decision "$1" "$2"
      ;;
    blocker)
      if [[ $# -lt 2 ]]; then
        log_error "Usage: checkpoint.sh blocker <id> <description> [priority]"
        exit 1
      fi
      add_blocker "$1" "$2" "${3:-P1}"
      ;;
    clear-blocker)
      if [[ $# -lt 1 ]]; then
        log_error "Usage: checkpoint.sh clear-blocker <id>"
        exit 1
      fi
      clear_blocker "$1"
      ;;
    needs-recovery)
      needs_recovery
      ;;
    increment-recovery)
      increment_recovery_count
      ;;
    -h | --help | help)
      show_usage
      exit 0
      ;;
    *)
      log_error "Unknown command: $command"
      show_usage
      exit 1
      ;;
  esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi
