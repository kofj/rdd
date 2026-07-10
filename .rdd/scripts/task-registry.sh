#!/bin/bash
#
# RDD Task Registry
# Ensures all scripts are registered as task entries in Taskfile.yml.
#
# Usage: task-registry.sh <command> [args]
#
# Commands:
#   register <name> <desc> <command>   - Register new task
#   verify                              - Check for orphan scripts (non-zero exit if found)
#   list-orphans                        - List scripts not in Taskfile
#

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
TASKFILE="${PROJECT_ROOT}/Taskfile.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[REGISTRY]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[REGISTRY]${NC} $*"; }
log_error() { echo -e "${RED}[REGISTRY]${NC} $*"; }

# ==========================================
# Register a new task
# ==========================================

register_task() {
  local name="$1" desc="$2" command="$3"

  if [ ! -f "$TASKFILE" ]; then
    log_error "Taskfile not found: ${TASKFILE}"
    return 1
  fi

  # Check if already registered
  if grep -q "  ${name}:" "$TASKFILE" 2>/dev/null; then
    log_info "Task '${name}' already registered — skipping"
    return 0
  fi

  # Append to Taskfile
  cat >>"$TASKFILE" <<EOF

  ${name}:
    desc: ${desc}
    cmds:
      - ${command}
EOF
  log_info "Task '${name}' registered"
}

# ==========================================
# Verify no orphan scripts
# ==========================================

verify_no_orphans() {
  local orphans=0

  # Scan scripts/ and .rdd/scripts/ only (not .claude/ — those are markdown skills)
  for dir in "scripts" ".rdd/scripts"; do
    if [ ! -d "${PROJECT_ROOT}/${dir}" ]; then continue; fi

    for script in "${PROJECT_ROOT}/${dir}"/*.sh; do
      [ -f "$script" ] || continue
      local name
      name=$(basename "$script")

      if ! grep -q "$name" "$TASKFILE" 2>/dev/null; then
        echo "  [WARN] Orphan script not in Taskfile: ${dir}/${name}"
        ((orphans++))
      fi
    done
  done

  if [ "$orphans" -gt 0 ]; then
    echo "  [FAIL] ${orphans} orphan script(s) found — all scripts must be registered as task entries"
    return 1
  fi

  log_info "All scripts registered in Taskfile"
  return 0
}

# ==========================================
# List orphan scripts
# ==========================================

list_orphans() {
  echo "Scanning for unregistered scripts..."
  echo ""

  local found=0
  for dir in "scripts" ".rdd/scripts"; do
    if [ ! -d "${PROJECT_ROOT}/${dir}" ]; then continue; fi

    for script in "${PROJECT_ROOT}/${dir}"/*.sh; do
      [ -f "$script" ] || continue
      local name
      name=$(basename "$script")

      if ! grep -q "$name" "$TASKFILE" 2>/dev/null; then
        echo "  NOT registered: ${dir}/${name}"
        ((found++))
      else
        echo "  OK: ${dir}/${name}"
      fi
    done
  done

  if [ "$found" -eq 0 ]; then
    log_info "No orphan scripts found"
  fi
}

# ==========================================
# Usage
# ==========================================

show_usage() {
  cat <<'EOF'
RDD Task Registry

Usage: task-registry.sh <command> [args]

Commands:
  register <name> <desc> <command>   Register new task in Taskfile.yml
  verify                              Check for orphan scripts (exit 1 if found)
  list-orphans                        List scripts not registered in Taskfile

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
    register) register_task "$@" ;;
    verify) verify_no_orphans ;;
    list-orphans) list_orphans ;;
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
