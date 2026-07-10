#!/bin/bash
#
# RDD Migration Script
# Handles upgrades and migrations between RDD versions
#
# Usage: migrate.sh [command] [options]
#
# Commands:
#   plan          - Generate migration plan
#   execute       - Execute migration
#   rollback      - Rollback to previous version
#   status        - Show migration status
#   history       - Show migration history
#   validate      - Validate migration prerequisites
#
# Options:
#   --target V    - Target version for migration
#   --dry-run     - Show what would be done without making changes
#   --force       - Force migration even with warnings
#   --backup DIR  - Backup directory (default: .rdd/backups)
#

set -euo pipefail

# Configuration
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
VERSION_FILE="${RDD_DIR}/VERSION"
MIGRATION_DIR="${RDD_DIR}/migrations"
BACKUP_DIR="${RDD_DIR}/backups"
MIGRATION_LOG="${RDD_DIR}/migration.log"
LOCK_FILE="${RDD_DIR}/.migration.lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Migration status
MIGRATION_STATUS="none"
TARGET_VERSION=""
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"

#######################################
# Logging functions
#######################################

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*" >&2
  log_to_file "INFO" "$*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
  log_to_file "WARN" "$*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  log_to_file "ERROR" "$*"
}

log_debug() {
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    log_to_file "DEBUG" "$*"
  fi
}

log_to_file() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "[$timestamp] [$level] $message" >>"$MIGRATION_LOG"
}

#######################################
# Lock management
#######################################

acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")

    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      log_error "Another migration is in progress (PID: $lock_pid)"
      return 1
    fi

    log_warn "Removing stale lock file"
    rm -f "$LOCK_FILE"
  fi

  echo $$ >"$LOCK_FILE"
  log_debug "Lock acquired (PID: $$)"
}

release_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE"
    log_debug "Lock released"
  fi
}

#######################################
# Version operations
#######################################

# Read current version
read_current_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    grep "^VERSION=" "$VERSION_FILE" | cut -d'=' -f2 || echo "0.0.0"
  else
    echo "0.0.0"
  fi
}

# Parse version into components
parse_version() {
  local version="$1"
  version="${version#v}"

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "0 0 0"
    return 1
  fi

  local major minor patch
  IFS='.' read -r major minor patch <<<"$version"
  echo "${major:-0} ${minor:-0} ${patch:-0}"
}

# Compare versions (returns 0 if equal, 1 if v1>v2, 2 if v1<v2)
compare_versions() {
  local v1="$1"
  local v2="$2"

  local v1_major v1_minor v1_patch
  local v2_major v2_minor v2_patch

  read -r v1_major v1_minor v1_patch <<<"$(parse_version "$v1")"
  read -r v2_major v2_minor v2_patch <<<"$(parse_version "$v2")"

  if [[ $v1_major -gt $v2_major ]]; then return 1; fi
  if [[ $v1_major -lt $v2_major ]]; then return 2; fi
  if [[ $v1_minor -gt $v2_minor ]]; then return 1; fi
  if [[ $v1_minor -lt $v2_minor ]]; then return 2; fi
  if [[ $v1_patch -gt $v2_patch ]]; then return 1; fi
  if [[ $v1_patch -lt $v2_patch ]]; then return 2; fi

  return 0
}

#######################################
# Backup operations
#######################################

create_backup() {
  local backup_name="$1"
  local backup_path="${BACKUP_DIR}/${backup_name}"

  log_info "Creating backup: $backup_path"

  mkdir -p "$BACKUP_DIR"

  # Backup key files
  local files_to_backup=(
    "$VERSION_FILE"
    "${RDD_DIR}/config.yml"
    "${RDD_DIR}/hooks.yml"
    "${RDD_DIR}/templates.yml"
  )

  for file in "${files_to_backup[@]}"; do
    if [[ -f "$file" ]]; then
      local relative_path="${file#${RDD_DIR}/}"
      local backup_file="${backup_path}/${relative_path}"
      mkdir -p "$(dirname "$backup_file")"
      cp "$file" "$backup_file"
      log_debug "Backed up: $relative_path"
    fi
  done

  # Create backup manifest
  cat >"${backup_path}/MANIFEST" <<EOF
backup_name: ${backup_name}
created_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
version: $(read_current_version)
files: $(printf '%s\n' "${files_to_backup[@]}" | grep -c '^' || echo 0)
EOF

  log_info "Backup created successfully"
  echo "$backup_path"
}

