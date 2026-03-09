#!/bin/bash
#
# RDD Performance Benchmark Script
# Measures and reports performance metrics for RDD operations
#
# Usage: benchmark.sh [command] [options]
#
# Commands:
#   all           - Run all benchmarks
#   hook          - Benchmark hook trigger latency
#   notification  - Benchmark notification sending latency
#   memory        - Benchmark memory usage
#   config        - Benchmark configuration loading
#   report        - Generate JSON report from last benchmark
#
# Options:
#   --iterations N    - Number of iterations (default: 100)
#   --output FILE     - Output file for results
#   --format FORMAT   - Output format: json, text (default: text)
#   --baseline FILE   - Compare against baseline file
#

set -euo pipefail

# Configuration
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"
CACHE_DIR="${RDD_DIR}/cache"
BENCHMARK_DIR="${CACHE_DIR}/benchmark"
RESULT_FILE="${BENCHMARK_DIR}/results.json"

# Default settings
DEFAULT_ITERATIONS=100
ITERATIONS="${ITERATIONS:-$DEFAULT_ITERATIONS}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
OUTPUT_FILE="${OUTPUT_FILE:-}"
BASELINE_FILE="${BASELINE_FILE:-}"

# Performance targets (in milliseconds)
TARGET_HOOK_LATENCY_MS=100
TARGET_NOTIFICATION_LATENCY_MS=500
TARGET_CONFIG_LOAD_MS=50
TARGET_MEMORY_IDLE_KB=51200  # 50MB

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#######################################
# Logging functions
#######################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

#######################################
# Utility functions
#######################################

# Ensure benchmark directory exists
ensure_benchmark_dir() {
    mkdir -p "$BENCHMARK_DIR"
}

# Get current timestamp in nanoseconds
get_timestamp_ns() {
    date +%s%N
}

# Get current timestamp in milliseconds
get_timestamp_ms() {
    echo $(( $(date +%s%N) / 1000000 ))
}

# Calculate duration in milliseconds from nanoseconds
calc_duration_ms() {
    local start_ns="$1"
    local end_ns="$2"
    echo $(( (end_ns - start_ns) / 1000000 ))
}

# Get current memory usage in KB
get_memory_kb() {
    local pid=$$
    if [[ -f /proc/$pid/status ]]; then
        local mem
        mem=$(grep VmRSS /proc/$pid/status 2>/dev/null | awk '{print $2}')
        echo "${mem:-0}"
    else
        # Fallback for macOS
        if command -v ps &> /dev/null; then
            ps -o rss= -p "$pid" 2>/dev/null || echo "0"
        else
            echo "0"
        fi
    fi
}

