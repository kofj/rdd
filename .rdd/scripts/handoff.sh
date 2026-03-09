#!/bin/bash
#
# RDD Handoff Document Generator
# Generates handoff documents for context recovery after compact
#
# Usage: handoff.sh <command> [options]
#
# Commands:
#   generate    - Generate handoff document
#   show        - Display current handoff
#   validate    - Validate handoff document
#   clear       - Clear handoff document
#

set -euo pipefail

# Configuration paths
RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
CACHE_DIR="${RDD_DIR}/cache"
HANDOFF_FILE="${CACHE_DIR}/handoff.md"
CHECKPOINT_FILE="${CACHE_DIR}/checkpoints.json"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${RDD_DIR}/.." && pwd)}"

# Document paths
NEXT_STEPS_FILE="${PROJECT_ROOT}/docs/11-next-steps.md"
AUTONOMOUS_DECISIONS_FILE="${PROJECT_ROOT}/docs/08-autonomous-decisions.md"
TECH_DEBT_FILE="${PROJECT_ROOT}/docs/12-technical-debt.md"
CHANGELOG_FILE="${PROJECT_ROOT}/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#######################################
# Logging functions
#######################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

#######################################
# Get current timestamp
#######################################

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_readable_timestamp() {
    date +"%Y-%m-%d %H:%M:%S %Z"
}

#######################################
# Extract current stage from next-steps.md
#######################################

get_current_stage() {
    if [[ -f "${NEXT_STEPS_FILE}" ]]; then
        local stage_info
        stage_info=$(grep -A 5 "当前 Stage" "${NEXT_STEPS_FILE}" 2>/dev/null | grep "| Stage" | head -1 || true)
        if [[ -n "$stage_info" ]]; then
            echo "$stage_info" | sed 's/|[^|]*| //' | sed 's/ |.*//' || echo "Unknown"
        else
            echo "Unknown"
        fi
    else
        echo "Unknown"
    fi
}

#######################################
# Extract progress percentage
#######################################

get_progress() {
    if [[ -f "${NEXT_STEPS_FILE}" ]]; then
        local progress
        progress=$(grep "整体进度" "${NEXT_STEPS_FILE}" 2>/dev/null | grep -o "[0-9]*%" | head -1 || echo "0%")
        echo "$progress"
    else
        echo "0%"
    fi
}

#######################################
# Extract current action items
#######################################

get_action_items() {
    if [[ -f "${NEXT_STEPS_FILE}" ]]; then
        echo ""
        # Extract P0 action items
        grep -A 10 "优先级 P0" "${NEXT_STEPS_FILE}" 2>/dev/null | grep "| [0-9]" | head -5 || echo "None"
    else
        echo "Unable to determine action items"
    fi
}

#######################################
# Extract recent decisions
#######################################

get_recent_decisions() {
    if [[ -f "${AUTONOMOUS_DECISIONS_FILE}" ]]; then
        echo ""
        # Get last 5 decisions
        grep -E "^### 决策|^### Decision" "${AUTONOMOUS_DECISIONS_FILE}" 2>/dev/null | tail -5 || echo "None"
    else
        echo "Unable to determine recent decisions"
    fi
}

#######################################
# Extract blockers and risks
#######################################

get_blockers() {
    if [[ -f "${NEXT_STEPS_FILE}" ]]; then
        # Check for blocker section
        if grep -q "## Blocker" "${NEXT_STEPS_FILE}" 2>/dev/null; then
            grep -A 5 "## Blocker" "${NEXT_STEPS_FILE}" 2>/dev/null | head -10 || echo "None"
        else
            echo "None identified"
        fi
    else
        echo "Unknown"
    fi
}

#######################################
# Extract tech debt summary
#######################################

get_tech_debt_summary() {
    if [[ -f "${TECH_DEBT_FILE}" ]]; then
        local total blocking
        total=$(grep -c "^### TD-" "${TECH_DEBT_FILE}" 2>/dev/null || echo "0")
        blocking=$(grep -c "Priority.*Blocking" "${TECH_DEBT_FILE}" 2>/dev/null || echo "0")
        echo "Total: ${total}, Blocking: ${blocking}"
    else
        echo "Unknown"
    fi
}

#######################################
# Extract recent changelog entries
#######################################

get_recent_changes() {
    if [[ -f "${CHANGELOG_FILE}" ]]; then
        echo ""
        head -30 "${CHANGELOG_FILE}" 2>/dev/null || echo "None"
    else
        echo "No changelog found"
    fi
}

#######################################
# Get stage document path
#######################################

get_stage_document() {
    local stage_dir="${PROJECT_ROOT}/docs/stages"
    if [[ -d "$stage_dir" ]]; then
        local stage_file
        stage_file=$(ls "${stage_dir}"/stage-[0-9]*.md 2>/dev/null | head -1 || true)
        if [[ -n "$stage_file" ]]; then
            basename "$stage_file"
        else
            echo "Not found"
        fi
    else
        echo "Not found"
    fi
}

