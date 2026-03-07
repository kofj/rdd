#!/bin/bash
#
# RDD Notification Script
# Sends notifications via configured channels (WeChat, Email, Bark, Telegram, Webhook)
#
# Usage: notify.sh <trigger_type> [options]
#
# Trigger Types:
#   roadmap_change       - Roadmap updated by human
#   consecutive_failure  - Multiple failures detected
#   hypothesis_invalid   - Core hypothesis invalidated
#   model_disagreement   - Significant model disagreement
#   tech_debt_threshold  - Tech debt exceeds threshold
#   stage_complete       - Stage completed successfully
#   daily_report         - Daily progress report
#   weekly_report        - Weekly progress report
#

set -euo pipefail

# Configuration paths
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
CONFIG_FILE="${RDD_DIR}/hooks.yml"
TEMPLATES_FILE="${RDD_DIR}/templates.yml"
CACHE_DIR="${RDD_DIR}/cache"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Priority levels
P0="critical"   # Urgent - needs immediate attention
P1="high"       # Important - needs attention within hours
P2="normal"     # Informational - review when convenient
P3="low"        # Report - for records only

# Default values
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

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
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $*"
    fi
}

#######################################
# Configuration loading
#######################################

load_yaml_value() {
    local file="$1"
    local path="$2"
    local default="${3:-}"

    # Simple YAML value extraction (handles basic cases)
    # For complex YAML, consider using yq or python
    if command -v yq &> /dev/null; then
        yq eval ".${path}" "$file" 2>/dev/null || echo "$default"
    else
        # Fallback: use grep for simple key-value pairs
        local key="${path##*.}"
        grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed 's/[^:]*: *//' | tr -d '"' || echo "$default"
    fi
}

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    log_debug "Loading configuration from $CONFIG_FILE"
}

#######################################
# Environment variable expansion
#######################################

