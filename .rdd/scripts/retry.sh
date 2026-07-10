#!/bin/bash
#
# RDD Retry Mechanism
# Implements exponential backoff with jitter for retry logic
#
# Usage:
#   source "${RDD_DIR}/scripts/retry.sh"
#   retry_with_backoff <command>

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"

#######################################
# Retry Configuration
#######################################

# Default retry configuration
RETRY_MAX_ATTEMPTS="${RETRY_MAX_ATTEMPTS:-3}"
RETRY_INITIAL_DELAY="${RETRY_INITIAL_DELAY:-1}"
RETRY_MAX_DELAY="${RETRY_MAX_DELAY:-30}"
RETRY_BACKOFF_MULTIPLIER="${RETRY_BACKOFF_MULTIPLIER:-2}"
RETRY_JITTER="${RETRY_JITTER:-true}"
RETRY_JITTER_RANGE="${RETRY_JITTER_RANGE:-0.5}"

# Retry state tracking
RETRY_LAST_ATTEMPT=0
RETRY_LAST_DELAY=0
RETRY_LAST_ERROR=""

#######################################
# Helper Functions
#######################################

# Calculate delay with jitter
# Usage: calculate_delay <base_delay>
calculate_delay() {
  local base_delay="$1"

  if [[ "$RETRY_JITTER" != "true" ]]; then
    echo "$base_delay"
    return
  fi

  # Add jitter: base_delay * (1 + (random - 0.5) * jitter_range)
  local random_factor
  random_factor=$(awk -v seed="$RANDOM" 'BEGIN{srand(seed); print rand()}')
  local jitter_adjustment
  jitter_adjustment=$(awk -v rand_val="$random_factor" -v range="$RETRY_JITTER_RANGE" 'BEGIN{print 1 + (rand_val - 0.5) * range}')
  local delay
  delay=$(awk -v base="$base_delay" -v adj="$jitter_adjustment" 'BEGIN{print int(base * adj)}')

  # Ensure minimum delay of 1
  if [[ $delay -lt 1 ]]; then
    delay=1
  fi

  echo "$delay"
}

# Calculate next delay with exponential backoff
# Usage: calculate_next_delay <current_delay>
calculate_next_delay() {
  local current_delay="$1"

  # Exponential backoff
  local next_delay=$((current_delay * RETRY_BACKOFF_MULTIPLIER))

  # Cap at max delay
  if [[ $next_delay -gt $RETRY_MAX_DELAY ]]; then
    next_delay=$RETRY_MAX_DELAY
  fi

  echo "$next_delay"
}

# Sleep with progress indication
# Usage: sleep_with_progress <seconds> [message]
sleep_with_progress() {
  local seconds="$1"
  local message="${2:-Waiting}"

  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo "[RETRY] ${message} ${seconds}s..." >&2
  fi

  sleep "$seconds"
}

#######################################
# Core Retry Functions
#######################################

# Execute command with retry
# Usage: retry_with_backoff [--attempts N] [--delay N] [--max-delay N] [--no-jitter] -- <command...>
# Returns: 0 on success, 1 on failure after all retries
retry_with_backoff() {
  local max_attempts="$RETRY_MAX_ATTEMPTS"
  local initial_delay="$RETRY_INITIAL_DELAY"
  local max_delay="$RETRY_MAX_DELAY"
  local use_jitter="$RETRY_JITTER"
  local on_failure=""
  local on_success=""
  local on_retry=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --attempts | -a)
        max_attempts="$2"
        shift 2
        ;;
      --delay | -d)
        initial_delay="$2"
        shift 2
        ;;
      --max-delay | -m)
        max_delay="$2"
        shift 2
        ;;
      --jitter | -j)
        use_jitter="true"
        shift
        ;;
      --no-jitter)
        use_jitter="false"
        shift
        ;;
      --on-failure)
        on_failure="$2"
        shift 2
        ;;
      --on-success)
        on_success="$2"
        shift 2
        ;;
      --on-retry)
        on_retry="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
  done

  # Remaining arguments are the command
  local cmd=("$@")

  if [[ ${#cmd[@]} -eq 0 ]]; then
    print_error "E103" "field=command" "expected=non-empty command"
    return 1
  fi

  local attempt=1
  local delay="$initial_delay"
  local last_exit_code=0
  local last_error=""

  RETRY_LAST_ATTEMPT=0
  RETRY_LAST_DELAY=0
  RETRY_LAST_ERROR=""

  while [[ $attempt -le $max_attempts ]]; do
    RETRY_LAST_ATTEMPT=$attempt
    RETRY_LAST_DELAY=$delay

    # Execute command
    if [[ "${VERBOSE:-false}" == "true" ]]; then
      echo "[RETRY] Attempt $attempt/$max_attempts: ${cmd[*]}" >&2
    fi

    # Capture output and exit code
    local output
    if output=$("${cmd[@]}" 2>&1); then
      # Success
      RETRY_LAST_ERROR=""
      last_exit_code=0

      if [[ -n "$on_success" ]]; then
        eval "$on_success"
      fi

      # Output captured stdout
      echo "$output"
      return 0
    else
      last_exit_code=$?
      last_error="$output"
      RETRY_LAST_ERROR="$last_error"
    fi

    # Check if error is retryable
    if [[ $last_exit_code -ne 0 ]]; then
      # For now, all failures are retryable unless explicitly marked
      # This can be enhanced to check error codes

      if [[ $attempt -lt $max_attempts ]]; then
        # Calculate delay with jitter
        local actual_delay
        actual_delay=$(calculate_delay "$delay")

        if [[ -n "$on_retry" ]]; then
          eval "$on_retry"
        fi

        if [[ "${VERBOSE:-false}" == "true" || "${DRY_RUN:-false}" == "true" ]]; then
          echo "[RETRY] Attempt $attempt/$max_attempts failed (exit code: $last_exit_code)" >&2
          echo "[RETRY] Retrying in ${actual_delay}s..." >&2
          if [[ -n "$last_error" ]]; then
            echo "[RETRY] Error: $last_error" >&2
          fi
        fi

        # Sleep before retry
        sleep_with_progress "$actual_delay" "Retrying in"

        # Calculate next delay with exponential backoff
        delay=$(calculate_next_delay "$delay")
      fi
    fi

    ((attempt++))
  done

  # All retries exhausted
  if [[ -n "$on_failure" ]]; then
    eval "$on_failure"
  fi

  print_error "E900" "attempts=$max_attempts" "operation=${cmd[*]}"
  if [[ -n "$last_error" ]]; then
    echo "[RETRY] Last error: $last_error" >&2
  fi

  return $last_exit_code
}

# Execute command with simple retry (no backoff)
# Usage: retry_simple <max_attempts> <command...>
retry_simple() {
  local max_attempts="$1"
  shift
  local cmd=("$@")

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if "${cmd[@]}" 2>&1; then
      return 0
    fi
    ((attempt++))
    [[ $attempt -le $max_attempts ]] && sleep 1
  done

  return 1
}

# Execute command with condition check
# Usage: retry_until <max_attempts> <interval> <condition_command> -- <command...>
retry_until() {
  local max_attempts="$1"
  local interval="$2"
  local condition_cmd="$3"
  shift 3

  # Skip --
  [[ "$1" == "--" ]] && shift

  local cmd=("$@")

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    # Check condition
    if eval "$condition_cmd"; then
      # Condition met, execute command
      if "${cmd[@]}" 2>&1; then
        return 0
      fi
    fi

    ((attempt++))
    [[ $attempt -le $max_attempts ]] && sleep "$interval"
  done

  return 1
}

#######################################
# Retry Strategy Functions
#######################################

# Get retry strategy for error code
# Usage: get_retry_strategy <error_code>
# Returns: strategy name and parameters
get_retry_strategy() {
  local code="$1"

  if ! is_retryable "$code"; then
    echo "none"
    return
  fi

  case "$code" in
    E302) # Rate limit exceeded
      echo "backoff:initial=2:max=60:jitter=true"
      ;;
    E303) # Service unavailable
      echo "backoff:initial=5:max=120:jitter=true"
      ;;
    E300 | E301) # Network errors
      echo "backoff:initial=1:max=30:jitter=true"
      ;;
    E200) # Notification failed
      echo "backoff:initial=1:max=30:jitter=true"
      ;;
    *)
      echo "default:initial=1:max=30:jitter=true"
      ;;
  esac
}

# Apply retry strategy
# Usage: apply_retry_strategy <strategy> <command...>
apply_retry_strategy() {
  local strategy="$1"
  shift
  local cmd=("$@")

  # Parse strategy
  local strategy_type="${strategy%%:*}"
  local params="${strategy#*:}"

  case "$strategy_type" in
    none)
      # No retry
      "${cmd[@]}"
      return $?
      ;;
    backoff)
      local initial=1
      local max=30
      local jitter="true"

      # Parse parameters
      IFS=':' read -ra param_parts <<<"$params"
      for part in "${param_parts[@]}"; do
        local key="${part%%=*}"
        local value="${part#*=}"
        case "$key" in
          initial) initial="$value" ;;
          max) max="$value" ;;
          jitter) jitter="$value" ;;
        esac
      done

      retry_with_backoff \
        --attempts "$RETRY_MAX_ATTEMPTS" \
        --delay "$initial" \
        --max-delay "$max" \
        $([[ "$jitter" == "true" ]] && echo "--jitter" || echo "--no-jitter") \
        -- "${cmd[@]}"
      return $?
      ;;
    default | *)
      retry_with_backoff -- "${cmd[@]}"
      return $?
      ;;
  esac
}

#######################################
# Retry Statistics
#######################################

# Track retry statistics
# Use -g flag to ensure global scope when sourced
declare -gA RETRY_STATS=() 2>/dev/null || declare -A RETRY_STATS=()

# Record retry attempt
# Usage: record_retry_attempt <operation> <success>
record_retry_attempt() {
  local operation="$1"
  local success="$2"

  local key="${operation}_total"
  local current_val="${RETRY_STATS[$key]:-0}"
  RETRY_STATS["$key"]=$((current_val + 1))

  if [[ "$success" == "true" ]]; then
    local success_key="${operation}_success"
    local success_val="${RETRY_STATS[$success_key]:-0}"
    RETRY_STATS["$success_key"]=$((success_val + 1))
  else
    local fail_key="${operation}_failed"
    local fail_val="${RETRY_STATS[$fail_key]:-0}"
    RETRY_STATS["$fail_key"]=$((fail_val + 1))
  fi
}

# Get retry statistics
# Usage: get_retry_stats [operation]
get_retry_stats() {
  local operation="${1:-}"

  if [[ -n "$operation" ]]; then
    local total="${RETRY_STATS[${operation}_total]:-0}"
    local success="${RETRY_STATS[${operation}_success]:-0}"
    local failed="${RETRY_STATS[${operation}_failed]:-0}"
    echo "operation=$operation total=$total success=$success failed=$failed"
  else
    local key
    for key in "${!RETRY_STATS[@]}"; do
      echo "$key=${RETRY_STATS[$key]}"
    done
  fi
}

# Reset retry statistics
# Usage: reset_retry_stats
reset_retry_stats() {
  RETRY_STATS=()
}

#######################################
# Retry with Error Handling
#######################################

# Execute with retry and proper error handling
# Usage: retry_with_error_handling <error_code> <command...>
retry_with_error_handling() {
  local error_code="$1"
  shift
  local cmd=("$@")

  local strategy
  strategy=$(get_retry_strategy "$error_code")

  if [[ "$strategy" == "none" ]]; then
    # Non-retryable error
    if ! "${cmd[@]}"; then
      print_error "$error_code"
      return 1
    fi
    return 0
  fi

  # Apply retry strategy
  if ! apply_retry_strategy "$strategy" "${cmd[@]}"; then
    print_error "E900" "attempts=$RETRY_MAX_ATTEMPTS" "operation=${cmd[*]}"
    return 1
  fi

  return 0
}

#######################################
# Initialization
#######################################

# Export functions for use in subshells
export -f calculate_delay calculate_next_delay sleep_with_progress
export -f retry_with_backoff retry_simple retry_until
export -f get_retry_strategy apply_retry_strategy
export -f record_retry_attempt get_retry_stats reset_retry_stats
export -f retry_with_error_handling
