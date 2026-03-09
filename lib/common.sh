#!/usr/bin/env bash
#
# RDD Common Library
# Shared functions for all RDD commands
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "\n${BLUE}==>${NC} ${BOLD}$*${NC}"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }

# Get RDD home directory
get_rdd_home() {
    if [[ -n "${RDD_FRAMEWORK_HOME:-}" ]]; then
        echo "${RDD_FRAMEWORK_HOME}"
    elif [[ -d "${HOME}/.rdd-framework" ]]; then
        echo "${HOME}/.rdd-framework"
    elif [[ -d "/usr/local/rdd-framework" ]]; then
        echo "/usr/local/rdd-framework"
    elif [[ -d "/opt/rdd-framework" ]]; then
        echo "/opt/rdd-framework"
    else
        echo ""
    fi
}

# Check if in RDD project
is_rdd_project() {
    local dir="${1:-$(pwd)}"
    [[ -d "${dir}/.rdd" ]] && [[ -f "${dir}/CLAUDE.md" ]]
}

# Get project name
get_project_name() {
    local dir="${1:-$(pwd)}"
    if [[ -f "${dir}/.rdd/config.yml" ]]; then
        grep -E "^\\s*name:" "${dir}/.rdd/config.yml" 2>/dev/null | head -1 | sed 's/.*name:\\s*//' | tr -d '"' || basename "${dir}"
    else
        basename "${dir}"
    fi
}

# Get project version
get_project_version() {
    local dir="${1:-$(pwd)}"
    if [[ -f "${dir}/.rdd/VERSION" ]]; then
        head -1 "${dir}/.rdd/VERSION"
    else
        echo "0.1.0"
    fi
}

# Create directory structure
create_dirs() {
    local dir="${1:-$(pwd)}"
    mkdir -p "${dir}"/{.rdd/{cache,scripts,hooks,config},docs/{stages,handoff},tests/{unit,bdd,e2e},.claude/{skills,commands}}
}

# Check dependencies
check_dependencies() {
    local missing=()

    # Check bash version
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        missing+=("bash >= 4.0")
    fi

    # Check git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    # Check task
    if ! command -v task &> /dev/null; then
        missing+=("go-task (task)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi

    return 0
}
