#!/bin/bash
#
# RDD Framework Validation Tests
# Tests to verify the RDD framework is correctly set up
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

check_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    pass "File exists: $file"
  else
    fail "File missing: $file"
  fi
}

check_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    pass "Directory exists: $dir"
  else
    fail "Directory missing: $dir"
  fi
}

check_yaml() {
  local file="$1"
  if command -v python3 &>/dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
      pass "Valid YAML: $file"
    else
      fail "Invalid YAML: $file"
    fi
  else
    pass "YAML validation skipped (python3 not available): $file"
  fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "               RDD Framework Validation Tests"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Change to project root
cd "$(dirname "$0")/.."

# ============================================
# Directory Structure Tests
# ============================================
echo "───────────────────────────────────────────────────────────────"
echo "DIRECTORY STRUCTURE"
echo "───────────────────────────────────────────────────────────────"

check_dir ".rdd"
check_dir ".rdd/cache"
check_dir ".rdd/scripts"
check_dir ".rdd/hooks"
check_dir "docs"
check_dir "docs/framework"
check_dir "docs/stages"
check_dir "docs/handoff"
check_dir ".claude"
check_dir ".claude/skills"
check_dir ".claude/commands"
check_dir "tests"

# ============================================
# Configuration Files Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "CONFIGURATION FILES"
echo "───────────────────────────────────────────────────────────────"

check_file ".rdd/config.yml"
check_file ".rdd/hooks.yml"
check_file ".rdd/templates.yml"
check_file ".rdd/checkpoints.yml"

check_yaml ".rdd/config.yml"
check_yaml ".rdd/hooks.yml"
check_yaml ".rdd/templates.yml"
check_yaml ".rdd/checkpoints.yml"

# ============================================
# Hook Scripts Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "HOOK SCRIPTS"
echo "───────────────────────────────────────────────────────────────"

check_file ".rdd/scripts/notify.sh"
check_file ".rdd/hooks/stage-complete.sh"
check_file ".rdd/hooks/roadmap-change.sh"
check_file ".rdd/hooks/consecutive-failure.sh"
check_file ".rdd/hooks/hypothesis-invalid.sh"
check_file ".rdd/hooks/model-disagreement.sh"
check_file ".rdd/hooks/tech-debt-threshold.sh"
check_file ".rdd/hooks/daily-report.sh"
check_file ".rdd/hooks/weekly-report.sh"

# Check if scripts are executable
for script in .rdd/scripts/notify.sh .rdd/hooks/*.sh; do
  if [[ -x "$script" ]]; then
    pass "Executable: $script"
  else
    fail "Not executable: $script"
  fi
done

# ============================================
# Skills Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "SKILLS"
echo "───────────────────────────────────────────────────────────────"

check_file ".claude/skills/rdd-core.md"
check_file ".claude/skills/rdd-templates.md"
check_file ".claude/skills/rdd-init.md"
check_file ".claude/skills/rdd-migrate.md"
check_file ".claude/skills/rdd-roadmap.md"
check_file ".claude/skills/rdd-stage-auto.md"
check_file ".claude/skills/rdd-knowledge.md"
check_file ".claude/skills/rdd-loop.md"
check_file ".claude/skills/rdd-review-auto.md"
check_file ".claude/skills/rdd-recovery.md"
check_file ".claude/skills/rdd-diagnosis.md"
check_file ".claude/skills/rdd-fresh-check.md"

# ============================================
# Commands Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "COMMANDS"
echo "───────────────────────────────────────────────────────────────"

check_file ".claude/commands/rdd-init.md"
check_file ".claude/commands/rdd-migrate.md"
check_file ".claude/commands/rdd-roadmap.md"
check_file ".claude/commands/rdd-stage-auto.md"
check_file ".claude/commands/rdd-knowledge.md"
check_file ".claude/commands/rdd-loop.md"

# ============================================
# Documentation Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "DOCUMENTATION"
echo "───────────────────────────────────────────────────────────────"

check_file "docs/01-charter.md"
check_file "docs/02-engineering-principles.md"
check_file "docs/03-stage-based-development.md"
check_file "docs/08-autonomous-decisions.md"
check_file "docs/10-review-practices.md"
check_file "docs/11-next-steps.md"
check_file "docs/12-technical-debt.md"
check_file "docs/stages/stage-roadmap.md"
check_file "docs/stages/stage-template.md"

check_file "docs/framework/project-governance-spec.md"
check_file "docs/framework/agentic-code-execution-spec.md"
check_file "docs/framework/standards-authoring-spec.md"

# ============================================
# Entry Points Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "ENTRY POINTS"
echo "───────────────────────────────────────────────────────────────"

check_file "AGENTS.md"
check_file "CLAUDE.md"
check_file "CHANGELOG.md"
check_file "README.md"
check_file "Taskfile.yml"

# ============================================
# Content Validation Tests
# ============================================
echo ""
echo "───────────────────────────────────────────────────────────────"
echo "CONTENT VALIDATION"
echo "───────────────────────────────────────────────────────────────"

# Check config has required fields
if grep -q "version:" .rdd/config.yml && grep -q "project:" .rdd/config.yml; then
  pass "config.yml has required fields"
else
  fail "config.yml missing required fields"
fi

# Check hooks.yml has channels
if grep -q "channels:" .rdd/hooks.yml; then
  pass "hooks.yml has channels configured"
else
  fail "hooks.yml missing channels"
fi

# Check templates.yml has templates
if grep -q "templates:" .rdd/templates.yml; then
  pass "templates.yml has templates"
else
  fail "templates.yml missing templates"
fi

# Check AGENTS.md has reading order
if grep -q "reading order" AGENTS.md || grep -q "Read this document first" AGENTS.md; then
  pass "AGENTS.md has reading order"
else
  fail "AGENTS.md missing reading order"
fi

# Check stage-roadmap.md has Stage 0
if grep -q "Stage 0" docs/stages/stage-roadmap.md; then
  pass "stage-roadmap.md has Stage 0"
else
  fail "stage-roadmap.md missing Stage 0"
fi

# Check autonomous-decisions.md has template
if grep -q "Decision" docs/08-autonomous-decisions.md; then
  pass "autonomous-decisions.md has structure"
else
  fail "autonomous-decisions.md missing structure"
fi

# Check technical-debt.md has template
if grep -q "TD-" docs/12-technical-debt.md; then
  pass "technical-debt.md has structure"
else
  fail "technical-debt.md missing structure"
fi

# ============================================
# Summary
# ============================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                       TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed. Please fix the issues above.${NC}"
  exit 1
fi
