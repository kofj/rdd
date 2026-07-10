#!/bin/bash
#
# RDD Audit Logging Script
# Records all significant operations for compliance and debugging
#
# Usage: audit.sh <command> [options]
#
# Commands:
#   log <operation> [details]   - Log an audit event
#   query [filter]              - Query audit logs
#   export [format] [output]    - Export audit logs
#   rotate                      - Rotate log files
#   status                      - Show audit status
#
# Can also be sourced to use log_audit function:
#   source audit.sh
#   log_audit "OPERATION" "key=value key2=value2"
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AUDIT_CONFIG="${RDD_DIR}/audit.yml"
AUDIT_LOG_DIR="${RDD_DIR}/logs"
AUDIT_LOG="${AUDIT_LOG_DIR}/audit.log"
AUDIT_JSON="${AUDIT_LOG_DIR}/audit.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################
# Get a value from YAML config
# Arguments:
#   $1 - YAML path (e.g., "audit.enabled")
#   $2 - default value
# Returns: value or default
#######################################
get_audit_config() {
  local path="$1"
  local default="${2:-}"

  if [[ ! -f "$AUDIT_CONFIG" ]]; then
    echo "$default"
    return 0
  fi

  if command -v yq &>/dev/null; then
    local value
    value=$(yq eval ".${path}" "$AUDIT_CONFIG" 2>/dev/null)
    if [[ -n "$value" && "$value" != "null" ]]; then
      echo "$value"
    else
      echo "$default"
    fi
  else
    # Fallback: simple YAML parsing for basic key-value pairs
    # Converts "audit.enabled" to grep for "enabled:" under "audit:" section
    _parse_yaml_simple "$AUDIT_CONFIG" "$path" "$default"
  fi
}

