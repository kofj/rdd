#!/usr/bin/env bash
#
# RDD Framework Uninstaller
# Removes RDD Framework from the system
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_PREFIX="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

confirm() {
    local prompt="$1"
    echo -e -n "${YELLOW}${prompt} [y/N]${NC}: "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

uninstall() {
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║               RDD Framework Uninstaller                       ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ ! -d "${INSTALL_PREFIX}" ]]; then
        log_warn "RDD Framework is not installed at ${INSTALL_PREFIX}"
        exit 0
    fi

    # Get version
    local version="unknown"
    if [[ -f "${INSTALL_PREFIX}/VERSION" ]]; then
        version=$(cat "${INSTALL_PREFIX}/VERSION")
    fi

    echo "Found: RDD Framework v${version}"
    echo "Location: ${INSTALL_PREFIX}"
    echo ""

    if ! confirm "Are you sure you want to uninstall RDD Framework?"; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo ""
    log_info "Removing RDD Framework..."

    # Remove installation directory
    rm -rf "${INSTALL_PREFIX}"
    log_info "Removed ${INSTALL_PREFIX}"

    # Remove skills
    local claude_dir="${HOME}/.claude"
    local skills_dir="${claude_dir}/skills"
    local commands_dir="${claude_dir}/commands"

    if [[ -d "${skills_dir}" ]]; then
        for skill in rdd-init rdd-migrate rdd-roadmap rdd-stage-auto rdd-knowledge rdd-loop rdd-review-auto rdd-recovery rdd-diagnosis rdd-fresh-check rdd-hooks rdd-core rdd-templates; do
            rm -f "${skills_dir}/${skill}.md"
        done
        log_info "Removed RDD skills from ${skills_dir}"
    fi

    # Remove commands
    if [[ -d "${commands_dir}" ]]; then
        for cmd in rdd-init rdd-migrate rdd-roadmap rdd-stage-auto rdd-knowledge rdd-loop; do
            rm -f "${commands_dir}/${cmd}.md"
        done
        log_info "Removed RDD commands from ${commands_dir}"
    fi

    echo ""
    echo -e "${GREEN}✓ RDD Framework has been uninstalled.${NC}"
    echo ""
    echo -e "${YELLOW}Manual cleanup required:${NC}"
    echo "Please remove the following from your shell RC file (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "  export RDD_FRAMEWORK_HOME=\"...\""
    echo "  export PATH=\"...:\$PATH\""
    echo ""
    echo "Then restart your shell."
}

uninstall "$@"
