#!/bin/bash
#
# RDD Hook: roadmap-change
# Triggered when the roadmap is modified
#
# This hook is called when:
# - A new stage is added
# - A stage is removed or reordered
# - Stage dependencies are changed
# - Stage priorities are modified
#
# Environment variables provided:
#   RDD_CHANGE_TYPE    - Type of change (add/remove/reorder/modify)
#   RDD_CHANGED_BY     - Who made the change (human/agent)
#   RDD_PROJECT_NAME   - Project name from config
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# Source shared functions
if [[ -f "${SCRIPTS_DIR}/notify.sh" ]]; then
  source "${SCRIPTS_DIR}/notify.sh"
fi

log_info "Roadmap change hook triggered"
log_info "Change type: ${RDD_CHANGE_TYPE:-unknown}"
log_info "Changed by: ${RDD_CHANGED_BY:-unknown}"

# Roadmap changes are critical - always send notification
send_notification "roadmap_change" \
  "project_name=${RDD_PROJECT_NAME:-Unknown}" \
  "change_type=${RDD_CHANGE_TYPE:-unknown}" \
  "changed_by=${RDD_CHANGED_BY:-unknown}" \
  "timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')" \
  "change_details=${RDD_CHANGE_DETAILS:-No details provided}"

# If human made the change, we need to update the roadmap history
if [[ "${RDD_CHANGED_BY:-agent}" == "human" ]]; then
  ROADMAP="${RDD_DIR}/../docs/stages/stage-roadmap.md"
  if [[ -f "$ROADMAP" ]]; then
    log_info "Human changed roadmap - agent should reload context"
    # Create a marker file to signal context reload
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC'): Roadmap changed by human" >"${RDD_DIR}/cache/roadmap_changed.flag"
  fi
fi

log_info "Roadmap change hook finished successfully"