#######################################
# Simple YAML parser (fallback when yq not available)
# Arguments:
#   $1 - YAML file path
#   $2 - YAML path (e.g., "audit.enabled")
#   $3 - default value
# Returns: value or default
#######################################
_parse_yaml_simple() {
  local yaml_file="$1"
  local path="$2"
  local default="$3"

  # Split path into parts (e.g., "audit.enabled" -> "audit" "enabled")
  local -a parts
  IFS='.' read -ra parts <<<"$path"

  local current_indent=0
  local target_indent=0
  local found_value="$default"
  local in_section=false
  local section_depth=0
  local matched_depth=0

  # For each part of the path, we need to track nesting
  # Simple approach: find the key at the right indentation level

  local search_key="${parts[-1]}"
  local parent_key=""
  if [[ ${#parts[@]} -gt 1 ]]; then
    parent_key="${parts[-2]}"
  fi

  # Read the file and find the value
  local line indent key value in_parent=false parent_indent=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue

    # Calculate indentation
    indent=$(echo "$line" | sed 's/[^ ].*//' | wc -c)
    ((indent--)) # wc -c includes newline or something, adjust

    # Extract key and value
    if [[ "$line" =~ ^([[:space:]]*)([^:]+):[[:space:]]*(.*) ]]; then
      key="${BASH_REMATCH[2]}"
      value="${BASH_REMATCH[3]}"

      # Remove quotes from value
      value="${value#\"}"
      value="${value%\"}"
      value="${value#\'}"
      value="${value%\'}"

      # Handle nested path like "audit.enabled"
      if [[ ${#parts[@]} -eq 1 ]]; then
        # Simple path like "version"
        if [[ "$key" == "$search_key" && $indent -eq 0 ]]; then
          if [[ -n "$value" ]]; then
            found_value="$value"
            break
          fi
        fi
      elif [[ ${#parts[@]} -eq 2 ]]; then
        # Two-level path like "audit.enabled"
        local top_key="${parts[0]}"
        local sub_key="${parts[1]}"

        if [[ $indent -eq 0 && "$key" == "$top_key" ]]; then
          in_parent=true
          parent_indent=$indent
        elif [[ "$in_parent" == true && $indent -gt $parent_indent ]]; then
          if [[ "$key" == "$sub_key" && -n "$value" ]]; then
            # Check we're at the right nesting level (direct child)
            local expected_indent=$((parent_indent + 2))
            if [[ $indent -eq $expected_indent || $indent -eq $((parent_indent + 4)) ]]; then
              found_value="$value"
              break
            fi
          fi
        elif [[ "$in_parent" == true && $indent -le $parent_indent ]]; then
          # Left the parent section
          in_parent=false
        fi
      else
        # Deeper nesting - use awk fallback
        local awk_path
        awk_path=$(echo "$path" | sed 's/\./\//g')
        found_value=$(awk -v path="$awk_path" '
                    BEGIN { depth=0; found=0 }
                    {
                        match($0, /^[[:space:]]*/)
                        indent = RLENGTH
                        gsub(/^[[:space:]]+/, "")

                        if ($0 ~ /^[^:]+:/) {
                            key = $0
                            sub(/:.*$/, "", key)
                            value = $0
                            sub(/^[^:]+:[[:space:]]*/, "", value)
                            gsub(/^["\x27]|["\x27]$/, "", value)

                            # Simple 2-level match
                            if (depth == 0 && key == "'"${parts[0]}"'") {
                                depth = 1
                                depth_indent[1] = indent
                                next
                            }
                            if (depth == 1 && indent > depth_indent[1] && key == "'"${parts[1]}"'") {
                                if (split_path == 2) {
                                    print value
                                    found = 1
                                    exit
                                }
                                depth = 2
                                depth_indent[2] = indent
                                next
                            }
                            if (depth == 2 && indent > depth_indent[2] && key == "'"$search_key"'") {
                                print value
                                found = 1
                                exit
                            }
                        }
                    }
                ' "$yaml_file" 2>/dev/null)

        if [[ -n "$found_value" && "$found_value" != "$default" ]]; then
          break
        fi
        found_value="$default"
        break
      fi
    fi
  done <"$yaml_file"

  echo "$found_value"
}

#######################################
# Create default audit configuration
#######################################
create_default_audit_config() {
  cat >"$AUDIT_CONFIG" <<'EOF'
# RDD Audit Configuration
version: "1.0.0"

# Audit settings
audit:
  enabled: true

  # What to audit
  events:
    # Security events (always audited)
    - category: SECURITY
      events:
        - PERMISSION_DENIED
        - AUTH_FAILURE
        - CONFIG_CHANGE
      level: INFO
      mandatory: true

    # Stage operations
    - category: STAGE
      events:
        - STAGE_START
        - STAGE_COMPLETE
        - STAGE_FAIL
        - STAGE_ROLLBACK
      level: INFO

    # Roadmap changes
    - category: ROADMAP
      events:
        - ROADMAP_CHANGE
        - STAGE_ADDED
        - STAGE_REMOVED
        - STAGE_REORDERED
      level: INFO

    # Tech debt operations
    - category: TECH_DEBT
      events:
        - DEBT_CREATED
        - DEBT_RESOLVED
        - DEBT_ESCALATED
      level: INFO

    # Hook executions
    - category: HOOK
      events:
        - HOOK_TRIGGERED
        - HOOK_SUCCESS
        - HOOK_FAILURE
      level: DEBUG

    # Notification events
    - category: NOTIFICATION
      events:
        - NOTIFICATION_SENT
        - NOTIFICATION_FAILED
      level: DEBUG

  # Storage configuration
  storage:
    # Log file settings
    file:
      enabled: true
      path: ".rdd/logs/audit.log"
      format: "text"
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 10
        compress: true

    # JSON log for machine processing
    json:
      enabled: true
      path: ".rdd/logs/audit.json"
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 30
        compress: true

  # Retention policy
  retention:
    days: 90
    archive:
      enabled: true
      path: ".rdd/logs/archive"
      compress: true

  # Sensitive data handling
  masking:
    enabled: true
    fields:
      - password
      - token
      - secret
      - api_key
      - credential
    pattern: "***MASKED***"
EOF
  chmod 600 "$AUDIT_CONFIG"
}

#######################################
# Initialize audit logging
#######################################
init_audit() {
  mkdir -p "$AUDIT_LOG_DIR"

  # Create default config if not exists
  if [[ ! -f "$AUDIT_CONFIG" ]]; then
    create_default_audit_config
  fi

  # Create log files if not exist
  if [[ ! -f "$AUDIT_LOG" ]]; then
    echo "# RDD Audit Log - Created $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >"$AUDIT_LOG"
    echo "# Format: [timestamp] [level] [category] who=<user> operation=<op> what=<what> result=<result>" >>"$AUDIT_LOG"
  fi

  if [[ ! -f "$AUDIT_JSON" ]]; then
    echo "[" >"$AUDIT_JSON"
    echo "]" >>"$AUDIT_JSON"
  fi
}

#######################################
# Mask sensitive data in a string
# Arguments:
#   $1 - string to mask
# Returns: masked string
#######################################
mask_sensitive_data() {
  local input="$1"

  local masking_enabled
  masking_enabled=$(get_audit_config "audit.masking.enabled" "true")

  if [[ "$masking_enabled" != "true" ]]; then
    echo "$input"
    return 0
  fi

  # Mask common sensitive patterns
  local result="$input"

  # Mask passwords
  result=$(echo "$result" | sed -E 's/password=[^ ]+/password=***MASKED***/g')
  result=$(echo "$result" | sed -E 's/pass=[^ ]+/pass=***MASKED***/g')

  # Mask tokens
  result=$(echo "$result" | sed -E 's/token=[^ ]+/token=***MASKED***/g')
  result=$(echo "$result" | sed -E 's/api_key=[^ ]+/api_key=***MASKED***/g')
  result=$(echo "$result" | sed -E 's/secret=[^ ]+/secret=***MASKED***/g')

  # Mask URLs with credentials
  result=$(echo "$result" | sed -E 's|(https?://)([^:]+):([^@]+)@|\1***:***@|g')

  echo "$result"
}

#######################################
# Check if an event should be logged
# Arguments:
#   $1 - operation
# Returns: 0 if should log, 1 if not
#######################################
should_log_event() {
  local operation="$1"

  # Check if audit is enabled
  local audit_enabled
  audit_enabled=$(get_audit_config "audit.enabled" "true")

  if [[ "$audit_enabled" != "true" ]]; then
    return 1
  fi

  # Security events are always logged
  case "$operation" in
    PERMISSION_DENIED | AUTH_FAILURE | CONFIG_CHANGE | SECURITY_*)
      return 0
      ;;
  esac

  return 0
}

#######################################
# Get current timestamp in ISO 8601 format
#######################################
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

#######################################
# Get session ID
#######################################
get_session_id() {
  echo "${RDD_SESSION_ID:-sess-$$}"
}

#######################################
# Log audit event (main function)
# Arguments:
#   $1 - operation (e.g., STAGE_START, PERMISSION_DENIED)
#   $2... - additional details as key=value pairs
#######################################
log_audit() {
  local operation="$1"
  shift
  local details="$*"

  # Check if we should log this event
  if ! should_log_event "$operation"; then
    return 0
  fi

  init_audit

  local timestamp user session_id result category

  timestamp=$(get_timestamp)
  user="${RDD_USER:-${USER:-unknown}}"
  session_id=$(get_session_id)

  # Extract result from details if present
  result="success"
  if [[ "$details" == *"result="* ]]; then
    result=$(echo "$details" | grep -oE 'result=[^ ]+' | cut -d= -f2)
  fi

  # Mask sensitive data
  details=$(mask_sensitive_data "$details")

  # Determine category
  case "$operation" in
    PERMISSION_DENIED | AUTH_FAILURE | CONFIG_CHANGE | SECURITY_*)
      category="SECURITY"
      ;;
    STAGE_*)
      category="STAGE"
      ;;
    ROADMAP_* | STAGE_ADDED | STAGE_REMOVED | STAGE_REORDERED)
      category="ROADMAP"
      ;;
    DEBT_*)
      category="TECH_DEBT"
      ;;
    HOOK_*)
      category="HOOK"
      ;;
    NOTIFICATION_*)
      category="NOTIFICATION"
      ;;
    *)
      category="GENERAL"
      ;;
  esac

  # Log to text file
  local log_line
  log_line="[${timestamp}] [INFO] [${category}] who=${user} operation=${operation} ${details}"
  echo "$log_line" >>"$AUDIT_LOG"

  # Log to JSON file
  log_to_json "$timestamp" "$category" "$operation" "$user" "$result" "$details" "$session_id"

  # Check for log rotation
  check_log_rotation
}

#######################################
# Log to JSON file
#######################################
log_to_json() {
  local timestamp="$1"
  local category="$2"
  local operation="$3"
  local user="$4"
  local result="$5"
  local details="$6"
  local session_id="$7"

  # Escape details for JSON
  local escaped_details
  escaped_details=$(echo "$details" | sed 's/\\/\\\\/g; s/"/\\"/g')

  local json_entry
  json_entry=$(
    cat <<EOF
{
  "timestamp": "${timestamp}",
  "level": "INFO",
  "category": "${category}",
  "event": {
    "who": "${user}",
    "operation": "${operation}",
    "when": "${timestamp}",
    "result": "${result}",
    "details": "${escaped_details}"
  },
  "context": {
    "session_id": "${session_id}",
    "source": "rdd"
  }
}
EOF
  )

  # Append to JSON log file
  # Check if file is empty or just has []
  if [[ ! -s "$AUDIT_JSON" ]] || [[ $(wc -l <"$AUDIT_JSON") -le 2 ]]; then
    # Start fresh
    echo "[" >"$AUDIT_JSON"
    echo "  $json_entry" >>"$AUDIT_JSON"
    echo "]" >>"$AUDIT_JSON"
  else
    # Remove trailing ], add new entry, add ] back
    local tmp_file="${AUDIT_JSON}.tmp"
    head -n -1 "$AUDIT_JSON" >"$tmp_file"
    echo "  ,$json_entry" >>"$tmp_file"
    echo "]" >>"$tmp_file"
    mv "$tmp_file" "$AUDIT_JSON"
  fi
}

#######################################
# Log security event (convenience function)
# Arguments:
#   $1 - event type
#   $2 - user (optional)
#   $3 - details (optional)
#######################################
log_security_event() {
  local event_type="$1"
  local user="${2:-${RDD_USER:-${USER:-unknown}}}"
  local details="${3:-}"

  log_audit "$event_type" "who=$user $details"
}

#######################################
# Log stage event (convenience function)
#######################################
log_stage_event() {
  local event_type="$1"
  local stage="${2:-unknown}"
  shift 2
  local details="$*"

  log_audit "$event_type" "stage=$stage $details"
}

#######################################
# Get file size in bytes
#######################################
get_file_size() {
  local file="$1"
  if [[ -f "$file" ]]; then
    stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

#######################################
# Check and rotate logs
#######################################
check_log_rotation() {
  local max_size_mb=10
  local max_files=10

  # Get rotation settings from config
  local rotation_enabled
  rotation_enabled=$(get_audit_config "audit.storage.file.rotation.enabled" "true")

  if [[ "$rotation_enabled" != "true" ]]; then
    return 0
  fi

  # Check text log
  local log_size
  log_size=$(get_file_size "$AUDIT_LOG")
  local max_size_bytes=$((max_size_mb * 1024 * 1024))

  if [[ "$log_size" -gt "$max_size_bytes" ]]; then
    rotate_log "$AUDIT_LOG" "$max_files"
  fi

  # Check JSON log
  log_size=$(get_file_size "$AUDIT_JSON")
  if [[ "$log_size" -gt "$max_size_bytes" ]]; then
    rotate_log "$AUDIT_JSON" "$max_files"
  fi
}

#######################################
# Rotate log file
# Arguments:
#   $1 - log file path
#   $2 - max files to keep
#######################################
rotate_log() {
  local log_file="$1"
  local max_files="$2"

  if [[ ! -f "$log_file" ]]; then
    return 0
  fi

  # Remove oldest file
  if [[ -f "${log_file}.${max_files}.gz" ]]; then
    rm -f "${log_file}.${max_files}.gz"
  fi

  # Rotate existing files
  for ((i = max_files - 1; i >= 1; i--)); do
    if [[ -f "${log_file}.${i}.gz" ]]; then
      mv "${log_file}.${i}.gz" "${log_file}.$((i + 1)).gz"
    fi
  done

  # Compress and rotate current log
  if command -v gzip &>/dev/null; then
    gzip -c "$log_file" >"${log_file}.1.gz"
  else
    cp "$log_file" "${log_file}.1"
  fi

  # Create new empty log
  if [[ "$log_file" == *".json" ]]; then
    echo "[" >"$log_file"
    echo "]" >>"$log_file"
  else
    echo "# RDD Audit Log - Rotated $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >"$log_file"
  fi
}

#######################################
# Query audit logs
# Arguments:
#   $1 - filter pattern (optional)
#   $2 - start date (optional)
#   $3 - end date (optional)
#######################################
query_audit() {
  local filter="${1:-}"
  local start_date="${2:-}"
  local end_date="${3:-}"

  if [[ ! -f "$AUDIT_LOG" ]]; then
    echo "No audit log found" >&2
    return 1
  fi

  local result
  result=$(cat "$AUDIT_LOG")

  # Filter by pattern
  if [[ -n "$filter" ]]; then
    result=$(echo "$result" | grep -E "$filter")
  fi

  # Filter by date range
  if [[ -n "$start_date" ]]; then
    result=$(echo "$result" | awk -v start="$start_date" '$1 >= start')
  fi

  if [[ -n "$end_date" ]]; then
    result=$(echo "$result" | awk -v end="$end_date" '$1 <= end')
  fi

  echo "$result"
}

#######################################
# Query JSON audit logs
# Arguments:
#   $1 - jq filter (optional)
#######################################
query_audit_json() {
  local filter="${1:-.}"

  if [[ ! -f "$AUDIT_JSON" ]]; then
    echo "No JSON audit log found" >&2
    return 1
  fi

  if command -v jq &>/dev/null; then
    jq "$filter" "$AUDIT_JSON"
  else
    cat "$AUDIT_JSON"
  fi
}

#######################################
# Export audit logs
# Arguments:
#   $1 - format (json, csv, text)
#   $2 - output file (optional)
#######################################
export_audit() {
  local format="${1:-json}"
  local output="${2:-audit-export.$format}"

  case "$format" in
    json)
      if [[ -f "$AUDIT_JSON" ]]; then
        cp "$AUDIT_JSON" "$output"
        echo "Audit exported to $output (JSON format)"
      else
        echo "No JSON audit log found" >&2
        return 1
      fi
      ;;
    csv)
      if command -v jq &>/dev/null && [[ -f "$AUDIT_JSON" ]]; then
        echo "timestamp,level,category,who,operation,result" >"$output"
        jq -r '.[] | [.timestamp, .level, .category, .event.who, .event.operation, .event.result] | @csv' "$AUDIT_JSON" >>"$output"
        echo "Audit exported to $output (CSV format)"
      else
        echo "jq required for CSV export" >&2
        return 1
      fi
      ;;
    text)
      if [[ -f "$AUDIT_LOG" ]]; then
        cp "$AUDIT_LOG" "$output"
        echo "Audit exported to $output (text format)"
      else
        echo "No text audit log found" >&2
        return 1
      fi
      ;;
    *)
      echo "Unknown format: $format. Use json, csv, or text." >&2
      return 1
      ;;
  esac
}

