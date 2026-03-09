#!/bin/bash
#
# RDD Security Configuration Checker
# Validates security settings and reports issues
#
# Usage: security-check.sh [options]
#
# Options:
#   --fix        Automatically fix fixable issues
#   --verbose    Show detailed output
#   --json       Output in JSON format
#   --quiet      Only show errors
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PERMISSIONS_FILE="${RDD_DIR}/permissions.yml"
AUDIT_CONFIG="${RDD_DIR}/audit.yml"
HOOKS_CONFIG="${RDD_DIR}/hooks.yml"
VAULT_CONFIG="${RDD_DIR}/vault.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
FIX_MODE="${FIX_MODE:-false}"
VERBOSE="${VERBOSE:-false}"
JSON_OUTPUT="${JSON_OUTPUT:-false}"
QUIET="${QUIET:-false}"

# Issue tracking
ISSUES=0
WARNINGS=0
FIXED=0
declare -a ISSUE_LIST=()
declare -a WARNING_LIST=()

#######################################
# Logging functions
#######################################
log_error() {
    local msg="$1"
    ((ISSUES++))
    ISSUE_LIST+=("ERROR: $msg")
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${RED}[ERROR]${NC} $msg"
    fi
}

log_warning() {
    local msg="$1"
    ((WARNINGS++))
    WARNING_LIST+=("WARN: $msg")
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $msg"
    fi
}

