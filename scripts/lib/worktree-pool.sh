#!/usr/bin/env bash
# Worktree Pool Manager for Parallel Stage Execution
# Manages git worktrees for isolated stage development

set -e

# Project root
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORKTREE_DIR="${PROJECT_ROOT}/.rdd/worktrees"
POOL_FILE="${WORKTREE_DIR}/pool.json"
MAX_WORKTREES="${MAX_WORKTREES:-3}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize worktree pool
init_pool() {
  mkdir -p "$WORKTREE_DIR"

  if [[ ! -f "$POOL_FILE" ]]; then
    echo '{
  "active": {},
  "available": [],
  "history": [],
  "max_worktrees": '$MAX_WORKTREES'
}' >"$POOL_FILE"
  fi

  echo -e "${GREEN}[OK]${NC} Worktree pool initialized at $WORKTREE_DIR"
}

# Allocate a worktree for a stage
allocate() {
  local stage="$1"
  local branch="${2:-stage-$stage}"

  if [[ -z "$stage" ]]; then
    echo -e "${RED}[ERROR]${NC} Stage number required"
    return 1
  fi

  # Check if already allocated
  if jq -e ".active[\"$stage\"]" "$POOL_FILE" >/dev/null 2>&1; then
    echo -e "${YELLOW}[WARN]${NC} Stage $stage already has a worktree allocated"
    return 0
  fi

  # Check pool limit
  local active_count=$(jq '.active | length' "$POOL_FILE")
  if [[ "$active_count" -ge "$MAX_WORKTREES" ]]; then
    echo -e "${RED}[ERROR]${NC} Maximum worktrees ($MAX_WORKTREES) reached"
    return 1
  fi

  # Generate unique ID
  local id=$(head -c 6 /dev/urandom | xxd -p | head -c 6)
  local worktree_path="${WORKTREE_DIR}/stage-${stage}-${id}"

  # Create worktree
  echo -e "${BLUE}[INFO]${NC} Creating worktree: $worktree_path"
  git worktree add "$worktree_path" -b "$branch" 2>/dev/null ||
    git worktree add "$worktree_path" "$branch" 2>/dev/null ||
    git worktree add "$worktree_path" --detach

  # Update pool
  local tmp_file=$(mktemp)
  jq --arg stage "$stage" --arg path "$worktree_path" --arg id "$id" --arg branch "$branch" \
    '.active[$stage] = {"path": $path, "id": $id, "branch": $branch, "created": (now | todate)}' \
    "$POOL_FILE" >"$tmp_file"
  mv "$tmp_file" "$POOL_FILE"

  echo -e "${GREEN}[OK]${NC} Allocated worktree for Stage $stage: $worktree_path"
  echo "$worktree_path"
}

# Release a worktree
release() {
  local stage="$1"

  if [[ -z "$stage" ]]; then
    echo -e "${RED}[ERROR]${NC} Stage number required"
    return 1
  fi

  local worktree_info=$(jq -c ".active[\"$stage\"]" "$POOL_FILE" 2>/dev/null)

  if [[ -z "$worktree_info" ]] || [[ "$worktree_info" == "null" ]]; then
    echo -e "${YELLOW}[WARN]${NC} No worktree allocated for Stage $stage"
    return 0
  fi

  local worktree_path=$(echo "$worktree_info" | jq -r '.path')

  # Remove worktree
  if [[ -d "$worktree_path" ]]; then
    echo -e "${BLUE}[INFO]${NC} Removing worktree: $worktree_path"
    git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
  fi

  # Update pool
  local tmp_file=$(mktemp)
  jq --arg stage "$stage" \
    '.history += [.active[$stage]] | del(.active[$stage])' \
    "$POOL_FILE" >"$tmp_file"
  mv "$tmp_file" "$POOL_FILE"

  echo -e "${GREEN}[OK]${NC} Released worktree for Stage $stage"
}

# List active worktrees
list() {
  echo -e "${BLUE}Active Worktrees:${NC}"
  jq -r '.active | to_entries[] | "  Stage \(.key): \(.value.path) (\(.value.branch))"' "$POOL_FILE" 2>/dev/null ||
    echo "  No active worktrees"

  echo ""
  echo -e "${BLUE}Pool Status:${NC}"
  local active=$(jq '.active | length' "$POOL_FILE")
  echo "  Active: $active / $MAX_WORKTREES"
}

# Get worktree path for a stage
get_path() {
  local stage="$1"
  jq -r ".active[\"$stage\"].path // empty" "$POOL_FILE" 2>/dev/null
}

# Clean up all worktrees
cleanup() {
  echo -e "${BLUE}[INFO]${NC} Cleaning up all worktrees..."

  local stages=$(jq -r '.active | keys[]' "$POOL_FILE" 2>/dev/null)

  for stage in $stages; do
    release "$stage"
  done

  # Prune stale worktrees
  git worktree prune 2>/dev/null || true

  echo -e "${GREEN}[OK]${NC} Cleanup complete"
}

# Merge worktree to main
merge() {
  local stage="$1"
  local target_branch="${2:-main}"

  local worktree_path=$(get_path "$stage")

  if [[ -z "$worktree_path" ]]; then
    echo -e "${RED}[ERROR]${NC} No worktree for Stage $stage"
    return 1
  fi

  local branch=$(jq -r ".active[\"$stage\"].branch" "$POOL_FILE")

  echo -e "${BLUE}[INFO]${NC} Merging $branch to $target_branch..."

  # Fetch and merge
  git fetch origin "$target_branch"
  git checkout "$target_branch"
  git merge "$branch" --no-edit

  echo -e "${GREEN}[OK]${NC} Merged $branch to $target_branch"

  # Release worktree
  release "$stage"
}

# Show pool status
status() {
  echo -e "${BLUE}=== Worktree Pool Status ===${NC}"
  echo ""

  list

  echo ""
  echo -e "${BLUE}Recent History:${NC}"
  jq -r '.history[-5:][] | "  \(.created): Stage \(.id) - \(.path)"' "$POOL_FILE" 2>/dev/null ||
    echo "  No history"
}

# Main function
main() {
  local command="${1:-status}"
  shift 2>/dev/null || true

  # Ensure pool is initialized
  init_pool >/dev/null 2>&1

  case "$command" in
    init)
      init_pool
      ;;
    allocate)
      allocate "$@"
      ;;
    release)
      release "$@"
      ;;
    list)
      list
      ;;
    path)
      get_path "$@"
      ;;
    cleanup)
      cleanup
      ;;
    merge)
      merge "$@"
      ;;
    status)
      status
      ;;
    *)
      echo "Usage: $0 {init|allocate|release|list|path|cleanup|merge|status}"
      echo ""
      echo "Commands:"
      echo "  init              Initialize worktree pool"
      echo "  allocate N        Allocate worktree for Stage N"
      echo "  release N         Release worktree for Stage N"
      echo "  list              List active worktrees"
      echo "  path N            Get worktree path for Stage N"
      echo "  cleanup           Remove all worktrees"
      echo "  merge N [branch]  Merge Stage N to branch (default: main)"
      echo "  status            Show pool status"
      exit 1
      ;;
  esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