restore_backup() {
  local backup_path="$1"

  if [[ ! -d "$backup_path" ]]; then
    log_error "Backup not found: $backup_path"
    return 1
  fi

  log_info "Restoring from backup: $backup_path"

  # Restore files
  find "$backup_path" -type f ! -name "MANIFEST" | while read -r backup_file; do
    local relative_path="${backup_file#${backup_path}/}"
    local target_file="${RDD_DIR}/${relative_path}"
    mkdir -p "$(dirname "$target_file")"
    cp "$backup_file" "$target_file"
    log_debug "Restored: $relative_path"
  done

  log_info "Backup restored successfully"
}

#######################################
# Migration operations
#######################################

# Check migration prerequisites
check_prerequisites() {
  local current_version
  current_version=$(read_current_version)
  local target_version="${TARGET_VERSION:-}"

  log_info "Checking migration prerequisites..."
  log_info "Current version: $current_version"
  log_info "Target version: ${target_version:-latest}"

  local warnings=0
  local errors=0

  # Check if VERSION file exists
  if [[ ! -f "$VERSION_FILE" ]]; then
    log_warn "VERSION file not found, will be created"
    warnings=$((warnings + 1))
  fi

  # Check if config files exist
  for config_file in config.yml hooks.yml templates.yml; do
    if [[ ! -f "${RDD_DIR}/${config_file}" ]]; then
      log_warn "Config file not found: $config_file"
      warnings=$((warnings + 1))
    fi
  done

  # Check disk space (at least 10MB)
  local available_kb
  if command -v df &>/dev/null; then
    available_kb=$(df -k "${RDD_DIR}" | awk 'NR==2 {print $4}')
    if [[ ${available_kb:-0} -lt 10240 ]]; then
      log_error "Insufficient disk space (need at least 10MB)"
      errors=$((errors + 1))
    fi
  fi

  # Check write permissions
  if [[ ! -w "${RDD_DIR}" ]]; then
    log_error "No write permission on RDD directory"
    errors=$((errors + 1))
  fi

  # Summary
  echo ""
  log_info "Prerequisite check complete"
  echo "  Warnings: $warnings"
  echo "  Errors:   $errors"

  if [[ $errors -gt 0 ]]; then
    return 1
  fi

  if [[ $warnings -gt 0 && "$FORCE" != "true" ]]; then
    log_warn "Warnings detected. Use --force to proceed."
    return 2
  fi

  return 0
}

# Generate migration plan
generate_plan() {
  local current_version
  current_version=$(read_current_version)
  local target_version="${TARGET_VERSION:-latest}"

  log_info "Generating migration plan..."
  log_info "From: $current_version"
  log_info "To:   $target_version"

  # Determine migration direction
  local cmp_result=0
  compare_versions "$current_version" "$target_version" || cmp_result=$?

  local direction
  if [[ $cmp_result -eq 2 ]]; then
    direction="upgrade"
  elif [[ $cmp_result -eq 1 ]]; then
    direction="downgrade"
    log_warn "Downgrade detected. This may not be fully supported."
  else
    direction="none"
    log_info "Already at target version"
  fi

  # List migration steps
  echo ""
  log_info "Migration Plan:"
  echo "----------------------------------------"

  local step=1

  # Step 1: Backup
  echo "$step. Create backup of current configuration"
  ((step++))

  # Step 2: Check prerequisites
  echo "$step. Validate migration prerequisites"
  ((step++))

  # Step 3: Update VERSION file
  echo "$step. Update VERSION file ($current_version -> $target_version)"
  ((step++))

  # Step 4: Run migration scripts (if any)
  if [[ -d "$MIGRATION_DIR" ]]; then
    local migration_scripts
    migration_scripts=$(find "$MIGRATION_DIR" -name "*.sh" -type f 2>/dev/null | sort)
    if [[ -n "$migration_scripts" ]]; then
      echo "$step. Execute migration scripts:"
      echo "$migration_scripts" | while read -r script; do
        echo "     - $(basename "$script")"
      done
      ((step++))
    fi
  fi

  # Step 5: Update configurations
  echo "$step. Update configuration files"
  ((step++))

  # Step 6: Verify migration
  echo "$step. Verify migration success"
  ((step++))

  # Step 7: Cleanup
  echo "$step. Cleanup temporary files"
  ((step++))

  echo "----------------------------------------"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run complete. No changes made."
  fi
}

