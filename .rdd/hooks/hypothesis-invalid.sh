#!/bin/bash
#
# RDD Hook: hypothesis-invalid
# Triggered when a core hypothesis is invalidated during testing
#
# This hook is called when:
# - A test proves a hypothesis false
# - Real-world data contradicts assumptions
# - Integration reveals unexpected behavior
#
# Environment variables provided:
#   RDD_STAGE_NUMBER   - Current stage number
#   RDD_HYPOTHESIS     - The invalidated hypothesis
#   RDD_REASON         - Why it was invalidated
#   RDD_EVIDENCE       - Evidence that invalidated it
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
    source "${SCRIPTS_DIR}/notify.sh"
fi

log_warn "Hypothesis invalidation hook triggered"
log_warn "Stage: ${RDD_STAGE_NUMBER:-unknown}"
log_warn "Hypothesis: ${RDD_HYPOTHESIS:-unknown}"
log_warn "Reason: ${RDD_REASON:-unknown}"

# Hypothesis invalidation is high priority
send_notification "hypothesis_invalid" \
    "project_name=${RDD_PROJECT_NAME:-Unknown}" \
    "hypothesis_text=${RDD_HYPOTHESIS:-Unknown}" \
    "invalidation_reason=${RDD_REASON:-Unknown}" \
    "evidence=${RDD_EVIDENCE:-No evidence provided}" \
    "timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Record in ADR
ADR_FILE="${RDD_DIR}/../docs/08-autonomous-decisions.md"
if [[ -f "$ADR_FILE" ]]; then
    log_info "Recording hypothesis invalidation in ADR"

    cat >> "$ADR_FILE" << EOF

### Decision: Hypothesis Invalidated (Stage ${RDD_STAGE_NUMBER:-unknown})

**Background**: During Stage ${RDD_STAGE_NUMBER:-unknown}, testing revealed that a core hypothesis was invalid.

**Hypothesis**: ${RDD_HYPOTHESIS:-Unknown}

**Invalidation Reason**: ${RDD_REASON:-Unknown}

**Evidence**: ${RDD_EVIDENCE:-No evidence provided}

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: $(date '+%Y-%m-%d')
**Related Stage**: Stage ${RDD_STAGE_NUMBER:-unknown}

EOF
fi

# Update next steps
NEXT_STEPS="${RDD_DIR}/../docs/11-next-steps.md"
if [[ -f "$NEXT_STEPS" ]]; then
    log_info "Adding blocker to next-steps.md"
    echo "" >> "$NEXT_STEPS"
    echo "## Blocker" >> "$NEXT_STEPS"
    echo "" >> "$NEXT_STEPS"
    echo "A core hypothesis was invalidated. Human review required." >> "$NEXT_STEPS"
    echo "- **Hypothesis**: ${RDD_HYPOTHESIS:-unknown}" >> "$NEXT_STEPS"
    echo "- **Reason**: ${RDD_REASON:-unknown}" >> "$NEXT_STEPS"
fi

log_info "Hypothesis invalidation hook finished"
