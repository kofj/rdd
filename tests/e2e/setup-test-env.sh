#!/usr/bin/env bash
#
# E2E Test Environment Setup Script
# Configures the test environment with Claude Code and RDD Framework
#
# Usage: ./setup-test-env.sh [--skip-claude]
#
# Environment Variables (required):
#   ANTHROPIC_AUTH_TOKEN - API authentication token
#   ANTHROPIC_BASE_URL   - API endpoint URL
#   ANTHROPIC_MODEL      - Model name
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "\n${BLUE}==>${NC} ${BOLD}$*${NC}"; }

# Check required environment variables
check_env_vars() {
  log_step "Checking environment variables..."

  local missing=()

  if [[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
    missing+=("ANTHROPIC_AUTH_TOKEN")
  fi

  if [[ -z "${ANTHROPIC_BASE_URL:-}" ]]; then
    missing+=("ANTHROPIC_BASE_URL")
  fi

  if [[ -z "${ANTHROPIC_MODEL:-}" ]]; then
    missing+=("ANTHROPIC_MODEL")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required environment variables:"
    for var in "${missing[@]}"; do
      echo "  - $var"
    done
    echo ""
    echo "Please set them before running this script:"
    echo "  export ANTHROPIC_AUTH_TOKEN='your-token'"
    echo "  export ANTHROPIC_BASE_URL='your-api-url'"
    echo "  export ANTHROPIC_MODEL='your-model'"
    exit 1
  fi

  log_info "All required environment variables are set"
}

# Create Claude Code settings
create_settings() {
  log_step "Creating Claude Code settings..."

  local settings_file="${HOME}/.claude/settings.json"

  mkdir -p "$(dirname "$settings_file")"

  # Create settings with environment variable placeholders
  cat >"$settings_file" <<EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "\${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "\${ANTHROPIC_BASE_URL}",
    "ANTHROPIC_MODEL": "\${ANTHROPIC_MODEL}"
  },
  "model": "\${ANTHROPIC_MODEL}",
  "skipWebFetchPreflight": true
}
EOF

  log_info "Created settings at $settings_file"
}

# Install RDD Skills
install_skills() {
  log_step "Installing RDD Skills..."

  local skills_dir="${HOME}/.claude/skills"
  local commands_dir="${HOME}/.claude/commands"

  mkdir -p "$skills_dir" "$commands_dir"

  # Copy skills
  if [[ -d "${PROJECT_ROOT}/.claude/skills" ]]; then
    cp -r "${PROJECT_ROOT}/.claude/skills/"* "$skills_dir/"
    log_info "Copied $(ls "$skills_dir"/*.md 2>/dev/null | wc -l) skills"
  else
    log_warn "Skills directory not found"
  fi

  # Copy commands
  if [[ -d "${PROJECT_ROOT}/.claude/commands" ]]; then
    cp -r "${PROJECT_ROOT}/.claude/commands/"* "$commands_dir/"
    log_info "Copied $(ls "$commands_dir"/*.md 2>/dev/null | wc -l) commands"
  else
    log_warn "Commands directory not found"
  fi
}

# Install RDD CLI
install_cli() {
  log_step "Installing RDD CLI..."

  local bin_dir="${HOME}/.local/bin"
  mkdir -p "$bin_dir"

  if [[ -f "${PROJECT_ROOT}/bin/rdd" ]]; then
    cp "${PROJECT_ROOT}/bin/rdd" "$bin_dir/rdd"
    chmod +x "$bin_dir/rdd"
    log_info "Installed rdd CLI to $bin_dir"
  else
    log_warn "CLI not found at ${PROJECT_ROOT}/bin/rdd"
  fi
}

# Create test project template
create_test_template() {
  log_step "Creating test project template..."

  local template_dir="${SCRIPT_DIR}/test-project-template"
  mkdir -p "$template_dir"

  # Create minimal project structure
  mkdir -p "$template_dir"/{.rdd/{cache,scripts,hooks,config},docs/{stages,handoff},tests/{unit,bdd,e2e}}

  # Create basic files
  cat >"$template_dir/Taskfile.yml" <<'EOF'
version: '3'
tasks:
  doctor:
    desc: Run health check
    cmds:
      - echo "All checks passed"
EOF

  cat >"$template_dir/CLAUDE.md" <<'EOF'
# Test Project

This is a minimal test project for E2E testing.
EOF

  log_info "Created test project template at $template_dir"
}

# Verify installation
verify() {
  log_step "Verifying installation..."

  # Check skills
  local skills_count
  skills_count=$(ls "${HOME}/.claude/skills"/*.md 2>/dev/null | wc -l || echo 0)
  log_info "Skills installed: $skills_count"

  # Check commands
  local commands_count
  commands_count=$(ls "${HOME}/.claude/commands"/*.md 2>/dev/null | wc -l || echo 0)
  log_info "Commands installed: $commands_count"

  # Check CLI
  if command -v rdd &>/dev/null; then
    log_info "RDD CLI available: $(rdd --version 2>/dev/null || echo 'installed')"
  else
    log_warn "RDD CLI not in PATH"
  fi

  # Check settings
  if [[ -f "${HOME}/.claude/settings.json" ]]; then
    log_info "Settings file created"
  else
    log_warn "Settings file not found"
  fi
}

# Main
main() {
  log_step "Setting up E2E test environment..."

  check_env_vars
  create_settings
  install_skills
  install_cli
  create_test_template
  verify

  log_step "E2E test environment ready!"
  echo ""
  echo "To run tests:"
  echo "  cd ${PROJECT_ROOT}"
  echo "  task test:e2e"
}

main "$@"
