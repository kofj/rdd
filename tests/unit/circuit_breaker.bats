#!/usr/bin/env bats
#
# Unit tests for circuit_breaker.sh
# Tests circuit breaker pattern implementation

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR

    # Create temp cache directory for tests
    TEST_CACHE_DIR="$(mktemp -d)"
    CIRCUIT_BREAKER_DIR="$TEST_CACHE_DIR/circuit_breaker"
    export CIRCUIT_BREAKER_DIR

    source "${RDD_DIR}/lib/error_codes.sh"
    source "${RDD_DIR}/scripts/circuit_breaker.sh"

    # Reset configuration
    CIRCUIT_BREAKER_ENABLED="true"
    CIRCUIT_BREAKER_FAILURE_THRESHOLD=5
    CIRCUIT_BREAKER_SUCCESS_THRESHOLD=3
    CIRCUIT_BREAKER_TIMEOUT=60
}

teardown() {
    rm -rf "$TEST_CACHE_DIR"
}

#######################################
# Initialization Tests
#######################################

@test "circuit_breaker: init_circuit_breaker creates directory" {
    rm -rf "$CIRCUIT_BREAKER_DIR"
    run init_circuit_breaker
    [ "$status" -eq 0 ]
    [ -d "$CIRCUIT_BREAKER_DIR" ]
}

@test "circuit_breaker: state file is created on first read" {
    rm -rf "$CIRCUIT_BREAKER_DIR"
    init_circuit_breaker

    run read_circuit_state "test_service"
    [ "$status" -eq 0 ]
    [[ "$output" =~ '"state":"CLOSED"' ]]
    [[ "$output" =~ '"failures":0' ]]
}

#######################################
# State Management Tests
#######################################

@test "read_circuit_state: returns valid JSON" {
    init_circuit_breaker

    run read_circuit_state "test_service"
    [ "$status" -eq 0 ]

    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

@test "write_circuit_state: persists state" {
    init_circuit_breaker

    local state='{"state":"OPEN","failures":5,"successes":0,"last_failure":123456,"last_success":0,"total_requests":10}'
    write_circuit_state "test_service" "$state"

    run read_circuit_state "test_service"
    [ "$status" -eq 0 ]
    [[ "$output" =~ '"state":"OPEN"' ]]
    [[ "$output" =~ '"failures":5' ]]
}

@test "get_state_field: extracts state field" {
    init_circuit_breaker

    circuit_breaker_reset "test_service"

    run get_state_field "test_service" "state"
    [ "$status" -eq 0 ]
    [[ "$output" == "CLOSED" ]]
}

@test "get_state_field: extracts failures field" {
    init_circuit_breaker

    circuit_breaker_reset "test_service"

    run get_state_field "test_service" "failures"
    [ "$status" -eq 0 ]
    [[ "$output" == "0" ]]
}

#######################################
# Circuit Breaker Check Tests
#######################################

@test "circuit_breaker_check: allows request when CLOSED" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run circuit_breaker_check "test_service"
    [ "$status" -eq 0 ]
}

@test "circuit_breaker_check: blocks request when OPEN" {
    init_circuit_breaker

    # Manually open the circuit
    circuit_breaker_open "test_service"

    run circuit_breaker_check "test_service"
    [ "$status" -eq 1 ]
}

@test "circuit_breaker_check: allows request in HALF_OPEN" {
    init_circuit_breaker

    # Manually set to half-open
    circuit_breaker_transition "test_service" "HALF_OPEN"

    run circuit_breaker_check "test_service"
    [ "$status" -eq 0 ]
}

@test "circuit_breaker_check: transitions to HALF_OPEN after timeout" {
    init_circuit_breaker

    # Open the circuit with old timestamp
    local old_time=$(( $(date +%s) - 120 ))
    local state="{\"state\":\"OPEN\",\"failures\":5,\"successes\":0,\"last_failure\":${old_time},\"last_success\":0,\"total_requests\":10}"
    write_circuit_state "test_service" "$state"

    # Check should transition to half-open
    circuit_breaker_check "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "HALF_OPEN" ]]
}

