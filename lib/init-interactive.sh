#!/usr/bin/env bash
#
# RDD Interactive Init Wizard
# Guides users through project initialization with prompts
#
# Usage: rdd init --interactive
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

RDD_FRAMEWORK_HOME="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"

# Banner
show_banner() {
  echo -e "
${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}
${CYAN}║${NC}                                                              ${CYAN}║${NC}
${CYAN}║${NC}   ${BOLD}Welcome to RDD Framework Project Setup${NC}                       ${CYAN}║${NC}
${CYAN}║${NC}                                                              ${CYAN}║${NC}
${CYAN}║${NC}   This wizard will help you create a new RDD project.        ${CYAN}║${NC}
${CYAN}║${NC}   Press Enter to accept defaults or type your values.        ${CYAN}║${NC}
${CYAN}║${NC}                                                              ${CYAN}║${NC}
${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}
"
}

# Ask a question with default value
ask() {
  local prompt="$1"
  local default="$2"
  local answer

  if [[ -n "${default}" ]]; then
    echo -e -n "${GREEN}?${NC} ${prompt} ${CYAN}(${default})${NC}: "
  else
    echo -e -n "${GREEN}?${NC} ${prompt}: "
  fi

  read -r answer

  if [[ -z "${answer}" && -n "${default}" ]]; then
    echo "${default}"
  else
    echo "${answer}"
  fi
}

# Ask yes/no question
ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer

  if [[ "${default}" == "y" ]]; then
    echo -e -n "${GREEN}?${NC} ${prompt} ${CYAN}[Y/n]${NC}: "
  else
    echo -e -n "${GREEN}?${NC} ${prompt} ${CYAN}[y/N]${NC}: "
  fi

  read -r answer

  case "${answer:-${default}}" in
    y | Y | yes | YES) echo "y" ;;
    *) echo "n" ;;
  esac
}

