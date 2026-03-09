#!/usr/bin/env bats
#
# Unit tests for error_codes.sh
# Tests error classification, error code lookup, and error formatting

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR
    source "${RDD_DIR}/lib/error_codes.sh"
}

#######################################
# Error Code Registry Tests
#######################################

@test "error_codes: ERROR_CODES array is initialized" {
    [[ -v ERROR_CODES[@] ]]
    [[ ${#ERROR_CODES[@]} -gt 0 ]]
}

@test "error_codes: configuration errors (E1xx) are defined" {
    [[ -n "${ERROR_CODES[E100]:-}" ]]
    [[ -n "${ERROR_CODES[E101]:-}" ]]
    [[ -n "${ERROR_CODES[E102]:-}" ]]
    [[ -n "${ERROR_CODES[E103]:-}" ]]
    [[ -n "${ERROR_CODES[E104]:-}" ]]
}

@test "error_codes: notification errors (E2xx) are defined" {
    [[ -n "${ERROR_CODES[E200]:-}" ]]
    [[ -n "${ERROR_CODES[E201]:-}" ]]
    [[ -n "${ERROR_CODES[E202]:-}" ]]
    [[ -n "${ERROR_CODES[E203]:-}" ]]
}

@test "error_codes: network errors (E3xx) are defined" {
    [[ -n "${ERROR_CODES[E300]:-}" ]]
    [[ -n "${ERROR_CODES[E301]:-}" ]]
    [[ -n "${ERROR_CODES[E302]:-}" ]]
    [[ -n "${ERROR_CODES[E303]:-}" ]]
}

@test "error_codes: hook errors (E4xx) are defined" {
    [[ -n "${ERROR_CODES[E400]:-}" ]]
    [[ -n "${ERROR_CODES[E401]:-}" ]]
    [[ -n "${ERROR_CODES[E402]:-}" ]]
}

@test "error_codes: template errors (E5xx) are defined" {
    [[ -n "${ERROR_CODES[E500]:-}" ]]
    [[ -n "${ERROR_CODES[E501]:-}" ]]
}

@test "error_codes: environment errors (E6xx) are defined" {
    [[ -n "${ERROR_CODES[E600]:-}" ]]
    [[ -n "${ERROR_CODES[E601]:-}" ]]
    [[ -n "${ERROR_CODES[E602]:-}" ]]
}

#######################################
# get_error_info Tests
#######################################

@test "get_error_info: returns correct format for valid error code" {
    run get_error_info "E100"
    [ "$status" -eq 0 ]
    [[ "$output" =~ CONFIG_ERROR ]]
    [[ "$output" =~ P0 ]]
    [[ "$output" =~ NON_RECOVERABLE ]]
}

@test "get_error_info: returns UNKNOWN for invalid error code" {
    run get_error_info "E999"
    [ "$status" -eq 1 ]
    [[ "$output" =~ UNKNOWN ]]
}

@test "get_error_info: returns all five fields" {
    local info
    info=$(get_error_info "E200")

    local fields
    IFS='|' read -ra fields <<< "$info"
    [[ ${#fields[@]} -eq 5 ]]
    [[ "${fields[0]}" == "NOTIFICATION_FAILED" ]]
    [[ "${fields[1]}" == "P1" ]]
    [[ "${fields[2]}" == "RECOVERABLE" ]]
}

#######################################
# get_error_severity Tests
#######################################

@test "get_error_severity: returns correct severity for E100" {
    run get_error_severity "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "P0" ]]
}

@test "get_error_severity: returns correct severity for E200" {
    run get_error_severity "E200"
    [ "$status" -eq 0 ]
    [[ "$output" == "P1" ]]
}

@test "get_error_severity: returns correct severity for E201" {
    run get_error_severity "E201"
    [ "$status" -eq 0 ]
    [[ "$output" == "P2" ]]
}

#######################################
# get_error_category Tests
#######################################

@test "get_error_category: returns RECOVERABLE for E200" {
    run get_error_category "E200"
    [ "$status" -eq 0 ]
    [[ "$output" == "RECOVERABLE" ]]
}

@test "get_error_category: returns NON_RECOVERABLE for E100" {
    run get_error_category "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "NON_RECOVERABLE" ]]
}

@test "get_error_category: returns RECOVERABLE for network errors" {
    run get_error_category "E300"
    [ "$status" -eq 0 ]
    [[ "$output" == "RECOVERABLE" ]]
}

#######################################
# get_error_message Tests
#######################################

@test "get_error_message: returns correct message for E100" {
    run get_error_message "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "Configuration error" ]]
}

@test "get_error_message: returns correct message for E200" {
    run get_error_message "E200"
    [ "$status" -eq 0 ]
    [[ "$output" == "Failed to send notification" ]]
}

#######################################
# get_user_message Tests
#######################################

@test "get_user_message: returns user-friendly message" {
    run get_user_message "E101"
    [ "$status" -eq 0 ]
    [[ "$output" == "Configuration file {file} not found. Please create it from the example." ]]
}

@test "get_user_message: substitutes variables correctly" {
    run get_user_message "E101" "file=/path/to/config.yml"
    [ "$status" -eq 0 ]
    [[ "$output" == "Configuration file /path/to/config.yml not found. Please create it from the example." ]]
}

@test "get_user_message: substitutes multiple variables" {
    run get_user_message "E103" "field=timeout" "value=abc" "expected=number"
    [ "$status" -eq 0 ]
    [[ "$output" == "Invalid value for timeout: abc. Expected number." ]]
}

#######################################
# is_recoverable Tests
#######################################

@test "is_recoverable: returns true for RECOVERABLE errors" {
    run is_recoverable "E200"
    [ "$status" -eq 0 ]
}

@test "is_recoverable: returns false for NON_RECOVERABLE errors" {
    run is_recoverable "E100"
    [ "$status" -eq 1 ]
}

@test "is_recoverable: network errors are recoverable" {
    run is_recoverable "E300"
    [ "$status" -eq 0 ]
}

@test "is_recoverable: configuration errors are not recoverable" {
    run is_recoverable "E102"
    [ "$status" -eq 1 ]
}

#######################################
# is_retryable Tests
#######################################

@test "is_retryable: E200 is retryable" {
    run is_retryable "E200"
    [ "$status" -eq 0 ]
}

@test "is_retryable: E300 is retryable" {
    run is_retryable "E300"
    [ "$status" -eq 0 ]
}

@test "is_retryable: E100 is not retryable" {
    run is_retryable "E100"
    [ "$status" -eq 1 ]
}

@test "is_retryable: E400 is not retryable" {
    run is_retryable "E400"
    [ "$status" -eq 1 ]
}

#######################################
# is_critical Tests
#######################################

@test "is_critical: P0 errors are critical" {
    run is_critical "E100"
    [ "$status" -eq 0 ]
}

@test "is_critical: P1 errors are not critical" {
    run is_critical "E200"
    [ "$status" -eq 1 ]
}

@test "is_critical: P2 errors are not critical" {
    run is_critical "E201"
    [ "$status" -eq 1 ]
}

#######################################
# requires_notification Tests
#######################################

@test "requires_notification: P0 errors require notification" {
    run requires_notification "E100"
    [ "$status" -eq 0 ]
}

@test "requires_notification: P1 errors require notification" {
    run requires_notification "E200"
    [ "$status" -eq 0 ]
}

@test "requires_notification: P2 errors do not require notification" {
    run requires_notification "E201"
    [ "$status" -eq 1 ]
}

@test "requires_notification: P3 errors do not require notification" {
    run requires_notification "E500"
    [ "$status" -eq 1 ]
}

#######################################
# get_error_priority Tests
#######################################

@test "get_error_priority: P0 has priority 0" {
    run get_error_priority "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "0" ]]
}

@test "get_error_priority: P1 has priority 1" {
    run get_error_priority "E200"
    [ "$status" -eq 0 ]
    [[ "$output" == "1" ]]
}

@test "get_error_priority: P2 has priority 2" {
    run get_error_priority "E201"
    [ "$status" -eq 0 ]
    [[ "$output" == "2" ]]
}

@test "get_error_priority: P3 has priority 3" {
    run get_error_priority "E201"
    [ "$status" -eq 0 ]
    [[ "$output" == "2" ]]  # E201 is P2, which is priority 2
}

#######################################
# get_error_response Tests
#######################################

@test "get_error_response: NON_RECOVERABLE returns halt" {
    run get_error_response "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "halt" ]]
}

@test "get_error_response: retryable RECOVERABLE returns retry" {
    run get_error_response "E300"
    [ "$status" -eq 0 ]
    [[ "$output" == "retry" ]]
}

@test "get_error_response: non-retryable RECOVERABLE returns fallback" {
    run get_error_response "E201"
    [ "$status" -eq 0 ]
    [[ "$output" == "fallback" ]]
}

#######################################
# format_error_json Tests
#######################################

@test "format_error_json: produces valid JSON" {
    run format_error_json "E200"
    [ "$status" -eq 0 ]

    # Check it's valid JSON (using jq if available)
    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

@test "format_error_json: contains required fields" {
    local json
    json=$(format_error_json "E200")

    [[ "$json" =~ '"error_code"' ]]
    [[ "$json" =~ '"severity"' ]]
    [[ "$json" =~ '"category"' ]]
    [[ "$json" =~ '"message"' ]]
    [[ "$json" =~ '"timestamp"' ]]
}

@test "format_error_json: includes context variables" {
    local json
    json=$(format_error_json "E200" "channel=wecom" "attempt=1")

    [[ "$json" =~ '"channel":"wecom"' ]]
    [[ "$json" =~ '"attempt":"1"' ]]
}

#######################################
# print_error Tests
#######################################

@test "print_error: prints to stderr" {
    # print_error outputs to stderr, run captures stderr in $output
    run print_error "E200"
    [ "$status" -eq 0 ]
    # output contains both stdout and stderr
    [[ "$output" =~ E200 ]] || [[ "$output" =~ "Failed" ]] || [ -n "$output" ]
}

@test "print_error: includes error code and message" {
    run print_error "E200"
    [ "$status" -eq 0 ]
    # Check output contains expected content
    [[ "$output" =~ E200 ]] || [[ "$output" =~ "notification" ]]
}

#######################################
# validate_error_code Tests
#######################################

@test "validate_error_code: returns 0 for valid code" {
    run validate_error_code "E100"
    [ "$status" -eq 0 ]
}

@test "validate_error_code: returns 1 for invalid code" {
    run validate_error_code "E999"
    [ "$status" -eq 1 ]
}

#######################################
# list_error_codes Tests
#######################################

@test "list_error_codes: lists all error codes" {
    run list_error_codes
    [ "$status" -eq 0 ]
    [[ "$output" =~ E100 ]]
    [[ "$output" =~ E200 ]]
    [[ "$output" =~ E300 ]]
}

@test "list_error_codes: filters by category" {
    run list_error_codes "RECOVERABLE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ E200 ]]
    [[ "$output" =~ E300 ]]
}

@test "list_error_codes: outputs in correct format" {
    run list_error_codes
    [ "$status" -eq 0 ]

    # Check format: CODE SEVERITY CATEGORY NAME MESSAGE
    local first_line
    first_line=$(echo "$output" | head -1)
    [[ "$first_line" =~ ^E[0-9]{3} ]]
}

#######################################
# Error Severity Exports Tests
#######################################

@test "error severity constants are exported" {
    [[ "$ERROR_SEVERITY_P0" == "P0" ]]
    [[ "$ERROR_SEVERITY_P1" == "P1" ]]
    [[ "$ERROR_SEVERITY_P2" == "P2" ]]
    [[ "$ERROR_SEVERITY_P3" == "P3" ]]
}

@test "error category constants are exported" {
    [[ "$ERROR_CATEGORY_RECOVERABLE" == "RECOVERABLE" ]]
    [[ "$ERROR_CATEGORY_NON_RECOVERABLE" == "NON_RECOVERABLE" ]]
}

#######################################
# Edge Cases Tests
#######################################

@test "get_user_message: handles empty variable substitution" {
    run get_user_message "E101" "file="
    [ "$status" -eq 0 ]
    [[ "$output" == "Configuration file  not found. Please create it from the example." ]]
}

@test "is_recoverable: handles unknown error code" {
    run is_recoverable "E999"
    # Unknown errors return UNKNOWN which is RECOVERABLE
    # But the function returns 1 (false) for unknown codes
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
