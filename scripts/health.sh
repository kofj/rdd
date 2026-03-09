#!/bin/bash
#
# RDD Health Check System
# Provides health, readiness, and liveness checks for the framework
#
# Usage:
#   source "${RDD_DIR}/scripts/health.sh"
#   health_check

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"
source "${RDD_DIR}/scripts/logger.sh"
source "${RDD_DIR}/scripts/circuit_breaker.sh"
source "${RDD_DIR}/lib/degradation.sh"

#######################################
# Health Check Configuration
#######################################

# Health check output format: json or text
HEALTH_OUTPUT_FORMAT="${HEALTH_OUTPUT_FORMAT:-json}"

# Include detailed checks
HEALTH_DETAILED_CHECKS="${HEALTH_DETAILED_CHECKS:-true}"

# Include dependencies in check
HEALTH_INCLUDE_DEPENDENCIES="${HEALTH_INCLUDE_DEPENDENCIES:-true}"

# RDD version
RDD_VERSION="${RDD_VERSION:-1.0.0}"

#######################################
# Health Check Functions
#######################################

# Check if a command exists
# Usage: check_command_exists <command>
check_command_exists() {
    local cmd="$1"
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}

# Check if a file exists and is readable
# Usage: check_file_readable <file>
check_file_readable() {
    local file="$1"
    if [[ -f "$file" && -r "$file" ]]; then
        return 0
    fi
    return 1
}

# Check if a file exists and is executable
# Usage: check_file_executable <file>
check_file_executable() {
    local file="$1"
    if [[ -f "$file" && -x "$file" ]]; then
        return 0
    fi
    return 1
}

# Check if a directory exists and is writable
# Usage: check_directory_writable <dir>
check_directory_writable() {
    local dir="$1"
    if [[ -d "$dir" && -w "$dir" ]]; then
        return 0
    fi
    return 1
}

#######################################
# Individual Health Checks
#######################################

# Check configuration files
check_config_files() {
    local checks=()
    local status="pass"

    # Check hooks.yml
    if check_file_readable "${RDD_DIR}/hooks.yml"; then
        checks+=("config_hooks_yml:pass")
    else
        checks+=("config_hooks_yml:fail:missing")
        status="fail"
    fi

    # Check templates.yml
    if check_file_readable "${RDD_DIR}/templates.yml"; then
        checks+=("config_templates_yml:pass")
    else
        checks+=("config_templates_yml:fail:missing")
        status="fail"
    fi

    # Check config.yml
    if check_file_readable "${RDD_DIR}/config.yml"; then
        checks+=("config_yml:pass")
    else
        checks+=("config_yml:warn:missing")
        [[ "$status" == "pass" ]] && status="degraded"
    fi

    # Check checkpoints.yml
    if check_file_readable "${RDD_DIR}/checkpoints.yml"; then
        checks+=("config_checkpoints_yml:pass")
    else
        checks+=("config_checkpoints_yml:warn:missing")
        [[ "$status" == "pass" ]] && status="degraded"
    fi

    echo "$status|${checks[*]}"
}

# Check scripts
check_scripts() {
    local checks=()
    local status="pass"

    # Check notify.sh
    if check_file_executable "${RDD_DIR}/scripts/notify.sh"; then
        checks+=("script_notify:pass")
    else
        checks+=("script_notify:fail:not_executable")
        status="fail"
    fi

    # Check required scripts
    local required_scripts=("retry.sh" "circuit_breaker.sh" "logger.sh" "metrics.sh" "health.sh")
    for script in "${required_scripts[@]}"; do
        if check_file_readable "${RDD_DIR}/scripts/$script"; then
            checks+=("script_${script%.sh}:pass")
        else
            checks+=("script_${script%.sh}:fail:missing")
            status="fail"
        fi
    done

    # Check lib files
    local lib_files=("error_codes.sh" "degradation.sh")
    for lib in "${lib_files[@]}"; do
        if check_file_readable "${RDD_DIR}/lib/$lib"; then
            checks+=("lib_${lib%.sh}:pass")
        else
            checks+=("lib_${lib%.sh}:fail:missing")
            status="fail"
        fi
    done

    echo "$status|${checks[*]}"
}

# Check cache directory
check_cache() {
    local checks=()
    local status="pass"

    # Check cache directory
    if check_directory_writable "${RDD_DIR}/cache"; then
        checks+=("cache_dir:pass")
    else
        checks+=("cache_dir:fail:not_writable")
        status="fail"
    fi

    # Check circuit breaker directory
    if check_directory_writable "${RDD_DIR}/cache/circuit_breaker"; then
        checks+=("cache_circuit_breaker:pass")
    else
        checks+=("cache_circuit_breaker:warn:not_writable")
        [[ "$status" == "pass" ]] && status="degraded"
    fi

    echo "$status|${checks[*]}"
}

