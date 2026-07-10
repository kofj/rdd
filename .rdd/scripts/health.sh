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

# Source dependencies (with fallback if not available)
if [[ -f "${RDD_DIR}/lib/error_codes.sh" ]]; then
  source "${RDD_DIR}/lib/error_codes.sh"
fi
if [[ -f "${RDD_DIR}/scripts/logger.sh" ]]; then
  source "${RDD_DIR}/scripts/logger.sh"
fi
if [[ -f "${RDD_DIR}/scripts/circuit_breaker.sh" ]]; then
  source "${RDD_DIR}/scripts/circuit_breaker.sh"
fi
if [[ -f "${RDD_DIR}/lib/degradation.sh" ]]; then
  source "${RDD_DIR}/lib/degradation.sh"
fi

#######################################
# Health Check Configuration
#######################################

HEALTH_OUTPUT_FORMAT="${HEALTH_OUTPUT_FORMAT:-json}"
HEALTH_DETAILED_CHECKS="${HEALTH_DETAILED_CHECKS:-true}"
HEALTH_INCLUDE_DEPENDENCIES="${HEALTH_INCLUDE_DEPENDENCIES:-true}"
RDD_VERSION="${RDD_VERSION:-1.0.0}"

#######################################
# Health Check Functions
#######################################

# Check if a command exists
check_command_exists() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
}

# Check if a file exists and is readable
check_file_readable() {
  local file="$1"
  [[ -f "$file" && -r "$file" ]]
}

# Check if a file exists and is executable
check_file_executable() {
  local file="$1"
  [[ -f "$file" && -x "$file" ]]
}

# Check if a directory exists and is writable
check_directory_writable() {
  local dir="$1"
  [[ -d "$dir" && -w "$dir" ]]
}

#######################################
# Individual Health Checks
#######################################

# Check configuration files
check_config_files() {
  local checks=()
  local status="pass"

  if check_file_readable "${RDD_DIR}/hooks.yml"; then
    checks+=("config_hooks_yml:pass")
  else
    checks+=("config_hooks_yml:fail:missing")
    status="fail"
  fi

  if check_file_readable "${RDD_DIR}/templates.yml"; then
    checks+=("config_templates_yml:pass")
  else
    checks+=("config_templates_yml:fail:missing")
    status="fail"
  fi

  if check_file_readable "${RDD_DIR}/config.yml"; then
    checks+=("config_yml:pass")
  else
    checks+=("config_yml:warn:missing")
    [[ "$status" == "pass" ]] && status="degraded"
  fi

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

  if check_file_executable "${RDD_DIR}/scripts/notify.sh"; then
    checks+=("script_notify:pass")
  else
    checks+=("script_notify:fail:not_executable")
    status="fail"
  fi

  local required_scripts=("retry.sh" "circuit_breaker.sh" "logger.sh" "metrics.sh" "health.sh")
  for script in "${required_scripts[@]}"; do
    if check_file_readable "${RDD_DIR}/scripts/$script"; then
      checks+=("script_${script%.sh}:pass")
    else
      checks+=("script_${script%.sh}:fail:missing")
    fi
  done

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

  if check_directory_writable "${RDD_DIR}/cache"; then
    checks+=("cache_dir:pass")
  else
    checks+=("cache_dir:fail:not_writable")
    status="fail"
  fi

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

  local required_tools=("curl" "jq")
  for tool in "${required_tools[@]}"; do
    if check_command_exists "$tool"; then
      checks+=("tool_${tool}:pass")
    else
      checks+=("tool_${tool}:fail:missing")
      status="fail"
    fi
  done

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

  # Return appropriate exit code
  [[ "$status" == "fail" ]] && return 1
  return 0
}

# Check circuit breakers
check_circuit_breakers() {
  local checks=()
  local status="pass"

  local channels=("wecom" "email" "telegram" "bark" "webhook")
  for channel in "${channels[@]}"; do
    local cb_state="CLOSED"
    if declare -f get_circuit_breaker_state &>/dev/null; then
      cb_state=$(get_circuit_breaker_state "$channel" 2>/dev/null || echo "CLOSED")
    fi

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

  local level=0
  if declare -f get_degradation_level &>/dev/null; then
    level=$(get_degradation_level 2>/dev/null || echo "0")
  fi

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

  local config_file="${RDD_DIR}/hooks.yml"
  if [[ -f "$config_file" ]]; then
    if command -v yq &>/dev/null; then
      local channels
      channels=$(yq eval '.channels | keys[]' "$config_file" 2>/dev/null || true)

      for channel in $channels; do
        local enabled
        enabled=$(yq eval ".channels.${channel}.enabled" "$config_file" 2>/dev/null || echo "false")

        if [[ "$enabled" == "true" ]]; then
          checks+=("channel_${channel}:pass:configured")
        else
          checks+=("channel_${channel}:warn:disabled")
        fi
      done
    fi
  fi

  if [[ ${#checks[@]} -eq 0 ]]; then
    checks+=("channels:warn:none_configured")
    status="degraded"
  fi

  echo "$status|${checks[*]}"
}

#######################################
# Main Health Check
#######################################

# Run all health checks
health_check() {
  local format="${1:-$HEALTH_OUTPUT_FORMAT}"

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

  local overall_status="healthy"
  local all_checks=()

  # Run checks
  local config_result scripts_result cache_result tools_result cb_result deg_result channels_result

  config_result=$(check_config_files)
  local config_status="${config_result%%|*}"
  local config_checks="${config_result#*|}"
  [[ -n "$config_checks" ]] && all_checks+=($config_checks)
  [[ "$config_status" == "fail" ]] && overall_status="unhealthy"
  [[ "$config_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

  scripts_result=$(check_scripts)
  local scripts_status="${scripts_result%%|*}"
  local scripts_checks="${scripts_result#*|}"
  [[ -n "$scripts_checks" ]] && all_checks+=($scripts_checks)
  [[ "$scripts_status" == "fail" ]] && overall_status="unhealthy"
  [[ "$scripts_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

  cache_result=$(check_cache)
  local cache_status="${cache_result%%|*}"
  local cache_checks="${cache_result#*|}"
  [[ -n "$cache_checks" ]] && all_checks+=($cache_checks)
  [[ "$cache_status" == "fail" ]] && overall_status="unhealthy"
  [[ "$cache_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

  tools_result=$(check_tools)
  local tools_status="${tools_result%%|*}"
  local tools_checks="${tools_result#*|}"
  [[ -n "$tools_checks" ]] && all_checks+=($tools_checks)
  [[ "$tools_status" == "fail" ]] && overall_status="unhealthy"
  [[ "$tools_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

  if [[ "$HEALTH_DETAILED_CHECKS" == "true" ]]; then
    cb_result=$(check_circuit_breakers)
    local cb_status="${cb_result%%|*}"
    local cb_checks="${cb_result#*|}"
    [[ -n "$cb_checks" ]] && all_checks+=($cb_checks)
    [[ "$cb_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"

    deg_result=$(check_degradation)
    local deg_status="${deg_result%%|*}"
    local deg_checks="${deg_result#*|}"
    [[ -n "$deg_checks" ]] && all_checks+=($deg_checks)
    [[ "$deg_status" == "fail" ]] && overall_status="unhealthy"
    [[ "$deg_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"
  fi

  if [[ "$HEALTH_INCLUDE_DEPENDENCIES" == "true" ]]; then
    channels_result=$(check_channels)
    local channels_status="${channels_result%%|*}"
    local channels_checks="${channels_result#*|}"
    [[ -n "$channels_checks" ]] && all_checks+=($channels_checks)
    [[ "$channels_status" == "degraded" && "$overall_status" != "unhealthy" ]] && overall_status="degraded"
  fi

  # Output result
  if [[ "$format" == "json" ]]; then
    output_health_json "$overall_status" "$timestamp" "${all_checks[@]}"
  else
    output_health_text "$overall_status" "$timestamp" "${all_checks[@]}"
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
    healthy) color="\033[0;32m" ;;
    degraded) color="\033[1;33m" ;;
    unhealthy) color="\033[0;31m" ;;
    *) color="" ;;
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
      pass) check_color="\033[0;32m" ;;
      warn*) check_color="\033[1;33m" ;;
      fail*) check_color="\033[0;31m" ;;
      *) check_color="" ;;
    esac
    echo -e "  ${check_color}[${check_status}]${reset} ${check_name}"
  done
}

#######################################
# Readiness Check
#######################################

readiness_check() {
  local format="${1:-$HEALTH_OUTPUT_FORMAT}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

  local ready=true
  local reasons=()

  local level=0
  if declare -f get_degradation_level &>/dev/null; then
    level=$(get_degradation_level 2>/dev/null || echo "0")
  fi
  if [[ $level -ge 4 ]]; then
    ready=false
    reasons+=("degradation_level_4")
  fi

  if ! check_command_exists "curl"; then
    ready=false
    reasons+=("missing_curl")
  fi

  if ! check_command_exists "jq"; then
    ready=false
    reasons+=("missing_jq")
  fi

  if ! check_directory_writable "${RDD_DIR}/cache"; then
    ready=false
    reasons+=("cache_not_writable")
  fi

  if [[ "$format" == "json" ]]; then
    if [[ "$ready" == "true" ]]; then
      echo "{\"status\":\"ready\",\"timestamp\":\"$timestamp\"}"
    else
      local reasons_json="[]"
      if [[ ${#reasons[@]} -gt 0 ]]; then
        reasons_json=$(printf '%s\n' "${reasons[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
      fi
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

dependency_check() {
  local format="${1:-$HEALTH_OUTPUT_FORMAT}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

  local deps=()

  local config_file="${RDD_DIR}/hooks.yml"
  if [[ -f "$config_file" ]]; then
    if command -v yq &>/dev/null; then
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

  if [[ -f "${RDD_DIR}/templates.yml" ]]; then
    deps+=("templates:configured")
  else
    deps+=("templates:missing")
  fi

  if [[ -d "${RDD_DIR}/hooks" ]]; then
    local hook_count
    hook_count=$(find "${RDD_DIR}/hooks" -name "*.sh" -type f 2>/dev/null | wc -l)
    deps+=("hooks:configured:${hook_count}")
  else
    deps+=("hooks:missing")
  fi

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

  # Handle help flags
  case "$command" in
    -h | --help | help)
      show_health_usage
      return 0
      ;;
  esac

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
      -h | --help | help)
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
    dependency | dependencies)
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
export -f output_health_json output_health_text show_health_usage health_main
