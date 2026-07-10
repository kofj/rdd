#!/usr/bin/env bash
#
# RDD Migrate Command
# Migrate existing project to RDD Framework
#
# Usage: rdd migrate [--analyze] [--plan]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

rdd_migrate() {
  local analyze_only=false
  local plan_only=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --analyze)
        analyze_only=true
        shift
        ;;
      --plan)
        plan_only=true
        shift
        ;;
      --help | -h)
        show_migrate_help
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done

  log_step "Analyzing project for RDD migration..."

  # Check if already an RDD project
  if is_rdd_project; then
    log_warn "This is already an RDD project"
    exit 0
  fi

  # Analyze project
  local project_type="unknown"
  if [[ -f "package.json" ]]; then
    project_type="node"
  elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    project_type="python"
  elif [[ -f "Cargo.toml" ]]; then
    project_type="rust"
  elif [[ -f "go.mod" ]]; then
    project_type="go"
  fi

  log_info "Detected project type: ${project_type}"

  if [[ "${analyze_only}" == "true" ]]; then
    echo ""
    echo "Analysis complete. Run 'rdd migrate' to proceed."
    exit 0
  fi

  log_step "Creating RDD structure..."

  # Create RDD directories (don't overwrite existing)
  mkdir -p .rdd/{cache,scripts,hooks,config}
  mkdir -p docs/{stages,handoff}
  mkdir -p tests/{unit,bdd,e2e}
  mkdir -p .claude/{skills,commands}

  # Create config if not exists
  if [[ ! -f ".rdd/config.yml" ]]; then
    create_config "." "$(basename "$(pwd)")"
  fi

  # Create entry points if not exist
  if [[ ! -f "CLAUDE.md" ]]; then
    create_entry_points "." "$(basename "$(pwd)")"
  fi

  log_success "RDD structure created"
  echo ""
  echo "Next steps:"
  echo "  1. Review and update .rdd/config.yml"
  echo "  2. Create docs/01-charter.md with project vision"
  echo "  3. Create docs/stages/stage-roadmap.md for your stages"
  echo "  4. Run 'task doctor' to verify setup"
}

show_migrate_help() {
  cat <<'EOF'
RDD Migrate - Migrate existing project to RDD Framework

Usage:
    rdd migrate [OPTIONS]

Options:
    --analyze    Only analyze the project, don't migrate
    --plan       Show migration plan
    --help, -h   Show this help message

Examples:
    rdd migrate              Migrate current project
    rdd migrate --analyze    Analyze only
EOF
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  rdd_migrate "$@"
fi
