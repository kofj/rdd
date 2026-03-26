#!/usr/bin/env bash
#
# RDD Framework Installer
# One-line installation: curl -fsSL https://.../install.sh | sh
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh
#
# Or with options:
#   curl -fsSL https://.../install.sh | sh -s -- --version v1.0.0
#
# Options:
#   --version VERSION    Install specific version (default: latest)
#   --prefix DIR         Install directory (default: ~/.rdd-framework)
#   --no-path            Don't modify PATH
#   --uninstall          Uninstall RDD Framework
#   --upgrade            Upgrade to latest version
#   --help               Show this help message
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Version
INSTALLER_VERSION="1.0.0"
RDD_VERSION="${RDD_VERSION:-latest}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/.rdd-framework}"
MODIFY_PATH="${MODIFY_PATH:-true}"
GITHUB_REPO="${GITHUB_REPO:-kofj/rdd}"
DOWNLOAD_URL="${DOWNLOAD_URL:-}"

# Temporary directory
TEMP_DIR=""

# Logging functions
log_info() {
    printf '%b\n' "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    printf '%b\n' "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    printf '%b\n' "${RED}[ERROR]${NC} $*"
}

log_step() {
    printf '\n%b\n' "${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"
}

# Cleanup on exit
cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT

# Show banner
show_banner() {
    printf '%b\n' "
${BOLD}${BLUE}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                █████╗ ██████╗ ██████╗                        ║
║                ██╔══██╗██╔══██╗██╔══██╗                      ║
║                █████╔╝ ██║  ██║██║  ██║                      ║
║                ██╔══██╗██║  ██║██║  ██║                      ║
║                ██║  ██║██████╔╝██████╔╝                      ║
║                ╚═╝  ╚═╝╚═════╝ ╚═════╝                       ║
║                                                              ║
║          Roadmap Driven Development Framework                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${NC}
${BOLD}Version:${NC} ${RDD_VERSION}
${BOLD}Installer:${NC} ${INSTALLER_VERSION}
"
}

# Show help
show_help() {
    echo "RDD Framework Installer

Usage:
    curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh

Options:
    --version VERSION    Install specific version (default: latest)
    --prefix DIR         Install directory (default: ~/.rdd-framework)
    --no-path            Don't modify PATH
    --uninstall          Uninstall RDD Framework
    --upgrade            Upgrade to latest version
    --help               Show this help message

Examples:
    # Install latest version
    curl -fsSL https://.../install.sh | sh

    # Install specific version
    curl -fsSL https://.../install.sh | sh -s -- --version v1.0.0

    # Install to custom directory
    curl -fsSL https://.../install.sh | sh -s -- --prefix /opt/rdd

    # Upgrade to latest version
    curl -fsSL https://.../install.sh | sh -s -- --upgrade

    # Uninstall
    curl -fsSL https://.../install.sh | sh -s -- --uninstall
"
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                RDD_VERSION="$2"
                shift 2
                ;;
            --prefix)
                INSTALL_PREFIX="$2"
                shift 2
                ;;
            --no-path)
                MODIFY_PATH="false"
                shift
                ;;
            --uninstall)
                ACTION="uninstall"
                shift
                ;;
            --upgrade)
                ACTION="upgrade"
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check operating system
check_os() {
    log_step "Checking operating system..."

    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "${OS}" in
        Darwin*)
            OS="macos"
            log_info "Detected: macOS (${ARCH})"
            ;;
        Linux*)
            OS="linux"
            log_info "Detected: Linux (${ARCH})"
            ;;
        *)
            log_error "Unsupported operating system: ${OS}"
            log_error "RDD Framework supports macOS and Linux only."
            exit 1
            ;;
    esac

    # Check architecture
    case "${ARCH}" in
        x86_64|amd64|arm64|aarch64)
            log_info "Architecture supported: ${ARCH}"
            ;;
        *)
            log_error "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    log_step "Checking dependencies..."

    local missing=()

    # Check bash version
    local bash_version
    bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ $(echo "${bash_version} >= 4.0" | bc -l 2>/dev/null || echo 0) -eq 0 ]]; then
        log_warn "Bash version ${bash_version} detected. Bash 4.0+ recommended."
    else
        log_info "Bash ${bash_version} ✓"
    fi

    # Check git
    if command -v git &> /dev/null; then
        log_info "git $(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ✓"
    else
        missing+=("git")
    fi

    # Check curl or wget
    if command -v curl &> /dev/null; then
        log_info "curl $(curl --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ✓"
    elif command -v wget &> /dev/null; then
        log_info "wget $(wget --version | head -1 | grep -oE '[0-9]+\.[0-9]+') ✓"
    else
        missing+=("curl or wget")
    fi

    # Check task (optional, will be installed if missing)
    if command -v task &> /dev/null; then
        log_info "task $(task --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ✓"
    else
        log_warn "task (go-task) not found. It will be installed."
    fi

    # Report missing
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install missing dependencies and try again:"
        echo ""
        for dep in "${missing[@]}"; do
            case "${dep}" in
                git)
                    echo "  git:    https://git-scm.com/downloads"
                    ;;
                "curl or wget")
                    echo "  curl:   https://curl.se/download.html"
                    echo "  wget:   https://www.gnu.org/software/wget/"
                    ;;
            esac
        done
        exit 1
    fi
}