expand_env_vars() {
    # Expand ${VAR} and $VAR style environment variables in a string
    local str="$1"

    # Expand ${VAR} style
    while [[ "$str" =~ \$\{([a-zA-Z_][a-zA-Z0-9_]*)\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local var_value="${!var_name:-}"
        str="${str//\$\{${var_name}\}/${var_value}}"
    done

    # Expand $VAR style (only if not followed by {)
    while [[ "$str" =~ \$([a-zA-Z_][a-zA-Z0-9_]*) ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local var_value="${!var_name:-}"
        # Replace $VAR but not ${VAR}
        str="${str//\$${var_name}/\$${var_name}}"
        str="${str//\$${var_name}([^a-zA-Z0-9_])/noop}"
        str=$(echo "$str" | sed "s|\\\$$var_name|${var_value}|g")
    done

    echo "$str"
}

load_templates() {
    if [[ ! -f "$TEMPLATES_FILE" ]]; then
        log_error "Templates file not found: $TEMPLATES_FILE"
        return 1
    fi

    log_debug "Loading templates from $TEMPLATES_FILE"
}

#######################################
# Template rendering
#######################################

render_template() {
    local trigger_type="$1"
    shift
    local vars=("$@")

    local template
    if command -v yq &> /dev/null; then
        template=$(yq eval ".templates.${trigger_type}.body" "$TEMPLATES_FILE" 2>/dev/null)
    else
        # Fallback: grep the template section
        template="Template for ${trigger_type} - please configure ${TEMPLATES_FILE}"
    fi

    # Replace variables
    for var in "${vars[@]}"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        template="${template//\{\{${key}\}\}/${value}}"
    done

    echo "$template"
}

get_block_message() {
    local trigger_type="$1"

    if command -v yq &> /dev/null; then
        yq eval ".templates.${trigger_type}.block_message" "$TEMPLATES_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

get_title() {
    local trigger_type="$1"

    if command -v yq &> /dev/null; then
        yq eval ".templates.${trigger_type}.title" "$TEMPLATES_FILE" 2>/dev/null || echo "${trigger_type}"
    else
        echo "${trigger_type}"
    fi
}

#######################################
# Channel: WeChat (WeCom)
#######################################

send_wecom() {
    local webhook_url="$1"
    local title="$2"
    local message="$3"

    log_debug "Sending WeChat notification"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would send WeChat: $title"
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
    "msgtype": "markdown",
    "markdown": {
        "content": "## ${title}\n\n${message}"
    }
}
EOF
)

    local response
    response=$(curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>&1) || {
        log_error "Failed to send WeChat notification: $response"
        return 1
    }

    log_debug "WeChat response: $response"
    log_info "WeChat notification sent successfully"
}

#######################################
# Channel: Email
#######################################

send_email() {
    local smtp_host="$1"
    local smtp_port="$2"
    local smtp_user="$3"
    local smtp_pass="$4"
    local from="$5"
    local to="$6"
    local title="$7"
    local message="$8"

    log_debug "Sending email notification"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would send email: $title to $to"
        return 0
    fi

    # Check if sendmail or mail command is available
    if command -v sendmail &> /dev/null; then
        {
            echo "From: $from"
            echo "To: $to"
            echo "Subject: [RDD] $title"
            echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            echo "$message"
        } | sendmail -t || {
            log_error "Failed to send email via sendmail"
            return 1
        }
    elif command -v mail &> /dev/null; then
        echo "$message" | mail -s "[RDD] $title" -r "$from" "$to" || {
            log_error "Failed to send email via mail"
            return 1
        }
    else
        log_warn "No email command available (sendmail or mail)"
        return 1
    fi

    log_info "Email notification sent successfully"
}

#######################################
# Channel: Bark (iOS)
#######################################

send_bark() {
    local server_url="$1"
    local device_key="$2"
    local title="$3"
    local message="$4"

    log_debug "Sending Bark notification"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would send Bark: $title"
        return 0
    fi

    # Bark URL format: {server_url}/{device_key}/{title}/{body}
    local url="${server_url}/${device_key}/$(urlencode "$title")/$(urlencode "$message")"

    local response
    response=$(curl -s -X GET "$url" 2>&1) || {
        log_error "Failed to send Bark notification: $response"
        return 1
    }

    log_debug "Bark response: $response"
    log_info "Bark notification sent successfully"
}

#######################################
# Channel: Telegram
#######################################

send_telegram() {
    local bot_token="$1"
    local chat_id="$2"
    local title="$3"
    local message="$4"

    log_debug "Sending Telegram notification"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would send Telegram: $title"
        return 0
    fi

    local url="https://api.telegram.org/bot${bot_token}/sendMessage"
    local text="<b>${title}</b>\n\n${message}"

    local payload
    payload=$(cat <<EOF
{
    "chat_id": "${chat_id}",
    "text": "${text}",
    "parse_mode": "HTML"
}
EOF
)

    local response
    response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>&1) || {
        log_error "Failed to send Telegram notification: $response"
        return 1
    }

    log_debug "Telegram response: $response"
    log_info "Telegram notification sent successfully"
}

#######################################
# Channel: Webhook (Generic)
#######################################

send_webhook() {
    local url="$1"
    local method="$2"
    local headers="$3"
    local title="$4"
    local message="$5"

    log_debug "Sending Webhook notification to $url"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would send Webhook: $title"
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
    "title": "${title}",
    "message": "${message}",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)

    local curl_headers=()
    curl_headers+=(-H "Content-Type: application/json")

    # Parse additional headers
    if [[ -n "$headers" ]]; then
        # Expecting headers in format: "Key1:Value1,Key2:Value2"
        IFS=',' read -ra header_pairs <<< "$headers"
        for pair in "${header_pairs[@]}"; do
            curl_headers+=(-H "${pair}")
        done
    fi

    local response
    response=$(curl -s -X "$method" "$url" \
        "${curl_headers[@]}" \
        -d "$payload" 2>&1) || {
        log_error "Failed to send Webhook notification: $response"
        return 1
    }

    log_debug "Webhook response: $response"
    log_info "Webhook notification sent successfully"
}

#######################################
# URL encoding helper
#######################################

urlencode() {
    local string="$1"
    local length="${#string}"
    local encoded=""

    for (( i = 0; i < length; i++ )); do
        local c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-])
                encoded+="$c"
                ;;
            *)
                encoded+=$(printf '%%%02X' "'$c")
                ;;
        esac
    done

    echo "$encoded"
}

#######################################
# Quiet hours check
#######################################

