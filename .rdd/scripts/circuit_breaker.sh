#!/bin/bash
#
# RDD Circuit Breaker Implementation
# Implements circuit breaker pattern to prevent cascading failures
#
# Usage:
#   source "${RDD_DIR}/scripts/circuit_breaker.sh"
#   if circuit_breaker_check "wecom"; then
#       # Execute operation
#       if success; then
#           circuit_breaker_record_success "wecom"
#       else
#           circuit_breaker_record_failure "wecom"
#       fi
#   else
#       # Circuit is open, fail fast
#   fi

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"

#######################################
# Circuit Breaker Configuration
#######################################

# Default configuration
CIRCUIT_BREAKER_ENABLED="${CIRCUIT_BREAKER_ENABLED:-true}"
CIRCUIT_BREAKER_FAILURE_THRESHOLD="${CIRCUIT_BREAKER_FAILURE_THRESHOLD:-5}"
CIRCUIT_BREAKER_SUCCESS_THRESHOLD="${CIRCUIT_BREAKER_SUCCESS_THRESHOLD:-3}"
CIRCUIT_BREAKER_TIMEOUT="${CIRCUIT_BREAKER_TIMEOUT:-60}"
CIRCUIT_BREAKER_HALF_OPEN_MAX_REQUESTS="${CIRCUIT_BREAKER_HALF_OPEN_MAX_REQUESTS:-1}"

# Circuit breaker states
export CIRCUIT_STATE_CLOSED="CLOSED"
export CIRCUIT_STATE_OPEN="OPEN"
export CIRCUIT_STATE_HALF_OPEN="HALF_OPEN"

# State storage directory
CIRCUIT_BREAKER_DIR="${CIRCUIT_BREAKER_DIR:-${RDD_DIR}/cache/circuit_breaker}"

#######################################
# Circuit Breaker State Management
#######################################

# Initialize circuit breaker directory
init_circuit_breaker() {
  mkdir -p "$CIRCUIT_BREAKER_DIR"
}

# Get state file path for a service
# Usage: get_state_file <service_name>
get_state_file() {
  local service="$1"
  echo "${CIRCUIT_BREAKER_DIR}/${service}.json"
}

# Read circuit breaker state
# Usage: read_circuit_state <service_name>
# Returns JSON: {"state":"CLOSED","failures":0,"successes":0,"last_failure":0,"last_success":0,"total_requests":0}
read_circuit_state() {
  local service="$1"
  local state_file
  state_file=$(get_state_file "$service")

  if [[ ! -f "$state_file" ]]; then
    # Return default state
    echo '{"state":"CLOSED","failures":0,"successes":0,"last_failure":0,"last_success":0,"total_requests":0}'
    return
  fi

  cat "$state_file"
}

# Write circuit breaker state
# Usage: write_circuit_state <service_name> <state_json>
write_circuit_state() {
  local service="$1"
  local state_json="$2"
  local state_file
  state_file=$(get_state_file "$service")

  init_circuit_breaker
  echo "$state_json" >"$state_file"
}

# Get specific field from state
# Usage: get_state_field <service_name> <field>
get_state_field() {
  local service="$1"
  local field="$2"
  local state
  state=$(read_circuit_state "$service")

  if command -v jq &>/dev/null; then
    echo "$state" | jq -r ".${field}"
  else
    # Fallback: simple JSON parsing
    echo "$state" | grep -o "\"${field}\":[^,}]*" | sed 's/.*: *"\?\([^",}]*\)"\?.*/\1/'
  fi
}

#######################################
# Circuit Breaker Core Functions
#######################################

