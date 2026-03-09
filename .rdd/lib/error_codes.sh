#!/bin/bash
#
# RDD Error Code Definitions
# Defines error classification, codes, and messages
#
# Source this file to use error codes:
#   source "${RDD_DIR}/lib/error_codes.sh"

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

#######################################
# Error Severity Levels
#######################################

# P0: Critical - System cannot continue, human intervention required
export ERROR_SEVERITY_P0="P0"
# P1: High - Major functionality degraded, operation may continue
export ERROR_SEVERITY_P1="P1"
# P2: Medium - Minor functionality affected
export ERROR_SEVERITY_P2="P2"
# P3: Low - Informational, no functional impact
export ERROR_SEVERITY_P3="P3"

#######################################
# Error Categories
#######################################

export ERROR_CATEGORY_RECOVERABLE="RECOVERABLE"
export ERROR_CATEGORY_NON_RECOVERABLE="NON_RECOVERABLE"

#######################################
# Error Code Registry
#######################################

# Configuration errors (E1xx)
declare -gA ERROR_CODES=(
    # Configuration errors (E100-E199)
    ["E100"]="CONFIG_ERROR|P0|NON_RECOVERABLE|Configuration error|Configuration file is invalid. Please check the format and values."
    ["E101"]="CONFIG_NOT_FOUND|P0|NON_RECOVERABLE|Configuration file not found|Configuration file {file} not found. Please create it from the example."
    ["E102"]="CONFIG_PARSE_ERROR|P0|NON_RECOVERABLE|Failed to parse configuration|Failed to parse configuration: {reason}. Please check YAML syntax."
    ["E103"]="CONFIG_INVALID_VALUE|P0|NON_RECOVERABLE|Invalid configuration value|Invalid value for {field}: {value}. Expected {expected}."
    ["E104"]="CONFIG_MISSING_REQUIRED|P0|NON_RECOVERABLE|Missing required configuration|Missing required configuration: {field}."

    # Notification errors (E200-E299)
    ["E200"]="NOTIFICATION_FAILED|P1|RECOVERABLE|Failed to send notification|Failed to send notification via {channel}. Will retry."
    ["E201"]="CHANNEL_DISABLED|P2|RECOVERABLE|Notification channel is disabled|Channel {channel} is disabled. Skipping."
    ["E202"]="ALL_CHANNELS_FAILED|P1|RECOVERABLE|All notification channels failed|All notification channels failed. Check configuration."
    ["E203"]="CIRCUIT_BREAKER_OPEN|P2|RECOVERABLE|Circuit breaker is open|Circuit breaker open for {channel}. Notification skipped."
    ["E204"]="CHANNEL_NOT_CONFIGURED|P2|RECOVERABLE|Notification channel not configured|Channel {channel} is not configured. Skipping."
    ["E205"]="NOTIFICATION_QUEUED|P2|RECOVERABLE|Notification queued|Notification queued for later delivery."

    # Network errors (E300-E399)
    ["E300"]="NETWORK_TIMEOUT|P1|RECOVERABLE|Network request timed out|Request to {url} timed out. Will retry."
    ["E301"]="NETWORK_ERROR|P1|RECOVERABLE|Network request failed|Network request failed: {reason}. Will retry."
    ["E302"]="RATE_LIMIT_EXCEEDED|P2|RECOVERABLE|Rate limit exceeded|Rate limit exceeded. Waiting {wait_time}s before retry."
    ["E303"]="SERVICE_UNAVAILABLE|P1|RECOVERABLE|Service unavailable|Service {service} unavailable (HTTP {status}). Will retry."
    ["E304"]="NETWORK_DNS_ERROR|P1|RECOVERABLE|DNS resolution failed|Failed to resolve {host}. Will retry."
    ["E305"]="NETWORK_SSL_ERROR|P1|RECOVERABLE|SSL/TLS error|SSL/TLS error connecting to {url}. Will retry."

    # Hook errors (E400-E499)
    ["E400"]="HOOK_EXECUTION_FAILED|P1|NON_RECOVERABLE|Hook script execution failed|Hook {hook_name} execution failed: {reason}"
    ["E401"]="HOOK_NOT_FOUND|P1|NON_RECOVERABLE|Hook script not found|Hook script {hook_name} not found."
    ["E402"]="HOOK_PERMISSION_DENIED|P1|NON_RECOVERABLE|Hook script not executable|Hook script {hook_name} is not executable. Run: chmod +x {path}"
    ["E403"]="HOOK_TIMEOUT|P1|RECOVERABLE|Hook execution timed out|Hook {hook_name} timed out after {timeout}s."
    ["E404"]="HOOK_INVALID_OUTPUT|P2|RECOVERABLE|Hook produced invalid output|Hook {hook_name} produced invalid output."

    # Template errors (E500-E599)
    ["E500"]="TEMPLATE_NOT_FOUND|P2|RECOVERABLE|Template not found|Template {template} not found. Using default."
    ["E501"]="TEMPLATE_RENDER_ERROR|P2|RECOVERABLE|Failed to render template|Failed to render template: {reason}. Using fallback."
    ["E502"]="TEMPLATE_SYNTAX_ERROR|P1|NON_RECOVERABLE|Template syntax error|Template syntax error in {template}: {reason}."

    # Environment errors (E600-E699)
    ["E600"]="MISSING_TOOL|P0|NON_RECOVERABLE|Required tool not found|Required tool '{tool}' not found. Please install it."
    ["E601"]="PERMISSION_DENIED|P0|NON_RECOVERABLE|Permission denied|Permission denied: {operation}. Check file permissions."
    ["E602"]="INVALID_DIRECTORY|P0|NON_RECOVERABLE|Invalid working directory|Working directory {dir} does not exist or is not accessible."
    ["E603"]="INSUFFICIENT_RESOURCES|P0|NON_RECOVERABLE|Insufficient system resources|Insufficient {resource}: {details}."

    # State errors (E700-E799)
    ["E700"]="STATE_LOAD_FAILED|P1|RECOVERABLE|Failed to load state|Failed to load state from {file}. Using defaults."
    ["E701"]="STATE_SAVE_FAILED|P1|RECOVERABLE|Failed to save state|Failed to save state to {file}. Will retry."
    ["E702"]="STATE_CORRUPTED|P1|RECOVERABLE|State file corrupted|State file {file} is corrupted. Reinitializing."

    # Degradation errors (E800-E899)
    ["E800"]="DEGRADATION_LEVEL_CHANGED|P2|RECOVERABLE|Degradation level changed|Degradation level changed from {old_level} to {new_level}."
    ["E801"]="DEGRADATION_SAFE_MODE|P1|RECOVERABLE|Entered safe mode|System entered safe mode. All external calls disabled."
    ["E802"]="DEGRADATION_RECOVERY|P2|RECOVERABLE|Degradation recovery|System recovered from degradation level {level}."

    # Retry errors (E900-E999)
    ["E900"]="RETRY_EXHAUSTED|P1|RECOVERABLE|Retry attempts exhausted|All {attempts} retry attempts failed for {operation}."
    ["E901"]="RETRY_ABORTED|P2|RECOVERABLE|Retry aborted|Retry aborted for {operation}: {reason}."
)