is_quiet_hours() {
    local quiet_enabled
    quiet_enabled=$(load_yaml_value "$CONFIG_FILE" "notifications.quiet_hours.enabled" "false")

    if [[ "$quiet_enabled" != "true" ]]; then
        return 1
    fi

    local start_time
    local end_time
    local timezone

    start_time=$(load_yaml_value "$CONFIG_FILE" "notifications.quiet_hours.start" "22:00")
    end_time=$(load_yaml_value "$CONFIG_FILE" "notifications.quiet_hours.end" "08:00")
    timezone=$(load_yaml_value "$CONFIG_FILE" "notifications.quiet_hours.timezone" "Asia/Shanghai")

    local current_hour
    current_hour=$(TZ="$timezone" date +"%H%M")

    local start_num end_num
    start_num=$(echo "$start_time" | tr -d ':')
    end_num=$(echo "$end_time" | tr -d ':')

    # Handle overnight quiet hours (e.g., 22:00 - 08:00)
    if [[ $start_num -gt $end_num ]]; then
        if [[ $current_hour -ge $start_num ]] || [[ $current_hour -lt $end_num ]]; then
            return 0
        fi
    else
        if [[ $current_hour -ge $start_num ]] && [[ $current_hour -lt $end_num ]]; then
            return 0
        fi
    fi

    return 1
}

#######################################
# Retry with backoff
#######################################

send_with_retry() {
    local channel="$1"
    shift
    local args=("$@")

    local max_attempts
    local initial_delay
    local max_delay

    max_attempts=$(load_yaml_value "$CONFIG_FILE" "retry.max_attempts" "3")
    initial_delay=$(load_yaml_value "$CONFIG_FILE" "retry.initial_delay" "1s")
    max_delay=$(load_yaml_value "$CONFIG_FILE" "retry.max_delay" "30s")

    local attempt=1
    local delay="$initial_delay"

    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt/$max_attempts for $channel"

        if "send_${channel}" "${args[@]}"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Retry $attempt/$max_attempts failed for $channel, waiting ${delay}..."
            sleep "$delay"

            # Exponential backoff
            delay=$((delay * 2))
            if [[ $delay -gt $max_delay ]]; then
                delay=$max_delay
            fi
        fi

        ((attempt++))
    done

    log_error "All $max_attempts attempts failed for $channel"
    return 1
}

#######################################
# Main notification dispatcher
#######################################