log_info() {
    if [[ "${VERBOSE:-false}" == "true" && "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_ok() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

log_fixed() {
    ((FIXED++))
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo -e "${GREEN}[FIXED]${NC} $1"
    fi
}

#######################################
# Get file permissions in octal
#######################################
get_file_perms() {
    local file="$1"
    if [[ -e "$file" ]]; then
        stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null || echo "???"
    else
        echo "missing"
    fi
}

#######################################
# Check if file is world-readable
#######################################
is_world_readable() {
    local file="$1"
    local perms
    perms=$(get_file_perms "$file")
    [[ "$((perms & 004))" -ne 0 ]]
}

#######################################
# Check if file is world-writable
#######################################
is_world_writable() {
    local file="$1"
    local perms
    perms=$(get_file_perms "$file")
    [[ "$((perms & 002))" -ne 0 ]]
}

#######################################
# Check file permissions
#######################################
check_file_permissions() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking File Permissions ==="
    fi

    local sensitive_files=(
        "$PERMISSIONS_FILE"
        "$HOOKS_CONFIG"
        "${RDD_DIR}/config.yml"
        "${RDD_DIR}/.keys"
    )

    for file in "${sensitive_files[@]}"; do
        if [[ -e "$file" ]]; then
            local perms
            perms=$(get_file_perms "$file")

            # Check if world-readable or world-writable
            if is_world_readable "$file" || is_world_writable "$file"; then
                if [[ "$file" == "${RDD_DIR}/.keys" ]]; then
                    # Keys directory should be 700
                    if [[ "$perms" != "700" ]]; then
                        log_warning "Key directory has wrong permissions: $file ($perms)"
                        if [[ "$FIX_MODE" == "true" ]]; then
                            chmod 700 "$file"
                            log_fixed "Fixed permissions on $file to 700"
                        else
                            if [[ "$JSON_OUTPUT" != "true" ]]; then
                                echo "         Recommended: chmod 700 $file"
                            fi
                        fi
                    else
                        log_ok "Key directory permissions: $file ($perms)"
                    fi
                else
                    # Sensitive files should be 600
                    if [[ "$perms" != "600" ]]; then
                        log_error "Sensitive file has wrong permissions: $file ($perms)"
                        if [[ "$FIX_MODE" == "true" ]]; then
                            chmod 600 "$file"
                            log_fixed "Fixed permissions on $file to 600"
                        else
                            if [[ "$JSON_OUTPUT" != "true" ]]; then
                                echo "         Recommended: chmod 600 $file"
                            fi
                        fi
                    else
                        log_ok "Sensitive file permissions: $file ($perms)"
                    fi
                fi
            else
                log_ok "File permissions secure: $file ($perms)"
            fi
        else
            log_info "File not found: $file"
        fi
    done

    # Check for world-writable files in .rdd
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
    fi
    log_info "Checking for world-writable files in .rdd..."

    local world_writable
    world_writable=$(find "${RDD_DIR}" -type f -perm /002 2>/dev/null || true)

    if [[ -n "$world_writable" ]]; then
        log_warning "Found world-writable files:"
        if [[ "$JSON_OUTPUT" != "true" ]]; then
            echo "$world_writable" | while read -r f; do
                echo "  - $f"
            done
        fi
        if [[ "$FIX_MODE" == "true" ]]; then
            echo "$world_writable" | while read -r f; do
                chmod o-w "$f"
                log_fixed "Fixed world-writable: $f"
            done
        fi
    else
        log_ok "No world-writable files found"
    fi
}

#######################################
# Check for exposed credentials
#######################################
check_exposed_credentials() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking for Exposed Credentials ==="
    fi

    local patterns=(
        "password\s*=\s*['\"][^'\"]+['\"]"
        "passwd\s*=\s*['\"][^'\"]+['\"]"
        "pwd\s*=\s*['\"][^'\"]+['\"]"
        "secret\s*=\s*['\"][^'\"]+['\"]"
        "api_key\s*=\s*['\"][^'\"]+['\"]"
        "apikey\s*=\s*['\"][^'\"]+['\"]"
        "token\s*=\s*['\"][^'\"]+['\"]"
    )

    local found_issues=0

    for pattern in "${patterns[@]}"; do
        if grep -rqE "$pattern" "${RDD_DIR}" --include="*.yml" --include="*.yaml" --include="*.json" 2>/dev/null; then
            local matches
            matches=$(grep -rE "$pattern" "${RDD_DIR}" --include="*.yml" --include="*.yaml" --include="*.json" 2>/dev/null | head -5)

            if [[ -n "$matches" ]]; then
                log_warning "Potential credential exposure found (pattern: $pattern)"
                if [[ "$JSON_OUTPUT" != "true" ]]; then
                    echo "$matches" | while read -r match; do
                        echo "  - $match"
                    done
                fi
                ((found_issues++))
            fi
        fi
    done

    if [[ $found_issues -eq 0 ]]; then
        log_ok "No exposed credentials found"
    fi

    # Check for environment variable usage
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
    fi
    log_info "Checking environment variable usage..."

    local env_usage
    env_usage=$(grep -r '\${' "${RDD_DIR}" --include="*.yml" --include="*.yaml" 2>/dev/null | wc -l || echo "0")

    if [[ "$env_usage" -gt 0 ]]; then
        log_ok "Found $env_usage environment variable references (good practice)"
    else
        log_info "No environment variable references found"
    fi
}

#######################################
# Check RBAC configuration
#######################################
check_rbac_config() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking RBAC Configuration ==="
    fi

    if [[ ! -f "$PERMISSIONS_FILE" ]]; then
        log_warning "RBAC configuration not found: $PERMISSIONS_FILE"
        if [[ "$FIX_MODE" == "true" ]]; then
            log_info "Creating default RBAC configuration..."
            source "${RDD_DIR}/lib/permissions.sh"
            log_fixed "Created default RBAC configuration"
        fi
        return
    fi

    # Check if RBAC is enabled
    if command -v yq &> /dev/null; then
        local rbac_enabled
        rbac_enabled=$(yq eval '.rbac.enabled' "$PERMISSIONS_FILE" 2>/dev/null || echo "false")

        if [[ "$rbac_enabled" == "true" ]]; then
            log_ok "RBAC is enabled"
        else
            log_warning "RBAC is disabled"
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                echo "         Recommended: Set rbac.enabled: true in permissions.yml"
            fi
        fi

        # Check default role
        local default_role
        default_role=$(yq eval '.rbac.default_role' "$PERMISSIONS_FILE" 2>/dev/null || echo "unknown")

        if [[ "$default_role" == "viewer" ]]; then
            log_ok "Default role is restrictive (viewer)"
        elif [[ "$default_role" == "none" ]]; then
            log_ok "Default role is restrictive (none)"
        else
            log_warning "Default role is permissive: $default_role"
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                echo "         Recommended: Set default_role to 'viewer' or 'none'"
            fi
        fi

        # Check strict mode
        local strict_mode
        strict_mode=$(yq eval '.checking.strict_mode' "$PERMISSIONS_FILE" 2>/dev/null || echo "false")

        if [[ "$strict_mode" == "true" ]]; then
            log_ok "Strict mode is enabled"
        else
            log_warning "Strict mode is disabled"
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                echo "         Recommended: Set checking.strict_mode: true"
            fi
        fi

        # Check if admin users are configured
        local admin_count
        admin_count=$(yq eval '[.rbac.users[] | select(.role == "admin")] | length' "$PERMISSIONS_FILE" 2>/dev/null || echo "0")

        if [[ "$admin_count" -gt 0 ]]; then
            log_ok "Found $admin_count admin user(s) configured"
        else
            log_warning "No admin users configured"
        fi

    else
        log_info "yq not available, skipping detailed RBAC checks"

        # Basic grep checks
        if grep -q "enabled: true" "$PERMISSIONS_FILE" 2>/dev/null; then
            log_ok "RBAC appears to be enabled"
        else
            log_warning "RBAC may be disabled"
        fi
    fi
}

