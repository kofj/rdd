#!/bin/bash
#
# RDD Hook: daily-report
# Generates and sends a daily progress report
#
# This hook is called:
# - On a scheduled basis (typically daily at 09:00)
# - Manually via `rdd-knowledge context` or similar
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

log_info "Daily report hook triggered"

# Gather project status
ROADMAP="${RDD_DIR}/../docs/stages/stage-roadmap.md"
NEXT_STEPS="${RDD_DIR}/../docs/11-next-steps.md"
TECH_DEBT="${RDD_DIR}/../docs/12-technical-debt.md"

# Extract current stage
CURRENT_STAGE="unknown"
if [[ -f "$ROADMAP" ]]; then
    CURRENT_STAGE=$(grep -E "Current Stage:" "$ROADMAP" | head -1 | sed 's/.*Current Stage: *//' || echo "unknown")
fi

# Extract progress
PROGRESS="unknown"
if [[ -f "$ROADMAP" ]]; then
    PROGRESS=$(grep -E "Overall Progress:" "$ROADMAP" | head -1 | sed 's/.*Overall Progress: *//' || echo "unknown")
fi

# Count completed tasks
COMPLETED_TASKS="0"
if [[ -f "$NEXT_STEPS" ]]; then
    COMPLETED_TASKS=$(grep -c "\[x\]" "$NEXT_STEPS" 2>/dev/null || echo "0")
fi

# Count in-progress tasks
IN_PROGRESS="0"
if [[ -f "$NEXT_STEPS" ]]; then
    IN_PROGRESS=$(grep -c "\[ \]" "$NEXT_STEPS" 2>/dev/null || echo "0")
fi

# Count tech debt
DEBT_COUNT="0"
if [[ -f "$TECH_DEBT" ]]; then
    DEBT_COUNT=$(grep -c "TD-" "$TECH_DEBT" 2>/dev/null || echo "0")
fi

# Send notification
send_notification "daily_report" \
    "project_name=${RDD_PROJECT_NAME:-Unknown}" \
    "date=$(date '+%Y-%m-%d')" \
    "completed_tasks=${COMPLETED_TASKS}" \
    "in_progress_tasks=${IN_PROGRESS}" \
    "tech_debt_count=${DEBT_COUNT}" \
    "current_stage=${CURRENT_STAGE}" \
    "progress=${PROGRESS}"

log_info "Daily report hook finished"
