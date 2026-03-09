#!/usr/bin/env bats
#
# Unit tests for logger.sh
# Tests structured JSON logging

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

bats_require_minimum_version 1.5.0

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR

    # Create temp directory for test logs
    TEST_LOG_DIR="$(mktemp -d)"
    export LOG_FILE="$TEST_LOG_DIR/test.log"
    export LOG_FORMAT="json"
    export LOG_LEVEL="DEBUG"
    export LOG_OUTPUT="file"
    export LOG_INCLUDE_TRACE_ID="true"
    export LOG_INCLUDE_CONTEXT="true"
    export COMPONENT_NAME="test_component"
    export RDD_PROJECT="test_project"
    export RDD_STAGE="test_stage"

    source "${RDD_DIR}/lib/error_codes.sh"
    source "${RDD_DIR}/scripts/logger.sh"
}

teardown() {
    rm -rf "$TEST_LOG_DIR"
}

#######################################
# Log Level Tests
#######################################

@test "logger: should_log returns correct values" {
    LOG_LEVEL="DEBUG"

    run should_log "DEBUG"
    [ "$status" -eq 0 ]

    run should_log "INFO"
    [ "$status" -eq 0 ]

    LOG_LEVEL="WARN"

    run should_log "DEBUG"
    [ "$status" -eq 1 ]

    run should_log "INFO"
    [ "$status" -eq 1 ]

    run should_log "WARN"
    [ "$status" -eq 0 ]

    run should_log "ERROR"
    [ "$status" -eq 0 ]
}

@test "logger: log level priority is correct" {
    [[ ${LOG_LEVEL_PRIORITY[DEBUG]} -eq 0 ]]
    [[ ${LOG_LEVEL_PRIORITY[INFO]} -eq 1 ]]
    [[ ${LOG_LEVEL_PRIORITY[WARN]} -eq 2 ]]
    [[ ${LOG_LEVEL_PRIORITY[ERROR]} -eq 3 ]]
    [[ ${LOG_LEVEL_PRIORITY[CRITICAL]} -eq 4 ]]
}

#######################################
# JSON Generation Tests
#######################################

@test "generate_trace_id: returns non-empty string" {
    run generate_trace_id
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
}

@test "generate_span_id: returns non-empty string" {
    run generate_span_id
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
}

@test "format_timestamp: returns ISO8601 format" {
    run format_timestamp
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

@test "json_escape: escapes special characters" {
    run json_escape 'test "quoted" value'
    [ "$status" -eq 0 ]
    [[ "$output" == 'test \"quoted\" value' ]]
}

@test "json_escape: escapes newlines" {
    run json_escape $'line1\nline2'
    [ "$status" -eq 0 ]
    [[ "$output" == 'line1\nline2' ]]
}

@test "json_escape: escapes backslashes" {
    run json_escape 'path\to\file'
    [ "$status" -eq 0 ]
    [[ "$output" == 'path\\to\\file' ]]
}

#######################################
# build_json_log Tests
#######################################

@test "build_json_log: creates valid JSON" {
    run build_json_log "INFO" "test message"
    [ "$status" -eq 0 ]

    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

@test "build_json_log: includes required fields" {
    local json
    json=$(build_json_log "INFO" "test message")

    [[ "$json" =~ '"timestamp"' ]]
    [[ "$json" =~ '"level":"INFO"' ]]
    [[ "$json" =~ '"message":"test message"' ]]
    [[ "$json" =~ '"component":"test_component"' ]]
}

@test "build_json_log: includes trace_id when set" {
    TRACE_ID="test-trace-123"

    local json
    json=$(build_json_log "INFO" "test message")

    [[ "$json" =~ '"trace_id":"test-trace-123"' ]]
}

@test "build_json_log: includes span_id when set" {
    SPAN_ID="span-456"

    local json
    json=$(build_json_log "INFO" "test message")

    [[ "$json" =~ '"span_id":"span-456"' ]]
}

@test "build_json_log: includes RDD context" {
    local json
    json=$(build_json_log "INFO" "test message")

    [[ "$json" =~ '"rdd_project":"test_project"' ]]
    [[ "$json" =~ '"rdd_stage":"test_stage"' ]]
}

@test "build_json_log: includes context variables" {
    local json
    json=$(build_json_log "INFO" "test message" "key1=value1" "key2=value2")

    [[ "$json" =~ '"key1":"value1"' ]]
    [[ "$json" =~ '"key2":"value2"' ]]
}

@test "build_json_log: escapes special characters in message" {
    local json
    json=$(build_json_log "INFO" 'message with "quotes"')

    [[ "$json" =~ '\"quotes\"' ]]
}

#######################################
# Core Logging Functions Tests
#######################################

@test "log_json: writes to file when LOG_OUTPUT is file" {
    rm -f "$LOG_FILE"

    log_json "INFO" "test message"

    [[ -f "$LOG_FILE" ]]
    [[ "$(cat "$LOG_FILE")" =~ "test message" ]]
}

@test "log_json: respects log level" {
    LOG_LEVEL="WARN"
    rm -f "$LOG_FILE"

    log_json "DEBUG" "debug message"
    log_json "WARN" "warn message"

    [[ ! "$(cat "$LOG_FILE")" =~ "debug message" ]]
    [[ "$(cat "$LOG_FILE")" =~ "warn message" ]]
}

@test "log_debug: creates DEBUG level log" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_debug "debug test"

    [[ "$(cat "$LOG_FILE")" =~ '"level":"DEBUG"' ]]
}

@test "log_info: creates INFO level log" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_info "info test"

    [[ "$(cat "$LOG_FILE")" =~ '"level":"INFO"' ]]
}

