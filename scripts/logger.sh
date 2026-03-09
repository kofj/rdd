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

declare -A LOG_LEVEL_PRIORITY=(
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
    str="${str//\\/\\\\}"      # Escape backslash
    str="${str//\"/\\\"}"      # Escape double quote
    str="${str//$'\n'/\\n}"    # Escape newline
    str="${str//$'\r'/\\r}"    # Escape carriage return
    str="${str//$'\t'/\\t}"    # Escape tab
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

    # Escape message
    local escaped_message
    escaped_message=$(json_escape "$message")

    # Start building JSON
    local json="{"
    json+="\"timestamp\":\"${timestamp}\""
    json+=",\"level\":\"${level}\""
    json+=",\"message\":\"${escaped_message}\""
    json+=",\"component\":\"${COMPONENT_NAME}\""

    # Add trace ID if available
    if [[ "$LOG_INCLUDE_TRACE_ID" == "true" && -n "$TRACE_ID" ]]; then
        json+=",\"trace_id\":\"${TRACE_ID}\""
    fi

    # Add span ID if available
    if [[ -n "$SPAN_ID" ]]; then
        json+=",\"span_id\":\"${SPAN_ID}\""
    fi

    # Add RDD context
    json+=",\"rdd_project\":\"${RDD_PROJECT}\""
    json+=",\"rdd_stage\":\"${RDD_STAGE}\""

    # Add context variables
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
            # Output to file
            if [[ -n "$LOG_FILE" ]]; then
                mkdir -p "$(dirname "$LOG_FILE")"
                echo "$json" >> "$LOG_FILE"
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
# Usage: log_debug <message> [key=value] ...
log_debug() {
    log_json "DEBUG" "$@"
}

# Log INFO
# Usage: log_info <message> [key=value] ...
log_info() {
    log_json "INFO" "$@"
}

# Log WARN
# Usage: log_warn <message> [key=value] ...
log_warn() {
    log_json "WARN" "$@"
}

# Log ERROR
# Usage: log_error <message> [key=value] ...
log_error() {
    log_json "ERROR" "$@"
}

# Log CRITICAL
# Usage: log_critical <message> [key=value] ...
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
    local user_message
    user_message=$(get_user_message "$error_code" "${context_vars[@]}")

    # Map severity to log level
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
    local escaped_user_message
    escaped_user_message=$(json_escape "$user_message")

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
    json+=",\"user_message\":\"${escaped_user_message}\""

    # Add context
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
# Usage: log_with_duration <level> <message> <duration_ms> [key=value] ...
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

    # Add context
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

# Time an operation and log
# Usage: time_operation <level> <message> -- <command...>
time_operation() {
    local level="$1"
    local message="$2"
    shift 2

    # Skip --
    [[ "$1" == "--" ]] && shift

    local cmd=("$@")

    local start_time
    start_time=$(date +%s%3N)

    local exit_code=0
    local output
    if output=$("${cmd[@]}" 2>&1); then
        :
    else
        exit_code=$?
    fi

    local end_time
    end_time=$(date +%s%3N)
    local duration_ms=$((end_time - start_time))

    log_with_duration "$level" "$message" "$duration_ms" "exit_code=$exit_code"

    if [[ $exit_code -ne 0 ]]; then
        return $exit_code
    fi

    echo "$output"
}

#######################################
# Structured Logging Helpers
#######################################

# Create a logging context with trace ID
# Usage: with_trace_context <trace_id> <command...>
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

# Create a logging context with span ID
# Usage: with_span_context <span_id> <command...>
with_span_context() {
    local span_id="$1"
    shift
    local cmd=("$@")

    local old_span_id="$SPAN_ID"
    SPAN_ID="$span_id"

    "${cmd[@]}"
    local exit_code=$?

    SPAN_ID="$old_span_id"
    return $exit_code
}

# Start a new trace
# Usage: start_trace [trace_id]
start_trace() {
    TRACE_ID="${1:-$(generate_trace_id)}"
    SPAN_ID=$(generate_span_id)
    echo "$TRACE_ID"
}

# Start a new span within current trace
# Usage: start_span
start_span() {
    SPAN_ID=$(generate_span_id)
    echo "$SPAN_ID"
}

#######################################
# Log Rotation
#######################################

# Rotate log file if too large
# Usage: rotate_log_if_needed [max_size_mb]
rotate_log_if_needed() {
    local max_size_mb="${1:-10}"
    local max_size_bytes=$((max_size_mb * 1024 * 1024))

    if [[ -f "$LOG_FILE" ]]; then
        local file_size
        file_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)

        if [[ $file_size -gt $max_size_bytes ]]; then
            local backup="${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
            mv "$LOG_FILE" "$backup"

            # Compress old backup
            if command -v gzip &> /dev/null; then
                gzip "$backup" &
            fi

            # Create new empty log file
            touch "$LOG_FILE"
        fi
    fi
}

# Clean up old log files
# Usage: cleanup_old_logs [keep_count]
cleanup_old_logs() {
    local keep_count="${1:-10}"
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    local log_name
    log_name=$(basename "$LOG_FILE")

    # Find and delete old log files
    local count=0
    for file in $(ls -t "${log_dir}/${log_name}."* 2>/dev/null); do
        ((count++))
        if [[ $count -gt $keep_count ]]; then
            rm -f "$file"
        fi
    done
}

#######################################
# Text Format Logging (for compatibility)
#######################################

# Log with text format (fallback)
# Usage: log_text <level> <message> [key=value] ...
log_text() {
    local level="$1"
    local message="$2"
    shift 2
    local context_vars=("$@")

    if ! should_log "$level"; then
        return 0
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local prefix

    case "$level" in
        DEBUG)   prefix="\033[0;36m[DEBUG]\033[0m" ;;
        INFO)    prefix="\033[0;32m[INFO]\033[0m" ;;
        WARN)    prefix="\033[1;33m[WARN]\033[0m" ;;
        ERROR)   prefix="\033[0;31m[ERROR]\033[0m" ;;
        CRITICAL) prefix="\033[1;31m[CRITICAL]\033[0m" ;;
        *)       prefix="[$level]" ;;
    esac

    local context=""
    if [[ ${#context_vars[@]} -gt 0 ]]; then
        context=" ("
        local first=true
        for var in "${context_vars[@]}"; do
            if [[ "$first" != "true" ]]; then
                context+=", "
            fi
            context+="$var"
            first=false
        done
        context+=")"
    fi

    echo -e "${prefix} ${timestamp} [${COMPONENT_NAME}] ${message}${context}" >&2
}

#######################################
# Initialization
#######################################

# Initialize logger
init_logger() {
    # Ensure log directory exists
    if [[ "$LOG_OUTPUT" != "stderr" && "$LOG_OUTPUT" != "stdout" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")"
    fi

    # Generate trace ID if not set
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
export -f log_error_with_code log_with_duration time_operation
export -f with_trace_context with_span_context start_trace start_span
export -f rotate_log_if_needed cleanup_old_logs log_text init_logger