# Download file
download_file() {
    local url="$1"
    local output="$2"

    if command -v curl &> /dev/null; then
        curl -fsSL "${url}" -o "${output}"
    elif command -v wget &> /dev/null; then
        wget -q "${url}" -O "${output}"
    fi
}

# Get latest version from GitHub
get_latest_version() {
    local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

    if command -v curl &> /dev/null; then
        curl -fsSL "${api_url}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget &> /dev/null; then
        wget -qO- "${api_url}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    fi
}

# Download RDD Framework
download_rdd() {
    log_step "Downloading RDD Framework..."

    # Determine version
    if [[ "${RDD_VERSION}" == "latest" ]]; then
        RDD_VERSION=$(get_latest_version)
        log_info "Latest version: ${RDD_VERSION}"
    fi

    # Construct download URL
    local archive_name="rdd-framework-${RDD_VERSION}.tar.gz"
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/archive/refs/tags/${RDD_VERSION}.tar.gz"

    # For main branch
    if [[ "${RDD_VERSION}" == "main" || "${RDD_VERSION}" == "master" ]]; then
        DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/archive/refs/heads/main.tar.gz"
        RDD_VERSION="main"
    fi

    log_info "Download URL: ${DOWNLOAD_URL}"

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    local archive_path="${TEMP_DIR}/${archive_name}"

    # Download
    log_info "Downloading..."
    download_file "${DOWNLOAD_URL}" "${archive_path}"

    if [[ ! -f "${archive_path}" ]]; then
        log_error "Download failed"
        exit 1
    fi

    # Extract
    log_info "Extracting..."
    tar -xzf "${archive_path}" -C "${TEMP_DIR}"

    # Find extracted directory
    # GitHub naming: {repo}-{branch} for branches, {repo}-{version} for tags
    local extracted_dir
    extracted_dir=$(find "${TEMP_DIR}" -maxdepth 1 -type d \( -name "rdd-*" -o -name "RDD-*" \) | head -1)

    if [[ -z "${extracted_dir}" ]]; then
        log_error "Could not find extracted directory"
        log_error "Archive contents:"
        ls -la "${TEMP_DIR}"
        exit 1
    fi

    RDD_DOWNLOAD_DIR="${extracted_dir}"
    log_info "Downloaded to: ${RDD_DOWNLOAD_DIR}"
}