@test "log_warn: creates WARN level log" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_warn "warn test"

    [[ "$(cat "$LOG_FILE")" =~ '"level":"WARN"' ]]
}

@test "log_error: creates ERROR level log" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_error "error test"

    [[ "$(cat "$LOG_FILE")" =~ '"level":"ERROR"' ]]
}

@test "log_critical: creates CRITICAL level log" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_critical "critical test"

    [[ "$(cat "$LOG_FILE")" =~ '"level":"CRITICAL"' ]]
}

#######################################
# Error Logging Tests
#######################################

@test "log_error_with_code: includes error code" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_error_with_code "E200" "notification failed" "channel=wecom"

    local content
    content=$(cat "$LOG_FILE")

    [[ "$content" =~ '"error_code":"E200"' ]]
    [[ "$content" =~ '"error_category":"RECOVERABLE"' ]]
    [[ "$content" =~ '"severity":"P1"' ]]
}

@test "log_error_with_code: maps severity to log level" {
    LOG_LEVEL="DEBUG"

    # P0 -> CRITICAL
    rm -f "$LOG_FILE"
    log_error_with_code "E100" "config error"
    [[ "$(cat "$LOG_FILE")" =~ '"level":"CRITICAL"' ]]

    # P1 -> ERROR
    rm -f "$LOG_FILE"
    log_error_with_code "E200" "notification error"
    [[ "$(cat "$LOG_FILE")" =~ '"level":"ERROR"' ]]

    # P2 -> WARN
    rm -f "$LOG_FILE"
    log_error_with_code "E201" "channel disabled"
    [[ "$(cat "$LOG_FILE")" =~ '"level":"WARN"' ]]
}

@test "log_error_with_code: includes context" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_error_with_code "E101" "config not found" "file=/path/to/config.yml"

    [[ "$(cat "$LOG_FILE")" =~ '"file":"/path/to/config.yml"' ]]
}

#######################################
# Performance Logging Tests
#######################################

@test "log_with_duration: includes duration_ms" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    log_with_duration "INFO" "operation completed" 1500

    [[ "$(cat "$LOG_FILE")" =~ '"duration_ms":1500' ]]
}

@test "log_with_duration: respects log level" {
    LOG_LEVEL="WARN"
    rm -f "$LOG_FILE"

    log_with_duration "DEBUG" "operation" 100

    [[ ! -f "$LOG_FILE" ]] || [[ ! "$(cat "$LOG_FILE")" =~ "operation" ]]
}

#######################################
# Context Functions Tests
#######################################

@test "with_trace_context: sets trace ID" {
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    with_trace_context "trace-123" log_info "test message"

    [[ "$(cat "$LOG_FILE")" =~ '"trace_id":"trace-123"' ]]
}

@test "with_trace_context: restores previous trace ID" {
    TRACE_ID="original-trace"
    LOG_LEVEL="DEBUG"
    rm -f "$LOG_FILE"

    with_trace_context "temp-trace" log_info "test message"

    [[ "$TRACE_ID" == "original-trace" ]]
}

@test "start_trace: creates new trace ID" {
    TRACE_ID=""

    # Use temp file to capture output while running in current shell
    # (command substitution would run in subshell and lose global var)
    local temp_file
    temp_file=$(mktemp)
    start_trace > "$temp_file"
    local output
    output=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ -n "$output" ]]
    [[ "$TRACE_ID" == "$output" ]]
}

@test "start_span: creates new span ID" {
    SPAN_ID=""

    # Use temp file to capture output while running in current shell
    # (command substitution would run in subshell and lose global var)
    local temp_file
    temp_file=$(mktemp)
    start_span > "$temp_file"
    local output
    output=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ -n "$output" ]]
    [[ "$SPAN_ID" == "$output" ]]
}

#######################################
# Output Tests
#######################################

@test "output_log: writes to stderr when LOG_OUTPUT=stderr" {
    LOG_OUTPUT="stderr"

    run --separate-stderr output_log '{"test":"value"}'
    [ "$status" -eq 0 ]
    [[ "$stderr" == '{"test":"value"}' ]]
}

@test "output_log: writes to stdout when LOG_OUTPUT=stdout" {
    LOG_OUTPUT="stdout"

    run output_log '{"test":"value"}'
    [ "$status" -eq 0 ]
    [[ "$output" == '{"test":"value"}' ]]
}

#######################################
# Initialization Tests
#######################################

@test "init_logger: creates log directory" {
    LOG_FILE="/tmp/test_logs/rdd/test.log"
    LOG_OUTPUT="file"

    init_logger

    [[ -d "/tmp/test_logs/rdd" ]]
    rm -rf /tmp/test_logs
}

@test "init_logger: generates trace ID if not set" {
    TRACE_ID=""

    init_logger

    [[ -n "$TRACE_ID" ]]
}
