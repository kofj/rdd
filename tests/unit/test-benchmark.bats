#!/usr/bin/env bats
#
# Unit tests for benchmark.sh
#
# Run with: bats tests/unit/test-benchmark.bats
#

# Setup test environment
setup() {
    # Set RDD_DIR to test directory
    export RDD_DIR="$(mktemp -d)"
    export SCRIPTS_DIR="${RDD_DIR}/scripts"
    export CACHE_DIR="${RDD_DIR}/cache"
    export BENCHMARK_DIR="${CACHE_DIR}/benchmark"

    # Create directories
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$BENCHMARK_DIR"

    # Copy scripts to test directory
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/benchmark.sh" "$SCRIPTS_DIR/"
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/notify.sh" "$SCRIPTS_DIR/"
    chmod +x "${SCRIPTS_DIR}/benchmark.sh"
    chmod +x "${SCRIPTS_DIR}/notify.sh"

    # Create minimal config files
    cat > "${RDD_DIR}/config.yml" <<EOF
version: "1.0.0"
stage:
  min_coverage: 20
  max_failures: 3
EOF

    cat > "${RDD_DIR}/hooks.yml" <<EOF
triggers:
  stage_complete:
    enabled: false
channels:
  wecom:
    enabled: false
EOF

    cat > "${RDD_DIR}/templates.yml" <<EOF
templates:
  stage_complete:
    title: "Stage Complete"
    body: "Stage completed"
EOF

    # Create a test hook
    mkdir -p "${RDD_DIR}/hooks"
    cat > "${RDD_DIR}/hooks/stage-complete.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
    source "${SCRIPTS_DIR}/notify.sh"
fi
log_info "Test hook executed"
EOF
    chmod +x "${RDD_DIR}/hooks/stage-complete.sh"
}

# Cleanup test environment
teardown() {
    rm -rf "${RDD_DIR}"
}

#######################################
# Test: Script exists and is executable
#######################################
@test "benchmark.sh exists and is executable" {
    [[ -x "${SCRIPTS_DIR}/benchmark.sh" ]]
}

#######################################
# Test: Help output
#######################################
@test "benchmark.sh shows help" {
    run "${SCRIPTS_DIR}/benchmark.sh" --help
    [[ $status -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Commands"* ]]
}

#######################################
# Test: get_timestamp_ms function
#######################################
@test "get_timestamp_ms returns timestamp in milliseconds" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Call the function (it will be defined when sourced, but we need to test it)
    local ts1 ts2
    ts1=$(get_timestamp_ms)
    sleep 0.1
    ts2=$(get_timestamp_ms)

    # Second timestamp should be greater
    [[ $ts2 -ge $ts1 ]]
}

#######################################
# Test: calc_duration_ms function
#######################################
@test "calc_duration_ms calculates duration correctly" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Test with known values (1 second = 1000000000 ns)
    local duration
    duration=$(calc_duration_ms 0 1000000000)

    # Should be approximately 1000ms
    [[ $duration -ge 990 ]] && [[ $duration -le 1010 ]]
}

#######################################
# Test: get_memory_kb function
#######################################
@test "get_memory_kb returns numeric value" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    local mem
    mem=$(get_memory_kb)

    # Should be a number
    [[ "$mem" =~ ^[0-9]+$ ]]
}

#######################################
# Test: calc_stats function
#######################################
@test "calc_stats calculates statistics correctly" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Test with known values
    local stats
    stats=$(calc_stats 10 20 30 40 50)

    # Parse and verify
    [[ "$stats" == *"\"count\": 5"* ]]
    [[ "$stats" == *"\"min\": 10"* ]]
    [[ "$stats" == *"\"max\": 50"* ]]
    [[ "$stats" == *"\"avg\": 30"* ]]
}

#######################################
# Test: calc_stats with empty input
#######################################
@test "calc_stats handles empty input" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    local stats
    stats=$(calc_stats)

    # Accept both formats: "count":0 or "count": 0
    [[ "$stats" == *"\"count\":0"* ]] || [[ "$stats" == *"\"count\": 0"* ]]
}

