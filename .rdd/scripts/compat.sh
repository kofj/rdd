#!/bin/bash
#
# RDD Compatibility Checker Script
# Validates configuration compatibility and checks for breaking changes
#
# Usage: compat.sh [command] [options]
#
# Commands:
#   check         - Check configuration compatibility
#   validate      - Validate configuration schema
#   breaking      - Check for breaking changes
#   deprecations  - Show deprecation warnings
#   fix           - Auto-fix compatibility issues
#   report        - Generate compatibility report
#
# Options:
#   --config F    - Configuration file to check
#   --version V   - Target version for compatibility check
#   --fix         - Apply auto-fixes where possible
#   --format FMT  - Output format: text, json (default: text)
#

set -euo pipefail

# Configuration
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
CONFIG_FILE="${CONFIG_FILE:-${RDD_DIR}/config.yml}"
HOOKS_FILE="${HOOKS_FILE:-${RDD_DIR}/hooks.yml}"
TEMPLATES_FILE="${TEMPLATES_FILE:-${RDD_DIR}/templates.yml}"
VERSION_FILE="${VERSION_FILE:-${RDD_DIR}/VERSION}"
COMPAT_FILE="${RDD_DIR}/compatibility.json"

# Output settings
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check results
COMPAT_ISSUES=()
COMPAT_WARNINGS=()
COMPAT_INFO=()

#######################################
# Logging functions
#######################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

add_issue() {
    COMPAT_ISSUES+=("$1")
}

add_warning() {
    COMPAT_WARNINGS+=("$1")
}

add_info() {
    COMPAT_INFO+=("$1")
}

#######################################
# Version operations
#######################################

read_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        grep "^VERSION=" "$VERSION_FILE" | cut -d'=' -f2 || echo "0.0.0"
    else
        echo "0.0.0"
    fi
}

parse_version() {
    local version="$1"
    version="${version#v}"
    IFS='.' read -r major minor patch <<< "$version"
    echo "${major:-0} ${minor:-0} ${patch:-0}"
}

compare_versions() {
    local v1="$1"
    local v2="$2"

    local v1_major v1_minor v1_patch
    local v2_major v2_minor v2_patch

    read -r v1_major v1_minor v1_patch <<< "$(parse_version "$v1")"
    read -r v2_major v2_minor v2_patch <<< "$(parse_version "$v2")"

    if [[ $v1_major -gt $v2_major ]]; then return 1; fi
    if [[ $v1_major -lt $v2_major ]]; then return 2; fi
    if [[ $v1_minor -gt $v2_minor ]]; then return 1; fi
    if [[ $v1_minor -lt $v2_minor ]]; then return 2; fi
    if [[ $v1_patch -gt $v2_patch ]]; then return 1; fi
    if [[ $v1_patch -lt $v2_patch ]]; then return 2; fi

    return 0
}

#######################################
# YAML validation helpers
#######################################

# Check if yq is available
has_yq() {
    command -v yq &> /dev/null
}

# Get YAML value (simple implementation without yq)
get_yaml_value() {
    local file="$1"
    local path="$2"
    local default="${3:-}"

    if [[ ! -f "$file" ]]; then
        echo "$default"
        return 1
    fi

    if has_yq; then
        yq eval ".${path}" "$file" 2>/dev/null || echo "$default"
    else
        # Simple fallback for basic key-value pairs
        local key="${path##*.}"
        grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed 's/[^:]*: *//' | tr -d '"' || echo "$default"
    fi
}

# Check if key exists in YAML
yaml_key_exists() {
    local file="$1"
    local path="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if has_yq; then
        yq eval ".${path}" "$file" 2>/dev/null | grep -qv 'null'
    else
        local key="${path##*.}"
        grep -qE "^${key}:" "$file" 2>/dev/null
    fi
}

#######################################
# Configuration validators
#######################################

