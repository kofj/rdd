#!/usr/bin/env bats
#
# Unit tests for retry.sh
# Tests exponential backoff, jitter, and retry logic

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR
    source "${RDD_DIR}/lib/error_codes.sh"
    source "${RDD_DIR}/scripts/retry.sh"

    # Reset retry configuration to defaults
    RETRY_MAX_ATTEMPTS=3
    RETRY_INITIAL_DELAY=1
    RETRY_MAX_DELAY=30
    RETRY_BACKOFF_MULTIPLIER=2
    RETRY_JITTER="false"  # Disable jitter for predictable tests
    RETRY_JITTER_RANGE=0.5
}

#######################################
# calculate_delay Tests
#######################################

@test "calculate_delay: returns base delay when jitter is disabled" {
    RETRY_JITTER="false"
    run calculate_delay 5
    [ "$status" -eq 0 ]
    [[ "$output" == "5" ]]
}

@test "calculate_delay: returns at least 1" {
    RETRY_JITTER="true"
    run calculate_delay 0
    [ "$status" -eq 0 ]
    [[ "$output" -ge 1 ]]
}

@test "calculate_delay: adds jitter when enabled" {
    RETRY_JITTER="true"
    # Run multiple times to verify jitter is applied
    local delays=()
    for i in {1..10}; do
        delays+=("$(calculate_delay 10)")
    done

    # At least some delays should be different due to jitter
    local unique_delays
    unique_delays=$(printf '%s\n' "${delays[@]}" | sort -u | wc -l)
    [[ $unique_delays -gt 1 ]]
}

#######################################
# calculate_next_delay Tests
#######################################

@test "calculate_next_delay: multiplies by backoff multiplier" {
    run calculate_next_delay 2
    [ "$status" -eq 0 ]
    [[ "$output" == "4" ]]
}

@test "calculate_next_delay: respects max delay" {
    RETRY_MAX_DELAY=10
    run calculate_next_delay 10
    [ "$status" -eq 0 ]
    [[ "$output" == "10" ]]
}

@test "calculate_next_delay: caps at max delay" {
    RETRY_MAX_DELAY=30
    run calculate_next_delay 20
    [ "$status" -eq 0 ]
    [[ "$output" == "30" ]]
}

#######################################
# retry_with_backoff Tests
####################################@

@test "retry_with_backoff: succeeds on first attempt" {
    run retry_with_backoff -- echo "success"
    [ "$status" -eq 0 ]
    [[ "$output" == "success" ]]
}

@test "retry_with_backoff: retries on failure and eventually succeeds" {
    # Create a counter file with unique name
    local counter_file="/tmp/retry_counter_${BATS_TEST_NAME}_$RANDOM"

    # Create a script that fails twice then succeeds
    cat > /tmp/test_retry.sh << EOF
#!/bin/bash
COUNTER_FILE="$counter_file"
if [[ ! -f "\$COUNTER_FILE" ]]; then
    echo 0 > "\$COUNTER_FILE"
fi
COUNT=\$(cat "\$COUNTER_FILE")
COUNT=\$((COUNT + 1))
echo "\$COUNT" > "\$COUNTER_FILE"
if [[ \$COUNT -lt 3 ]]; then
    exit 1
fi
echo "success after \$COUNT attempts"
EOF
    chmod +x /tmp/test_retry.sh

    run retry_with_backoff --attempts 5 --delay 0 -- /tmp/test_retry.sh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "success after" ]]

    rm -f /tmp/test_retry.sh "$counter_file"
}

@test "retry_with_backoff: fails after max attempts" {
    run retry_with_backoff --attempts 2 --delay 0 -- false
    [ "$status" -eq 1 ]
}

@test "retry_with_backoff: respects max attempts" {
    # Use a counter file to track attempts across subshells
    local counter_file="/tmp/max_attempts_counter_$RANDOM"
    rm -f "$counter_file"

    # Create a script that always fails and counts attempts
    cat > /tmp/test_max_attempts.sh << EOF
#!/bin/bash
COUNTER_FILE="$counter_file"
if [[ ! -f "\$COUNTER_FILE" ]]; then
    echo 0 > "\$COUNTER_FILE"
fi
COUNT=\$(cat "\$COUNTER_FILE")
COUNT=\$((COUNT + 1))
echo "\$COUNT" > "\$COUNTER_FILE"
exit 1
EOF
    chmod +x /tmp/test_max_attempts.sh

    run retry_with_backoff --attempts 3 --delay 0 -- /tmp/test_max_attempts.sh

    # Should have attempted 3 times
    [[ -f "$counter_file" ]]
    local attempts=$(cat "$counter_file")
    [[ $attempts -eq 3 ]]

    rm -f /tmp/test_max_attempts.sh "$counter_file"
}

@test "retry_with_backoff: --no-jitter disables jitter" {
    RETRY_JITTER="true"
    run retry_with_backoff --no-jitter --delay 0 -- echo "test"
    [ "$status" -eq 0 ]
}

@test "retry_with_backoff: handles empty command" {
    run retry_with_backoff
    [ "$status" -eq 1 ]
}

@test "retry_with_backoff: captures command output" {
    run retry_with_backoff -- echo "captured output"
    [ "$status" -eq 0 ]
    [[ "$output" == "captured output" ]]
}

@test "retry_with_backoff: captures command stderr" {
    run retry_with_backoff -- bash -c 'echo "stderr" >&2; false'
    [ "$status" -eq 1 ]
    [[ "$output" =~ "stderr" || "$stderr" =~ "stderr" ]]
}

#######################################
# retry_simple Tests
#######################################

@test "retry_simple: succeeds on first attempt" {
    run retry_simple 3 echo "success"
    [ "$status" -eq 0 ]
    [[ "$output" == "success" ]]
}