# Install go-task if not present
install_task() {
    if command -v task &> /dev/null; then
        log_info "task $(task --version 2>&1 | head -1 || echo 'already installed') ✓"
        return 0
    fi

    log_step "Installing go-task..."

    local task_install_dir="${INSTALL_PREFIX}/bin"
    mkdir -p "${task_install_dir}"

    # Use official install script
    if curl -sL https://taskfile.dev/install.sh | sh -s -- -d -b "${task_install_dir}"; then
        chmod +x "${task_install_dir}/task" 2>/dev/null || true
        log_info "go-task installed to ${task_install_dir}/task"
    else
        log_warn "Official install script failed, trying fallback..."

        # Fallback: direct download from GitHub Releases
        local task_version="v3.42.1"
        local task_url
        local task_arch="${ARCH}"

        case "${task_arch}" in
            x86_64|amd64) task_arch="amd64" ;;
            aarch64|arm64) task_arch="arm64" ;;
        esac

        case "${OS}" in
            macos)
                task_url="https://github.com/go-task/task/releases/download/${task_version}/task_darwin_${task_arch}.tar.gz"
                ;;
            linux)
                task_url="https://github.com/go-task/task/releases/download/${task_version}/task_linux_${task_arch}.tar.gz"
                ;;
            *)
                log_error "Unsupported OS for fallback: ${OS}"
                return 1
                ;;
        esac

        local task_temp="${TEMP_DIR}/task"
        mkdir -p "${task_temp}"

        download_file "${task_url}" "${task_temp}/task.tar.gz"
        tar -xzf "${task_temp}/task.tar.gz" -C "${task_temp}"
        mv "${task_temp}/task" "${task_install_dir}/"
        chmod +x "${task_install_dir}/task"
        log_info "go-task installed via fallback to ${task_install_dir}/task"
    fi

    # Verify installation
    if ! command -v task &> /dev/null && [[ ! -x "${task_install_dir}/task" ]]; then
        log_error "Failed to install go-task"
        return 1
    fi
}

# Install RDD Framework
install_rdd() {
    log_step "Installing RDD Framework..."

    # Create directories
    mkdir -p "${INSTALL_PREFIX}"/{bin,lib,scripts,hooks,templates}
    mkdir -p "${HOME}/.claude"/{skills,commands}

    # Copy files
    log_info "Copying framework files..."

    # Core scripts
    if [[ -d "${RDD_DOWNLOAD_DIR}/.rdd/scripts" ]]; then
        cp -r "${RDD_DOWNLOAD_DIR}/.rdd/scripts/"* "${INSTALL_PREFIX}/scripts/"
    fi

    # Hooks
    if [[ -d "${RDD_DOWNLOAD_DIR}/.rdd/hooks" ]]; then
        cp -r "${RDD_DOWNLOAD_DIR}/.rdd/hooks/"* "${INSTALL_PREFIX}/hooks/"
    fi

    # Skills
    if [[ -d "${RDD_DOWNLOAD_DIR}/.claude/skills" ]]; then
        cp -r "${RDD_DOWNLOAD_DIR}/.claude/skills/"* "${HOME}/.claude/skills/"
    fi

    # Commands
    if [[ -d "${RDD_DOWNLOAD_DIR}/.claude/commands" ]]; then
        cp -r "${RDD_DOWNLOAD_DIR}/.claude/commands/"* "${HOME}/.claude/commands/"
    fi

    # Templates
    if [[ -d "${RDD_DOWNLOAD_DIR}/docs" ]]; then
        cp -r "${RDD_DOWNLOAD_DIR}/docs" "${INSTALL_PREFIX}/templates/"
    fi

    # Copy Taskfile
    if [[ -f "${RDD_DOWNLOAD_DIR}/Taskfile.yml" ]]; then
        cp "${RDD_DOWNLOAD_DIR}/Taskfile.yml" "${INSTALL_PREFIX}/templates/"
    fi

    # Create rdd command wrapper
    create_rdd_command

    # Create VERSION file
    echo "${RDD_VERSION}" > "${INSTALL_PREFIX}/VERSION"

    # Set permissions
    chmod +x "${INSTALL_PREFIX}/bin/rdd"
    chmod +x "${INSTALL_PREFIX}/scripts/"*.sh 2>/dev/null || true
    chmod +x "${INSTALL_PREFIX}/hooks/"*.sh 2>/dev/null || true

    log_info "Framework installed to ${INSTALL_PREFIX}"
}