# Validate config.yml
validate_config() {
    log_info "Validating config.yml..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        add_issue "config.yml not found"
        return 1
    fi

    local current_version
    current_version=$(read_current_version)

    # Check required fields
    local required_fields=(
        "version"
        "project"
        "stage.min_coverage"
        "stage.max_failures"
        "stage.tech_debt_threshold"
        "gates.design_required"
        "gates.review_required"
        "gates.e2e_required"
        "gates.docs_required"
    )

    for field in "${required_fields[@]}"; do
        if ! yaml_key_exists "$CONFIG_FILE" "$field"; then
            add_warning "Missing recommended field: $field"
        fi
    done

    # Validate version format
    local config_version
    config_version=$(get_yaml_value "$CONFIG_FILE" "version" "0.0.0")

    if [[ ! "$config_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        add_warning "Invalid version format in config.yml: $config_version"
    fi

    # Validate min_coverage
    local min_coverage
    min_coverage=$(get_yaml_value "$CONFIG_FILE" "stage.min_coverage" "20")

    if [[ ! "$min_coverage" =~ ^[0-9]+$ ]] || [[ "$min_coverage" -lt 0 ]] || [[ "$min_coverage" -gt 100 ]]; then
        add_issue "Invalid min_coverage value: $min_coverage (must be 0-100)"
    fi

    # Validate max_failures
    local max_failures
    max_failures=$(get_yaml_value "$CONFIG_FILE" "stage.max_failures" "3")

    if [[ ! "$max_failures" =~ ^[0-9]+$ ]] || [[ "$max_failures" -lt 1 ]]; then
        add_warning "Invalid max_failures value: $max_failures (should be >= 1)"
    fi

    log_debug "config.yml validation complete"
}

# Validate hooks.yml
validate_hooks() {
    log_info "Validating hooks.yml..."

    if [[ ! -f "$HOOKS_FILE" ]]; then
        add_info "hooks.yml not found (hooks disabled)"
        return 0
    fi

    # Check triggers section
    if ! yaml_key_exists "$HOOKS_FILE" "triggers"; then
        add_warning "Missing triggers section in hooks.yml"
    fi

    # Check channels section
    if ! yaml_key_exists "$HOOKS_FILE" "channels"; then
        add_warning "Missing channels section in hooks.yml"
    fi

    # Validate trigger configurations
    local trigger_types=(
        "roadmap_change"
        "consecutive_failure"
        "hypothesis_invalid"
        "model_disagreement"
        "tech_debt_threshold"
        "stage_complete"
        "daily_report"
        "weekly_report"
    )

    for trigger in "${trigger_types[@]}"; do
        if yaml_key_exists "$HOOKS_FILE" "triggers.${trigger}"; then
            local enabled
            enabled=$(get_yaml_value "$HOOKS_FILE" "triggers.${trigger}.enabled" "false")

            if [[ "$enabled" == "true" ]]; then
                log_debug "Trigger enabled: $trigger"

                # Check channels
                if ! yaml_key_exists "$HOOKS_FILE" "triggers.${trigger}.channels"; then
                    add_warning "Trigger $trigger enabled but no channels configured"
                fi
            fi
        fi
    done

    # Validate channel configurations
    local channel_types=("wecom" "email" "bark" "telegram" "webhook")

    for channel in "${channel_types[@]}"; do
        if yaml_key_exists "$HOOKS_FILE" "channels.${channel}"; then
            local enabled
            enabled=$(get_yaml_value "$HOOKS_FILE" "channels.${channel}.enabled" "false")

            if [[ "$enabled" == "true" ]]; then
                log_debug "Channel enabled: $channel"

                case "$channel" in
                    wecom)
                        if ! yaml_key_exists "$HOOKS_FILE" "channels.${channel}.webhook_url"; then
                            add_warning "WeChat channel enabled but webhook_url not configured"
                        fi
                        ;;
                    email)
                        if ! yaml_key_exists "$HOOKS_FILE" "channels.${channel}.smtp_host"; then
                            add_warning "Email channel enabled but smtp_host not configured"
                        fi
                        ;;
                    telegram)
                        if ! yaml_key_exists "$HOOKS_FILE" "channels.${channel}.bot_token"; then
                            add_warning "Telegram channel enabled but bot_token not configured"
                        fi
                        ;;
                esac
            fi
        fi
    done

    log_debug "hooks.yml validation complete"
}