#######################################
# Check audit logging configuration
#######################################
check_audit_config() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking Audit Logging Configuration ==="
    fi

    if [[ ! -f "$AUDIT_CONFIG" ]]; then
        log_warning "Audit configuration not found: $AUDIT_CONFIG"
        if [[ "$FIX_MODE" == "true" ]]; then
            log_info "Creating default audit configuration..."
            if [[ -f "${RDD_DIR}/scripts/audit.sh" ]]; then
                source "${RDD_DIR}/scripts/audit.sh"
                init_audit
                log_fixed "Created default audit configuration"
            fi
        fi
        return
    fi

    if command -v yq &> /dev/null; then
        local audit_enabled
        audit_enabled=$(yq eval '.audit.enabled' "$AUDIT_CONFIG" 2>/dev/null || echo "false")

        if [[ "$audit_enabled" == "true" ]]; then
            log_ok "Audit logging is enabled"
        else
            log_warning "Audit logging is disabled"
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                echo "         Recommended: Set audit.enabled: true"
            fi
        fi

        # Check log rotation
        local rotation_enabled
        rotation_enabled=$(yq eval '.audit.storage.file.rotation.enabled' "$AUDIT_CONFIG" 2>/dev/null || echo "false")

        if [[ "$rotation_enabled" == "true" ]]; then
            log_ok "Log rotation is enabled"
        else
            log_warning "Log rotation is disabled"
        fi

        # Check masking
        local masking_enabled
        masking_enabled=$(yq eval '.audit.masking.enabled' "$AUDIT_CONFIG" 2>/dev/null || echo "false")

        if [[ "$masking_enabled" == "true" ]]; then
            log_ok "Sensitive data masking is enabled"
        else
            log_warning "Sensitive data masking is disabled"
        fi

        # Check retention
        local retention_days
        retention_days=$(yq eval '.audit.retention.days' "$AUDIT_CONFIG" 2>/dev/null || echo "0")

        if [[ "$retention_days" -ge 30 ]]; then
            log_ok "Audit log retention: $retention_days days"
        else
            log_warning "Audit log retention is short: $retention_days days"
        fi

    else
        if grep -q "enabled: true" "$AUDIT_CONFIG" 2>/dev/null; then
            log_ok "Audit logging appears to be enabled"
        else
            log_warning "Audit logging may be disabled"
        fi
    fi

    # Check if log files exist and are writable
    local audit_log="${RDD_DIR}/logs/audit.log"
    local audit_json="${RDD_DIR}/logs/audit.json"

    if [[ -f "$audit_log" ]]; then
        if [[ -w "$audit_log" ]]; then
            log_ok "Audit log file is writable"
        else
            log_error "Audit log file is not writable: $audit_log"
        fi
    else
        log_info "Audit log file not yet created: $audit_log"
    fi

    if [[ -f "$audit_json" ]]; then
        if [[ -w "$audit_json" ]]; then
            log_ok "JSON audit log is writable"
        else
            log_error "JSON audit log is not writable: $audit_json"
        fi
    else
        log_info "JSON audit log not yet created: $audit_json"
    fi
}