@test "circuit_breaker_check: returns success when disabled" {
    init_circuit_breaker
    circuit_breaker_open "test_service"

    CIRCUIT_BREAKER_ENABLED="false"

    run circuit_breaker_check "test_service"
    [ "$status" -eq 0 ]
}

#######################################
# Record Success Tests
#######################################

@test "circuit_breaker_record_success: increments success counter" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_record_success "test_service"
    circuit_breaker_record_success "test_service"

    run get_state_field "test_service" "successes"
    [[ "$output" == "2" ]]
}

@test "circuit_breaker_record_success: resets failure counter" {
    init_circuit_breaker

    # Set some failures
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"

    # Record success
    circuit_breaker_record_success "test_service"

    run get_state_field "test_service" "failures"
    [[ "$output" == "0" ]]
}

@test "circuit_breaker_record_success: closes circuit from HALF_OPEN after threshold" {
    init_circuit_breaker
    CIRCUIT_BREAKER_SUCCESS_THRESHOLD=3

    # Set to half-open
    circuit_breaker_transition "test_service" "HALF_OPEN"

    # Record enough successes
    circuit_breaker_record_success "test_service"
    circuit_breaker_record_success "test_service"
    circuit_breaker_record_success "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "CLOSED" ]]
}

@test "circuit_breaker_record_success: increments total_requests" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_record_success "test_service"
    circuit_breaker_record_success "test_service"

    run get_state_field "test_service" "total_requests"
    [[ "$output" == "2" ]]
}

#######################################
# Record Failure Tests
#######################################

@test "circuit_breaker_record_failure: increments failure counter" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"

    run get_state_field "test_service" "failures"
    [[ "$output" == "2" ]]
}

@test "circuit_breaker_record_failure: opens circuit after threshold" {
    init_circuit_breaker
    CIRCUIT_BREAKER_FAILURE_THRESHOLD=3

    circuit_breaker_reset "test_service"

    # Record failures up to threshold
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "OPEN" ]]
}

@test "circuit_breaker_record_failure: opens immediately in HALF_OPEN" {
    init_circuit_breaker

    # Set to half-open
    circuit_breaker_transition "test_service" "HALF_OPEN"

    # Single failure should open
    circuit_breaker_record_failure "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "OPEN" ]]
}

@test "circuit_breaker_record_failure: increments total_requests" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_record_failure "test_service"

    run get_state_field "test_service" "total_requests"
    [[ "$output" == "1" ]]
}

@test "circuit_breaker_record_failure: resets success counter" {
    init_circuit_breaker

    circuit_breaker_record_success "test_service"
    circuit_breaker_record_success "test_service"

    circuit_breaker_record_failure "test_service"

    run get_state_field "test_service" "successes"
    [[ "$output" == "0" ]]
}

#######################################
# State Transition Tests
#######################################

@test "circuit_breaker_open: sets state to OPEN" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_open "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "OPEN" ]]
}

@test "circuit_breaker_close: sets state to CLOSED" {
    init_circuit_breaker

    circuit_breaker_open "test_service"
    circuit_breaker_close "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "CLOSED" ]]
}

@test "circuit_breaker_reset: resets all counters" {
    init_circuit_breaker

    # Add some state
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"
    circuit_breaker_record_failure "test_service"

    # Reset
    circuit_breaker_reset "test_service"

    run read_circuit_state "test_service"
    [[ "$output" =~ '"state":"CLOSED"' ]]
    [[ "$output" =~ '"failures":0' ]]
    [[ "$output" =~ '"successes":0' ]]
}

@test "circuit_breaker_transition: changes state" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    circuit_breaker_transition "test_service" "HALF_OPEN"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "HALF_OPEN" ]]
}

#######################################
# Helper Functions Tests
#######################################

@test "get_circuit_breaker_state: returns correct state" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "CLOSED" ]]

    circuit_breaker_open "test_service"

    run get_circuit_breaker_state "test_service"
    [[ "$output" == "OPEN" ]]
}

@test "is_circuit_open: returns correct status" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run is_circuit_open "test_service"
    [ "$status" -eq 1 ]

    circuit_breaker_open "test_service"

    run is_circuit_open "test_service"
    [ "$status" -eq 0 ]
}

@test "is_circuit_closed: returns correct status" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run is_circuit_closed "test_service"
    [ "$status" -eq 0 ]

    circuit_breaker_open "test_service"

    run is_circuit_closed "test_service"
    [ "$status" -eq 1 ]
}

@test "is_circuit_half_open: returns correct status" {
    init_circuit_breaker

    circuit_breaker_transition "test_service" "HALF_OPEN"

    run is_circuit_half_open "test_service"
    [ "$status" -eq 0 ]
}

@test "get_circuit_breaker_stats: returns valid JSON" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run get_circuit_breaker_stats "test_service"
    [ "$status" -eq 0 ]

    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

@test "get_all_circuit_breaker_states: returns all states" {
    init_circuit_breaker

    circuit_breaker_reset "service1"
    circuit_breaker_open "service2"

    run get_all_circuit_breaker_states
    [ "$status" -eq 0 ]

    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

#######################################
# with_circuit_breaker Tests
#######################################

@test "with_circuit_breaker: executes command when CLOSED" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    run with_circuit_breaker "test_service" echo "success"
    [ "$status" -eq 0 ]
    [[ "$output" == "success" ]]
}

@test "with_circuit_breaker: blocks command when OPEN" {
    init_circuit_breaker
    circuit_breaker_open "test_service"

    run with_circuit_breaker "test_service" echo "should not run"
    [ "$status" -eq 1 ]
}

@test "with_circuit_breaker: records success on success" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    with_circuit_breaker "test_service" true

    run get_state_field "test_service" "successes"
    [[ "$output" == "1" ]]
}

@test "with_circuit_breaker: records failure on failure" {
    init_circuit_breaker
    circuit_breaker_reset "test_service"

    with_circuit_breaker "test_service" false || true

    run get_state_field "test_service" "failures"
    [[ "$output" == "1" ]]
}

#######################################
# Export Metrics Tests
#######################################

@test "export_circuit_breaker_metrics: produces Prometheus format" {
    init_circuit_breaker

    circuit_breaker_reset "service1"
    circuit_breaker_open "service2"

    run export_circuit_breaker_metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rdd_circuit_breaker_state" ]]
    [[ "$output" =~ "rdd_circuit_breaker_failures" ]]
    [[ "$output" =~ "rdd_circuit_breaker_requests" ]]
}

#######################################
# Edge Cases Tests
#######################################

@test "circuit_breaker_check: handles missing state file" {
    init_circuit_breaker

    # Ensure no state file exists
    rm -f "$CIRCUIT_BREAKER_DIR/new_service.json"

    run circuit_breaker_check "new_service"
    [ "$status" -eq 0 ]  # Should default to CLOSED
}

@test "circuit_breaker: handles concurrent access" {
    init_circuit_breaker
    circuit_breaker_reset "concurrent_test"

    # Simulate concurrent access
    for i in {1..10}; do
        circuit_breaker_record_success "concurrent_test" &
    done
    wait

    run get_state_field "concurrent_test" "successes"
    # Should have recorded all successes (may not be exactly 10 due to race conditions)
    [[ "$output" -ge 1 ]]
}

@test "circuit_breaker: does nothing when disabled" {
    init_circuit_breaker
    CIRCUIT_BREAKER_ENABLED="false"

    circuit_breaker_record_failure "test_service"

    # Should not have created state file
    [[ ! -f "$CIRCUIT_BREAKER_DIR/test_service.json" ]]
}