# Check required tools
check_tools() {
    local checks=()
    local status="pass"
    local missing_tools=()

    # Required tools
    local required_tools=("curl" "jq")
    for tool in "${required_tools[@]}"; do
        if check_command_exists "$tool"; then
            checks+=("tool_${tool}:pass")
        else
            checks+=("tool_${tool}:fail:missing")
            missing_tools+=("$tool")
            status="fail"
        fi
    done

    # Optional tools
    local optional_tools=("yq" "sendmail" "mail")
    for tool in "${optional_tools[@]}"; do
        if check_command_exists "$tool"; then
            checks+=("tool_${tool}:pass")
        else
            checks+=("tool_${tool}:warn:missing")
            [[ "$status" == "pass" ]] && status="degraded"
        fi
    done

    echo "$status|${checks[*]}"
}

# Check circuit breakers
check_circuit_breakers() {
    local checks=()
    local status="pass"

    # Check circuit breaker for each channel
    local channels=("wecom" "email" "telegram" "bark" "webhook")
    for channel in "${channels[@]}"; do
        local cb_state
        cb_state=$(get_circuit_breaker_state "$channel" 2>/dev/null || echo "CLOSED")

        case "$cb_state" in
            "CLOSED")
                checks+=("circuit_breaker_${channel}:pass")
                ;;
            "HALF_OPEN")
                checks+=("circuit_breaker_${channel}:warn:half_open")
                [[ "$status" == "pass" ]] && status="degraded"
                ;;
            "OPEN")
                checks+=("circuit_breaker_${channel}:fail:open")
                # Open circuit breakers are degraded, not failed
                [[ "$status" == "pass" ]] && status="degraded"
                ;;
        esac
    done

    echo "$status|${checks[*]}"
}

# Check degradation level
check_degradation() {
    local checks=()
    local status="pass"

    local level
    level=$(get_degradation_level 2>/dev/null || echo "0")

    case "$level" in
        0)
            checks+=("degradation_level:pass:0")
            ;;
        1)
            checks+=("degradation_level:warn:1")
            status="degraded"
            ;;
        2)
            checks+=("degradation_level:warn:2")
            status="degraded"
            ;;
        3)
            checks+=("degradation_level:warn:3")
            status="degraded"
            ;;
        4)
            checks+=("degradation_level:fail:4")
            status="fail"
            ;;
    esac

    echo "$status|${checks[*]}"
}

