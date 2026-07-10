#!/bin/bash
#
# RDD Progress Dashboard
# Displays real-time multi-stage progress with autosave status.
#
# Usage: progress-dashboard.sh [--json]
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
RDD_DIR="${RDD_DIR:-${PROJECT_ROOT}/.rdd}"
LOOP_STATE="${RDD_DIR}/cache/loop-state.yaml"
ROADMAP="${PROJECT_ROOT}/docs/stages/stage-roadmap.md"
CHECKPOINT="${RDD_DIR}/cache/checkpoints.json"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'
BLUE='\033[0;34m'
DIM='\033[2m'

# ==========================================
# Parse roadmap for stage names and statuses
# ==========================================

get_stage_name() {
  local id="$1"
  grep "Stage ${id}" "$ROADMAP" 2>/dev/null | grep "Goal" | head -1 |
    sed 's/.*\*\*Goal\*\*: //' | sed 's/|.*//' | sed 's/\*//g' | tr -d '\n' | sed 's/^ *//;s/ *$//'
}

get_roadmap_status() {
  local id="$1"
  local line
  line=$(grep "| Stage ${id} " "$ROADMAP" 2>/dev/null | head -1)
  if echo "$line" | grep -q "Completed"; then
    echo "complete"
  elif echo "$line" | grep -q "Progress"; then
    echo "in_progress"
  elif echo "$line" | grep -q "Pending"; then
    echo "pending"
  else
    echo "unknown"
  fi
}

get_loop_status() {
  local id="$1"
  if [ -f "$LOOP_STATE" ]; then
    yq eval ".stages[] | select(.id == ${id}).status" "$LOOP_STATE" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

get_loop_gate() {
  local id="$1"
  if [ -f "$LOOP_STATE" ]; then
    yq eval ".stages[] | select(.id == ${id}).current_gate // \"\"" "$LOOP_STATE" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# ==========================================
# Progress bar
# ==========================================

progress_bar() {
  local pct="$1" width="${2:-10}"
  local filled=$((pct * width / 100))
  local empty=$((width - filled))

  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done
  echo "$bar"
}

# ==========================================
# Gate-to-progress mapping
# ==========================================

gate_to_pct() {
  local gate="$1"
  case "$gate" in
    0) echo 0 ;;
    1) echo 15 ;;
    2) echo 30 ;;
    3) echo 60 ;;
    4) echo 80 ;;
    5) echo 100 ;;
    *) echo 0 ;;
  esac
}

gate_to_label() {
  local gate="$1"
  case "$gate" in
    0) echo "Init  " ;;
    1) echo "Design" ;;
    2) echo "Review" ;;
    3) echo "Impl  " ;;
    4) echo "CR    " ;;
    5) echo "Done  " ;;
    *) echo "?     " ;;
  esac
}

# ==========================================
# Render dashboard
# ==========================================