#######################################
# Show audit status
#######################################
show_audit_status() {
  echo "=== RDD Audit Status ==="
  echo ""

  # Check if audit is enabled
  local enabled
  enabled=$(get_audit_config "audit.enabled" "true")
  echo "Audit enabled: $enabled"

  # Check log files
  echo ""
  echo "Log files:"

  if [[ -f "$AUDIT_LOG" ]]; then
    local size lines
    size=$(get_file_size "$AUDIT_LOG")
    lines=$(wc -l <"$AUDIT_LOG" | tr -d ' ')
    echo "  Text log: $AUDIT_LOG"
    echo "    Size: $size bytes"
    echo "    Lines: $lines"
  else
    echo "  Text log: Not found"
  fi

  if [[ -f "$AUDIT_JSON" ]]; then
    local size entries
    size=$(get_file_size "$AUDIT_JSON")
    entries=$(wc -l <"$AUDIT_JSON" | tr -d ' ')
    echo "  JSON log: $AUDIT_JSON"
    echo "    Size: $size bytes"
    echo "    Lines: $entries"
  else
    echo "  JSON log: Not found"
  fi

  # Show recent entries
  echo ""
  echo "Recent entries (last 5):"
  if [[ -f "$AUDIT_LOG" ]]; then
    tail -5 "$AUDIT_LOG" | sed 's/^/  /'
  fi

  # Check rotation
  echo ""
  local rotation_enabled
  rotation_enabled=$(get_audit_config "audit.storage.file.rotation.enabled" "true")
  echo "Rotation enabled: $rotation_enabled"

  # Retention
  local retention_days
  retention_days=$(get_audit_config "audit.retention.days" "90")
  echo "Retention period: $retention_days days"
}