# Ask to select from options
ask_select() {
  local prompt="$1"
  shift
  local options=("$@")
  local selected=1
  local answer

  echo -e "${GREEN}?${NC} ${prompt}"
  echo ""

  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${CYAN}${i})${NC} ${opt}"
    ((i++))
  done

  echo ""
  echo -e -n "${GREEN}?${NC} Select option ${CYAN}[1-${#options[@]}]${NC}: "
  read -r answer

  if [[ "${answer}" =~ ^[0-9]+$ && "${answer}" -ge 1 && "${answer}" -le ${#options[@]} ]]; then
    echo "${options[$((answer - 1))]}"
  else
    echo "${options[0]}"
  fi
}

# Ask to select multiple options
ask_multiselect() {
  local prompt="$1"
  shift
  local options=("$@")
  local selected=()

  echo -e "${GREEN}?${NC} ${prompt} ${CYAN}(space to select, enter to confirm)${NC}"
  echo ""

  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${CYAN}${i})${NC} ${opt}"
    ((i++))
  done

  echo ""
  echo -e "Enter comma-separated numbers (e.g., 1,3,4) or 'none': "
  echo -e -n "${GREEN}?${NC} Selection: "
  read -r answer

  if [[ "${answer}" == "none" || -z "${answer}" ]]; then
    echo ""
    return
  fi

  # Parse selection
  IFS=',' read -ra nums <<<"${answer}"
  for num in "${nums[@]}"; do
    num="${num// /}" # Remove spaces
    if [[ "${num}" =~ ^[0-9]+$ && "${num}" -ge 1 && "${num}" -le ${#options[@]} ]]; then
      selected+=("${options[$((num - 1))]}")
    fi
  done

  echo "${selected[*]}"
}

# Progress indicator
show_progress() {
  local current="$1"
  local total="$2"
  local message="$3"

  echo -e "\n${BOLD}${BLUE}[${current}/${total}]${NC} ${message}"
}

# Success message
show_success() {
  echo -e "${GREEN}✓${NC} $*"
}

# Warning message
show_warning() {
  echo -e "${YELLOW}!${NC} $*"
}

# Main wizard
interactive_init() {
  show_banner

  # Step 1: Project name
  show_progress 1 6 "Project Information"
  local project_name
  project_name=$(ask "What is your project name?" "$(basename "$(pwd)")")
  local project_dir
  if [[ "${project_name}" == "$(basename "$(pwd)")" ]]; then
    project_dir="$(pwd)"
  else
    project_dir="$(pwd)/${project_name}"
  fi

  # Step 2: Project description
  show_progress 2 6 "Project Description"
  local project_description
  project_description=$(ask "What is your project description?" "A project using RDD Framework")

  # Step 3: Notification channels
  show_progress 3 6 "Notification Configuration"
  local enable_notifications
  enable_notifications=$(ask_yes_no "Enable notifications?" "n")

  local channels=""
  if [[ "${enable_notifications}" == "y" ]]; then
    echo ""
    channels=$(ask_multiselect "Which notification channels?" \
      "WeChat (WeCom)" \
      "Email" \
      "Slack" \
      "Telegram" \
      "Webhook")
  fi

  # Step 4: Stage planning
  show_progress 4 6 "Stage Planning"
  local stage_count
  stage_count=$(ask "How many stages do you plan?" "5")

  # Step 5: Development approach
  show_progress 5 6 "Development Approach"
  local dev_approach
  dev_approach=$(ask_select "What is your development approach?" \
    "Test-Driven Development (recommended)" \
    "Behavior-Driven Development" \
    "Documentation-Driven Development" \
    "Agile/Iterative")

  # Step 6: Confirm
  show_progress 6 6 "Confirmation"
  echo ""
  echo -e "${BOLD}Configuration Summary:${NC}"
  echo -e "  Project Name:        ${CYAN}${project_name}${NC}"
  echo -e "  Project Directory:   ${CYAN}${project_dir}${NC}"
  echo -e "  Description:         ${CYAN}${project_description}${NC}"
  echo -e "  Notifications:       ${CYAN}${enable_notifications}${NC}"
  if [[ -n "${channels}" ]]; then
    echo -e "  Channels:            ${CYAN}${channels}${NC}"
  fi
  echo -e "  Stages:              ${CYAN}${stage_count}${NC}"
  echo -e "  Approach:            ${CYAN}${dev_approach}${NC}"
  echo ""

  local confirm
  confirm=$(ask_yes_no "Create project with this configuration?" "y")

  if [[ "${confirm}" != "y" ]]; then
    echo -e "${YELLOW}Project creation cancelled.${NC}"
    exit 0
  fi

  # Create project
  echo ""
  echo -e "${BOLD}Creating project...${NC}"
  echo ""

  # Create directory structure
  show_success "Creating directory structure..."
  mkdir -p "${project_dir}"/{.rdd/{cache,scripts,hooks,config},docs/{stages,handoff},tests/{unit,bdd,e2e},.claude/{skills,commands}}

  # Create configuration
  show_success "Creating configuration files..."
  create_config "${project_dir}" "${project_name}" "${project_description}" "${enable_notifications}" "${channels}"

  # Create documentation
  show_success "Creating documentation..."
  create_docs "${project_dir}" "${project_name}" "${project_description}" "${stage_count}" "${dev_approach}"

  # Create entry points
  show_success "Creating entry points..."
  create_entry_points "${project_dir}" "${project_name}"

  # Create symlinks
  show_success "Creating framework links..."
  create_links "${project_dir}"

  # Show completion
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                Project Created Successfully!                   ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}Project:${NC} ${project_name}"
  echo -e "${BOLD}Location:${NC} ${project_dir}"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  echo ""
  if [[ "${project_name}" != "$(basename "$(pwd)")" ]]; then
    echo -e "  ${YELLOW}1.${NC} ${CYAN}cd ${project_name}${NC}"
  fi
  echo -e "  ${YELLOW}2.${NC} Edit ${CYAN}docs/01-charter.md${NC} with your project vision"
  echo -e "  ${YELLOW}3.${NC} Edit ${CYAN}docs/stages/stage-roadmap.md${NC} to plan your stages"
  echo -e "  ${YELLOW}4.${NC} Run ${CYAN}task doctor${NC} to verify setup"
  echo -e "  ${YELLOW}5.${NC} Open Claude Code and use ${CYAN}/rdd-stage-auto${NC} to start"
  echo ""
  echo -e "${BOLD}Documentation:${NC} https://github.com/kofj/rdd"
  echo ""
}

create_config() {
  local dir="$1"
  local name="$2"
  local desc="$3"
  local notifications="$4"
  local channels="$5"

  mkdir -p "${dir}/.rdd/config"

  cat >"${dir}/.rdd/config.yml" <<EOF
# RDD Configuration
# Generated by RDD Framework init wizard

version: "1.0.0"
project:
  name: "${name}"
  description: "${desc}"

# Stage settings
stage:
  min_coverage: 20
  max_failures: 3
  tech_debt_threshold: 3

# Gate settings
gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

# Notification settings
hooks:
  enabled: $([[ "${notifications}" == "y" ]] && echo "true" || echo "false")
  config_file: ".rdd/config/hooks.yml"
EOF

  if [[ "${notifications}" == "y" ]]; then
    cat >"${dir}/.rdd/config/hooks.yml" <<EOF
# RDD Hooks Configuration
# Configure your notification channels below

channels:
  # WeChat (WeCom)
  wecom:
    enabled: $([[ "${channels}" == *"WeChat"* ]] && echo "true" || echo "false")
    webhook_url: "\${WECOM_WEBHOOK_URL}"

  # Email
  email:
    enabled: $([[ "${channels}" == *"Email"* ]] && echo "true" || echo "false")
    smtp_host: "\${SMTP_HOST}"
    smtp_port: 587
    smtp_user: "\${SMTP_USER}"
    smtp_pass: "\${SMTP_PASS}"
    from_address: "\${EMAIL_FROM}"
    to_addresses: []

  # Slack
  slack:
    enabled: $([[ "${channels}" == *"Slack"* ]] && echo "true" || echo "false")
    webhook_url: "\${SLACK_WEBHOOK_URL}"

  # Telegram
  telegram:
    enabled: $([[ "${channels}" == *"Telegram"* ]] && echo "true" || echo "false")
    bot_token: "\${TELEGRAM_BOT_TOKEN}"
    chat_id: "\${TELEGRAM_CHAT_ID}"

  # Generic Webhook
  webhook:
    enabled: $([[ "${channels}" == *"Webhook"* ]] && echo "true" || echo "false")
    url: "\${WEBHOOK_URL}"
    method: "POST"

# Trigger configurations
triggers:
  stage_complete:
    enabled: true
    priority: "normal"
  roadmap_change:
    enabled: true
    priority: "high"
  consecutive_failure:
    enabled: true
    priority: "critical"
EOF
  fi

  echo "0.1.0" >"${dir}/.rdd/VERSION"
}

create_docs() {
  local dir="$1"
  local name="$2"
  local desc="$3"
  local stages="$4"
  local approach="$5"
  local date
  date=$(date +%Y-%m-%d)

  mkdir -p "${dir}/docs/stages"

  # Charter
  cat >"${dir}/docs/01-charter.md" <<EOF
# Project Charter

**Project**: ${name}
**Created**: ${date}

## Vision

${desc}

## Goals

1. [Goal 1 - to be defined]
2. [Goal 2 - to be defined]
3. [Goal 3 - to be defined]

## Non-Goals

1. [What this project will NOT do]
2. [Explicit scope boundaries]

## Success Criteria

- [ ] [Measurable success criterion 1]
- [ ] [Measurable success criterion 2]
- [ ] [Measurable success criterion 3]

## Timeline

- **Start Date**: ${date}
- **Target MVP**: [TBD]
- **Target v1.0**: [TBD]
EOF

  # Next Steps
  cat >"${dir}/docs/11-next-steps.md" <<EOF
# Next Steps

**Last Updated**: ${date}

## Current Status

**Stage**: 0 (Initialization)
**Progress**: 0%

## Immediate Actions

- [ ] Define project vision in docs/01-charter.md
- [ ] Create roadmap in docs/stages/stage-roadmap.md
- [ ] Set up development environment
- [ ] Create Stage 0 design document

## Upcoming Stages

| Stage | Title | Priority | Status |
|-------|-------|----------|--------|
| 0 | Initialization | P0 | Planning |
| 1 | [TBD] | - | - |
EOF

  # Roadmap
  cat >"${dir}/docs/stages/stage-roadmap.md" <<EOF
# Project Roadmap

**Last Updated**: ${date}
**Current Stage**: 0
**Planned Stages**: ${stages}

## Vision

${desc}

## Stage Overview

| Stage | Title | Status | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| 0 | Initialization | Planning | P0 | None |
EOF

  # Add stages based on count
  for i in $(seq 1 "${stages}"); do
    echo "| ${i} | [TBD] | - | - | Stage $((i - 1)) |" >>"${dir}/docs/stages/stage-roadmap.md"
  done

  # Empty ADR
  cat >"${dir}/docs/08-autonomous-decisions.md" <<EOF
# Autonomous Decision Records (ADR)

**Last Updated**: ${date}

## Overview

This document records all significant autonomous decisions made during development.

## ADR Index

| ID | Title | Stage | Date | Status |
|----|-------|-------|------|--------|
| - | (No decisions yet) | - | - | - |

## Decision Template

Use this template for new decisions:

\`\`\`markdown
### Decision N: [Title]

**Background**: What circumstances led to this decision

**Decision**: What path was chosen

**Rationale**: Why this path was selected

**Impact on Subsequent Stages**:
- [Impact on future work]
\`\`\`
EOF

  # Tech Debt
  cat >"${dir}/docs/12-technical-debt.md" <<EOF
# Technical Debt Ledger

**Last Updated**: ${date}

## Active Technical Debt

(No technical debt recorded yet)

## Debt Template

\`\`\`markdown
### TD-NN: [Title]

- **Priority**: [Blocking/Degraded Functionality/Technical Optimization]
- **Source**: [Stage N]
- **Description**: [What the debt is]
- **Resolution Plan**: [How to address it]
- **Created**: [Date]
- **Resolved**: [Date or empty]
\`\`\`
EOF

  # CHANGELOG
  cat >"${dir}/CHANGELOG.md" <<EOF
# Changelog

## [Unreleased]

### Added
- Initial project setup with RDD Framework
EOF

  # gitignore
  cat >"${dir}/.gitignore" <<EOF
# RDD
.rdd/cache/

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Logs
*.log

# Environment
.env
.env.local
EOF
}

create_entry_points() {
  local dir="$1"
  local name="$2"

  # AGENTS.md
  cat >"${dir}/AGENTS.md" <<EOF
# Agent Entry Point

> AI Agent entry point for ${name}

## Quick Start

1. Read \`docs/01-charter.md\` for project vision
2. Read \`docs/stages/stage-roadmap.md\` for current status
3. Read \`docs/11-next-steps.md\` for immediate actions

## RDD Commands

| Command | Purpose |
|---------|---------|
| \`/rdd-init\` | Initialize project |
| \`/rdd-stage-auto\` | Execute current stage |
| \`/rdd-knowledge adr\` | Record decision |
| \`/rdd-knowledge debt\` | Record tech debt |

## Key Files

| File | Purpose |
|------|---------|
| docs/01-charter.md | Project vision |
| docs/stages/stage-roadmap.md | Roadmap |
| docs/11-next-steps.md | Next actions |
| docs/08-autonomous-decisions.md | Decision log |
| docs/12-technical-debt.md | Tech debt |

## Gate Checklist

- [ ] Gate 1: Design doc created
- [ ] Gate 2: Design reviewed
- [ ] Gate 3: Implementation + tests pass
- [ ] Gate 4: Code reviewed
- [ ] Gate 5: Completion verified
EOF

  # CLAUDE.md
  cat >"${dir}/CLAUDE.md" <<EOF
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

| Skill | Purpose |
|-------|---------|
| \`/rdd-stage-auto\` | Execute stage with gates |
| \`/rdd-knowledge adr\` | Record decision |
| \`/rdd-knowledge debt\` | Record tech debt |
| \`/rdd-loop\` | Control autonomous execution |

## Key Documents

Start with: \`docs/11-next-steps.md\`
EOF
}

create_links() {
  local dir="$1"

  # Symlink Taskfile
  if [[ -f "${RDD_FRAMEWORK_HOME}/templates/Taskfile.yml" ]]; then
    ln -sf "${RDD_FRAMEWORK_HOME}/templates/Taskfile.yml" "${dir}/Taskfile.yml"
  fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  interactive_init "$@"
fi