render_dashboard() {
  # Collect all stages from roadmap
  local stages
  stages=$(grep -E '^\| Stage [0-9]+' "$ROADMAP" 2>/dev/null |
    sed 's/| Stage \([0-9]*\).*/\1/' | sort -n)

  if [ -z "$stages" ]; then
    echo "No stages found in roadmap."
    return 1
  fi

  echo ""
  printf "${BOLD}┌───────────────────────────────────────────────────────────────┐${NC}\n"
  printf "${BOLD}│${NC} ${CYAN}${BOLD}RDD Multi-stage Progress Dashboard${NC}                              ${BOLD}│${NC}\n"
  printf "${BOLD}├───────────────────────────────────────────────────────────────┤${NC}\n"

  local total=0 completed=0 in_progress=0 pending=0
  local current_stage="" current_gate=""

  for id in $stages; do
    total=$((total + 1))
    local roadmap_status loop_status gate
    roadmap_status=$(get_roadmap_status "$id")
    loop_status=$(get_loop_status "$id")
    gate=$(get_loop_gate "$id")

    # Use loop state if available, else fall back to roadmap
    local effective_status="${loop_status:-$roadmap_status}"

    local status_icon="" status_color="" pct=0
    case "$effective_status" in
      complete)
        status_icon="✅"
        pct=100
        completed=$((completed + 1))
        ;;
      in_progress)
        status_icon="🔄"
        pct=$(gate_to_pct "${gate:-0}")
        in_progress=$((in_progress + 1))
        current_stage="$id"
        current_gate="${gate:-0}"
        ;;
      failed)
        status_icon="❌"
        pct=0
        ;;
      *)
        status_icon="⏳"
        pct=0
        pending=$((pending + 1))
        ;;
    esac

    local name bar gate_label
    name=$(get_stage_name "$id")
    bar=$(progress_bar "$pct" 14)
    gate_label=$(gate_to_label "${gate:-0}")

    printf "${BOLD}│${NC} Stage %-3s ${bar} %3d%% %s %-5s %-28s ${BOLD}│${NC}\n" \
      "$id" "$pct" "$status_icon" "$gate_label" "${name:0:28}"
  done

  printf "${BOLD}├───────────────────────────────────────────────────────────────┤${NC}\n"

  # Summary line
  local session_id="-" autosave="no data"
  if [ -f "$LOOP_STATE" ]; then
    session_id=$(yq eval '.session_id // "-"' "$LOOP_STATE" 2>/dev/null)
    autosave=$(yq eval '.last_checkpoint // "no data"' "$LOOP_STATE" 2>/dev/null)
    local ts_now ts_save
    ts_now=$(date +%s)
    ts_save=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$autosave" +%s 2>/dev/null || echo 0)
    local ago=$(((ts_now - ts_save) / 60))
    autosave="${ago}m ago"
  fi

  printf "${BOLD}│${NC} ${DIM}Session: ${session_id:0:24}${NC}     ${DIM}Autosave: ${autosave}${NC}                  ${BOLD}│${NC}\n"

  # Parallel info
  local active_wt=0
  if [ -f "${RDD_DIR}/worktrees/pool.json" ]; then
    active_wt=$(grep -c '"[0-9]*":' "${RDD_DIR}/worktrees/pool.json" 2>/dev/null || echo 0)
  fi

  local test_status="-"
  if [ -f "$LOOP_STATE" ]; then
    local unit_pass unit_fail
    unit_pass=$(yq eval '.last_test_results.unit.pass // "-"' "$LOOP_STATE" 2>/dev/null)
    unit_fail=$(yq eval '.last_test_results.unit.fail // "0"' "$LOOP_STATE" 2>/dev/null)
    if [ "$unit_pass" != "-" ]; then
      test_status="${unit_pass}/${unit_fail}"
    fi
  fi

  printf "${BOLD}│${NC} ${DIM}Total: ${total} | Done: ${completed} | Active: ${in_progress} | Pending: ${pending} | Par: ${active_wt} | Tests: ${test_status}${NC}  ${BOLD}│${NC}\n"
  printf "${BOLD}└───────────────────────────────────────────────────────────────┘${NC}\n"
  echo ""

  # Current gate focus
  if [ -n "$current_stage" ]; then
    local gate_name
    gate_name=$(gate_to_label "$current_gate")
    printf "Next: Stage ${current_stage} Gate ${current_gate} (${gate_name})\n"
  else
    printf "All stages complete.\n"
  fi
}

# ==========================================
# JSON output for machine consumption
# ==========================================

render_json() {
  if [ ! -f "$LOOP_STATE" ]; then
    echo '{"error": "no loop state"}'
    return 1
  fi
  yq eval -o=json '.' "$LOOP_STATE" 2>/dev/null || echo '{"error": "parse failed"}'
}

# ==========================================
# Usage
# ==========================================

show_usage() {
  cat <<'EOF'
RDD Progress Dashboard

Usage: progress-dashboard.sh [--json]

Options:
  --json    Output machine-readable JSON (loop-state.yaml)
  (none)    Render human-readable dashboard

EOF
}

# ==========================================
# Main
# ==========================================

main() {
  if [ "$#" -gt 0 ] && [ "$1" = "--json" ]; then
    render_json
  elif [ "$#" -gt 0 ] && [ "$1" = "--help" ]; then
    show_usage
  else
    render_dashboard
  fi
}

main "$@"