#######################################
# Clean old logs
# Arguments:
#   $1 - days to keep (optional, default from config)
#######################################
clean_old_logs() {
  local days="${1:-}"
  if [[ -z "$days" ]]; then
    days=$(get_audit_config "audit.retention.days" "90")
  fi

  local archive_dir="${AUDIT_LOG_DIR}/archive"
  mkdir -p "$archive_dir"

  # Find and archive logs older than retention period
  local count=0

  # Archive rotated logs
  for log_file in "$AUDIT_LOG".* "$AUDIT_JSON".*; do
    if [[ -f "$log_file" ]]; then
      # Check file age
      local file_age_days
      file_age_days=$((($(date +%s) - $(stat -c%Y "$log_file" 2>/dev/null || stat -f%m "$log_file" 2>/dev/null)) / 86400))

      if [[ $file_age_days -gt $days ]]; then
        mv "$log_file" "$archive_dir/"
        ((count++))
      fi
    fi
  done

  echo "Archived $count old log files to $archive_dir"
}

#######################################
# Show usage
#######################################
show_usage() {
  cat <<'EOF'
RDD Audit Logging

Usage: audit.sh <command> [options]

Commands:
  log <operation> [details]   Log an audit event
                              Example: audit.sh log STAGE_START "stage=1 project=myproject"

  query [filter]              Query audit logs
                              Example: audit.sh query "PERMISSION_DENIED"
                              Example: audit.sh query "stage=1" "2024-01-01" "2024-12-31"

  query-json [jq_filter]      Query JSON audit logs with jq
                              Example: audit.sh query-json '.[] | select(.event.operation=="STAGE_START")'

  export [format] [output]    Export audit logs
                              Formats: json, csv, text
                              Example: audit.sh export csv audit.csv

  rotate                      Manually rotate log files

  clean [days]                Clean logs older than specified days

  status                      Show audit status

Environment Variables:
  RDD_DIR          RDD configuration directory
  RDD_USER         Current user for audit logging
  RDD_SESSION_ID   Session ID for correlation

Examples:
  # Log a stage event
  audit.sh log STAGE_START "stage=2 project=myproject"

  # Log a security event
  audit.sh log PERMISSION_DENIED "user=guest operation=rdd:config:write"

  # Query recent security events
  audit.sh query "SECURITY"

  # Export to CSV
  audit.sh export csv /tmp/audit-report.csv

EOF
}

