#!/bin/bash
#
# RDD Restore Script
# Restores RDD Framework from backup
#
# Usage: restore.sh [options] BACKUP_FILE
#
# Options:
#   --target DIR    Target directory (default: current directory)
#   --force         Force restore even if version mismatch
#   --dry-run       Show what would be restored without making changes
#   --quiet         Suppress output
#   --help          Show this help
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
TARGET_DIR="."
BACKUP_FILE=""
FORCE=false
DRY_RUN=false
QUIET=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                TARGET_DIR="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                BACKUP_FILE="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$BACKUP_FILE" ]]; then
        echo -e "${RED}[ERROR]${NC} Backup file is required" >&2
        show_help
        exit 1
    fi
}

show_help() {
    cat << 'EOF'
RDD Restore Script

Usage: restore.sh [options] BACKUP_FILE

Options:
  --target DIR    Target directory (default: current directory)
  --force         Force restore even if version mismatch
  --dry-run       Show what would be restored without making changes
  --quiet         Suppress output
  --help          Show this help

Examples:
  # Restore from backup
  restore.sh .rdd/backups/backup-2026-03-08.tar.gz

  # Restore to specific directory
  restore.sh --target /path/to/project backup.tar.gz

  # Dry run to see what would be restored
  restore.sh --dry-run backup.tar.gz

EOF
}

log_info() {
    [[ "$QUIET" == "true" ]] || echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    [[ "$QUIET" == "true" ]] || echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check version compatibility
check_version() {
    local backup_version="$1"
    local current_version

    current_version=$(cat "${TARGET_DIR}/.rdd/VERSION" 2>/dev/null | grep VERSION | cut -d= -f2 || echo 'unknown')

    if [[ "$backup_version" != "$current_version" && "$FORCE" != "true" ]]; then
        log_error "Version mismatch: backup=$backup_version, current=$current_version"
        log_error "Use --force to override"
        return 1
    fi

    if [[ "$backup_version" != "$current_version" ]]; then
        log_warn "Version mismatch (forced): backup=$backup_version, current=$current_version"
    fi

    return 0
}

# Extract backup
extract_backup() {
    local backup_file="$1"
    local extract_dir="$2"

    if [[ "$backup_file" == *.tar.gz || "$backup_file" == *.tgz ]]; then
        log_info "Extracting compressed backup..."
        tar -xzf "$backup_file" -C "$extract_dir"
    elif [[ -d "$backup_file" ]]; then
        log_info "Copying backup directory..."
        cp -r "$backup_file"/* "$extract_dir/"
    else
        log_error "Unknown backup format: $backup_file"
        return 1
    fi

    return 0
}

# Restore backup
restore_backup() {
    local temp_dir
    temp_dir=$(mktemp -d)

    trap "rm -rf '$temp_dir'" EXIT

    # Extract backup
    if ! extract_backup "$BACKUP_FILE" "$temp_dir"; then
        return 1
    fi

    # Find extracted content
    local backup_content="$temp_dir"
    if [[ -d "${temp_dir}/$(basename "${BACKUP_FILE%.tar.gz}")" ]]; then
        backup_content="${temp_dir}/$(basename "${BACKUP_FILE%.tar.gz}")"
    fi

    # Read manifest
    local manifest_file="${backup_content}/MANIFEST.json"
    if [[ -f "$manifest_file" ]]; then
        log_info "Reading backup manifest..."

        if command -v jq &> /dev/null; then
            local backup_version
            backup_version=$(jq -r '.rdd_version // "unknown"' "$manifest_file")
            local created_at
            created_at=$(jq -r '.created_at // "unknown"' "$manifest_file")

            log_info "Backup created: $created_at"
            log_info "Backup version: $backup_version"

            if ! check_version "$backup_version"; then
                return 1
            fi
        fi
    else
        log_warn "No manifest found in backup"
    fi

    # Dry run - just show what would be restored
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would restore the following:"
        find "$backup_content" -type f | while read -r file; do
            echo "  - ${file#$backup_content/}"
        done
        return 0
    fi

    # Create target directory
    mkdir -p "$TARGET_DIR"

    # Restore .rdd directory
    if [[ -d "${backup_content}/rdd" ]]; then
        log_info "Restoring .rdd directory..."
        rm -rf "${TARGET_DIR}/.rdd"
        cp -r "${backup_content}/rdd" "${TARGET_DIR}/.rdd"
    fi

    # Restore docs directory
    if [[ -d "${backup_content}/docs" ]]; then
        log_info "Restoring docs directory..."
        rm -rf "${TARGET_DIR}/docs"
        cp -r "${backup_content}/docs" "${TARGET_DIR}/docs"
    fi

    # Restore tests directory
    if [[ -d "${backup_content}/tests" ]]; then
        log_info "Restoring tests directory..."
        rm -rf "${TARGET_DIR}/tests"
        cp -r "${backup_content}/tests" "${TARGET_DIR}/tests"
    fi

    # Restore Taskfile.yml
    if [[ -f "${backup_content}/Taskfile.yml" ]]; then
        log_info "Restoring Taskfile.yml..."
        cp "${backup_content}/Taskfile.yml" "${TARGET_DIR}/"
    fi

    # Restore CLAUDE.md
    if [[ -f "${backup_content}/CLAUDE.md" ]]; then
        log_info "Restoring CLAUDE.md..."
        cp "${backup_content}/CLAUDE.md" "${TARGET_DIR}/"
    fi

    # Restore AGENTS.md
    if [[ -f "${backup_content}/AGENTS.md" ]]; then
        log_info "Restoring AGENTS.md..."
        cp "${backup_content}/AGENTS.md" "${TARGET_DIR}/"
    fi

    log_info "Restore completed to: $TARGET_DIR"

    return 0
}

# Main
main() {
    parse_args "$@"
    restore_backup
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
