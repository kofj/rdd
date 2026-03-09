#!/bin/bash
#
# RDD Structured JSON Logger
# Provides structured JSON logging with trace IDs and context
#
# Usage:
#   source "${RDD_DIR}/scripts/logger.sh"
#   log_json "INFO" "Operation completed" "key1=value1" "key2=value2"

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"

#######################################
# Logger Configuration
#######################################

# Log format: json or text
LOG_FORMAT="${LOG_FORMAT:-json}"

# Log level: DEBUG, INFO, WARN, ERROR, CRITICAL
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Log output: stderr or file path
LOG_OUTPUT="${LOG_OUTPUT:-stderr}"

# Include trace ID in logs
LOG_INCLUDE_TRACE_ID="${LOG_INCLUDE_TRACE_ID:-true}"

# Include context in logs
LOG_INCLUDE_CONTEXT="${LOG_INCLUDE_CONTEXT:-true}"

# Component name for logs
COMPONENT_NAME="${COMPONENT_NAME:-rdd}"

# Trace ID for request tracking
TRACE_ID="${TRACE_ID:-}"

# Span ID for sub-operation tracking
SPAN_ID="${SPAN_ID:-}"

# Project name
RDD_PROJECT="${RDD_PROJECT:-unknown}"

# Current stage
RDD_STAGE="${RDD_STAGE:-unknown}"

# Log file path (if output is file)
LOG_FILE="${LOG_FILE:-${RDD_DIR}/cache/rdd.log}"

#######################################
# Log Level Priority
#######################################

declare -gA LOG_LEVEL_PRIORITY=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["CRITICAL"]=4
)

# Check if log level should be output
# Usage: should_log <level>
should_log() {
    local level="$1"
    local current_priority="${LOG_LEVEL_PRIORITY[$LOG_LEVEL]:-1}"
    local level_priority="${LOG_LEVEL_PRIORITY[$level]:-1}"

    [[ $level_priority -ge $current_priority ]]
}

#######################################
# JSON Log Functions
#######################################

# Generate unique trace ID
# Usage: generate_trace_id
generate_trace_id() {
    echo "$(date +%s)-$$-${RANDOM}"
}

# Generate unique span ID
# Usage: generate_span_id
generate_span_id() {
    echo "${RANDOM}-${RANDOM}"
}

# Format timestamp in ISO8601
# Usage: format_timestamp
format_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

# Escape string for JSON
# Usage: json_escape <string>
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Build JSON log entry
# Usage: build_json_log <level> <message> [key=value] ...
build_json_log() {
    local level="$1"
    local message="$2"
    shift 2
    local context_vars=("$@")

    local timestamp
    timestamp=$(format_timestamp)
    local escaped_message
    escaped_message=$(json_escape "$message")

    local json="{"
    json+="\"timestamp\":\"${timestamp}\""
    json+=",\"level\":\"${level}\""
    json+=",\"message\":\"${escaped_message}\""
    json+=",\"component\":\"${COMPONENT_NAME}\""

    if [[ "$LOG_INCLUDE_TRACE_ID" == "true" && -n "$TRACE_ID" ]]; then
        json+=",\"trace_id\":\"${TRACE_ID}\""
    fi

    if [[ -n "$SPAN_ID" ]]; then
        json+=",\"span_id\":\"${SPAN_ID}\""
    fi

    json+=",\"rdd_project\":\"${RDD_PROJECT}\""
    json+=",\"rdd_stage\":\"${RDD_STAGE}\""

    if [[ "$LOG_INCLUDE_CONTEXT" == "true" && ${#context_vars[@]} -gt 0 ]]; then
        json+=",\"context\":{"
        local first=true
        for var in "${context_vars[@]}"; do
            local key="${var%%=*}"
            local value="${var#*=}"
            local escaped_value
            escaped_value=$(json_escape "$value")
            if [[ "$first" != "true" ]]; then
                json+=","
            fi
            json+="\"${key}\":\"${escaped_value}\""
            first=false
        done
        json+="}"
    fi

    json+="}"
    echo "$json"
}

# Output log entry
# Usage: output_log <json>
output_log() {
    local json="$1"

    case "$LOG_OUTPUT" in
        stderr)
            echo "$json" >&2
            ;;
        stdout)
            echo "$json"
            ;;
        *)
            if [[ -n "$LOG_FILE" ]]; then
                mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
                echo "$json" >> "$LOG_FILE" 2>/dev/null || echo "$json" >&2
            else
                echo "$json" >&2
            fi
            ;;
    esac
}

#######################################
# Core Logging Functions
#######################################

# Log with JSON format
# Usage: log_json <level> <message> [key=value] ...
log_json() {
    local level="$1"
    local message="$2"
    shift 2
    local context_vars=("$@")

    if ! should_log "$level"; then
        return 0
    fi

    local json
    json=$(build_json_log "$level" "$message" "${context_vars[@]}")
    output_log "$json"
}

# Log DEBUG
log_debug() {
    log_json "DEBUG" "$@"
}

# Log INFO
log_info() {
    log_json "INFO" "$@"
}

# Log WARN
log_warn() {
    log_json "WARN" "$@"
}

# Log ERROR
log_error() {
    log_json "ERROR" "$@"
}

