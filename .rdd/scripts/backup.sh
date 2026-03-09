#!/bin/bash
#
# RDD Backup Script
# Creates backups of RDD Framework data
#
# Usage: backup.sh [options]
#
# Options:
#   --output DIR    Output directory for backup (default: .rdd/backups)
#   --name NAME     Custom backup name
#   --compress      Compress backup (default: true)
#   --include-docs  Include docs directory (default: true)
#   --include-tests Include tests directory (default: false)
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
RDD_DIR="${RDD_DIR:-.rdd}"
OUTPUT_DIR="${RDD_DIR}/backups"
BACKUP_NAME=""
COMPRESS=true
INCLUDE_DOCS=true
INCLUDE_TESTS=false
QUIET=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            --no-compress)
                COMPRESS=false
                shift
                ;;
            --compress)
                COMPRESS=true
                shift
                ;;
            --include-docs)
                INCLUDE_DOCS=true
                shift
                ;;
            --no-docs)
                INCLUDE_DOCS=false
                shift
                ;;
            --include-tests)
                INCLUDE_TESTS=true
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
            *)
                echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
RDD Backup Script

Usage: backup.sh [options]

Options:
  --output DIR    Output directory for backup (default: .rdd/backups)
  --name NAME     Custom backup name
  --compress      Compress backup (default: true)
  --include-docs  Include docs directory (default: true)
  --include-tests Include tests directory (default: false)
  --quiet         Suppress output
  --help          Show this help

Examples:
  # Create backup with default settings
  backup.sh

  # Create backup with custom name
  backup.sh --name pre-upgrade

  # Create backup to specific directory
  backup.sh --output /backups

  # Create full backup including tests
  backup.sh --include-tests

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

# Create backup manifest
create_manifest() {
    local backup_dir="$1"
    local manifest_file="${backup_dir}/MANIFEST.json"

    cat > "$manifest_file" << EOF
{
  "version": "1.0.0",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hostname": "$(hostname 2>/dev/null || echo 'unknown')",
  "user": "${USER:-unknown}",
  "rdd_version": "$(cat "${RDD_DIR}/VERSION" 2>/dev/null | grep VERSION | cut -d= -f2 || echo 'unknown')",
  "components": {
    "rdd_dir": true,
    "docs": ${INCLUDE_DOCS},
    "tests": ${INCLUDE_TESTS}
  },
  "files": $(find "$backup_dir" -type f | wc -l),
  "size_bytes": $(du -sb "$backup_dir" 2>/dev/null | cut -f1 || echo '0')
}
EOF

    log_info "Created manifest: $manifest_file"
}

# Create backup
create_backup() {
    # Generate backup name if not specified
    if [[ -z "$BACKUP_NAME" ]]; then
        BACKUP_NAME="backup-$(date +%Y-%m-%d-%H%M%S)"
    fi

    local backup_path="${OUTPUT_DIR}/${BACKUP_NAME}"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Create backup directory
    mkdir -p "$backup_path"

    log_info "Creating backup: $backup_path"

    # Backup .rdd directory
    if [[ -d "$RDD_DIR" ]]; then
        log_info "Backing up .rdd directory..."
        cp -r "$RDD_DIR" "$backup_path/rdd"
    else
        log_warn ".rdd directory not found"
    fi

    # Backup docs directory
    if [[ "$INCLUDE_DOCS" == "true" && -d "docs" ]]; then
        log_info "Backing up docs directory..."
        cp -r docs "$backup_path/docs"
    fi

    # Backup tests directory
    if [[ "$INCLUDE_TESTS" == "true" && -d "tests" ]]; then
        log_info "Backing up tests directory..."
        cp -r tests "$backup_path/tests"
    fi

    # Backup Taskfile.yml
    if [[ -f "Taskfile.yml" ]]; then
        log_info "Backing up Taskfile.yml..."
        cp Taskfile.yml "$backup_path/"
    fi

    # Backup CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        log_info "Backing up CLAUDE.md..."
        cp CLAUDE.md "$backup_path/"
    fi

    # Backup AGENTS.md
    if [[ -f "AGENTS.md" ]]; then
        log_info "Backing up AGENTS.md..."
        cp AGENTS.md "$backup_path/"
    fi

    # Create manifest
    create_manifest "$backup_path"

    # Compress if requested
    if [[ "$COMPRESS" == "true" ]]; then
        log_info "Compressing backup..."
        tar -czf "${backup_path}.tar.gz" -C "$OUTPUT_DIR" "$BACKUP_NAME"
        rm -rf "$backup_path"
        backup_path="${backup_path}.tar.gz"
        log_info "Compressed: $backup_path"
    fi

    # Calculate size
    local size
    size=$(du -sh "$backup_path" 2>/dev/null | cut -f1 || echo 'unknown')

    log_info "Backup completed: $backup_path"
    log_info "Size: $size"

    # Output path for programmatic use
    echo "$backup_path"

    return 0
}

# Main
main() {
    parse_args "$@"
    create_backup
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
