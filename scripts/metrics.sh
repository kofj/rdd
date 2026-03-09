#!/bin/bash
#
# RDD Prometheus Metrics Collection
# Provides Prometheus-compatible metrics for monitoring
#
# Usage:
#   source "${RDD_DIR}/scripts/metrics.sh"
#   metrics_counter_inc "notifications_total" "channel=wecom" "status=success"
#   metrics_gauge_set "degradation_level" 2

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"

#######################################
# Metrics Configuration
#######################################

# Metrics output file
METRICS_FILE="${METRICS_FILE:-${RDD_DIR}/cache/metrics.prom}"

# Metrics enabled
METRICS_ENABLED="${METRICS_ENABLED:-true}"

# Metrics namespace (prefix for all metrics)
METRICS_NAMESPACE="${METRICS_NAMESPACE:-rdd}"

# Metrics collection interval (seconds)
METRICS_COLLECTION_INTERVAL="${METRICS_COLLECTION_INTERVAL:-60}"

# In-memory metrics storage
declare -A METRICS_COUNTERS=()
declare -A METRICS_GAUGES=()
declare -A METRICS_HISTOGRAMS=()

# Histogram bucket defaults
HISTOGRAM_BUCKETS_DEFAULT="0.01,0.05,0.1,0.5,1,5,10,30,60"

#######################################
# Counter Metrics
#######################################

# Increment a counter metric
# Usage: metrics_counter_inc <name> [label1=value1] [label2=value2] ...
metrics_counter_inc() {
    local name="$1"
    shift
    local labels=("$@")

    if [[ "$METRICS_ENABLED" != "true" ]]; then
        return 0
    fi

    # Build metric key
    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"

    # Increment counter
    METRICS_COUNTERS[$full_key]=$((${METRICS_COUNTERS[$full_key]:-0} + 1))
}

# Get counter value
# Usage: metrics_counter_get <name> [label1=value1] [label2=value2] ...
metrics_counter_get() {
    local name="$1"
    shift
    local labels=("$@")

    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"
    echo "${METRICS_COUNTERS[$full_key]:-0}"
}

#######################################
# Gauge Metrics
#######################################

# Set a gauge metric
# Usage: metrics_gauge_set <name> <value> [label1=value1] [label2=value2] ...
metrics_gauge_set() {
    local name="$1"
    local value="$2"
    shift 2
    local labels=("$@")

    if [[ "$METRICS_ENABLED" != "true" ]]; then
        return 0
    fi

    # Build metric key
    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"

    # Set gauge value
    METRICS_GAUGES[$full_key]="$value"
}

# Increment a gauge metric
# Usage: metrics_gauge_inc <name> [value] [label1=value1] ...
metrics_gauge_inc() {
    local name="$1"
    local value="${2:-1}"
    shift 2
    local labels=("$@")

    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"
    METRICS_GAUGES[$full_key]=$((${METRICS_GAUGES[$full_key]:-0} + value))
}

# Decrement a gauge metric
# Usage: metrics_gauge_dec <name> [value] [label1=value1] ...
metrics_gauge_dec() {
    local name="$1"
    local value="${2:-1}"
    shift 2
    local labels=("$@")

    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"
    METRICS_GAUGES[$full_key]=$((${METRICS_GAUGES[$full_key]:-0} - value))
}

# Get gauge value
# Usage: metrics_gauge_get <name> [label1=value1] [label2=value2] ...
metrics_gauge_get() {
    local name="$1"
    shift
    local labels=("$@")

    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    local full_key="${key}${label_str}"
    echo "${METRICS_GAUGES[$full_key]:-0}"
}

#######################################
# Histogram Metrics
#######################################