# Log CRITICAL
log_critical() {
    log_json "CRITICAL" "$@"
}

#######################################
# Error Logging Functions
#######################################

# Log error with error code
# Usage: log_error_with_code <error_code> <message> [key=value] ...
log_error_with_code() {
    local error_code="$1"
    local message="$2"
    shift 2
    local context_vars=("$@")

    local severity
    severity=$(get_error_severity "$error_code")
    local category
    category=$(get_error_category "$error_code")

    local level
    case "$severity" in
        P0) level="CRITICAL" ;;
        P1) level="ERROR" ;;
        P2) level="WARN" ;;
        P3) level="INFO" ;;
        *)  level="ERROR" ;;
    esac

    if ! should_log "$level"; then
        return 0
    fi

    local timestamp
    timestamp=$(format_timestamp)
    local escaped_message
    escaped_message=$(json_escape "$message")

    local json="{"
    json+="\"timestamp\":\"${timestamp}\""
    json+=",\"level\":\"${level}\""
    json+=",\"message\":\"${escaped_message}\""
    json+=",\"component\":\"${COMPONENT_NAME}\""

    if [[ "$LOG_INCLUDE_TRACE_ID" == "true" && -n "$TRACE_ID" ]]; then
        json+=",\"trace_id\":\"${TRACE_ID}\""
    fi

    if [[ -n "$SPAN_ID" ]]; then
        json+=",\"span_id\":\"${SPAN_ID}\""
    fi

    json+=",\"rdd_project\":\"${RDD_PROJECT}\""
    json+=",\"rdd_stage\":\"${RDD_STAGE}\""
    json+=",\"error_code\":\"${error_code}\""
    json+=",\"error_category\":\"${category}\""
    json+=",\"severity\":\"${severity}\""

    if [[ "$LOG_INCLUDE_CONTEXT" == "true" && ${#context_vars[@]} -gt 0 ]]; then
        json+=",\"context\":{"
        local first=true
        for var in "${context_vars[@]}"; do
            local key="${var%%=*}"
            local value="${var#*=}"
            local escaped_value
            escaped_value=$(json_escape "$value")
            if [[ "$first" != "true" ]]; then
                json+=","
            fi
            json+="\"${key}\":\"${escaped_value}\""
            first=false
        done
        json+="}"
    fi

    json+="}"
    output_log "$json"
}

#######################################
# Performance Logging Functions
#######################################

# Log with duration
log_with_duration() {
    local level="$1"
    local message="$2"
    local duration_ms="$3"
    shift 3
    local context_vars=("$@")

    if ! should_log "$level"; then
        return 0
    fi

    local timestamp
    timestamp=$(format_timestamp)
    local escaped_message
    escaped_message=$(json_escape "$message")

    local json="{"
    json+="\"timestamp\":\"${timestamp}\""
    json+=",\"level\":\"${level}\""
    json+=",\"message\":\"${escaped_message}\""
    json+=",\"component\":\"${COMPONENT_NAME}\""

    if [[ "$LOG_INCLUDE_TRACE_ID" == "true" && -n "$TRACE_ID" ]]; then
        json+=",\"trace_id\":\"${TRACE_ID}\""
    fi

    json+=",\"rdd_project\":\"${RDD_PROJECT}\""
    json+=",\"rdd_stage\":\"${RDD_STAGE}\""
    json+=",\"duration_ms\":${duration_ms}"

    if [[ "$LOG_INCLUDE_CONTEXT" == "true" && ${#context_vars[@]} -gt 0 ]]; then
        json+=",\"context\":{"
        local first=true
        for var in "${context_vars[@]}"; do
            local key="${var%%=*}"
            local value="${var#*=}"
            local escaped_value
            escaped_value=$(json_escape "$value")
            if [[ "$first" != "true" ]]; then
                json+=","
            fi
            json+="\"${key}\":\"${escaped_value}\""
            first=false
        done
        json+="}"
    fi

    json+="}"
    output_log "$json"
}

# Create a logging context with trace ID
with_trace_context() {
    local trace_id="$1"
    shift
    local cmd=("$@")

    local old_trace_id="$TRACE_ID"
    TRACE_ID="$trace_id"

    "${cmd[@]}"
    local exit_code=$?

    TRACE_ID="$old_trace_id"
    return $exit_code
}

# Start a new trace
start_trace() {
    TRACE_ID="${1:-$(generate_trace_id)}"
    SPAN_ID=$(generate_span_id)
    echo "$TRACE_ID"
}

# Start a new span
start_span() {
    SPAN_ID=$(generate_span_id)
    echo "$SPAN_ID"
}

#######################################
# Initialization
#######################################

# Initialize logger
init_logger() {
    if [[ "$LOG_OUTPUT" != "stderr" && "$LOG_OUTPUT" != "stdout" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    fi

    if [[ -z "$TRACE_ID" ]]; then
        TRACE_ID=$(generate_trace_id)
    fi
}

# Initialize on source
init_logger

# Export functions
export -f should_log generate_trace_id generate_span_id format_timestamp
export -f json_escape build_json_log output_log
export -f log_json log_debug log_info log_warn log_error log_critical
export -f log_error_with_code log_with_duration
export -f with_trace_context start_trace start_span init_logger