#######################################
# Check encryption key
#######################################
check_encryption() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking Encryption Configuration ==="
    fi

    local key_dir="${RDD_DIR}/.keys"
    local key_file="${key_dir}/encryption.key"

    if [[ ! -d "$key_dir" ]]; then
        log_warning "Key directory does not exist: $key_dir"
        if [[ "$FIX_MODE" == "true" ]]; then
            mkdir -p "$key_dir"
            chmod 700 "$key_dir"
            log_fixed "Created key directory with secure permissions"
        fi
        return
    fi

    # Check key directory permissions
    local key_dir_perms
    key_dir_perms=$(get_file_perms "$key_dir")

    if [[ "$key_dir_perms" != "700" ]]; then
        log_warning "Key directory has wrong permissions: $key_dir_perms"
        if [[ "$FIX_MODE" == "true" ]]; then
            chmod 700 "$key_dir"
            log_fixed "Fixed key directory permissions to 700"
        else
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                echo "         Recommended: chmod 700 $key_dir"
            fi
        fi
    else
        log_ok "Key directory has secure permissions"
    fi

    # Check encryption key
    if [[ ! -f "$key_file" ]]; then
        log_warning "Encryption key not found"
        if [[ "$FIX_MODE" == "true" ]]; then
            if [[ -f "${RDD_DIR}/lib/crypto.sh" ]]; then
                source "${RDD_DIR}/lib/crypto.sh"
                generate_key > /dev/null
                log_fixed "Generated encryption key"
            fi
        fi
    else
        local key_perms
        key_perms=$(get_file_perms "$key_file")

        if [[ "$key_perms" != "600" ]]; then
            log_warning "Encryption key has wrong permissions: $key_perms"
            if [[ "$FIX_MODE" == "true" ]]; then
                chmod 600 "$key_file"
                log_fixed "Fixed encryption key permissions to 600"
            else
                if [[ "$JSON_OUTPUT" != "true" ]]; then
                    echo "         Recommended: chmod 600 $key_file"
                fi
            fi
        else
            log_ok "Encryption key has secure permissions"
        fi

        # Check key is not in git
        if [[ -d "${RDD_DIR}/../.git" ]]; then
            if git -C "${RDD_DIR}/.." check-ignore -q "$key_file" 2>/dev/null; then
                log_ok "Encryption key is gitignored"
            else
                log_error "Encryption key is not in .gitignore!"
                if [[ "$JSON_OUTPUT" != "true" ]]; then
                    echo "         Add '.rdd/.keys/' to .gitignore immediately"
                fi
            fi
        fi
    fi
}

#######################################
# Check .gitignore
#######################################
check_gitignore() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking .gitignore ==="
    fi

    local gitignore="${RDD_DIR}/../.gitignore"

    if [[ ! -f "$gitignore" ]]; then
        log_warning "No .gitignore file found"
        return
    fi

    local required_ignores=(
        ".rdd/.keys/"
        ".rdd/logs/"
        ".rdd/cache/"
        "*.key"
        "*.pem"
        "*.env"
    )

    for pattern in "${required_ignores[@]}"; do
        if grep -qE "$pattern" "$gitignore" 2>/dev/null; then
            log_ok ".gitignore contains: $pattern"
        else
            log_warning ".gitignore missing: $pattern"
            if [[ "$FIX_MODE" == "true" ]]; then
                echo "$pattern" >> "$gitignore"
                log_fixed "Added $pattern to .gitignore"
            fi
        fi
    done
}

#######################################
# Check dependencies
#######################################
check_dependencies() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking Security Dependencies ==="
    fi

    # Check openssl
    if command -v openssl &> /dev/null; then
        log_ok "openssl is available"
    else
        log_warning "openssl not found - encryption features limited"
    fi

    # Check jq
    if command -v jq &> /dev/null; then
        log_ok "jq is available"
    else
        log_warning "jq not found - JSON processing limited"
    fi

    # Check yq
    if command -v yq &> /dev/null; then
        log_ok "yq is available"
    else
        log_warning "yq not found - YAML processing limited"
    fi

    # Check curl (for Vault integration)
    if command -v curl &> /dev/null; then
        log_ok "curl is available (for Vault integration)"
    else
        log_info "curl not found - Vault integration unavailable"
    fi
}