#######################################
# Main entry point
#######################################
main() {
  if [[ $# -lt 1 ]]; then
    show_usage
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    log)
      if [[ $# -lt 1 ]]; then
        echo "Error: operation required" >&2
        echo "Usage: audit.sh log <operation> [details]" >&2
        exit 1
      fi
      log_audit "$@"
      ;;
    query)
      query_audit "$@"
      ;;
    query-json)
      query_audit_json "$@"
      ;;
    export)
      export_audit "$@"
      ;;
    rotate)
      check_log_rotation
      echo "Log rotation completed"
      ;;
    clean)
      clean_old_logs "$@"
      ;;
    status)
      show_audit_status
      ;;
    -h | --help | help)
      show_usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      show_usage
      exit 1
      ;;
  esac
}

# Only run main if script is executed directly (not sourced)
# When sourced for tests, BASH_SOURCE has multiple elements
if [[ "${#BASH_SOURCE[@]}" -gt 1 ]] || [[ "${BASH_SOURCE[0]:-$0}" != "${0}" ]]; then
  # Sourced, don't run main
  :
elif [[ $# -gt 0 ]]; then
  # Executed with arguments
  main "$@"
fi

# Export functions for use in other scripts
export -f log_audit log_security_event log_stage_event
export -f query_audit query_audit_json export_audit
export -f show_audit_status check_log_rotation clean_old_logs
export -f init_audit mask_sensitive_data get_audit_config