send_notification() {
    local trigger_type="$1"
    shift
    local vars=("$@")

    log_info "Processing notification trigger: $trigger_type"

    # Load configuration
    load_config
    load_templates

    # Check quiet hours (bypass for P0)
    local bypass_quiet
    bypass_quiet=$(load_yaml_value "$CONFIG_FILE" "notifications.quiet_hours.bypass_for_p0" "true")

    if is_quiet_hours && [[ "$bypass_quiet" != "true" ]]; then
        log_info "Quiet hours active, skipping notification"
        return 0
    fi

    # Get trigger configuration
    local trigger_enabled
    trigger_enabled=$(load_yaml_value "$CONFIG_FILE" "triggers.${trigger_type}.enabled" "false")

    if [[ "$trigger_enabled" != "true" ]]; then
        log_info "Trigger $trigger_type is disabled"
        return 0
    fi

    # Render template
    local title message block_message
    title=$(get_title "$trigger_type")
    message=$(render_template "$trigger_type" "${vars[@]}")
    block_message=$(get_block_message "$trigger_type")

    log_debug "Title: $title"
    log_debug "Block Message: $block_message"

    # Get channels for this trigger
    local channels
    if command -v yq &> /dev/null; then
        channels=$(yq eval ".triggers.${trigger_type}.channels[]" "$CONFIG_FILE" 2>/dev/null | tr '\n' ' ')
    else
        channels="wecom"
    fi

    log_info "Sending to channels: $channels"

    local success=0
    local failed=0

    for channel in $channels; do
        log_debug "Processing channel: $channel"

        local channel_enabled
        channel_enabled=$(load_yaml_value "$CONFIG_FILE" "channels.${channel}.enabled" "false")

        if [[ "$channel_enabled" != "true" ]]; then
            log_debug "Channel $channel is disabled, skipping"
            continue
        fi

        case "$channel" in
            wecom)
                local webhook_url
                webhook_url=$(load_yaml_value "$CONFIG_FILE" "channels.wecom.webhook_url" "")
                if [[ -n "$webhook_url" ]]; then
                    if send_with_retry "wecom" "$webhook_url" "$title" "$message"; then
                        ((success++))
                    else
                        ((failed++))
                    fi
                fi
                ;;
            email)
                local smtp_host smtp_port smtp_user smtp_pass from to
                smtp_host=$(load_yaml_value "$CONFIG_FILE" "channels.email.smtp_host" "")
                smtp_port=$(load_yaml_value "$CONFIG_FILE" "channels.email.smtp_port" "587")
                smtp_user=$(load_yaml_value "$CONFIG_FILE" "channels.email.smtp_user" "")
                smtp_pass=$(load_yaml_value "$CONFIG_FILE" "channels.email.smtp_pass" "")
                from=$(load_yaml_value "$CONFIG_FILE" "channels.email.from_address" "")
                to=$(load_yaml_value "$CONFIG_FILE" "channels.email.to_addresses[]" "$CONFIG_FILE" | tr '\n' ',')

                if [[ -n "$smtp_host" && -n "$from" && -n "$to" ]]; then
                    if send_with_retry "email" "$smtp_host" "$smtp_port" "$smtp_user" "$smtp_pass" "$from" "$to" "$title" "$message"; then
                        ((success++))
                    else
                        ((failed++))
                    fi
                fi
                ;;
            bark)
                local server_url device_key
                server_url=$(load_yaml_value "$CONFIG_FILE" "channels.bark.server_url" "")
                device_key=$(load_yaml_value "$CONFIG_FILE" "channels.bark.device_key" "")

                if [[ -n "$server_url" && -n "$device_key" ]]; then
                    if send_with_retry "bark" "$server_url" "$device_key" "$title" "$message"; then
                        ((success++))
                    else
                        ((failed++))
                    fi
                fi
                ;;
            telegram)
                local bot_token chat_id
                bot_token=$(load_yaml_value "$CONFIG_FILE" "channels.telegram.bot_token" "")
                chat_id=$(load_yaml_value "$CONFIG_FILE" "channels.telegram.chat_id" "")

                if [[ -n "$bot_token" && -n "$chat_id" ]]; then
                    if send_with_retry "telegram" "$bot_token" "$chat_id" "$title" "$message"; then
                        ((success++))
                    else
                        ((failed++))
                    fi
                fi
                ;;
            webhook)
                local url method headers
                url=$(load_yaml_value "$CONFIG_FILE" "channels.webhook.url" "")
                method=$(load_yaml_value "$CONFIG_FILE" "channels.webhook.method" "POST")
                headers=$(load_yaml_value "$CONFIG_FILE" "channels.webhook.headers" "")

                if [[ -n "$url" ]]; then
                    if send_with_retry "webhook" "$url" "$method" "$headers" "$title" "$message"; then
                        ((success++))
                    else
                        ((failed++))
                    fi
                fi
                ;;
            *)
                log_warn "Unknown channel: $channel"
                ;;
        esac
    done

    log_info "Notification complete: $success succeeded, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi

    return 0
}

#######################################
# Show usage
#######################################

show_usage() {
    cat << EOF
RDD Notification Script

Usage: notify.sh <trigger_type> [variables...]

Trigger Types:
  roadmap_change       Roadmap updated by human
  consecutive_failure  Multiple failures detected
  hypothesis_invalid   Core hypothesis invalidated
  model_disagreement   Significant model disagreement
  tech_debt_threshold  Tech debt exceeds threshold
  stage_complete       Stage completed successfully
  daily_report         Daily progress report
  weekly_report        Weekly progress report

Variables:
  Variables are passed as key=value pairs and substituted in templates.
  Example: notify.sh stage_complete project_name=MyProject stage_name="Stage 1"

Environment Variables:
  RDD_DIR       RDD configuration directory (default: script parent)
  DRY_RUN       Set to 'true' to skip actual sending
  VERBOSE       Set to 'true' for debug output

Examples:
  # Notify stage completion
  notify.sh stage_complete project_name=MyProject stage_name="Stage 1" duration="2h" coverage=85

  # Notify consecutive failures
  notify.sh consecutive_failure project_name=MyProject stage_name="Stage 2" failure_count=3 last_error="Test failed"

  # Dry run for testing
  DRY_RUN=true notify.sh roadmap_change project_name=MyProject change_type="Stage added"

EOF
}

#######################################
# Main entry point
#######################################

main() {
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi

    local trigger_type="$1"
    shift
    local vars=("$@")

    case "$trigger_type" in
        roadmap_change|consecutive_failure|hypothesis_invalid|model_disagreement|tech_debt_threshold|stage_complete|daily_report|weekly_report)
            send_notification "$trigger_type" "${vars[@]}"
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown trigger type: $trigger_type"
            show_usage
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
# Using a function wrapper to prevent execution when sourced
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
