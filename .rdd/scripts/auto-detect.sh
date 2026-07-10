#!/bin/bash
#
# RDD Auto-Detect Engine
# Scans stage roadmap, identifies incomplete stages, resolves dependencies.
#
# Usage: auto-detect.sh [--from N] [--to M]
#
# Output: JSON/YAML execution plan to stdout.
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
ROADMAP_FILE="${PROJECT_ROOT}/docs/stages/stage-roadmap.md"
DEPENDENCY_FILE="${PROJECT_ROOT}/.rdd/dependency-graph.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[DETECT]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[DETECT]${NC} $*"; }
log_error() { echo -e "${RED}[DETECT]${NC} $*"; }

FROM_STAGE=""
TO_STAGE=""

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --from)
      FROM_STAGE="$2"
      shift 2
      ;;
    --to)
      TO_STAGE="$2"
      shift 2
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ==========================================
# Parse roadmap to extract stage status
# ==========================================

parse_stages() {
  if [ ! -f "$ROADMAP_FILE" ]; then
    log_error "Roadmap not found: ${ROADMAP_FILE}"
    exit 1
  fi

  # Extract stage rows: | Stage N | Status | Goal | Dependencies |
  # Status patterns: "✅ Completed", "🔄 In Progress", "⏳ Pending"
  grep -E '^\| Stage [0-9]+' "$ROADMAP_FILE" | while IFS='|' read -r _ stage status goal deps; do
    stage=$(echo "$stage" | sed 's/Stage //' | tr -d ' ')
    status=$(echo "$status" | tr -d ' ')

    # Normalize status
    case "$status" in
      *Completed*) status="complete" ;;
      *Progress*) status="in_progress" ;;
      *Pending*) status="pending" ;;
      *) status="pending" ;;
    esac

    # Extract dependency numbers
    local dep_list=""
    if echo "$deps" | grep -q "Stage"; then
      dep_list=$(echo "$deps" | grep -oE '[0-9]+' | tr '\n' ',' | sed 's/,$//')
    fi

    echo "${stage}|${status}|${dep_list}"
  done
}

# ==========================================
# Topological sort of stages by dependencies
# ==========================================

topological_sort() {
  local stages_file="$1"

  # Build dependency graph and sort
  # Simple implementation: iterate until all stages ordered
  # For production, use proper Kahn's algorithm

  local ordered=""
  local resolved=""
  local remaining
  remaining=$(cat "$stages_file")

  local max_iter=100 iter=0
  while [ -n "$remaining" ] && [ $iter -lt $max_iter ]; do
    iter=$((iter + 1))
    local new_remaining=""
    local progress=0

    while IFS='|' read -r id status deps; do
      if [ -z "$id" ]; then continue; fi

      # Check if all dependencies are resolved
      local all_deps_met=true
      if [ -n "$deps" ]; then
        IFS=',' read -ra DEP_ARRAY <<<"$deps"
        for dep in "${DEP_ARRAY[@]}"; do
          if ! echo "$resolved" | grep -q " ${dep} "; then
            all_deps_met=false
            break
          fi
        done
      fi

      if [ "$all_deps_met" = true ]; then
        ordered="${ordered}${id} "
        resolved="${resolved} ${id} "
        progress=1
      else
        new_remaining="${new_remaining}${id}|${status}|${deps}
"
      fi
    done <<<"$remaining"

    remaining="$new_remaining"
    if [ $progress -eq 0 ] && [ -n "$remaining" ]; then
      log_error "Circular dependency detected! Remaining stages: $(echo "$remaining" | cut -d'|' -f1 | tr '\n' ' ')"
      exit 1
    fi
  done

  echo "$ordered"
}

# ==========================================
# Generate execution plan
# ==========================================

generate_plan() {
  local stages_data="$1"
  local ordered="$2"

  log_info "Scanning roadmap for incomplete stages..."

  # Collect incomplete stages in dependency order
  local todo=""
  local todo_details=""
  for stage_id in $ordered; do
    local status
    status=$(echo "$stages_data" | grep "^${stage_id}|" | cut -d'|' -f2)
    if [ "$status" != "complete" ]; then
      # Apply --from/--to filters
      if [ -n "$FROM_STAGE" ] && [ "$stage_id" -lt "$FROM_STAGE" ] 2>/dev/null; then
        continue
      fi
      if [ -n "$TO_STAGE" ] && [ "$stage_id" -gt "$TO_STAGE" ] 2>/dev/null; then
        continue
      fi
      todo="${todo}${stage_id} "
      local deps
      deps=$(echo "$stages_data" | grep "^${stage_id}|" | cut -d'|' -f3)
      todo_details="${todo_details}  ${stage_id}: deps=[${deps}] status=${status}
"
    fi
  done

  if [ -z "$todo" ]; then
    log_info "No incomplete stages found in range."
    return 0
  fi

  # Count
  local count
  count=$(echo "$todo" | wc -w | tr -d ' ')
  log_info "Found ${count} incomplete stage(s):${todo// /, }"

  echo ""
  echo "Execution Plan:"
  echo "==============="
  echo -e "$todo_details"

  # Build ordered array
  echo ""
  echo "Ordered execution sequence:"
  local seq=1
  for stage_id in $todo; do
    local line
    line=$(echo "$stages_data" | grep "^${stage_id}|")
    local stage_name=""
    # Try to get name from roadmap
    stage_name=$(grep -A 3 "### Stage ${stage_id}:" "$ROADMAP_FILE" 2>/dev/null | grep "Goal" | head -1 | sed 's/.*\*\*Goal\*\*: //' | sed 's/\*//g' | tr -d '\n' | sed 's/^ *//;s/ *$//')
    echo "  ${seq}. Stage ${stage_id}: ${stage_name:-unknown}"
    seq=$((seq + 1))
  done

  return 0
}

# ==========================================
# Main
# ==========================================

main() {
  if [ ! -f "$ROADMAP_FILE" ]; then
    log_error "Roadmap file not found: ${ROADMAP_FILE}"
    exit 1
  fi

  local stages_data ordered plan_file
  plan_file="/tmp/rdd-detect-$$.tmp"

  # Parse stages
  stages_data=$(parse_stages)

  # Save for topological sort
  echo "$stages_data" >"$plan_file"

  # Sort
  ordered=$(topological_sort "$plan_file")

  # Generate plan
  generate_plan "$stages_data" "$ordered"

  rm -f "$plan_file"
}

main "$@"
