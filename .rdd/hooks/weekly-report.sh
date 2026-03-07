#!/bin/bash
#
# RDD Hook: weekly-report
# Generates and sends a weekly progress report
#
# This hook is called:
# - On a scheduled basis (typically Monday at 09:00)
# - Manually via command
#
# Environment variables provided:
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
    source "${SCRIPTS_DIR}/notify.sh"
fi

log_info "Weekly report hook triggered"

# Gather project status
ROADMAP="${RDD_DIR}/../docs/stages/stage-roadmap.md"
CHANGELOG="${RDD_DIR}/../CHANGELOG.md"

# Calculate week range
WEEK_START=$(date -d "last monday" '+%Y-%m-%d' 2>/dev/null || date -v-monw '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
WEEK_END=$(date '+%Y-%m-%d')

# Count stages finished this week
STAGES_FINISHED="0"
if [[ -f "$CHANGELOG" ]]; then
    # Count entries between week start and end
    STAGES_FINISHED=$(grep -c "## \[Stage" "$CHANGELOG" 2>/dev/null || echo "0")
fi

# Count tasks completed this week
TASKS_COMPLETED="0"
if [[ -f "$CHANGELOG" ]]; then
    TASKS_COMPLETED=$(grep -c "### Added" "$CHANGELOG" 2>/dev/null || echo "0")
fi

# Send notification
send_notification "weekly_report" \
    "project_name=${RDD_PROJECT_NAME:-Unknown}" \
    "week_range=${WEEK_START} to ${WEEK_END}" \
    "tasks_completed=${TASKS_COMPLETED}" \
    "stages_finished=${STAGES_FINISHED}"

log_info "Weekly report hook finished"