#######################################
# Error Code Functions
#######################################

# Get error code details
# Usage: get_error_info <code>
# Returns: CODE|SEVERITY|CATEGORY|MESSAGE|USER_MESSAGE
get_error_info() {
    local code="$1"
    local info="${ERROR_CODES[$code]:-}"

    if [[ -z "$info" ]]; then
        # Unknown error code
        echo "UNKNOWN|P3|RECOVERABLE|Unknown error code: $code|An unknown error occurred."
        return 1
    fi

    echo "$info"
}

# Get error code
# Usage: get_error_code <code>
get_error_code() {
    local info
    info=$(get_error_info "$1")
    echo "${info%%|*}"
}

# Get error severity
# Usage: get_error_severity <code>
get_error_severity() {
    local info
    info=$(get_error_info "$1")
    local fields
    IFS='|' read -ra fields <<< "$info"
    echo "${fields[1]}"
}

# Get error category
# Usage: get_error_category <code>
get_error_category() {
    local info
    info=$(get_error_info "$1")
    local fields
    IFS='|' read -ra fields <<< "$info"
    echo "${fields[2]}"
}

# Get error message
# Usage: get_error_message <code>
get_error_message() {
    local info
    info=$(get_error_info "$1")
    local fields
    IFS='|' read -ra fields <<< "$info"
    echo "${fields[3]}"
}

# Get user-friendly error message
# Usage: get_user_message <code> [var1=value1] [var2=value2] ...
get_user_message() {
    local code="$1"
    shift

    local info
    info=$(get_error_info "$code")
    local fields
    IFS='|' read -ra fields <<< "$info"
    local message="${fields[4]}"

    # Replace placeholders with values
    for var in "$@"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        message="${message//\{${key}\}/${value}}"
    done

    echo "$message"
}

# Check if error is recoverable
# Usage: is_recoverable <code>
is_recoverable() {
    local category
    category=$(get_error_category "$1")
    [[ "$category" == "RECOVERABLE" ]]
}