#######################################
# Get gate status from checkpoint
#######################################

get_gate_status() {
    local gate_file="${CACHE_DIR}/checkpoints.json"

    if [[ -f "$gate_file" ]]; then
        local status=""
        for i in 1 2 3 4 5; do
            local gate_status
            gate_status=$(grep -o "\"gate_${i}_status\": \"[^\"]*\"" "$gate_file" 2>/dev/null | sed 's/.*: "//' | sed 's/"$//' || echo "pending")
            if [[ "$gate_status" == "completed" ]]; then
                status+="[x] "
            else
                status+="[ ] "
            fi
        done
        echo "$status"
    else
        echo "[ ] [ ] [ ] [ ] [ ]"
    fi
}

#######################################
# Generate handoff document
#######################################

generate_handoff() {
    local trigger="${1:-manual}"
    local reason="${2:-Scheduled handoff}"

    mkdir -p "${CACHE_DIR}"

    local timestamp readable_timestamp current_stage progress stage_doc
    timestamp=$(get_timestamp)
    readable_timestamp=$(get_readable_timestamp)
    current_stage=$(get_current_stage)
    progress=$(get_progress)
    stage_doc=$(get_stage_document)

    log_info "Generating handoff document..."
    log_debug "Trigger: ${trigger}"
    log_debug "Reason: ${reason}"

    cat > "${HANDOFF_FILE}" << EOF
# RDD Handoff Document

> This document enables context recovery after a compact operation.
> Generated: ${readable_timestamp}
> Trigger: ${trigger}

---

## Current Progress

| Item | Value |
|------|-------|
| **Current Stage** | ${current_stage} |
| **Progress** | ${progress} |
| **Stage Document** | ${stage_doc} |
| **Gate Status** | $(get_gate_status) |
| **Timestamp** | ${timestamp} |

---

## Completed Evidence

### Recent Work
$(get_recent_changes)

### Recent Decisions
$(get_recent_decisions)

---

## Blockers and Risks

$(get_blockers)

### Tech Debt Status
$(get_tech_debt_summary)

---

## Next Single Action

### Priority Actions (P0)
$(get_action_items)

### Immediate Next Step
1. Read \`docs/11-next-steps.md\` for current status
2. Read \`docs/08-autonomous-decisions.md\` for key decisions
3. Run \`task doctor\` to verify project health
4. Run \`task test\` to verify tests pass
5. Continue with the first incomplete P0 action item

---

## Degradation Strategy

If no progress in 30 minutes:

1. **Check for blockers**: Review \`docs/12-technical-debt.md\` for blocking issues
2. **Simplify task**: Break current task into smaller sub-tasks
3. **Seek help**: Notify human via hook if stuck
4. **Document findings**: Update this handoff with new information

If environment issues:

1. Run \`task bootstrap\` to verify structure
2. Run \`task doctor\` for health check
3. Check \`.rdd/cache/\` for checkpoint data
4. Review recent logs for errors

---

## Recovery Instructions

### For New Agent

When recovering from compact:

1. **Read this document first** - You are here
2. **Verify environment**:
   \`\`\`bash
   task doctor
   task test
   \`\`\`
3. **Load checkpoint**:
   \`\`\`bash
   task recovery:load
   \`\`\`
4. **Continue from last checkpoint**:
   - Review gate status above
   - Resume from first incomplete gate
   - Update checkpoint after each step

### Key Files to Read

| Priority | File | Purpose |
|----------|------|---------|
| 1 | docs/11-next-steps.md | Current status |
| 2 | docs/01-charter.md | Project vision |
| 3 | docs/08-autonomous-decisions.md | Key decisions |
| 4 | docs/12-technical-debt.md | Known issues |
| 5 | CLAUDE.md | Claude Code entry point |
| 6 | AGENTS.md | General agent entry point |

### Quick Start Commands

\`\`\`bash
# Check project health
task doctor

# Run all tests
task test

# Check current stage
task status

# Run gate checks
task gate-check

# Generate fresh handoff
task handoff:pack
\`\`\`

---

## Context Details

### Project Structure

\`\`\`
${PROJECT_ROOT}/
├── AGENTS.md              # Agent entry point
├── CLAUDE.md              # Claude Code entry point
├── CHANGELOG.md           # Change log
├── Taskfile.yml           # Task definitions
├── docs/
│   ├── 11-next-steps.md   # Current status (READ FIRST)
│   ├── 01-charter.md      # Project charter
│   ├── 08-autonomous-decisions.md  # ADR log
│   ├── 12-technical-debt.md        # Tech debt ledger
│   └── stages/            # Stage documents
├── .rdd/
│   ├── config.yml         # RDD configuration
│   ├── cache/
│   │   ├── handoff.md     # This file
│   │   └── checkpoints.json  # Checkpoint state
│   ├── scripts/           # Utility scripts
│   └── hooks/             # Hook scripts
└── tests/                 # Test files
\`\`\`

### Recovery Reason

${reason}

---

## Verification Checklist

Before marking recovery complete:

- [ ] Read docs/11-next-steps.md
- [ ] Read docs/08-autonomous-decisions.md
- [ ] Run \`task doctor\` - all checks pass
- [ ] Run \`task test\` - all tests pass
- [ ] Identified current task from Next Single Action
- [ ] Resumed work on current task

---

> **Note**: This handoff document is automatically generated.
> Last updated: ${readable_timestamp}
> Trigger: ${trigger}

EOF

    log_info "Handoff document generated: ${HANDOFF_FILE}"

    # Also update checkpoint timestamp
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
        # Update timestamp in checkpoint
        sed -i "s/\"timestamp\": \"[^\"]*\"/\"timestamp\": \"${timestamp}\"/" "${CHECKPOINT_FILE}" 2>/dev/null || true
    fi
}

#######################################
# Show handoff document
#######################################

show_handoff() {
    if [[ ! -f "${HANDOFF_FILE}" ]]; then
        log_warn "No handoff document found"
        echo "Use 'handoff.sh generate' to create one."
        return 1
    fi

    cat "${HANDOFF_FILE}"
}

#######################################
# Validate handoff document
#######################################

validate_handoff() {
    if [[ ! -f "${HANDOFF_FILE}" ]]; then
        log_error "No handoff document found"
        return 1
    fi

    log_info "Validating handoff document..."

    local errors=0
    local warnings=0

    # Check required sections
    local required_sections=("Current Progress" "Completed Evidence" "Blockers and Risks" "Next Single Action" "Degradation Strategy" "Recovery Instructions")

    for section in "${required_sections[@]}"; do
        if ! grep -q "## ${section}" "${HANDOFF_FILE}"; then
            log_error "Missing section: ${section}"
            ((errors++))
        fi
    done

    # Check for placeholder text
    if grep -q "Unknown" "${HANDOFF_FILE}"; then
        log_warn "Handoff contains 'Unknown' values - may need update"
        ((warnings++))
    fi

    # Check timestamp is recent (within 24 hours)
    local handoff_time
    handoff_time=$(grep "Generated:" "${HANDOFF_FILE}" | head -1 | sed 's/.*Generated: //' || echo "")
    if [[ -n "$handoff_time" ]]; then
        log_debug "Handoff generated at: ${handoff_time}"
    fi

    # Check for key file references
    if ! grep -q "docs/11-next-steps.md" "${HANDOFF_FILE}"; then
        log_warn "Missing reference to docs/11-next-steps.md"
        ((warnings++))
    fi

    if ! grep -q "docs/08-autonomous-decisions.md" "${HANDOFF_FILE}"; then
        log_warn "Missing reference to docs/08-autonomous-decisions.md"
        ((warnings++))
    fi

    # Summary
    echo ""
    echo "Validation Results:"
    echo "-------------------"
    echo "Errors: ${errors}"
    echo "Warnings: ${warnings}"

    if [[ $errors -eq 0 ]]; then
        log_info "Handoff document is valid"
        return 0
    else
        log_error "Handoff document has validation errors"
        return 1
    fi
}

#######################################
# Clear handoff document
#######################################

clear_handoff() {
    if [[ -f "${HANDOFF_FILE}" ]]; then
        rm -f "${HANDOFF_FILE}"
        log_info "Handoff document cleared"
    else
        log_warn "No handoff document to clear"
    fi
}

#######################################
# Check if handoff exists
#######################################

handoff_exists() {
    if [[ -f "${HANDOFF_FILE}" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

#######################################
# Show usage
#######################################

show_usage() {
    cat << 'EOF'
RDD Handoff Document Generator

Usage: handoff.sh <command> [options]

Commands:
  generate [trigger] [reason]
                          Generate handoff document
                          Triggers: gate_complete, decision, timer, manual
  show                    Display current handoff document
  validate                Validate handoff document
  clear                   Clear handoff document
  exists                  Check if handoff exists (returns true/false)

Environment Variables:
  RDD_DIR         RDD configuration directory (default: script parent)
  PROJECT_ROOT    Project root directory (default: RDD_DIR parent)
  VERBOSE         Set to 'true' for debug output

Trigger Types:
  gate_complete   - Triggered when a gate is completed
  decision        - Triggered when an important decision is made
  timer           - Triggered by timer (30 min no progress)
  manual          - Manually triggered

Examples:
  # Generate handoff manually
  handoff.sh generate manual "Agent switch"

  # Generate after gate completion
  handoff.sh generate gate_complete "Gate 3 passed"

  # Check if handoff exists
  if [ "$(handoff.sh exists)" = "true" ]; then
    echo "Handoff document available"
  fi

  # Validate handoff
  handoff.sh validate

EOF
}

#######################################
# Main entry point
#######################################

main() {
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        generate)
            generate_handoff "${1:-manual}" "${2:-Scheduled handoff}"
            ;;
        show)
            show_handoff
            ;;
        validate)
            validate_handoff
            ;;
        clear)
            clear_handoff
            ;;
        exists)
            handoff_exists
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
