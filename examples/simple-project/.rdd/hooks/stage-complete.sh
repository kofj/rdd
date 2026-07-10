#!/usr/bin/env bash
# Stage 完成 Hook
# 在 Stage 完成时触发

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RDD_DIR="${RDD_DIR:-${SCRIPT_DIR}/../..}"
SCRIPTS_DIR="${RDD_DIR}/scripts"

# 加载通知函数
source "${SCRIPTS_DIR}/notify.sh"

# Hook 参数
STAGE_ID="${1:-unknown}"
STAGE_STATUS="${2:-success}"

log_info() {
  echo "[INFO] $*"
}

main() {
  log_info "Stage Complete Hook triggered"
  log_info "Stage: ${STAGE_ID}"
  log_info "Status: ${STAGE_STATUS}"

  # 发送通知
  if [[ "${STAGE_STATUS}" == "success" ]]; then
    send_notification "Stage ${STAGE_ID} 完成" "success" "Stage has been completed successfully."
  else
    send_notification "Stage ${STAGE_ID} 失败" "error" "Stage execution failed."
  fi

  # 记录审计日志
  if [[ -f "${SCRIPTS_DIR}/audit.sh" ]]; then
    source "${SCRIPTS_DIR}/audit.sh"
    audit_log "stage_complete" "Stage ${STAGE_ID} completed with status: ${STAGE_STATUS}"
  fi
}

main "$@"