# Check if error should trigger retry
# Usage: is_retryable <code>
is_retryable() {
    local code="$1"

    # Retryable error codes
    local retryable_codes="E200 E300 E301 E302 E303 E304 E305 E700 E701 E702"

    [[ " $retryable_codes " == *" $code "* ]]
}

# Check if error is critical (P0)
# Usage: is_critical <code>
is_critical() {
    local severity
    severity=$(get_error_severity "$1")
    [[ "$severity" == "P0" ]]
}

# Check if error requires notification
# Usage: requires_notification <code>
requires_notification() {
    local severity
    severity=$(get_error_severity "$1")
    [[ "$severity" == "P0" || "$severity" == "P1" ]]
}

# Get error priority as number (for sorting)
# Usage: get_error_priority <code>
# Returns: 0 for P0, 1 for P1, 2 for P2, 3 for P3
get_error_priority() {
    local severity
    severity=$(get_error_severity "$1")

    case "$severity" in
        P0) echo 0 ;;
        P1) echo 1 ;;
        P2) echo 2 ;;
        P3) echo 3 ;;
        *)  echo 3 ;;
    esac
}

#######################################
# Error Response Functions
#######################################

# Get recommended response action for an error
# Usage: get_error_response <code>
get_error_response() {
    local code="$1"
    local category
    category=$(get_error_category "$code")

    if [[ "$category" == "NON_RECOVERABLE" ]]; then
        echo "halt"
    elif is_retryable "$code"; then
        echo "retry"
    else
        echo "fallback"
    fi
}

# Format error as JSON
# Usage: format_error_json <code> [var1=value1] [var2=value2] ...
format_error_json() {
    local code="$1"
    shift

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local error_code
    error_code=$(get_error_code "$code")
    local severity
    severity=$(get_error_severity "$code")
    local category
    category=$(get_error_category "$code")
    local message
    message=$(get_error_message "$code")
    local user_message
    user_message=$(get_user_message "$code" "$@")
    local response
    response=$(get_error_response "$code")

    # Build context object
    local context="{"
    local first=true
    for var in "$@"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        if [[ "$first" != "true" ]]; then
            context+=","
        fi
        context+="\"${key}\":\"${value}\""
        first=false
    done
    context+="}"

    cat <<EOF
{
    "timestamp": "${timestamp}",
    "error_code": "${code}",
    "error_name": "${error_code}",
    "severity": "${severity}",
    "category": "${category}",
    "message": "${message}",
    "user_message": "${user_message}",
    "response": "${response}",
    "context": ${context}
}
EOF
}

# Print error to stderr in a formatted way
# Usage: print_error <code> [var1=value1] [var2=value2] ...
print_error() {
    local code="$1"
    shift

    local severity
    severity=$(get_error_severity "$code")
    local message
    message=$(get_error_message "$code")
    local user_message
    user_message=$(get_user_message "$code" "$@")

    local prefix
    case "$severity" in
        P0) prefix="[CRITICAL]" ;;
        P1) prefix="[ERROR]" ;;
        P2) prefix="[WARN]" ;;
        P3) prefix="[INFO]" ;;
        *)  prefix="[INFO]" ;;
    esac

    echo "${prefix} ${code}: ${message}" >&2
    echo "  ${user_message}" >&2
}

#######################################
# Validation Functions
#######################################

# Validate error code exists
# Usage: validate_error_code <code>
validate_error_code() {
    local code="$1"

    if [[ -z "${ERROR_CODES[$code]:-}" ]]; then
        echo "Invalid error code: $code" >&2
        return 1
    fi

    return 0
}

# List all error codes
# Usage: list_error_codes [category]
list_error_codes() {
    local filter_category="${1:-}"

    for code in "${!ERROR_CODES[@]}"; do
        local info="${ERROR_CODES[$code]}"
        local fields
        IFS='|' read -ra fields <<< "$info"
        local name="${fields[0]}"
        local severity="${fields[1]}"
        local category="${fields[2]}"
        local message="${fields[3]}"

        if [[ -n "$filter_category" && "$category" != "$filter_category" ]]; then
            continue
        fi

        printf "%-6s %-8s %-16s %-25s %s\n" "$code" "$severity" "$category" "$name" "$message"
    done | sort
}

#######################################
# Initialize error system
#######################################

# Initialize error tracking
init_error_system() {
    local cache_dir="${RDD_DIR}/cache"
    mkdir -p "$cache_dir"

    # Create error log file if it doesn't exist
    local error_log="${cache_dir}/errors.log"
    touch "$error_log" 2>/dev/null || true
}

# Initialize on source
init_error_system
