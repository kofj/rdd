#!/usr/bin/env bash
#
# RDD Framework Upgrade Script
# Upgrades RDD Framework to a newer version
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_PREFIX="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"
TARGET_VERSION="${1:-latest}"
GITHUB_REPO="${GITHUB_REPO:-kofj/rdd}"

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
  echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"
}

# Get current version
get_current_version() {
  if [[ -f "${INSTALL_PREFIX}/VERSION" ]]; then
    cat "${INSTALL_PREFIX}/VERSION"
  else
    echo "unknown"
  fi
}

# Get latest version from GitHub
get_latest_version() {
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

  if command -v curl &>/dev/null; then
    curl -fsSL "${api_url}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
  elif command -v wget &>/dev/null; then
    wget -qO- "${api_url}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
  fi
}

# Download file
download_file() {
  local url="$1"
  local output="$2"

  if command -v curl &>/dev/null; then
    curl -fsSL "${url}" -o "${output}"
  elif command -v wget &>/dev/null; then
    wget -q "${url}" -O "${output}"
  fi
}

upgrade() {
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║               RDD Framework Upgrader                          ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Check current installation
  if [[ ! -d "${INSTALL_PREFIX}" ]]; then
    log_error "RDD Framework is not installed."
    log_info "Run the installer first: curl -fsSL https://.../install.sh | sh"
    exit 1
  fi

  local current_version
  current_version=$(get_current_version)

  echo "Current version: ${current_version}"
  echo "Install location: ${INSTALL_PREFIX}"
  echo ""

  # Determine target version
  if [[ "${TARGET_VERSION}" == "latest" ]]; then
    TARGET_VERSION=$(get_latest_version)
    log_info "Latest version: ${TARGET_VERSION}"
  fi

  # Check if already on target version
  if [[ "${current_version}" == "${TARGET_VERSION}" ]]; then
    log_info "Already on version ${TARGET_VERSION}"
    exit 0
  fi

  echo "Upgrading to: ${TARGET_VERSION}"
  echo ""

  # Backup current installation
  log_step "Backing up current installation..."
  local backup_dir="${INSTALL_PREFIX}.backup.$(date +%Y%m%d%H%M%S)"
  cp -r "${INSTALL_PREFIX}" "${backup_dir}"
  log_info "Backup created at ${backup_dir}"

  # Download new version
  log_step "Downloading RDD Framework ${TARGET_VERSION}..."

  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf ${temp_dir}" EXIT

  local download_url="https://github.com/${GITHUB_REPO}/archive/refs/tags/${TARGET_VERSION}.tar.gz"
  local archive_path="${temp_dir}/rdd.tar.gz"

  download_file "${download_url}" "${archive_path}"

  if [[ ! -f "${archive_path}" ]]; then
    log_error "Download failed"
    exit 1
  fi

  log_info "Extracting..."
  tar -xzf "${archive_path}" -C "${temp_dir}"

  local extracted_dir
  extracted_dir=$(find "${temp_dir}" -maxdepth 1 -type d -name "rdd-framework*" | head -1)

  if [[ -z "${extracted_dir}" ]]; then
    log_error "Could not find extracted directory"
    exit 1
  fi

  # Update installation
  log_step "Updating installation..."

  # Preserve user configurations
  local preserve_dir
  preserve_dir=$(mktemp -d)

  # Update core files
  cp -r "${extracted_dir}/.rdd/scripts/"* "${INSTALL_PREFIX}/scripts/"
  cp -r "${extracted_dir}/.rdd/hooks/"* "${INSTALL_PREFIX}/hooks/"

  # Update skills
  local claude_dir="${HOME}/.claude"
  if [[ -d "${extracted_dir}/.claude/skills" ]]; then
    cp -r "${extracted_dir}/.claude/skills/"* "${claude_dir}/skills/"
  fi
  if [[ -d "${extracted_dir}/.claude/commands" ]]; then
    cp -r "${extracted_dir}/.claude/commands/"* "${claude_dir}/commands/"
  fi

  # Update templates
  cp -r "${extracted_dir}/docs" "${INSTALL_PREFIX}/templates/"
  cp "${extracted_dir}/Taskfile.yml" "${INSTALL_PREFIX}/templates/" 2>/dev/null || true

  # Update VERSION
  echo "${TARGET_VERSION}" >"${INSTALL_PREFIX}/VERSION"

  # Set permissions
  chmod +x "${INSTALL_PREFIX}/bin/rdd"
  chmod +x "${INSTALL_PREFIX}/scripts/"*.sh 2>/dev/null || true
  chmod +x "${INSTALL_PREFIX}/hooks/"*.sh 2>/dev/null || true

  log_info "Update complete"

  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                 Upgrade Complete!                             ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}Upgraded from ${current_version} to ${TARGET_VERSION}${NC}"
  echo ""
  echo -e "Backup: ${backup_dir}"
  echo ""
  echo "Run 'rdd --version' to verify."
}

upgrade "$@"