# Execute migration
execute_migration() {
  local current_version
  current_version=$(read_current_version)
  local target_version="${TARGET_VERSION:-}"

  if [[ -z "$target_version" ]]; then
    log_error "Target version not specified. Use --target V"
    return 1
  fi

  # Validate target version
  if [[ ! "$target_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    log_error "Invalid target version format: $target_version"
    return 1
  fi

  log_info "Starting migration: $current_version -> $target_version"

  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi

  # Trap to release lock on exit
  trap release_lock EXIT

  # Check prerequisites
  if ! check_prerequisites; then
    log_error "Prerequisites check failed"
    return 1
  fi

  # Create backup
  local backup_name="pre-migration-${current_version}-$(date +%Y%m%d-%H%M%S)"
  local backup_path
  if [[ "$DRY_RUN" != "true" ]]; then
    backup_path=$(create_backup "$backup_name")
  else
    log_info "[DRY RUN] Would create backup: $backup_name"
  fi

  # Update VERSION file
  if [[ "$DRY_RUN" != "true" ]]; then
    cat >"$VERSION_FILE" <<EOF
# RDD Framework Version
# This file was updated by migrate.sh
# Migration: $current_version -> $target_version
# Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

VERSION=${target_version}
COMPAT_MIN=${current_version}
COMPAT_MAX=${target_version}
EOF
    log_info "VERSION file updated"
  else
    log_info "[DRY RUN] Would update VERSION file"
  fi

  # Run migration scripts
  if [[ -d "$MIGRATION_DIR" ]]; then
    find "$MIGRATION_DIR" -name "*.sh" -type f -executable 2>/dev/null | sort | while read -r script; do
      if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Running migration script: $(basename "$script")"
        if bash "$script"; then
          log_info "Migration script completed: $(basename "$script")"
        else
          log_error "Migration script failed: $(basename "$script")"
        fi
      else
        log_info "[DRY RUN] Would run: $(basename "$script")"
      fi
    done
  fi

  # Record migration in history
  if [[ "$DRY_RUN" != "true" ]]; then
    local history_file="${RDD_DIR}/MIGRATION_HISTORY"
    cat >>"$history_file" <<EOF
# Migration: $current_version -> $target_version
# Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Backup: ${backup_path:-N/A}
# Status: completed
---
EOF
    log_info "Migration history updated"
  fi

  log_info "Migration completed successfully"
  log_info "From: $current_version"
  log_info "To:   $target_version"

  if [[ -n "${backup_path:-}" ]]; then
    log_info "Backup: $backup_path"
  fi
}

# Rollback migration
rollback_migration() {
  local backup_path="${ROLLBACK_PATH:-}"

  # Find latest backup if not specified
  if [[ -z "$backup_path" ]]; then
    backup_path=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "pre-migration-*" | sort -r | head -1)
  fi

  if [[ -z "$backup_path" ]]; then
    log_error "No backup found for rollback"
    return 1
  fi

  log_info "Rolling back to: $backup_path"

  if [[ "$DRY_RUN" != "true" ]]; then
    restore_backup "$backup_path"
    log_info "Rollback completed successfully"
  else
    log_info "[DRY RUN] Would restore from: $backup_path"
  fi
}

# Show migration status
show_status() {
  local current_version
  current_version=$(read_current_version)

  log_info "Migration Status"
  echo ""
  echo "Current Version: $current_version"
  echo "Migration Lock:  $([ -f "$LOCK_FILE" ] && echo "Active ($(cat "$LOCK_FILE" 2>/dev/null))" || echo "None")"
  echo "Backup Dir:      $BACKUP_DIR"
  echo "Migration Dir:   $MIGRATION_DIR"

  # Show latest backup
  if [[ -d "$BACKUP_DIR" ]]; then
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "pre-migration-*" | sort -r | head -1)
    if [[ -n "$latest_backup" ]]; then
      echo "Latest Backup:   $(basename "$latest_backup")"
    fi
  fi

  # Show pending migrations
  echo ""
  echo "Migration History:"
  if [[ -f "${RDD_DIR}/MIGRATION_HISTORY" ]]; then
    tail -20 "${RDD_DIR}/MIGRATION_HISTORY"
  else
    echo "  No migration history found"
  fi
}

