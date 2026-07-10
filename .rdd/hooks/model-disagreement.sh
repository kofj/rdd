#!/bin/bash
#
# RDD Hook: model-disagreement
# Triggered when significant disagreement is detected between models
#
# This hook is called when:
# - Multi-model review produces conflicting findings
# - Models disagree on approach or implementation
# - Triangulation verification fails
#
# Environment variables provided:
#   RDD_MODELS         - Names of models that disagreed
#   RDD_CONTEXT        - Context of the disagreement
#   RDD_FINDING_A      - Finding from model A
#   RDD_FINDING_B      - Finding from model B
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
  source "${SCRIPTS_DIR}/notify.sh"
fi

log_info "Model disagreement hook triggered"
log_info "Models: ${RDD_MODELS:-unknown}"
log_info "Context: ${RDD_CONTEXT:-unknown}"

# Model disagreement is informational but important
send_notification "model_disagreement" \
  "project_name=${RDD_PROJECT_NAME:-Unknown}" \
  "model_names=${RDD_MODELS:-unknown}" \
  "context=${RDD_CONTEXT:-unknown}" \
  "timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Record in review log
REVIEW_LOG="${RDD_DIR}/../docs/stages/stage-${RDD_STAGE_NUMBER:-current}-review-log.md"
if [[ -f "$REVIEW_LOG" ]]; then
  log_info "Recording model disagreement in review log"

  cat >>"$REVIEW_LOG" <<EOF

## Model Disagreement (Automated Log)

**Time**: $(date '+%Y-%m-%d %H:%M')
**Models**: ${RDD_MODELS:-unknown}
**Context**: ${RDD_CONTEXT:-unknown}

### Finding A
${RDD_FINDING_A:-Not provided}

### Finding B
${RDD_FINDING_B:-Not provided}

### Resolution
- [ ] Needs human review
- [ ] Verify with authoritative source
- [ ] Check with third model

EOF
fi

log_info "Model disagreement hook finished"