# Check if circuit breaker allows request
# Usage: circuit_breaker_check <service_name>
# Returns: 0 if allowed, 1 if blocked
circuit_breaker_check() {
  local service="$1"

  if [[ "$CIRCUIT_BREAKER_ENABLED" != "true" ]]; then
    return 0
  fi

  local state
  state=$(get_state_field "$service" "state")
  local last_failure
  last_failure=$(get_state_field "$service" "last_failure")
  local now
  now=$(date +%s)

  case "$state" in
    "$CIRCUIT_STATE_CLOSED")
      # Circuit is closed, allow request
      return 0
      ;;
    "$CIRCUIT_STATE_OPEN")
      # Check if timeout has passed
      local timeout_diff=$((now - last_failure))
      if [[ $timeout_diff -ge $CIRCUIT_BREAKER_TIMEOUT ]]; then
        # Transition to half-open
        circuit_breaker_transition "$service" "$CIRCUIT_STATE_HALF_OPEN"
        return 0
      fi
      # Circuit is still open, block request
      return 1
      ;;
    "$CIRCUIT_STATE_HALF_OPEN")
      # Allow limited requests in half-open state
      return 0
      ;;
    *)
      # Unknown state, reset to closed
      circuit_breaker_reset "$service"
      return 0
      ;;
  esac
}

# Record successful request
# Usage: circuit_breaker_record_success <service_name>
circuit_breaker_record_success() {
  local service="$1"

  if [[ "$CIRCUIT_BREAKER_ENABLED" != "true" ]]; then
    return
  fi

  local state
  state=$(read_circuit_state "$service")
  local current_state
  current_state=$(echo "$state" | jq -r '.state')
  local now
  now=$(date +%s)

  # Increment counters
  local successes
  successes=$(echo "$state" | jq -r '.successes')
  successes=$((successes + 1))

  local total
  total=$(echo "$state" | jq -r '.total_requests')
  total=$((total + 1))

  # Check if we should close the circuit (in half-open state)
  if [[ "$current_state" == "$CIRCUIT_STATE_HALF_OPEN" ]]; then
    if [[ $successes -ge $CIRCUIT_BREAKER_SUCCESS_THRESHOLD ]]; then
      # Reset to closed
      circuit_breaker_reset "$service"
      if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo "[CIRCUIT_BREAKER] $service: HALF_OPEN -> CLOSED (success threshold reached)" >&2
      fi
      return
    fi
  fi

  # Reset failure counter on success
  local new_state
  new_state=$(echo "$state" | jq --arg state "$current_state" \
    --argjson successes "$successes" \
    --argjson total "$total" \
    --arg now "$now" \
    '.failures = 0 | .successes = $successes | .last_success = $now | .total_requests = $total')

  write_circuit_state "$service" "$new_state"
}

# Record failed request
# Usage: circuit_breaker_record_failure <service_name>
circuit_breaker_record_failure() {
  local service="$1"

  if [[ "$CIRCUIT_BREAKER_ENABLED" != "true" ]]; then
    return
  fi

  local state
  state=$(read_circuit_state "$service")
  local current_state
  current_state=$(echo "$state" | jq -r '.state')
  local now
  now=$(date +%s)

  # Increment counters
  local failures
  failures=$(echo "$state" | jq -r '.failures')
  failures=$((failures + 1))

  local total
  total=$(echo "$state" | jq -r '.total_requests')
  total=$((total + 1))

  # Reset success counter on failure
  local successes=0

  # Check if we should open the circuit
  if [[ "$current_state" == "$CIRCUIT_STATE_HALF_OPEN" ]]; then
    # Any failure in half-open state opens the circuit
    circuit_breaker_open "$service"
    if [[ "${VERBOSE:-false}" == "true" ]]; then
      echo "[CIRCUIT_BREAKER] $service: HALF_OPEN -> OPEN (failure in half-open)" >&2
    fi
    return
  elif [[ $failures -ge $CIRCUIT_BREAKER_FAILURE_THRESHOLD ]]; then
    circuit_breaker_open "$service"
    if [[ "${VERBOSE:-false}" == "true" ]]; then
      echo "[CIRCUIT_BREAKER] $service: CLOSED -> OPEN (failure threshold reached)" >&2
    fi
    return
  fi

  # Update state
  local new_state
  new_state=$(echo "$state" | jq --arg state "$current_state" \
    --argjson failures "$failures" \
    --argjson successes "$successes" \
    --argjson total "$total" \
    --arg now "$now" \
    '.failures = $failures | .successes = $successes | .last_failure = $now | .total_requests = $total')

  write_circuit_state "$service" "$new_state"
}

# Transition circuit breaker state
# Usage: circuit_breaker_transition <service_name> <new_state>
circuit_breaker_transition() {
  local service="$1"
  local new_state="$2"

  local state
  state=$(read_circuit_state "$service")
  local now
  now=$(date +%s)

  local new_state_json
  new_state_json=$(echo "$state" | jq --arg state "$new_state" --arg now "$now" \
    '.state = $state | .last_transition = $now')

  write_circuit_state "$service" "$new_state_json"
}

# Open the circuit
# Usage: circuit_breaker_open <service_name>
circuit_breaker_open() {
  local service="$1"

  local state
  state=$(read_circuit_state "$service")
  local now
  now=$(date +%s)

  local new_state
  new_state=$(echo "$state" | jq --arg now "$now" \
    '.state = "OPEN" | .last_failure = $now | .last_transition = $now')

  write_circuit_state "$service" "$new_state"
}

# Close the circuit (reset to healthy state)
# Usage: circuit_breaker_close <service_name>
circuit_breaker_close() {
  local service="$1"
  circuit_breaker_reset "$service"
}

# Reset circuit breaker to initial state
# Usage: circuit_breaker_reset <service_name>
circuit_breaker_reset() {
  local service="$1"

  local initial_state='{"state":"CLOSED","failures":0,"successes":0,"last_failure":0,"last_success":0,"total_requests":0}'
  write_circuit_state "$service" "$initial_state"
}

#######################################
# Circuit Breaker Information Functions
#######################################

# Get circuit breaker state
# Usage: get_circuit_breaker_state <service_name>
get_circuit_breaker_state() {
  local service="$1"
  get_state_field "$service" "state"
}

# Check if circuit is open
# Usage: is_circuit_open <service_name>
is_circuit_open() {
  local service="$1"
  local state
  state=$(get_circuit_breaker_state "$service")
  [[ "$state" == "$CIRCUIT_STATE_OPEN" ]]
}

# Check if circuit is closed
# Usage: is_circuit_closed <service_name>
is_circuit_closed() {
  local service="$1"
  local state
  state=$(get_circuit_breaker_state "$service")
  [[ "$state" == "$CIRCUIT_STATE_CLOSED" ]]
}

# Check if circuit is half-open
# Usage: is_circuit_half_open <service_name>
is_circuit_half_open() {
  local service="$1"
  local state
  state=$(get_circuit_breaker_state "$service")
  [[ "$state" == "$CIRCUIT_STATE_HALF_OPEN" ]]
}

# Get circuit breaker statistics
# Usage: get_circuit_breaker_stats <service_name>
get_circuit_breaker_stats() {
  local service="$1"
  read_circuit_state "$service"
}

# Get all circuit breaker states
# Usage: get_all_circuit_breaker_states
get_all_circuit_breaker_states() {
  init_circuit_breaker

  local result="{"
  local first=true

  for state_file in "$CIRCUIT_BREAKER_DIR"/*.json; do
    if [[ -f "$state_file" ]]; then
      local service
      service=$(basename "$state_file" .json)
      local state
      state=$(get_circuit_breaker_state "$service")

      if [[ "$first" != "true" ]]; then
        result+=","
      fi
      result+="\"$service\":\"$state\""
      first=false
    fi
  done

  result+="}"
  echo "$result"
}

#######################################
# Circuit Breaker with Operation
#######################################

# Execute operation with circuit breaker protection
# Usage: with_circuit_breaker <service_name> <command...>
# Returns: 0 on success, 1 on failure or circuit open
with_circuit_breaker() {
  local service="$1"
  shift
  local cmd=("$@")

  # Check circuit state
  if ! circuit_breaker_check "$service"; then
    print_error "E203" "channel=$service"
    return 1
  fi

  # Execute command
  local exit_code=0
  if "${cmd[@]}" 2>&1; then
    circuit_breaker_record_success "$service"
    return 0
  else
    exit_code=$?
    circuit_breaker_record_failure "$service"
    return $exit_code
  fi
}

# Execute operation with circuit breaker and fallback
# Usage: with_circuit_breaker_fallback <service_name> <fallback_command> -- <command...>
with_circuit_breaker_fallback() {
  local service="$1"
  local fallback="$2"
  shift 2

  # Skip --
  [[ "$1" == "--" ]] && shift

  local cmd=("$@")

  # Try with circuit breaker
  if with_circuit_breaker "$service" "${cmd[@]}"; then
    return 0
  fi

  # Execute fallback
  if [[ -n "$fallback" ]]; then
    if [[ "${VERBOSE:-false}" == "true" ]]; then
      echo "[CIRCUIT_BREAKER] $service: Executing fallback" >&2
    fi
    eval "$fallback"
    return $?
  fi

  return 1
}

#######################################
# Circuit Breaker Metrics
#######################################

# Export circuit breaker metrics for Prometheus
# Usage: export_circuit_breaker_metrics
export_circuit_breaker_metrics() {
  init_circuit_breaker

  echo "# HELP rdd_circuit_breaker_state Circuit breaker state (0=closed, 1=open, 2=half_open)"
  echo "# TYPE rdd_circuit_breaker_state gauge"

  for state_file in "$CIRCUIT_BREAKER_DIR"/*.json; do
    if [[ -f "$state_file" ]]; then
      local service
      service=$(basename "$state_file" .json)
      local state
      state=$(get_circuit_breaker_state "$service")

      local state_value
      case "$state" in
        "$CIRCUIT_STATE_CLOSED") state_value=0 ;;
        "$CIRCUIT_STATE_OPEN") state_value=1 ;;
        "$CIRCUIT_STATE_HALF_OPEN") state_value=2 ;;
        *) state_value=0 ;;
      esac

      echo "rdd_circuit_breaker_state{service=\"${service}\"} ${state_value}"
    fi
  done

  echo ""
  echo "# HELP rdd_circuit_breaker_failures Total failures recorded"
  echo "# TYPE rdd_circuit_breaker_failures gauge"

  for state_file in "$CIRCUIT_BREAKER_DIR"/*.json; do
    if [[ -f "$state_file" ]]; then
      local service
      service=$(basename "$state_file" .json)
      local failures
      failures=$(get_state_field "$service" "failures")
      echo "rdd_circuit_breaker_failures{service=\"${service}\"} ${failures:-0}"
    fi
  done

  echo ""
  echo "# HELP rdd_circuit_breaker_requests Total requests recorded"
  echo "# TYPE rdd_circuit_breaker_requests gauge"

  for state_file in "$CIRCUIT_BREAKER_DIR"/*.json; do
    if [[ -f "$state_file" ]]; then
      local service
      service=$(basename "$state_file" .json)
      local total
      total=$(get_state_field "$service" "total_requests")
      echo "rdd_circuit_breaker_requests{service=\"${service}\"} ${total:-0}"
    fi
  done
}

#######################################
# Initialization
#######################################

# Initialize circuit breaker on source
init_circuit_breaker

# Export functions
export -f init_circuit_breaker get_state_file read_circuit_state write_circuit_state get_state_field
export -f circuit_breaker_check circuit_breaker_record_success circuit_breaker_record_failure
export -f circuit_breaker_transition circuit_breaker_open circuit_breaker_close circuit_breaker_reset
export -f get_circuit_breaker_state is_circuit_open is_circuit_closed is_circuit_half_open
export -f get_circuit_breaker_stats get_all_circuit_breaker_states
export -f with_circuit_breaker with_circuit_breaker_fallback
export -f export_circuit_breaker_metrics