#######################################
# Check security scripts
#######################################
check_security_scripts() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "=== Checking Security Scripts ==="
    fi

    local scripts=(
        "${RDD_DIR}/lib/permissions.sh"
        "${RDD_DIR}/lib/crypto.sh"
        "${RDD_DIR}/lib/security.sh"
        "${RDD_DIR}/scripts/audit.sh"
    )

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_ok "Script exists and is executable: $(basename "$script")"
            else
                log_warning "Script exists but not executable: $(basename "$script")"
                if [[ "$FIX_MODE" == "true" ]]; then
                    chmod +x "$script"
                    log_fixed "Made $(basename "$script") executable"
                fi
            fi

            # Basic syntax check
            if bash -n "$script" 2>/dev/null; then
                log_ok "Script syntax valid: $(basename "$script")"
            else
                log_error "Script syntax error: $(basename "$script")"
            fi
        else
            log_warning "Script not found: $(basename "$script")"
        fi
    done
}

#######################################
# Run all checks
#######################################
run_all_checks() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "========================================"
        echo "   RDD Security Configuration Check"
        echo "========================================"
        echo ""
    fi

    check_file_permissions
    check_exposed_credentials
    check_rbac_config
    check_audit_config
    check_encryption
    check_gitignore
    check_dependencies
    check_security_scripts
}

#######################################
# Print summary
#######################################
print_summary() {
    if [[ "$JSON_OUTPUT" != "true" && "$QUIET" != "true" ]]; then
        echo ""
        echo "========================================"
        echo "             Summary"
        echo "========================================"
        echo ""
    fi

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        cat << EOF
{
  "issues": $ISSUES,
  "warnings": $WARNINGS,
  "fixed": $FIXED,
  "issue_list": $(printf '%s\n' "${ISSUE_LIST[@]}" | jq -R . | jq -s .),
  "warning_list": $(printf '%s\n' "${WARNING_LIST[@]}" | jq -R . | jq -s .)
}
EOF
    else
        echo "Issues found: $ISSUES"
        echo "Warnings found: $WARNINGS"

        if [[ "$FIX_MODE" == "true" ]]; then
            echo "Issues fixed: $FIXED"
        fi

        echo ""

        if [[ $ISSUES -gt 0 ]]; then
            echo -e "${RED}Security issues detected!${NC}"
            echo "Please review and fix the issues above."
            if [[ "$FIX_MODE" != "true" ]]; then
                echo "Run with --fix to automatically fix fixable issues."
            fi
        elif [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}Security warnings detected.${NC}"
            echo "Review the warnings above and consider fixing them."
        else
            echo -e "${GREEN}No security issues found!${NC}"
        fi
    fi
}

#######################################
# Show usage
#######################################
show_usage() {
    cat << 'EOF'
RDD Security Configuration Checker

Usage: security-check.sh [options]

Options:
  --fix        Automatically fix fixable issues
  --verbose    Show detailed output
  --json       Output in JSON format
  --quiet      Only show errors
  -h, --help   Show this help message

Checks performed:
  1. File permissions on sensitive files
  2. Exposed credentials in configuration
  3. RBAC configuration
  4. Audit logging configuration
  5. Encryption key setup
  6. .gitignore for sensitive files
  7. Security dependencies
  8. Security script validity

Examples:
  # Run security check
  security-check.sh

  # Run and fix issues automatically
  security-check.sh --fix

  # Get JSON output
  security-check.sh --json

  # Verbose output
  security-check.sh --verbose

EOF
}

#######################################
# Parse arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_MODE="true"
                shift
                ;;
            --verbose|-v)
                VERBOSE="true"
                shift
                ;;
            --json)
                JSON_OUTPUT="true"
                shift
                ;;
            --quiet|-q)
                QUIET="true"
                shift
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
    done
}

#######################################
# Main entry point
#######################################
main() {
    parse_args "$@"
    run_all_checks
    print_summary

    # Exit with error code if issues found
    if [[ $ISSUES -gt 0 ]]; then
        exit 1
    fi

    exit 0
}

# Run main
main "$@"