@test "retry_simple: retries specified number of times" {
    run retry_simple 2 false
    [ "$status" -eq 1 ]
}

@test "retry_simple: eventually succeeds" {
    # Use a unique counter file
    local counter_file="/tmp/simple_counter_${BATS_TEST_NAME}_$RANDOM"

    cat > /tmp/test_simple.sh << EOF
#!/bin/bash
COUNTER_FILE="$counter_file"
if [[ ! -f "\$COUNTER_FILE" ]]; then
    echo 0 > "\$COUNTER_FILE"
fi
COUNT=\$(cat "\$COUNTER_FILE")
COUNT=\$((COUNT + 1))
echo "\$COUNT" > "\$COUNTER_FILE"
if [[ \$COUNT -lt 2 ]]; then
    exit 1
fi
echo "success"
EOF
    chmod +x /tmp/test_simple.sh

    run retry_simple 5 /tmp/test_simple.sh
    [ "$status" -eq 0 ]

    rm -f /tmp/test_simple.sh "$counter_file"
}

#######################################
# get_retry_strategy Tests
#######################################

@test "get_retry_strategy: returns none for non-retryable errors" {
    run get_retry_strategy "E100"
    [ "$status" -eq 0 ]
    [[ "$output" == "none" ]]
}

@test "get_retry_strategy: returns backoff for network timeout" {
    run get_retry_strategy "E300"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "backoff" ]]
}

@test "get_retry_strategy: returns backoff for rate limit" {
    run get_retry_strategy "E302"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "backoff" ]]
    [[ "$output" =~ "initial=2" ]]
    [[ "$output" =~ "max=60" ]]
}

@test "get_retry_strategy: returns default for unknown retryable" {
    run get_retry_strategy "E700"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "default" ]]
}

#######################################
# Retry Statistics Tests
#######################################

@test "record_retry_attempt: tracks total attempts" {
    reset_retry_stats

    record_retry_attempt "test_op" "true"
    record_retry_attempt "test_op" "false"
    record_retry_attempt "test_op" "true"

    run get_retry_stats "test_op"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "total=3" ]]
    [[ "$output" =~ "success=2" ]]
    [[ "$output" =~ "failed=1" ]]
}

@test "get_retry_stats: returns all stats without argument" {
    reset_retry_stats

    record_retry_attempt "op1" "true"
    record_retry_attempt "op2" "false"

    run get_retry_stats
    [ "$status" -eq 0 ]
    [[ "$output" =~ "op1_total=1" ]]
    [[ "$output" =~ "op2_total=1" ]]
}

@test "reset_retry_stats: clears all statistics" {
    record_retry_attempt "test" "true"

    reset_retry_stats

    run get_retry_stats "test"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "total=0" ]]
}

#######################################
# RETRY_LAST_* Variables Tests
#######################################

@test "RETRY_LAST_ATTEMPT is set after retry" {
    RETRY_JITTER="false"

    retry_with_backoff --attempts 2 --delay 0 -- false || true

    [[ $RETRY_LAST_ATTEMPT -eq 2 ]]
}

@test "RETRY_LAST_ERROR is set on failure" {
    RETRY_JITTER="false"

    retry_with_backoff --attempts 1 --delay 0 -- bash -c 'echo "error message" >&2; exit 1' || true

    [[ "$RETRY_LAST_ERROR" =~ "error message" ]]
}

#######################################
# Configuration Override Tests
#######################################

@test "retry_with_backoff: --attempts overrides config" {
    # Use a counter file to track attempts across subshells
    local counter_file="/tmp/attempts_override_counter_$RANDOM"
    rm -f "$counter_file"

    # Create a script that fails 3 times then succeeds
    cat > /tmp/test_attempts_override.sh << EOF
#!/bin/bash
COUNTER_FILE="$counter_file"
if [[ ! -f "\$COUNTER_FILE" ]]; then
    echo 0 > "\$COUNTER_FILE"
fi
COUNT=\$(cat "\$COUNTER_FILE")
COUNT=\$((COUNT + 1))
echo "\$COUNT" > "\$COUNTER_FILE"
if [[ \$COUNT -lt 4 ]]; then
    exit 1
fi
echo "done"
EOF
    chmod +x /tmp/test_attempts_override.sh

    run retry_with_backoff --attempts 5 --delay 0 -- /tmp/test_attempts_override.sh

    # Should succeed on 4th attempt (within 5 max attempts)
    [ "$status" -eq 0 ]
    [[ -f "$counter_file" ]]
    local attempts=$(cat "$counter_file")
    [[ $attempts -ge 4 ]]

    rm -f /tmp/test_attempts_override.sh "$counter_file"
}

@test "retry_with_backoff: --delay overrides config" {
    RETRY_INITIAL_DELAY=10

    local start end
    start=$(date +%s)
    retry_with_backoff --delay 0 --attempts 2 -- false || true
    end=$(date +%s)

    # Should complete quickly with delay=0
    local duration=$((end - start))
    [[ $duration -lt 5 ]]
}

#######################################
# Edge Cases Tests
#######################################

@test "retry_with_backoff: handles command with arguments" {
    run retry_with_backoff -- echo "arg1" "arg2" "arg3"
    [ "$status" -eq 0 ]
    [[ "$output" == "arg1 arg2 arg3" ]]
}

@test "retry_with_backoff: handles command with special characters" {
    run retry_with_backoff -- bash -c 'echo "special: $HOME"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "special:" ]]
}

@test "retry_with_backoff: handles very quick success" {
    run retry_with_backoff -- true
    [ "$status" -eq 0 ]
}

@test "retry_with_backoff: handles exit code preservation" {
    run retry_with_backoff --attempts 1 -- bash -c 'exit 42'
    [ "$status" -eq 42 ]
}
