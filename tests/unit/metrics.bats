#!/usr/bin/env bats
#
# Unit tests for metrics.sh
# Tests Prometheus metrics collection

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Setup test environment
setup() {
    RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
    export RDD_DIR

    # Create temp directory for metrics
    TEST_CACHE_DIR="$(mktemp -d)"
    export METRICS_FILE="$TEST_CACHE_DIR/metrics.prom"
    export METRICS_ENABLED="true"
    export METRICS_NAMESPACE="rdd_test"

    source "${RDD_DIR}/lib/error_codes.sh"
    source "${RDD_DIR}/scripts/metrics.sh"
}

teardown() {
    rm -rf "$TEST_CACHE_DIR"
}

#######################################
# Initialization Tests
#######################################

@test "metrics: init_metrics creates directory" {
    METRICS_FILE="/tmp/test_metrics/metrics.prom"

    run init_metrics
    [ "$status" -eq 0 ]
    [ -d "/tmp/test_metrics" ]

    rm -rf /tmp/test_metrics
}

@test "metrics: init_metrics registers standard metrics" {
    [[ -n "${METRIC_HELP[rdd_test_notifications_total]:-}" ]]
    [[ -n "${METRIC_HELP[rdd_test_hook_executions_total]:-}" ]]
    [[ -n "${METRIC_HELP[rdd_test_errors_total]:-}" ]]
}

#######################################
# Counter Tests
#######################################

@test "metrics_counter_inc: increments counter" {
    metrics_counter_inc "test_counter"

    run metrics_counter_get "test_counter"
    [[ "$output" == "1" ]]

    metrics_counter_inc "test_counter"

    run metrics_counter_get "test_counter"
    [[ "$output" == "2" ]]
}

@test "metrics_counter_inc: handles labels" {
    metrics_counter_inc "requests_total" "method=GET" "status=200"
    metrics_counter_inc "requests_total" "method=GET" "status=200"
    metrics_counter_inc "requests_total" "method=POST" "status=201"

    run metrics_counter_get "requests_total" "method=GET" "status=200"
    [[ "$output" == "2" ]]

    run metrics_counter_get "requests_total" "method=POST" "status=201"
    [[ "$output" == "1" ]]
}

@test "metrics_counter_inc: returns nothing when disabled" {
    METRICS_ENABLED="false"

    run metrics_counter_inc "test_counter"
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]
}

#######################################
# Gauge Tests
#######################################

@test "metrics_gauge_set: sets gauge value" {
    metrics_gauge_set "temperature" 25

    run metrics_gauge_get "temperature"
    [[ "$output" == "25" ]]
}

@test "metrics_gauge_set: overwrites previous value" {
    metrics_gauge_set "temperature" 25
    metrics_gauge_set "temperature" 30

    run metrics_gauge_get "temperature"
    [[ "$output" == "30" ]]
}

@test "metrics_gauge_set: handles labels" {
    metrics_gauge_set "queue_size" 100 "queue=emails"
    metrics_gauge_set "queue_size" 50 "queue=notifications"

    run metrics_gauge_get "queue_size" "queue=emails"
    [[ "$output" == "100" ]]

    run metrics_gauge_get "queue_size" "queue=notifications"
    [[ "$output" == "50" ]]
}

@test "metrics_gauge_inc: increments gauge" {
    metrics_gauge_set "counter" 10
    metrics_gauge_inc "counter"

    run metrics_gauge_get "counter"
    [[ "$output" == "11" ]]
}

@test "metrics_gauge_inc: handles custom increment" {
    metrics_gauge_set "counter" 10
    metrics_gauge_inc "counter" 5

    run metrics_gauge_get "counter"
    [[ "$output" == "15" ]]
}

@test "metrics_gauge_dec: decrements gauge" {
    metrics_gauge_set "counter" 10
    metrics_gauge_dec "counter"

    run metrics_gauge_get "counter"
    [[ "$output" == "9" ]]
}

@test "metrics_gauge_dec: handles custom decrement" {
    metrics_gauge_set "counter" 10
    metrics_gauge_dec "counter" 3

    run metrics_gauge_get "counter"
    [[ "$output" == "7" ]]
}

#######################################
# Histogram Tests
#######################################

@test "metrics_histogram_observe: records observations" {
    metrics_histogram_observe "request_duration" 0.1
    metrics_histogram_observe "request_duration" 0.2
    metrics_histogram_observe "request_duration" 0.5

    # Check sum and count are tracked
    local state
    state=$(declare -p METRICS_HISTOGRAMS)

    [[ "$state" =~ "request_duration" ]]
}

@test "metrics_histogram_observe: handles labels" {
    metrics_histogram_observe "request_duration" 0.1 "endpoint=/api"
    metrics_histogram_observe "request_duration" 0.2 "endpoint=/api"

    local state
    state=$(declare -p METRICS_HISTOGRAMS)

    [[ "$state" =~ "endpoint=/api" ]]
}

#######################################
# Export Tests
#######################################

