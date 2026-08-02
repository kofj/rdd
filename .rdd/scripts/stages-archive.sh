#!/bin/bash
#
# RDD Stages Archive Script
# Archive old stage-N.md files, keeping the 5 most recent completed stages
# plus all incomplete stages. Non-stage-N.md files are never touched.
#
# Usage: stages-archive.sh [options]
#
# Options:
#   --dry-run      Preview what would be archived without making changes
#   --keep N       Number of recent completed stages to keep (default: 5)
#   --help, -h     Show this help
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
STAGES_DIR="${STAGES_DIR:-${PROJECT_ROOT}/docs/stages}"
ROADMAP_FILE="${ROADMAP_FILE:-${STAGES_DIR}/stage-roadmap.md}"
ARCHIVE_DIR="${STAGES_DIR}/archived"

KEEP_COUNT=5
DRY_RUN=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_debug() {
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*"
  fi
}

#######################################
# Parse roadmap to get completed stage numbers.
# Matches table rows like: | Stage N | ✅ Completed |
# Returns: space-separated sorted stage numbers that are completed.
#######################################
get_completed_stages() {
  if [[ ! -f "$ROADMAP_FILE" ]]; then
    log_error "Roadmap file not found: ${ROADMAP_FILE}"
    return 1
  fi

  # Extract stage numbers from completed rows
  # Pattern: | Stage <num> | ✅ Completed |
  completed=$(grep -E '^\| Stage [0-9]+ \| ✅ Completed \|' "$ROADMAP_FILE" | \
    sed -E 's/^\| Stage ([0-9]+) \|.*/\1/' | \
    sort -n)

  echo "$completed"
}

#######################################
# Find all stage-N.md files (pure numeric) in stages dir.
# Returns: space-separated list of filenames (without path).
#######################################
get_stage_files() {
  local files=""
  for f in "$STAGES_DIR"/stage-*.md; do
    [[ -f "$f" ]] || continue
    local name
    name=$(basename "$f")
    # Only match stage-N.md where N is purely numeric
    if [[ "$name" =~ ^stage-[0-9]+\.md$ ]]; then
      files="${files}${name} "
    fi
  done
  echo "${files% }"
}

#######################################
# Parse arguments.
#######################################
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --keep)
        KEEP_COUNT="$2"
        if ! [[ "$KEEP_COUNT" =~ ^[0-9]+$ ]]; then
          log_error "--keep requires a positive integer, got: $KEEP_COUNT"
          exit 1
        fi
        shift 2
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

#######################################
# Show usage help.
#######################################
show_help() {
  cat <<'EOF'
RDD Stages Archive Script

Archive old stage-N.md files to docs/stages/archived/.
Keeps the N most recent completed stages plus all incomplete stages.
Only pure numeric stage-N.md files are considered; other files are untouched.

Usage: stages-archive.sh [options]

Options:
  --dry-run      Preview what would be archived without making changes
  --keep N       Number of recent completed stages to keep (default: 5)
  --help, -h     Show this help

Examples:
  # Preview what would be archived
  stages-archive.sh --dry-run

  # Archive, keeping only the 3 most recent completed stages
  stages-archive.sh --keep 3

EOF
}

#######################################
# Main archive logic.
#######################################
do_archive() {
  # Get completed stages from roadmap
  local completed
  completed=$(get_completed_stages)
  if [[ -z "$completed" ]]; then
    log_info "No completed stages found in roadmap — nothing to archive"
    return 0
  fi

  # Build associative array of completed status
  declare -A is_completed
  while IFS= read -r num; do
    [[ -n "$num" ]] && is_completed[$num]=1
  done <<< "$completed"

  log_debug "Completed stages: $completed"

  # Get all stage-N.md files
  local all_stages
  all_stages=$(get_stage_files)
  if [[ -z "$all_stages" ]]; then
    log_info "No stage-N.md files found — nothing to do"
    return 0
  fi

  # Classify and separate
  local completed_list=()
  local incomplete_list=()

  for f in $all_stages; do
    local num
    num=$(echo "$f" | sed -E 's/^stage-([0-9]+)\.md$/\1/')
    if [[ -n "${is_completed[$num]:-}" ]]; then
      completed_list+=("$num")
    else
      incomplete_list+=("$num")
    fi
  done

  # Sort completed by number descending (highest first)
  local sorted_completed
  sorted_completed=$(printf '%s\n' "${completed_list[@]}" | sort -rn)

  # Determine which completed stages to keep (top N) and which to archive (rest)
  local keep_count=0
  local to_archive=()
  local to_keep=()

  for num in $sorted_completed; do
    keep_count=$((keep_count + 1))
    if [[ $keep_count -le $KEEP_COUNT ]]; then
      to_keep+=("$num")
    else
      to_archive+=("$num")
    fi
  done

  log_info "Completed stage(s): ${#completed_list[@]}"
  log_info "Incomplete stage(s) (always kept): ${#incomplete_list[@]}"
  log_info "Keeping ${#to_keep[@]} most recent completed stage(s): $(echo "${to_keep[@]}" | tr ' ' ', ')"
  log_info "Archive list (${#to_archive[@]}): $(echo "${to_archive[@]}" | tr ' ' ', ')"

  if [[ ${#to_archive[@]} -eq 0 ]]; then
    log_info "Nothing to archive — all stages within keep threshold"
    return 0
  fi

  # Create archive directory if needed
  if [[ "$DRY_RUN" == "false" ]]; then
    mkdir -p "$ARCHIVE_DIR"
  fi

  # Move files
  local moved=0
  for num in "${to_archive[@]}"; do
    local src="${STAGES_DIR}/stage-${num}.md"
    local dst="${ARCHIVE_DIR}/stage-${num}.md"

    if [[ ! -f "$src" ]]; then
      log_warn "Stage file not found (skipping): ${src}"
      continue
    fi

    if [[ -f "$dst" ]]; then
      log_warn "Already archived (skipping): stage-${num}.md"
      continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would move: stage-${num}.md → archived/"
    else
      mv "$src" "$dst"
      log_info "Moved: stage-${num}.md → archived/"
    fi
    moved=$((moved + 1))
  done

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would move ${moved} file(s) to ${ARCHIVE_DIR}"
  else
    log_info "Archive complete: ${moved} moved, ${#to_keep[@]} kept, ${#incomplete_list[@]} incomplete kept"
  fi
}

#######################################
# Main entry.
#######################################
main() {
  parse_args "$@"
  do_archive
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi
