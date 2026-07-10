#!/bin/bash
#
# RDD Degradation Strategy
# Implements 5-level degradation strategy for graceful degradation
#
# Levels:
#   Level 0: Full Functionality - All features available
#   Level 1: Reduced Redundancy - Primary channels only
#   Level 2: Essential Only - Only critical notifications (P0/P1)
#   Level 3: Minimal Operation - Only P0 notifications, no retry
#   Level 4: Safe Mode - No external calls, local logging only
#
# Usage:
#   source "${RDD_DIR}/lib/degradation.sh"
#   set_degradation_level 2
#   if should_send_notification "P0"; then
#       send_notification...
#   fi

set -euo pipefail

# Ensure RDD_DIR is set
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source dependencies
source "${RDD_DIR}/lib/error_codes.sh"

#######################################
# Degradation Level Definitions
#######################################

export DEGRADATION_LEVEL_0="0" # Full Functionality
export DEGRADATION_LEVEL_1="1" # Reduced Redundancy
export DEGRADATION_LEVEL_2="2" # Essential Only
export DEGRADATION_LEVEL_3="3" # Minimal Operation
export DEGRADATION_LEVEL_4="4" # Safe Mode

export DEGRADATION_LEVEL_NAMES=(
  [0]="Full Functionality"
  [1]="Reduced Redundancy"
  [2]="Essential Only"
  [3]="Minimal Operation"
  [4]="Safe Mode"
)

#######################################
# Degradation Configuration
#######################################

# State file for persistence
DEGRADATION_STATE_FILE="${RDD_DIR}/cache/degradation_state.json"

# Auto-adjustment settings
DEGRADATION_AUTO_ADJUST="${DEGRADATION_AUTO_ADJUST:-false}"
DEGRADATION_FAILURE_THRESHOLD="${DEGRADATION_FAILURE_THRESHOLD:-10}"
DEGRADATION_RECOVERY_CHECK_INTERVAL="${DEGRADATION_RECOVERY_CHECK_INTERVAL:-300}"

# Current degradation level
CURRENT_DEGRADATION_LEVEL="${CURRENT_DEGRADATION_LEVEL:-0}"

#######################################
# Degradation Level Management
#######################################

# Initialize degradation state
init_degradation() {
  mkdir -p "${RDD_DIR}/cache"

  if [[ ! -f "$DEGRADATION_STATE_FILE" ]]; then
    echo '{
            "level": 0,
            "previous_level": 0,
            "last_change": 0,
            "reason": "initialized",
            "failure_count": 0,
            "recovery_attempts": 0
        }' >"$DEGRADATION_STATE_FILE"
  fi
}

# Read degradation state
read_degradation_state() {
  if [[ ! -f "$DEGRADATION_STATE_FILE" ]]; then
    init_degradation
  fi

  cat "$DEGRADATION_STATE_FILE"
}

# Write degradation state
write_degradation_state() {
  local state="$1"
  echo "$state" >"$DEGRADATION_STATE_FILE"
}

# Get current degradation level
# Usage: get_degradation_level
get_degradation_level() {
  local state
  state=$(read_degradation_state)
  echo "$state" | jq -r '.level'
}

# Get degradation level name
# Usage: get_degradation_level_name [level]
get_degradation_level_name() {
  local level="${1:-$(get_degradation_level)}"
  echo "${DEGRADATION_LEVEL_NAMES[$level]:-Unknown}"
}

# Set degradation level
# Usage: set_degradation_level <level> [reason]
set_degradation_level() {
  local new_level="$1"
  local reason="${2:-manual adjustment}"

  # Validate level
  if [[ ! "$new_level" =~ ^[0-4]$ ]]; then
    echo "Invalid degradation level: $new_level. Must be 0-4." >&2
    return 1
  fi

  local state
  state=$(read_degradation_state)
  local current_level
  current_level=$(echo "$state" | jq -r '.level')
  local now
  now=$(date +%s)

  # Update state
  local new_state
  new_state=$(echo "$state" | jq \
    --argjson level "$new_level" \
    --argjson prev "$current_level" \
    --arg now "$now" \
    --arg reason "$reason" \
    '.previous_level = $prev | .level = $level | .last_change = $now | .reason = $reason')

  write_degradation_state "$new_state"
  CURRENT_DEGRADATION_LEVEL=$new_level

  # Log the change
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    local old_name="${DEGRADATION_LEVEL_NAMES[$current_level]}"
    local new_name="${DEGRADATION_LEVEL_NAMES[$new_level]}"
    echo "[DEGRADATION] Level changed: $old_name -> $new_name (Reason: $reason)" >&2
  fi

  return 0
}

# Increase degradation level
# Usage: increase_degradation_level [reason]
increase_degradation_level() {
  local reason="${1:-escalation}"
  local current
  current=$(get_degradation_level)

  if [[ $current -lt 4 ]]; then
    set_degradation_level $((current + 1)) "$reason"
    return 0
  fi

  return 1
}

# Decrease degradation level
# Usage: decrease_degradation_level [reason]
decrease_degradation_level() {
  local reason="${1:-recovery}"
  local current
  current=$(get_degradation_level)

  if [[ $current -gt 0 ]]; then
    set_degradation_level $((current - 1)) "$reason"
    return 0
  fi

  return 1
}

# Reset to full functionality
# Usage: reset_degradation
reset_degradation() {
  set_degradation_level 0 "reset"
}

#######################################
# Degradation Behavior
#######################################

# Check if notifications should be sent at current level
# Usage: should_send_notification <priority>
# Priority: P0 (critical), P1 (high), P2 (normal), P3 (low)
should_send_notification() {
  local priority="$1"
  local level
  level=$(get_degradation_level)

  case "$level" in
    0) return 0 ;; # Full: all notifications
    1) return 0 ;; # Reduced: all notifications
    2)             # Essential: P0/P1 only
      [[ "$priority" == "P0" || "$priority" == "P1" ]]
      return $?
      ;;
    3) # Minimal: P0 only
      [[ "$priority" == "P0" ]]
      return $?
      ;;
    4) return 1 ;; # Safe: no notifications
  esac
}

# Check if retry should be attempted at current level
# Usage: should_retry
should_retry() {
  local level
  level=$(get_degradation_level)

  case "$level" in
    0 | 1) return 0 ;; # Full retry allowed
    2) return 0 ;;     # Standard retry
    3 | 4) return 1 ;; # No retry
  esac
}

# Check if channel is available at current level
# Usage: is_channel_available <channel>
is_channel_available() {
  local channel="$1"
  local level
  level=$(get_degradation_level)

  case "$level" in
    0) return 0 ;; # All channels
    1)             # Primary channels only
      # Primary channels: wecom, email
      [[ "$channel" == "wecom" || "$channel" == "email" ]]
      return $?
      ;;
    2) return 0 ;; # All available for essential
    3)             # Only most reliable
      [[ "$channel" == "email" ]]
      return $?
      ;;
    4) return 1 ;; # No channels
  esac
}

# Get maximum retry attempts for current level
# Usage: get_max_retry_attempts
get_max_retry_attempts() {
  local level
  level=$(get_degradation_level)

  case "$level" in
    0) echo 3 ;;
    1) echo 3 ;;
    2) echo 2 ;;
    3) echo 1 ;;
    4) echo 0 ;;
    *) echo 1 ;;
  esac
}

# Get logging level for current degradation
# Usage: get_log_level
get_log_level() {
  local level
  level=$(get_degradation_level)

  case "$level" in
    0) echo "DEBUG" ;;
    1) echo "INFO" ;;
    2) echo "WARN" ;;
    3) echo "ERROR" ;;
    4) echo "CRITICAL" ;;
    *) echo "INFO" ;;
  esac
}

# Check if external calls are allowed
# Usage: allows_external_calls
allows_external_calls() {
  local level
  level=$(get_degradation_level)
  [[ $level -lt 4 ]]
}

# Check if template fallback should be used
# Usage: use_fallback_template
use_fallback_template() {
  local level
  level=$(get_degradation_level)
  [[ $level -ge 2 ]]
}

#######################################
# Degradation Level Capabilities
#######################################

# Get capabilities for current level
# Usage: get_degradation_capabilities
get_degradation_capabilities() {
  local level
  level=$(get_degradation_level)

  case "$level" in
    0)
      cat <<EOF
{
    "level": 0,
    "name": "Full Functionality",
    "notifications": "all",
    "retry": true,
    "max_retries": 3,
    "channels": ["wecom", "email", "telegram", "bark", "webhook"],
    "logging": "DEBUG",
    "external_calls": true,
    "circuit_breaker": true
}
EOF
      ;;
    1)
      cat <<EOF
{
    "level": 1,
    "name": "Reduced Redundancy",
    "notifications": "all",
    "retry": true,
    "max_retries": 3,
    "channels": ["wecom", "email"],
    "logging": "INFO",
    "external_calls": true,
    "circuit_breaker": true
}
EOF
      ;;
    2)
      cat <<EOF
{
    "level": 2,
    "name": "Essential Only",
    "notifications": "P0,P1",
    "retry": true,
    "max_retries": 2,
    "channels": ["wecom", "email", "telegram", "bark", "webhook"],
    "logging": "WARN",
    "external_calls": true,
    "circuit_breaker": true
}
EOF
      ;;
    3)
      cat <<EOF
{
    "level": 3,
    "name": "Minimal Operation",
    "notifications": "P0",
    "retry": false,
    "max_retries": 1,
    "channels": ["email"],
    "logging": "ERROR",
    "external_calls": true,
    "circuit_breaker": false,
    "static_content": true
}
EOF
      ;;
    4)
      cat <<EOF
{
    "level": 4,
    "name": "Safe Mode",
    "notifications": "none",
    "retry": false,
    "max_retries": 0,
    "channels": [],
    "logging": "CRITICAL",
    "external_calls": false,
    "circuit_breaker": false,
    "state_preservation": true
}
EOF
      ;;
  esac
}

#######################################
# Failure Tracking and Auto-Adjustment
#######################################

# Record a failure for auto-adjustment
# Usage: record_degradation_failure
record_degradation_failure() {
  local state
  state=$(read_degradation_state)
  local failure_count
  failure_count=$(echo "$state" | jq -r '.failure_count')
  failure_count=$((failure_count + 1))

  local new_state
  new_state=$(echo "$state" | jq --argjson count "$failure_count" '.failure_count = $count')
  write_degradation_state "$new_state"

  # Check if we should auto-escalate
  if [[ "$DEGRADATION_AUTO_ADJUST" == "true" ]]; then
    if [[ $failure_count -ge $DEGRADATION_FAILURE_THRESHOLD ]]; then
      local current_level
      current_level=$(get_degradation_level)

      if [[ $current_level -lt 4 ]]; then
        increase_degradation_level "auto-escalation: $failure_count failures"
        print_error "E800" "old_level=$current_level" "new_level=$((current_level + 1))"
      fi
    fi
  fi
}

# Record a success (resets failure count)
# Usage: record_degradation_success
record_degradation_success() {
  local state
  state=$(read_degradation_state)
  local new_state
  new_state=$(echo "$state" | jq '.failure_count = 0 | .recovery_attempts = 0')
  write_degradation_state "$new_state"
}

# Check for recovery opportunity
# Usage: check_degradation_recovery
check_degradation_recovery() {
  local state
  state=$(read_degradation_state)

  local current_level
  current_level=$(get_degradation_level)

  # Can't recover from level 0
  if [[ $current_level -eq 0 ]]; then
    return 0
  fi

  local last_change
  last_change=$(echo "$state" | jq -r '.last_change')
  local now
  now=$(date +%s)
  local elapsed=$((now - last_change))

  # Check if enough time has passed for recovery
  if [[ $elapsed -ge $DEGRADATION_RECOVERY_CHECK_INTERVAL ]]; then
    local recovery_attempts
    recovery_attempts=$(echo "$state" | jq -r '.recovery_attempts')
    recovery_attempts=$((recovery_attempts + 1))

    local new_state
    new_state=$(echo "$state" | jq --argjson attempts "$recovery_attempts" '.recovery_attempts = $attempts')
    write_degradation_state "$new_state"

    # Attempt recovery
    if decrease_degradation_level "recovery attempt $recovery_attempts"; then
      print_error "E802" "level=$current_level"
      return 0
    fi
  fi

  return 1
}

#######################################
# Degradation Metrics
#######################################

# Export degradation metrics for Prometheus
# Usage: export_degradation_metrics
export_degradation_metrics() {
  local level
  level=$(get_degradation_level)
  local state
  state=$(read_degradation_state)

  echo "# HELP rdd_degradation_level Current degradation level (0-4)"
  echo "# TYPE rdd_degradation_level gauge"
  echo "rdd_degradation_level ${level}"

  echo ""
  echo "# HELP rdd_degradation_failure_count Failure count for auto-adjustment"
  echo "# TYPE rdd_degradation_failure_count gauge"
  local failure_count
  failure_count=$(echo "$state" | jq -r '.failure_count')
  echo "rdd_degradation_failure_count ${failure_count}"

  echo ""
  echo "# HELP rdd_degradation_last_change Timestamp of last level change"
  echo "# TYPE rdd_degradation_last_change gauge"
  local last_change
  last_change=$(echo "$state" | jq -r '.last_change')
  echo "rdd_degradation_last_change ${last_change}"
}

#######################################
# Degradation Fallback Templates
#######################################

# Get fallback notification content
# Usage: get_fallback_content <trigger_type> <priority>
get_fallback_content() {
  local trigger_type="$1"
  local priority="${2:-P2}"

  cat <<EOF
## [${priority}] RDD Notification

**Trigger**: ${trigger_type}
**Timestamp**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Degradation Mode**: $(get_degradation_level_name)

This notification was sent in degradation mode with minimal formatting.
Please check the application logs for more details.
EOF
}

# Get static fallback message for safe mode
# Usage: get_safe_mode_message
get_safe_mode_message() {
  cat <<EOF
[RDD SAFE MODE]
System is operating in safe mode.
All external calls are disabled.
Check local logs for details.
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

#######################################
# Initialization
#######################################

# Initialize on source
init_degradation

# Export functions
export -f init_degradation read_degradation_state write_degradation_state
export -f get_degradation_level get_degradation_level_name set_degradation_level
export -f increase_degradation_level decrease_degradation_level reset_degradation
export -f should_send_notification should_retry is_channel_available
export -f get_max_retry_attempts get_log_level allows_external_calls use_fallback_template
export -f get_degradation_capabilities
export -f record_degradation_failure record_degradation_success check_degradation_recovery
export -f export_degradation_metrics get_fallback_content get_safe_mode_message