# Observe a value for histogram
# Usage: metrics_histogram_observe <name> <value> [label1=value1] [label2=value2] ...
metrics_histogram_observe() {
    local name="$1"
    local value="$2"
    shift 2
    local labels=("$@")

    if [[ "$METRICS_ENABLED" != "true" ]]; then
        return 0
    fi

    # Build metric key
    local key="${METRICS_NAMESPACE}_${name}"
    local label_str=""
    if [[ ${#labels[@]} -gt 0 ]]; then
        label_str="{"
        local first=true
        for label in "${labels[@]}"; do
            if [[ "$first" != "true" ]]; then
                label_str+=","
            fi
            label_str+="$label"
            first=false
        done
        label_str+="}"
    fi

    # Store observation
    local observations_key="${key}${label_str}_observations"
    if [[ -z "${METRICS_HISTOGRAMS[$observations_key]:-}" ]]; then
        METRICS_HISTOGRAMS[$observations_key]=""
    fi
    METRICS_HISTOGRAMS[$observations_key]="${METRICS_HISTOGRAMS[$observations_key]}${value},"

    # Track sum and count
    local sum_key="${key}${label_str}_sum"
    local count_key="${key}${label_str}_count"

    METRICS_HISTOGRAMS[$sum_key]=$(awk "BEGIN{print ${METRICS_HISTOGRAMS[$sum_key]:-0} + $value}")
    METRICS_HISTOGRAMS[$count_key]=$((${METRICS_HISTOGRAMS[$count_key]:-0} + 1))
}

# Time an operation and record histogram
# Usage: metrics_histogram_time <name> -- <command...>
metrics_histogram_time() {
    local name="$1"
    shift

    # Skip --
    [[ "$1" == "--" ]] && shift

    local cmd=("$@")

    local start_time
    start_time=$(date +%s%N)

    local exit_code=0
    if "${cmd[@]}" 2>&1; then
        :
    else
        exit_code=$?
    fi

    local end_time
    end_time=$(date +%s%N)
    local duration_seconds
    duration_seconds=$(awk "BEGIN{print ($end_time - $start_time) / 1000000000}")

    metrics_histogram_observe "$name" "$duration_seconds"

    return $exit_code
}

#######################################
# Metric Description Registry
#######################################

declare -A METRIC_HELP=()
declare -A METRIC_TYPE=()

# Register a metric with help and type
# Usage: register_metric <name> <type> <help>
register_metric() {
    local name="$1"
    local type="$2"
    local help="$3"

    METRIC_HELP["${METRICS_NAMESPACE}_${name}"]="$help"
    METRIC_TYPE["${METRICS_NAMESPACE}_${name}"]="$type"
}

# Register standard RDD metrics
register_standard_metrics() {
    # Notification metrics
    register_metric "notifications_total" "counter" "Total number of notifications sent"
    register_metric "notification_duration_seconds" "histogram" "Time to send notifications"

    # Hook metrics
    register_metric "hook_executions_total" "counter" "Total number of hook executions"
    register_metric "hook_duration_seconds" "histogram" "Time to execute hooks"

    # Error metrics
    register_metric "errors_total" "counter" "Total number of errors by code"

    # Circuit breaker metrics
    register_metric "circuit_breaker_state" "gauge" "Circuit breaker state (0=closed, 1=open, 2=half_open)"
    register_metric "circuit_breaker_failures" "gauge" "Total failures recorded"
    register_metric "circuit_breaker_requests" "gauge" "Total requests recorded"

    # Degradation metrics
    register_metric "degradation_level" "gauge" "Current degradation level (0-4)"
    register_metric "degradation_failure_count" "gauge" "Failure count for auto-adjustment"

    # Retry metrics
    register_metric "retry_attempts_total" "counter" "Total number of retry attempts"
    register_metric "retry_success_total" "counter" "Total number of successful retries"
    register_metric "retry_failure_total" "counter" "Total number of failed retries"

    # Process metrics
    register_metric "process_start_time_seconds" "gauge" "Start time of the process"
    register_metric "process_uptime_seconds" "gauge" "Uptime of the process"
}

#######################################
# Export Metrics
#######################################

# Export metrics in Prometheus format
# Usage: export_metrics
export_metrics() {
    if [[ "$METRICS_ENABLED" != "true" ]]; then
        return 0
    fi

    local output=""
    local timestamp
    timestamp=$(date +%s)

    # Add header
    output+="# RDD Framework Metrics\n"
    output+="# Generated at $(date -u +"%Y-%m-%dT%H:%M:%SZ")\n\n"

    # Export counters
    if [[ ${#METRICS_COUNTERS[@]} -gt 0 ]]; then
        output+="# Counter Metrics\n"
        local last_metric=""
        for key in "${!METRICS_COUNTERS[@]}"; do
            local metric_name="${key%%\{*}"
            local value="${METRICS_COUNTERS[$key]}"

            # Add HELP and TYPE if new metric
            if [[ "$metric_name" != "$last_metric" ]]; then
                if [[ -n "${METRIC_HELP[$metric_name]:-}" ]]; then
                    output+="# HELP ${metric_name} ${METRIC_HELP[$metric_name]}\n"
                else
                    output+="# HELP ${metric_name} Counter metric\n"
                fi
                output+="# TYPE ${metric_name} counter\n"
                last_metric="$metric_name"
            fi

            output+="${key} ${value}\n"
        done
        output+="\n"
    fi

    # Export gauges
    if [[ ${#METRICS_GAUGES[@]} -gt 0 ]]; then
        output+="# Gauge Metrics\n"
        local last_metric=""
        for key in "${!METRICS_GAUGES[@]}"; do
            local metric_name="${key%%\{*}"
            local value="${METRICS_GAUGES[$key]}"

            # Add HELP and TYPE if new metric
            if [[ "$metric_name" != "$last_metric" ]]; then
                if [[ -n "${METRIC_HELP[$metric_name]:-}" ]]; then
                    output+="# HELP ${metric_name} ${METRIC_HELP[$metric_name]}\n"
                else
                    output+="# HELP ${metric_name} Gauge metric\n"
                fi
                output+="# TYPE ${metric_name} gauge\n"
                last_metric="$metric_name"
            fi

            output+="${key} ${value}\n"
        done
        output+="\n"
    fi

    # Export histograms
    if [[ ${#METRICS_HISTOGRAMS[@]} -gt 0 ]]; then
        output+="# Histogram Metrics\n"

        # Group by metric name
        declare -A histogram_metrics=()
        for key in "${!METRICS_HISTOGRAMS[@]}"; do
            if [[ "$key" == *_observations ]]; then
                local base_key="${key%_observations}"
                histogram_metrics["$base_key"]=1
            fi
        done

        for base_key in "${!histogram_metrics[@]}"; do
            local metric_name="${base_key%%\{*}"

            # Add HELP and TYPE
            if [[ -n "${METRIC_HELP[$metric_name]:-}" ]]; then
                output+="# HELP ${metric_name} ${METRIC_HELP[$metric_name]}\n"
            else
                output+="# HELP ${metric_name} Histogram metric\n"
            fi
            output+="# TYPE ${metric_name} histogram\n"

            # Get observations and calculate buckets
            local observations="${METRICS_HISTOGRAMS[${base_key}_observations]:-}"
            local sum="${METRICS_HISTOGRAMS[${base_key}_sum]:-0}"
            local count="${METRICS_HISTOGRAMS[${base_key}_count]:-0}"

            # Parse buckets
            IFS=',' read -ra buckets <<< "$HISTOGRAM_BUCKETS_DEFAULT"

            # Count observations per bucket
            local bucket_counts=()
            local cumulative=0

            if [[ -n "$observations" ]]; then
                IFS=',' read -ra obs_array <<< "$observations"
                for bucket in "${buckets[@]}"; do
                    local bucket_count=0
                    for obs in "${obs_array[@]}"; do
                        if [[ -n "$obs" ]] && (( $(awk "BEGIN{print ($obs <= $bucket)}") )); then
                            ((bucket_count++))
                        fi
                    done
                    cumulative=$((cumulative + bucket_count))
                    bucket_counts+=("$cumulative")
                done
            fi

            # Output bucket metrics
            local i=0
            for bucket in "${buckets[@]}"; do
                output+="${base_key}_bucket{le=\"${bucket}\"} ${bucket_counts[$i]:-0}\n"
                ((i++))
            done
            output+="${base_key}_bucket{le=\"+Inf\"} ${count}\n"

            # Output sum and count
            output+="${base_key}_sum ${sum}\n"
            output+="${base_key}_count ${count}\n"
        done
    fi

    echo -e "$output"
}

# Write metrics to file
# Usage: write_metrics_file
write_metrics_file() {
    if [[ "$METRICS_ENABLED" != "true" ]]; then
        return 0
    fi

    mkdir -p "$(dirname "$METRICS_FILE")"
    export_metrics > "$METRICS_FILE"
}

#######################################
# High-Level Metrics Functions
#######################################

# Record notification metrics
# Usage: record_notification_metric <channel> <status> <duration_seconds>
record_notification_metric() {
    local channel="$1"
    local status="$2"
    local duration="${3:-0}"

    metrics_counter_inc "notifications_total" "channel=$channel" "status=$status"

    if [[ -n "$duration" && "$duration" != "0" ]]; then
        metrics_histogram_observe "notification_duration_seconds" "$duration" "channel=$channel"
    fi
}

# Record hook execution metrics
# Usage: record_hook_metric <hook_name> <status> <duration_seconds>
record_hook_metric() {
    local hook_name="$1"
    local status="$2"
    local duration="${3:-0}"

    metrics_counter_inc "hook_executions_total" "hook=$hook_name" "status=$status"

    if [[ -n "$duration" && "$duration" != "0" ]]; then
        metrics_histogram_observe "hook_duration_seconds" "$duration" "hook=$hook_name"
    fi
}

# Record error metrics
# Usage: record_error_metric <error_code> <category>
record_error_metric() {
    local error_code="$1"
    local category="$2"

    metrics_counter_inc "errors_total" "code=$error_code" "category=$category"
}

# Record retry metrics
# Usage: record_retry_metric <operation> <success>
record_retry_metric() {
    local operation="$1"
    local success="$2"

    metrics_counter_inc "retry_attempts_total" "operation=$operation"

    if [[ "$success" == "true" ]]; then
        metrics_counter_inc "retry_success_total" "operation=$operation"
    else
        metrics_counter_inc "retry_failure_total" "operation=$operation"
    fi
}

#######################################
# Initialization
#######################################

# Initialize metrics system
init_metrics() {
    mkdir -p "$(dirname "$METRICS_FILE")"
    register_standard_metrics

    # Set process start time
    metrics_gauge_set "process_start_time_seconds" "$(date +%s)"
}

# Update process uptime
update_process_uptime() {
    local start_time
    start_time=$(metrics_gauge_get "process_start_time_seconds")
    local current_time
    current_time=$(date +%s)
    local uptime=$((current_time - start_time))
    metrics_gauge_set "process_uptime_seconds" "$uptime"
}

# Collect all metrics (including from other modules)
collect_all_metrics() {
    update_process_uptime
    write_metrics_file
}

# Initialize on source
init_metrics

# Export functions
export -f metrics_counter_inc metrics_counter_get
export -f metrics_gauge_set metrics_gauge_inc metrics_gauge_dec metrics_gauge_get
export -f metrics_histogram_observe metrics_histogram_time
export -f register_metric register_standard_metrics
export -f export_metrics write_metrics_file
export -f record_notification_metric record_hook_metric record_error_metric record_retry_metric
export -f init_metrics update_process_uptime collect_all_metrics