# Create rdd command wrapper
create_rdd_command() {
    cat > "${INSTALL_PREFIX}/bin/rdd" << 'RDDCMD'
#!/usr/bin/env bash
#
# RDD Framework CLI
#
# Usage:
#   rdd init [NAME]        Initialize a new RDD project
#   rdd migrate            Migrate existing project to RDD
#   rdd stage [COMMAND]    Stage management commands
#   rdd knowledge [CMD]    Knowledge management commands
#   rdd --version          Show version
#   rdd --help             Show help
#

set -euo pipefail

RDD_FRAMEWORK_HOME="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"
RDD_LIB="${RDD_FRAMEWORK_HOME}/lib"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Version
RDD_VERSION=$(cat "${RDD_FRAMEWORK_HOME}/VERSION" 2>/dev/null || echo "unknown")

show_version() {
    echo "RDD Framework v${RDD_VERSION}"
}

show_help() {
    echo "RDD Framework - Roadmap Driven Development

Usage:
    rdd <command> [arguments]

Commands:
    init [NAME]            Initialize a new RDD project
    migrate                Migrate existing project to RDD
    stage <cmd>            Stage management (verify, gate, etc.)
    knowledge <cmd>        Knowledge management (adr, debt, handoff)
    upgrade [--version V]  Upgrade to a new version
    uninstall              Remove RDD Framework

Options:
    --version              Show version
    --help                 Show this help message

Examples:
    rdd init my-project    Create a new project
    rdd init               Initialize in current directory
    rdd stage verify       Verify current stage
    rdd knowledge adr      Record a new decision

For more information, visit: https://github.com/kofj/rdd
"
}

# Source library functions
source_lib() {
    local lib_file="${RDD_LIB}/$1"
    if [[ -f "${lib_file}" ]]; then
        source "${lib_file}"
    fi
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "${command}" in
        init)
            source_lib "init.sh"
            rdd_init "$@"
            ;;
        migrate)
            source_lib "migrate.sh"
            rdd_migrate "$@"
            ;;
        stage)
            source_lib "stage.sh"
            rdd_stage "$@"
            ;;
        knowledge)
            source_lib "knowledge.sh"
            rdd_knowledge "$@"
            ;;
        upgrade)
            "${RDD_FRAMEWORK_HOME}/scripts/upgrade.sh" "$@"
            ;;
        uninstall)
            "${RDD_FRAMEWORK_HOME}/scripts/uninstall.sh" "$@"
            ;;
        --version|-v)
            show_version
            ;;
        --help|-h)
            show_help
            ;;
        *)
            printf '%b\n' "${RED}Error: Unknown command '${command}'${NC}"
            echo "Run 'rdd --help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
RDDCMD

    chmod +x "${INSTALL_PREFIX}/bin/rdd"
}

# Configure PATH
configure_path() {
    if [[ "${MODIFY_PATH}" != "true" ]]; then
        return 0
    fi

    log_step "Configuring PATH..."

    local shell_rc=""
    local current_shell=""

    # Detect shell
    current_shell=$(basename "${SHELL:-bash}")

    case "${current_shell}" in
        bash)
            shell_rc="${HOME}/.bashrc"
            ;;
        zsh)
            shell_rc="${HOME}/.zshrc"
            ;;
        fish)
            shell_rc="${HOME}/.config/fish/config.fish"
            ;;
        *)
            shell_rc="${HOME}/.profile"
            ;;
    esac

    # Check if already in PATH
    if [[ ":${PATH}:" == *":${INSTALL_PREFIX}/bin:"* ]]; then
        log_info "PATH already configured"
        return 0
    fi

    # Add to shell rc
    local path_entry=""
    if [[ "${current_shell}" == "fish" ]]; then
        path_entry="set -gx PATH \"${INSTALL_PREFIX}/bin\" \$PATH"
    else
        path_entry="export PATH=\"${INSTALL_PREFIX}/bin:\$PATH\""
    fi

    # Check if already added
    if ! grep -q "RDD_FRAMEWORK_HOME" "${shell_rc}" 2>/dev/null; then
        echo "" >> "${shell_rc}"
        echo "# RDD Framework" >> "${shell_rc}"
        echo "export RDD_FRAMEWORK_HOME=\"${INSTALL_PREFIX}\"" >> "${shell_rc}"
        echo "${path_entry}" >> "${shell_rc}"
        log_info "Added to ${shell_rc}"
    fi

    # Add to current session
    export PATH="${INSTALL_PREFIX}/bin:${PATH}"
    export RDD_FRAMEWORK_HOME="${INSTALL_PREFIX}"

    log_info "PATH configured for current session"
}

