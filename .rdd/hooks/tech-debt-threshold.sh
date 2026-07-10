#!/bin/bash
#
# RDD Hook: tech-debt-threshold
# Triggered when technical debt exceeds configured threshold
#
# This hook is called when:
# - Number of active tech debt items exceeds threshold
# - A new high-priority debt item is added
# - Blocking debt prevents progress
#
# Environment variables provided:
#   RDD_DEBT_COUNT     - Current debt count
#   RDD_THRESHOLD      - Configured threshold
#   RDD_DEBT_PRIORITY  - Priority of new debt (if applicable)
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
  source "${SCRIPTS_DIR}/notify.sh"
fi

log_warn "Tech debt threshold hook triggered"
log_warn "Current debt count: ${RDD_DEBT_COUNT:-0}"
log_warn "Threshold: ${RDD_THRESHOLD:-0}"

# Tech debt exceeding threshold is high priority
send_notification "tech_debt_alert" \
  "project_name=${RDD_PROJECT_NAME:-Unknown}" \
  "debt_count=${RDD_DEBT_COUNT:-0}" \
  "threshold=${RDD_THRESHOLD:-0}" \
  "timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# Update next steps with recommendation
NEXT_STEPS="${RDD_DIR}/../docs/11-next-steps.md"
if [[ -f "$NEXT_STEPS" ]]; then
  log_info "Adding debt recommendation to next-steps.md"

  cat >>"$NEXT_STEPS" <<EOF

## Tech Debt Alert

**Debt Count**: ${RDD_DEBT_COUNT:-0} (threshold: ${RDD_THRESHOLD:-0})
**Time**: $(date '+%Y-%m-%d %H:%M')

Consider scheduling a tech debt resolution sprint before proceeding with new features.

EOF
fi

log_info "Tech debt threshold hook finished"