#######################################
# Test: check_target function - pass
#######################################
@test "check_target passes when value is under target" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    run check_target 50 100 "Test metric"
    [[ $status -eq 0 ]]
    [[ "$output" == *"PASS"* ]]
}

#######################################
# Test: check_target function - fail
#######################################
@test "check_target fails when value is over target" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    run check_target 150 100 "Test metric"
    [[ $status -eq 1 ]]
    [[ "$output" == *"FAIL"* ]]
}

#######################################
# Test: ensure_benchmark_dir creates directory
#######################################
@test "ensure_benchmark_dir creates directory" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Remove directory if exists
    rm -rf "${BENCHMARK_DIR}"

    # Run function
    ensure_benchmark_dir

    # Directory should exist
    [[ -d "${BENCHMARK_DIR}" ]]
}

#######################################
# Test: benchmark report generation
#######################################
@test "generate_report creates JSON file" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Create some stats files
    echo '{"count":10,"min":1,"max":10,"avg":5,"median":5,"p95":9,"p99":10}' > "${BENCHMARK_DIR}/hook_stats.json"
    echo '{"count":10,"min":10,"max":100,"avg":50,"median":50,"p95":90,"p99":95}' > "${BENCHMARK_DIR}/notification_stats.json"

    # Generate report
    generate_report

    # Check report exists
    [[ -f "${BENCHMARK_DIR}/results.json" ]]

    # Check report content
    local report
    report=$(cat "${BENCHMARK_DIR}/results.json")
    [[ "$report" == *"\"timestamp\""* ]]
    [[ "$report" == *"\"targets\""* ]]
    [[ "$report" == *"\"results\""* ]]
}

#######################################
# Test: benchmark hook with minimal iterations
#######################################
@test "benchmark_hook runs successfully" {
    export ITERATIONS=5
    export DRY_RUN=true
    export VERBOSE=false

    run "${SCRIPTS_DIR}/benchmark.sh" hook --iterations 5
    [[ $status -eq 0 ]]
    [[ "$output" == *"Hook Trigger Latency Results"* ]]
}

#######################################
# Test: benchmark config loading
#######################################
@test "benchmark_config runs successfully" {
    export ITERATIONS=5

    run "${SCRIPTS_DIR}/benchmark.sh" config --iterations 5
    [[ $status -eq 0 ]]
    [[ "$output" == *"Configuration Loading Results"* ]]
}

#######################################
# Test: benchmark memory measurement
#######################################
@test "benchmark_memory runs successfully" {
    run "${SCRIPTS_DIR}/benchmark.sh" memory
    [[ $status -eq 0 ]]
    [[ "$output" == *"Memory Usage Results"* ]]
}

#######################################
# Test: parse_args handles --iterations
#######################################
@test "parse_args handles --iterations flag" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    # Reset ITERATIONS
    ITERATIONS=100

    # Parse with new iterations
    parse_args --iterations 50

    [[ "$ITERATIONS" == "50" ]]
}

#######################################
# Test: parse_args handles --format
#######################################
@test "parse_args handles --format flag" {
    source "${SCRIPTS_DIR}/benchmark.sh"

    parse_args --format json

    [[ "$OUTPUT_FORMAT" == "json" ]]
}

#######################################
# Test: benchmark all runs all benchmarks
#######################################
@test "benchmark_all runs all benchmarks" {
    export ITERATIONS=3
    export DRY_RUN=true

    run "${SCRIPTS_DIR}/benchmark.sh" all --iterations 3
    [[ $status -eq 0 ]]
    [[ "$output" == *"Running all benchmarks"* ]]
}

#######################################
# Test: Unknown command shows error
#######################################
@test "unknown command shows error" {
    run "${SCRIPTS_DIR}/benchmark.sh" unknown_command
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown command"* ]]
}

#######################################
# Test: Version file location
#######################################
@test "version script exists" {
    # Version script is not part of benchmark tests, skip this test
    # or check the actual location
    [[ -f "${BATS_TEST_DIRNAME}/../../.rdd/scripts/version.sh" ]]
}
