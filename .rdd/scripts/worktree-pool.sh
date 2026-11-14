#!/bin/bash
#
# RDD Worktree Pool Manager
# Manages git worktrees for isolated parallel stage execution.
#
# Usage: worktree-pool.sh <command> [args]
#
# Commands:
#   allocate <stage_id>              - Allocate a worktree for stage
#   release <stage_id>               - Release worktree after completion
#   list                             - List active worktrees
#   cleanup                          - Remove completed worktrees
#   status <stage_id>                - Check worktree status for stage
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
POOL_DIR="${PROJECT_ROOT}/.rdd/worktrees"
POOL_FILE="${POOL_DIR}/pool.json"
MAX_PARALLEL="${RDD_WORKTREE_MAX_PARALLEL:-3}"
DEFAULT_BRANCH="main"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[POOL]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[POOL]${NC} $*" >&2; }
log_error() { echo -e "${RED}[POOL]${NC} $*" >&2; }

get_timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ==========================================
# Initialize pool state
# ==========================================

init_pool() {
  mkdir -p "$POOL_DIR"
  if [ ! -f "$POOL_FILE" ]; then
    cat >"$POOL_FILE" <<'EOF'
{
  "max_parallel": 3,
  "active": {}
}
EOF
  fi
}

# ==========================================
# Allocate worktree for a stage
# ==========================================

allocate() {
  local stage_id="$1"

  init_pool

  # Check if already allocated
  local existing_path
  existing_path=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["active"].get(sys.argv[2], ""))' "$POOL_FILE" "$stage_id")
  if [ -n "$existing_path" ] && [ -d "$existing_path" ]; then
    log_info "Worktree already allocated for Stage ${stage_id}: ${existing_path}"
    echo "$existing_path"
    return 0
  fi

  # Check max parallel limit
  local active_count
  active_count=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["active"]))' "$POOL_FILE")
  if [ "$active_count" -ge "$MAX_PARALLEL" ]; then
    log_error "Max parallel worktrees reached (${MAX_PARALLEL})"
    return 1
  fi

  # Determine base branch
  local base_ref="origin/$DEFAULT_BRANCH"
  if ! git rev-parse --verify "origin/${DEFAULT_BRANCH}" >/dev/null 2>&1; then
    base_ref="HEAD"
  fi

  # Create branch and worktree
  local branch_name="rdd/stage-${stage_id}"
  local ts
  ts=$(date +%s)
  branch_name="${branch_name}-${ts}"

  local worktree_path="${POOL_DIR}/stage-${stage_id}-${ts}"

  log_info "Creating worktree for Stage ${stage_id}..."
  log_info "  Branch: ${branch_name}"
  log_info "  Path: ${worktree_path}"

  git worktree add "$worktree_path" -b "$branch_name" "$base_ref" >&2

  python3 - "$POOL_FILE" "$stage_id" "$worktree_path" <<'PYPOOL'
import json, os, sys
path, stage, worktree = sys.argv[1:]
with open(path) as f: state = json.load(f)
state['active'][stage] = worktree
with open(path + '.tmp', 'w') as f: json.dump(state, f, indent=2)
os.replace(path + '.tmp', path)
PYPOOL

  echo "$worktree_path"
}

# ==========================================
# Release worktree
# ==========================================

release() {
  local stage_id="$1"

  init_pool

  local worktree_path
  worktree_path=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["active"].get(sys.argv[2], ""))' "$POOL_FILE" "$stage_id")

  if [ -z "$worktree_path" ]; then
    log_warn "No worktree found for Stage ${stage_id}"
    return 0
  fi

  log_info "Releasing worktree for Stage ${stage_id}: ${worktree_path}"

  # Remove worktree
  if [ -d "$worktree_path" ]; then
    git worktree remove "$worktree_path" || {
      log_error "Worktree retained: commit/stash changes and verify stage completion before release"
      return 1
    }
  fi

  python3 - "$POOL_FILE" "$stage_id" <<'PYPOOL'