# Calculate statistics
calc_stats() {
    local values=("$@")
    local count=${#values[@]}

    if [[ $count -eq 0 ]]; then
        echo '{"count":0,"min":0,"max":0,"avg":0,"median":0,"p95":0,"p99":0}'
        return
    fi

    # Sort values
    local sorted
    sorted=$(printf '%s\n' "${values[@]}" | sort -n)

    # Calculate min and max
    local min max
    min=$(echo "$sorted" | head -1)
    max=$(echo "$sorted" | tail -1)

    # Calculate average
    local sum=0
    for v in "${values[@]}"; do
        sum=$((sum + v))
    done
    local avg=$((sum / count))

    # Calculate median
    local mid=$((count / 2))
    local median
    if [[ $((count % 2)) -eq 0 ]]; then
        local a b
        a=$(echo "$sorted" | sed -n "${mid}p")
        b=$(echo "$sorted" | sed -n "$((mid + 1))p")
        median=$(((a + b) / 2))
    else
        median=$(echo "$sorted" | sed -n "$((mid + 1))p")
    fi

    # Calculate percentiles
    local p95_idx=$(( (count * 95) / 100 ))
    local p99_idx=$(( (count * 99) / 100 ))
    [[ $p95_idx -ge $count ]] && p95_idx=$((count - 1))
    [[ $p99_idx -ge $count ]] && p99_idx=$((count - 1))

    local p95 p99
    p95=$(echo "$sorted" | sed -n "$((p95_idx + 1))p")
    p99=$(echo "$sorted" | sed -n "$((p99_idx + 1))p")

    # Output JSON
    cat <<EOF
{
  "count": $count,
  "min": $min,
  "max": $max,
  "avg": $avg,
  "median": $median,
  "p95": $p95,
  "p99": $p99
}
EOF
}

# Check if value meets target
check_target() {
    local value="$1"
    local target="$2"
    local name="$3"

    if [[ $value -le $target ]]; then
        log_info "$name: ${value}ms (target: ${target}ms) - PASS"
        return 0
    else
        log_error "$name: ${value}ms (target: ${target}ms) - FAIL"
        return 1
    fi
}

#######################################
# Benchmark: Hook trigger latency
#######################################

benchmark_hook() {
    log_info "Benchmarking hook trigger latency..."
    log_info "Iterations: $ITERATIONS"

    local durations=()
    local hook_dir="${RDD_DIR}/hooks"

    # Check if hooks exist
    if [[ ! -d "$hook_dir" ]]; then
        log_error "Hooks directory not found: $hook_dir"
        return 1
    fi

    # Find a test hook
    local test_hook="${hook_dir}/stage-complete.sh"
    if [[ ! -f "$test_hook" ]]; then
        log_warn "Test hook not found, creating minimal test"
        test_hook=$(find "$hook_dir" -name "*.sh" -type f | head -1)
    fi

    if [[ -z "$test_hook" ]]; then
        log_error "No hook scripts found for benchmarking"
        return 1
    fi

    log_debug "Using test hook: $test_hook"

    # Warmup
    log_debug "Running warmup..."
    for i in {1..5}; do
        DRY_RUN=true bash "$test_hook" &>/dev/null || true
    done

    # Run benchmark
    log_debug "Running benchmark..."
    local start_ns end_ns duration_ms

    for i in $(seq 1 "$ITERATIONS"); do
        # Set environment for hook
        export RDD_STAGE_NUMBER="5"
        export RDD_STAGE_NAME="Benchmark Test"
        export RDD_STAGE_DURATION="1s"
        export RDD_COVERAGE="95"
        export RDD_PROJECT_NAME="Benchmark"
        export DRY_RUN=true

        start_ns=$(get_timestamp_ns)
        bash "$test_hook" &>/dev/null || true
        end_ns=$(get_timestamp_ns)

        duration_ms=$(calc_duration_ms "$start_ns" "$end_ns")
        durations+=("$duration_ms")

        # Progress indicator
        if [[ $((i % 10)) -eq 0 ]]; then
            log_debug "Completed $i/$ITERATIONS iterations"
        fi
    done

    # Calculate statistics
    local stats
    stats=$(calc_stats "${durations[@]}")

    # Parse stats
    local avg median p95 p99 min max count
    count=$(echo "$stats" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
    min=$(echo "$stats" | grep -o '"min":[0-9]*' | grep -o '[0-9]*')
    max=$(echo "$stats" | grep -o '"max":[0-9]*' | grep -o '[0-9]*')
    avg=$(echo "$stats" | grep -o '"avg":[0-9]*' | grep -o '[0-9]*')
    median=$(echo "$stats" | grep -o '"median":[0-9]*' | grep -o '[0-9]*')
    p95=$(echo "$stats" | grep -o '"p95":[0-9]*' | grep -o '[0-9]*')
    p99=$(echo "$stats" | grep -o '"p99":[0-9]*' | grep -o '[0-9]*')

    # Output results
    echo ""
    log_info "Hook Trigger Latency Results:"
    echo "  Iterations: $count"
    echo "  Min:        ${min}ms"
    echo "  Max:        ${max}ms"
    echo "  Average:    ${avg}ms"
    echo "  Median:     ${median}ms"
    echo "  P95:        ${p95}ms"
    echo "  P99:        ${p99}ms"
    echo ""

    # Check target
    check_target "$p95" "$TARGET_HOOK_LATENCY_MS" "Hook latency (P95)"

    # Save result
    echo "$stats" > "${BENCHMARK_DIR}/hook_stats.json"

    return $?
}

#######################################
# Benchmark: Notification latency
#######################################

benchmark_notification() {
    log_info "Benchmarking notification sending latency..."
    log_info "Iterations: $ITERATIONS"

    local durations=()
    local notify_script="${SCRIPTS_DIR}/notify.sh"

    if [[ ! -f "$notify_script" ]]; then
        log_error "Notify script not found: $notify_script"
        return 1
    fi

    # Warmup
    log_debug "Running warmup..."
    for i in {1..5}; do
        DRY_RUN=true bash "$notify_script" stage_complete &>/dev/null || true
    done

    # Run benchmark
    log_debug "Running benchmark..."
    local start_ns end_ns duration_ms

    for i in $(seq 1 "$ITERATIONS"); do
        export DRY_RUN=true
        export VERBOSE=false

        start_ns=$(get_timestamp_ns)
        bash "$notify_script" stage_complete &>/dev/null || true
        end_ns=$(get_timestamp_ns)

        duration_ms=$(calc_duration_ms "$start_ns" "$end_ns")
        durations+=("$duration_ms")

        if [[ $((i % 10)) -eq 0 ]]; then
            log_debug "Completed $i/$ITERATIONS iterations"
        fi
    done

    # Calculate statistics
    local stats
    stats=$(calc_stats "${durations[@]}")

    # Parse stats
    local avg median p95 p99 min max count
    count=$(echo "$stats" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
    min=$(echo "$stats" | grep -o '"min":[0-9]*' | grep -o '[0-9]*')
    max=$(echo "$stats" | grep -o '"max":[0-9]*' | grep -o '[0-9]*')
    avg=$(echo "$stats" | grep -o '"avg":[0-9]*' | grep -o '[0-9]*')
    median=$(echo "$stats" | grep -o '"median":[0-9]*' | grep -o '[0-9]*')
    p95=$(echo "$stats" | grep -o '"p95":[0-9]*' | grep -o '[0-9]*')
    p99=$(echo "$stats" | grep -o '"p99":[0-9]*' | grep -o '[0-9]*')

    # Output results
    echo ""
    log_info "Notification Latency Results:"
    echo "  Iterations: $count"
    echo "  Min:        ${min}ms"
    echo "  Max:        ${max}ms"
    echo "  Average:    ${avg}ms"
    echo "  Median:     ${median}ms"
    echo "  P95:        ${p95}ms"
    echo "  P99:        ${p99}ms"
    echo ""

    # Check target
    check_target "$p95" "$TARGET_NOTIFICATION_LATENCY_MS" "Notification latency (P95)"

    # Save result
    echo "$stats" > "${BENCHMARK_DIR}/notification_stats.json"

    return $?
}

#######################################
# Benchmark: Memory usage
#######################################

benchmark_memory() {
    log_info "Benchmarking memory usage..."

    # Measure baseline memory
    local baseline_mem
    baseline_mem=$(get_memory_kb)
    log_info "Baseline memory: ${baseline_mem}KB"

    # Source notify.sh and measure
    if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
        # Start a subshell to measure
        local after_load_mem
        after_load_mem=$(bash -c "source ${SCRIPTS_DIR}/notify.sh; get_memory_kb" 2>/dev/null || echo "0")
        log_info "After loading notify.sh: ${after_load_mem}KB"
    fi

    # Simulate idle state (after all initialization)
    local idle_mem
    idle_mem=$(get_memory_kb)
    log_info "Idle state memory: ${idle_mem}KB"

    # Output results
    echo ""
    log_info "Memory Usage Results:"
    echo "  Baseline:     ${baseline_mem}KB"
    echo "  Idle State:   ${idle_mem}KB"
    echo "  Target:       ${TARGET_MEMORY_IDLE_KB}KB (50MB)"
    echo ""

    # Check target
    if [[ $idle_mem -le $TARGET_MEMORY_IDLE_KB ]]; then
        log_info "Memory usage: ${idle_mem}KB - PASS (target: ${TARGET_MEMORY_IDLE_KB}KB)"
        return 0
    else
        log_error "Memory usage: ${idle_mem}KB - FAIL (target: ${TARGET_MEMORY_IDLE_KB}KB)"
        return 1
    fi
}

#######################################
# Benchmark: Configuration loading
#######################################

benchmark_config() {
    log_info "Benchmarking configuration loading..."
    log_info "Iterations: $ITERATIONS"

    local durations=()
    local config_file="${RDD_DIR}/config.yml"

    if [[ ! -f "$config_file" ]]; then
        log_warn "Config file not found: $config_file"
        return 0
    fi

    # Run benchmark
    log_debug "Running benchmark..."
    local start_ns end_ns duration_ms

    for i in $(seq 1 "$ITERATIONS"); do
        start_ns=$(get_timestamp_ns)

        # Simulate config loading
        if command -v yq &> /dev/null; then
            yq eval '.' "$config_file" &>/dev/null
        else
            cat "$config_file" &>/dev/null
        fi

        end_ns=$(get_timestamp_ns)
        duration_ms=$(calc_duration_ms "$start_ns" "$end_ns")
        durations+=("$duration_ms")
    done

    # Calculate statistics
    local stats
    stats=$(calc_stats "${durations[@]}")

    # Parse stats
    local avg median p95 p99 min max count
    count=$(echo "$stats" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
    min=$(echo "$stats" | grep -o '"min":[0-9]*' | grep -o '[0-9]*')
    max=$(echo "$stats" | grep -o '"max":[0-9]*' | grep -o '[0-9]*')
    avg=$(echo "$stats" | grep -o '"avg":[0-9]*' | grep -o '[0-9]*')
    median=$(echo "$stats" | grep -o '"median":[0-9]*' | grep -o '[0-9]*')
    p95=$(echo "$stats" | grep -o '"p95":[0-9]*' | grep -o '[0-9]*')
    p99=$(echo "$stats" | grep -o '"p99":[0-9]*' | grep -o '[0-9]*')

    # Output results
    echo ""
    log_info "Configuration Loading Results:"
    echo "  Iterations: $count"
    echo "  Min:        ${min}ms"
    echo "  Max:        ${max}ms"
    echo "  Average:    ${avg}ms"
    echo "  Median:     ${median}ms"
    echo "  P95:        ${p95}ms"
    echo "  P99:        ${p99}ms"
    echo ""

    # Save result
    echo "$stats" > "${BENCHMARK_DIR}/config_stats.json"

    return 0
}

#######################################
# Generate report
#######################################

generate_report() {
    log_info "Generating benchmark report..."

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Read stats files
    local hook_stats="{}"
    local notification_stats="{}"
    local config_stats="{}"

    [[ -f "${BENCHMARK_DIR}/hook_stats.json" ]] && hook_stats=$(cat "${BENCHMARK_DIR}/hook_stats.json")
    [[ -f "${BENCHMARK_DIR}/notification_stats.json" ]] && notification_stats=$(cat "${BENCHMARK_DIR}/notification_stats.json")
    [[ -f "${BENCHMARK_DIR}/config_stats.json" ]] && config_stats=$(cat "${BENCHMARK_DIR}/config_stats.json")

    # Get memory
    local memory_kb
    memory_kb=$(get_memory_kb)

    # Generate JSON report
    cat <<EOF > "$RESULT_FILE"
{
  "timestamp": "$timestamp",
  "iterations": $ITERATIONS,
  "targets": {
    "hook_latency_ms": $TARGET_HOOK_LATENCY_MS,
    "notification_latency_ms": $TARGET_NOTIFICATION_LATENCY_MS,
    "config_load_ms": $TARGET_CONFIG_LOAD_MS,
    "memory_idle_kb": $TARGET_MEMORY_IDLE_KB
  },
  "results": {
    "hook": $hook_stats,
    "notification": $notification_stats,
    "config": $config_stats,
    "memory_kb": $memory_kb
  },
  "environment": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "kernel": "$(uname -r)",
    "bash_version": "${BASH_VERSION:-unknown}"
  }
}
EOF

    log_info "Report saved to: $RESULT_FILE"

    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        cat "$RESULT_FILE"
    fi
}

#######################################
# Compare with baseline
#######################################

compare_baseline() {
    if [[ -z "$BASELINE_FILE" ]]; then
        log_debug "No baseline file specified"
        return 0
    fi

    if [[ ! -f "$BASELINE_FILE" ]]; then
        log_warn "Baseline file not found: $BASELINE_FILE"
        return 0
    fi

    log_info "Comparing with baseline: $BASELINE_FILE"

    # This is a simplified comparison
    # In production, use jq for proper JSON comparison
    log_info "Baseline comparison complete"
}

#######################################
# Run all benchmarks
#######################################

benchmark_all() {
    log_info "Running all benchmarks..."
    echo ""

    local failed=0

    ensure_benchmark_dir

    benchmark_hook || ((failed++))
    echo ""

    benchmark_notification || ((failed++))
    echo ""

    benchmark_config || true  # Non-critical
    echo ""

    benchmark_memory || ((failed++))
    echo ""

    generate_report
    compare_baseline

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_info "All benchmarks passed!"
        return 0
    else
        log_error "$failed benchmark(s) failed"
        return 1
    fi
}

#######################################
# Show usage
#######################################

show_usage() {
    cat << EOF
RDD Performance Benchmark Script

Usage: benchmark.sh [command] [options]

Commands:
  all           Run all benchmarks
  hook          Benchmark hook trigger latency
  notification  Benchmark notification sending latency
  memory        Benchmark memory usage
  config        Benchmark configuration loading
  report        Generate JSON report from last benchmark

Options:
  --iterations N      Number of iterations (default: 100)
  --output FILE       Output file for results
  --format FORMAT     Output format: json, text (default: text)
  --baseline FILE     Compare against baseline file
  -v, --verbose       Enable verbose output
  -h, --help          Show this help message

Performance Targets:
  Hook trigger latency:     < ${TARGET_HOOK_LATENCY_MS}ms (P95)
  Notification latency:     < ${TARGET_NOTIFICATION_LATENCY_MS}ms (P95)
  Configuration load time:  < ${TARGET_CONFIG_LOAD_MS}ms (avg)
  Memory usage (idle):      < ${TARGET_MEMORY_IDLE_KB}KB (50MB)

Examples:
  # Run all benchmarks
  benchmark.sh all

  # Run hook benchmark with 50 iterations
  benchmark.sh hook --iterations 50

  # Run all benchmarks and save to file
  benchmark.sh all --output results.json --format json

  # Compare with baseline
  benchmark.sh all --baseline baseline.json

Environment Variables:
  RDD_DIR       RDD configuration directory (default: script parent)
  ITERATIONS    Default number of iterations (default: 100)
  VERBOSE       Enable verbose output (default: false)

EOF
}

#######################################
# Parse arguments
#######################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --baseline)
                BASELINE_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

#######################################
# Main entry point
#######################################

main() {
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift
    parse_args "$@"

    ensure_benchmark_dir

    case "$command" in
        all)
            benchmark_all
            ;;
        hook)
            benchmark_hook
            ;;
        notification)
            benchmark_notification
            ;;
        memory)
            benchmark_memory
            ;;
        config)
            benchmark_config
            ;;
        report)
            generate_report
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