# Validate templates.yml
validate_templates() {
    log_info "Validating templates.yml..."

    if [[ ! -f "$TEMPLATES_FILE" ]]; then
        add_warning "templates.yml not found"
        return 0
    fi

    # Check templates section
    if ! yaml_key_exists "$TEMPLATES_FILE" "templates"; then
        add_warning "Missing templates section in templates.yml"
    fi

    log_debug "templates.yml validation complete"
}

# Validate VERSION file
validate_version_file() {
    log_info "Validating VERSION file..."

    if [[ ! -f "$VERSION_FILE" ]]; then
        add_issue "VERSION file not found"
        return 1
    fi

    local version
    version=$(read_current_version)

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        add_issue "Invalid version format in VERSION file: $version"
    fi

    # Check compatibility range
    local compat_min compat_max
    compat_min=$(get_yaml_value "$VERSION_FILE" "COMPAT_MIN" "0.0.0")
    compat_max=$(get_yaml_value "$VERSION_FILE" "COMPAT_MAX" "99.99.99")

    log_debug "VERSION file validation complete"
}

#######################################
# Breaking change detection
#######################################

# Define breaking changes by version
declare -A BREAKING_CHANGES=(
    ["1.0.0"]="Initial stable release"
    ["1.1.0"]="Added notification templates"
    ["1.2.0"]="Changed hooks configuration format"
    ["2.0.0"]="Major configuration restructuring"
)

check_breaking_changes() {
    local from_version="$1"
    local to_version="$2"

    log_info "Checking for breaking changes..."
    log_info "From: $from_version"
    log_info "To:   $to_version"

    local has_breaking=false

    for version in "${!BREAKING_CHANGES[@]}"; do
        # Check if version is between from and to
        local after_from before_to
        compare_versions "$version" "$from_version" || after_from=$?
        compare_versions "$version" "$to_version" || before_to=$?

        if [[ ${after_from:-0} -eq 1 ]] && [[ ${before_to:-0} -eq 2 || ${before_to:-0} -eq 0 ]]; then
            add_warning "Breaking change in $version: ${BREAKING_CHANGES[$version]}"
            has_breaking=true
        fi
    done

    if [[ "$has_breaking" == "true" ]]; then
        log_warn "Breaking changes detected. Review migration guide."
    else
        log_info "No breaking changes detected"
    fi
}

#######################################
# Deprecation checks
#######################################

# Define deprecated features
declare -A DEPRECATIONS=(
    ["old_config_format"]="Deprecated in 1.1.0, removed in 2.0.0"
    ["legacy_hooks"]="Deprecated in 1.2.0, removed in 2.0.0"
)

check_deprecations() {
    log_info "Checking for deprecated features..."

    # Check for old config format
    if [[ -f "${RDD_DIR}/.rddrc" ]]; then
        add_warning "Deprecated: .rddrc file found. Use config.yml instead."
    fi

    # Check for legacy hooks directory
    if [[ -d "${RDD_DIR}/old_hooks" ]]; then
        add_warning "Deprecated: old_hooks directory found. Use hooks/ instead."
    fi

    log_debug "Deprecation check complete"
}

#######################################
# Auto-fix functions
#######################################