import json, os, sys
path, stage = sys.argv[1:]
with open(path) as f: state = json.load(f)
state['active'].pop(stage, None)
with open(path + '.tmp', 'w') as f: json.dump(state, f, indent=2)
os.replace(path + '.tmp', path)
PYPOOL

  log_info "Worktree released for Stage ${stage_id}"
}

# ==========================================
# List active worktrees
# ==========================================

list_worktrees() {
  init_pool

  echo "Active Worktrees:"
  echo "=================="

  if [ -f "$POOL_FILE" ]; then
    local active
    active=$(grep -o '"[0-9]*": "[^"]*"' "$POOL_FILE" 2>/dev/null || echo "")
    if [ -z "$active" ]; then
      echo "  (none)"
    else
      echo "$active" | while read -r line; do
        local id path
        id=$(echo "$line" | cut -d'"' -f2)
        path=$(echo "$line" | cut -d'"' -f4)
        local status="active"
        [ ! -d "$path" ] && status="orphaned"
        echo "  Stage ${id}: ${path} [${status}]"
      done
    fi
  fi

  echo ""
  git worktree list 2>/dev/null || echo "  (git worktree not available)"
}

# ==========================================
# Cleanup all worktrees
# ==========================================

cleanup() {
  log_info "Cleaning up worktree pool..."

  if [ -f "$POOL_FILE" ]; then
    # Release all from pool
    grep -o '"[0-9]*": "[^"]*"' "$POOL_FILE" 2>/dev/null | while read -r line; do
      local stage_id
      stage_id=$(echo "$line" | cut -d'"' -f2)
      release "$stage_id"
    done
  fi

  # Prune stale git worktrees
  git worktree prune 2>/dev/null || true

  log_info "Worktree pool cleaned"
}

# ==========================================
# Status
# ==========================================

status() {
  local stage_id="${1:-}"

  if [ -n "$stage_id" ]; then
    local path
    path=$(grep -o "\"${stage_id}\":[[:space:]]*\"[^\"]*\"" "$POOL_FILE" 2>/dev/null | sed 's/.*: "//' | sed 's/"$//' || echo "")
    if [ -n "$path" ] && [ -d "$path" ]; then
      echo "Stage ${stage_id}: allocated at ${path}"
    else
      echo "Stage ${stage_id}: not allocated"
    fi
  else
    list_worktrees
  fi
}

# ==========================================
# Usage
# ==========================================

show_usage() {
  cat <<'EOF'
RDD Worktree Pool Manager

Usage: worktree-pool.sh <command> [args]

Commands:
  allocate <stage_id>    Allocate a worktree for isolated stage execution
  release <stage_id>     Release worktree after stage completion
  list                   List all active worktrees
  cleanup                Remove all worktrees and prune
  status [stage_id]      Check worktree status

Environment:
  RDD_WORKTREE_MAX_PARALLEL  Max concurrent worktrees (default: 3)

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
  cd "$PROJECT_ROOT"
  case "$cmd" in
    allocate | release)
      [[ "${1:-}" =~ ^[0-9]+$ ]] || {
        log_error "Numeric stage id required"
        return 2
      }
      [[ "$MAX_PARALLEL" =~ ^[1-9][0-9]*$ ]] || {
        log_error "Positive pool limit required"
        return 2
      }
      ;;
  esac
  case "$cmd" in
    allocate | release | cleanup)
      mkdir -p "$POOL_DIR"
      mkdir "$POOL_DIR/.lock" 2>/dev/null || {
        log_error "Pool busy; retry after the active operation"
        return 1
      }
      trap 'rmdir "$POOL_DIR/.lock"' EXIT
      ;;
  esac
  case "$cmd" in
    allocate) allocate "$@" ;;
    release) release "$@" ;;
    list) list_worktrees "$@" ;;
    cleanup) cleanup "$@" ;;
    status) status "$@" ;;
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