# Check notification channels
check_channels() {
    local checks=()
    local status="pass"
    local configured_channels=()

    # Check each channel configuration
    local config_file="${RDD_DIR}/hooks.yml"
    if [[ -f "$config_file" ]]; then
        # Parse channels from config
        if command -v yq &> /dev/null; then
            local channels
            channels=$(yq eval '.channels | keys[]' "$config_file" 2>/dev/null || true)

            for channel in $channels; do
                local enabled
                enabled=$(yq eval ".channels.${channel}.enabled" "$config_file" 2>/dev/null || echo "false")

                if [[ "$enabled" == "true" ]]; then
                    configured_channels+=("$channel")
                    checks+=("channel_${channel}:pass:configured")
                else
                    checks+=("channel_${channel}:warn:disabled")
                fi
            done
        fi
    fi

    if [[ ${#configured_channels[@]} -eq 0 ]]; then
        checks+=("channels:warn:none_configured")
        status="degraded"
    fi

    echo "$status|${checks[*]}"
}

#######################################
# Main Health Check
#######################################

# Run all health checks
# Usage: health_check [format]
health_check() {
    local format="${1:-$HEALTH_OUTPUT_FORMAT}"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    local overall_status="healthy"
    local all_checks=()

    # Run checks
    local config_result
    config_result=$(check_config_files)
    local config_status="${config_result%%|*}"
    local config_checks="${config_result#*|}"
    all_checks+=($config_checks)
    [[ "$config_status" == "fail" ]] && overall_status="unhealthy"
    [[ "$config_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

    local scripts_result
    scripts_result=$(check_scripts)
    local scripts_status="${scripts_result%%|*}"
    local scripts_checks="${scripts_result#*|}"
    all_checks+=($scripts_checks)
    [[ "$scripts_status" == "fail" ]] && overall_status="unhealthy"
    [[ "$scripts_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

    local cache_result
    cache_result=$(check_cache)
    local cache_status="${cache_result%%|*}"
    local cache_checks="${cache_result#*|}"
    all_checks+=($cache_checks)
    [[ "$cache_status" == "fail" ]] && overall_status="unhealthy"
    [[ "$cache_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

    local tools_result
    tools_result=$(check_tools)
    local tools_status="${tools_result%%|*}"
    local tools_checks="${tools_result#*|}"
    all_checks+=($tools_checks)
    [[ "$tools_status" == "fail" ]] && overall_status="unhealthy"
    [[ "$tools_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

    # Run detailed checks if enabled
    if [[ "$HEALTH_DETAILED_CHECKS" == "true" ]]; then
        local cb_result
        cb_result=$(check_circuit_breakers)
        local cb_status="${cb_result%%|*}"
        local cb_checks="${cb_result#*|}"
        all_checks+=($cb_checks)
        [[ "$cb_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

        local deg_result
        deg_result=$(check_degradation)
        local deg_status="${deg_result%%|*}"
        local deg_checks="${deg_result#*|}"
        all_checks+=($deg_checks)
        [[ "$deg_status" == "fail" ]] && overall_status="unhealthy"
        [[ "$deg_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"
    fi

    # Run dependency checks if enabled
    if [[ "$HEALTH_INCLUDE_DEPENDENCIES" == "true" ]]; then
        local channels_result
        channels_result=$(check_channels)
        local channels_status="${channels_result%%|*}"
        local channels_checks="${channels_result#*|}"
        all_checks+=($channels_checks)
        [[ "$channels_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"
    fi

    # Output result
    if [[ "$format" == "json" ]]; then
        output_health_json "$overall_status" "$timestamp" all_checks
    else
        output_health_text "$overall_status" "$timestamp" all_checks
    fi

    [[ "$overall_status" == "healthy" ]] && return 0
    [[ "$overall_status" == "degraded" ]] && return 0
    return 1
}

# Output health as JSON
output_health_json() {
    local status="$1"
    local timestamp="$2"
    shift 2
    local checks=("$@")

    local checks_json="["
    local first=true
    for check in "${checks[@]}"; do
        if [[ "$first" != "true" ]]; then
            checks_json+=","
        fi
        checks_json+="\"$check\""
        first=false
    done
    checks_json+="]"

    cat <<EOF
{
    "status": "$status",
    "timestamp": "$timestamp",
    "version": "$RDD_VERSION",
    "checks": $checks_json
}
EOF
}

# Output health as text
output_health_text() {
    local status="$1"
    local timestamp="$2"
    shift 2
    local checks=("$@")

    local color
    case "$status" in
        healthy)   color="\033[0;32m" ;;
        degraded)  color="\033[1;33m" ;;
        unhealthy) color="\033[0;31m" ;;
    esac
    local reset="\033[0m"

    echo -e "${color}RDD Health Check${reset}"
    echo "==================="
    echo ""
    echo "Status: ${color}${status}${reset}"
    echo "Timestamp: $timestamp"
    echo "Version: $RDD_VERSION"
    echo ""
    echo "Checks:"
    for check in "${checks[@]}"; do
        local check_status="${check##*:}"
        local check_name="${check%:*}"
        local check_color
        case "$check_status" in
            pass)     check_color="\033[0;32m" ;;
            warn*)    check_color="\033[1;33m" ;;
            fail*)    check_color="\033[0;31m" ;;
        esac
        echo -e "  ${check_color}[${check_status}]${reset} ${check_name}"
    done
}

#######################################
# Readiness Check
#######################################

# Check if framework is ready to handle requests
# Usage: readiness_check [format]
readiness_check() {
    local format="${1:-$HEALTH_OUTPUT_FORMAT}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    local ready=true
    local reasons=()

    # Check if in safe mode
    local level
    level=$(get_degradation_level 2>/dev/null || echo "0")
    if [[ $level -ge 4 ]]; then
        ready=false
        reasons+=("degradation_level_4")
    fi

    # Check critical tools
    if ! check_command_exists "curl"; then
        ready=false
        reasons+=("missing_curl")
    fi

    if ! check_command_exists "jq"; then
        ready=false
        reasons+=("missing_jq")
    fi

    # Check cache directory
    if ! check_directory_writable "${RDD_DIR}/cache"; then
        ready=false
        reasons+=("cache_not_writable")
    fi

    # Output result
    if [[ "$format" == "json" ]]; then
        if [[ "$ready" == "true" ]]; then
            echo "{\"status\":\"ready\",\"timestamp\":\"$timestamp\"}"
        else
            local reasons_json=$(printf '%s\n' "${reasons[@]}" | jq -R . | jq -s .)
            echo "{\"status\":\"not_ready\",\"timestamp\":\"$timestamp\",\"reasons\":$reasons_json}"
        fi
    else
        if [[ "$ready" == "true" ]]; then
            echo "Status: READY"
        else
            echo "Status: NOT READY"
            echo "Reasons:"
            for reason in "${reasons[@]}"; do
                echo "  - $reason"
            done
        fi
    fi

    [[ "$ready" == "true" ]] && return 0
    return 1
}

#######################################
# Liveness Check
#######################################

# Check if process is alive
# Usage: liveness_check [format]
liveness_check() {
    local format="${1:-$HEALTH_OUTPUT_FORMAT}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    if [[ "$format" == "json" ]]; then
        echo "{\"status\":\"alive\",\"timestamp\":\"$timestamp\",\"pid\":$$}"
    else
        echo "Status: ALIVE"
        echo "Timestamp: $timestamp"
        echo "PID: $$"
    fi

    return 0
}

#######################################
# Dependency Check
#######################################

# Check configured dependencies
# Usage: dependency_check [format]
dependency_check() {
    local format="${1:-$HEALTH_OUTPUT_FORMAT}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    local deps=()

    # Check notification channels
    local config_file="${RDD_DIR}/hooks.yml"
    if [[ -f "$config_file" ]]; then
        if command -v yq &> /dev/null; then
            local channels
            channels=$(yq eval '.channels | keys[]' "$config_file" 2>/dev/null || true)

            for channel in $channels; do
                local enabled
                enabled=$(yq eval ".channels.${channel}.enabled" "$config_file" 2>/dev/null || echo "false")
                if [[ "$enabled" == "true" ]]; then
                    deps+=("notification_${channel}:configured")
                else
                    deps+=("notification_${channel}:disabled")
                fi
            done
        fi
    fi

    # Check templates
    if [[ -f "${RDD_DIR}/templates.yml" ]]; then
        deps+=("templates:configured")
    else
        deps+=("templates:missing")
    fi

    # Check hooks
    if [[ -d "${RDD_DIR}/hooks" ]]; then
        local hook_count
        hook_count=$(find "${RDD_DIR}/hooks" -name "*.sh" -type f 2>/dev/null | wc -l)
        deps+=("hooks:configured:${hook_count}")
    else
        deps+=("hooks:missing")
    fi

    # Output result
    if [[ "$format" == "json" ]]; then
        local deps_json="["
        local first=true
        for dep in "${deps[@]}"; do
            if [[ "$first" != "true" ]]; then
                deps_json+=","
            fi
            deps_json+="\"$dep\""
            first=false
        done
        deps_json+="]"

        echo "{\"dependencies\":$deps_json,\"timestamp\":\"$timestamp\"}"
    else
        echo "Dependencies:"
        for dep in "${deps[@]}"; do
            echo "  - $dep"
        done
    fi

    return 0
}

#######################################
# CLI Interface
#######################################

# Show usage
show_health_usage() {
    cat <<EOF
RDD Health Check System

Usage: health.sh <command> [options]

Commands:
  health      Run full health check
  readiness   Check if framework is ready
  liveness    Check if process is alive
  dependency  Check configured dependencies

Options:
  --format <json|text>  Output format (default: json)
  --detailed            Include detailed checks
  --no-deps             Exclude dependency checks

Examples:
  health.sh health
  health.sh health --format text
  health.sh readiness --format json
  health.sh liveness
  health.sh dependency
EOF
}

# Main entry point
health_main() {
    local command="${1:-health}"
    shift || true

    local format="$HEALTH_OUTPUT_FORMAT"
    local detailed="$HEALTH_DETAILED_CHECKS"
    local deps="$HEALTH_INCLUDE_DEPENDENCIES"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                format="$2"
                shift 2
                ;;
            --detailed)
                detailed="true"
                shift
                ;;
            --no-deps)
                deps="false"
                shift
                ;;
            -h|--help|help)
                show_health_usage
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done

    HEALTH_OUTPUT_FORMAT="$format"
    HEALTH_DETAILED_CHECKS="$detailed"
    HEALTH_INCLUDE_DEPENDENCIES="$deps"

    case "$command" in
        health)
            health_check "$format"
            ;;
        readiness)
            readiness_check "$format"
            ;;
        liveness)
            liveness_check "$format"
            ;;
        dependency|dependencies)
            dependency_check "$format"
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_health_usage
            return 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    health_main "$@"
fi

# Export functions for sourcing
export -f health_check readiness_check liveness_check dependency_check
export -f check_config_files check_scripts check_cache check_tools
export -f check_circuit_breakers check_degradation check_channels