auto_fix_issues() {
    log_info "Applying auto-fixes..."

    local fixed=0

    # Fix missing VERSION file
    if [[ ! -f "$VERSION_FILE" ]]; then
        log_info "Creating VERSION file..."
        cat > "$VERSION_FILE" <<EOF
VERSION=0.1.0
COMPAT_MIN=0.1.0
COMPAT_MAX=1.0.0
EOF
        fixed=$((fixed + 1))
    fi

    # Fix missing config.yml
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "Creating default config.yml..."
        cat > "$CONFIG_FILE" <<EOF
version: "1.0.0"
project:
  name: ""
  description: ""

stage:
  min_coverage: 20
  max_failures: 3
  tech_debt_threshold: 3

gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

hooks:
  enabled: false

notifications:
  quiet_hours:
    enabled: false
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true
EOF
        fixed=$((fixed + 1))
    fi

    # Fix missing hooks.yml
    if [[ ! -f "$HOOKS_FILE" ]]; then
        log_info "Creating default hooks.yml..."
        cat > "$HOOKS_FILE" <<EOF
# RDD Hooks Configuration
# See documentation for all available triggers and channels

triggers:
  stage_complete:
    enabled: false
    channels:
      - wecom

channels:
  wecom:
    enabled: false
    webhook_url: ""

retry:
  max_attempts: 3
  initial_delay: "1s"
  max_delay: "30s"
EOF
        fixed=$((fixed + 1))
    fi

    log_info "Auto-fixed $fixed issue(s)"
}

#######################################
# Report generation
#######################################