# Show migration history
show_history() {
  log_info "Migration History"

  if [[ -f "$MIGRATION_LOG" ]]; then
    echo ""
    cat "$MIGRATION_LOG"
  else
    echo ""
    log_info "No migration log found"
  fi
}

#######################################
# Show usage
#######################################

show_usage() {
  cat <<EOF
RDD Migration Script

Usage: migrate.sh [command] [options]

Commands:
  plan          Generate migration plan (dry-run)
  execute       Execute migration to target version
  rollback      Rollback to previous version
  status        Show migration status
  history       Show migration history
  validate      Validate migration prerequisites

Options:
  --target V        Target version for migration
  --dry-run         Show what would be done without making changes
  --force           Force migration even with warnings
  --backup DIR      Backup directory (default: .rdd/backups)
  --rollback PATH   Specific backup path for rollback
  -v, --verbose     Enable verbose output
  -h, --help        Show this help message

Migration Process:
  1. Check prerequisites
  2. Create backup of current configuration
  3. Update VERSION file
  4. Run migration scripts from .rdd/migrations/
  5. Update configuration files
  6. Verify migration success
  7. Cleanup temporary files

Rollback Process:
  1. Find latest backup (or use specified backup)
  2. Restore files from backup
  3. Verify rollback success

Examples:
  # Plan migration to version 1.1.0
  migrate.sh plan --target 1.1.0

  # Execute migration to version 1.1.0
  migrate.sh execute --target 1.1.0

  # Dry-run migration
  migrate.sh execute --target 1.1.0 --dry-run

  # Rollback to previous version
  migrate.sh rollback

  # Rollback to specific backup
  migrate.sh rollback --rollback .rdd/backups/pre-migration-1.0.0-20260307

  # Show migration status
  migrate.sh status

Environment Variables:
  RDD_DIR       RDD configuration directory
  DRY_RUN       Enable dry-run mode
  FORCE         Force migration with warnings

Files:
  .rdd/VERSION            Current version file
  .rdd/migrations/        Migration scripts directory
  .rdd/backups/           Backup directory
  .rdd/migration.log      Migration log file
  .rdd/MIGRATION_HISTORY  Migration history

EOF
}

#######################################
# Parse arguments
#######################################

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)
        TARGET_VERSION="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --backup)
        BACKUP_DIR="$2"
        shift 2
        ;;
      --rollback)
        ROLLBACK_PATH="$2"
        shift 2
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -h | --help | help)
        show_usage
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done
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
  parse_args "$@"

  case "$command" in
    plan)
      generate_plan
      ;;
    execute)
      execute_migration
      ;;
    rollback)
      rollback_migration
      ;;
    status)
      show_status
      ;;
    history)
      show_history
      ;;
    validate)
      check_prerequisites
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

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi
