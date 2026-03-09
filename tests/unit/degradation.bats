#!/usr/bin/env bats
#
# Unit tests for degradation.sh
# Tests 5-level degradation strategy

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR

    # Create temp cache directory for tests
    TEST_CACHE_DIR="$(mktemp -d)"
    export DEGRADATION_STATE_FILE="$TEST_CACHE_DIR/degradation_state.json"

    source "${RDD_DIR}/lib/error_codes.sh"
    source "${RDD_DIR}/lib/degradation.sh"

    # Reset to level 0
    reset_degradation
}

teardown() {
    rm -rf "$TEST_CACHE_DIR"
}

#######################################
# Initialization Tests
#######################################

@test "degradation: init_degradation creates state file" {
    rm -f "$DEGRADATION_STATE_FILE"

    run init_degradation
    [ "$status" -eq 0 ]
    [ -f "$DEGRADATION_STATE_FILE" ]
}

@test "degradation: initial state is level 0" {
    run get_degradation_level
    [ "$status" -eq 0 ]
    [[ "$output" == "0" ]]
}

#######################################
# Level Management Tests
#######################################

@test "get_degradation_level: returns current level" {
    set_degradation_level 2

    run get_degradation_level
    [ "$status" -eq 0 ]
    [[ "$output" == "2" ]]
}

@test "get_degradation_level_name: returns correct name for each level" {
    run get_degradation_level_name 0
    [[ "$output" == "Full Functionality" ]]

    run get_degradation_level_name 1
    [[ "$output" == "Reduced Redundancy" ]]

    run get_degradation_level_name 2
    [[ "$output" == "Essential Only" ]]

    run get_degradation_level_name 3
    [[ "$output" == "Minimal Operation" ]]

    run get_degradation_level_name 4
    [[ "$output" == "Safe Mode" ]]
}

@test "set_degradation_level: sets level correctly" {
    run set_degradation_level 3
    [ "$status" -eq 0 ]

    run get_degradation_level
    [[ "$output" == "3" ]]
}

@test "set_degradation_level: rejects invalid levels" {
    run set_degradation_level 5
    [ "$status" -eq 1 ]

    run set_degradation_level -1
    [ "$status" -eq 1 ]
}

@test "increase_degradation_level: increases level by 1" {
    set_degradation_level 2

    run increase_degradation_level
    [ "$status" -eq 0 ]

    run get_degradation_level
    [[ "$output" == "3" ]]
}

@test "increase_degradation_level: fails at max level" {
    set_degradation_level 4

    run increase_degradation_level
    [ "$status" -eq 1 ]
}

@test "decrease_degradation_level: decreases level by 1" {
    set_degradation_level 3

    run decrease_degradation_level
    [ "$status" -eq 0 ]

    run get_degradation_level
    [[ "$output" == "2" ]]
}

@test "decrease_degradation_level: fails at min level" {
    set_degradation_level 0

    run decrease_degradation_level
    [ "$status" -eq 1 ]
}

@test "reset_degradation: returns to level 0" {
    set_degradation_level 4

    reset_degradation

    run get_degradation_level
    [[ "$output" == "0" ]]
}

#######################################
# Notification Filtering Tests
#######################################

@test "should_send_notification: Level 0 allows all" {
    set_degradation_level 0

    run should_send_notification "P0"
    [ "$status" -eq 0 ]

    run should_send_notification "P1"
    [ "$status" -eq 0 ]

    run should_send_notification "P2"
    [ "$status" -eq 0 ]

    run should_send_notification "P3"
    [ "$status" -eq 0 ]
}

@test "should_send_notification: Level 1 allows all" {
    set_degradation_level 1

    run should_send_notification "P0"
    [ "$status" -eq 0 ]

    run should_send_notification "P3"
    [ "$status" -eq 0 ]
}

@test "should_send_notification: Level 2 allows P0 and P1 only" {
    set_degradation_level 2

    run should_send_notification "P0"
    [ "$status" -eq 0 ]

    run should_send_notification "P1"
    [ "$status" -eq 0 ]

    run should_send_notification "P2"
    [ "$status" -eq 1 ]

    run should_send_notification "P3"
    [ "$status" -eq 1 ]
}

@test "should_send_notification: Level 3 allows P0 only" {
    set_degradation_level 3

    run should_send_notification "P0"
    [ "$status" -eq 0 ]

    run should_send_notification "P1"
    [ "$status" -eq 1 ]

    run should_send_notification "P2"
    [ "$status" -eq 1 ]
}

@test "should_send_notification: Level 4 blocks all" {
    set_degradation_level 4

    run should_send_notification "P0"
    [ "$status" -eq 1 ]

    run should_send_notification "P3"
    [ "$status" -eq 1 ]
}

#######################################
# Retry Tests
#######################################

@test "should_retry: Level 0-2 allows retry" {
    set_degradation_level 0
    run should_retry
    [ "$status" -eq 0 ]

    set_degradation_level 1
    run should_retry
    [ "$status" -eq 0 ]

    set_degradation_level 2
    run should_retry
    [ "$status" -eq 0 ]
}

@test "should_retry: Level 3-4 disables retry" {
    set_degradation_level 3
    run should_retry
    [ "$status" -eq 1 ]

    set_degradation_level 4
    run should_retry
    [ "$status" -eq 1 ]
}

#######################################
# Channel Availability Tests
#######################################

@test "is_channel_available: Level 0 allows all channels" {
    set_degradation_level 0

    run is_channel_available "wecom"
    [ "$status" -eq 0 ]

    run is_channel_available "email"
    [ "$status" -eq 0 ]

    run is_channel_available "telegram"
    [ "$status" -eq 0 ]
}

@test "is_channel_available: Level 1 allows primary channels only" {
    set_degradation_level 1

    run is_channel_available "wecom"
    [ "$status" -eq 0 ]

    run is_channel_available "email"
    [ "$status" -eq 0 ]

    run is_channel_available "telegram"
    [ "$status" -eq 1 ]
}

@test "is_channel_available: Level 3 allows email only" {
    set_degradation_level 3

    run is_channel_available "email"
    [ "$status" -eq 0 ]

    run is_channel_available "wecom"
    [ "$status" -eq 1 ]
}

@test "is_channel_available: Level 4 blocks all channels" {
    set_degradation_level 4

    run is_channel_available "wecom"
    [ "$status" -eq 1 ]

    run is_channel_available "email"
    [ "$status" -eq 1 ]
}

#######################################
# Max Retry Attempts Tests
#######################################

@test "get_max_retry_attempts: returns correct values per level" {
    set_degradation_level 0
    run get_max_retry_attempts
    [[ "$output" == "3" ]]

    set_degradation_level 1
    run get_max_retry_attempts
    [[ "$output" == "3" ]]

    set_degradation_level 2
    run get_max_retry_attempts
    [[ "$output" == "2" ]]

    set_degradation_level 3
    run get_max_retry_attempts
    [[ "$output" == "1" ]]

    set_degradation_level 4
    run get_max_retry_attempts
    [[ "$output" == "0" ]]
}

#######################################
# Log Level Tests
#######################################

@test "get_log_level: returns correct level per degradation" {
    set_degradation_level 0
    run get_log_level
    [[ "$output" == "DEBUG" ]]

    set_degradation_level 1
    run get_log_level
    [[ "$output" == "INFO" ]]

    set_degradation_level 2
    run get_log_level
    [[ "$output" == "WARN" ]]

    set_degradation_level 3
    run get_log_level
    [[ "$output" == "ERROR" ]]

    set_degradation_level 4
    run get_log_level
    [[ "$output" == "CRITICAL" ]]
}

#######################################
# External Calls Tests
#######################################

@test "allows_external_calls: Level 0-3 allows calls" {
    set_degradation_level 0
    run allows_external_calls
    [ "$status" -eq 0 ]

    set_degradation_level 1
    run allows_external_calls
    [ "$status" -eq 0 ]

    set_degradation_level 2
    run allows_external_calls
    [ "$status" -eq 0 ]

    set_degradation_level 3
    run allows_external_calls
    [ "$status" -eq 0 ]
}

@test "allows_external_calls: Level 4 blocks calls" {
    set_degradation_level 4
    run allows_external_calls
    [ "$status" -eq 1 ]
}

#######################################
# Template Fallback Tests
#######################################

@test "use_fallback_template: Level 0-1 does not use fallback" {
    set_degradation_level 0
    run use_fallback_template
    [ "$status" -eq 1 ]

    set_degradation_level 1
    run use_fallback_template
    [ "$status" -eq 1 ]
}

@test "use_fallback_template: Level 2-4 uses fallback" {
    set_degradation_level 2
    run use_fallback_template
    [ "$status" -eq 0 ]

    set_degradation_level 3
    run use_fallback_template
    [ "$status" -eq 0 ]

    set_degradation_level 4
    run use_fallback_template
    [ "$status" -eq 0 ]
}

#######################################
# Capabilities Tests
#######################################

@test "get_degradation_capabilities: returns valid JSON" {
    set_degradation_level 0

    run get_degradation_capabilities
    [ "$status" -eq 0 ]

    if command -v jq &> /dev/null; then
        echo "$output" | jq . > /dev/null
    fi
}

@test "get_degradation_capabilities: contains required fields" {
    set_degradation_level 0

    local caps
    caps=$(get_degradation_capabilities)

    [[ "$caps" =~ '"level"' ]]
    [[ "$caps" =~ '"name"' ]]
    [[ "$caps" =~ '"notifications"' ]]
    [[ "$caps" =~ '"retry"' ]]
    [[ "$caps" =~ '"channels"' ]]
}

#######################################
# Failure Tracking Tests
#######################################

@test "record_degradation_failure: increments failure count" {
    record_degradation_failure
    record_degradation_failure

    local state
    state=$(read_degradation_state)

    if command -v jq &> /dev/null; then
        local count
        count=$(echo "$state" | jq -r '.failure_count')
        [[ "$count" == "2" ]]
    fi
}

@test "record_degradation_success: resets failure count" {
    record_degradation_failure
    record_degradation_failure
    record_degradation_failure

    record_degradation_success

    local state
    state=$(read_degradation_state)

    if command -v jq &> /dev/null; then
        local count
        count=$(echo "$state" | jq -r '.failure_count')
        [[ "$count" == "0" ]]
    fi
}

@test "auto-escalation: increases level after threshold" {
    DEGRADATION_AUTO_ADJUST="true"
    DEGRADATION_FAILURE_THRESHOLD=3

    set_degradation_level 0

    record_degradation_failure
    record_degradation_failure
    record_degradation_failure

    run get_degradation_level
    [[ "$output" == "1" ]]
}

#######################################
# Recovery Tests
#######################################

@test "check_degradation_recovery: no recovery at level 0" {
    set_degradation_level 0

    run check_degradation_recovery
    [ "$status" -eq 0 ]  # Success but no change
}

@test "decrease_degradation_level: for recovery" {
    set_degradation_level 2

    run decrease_degradation_level "test recovery"
    [ "$status" -eq 0 ]

    run get_degradation_level
    [[ "$output" == "1" ]]
}

#######################################
# Fallback Content Tests
#######################################

@test "get_fallback_content: returns content with trigger type" {
    run get_fallback_content "stage_complete" "P1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "stage_complete" ]]
    [[ "$output" =~ "P1" ]]
}

@test "get_safe_mode_message: returns safe mode message" {
    run get_safe_mode_message
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SAFE MODE" ]]
    [[ "$output" =~ "external calls are disabled" ]]
}

#######################################
# Metrics Tests
#######################################

@test "export_degradation_metrics: produces Prometheus format" {
    set_degradation_level 2

    run export_degradation_metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rdd_degradation_level 2" ]]
    [[ "$output" =~ "rdd_degradation_failure_count" ]]
}

#######################################
# Edge Cases Tests
#######################################

@test "degradation: handles rapid level changes" {
    set_degradation_level 0
    set_degradation_level 4
    set_degradation_level 2
    set_degradation_level 3
    set_degradation_level 1

    run get_degradation_level
    [[ "$output" == "1" ]]
}

@test "degradation: state persists across calls" {
    set_degradation_level 3

    # Re-source should load persisted state
    source "${RDD_DIR}/lib/degradation.sh"

    run get_degradation_level
    [[ "$output" == "3" ]]
}