@test "export_metrics: produces Prometheus format" {
    metrics_counter_inc "test_counter"
    metrics_gauge_set "test_gauge" 42

    run export_metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rdd_test_test_counter 1" ]]
    [[ "$output" =~ "rdd_test_test_gauge 42" ]]
}

@test "export_metrics: includes HELP and TYPE" {
    register_metric "custom_metric" "counter" "A custom metric"
    metrics_counter_inc "custom_metric"

    run export_metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "# HELP rdd_test_custom_metric A custom metric" ]]
    [[ "$output" =~ "# TYPE rdd_test_custom_metric counter" ]]
}

@test "export_metrics: handles counters with labels" {
    metrics_counter_inc "requests_total" "method=GET" "status=200"
    metrics_counter_inc "requests_total" "method=POST" "status=201"

    run export_metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ 'method=GET' ]]
    [[ "$output" =~ 'status=200' ]]
}

@test "write_metrics_file: writes to file" {
    metrics_counter_inc "test_counter"
    metrics_gauge_set "test_gauge" 100

    run write_metrics_file
    [ "$status" -eq 0 ]
    [ -f "$METRICS_FILE" ]

    [[ "$(cat "$METRICS_FILE")" =~ "rdd_test_test_counter" ]]
    [[ "$(cat "$METRICS_FILE")" =~ "rdd_test_test_gauge" ]]
}

#######################################
# High-Level Functions Tests
#######################################

@test "record_notification_metric: records counter and histogram" {
    record_notification_metric "wecom" "success" 0.5

    run metrics_counter_get "notifications_total" "channel=wecom" "status=success"
    [[ "$output" == "1" ]]
}

@test "record_notification_metric: handles zero duration" {
    record_notification_metric "email" "failed" 0

    run metrics_counter_get "notifications_total" "channel=email" "status=failed"
    [[ "$output" == "1" ]]
}

@test "record_hook_metric: records hook metrics" {
    record_hook_metric "stage_complete" "success" 0.1

    run metrics_counter_get "hook_executions_total" "hook=stage_complete" "status=success"
    [[ "$output" == "1" ]]
}

@test "record_error_metric: records error by code and category" {
    record_error_metric "E200" "recoverable"

    run metrics_counter_get "errors_total" "code=E200" "category=recoverable"
    [[ "$output" == "1" ]]
}

@test "record_retry_metric: records retry attempts" {
    record_retry_metric "notification" "true"

    run metrics_counter_get "retry_attempts_total" "operation=notification"
    [[ "$output" == "1" ]]

    run metrics_counter_get "retry_success_total" "operation=notification"
    [[ "$output" == "1" ]]
}

@test "record_retry_metric: records failed retries" {
    record_retry_metric "notification" "false"

    run metrics_counter_get "retry_failure_total" "operation=notification"
    [[ "$output" == "1" ]]
}

#######################################
# Process Metrics Tests
#######################################

@test "init_metrics: sets process start time" {
    init_metrics

    local start_time
    start_time=$(metrics_gauge_get "process_start_time_seconds")

    [[ -n "$start_time" ]]
    [[ "$start_time" -gt 0 ]]
}

@test "update_process_uptime: calculates uptime" {
    init_metrics

    sleep 1
    update_process_uptime

    local uptime
    uptime=$(metrics_gauge_get "process_uptime_seconds")

    [[ "$uptime" -ge 1 ]]
}

#######################################
# Disabled Metrics Tests
#######################################

@test "metrics functions return early when disabled" {
    METRICS_ENABLED="false"

    run metrics_counter_inc "test"
    [ "$status" -eq 0 ]

    run metrics_gauge_set "test" 1
    [ "$status" -eq 0 ]

    run metrics_histogram_observe "test" 1.0
    [ "$status" -eq 0 ]

    run export_metrics
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]
}

#######################################
# Edge Cases Tests
#######################################

@test "metrics: handles special characters in labels" {
    metrics_counter_inc "test" "label=value_with_underscore"
    metrics_counter_inc "test" "label=value-with-dash"

    run metrics_counter_get "test" "label=value_with_underscore"
    [[ "$output" == "1" ]]

    run metrics_counter_get "test" "label=value-with-dash"
    [[ "$output" == "1" ]]
}

@test "metrics: handles numeric values" {
    metrics_gauge_set "numeric_test" 123.456

    run metrics_gauge_get "numeric_test"
    [[ "$output" == "123.456" ]]
}

@test "metrics: handles zero values" {
    metrics_gauge_set "zero_test" 0
    metrics_counter_inc "zero_counter"
    metrics_counter_inc "zero_counter"  # Now 1

    run metrics_gauge_get "zero_test"
    [[ "$output" == "0" ]]
}

@test "register_metric: adds help and type" {
    register_metric "custom_gauge" "gauge" "A custom gauge for testing"

    [[ "${METRIC_HELP[rdd_test_custom_gauge]}" == "A custom gauge for testing" ]]
    [[ "${METRIC_TYPE[rdd_test_custom_gauge]}" == "gauge" ]]
}