# Install init.sh library
install_init_lib() {
    cat > "${INSTALL_PREFIX}/lib/init.sh" << 'INITSH'
#!/usr/bin/env bash
#
# RDD Init Library
#

RDD_FRAMEWORK_HOME="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"
RDD_TEMPLATES="${RDD_FRAMEWORK_HOME}/templates"

rdd_init() {
    local project_name="${1:-.}"
    local project_dir=""

    if [[ "${project_name}" == "." ]]; then
        project_dir="$(pwd)"
        project_name="$(basename "${project_dir}")"
    else
        project_dir="$(pwd)/${project_name}"
        mkdir -p "${project_dir}"
    fi

    printf '%b\n' "${GREEN}Initializing RDD project: ${project_name}${NC}"
    echo "Project directory: ${project_dir}"
    echo ""

    # Create directory structure
    create_directory_structure "${project_dir}"

    # Create configuration files
    create_config_files "${project_dir}" "${project_name}"

    # Create documentation files
    create_documentation "${project_dir}" "${project_name}"

    # Create agent entry points
    create_entry_points "${project_dir}" "${project_name}"

    # Create symlinks to framework
    create_symlinks "${project_dir}"

    echo ""
    printf '%b\n' "${GREEN}✓ RDD project initialized successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. cd ${project_name}"
    echo "  2. Edit docs/01-charter.md with your project vision"
    echo "  3. Edit docs/stages/stage-roadmap.md with your stages"
    echo "  4. Run 'task doctor' to verify setup"
    echo "  5. Start using RDD with Claude Code!"
}

create_directory_structure() {
    local dir="$1"

    echo "Creating directory structure..."

    mkdir -p "${dir}/.rdd"/{cache,scripts,hooks,config}
    mkdir -p "${dir}/docs"/{stages,handoff,framework}
    mkdir -p "${dir}/tests"/{unit,bdd,e2e}
    mkdir -p "${dir}/.claude"/{skills,commands}

    # Create .gitkeep for empty directories
    touch "${dir}/.rdd/cache/.gitkeep"
    touch "${dir}/.claude/skills/.gitkeep"
    touch "${dir}/.claude/commands/.gitkeep"
    touch "${dir}/tests/unit/.gitkeep"
    touch "${dir}/tests/bdd/.gitkeep"
    touch "${dir}/tests/e2e/.gitkeep"
}

create_config_files() {
    local dir="$1"
    local name="$2"

    echo "Creating configuration files..."

    # config.yml
    cat > "${dir}/.rdd/config.yml" << EOF
# RDD Configuration
version: "1.0.0"
project:
  name: "${name}"
  description: "Project description"

stage:
  min_coverage: 20
  max_failures: 3
  tech_debt_threshold: 3

gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

hooks:
  enabled: false
  config_file: ".rdd/config/hooks.yml"
EOF

    # Create hooks config directory
    mkdir -p "${dir}/.rdd/config"

    cat > "${dir}/.rdd/config/hooks.yml" << EOF
# RDD Hooks Configuration
channels:
  wecom:
    enabled: false
    webhook_url: "\${WECOM_WEBHOOK_URL}"

triggers:
  stage_complete:
    enabled: true
    channels: [wecom]
    priority: "normal"
EOF

    # VERSION
    echo "0.1.0" > "${dir}/.rdd/VERSION"
}

create_documentation() {
    local dir="$1"
    local name="$2"
    local date
    date=$(date +%Y-%m-%d)

    echo "Creating documentation..."

    # Copy templates if available
    if [[ -d "${RDD_TEMPLATES}/docs" ]]; then
        cp -r "${RDD_TEMPLATES}/docs/"* "${dir}/docs/" 2>/dev/null || true
    fi

    # Create minimal docs if templates not available
    cat > "${dir}/docs/01-charter.md" << EOF
# Project Charter

**Project**: ${name}
**Created**: ${date}

## Vision

[Describe your project vision]

## Goals

1. [Goal 1]
2. [Goal 2]

## Non-Goals

1. [What this project will NOT do]
EOF

    cat > "${dir}/docs/11-next-steps.md" << EOF
# Next Steps

**Last Updated**: ${date}

## Current Status

**Stage**: 0 (Initialization)
**Progress**: 0%

## Immediate Actions

- [ ] Define project vision
- [ ] Create roadmap
- [ ] Set up development environment
EOF

    cat > "${dir}/docs/stages/stage-roadmap.md" << EOF
# Project Roadmap

**Last Updated**: ${date}

## Stages

| Stage | Title | Status | Priority |
|-------|-------|--------|----------|
| 0 | Initialization | Planning | P0 |
EOF

    # CHANGELOG
    cat > "${dir}/CHANGELOG.md" << EOF
# Changelog

## [Unreleased]

### Added
- Initial project setup with RDD Framework
EOF
}

create_entry_points() {
    local dir="$1"
    local name="$2"

    echo "Creating entry points..."

    # AGENTS.md
    cat > "${dir}/AGENTS.md" << EOF
# Agent Entry Point

> AI Agent entry point for ${name}

## Quick Start

1. Read \`docs/01-charter.md\` for project vision
2. Read \`docs/stages/stage-roadmap.md\` for current status
3. Read \`docs/11-next-steps.md\` for immediate actions

## RDD Commands

- \`/rdd-init\` - Initialize project
- \`/rdd-stage-auto\` - Execute current stage
- \`/rdd-knowledge\` - Manage knowledge

## Key Files

| File | Purpose |
|------|---------|
| docs/01-charter.md | Project vision |
| docs/stages/stage-roadmap.md | Roadmap |
| docs/11-next-steps.md | Next actions |
| docs/08-autonomous-decisions.md | Decision log |
| docs/12-technical-debt.md | Tech debt |
EOF

    # CLAUDE.md
    cat > "${dir}/CLAUDE.md" << EOF
# Claude Code Entry Point

> Quick reference for Claude Code

## Project: ${name}

## Quick Commands

\`\`\`bash
task doctor      # Check project health
task test        # Run tests
task status      # Show status
\`\`\`

## RDD Skills

- \`/rdd-stage-auto\` - Execute stage with gates
- \`/rdd-knowledge adr\` - Record decision
- \`/rdd-knowledge debt\` - Record tech debt

## Key Documents

Start with: \`docs/11-next-steps.md\`
EOF
}

create_symlinks() {
    local dir="$1"

    echo "Creating symlinks..."

    # Symlink Taskfile if available
    if [[ -f "${RDD_FRAMEWORK_HOME}/templates/Taskfile.yml" ]]; then
        ln -sf "${RDD_FRAMEWORK_HOME}/templates/Taskfile.yml" "${dir}/Taskfile.yml"
    fi

    # Create .gitignore
    cat > "${dir}/.gitignore" << EOF
# RDD
.rdd/cache/

# OS
.DS_Store

# IDE
.idea/
.vscode/
*.swp

# Logs
*.log
EOF
}
INITSH

    chmod +x "${INSTALL_PREFIX}/lib/init.sh"
}

# Install other library files
install_libs() {
    # migrate.sh
    cat > "${INSTALL_PREFIX}/lib/migrate.sh" << 'EOF'
#!/usr/bin/env bash
rdd_migrate() {
    echo "Migration not yet implemented. Use 'rdd init' for new projects."
}
EOF

    # stage.sh
    cat > "${INSTALL_PREFIX}/lib/stage.sh" << 'EOF'
#!/usr/bin/env bash
rdd_stage() {
    local cmd="${1:-help}"
    shift || true

    case "${cmd}" in
        verify|gate|status)
            task "stage:${cmd}" "$@"
            ;;
        *)
            echo "Usage: rdd stage {verify|gate|status}"
            ;;
    esac
}
EOF

    # knowledge.sh
    cat > "${INSTALL_PREFIX}/lib/knowledge.sh" << 'EOF'
#!/usr/bin/env bash
rdd_knowledge() {
    local cmd="${1:-help}"
    shift || true

    case "${cmd}" in
        adr|debt|handoff|check)
            task "knowledge:${cmd}" "$@"
            ;;
        *)
            echo "Usage: rdd knowledge {adr|debt|handoff|check}"
            ;;
    esac
}
EOF

    chmod +x "${INSTALL_PREFIX}/lib/"*.sh
}

# Show post-install instructions
show_post_install() {
    printf '\n'
    printf '%b\n' "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf '%b\n' "${GREEN}║                  Installation Complete!                       ║${NC}"
    printf '%b\n' "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    printf '\n'
    printf '%b\n' "${BOLD}RDD Framework v${RDD_VERSION} installed successfully!${NC}"
    printf '\n'
    printf '%b\n' "${BOLD}Installed to:${NC} ${INSTALL_PREFIX}"
    printf '\n'
    printf '%b\n' "${BOLD}Next steps:${NC}"
    printf '\n'
    printf '%b\n' "  ${YELLOW}1.${NC} Restart your shell or run:"
    printf '%b\n' "     ${BLUE}source ~/.bashrc${NC}  (or ~/.zshrc)"
    printf '\n'
    printf '%b\n' "  ${YELLOW}2.${NC} Verify installation:"
    printf '%b\n' "     ${BLUE}rdd --version${NC}"
    printf '\n'
    printf '%b\n' "  ${YELLOW}3.${NC} Create a new project:"
    printf '%b\n' "     ${BLUE}rdd init my-project${NC}"
    printf '\n'
    printf '%b\n' "  ${YELLOW}4.${NC} Use with Claude Code:"
    printf '%b\n' "     Open Claude Code in your project directory"
    printf '%b\n' "     Skills are automatically available"
    printf '\n'
    printf '%b\n' "${BOLD}Documentation:${NC} https://github.com/kofj/rdd"
    printf '\n'
}

# Uninstall
uninstall() {
    log_step "Uninstalling RDD Framework..."

    if [[ ! -d "${INSTALL_PREFIX}" ]]; then
        log_warn "RDD Framework is not installed at ${INSTALL_PREFIX}"
        exit 0
    fi

    # Remove installation directory
    rm -rf "${INSTALL_PREFIX}"
    log_info "Removed ${INSTALL_PREFIX}"

    # Remove skills and commands
    local claude_dir="${HOME}/.claude"

    # Remove RDD skills
    for skill in rdd-init rdd-migrate rdd-roadmap rdd-stage-auto rdd-knowledge rdd-loop rdd-review-auto rdd-recovery rdd-diagnosis rdd-fresh-check rdd-hooks rdd-core rdd-templates; do
        rm -f "${claude_dir}/skills/${skill}.md"
    done
    log_info "Removed RDD skills"

    # Remove RDD commands
    for cmd in rdd-init rdd-migrate rdd-roadmap rdd-stage-auto rdd-knowledge rdd-loop; do
        rm -f "${claude_dir}/commands/${cmd}.md"
    done
    log_info "Removed RDD commands"

    # Remove from PATH (need to manually edit shell rc)
    log_warn "Please manually remove RDD entries from your shell RC file (~/.bashrc, ~/.zshrc, etc.)"

    printf '\n'
    printf '%b\n' "${GREEN}RDD Framework has been uninstalled.${NC}"
}

# Main
main() {
    local ACTION="${ACTION:-install}"

    parse_args "$@"
    show_banner

    case "${ACTION}" in
        uninstall)
            uninstall
            exit 0
            ;;
        upgrade)
            log_info "Upgrading RDD Framework..."
            ;;
    esac

    check_os
    check_dependencies
    download_rdd
    install_task
    install_rdd
    install_init_lib
    install_libs
    configure_path
    show_post_install
}

# Run main
main "$@"
