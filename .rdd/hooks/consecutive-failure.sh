#!/bin/bash
#
# RDD Hook: consecutive-failure
# Triggered when multiple consecutive failures occur
#
# This hook is called when:
# - A test fails 3+ times in a row
# - A gate check fails 2+ times in a row
# - An implementation approach fails 2+ times
#
# Environment variables provided:
#   RDD_STAGE_NUMBER   - Current stage number
#   RDD_STAGE_NAME     - Current stage name
#   RDD_FAILURE_COUNT  - Number of consecutive failures
#   RDD_LAST_ERROR     - Description of the last error
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
  source "${SCRIPTS_DIR}/notify.sh"
fi

log_warn "Consecutive failure hook triggered"
log_warn "Failure count: ${RDD_FAILURE_COUNT:-0}"
log_warn "Stage: ${RDD_STAGE_NUMBER:-unknown} - ${RDD_STAGE_NAME:-unknown}"
log_warn "Last error: ${RDD_LAST_ERROR:-unknown}"

# This is a critical notification - may block agent progress
send_notification "consecutive_failure" \
  "project_name=${RDD_PROJECT_NAME:-Unknown}" \
  "stage_name=${RDD_STAGE_NAME:-Stage ${RDD_STAGE_NUMBER:-unknown}}" \
  "failure_count=${RDD_FAILURE_COUNT:-0}" \
  "last_error=${RDD_LAST_ERROR:-Unknown error}" \
  "timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Generate handoff document since agent may need to stop
HANDOFF_DIR="${RDD_DIR}/../docs/handoff"
mkdir -p "$HANDOFF_DIR"

# Archive previous handoff if exists
if [[ -f "${HANDOFF_DIR}/handoff-latest.md" ]]; then
  TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
  mv "${HANDOFF_DIR}/handoff-latest.md" "${HANDOFF_DIR}/handoff-${TIMESTAMP}.md"
fi

# Create handoff document
cat >"${HANDOFF_DIR}/handoff-latest.md" <<EOF
# Agent Handoff Document

Generated: $(date '+%Y-%m-%d %H:%M')
Reason: Consecutive failures (${RDD_FAILURE_COUNT:-0} failures)
Current Stage: ${RDD_STAGE_NUMBER:-unknown}

---

## Current Progress

**Phase**: In Progress
**Progress Percentage**: Unknown
**Current Gate**: Unknown

### Blockers

1. **Consecutive Failures**
   - **Failure Count**: ${RDD_FAILURE_COUNT:-0}
   - **Last Error**: ${RDD_LAST_ERROR:-Unknown}
   - **Impact**: Agent cannot proceed
   - **Priority**: P0

---

## Next Single Action

**Immediate Next Step**: Investigate the failure and determine root cause

**How to Execute**:
1. Review the last error: ${RDD_LAST_ERROR:-Unknown}
2. Check recent changes in the stage
3. Consider alternative approaches
4. If blocked, escalate to human

**Expected Outcome**: Root cause identified and resolved

---

## Degradation Strategy

This hook was triggered because the agent has failed multiple times.
The human should:
1. Review the error details
2. Determine if the approach is correct
3. Provide guidance or take over

EOF

log_info "Handoff document created at ${HANDOFF_DIR}/handoff-latest.md"
log_info "Consecutive failure hook finished"