generate_report() {
    local format="${OUTPUT_FORMAT:-text}"
    local current_version
    current_version=$(read_current_version)

    if [[ "$format" == "json" ]]; then
        # JSON output
        local issues_json warnings_json info_json

        issues_json=$(printf '%s\n' "${COMPAT_ISSUES[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
        warnings_json=$(printf '%s\n' "${COMPAT_WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
        info_json=$(printf '%s\n' "${COMPAT_INFO[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")

        cat <<EOF
{
  "version": "${current_version}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "issues": ${issues_json},
  "warnings": ${warnings_json},
  "info": ${info_json},
  "summary": {
    "issues": ${#COMPAT_ISSUES[@]},
    "warnings": ${#COMPAT_WARNINGS[@]},
    "info": ${#COMPAT_INFO[@]},
    "passed": $([[ ${#COMPAT_ISSUES[@]} -eq 0 ]] && echo "true" || echo "false")
  }
}
EOF
    else
        # Text output
        echo ""
        echo "=========================================="
        echo "RDD Compatibility Report"
        echo "=========================================="
        echo ""
        echo "Version:     $current_version"
        echo "Timestamp:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo ""

        # Issues
        if [[ ${#COMPAT_ISSUES[@]} -gt 0 ]]; then
            echo "Issues (${#COMPAT_ISSUES[@]}):"
            for issue in "${COMPAT_ISSUES[@]}"; do
                echo "  [ERROR] $issue"
            done
            echo ""
        fi

        # Warnings
        if [[ ${#COMPAT_WARNINGS[@]} -gt 0 ]]; then
            echo "Warnings (${#COMPAT_WARNINGS[@]}):"
            for warning in "${COMPAT_WARNINGS[@]}"; do
                echo "  [WARN] $warning"
            done
            echo ""
        fi

        # Info
        if [[ ${#COMPAT_INFO[@]} -gt 0 ]]; then
            echo "Info (${#COMPAT_INFO[@]}):"
            for info in "${COMPAT_INFO[@]}"; do
                echo "  [INFO] $info"
            done
            echo ""
        fi

        # Summary
        echo "=========================================="
        echo "Summary"
        echo "=========================================="
        echo "Issues:    ${#COMPAT_ISSUES[@]}"
        echo "Warnings:  ${#COMPAT_WARNINGS[@]}"
        echo "Info:      ${#COMPAT_INFO[@]}"
        echo ""

        if [[ ${#COMPAT_ISSUES[@]} -eq 0 ]]; then
            log_info "All compatibility checks passed!"
        else
            log_error "${#COMPAT_ISSUES[@]} issue(s) need to be resolved"
        fi
    fi
}

#######################################
# Commands
#######################################

cmd_check() {
    log_info "Running compatibility check..."

    validate_version_file
    validate_config
    validate_hooks
    validate_templates

    generate_report

    [[ ${#COMPAT_ISSUES[@]} -eq 0 ]]
}

cmd_validate() {
    local file="${VALIDATE_FILE:-}"

    if [[ -z "$file" ]]; then
        log_error "File not specified. Use --config F"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    log_info "Validating: $file"

    case "$file" in
        */config.yml)
            CONFIG_FILE="$file"
            validate_config
            ;;
        */hooks.yml)
            HOOKS_FILE="$file"
            validate_hooks
            ;;
        */templates.yml)
            TEMPLATES_FILE="$file"
            validate_templates
            ;;
        */VERSION)
            VERSION_FILE="$file"
            validate_version_file
            ;;
        *)
            add_warning "Unknown file type: $file"
            ;;
    esac

    generate_report
}

cmd_breaking() {
    local from="${FROM_VERSION:-}"
    local to="${TO_VERSION:-$(read_current_version)}"

    if [[ -z "$from" ]]; then
        from=$(read_current_version)
    fi

    check_breaking_changes "$from" "$to"

    if [[ ${#COMPAT_WARNINGS[@]} -gt 0 ]]; then
        generate_report
        return 1
    fi

    return 0
}

cmd_deprecations() {
    check_deprecations
    generate_report
}

cmd_fix() {
    auto_fix_issues
    cmd_check
}

#######################################
# Show usage
#######################################

show_usage() {
    cat << EOF
RDD Compatibility Checker Script

Usage: compat.sh [command] [options]

Commands:
  check         Run full compatibility check
  validate      Validate a specific configuration file
  breaking      Check for breaking changes between versions
  deprecations  Show deprecation warnings
  fix           Auto-fix compatibility issues
  report        Generate compatibility report

Options:
  --config F        Configuration file to validate
  --from V          From version (for breaking change check)
  --to V            To version (for breaking change check)
  --fix             Apply auto-fixes after check
  --format FMT      Output format: text, json (default: text)
  -v, --verbose     Enable verbose output
  -h, --help        Show this help message

Compatibility Checks:
  - VERSION file format and content
  - config.yml schema validation
  - hooks.yml trigger and channel configuration
  - templates.yml template definitions
  - Breaking changes between versions
  - Deprecated features

Breaking Change Detection:
  Checks for breaking changes when migrating between versions.
  Breaking changes are defined in the script.

Deprecation Warnings:
  Checks for deprecated features that will be removed in future versions.
  Provides migration guidance for each deprecation.

Auto-fix:
  Creates missing configuration files with defaults.
  Does not modify existing files.

Examples:
  # Run full compatibility check
  compat.sh check

  # Validate specific file
  compat.sh validate --config .rdd/config.yml

  # Check for breaking changes
  compat.sh breaking --from 1.0.0 --to 1.2.0

  # Auto-fix and check
  compat.sh fix

  # JSON output
  compat.sh check --format json

Environment Variables:
  RDD_DIR       RDD configuration directory
  OUTPUT_FORMAT Output format (text, json)

Files:
  .rdd/VERSION       Version file
  .rdd/config.yml    Main configuration
  .rdd/hooks.yml     Hooks configuration
  .rdd/templates.yml Templates configuration

EOF
}

#######################################
# Parse arguments
#######################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --config)
                VALIDATE_FILE="$2"
                shift 2
                ;;
            --from)
                FROM_VERSION="$2"
                shift 2
                ;;
            --to)
                TO_VERSION="$2"
                shift 2
                ;;
            --fix)
                AUTO_FIX=true
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help|help)
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
        check)
            cmd_check
            ;;
        validate)
            cmd_validate
            ;;
        breaking)
            cmd_breaking
            ;;
        deprecations)
            cmd_deprecations
            ;;
        fix)
            cmd_fix
            ;;
        report)
            generate_report
            ;;
        -h|--help|help)
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