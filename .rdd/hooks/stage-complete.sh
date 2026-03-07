#!/bin/bash
#
# RDD Hook: stage-complete
# Triggered when a stage is successfully completed
#
# This hook is called after Gate 5 verification passes.
#
# Environment variables provided:
#   RDD_STAGE_NUMBER   - The completed stage number
#   RDD_STAGE_NAME     - The stage name/title
#   RDD_STAGE_DURATION - Time taken to complete the stage
#   RDD_COVERAGE       - Test coverage percentage
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
    source "${SCRIPTS_DIR}/notify.sh"
fi

log_info "Stage complete hook triggered"
log_info "Stage: ${RDD_STAGE_NUMBER:-unknown} - ${RDD_STAGE_NAME:-unknown}"
log_info "Duration: ${RDD_STAGE_DURATION:-unknown}"
log_info "Coverage: ${RDD_COVERAGE:-unknown}%"

# Send notification
send_notification "stage_complete" \
    "project_name=${RDD_PROJECT_NAME:-Unknown}" \
    "stage_name=${RDD_STAGE_NAME:-Stage ${RDD_STAGE_NUMBER:-unknown}}" \
    "duration=${RDD_STAGE_DURATION:-unknown}" \
    "coverage=${RDD_COVERAGE:-0}"

# Update next steps document
NEXT_STEPS="${RDD_DIR}/../docs/11-next-steps.md"
if [[ -f "$NEXT_STEPS" ]]; then
    log_info "Updating next-steps.md with stage completion"
    # Add progress log entry
    echo "" >> "$NEXT_STEPS"
    echo "### $(date '+%Y-%m-%d %H:%M')" >> "$NEXT_STEPS"
    echo "- **Stage**: ${RDD_STAGE_NUMBER:-unknown}" >> "$NEXT_STEPS"
    echo "- **Action**: Stage completed" >> "$NEXT_STEPS"
    echo "- **Status**: Success" >> "$NEXT_STEPS"
    echo "- **Coverage**: ${RDD_COVERAGE:-unknown}%" >> "$NEXT_STEPS"
fi

log_info "Stage complete hook finished successfully"
