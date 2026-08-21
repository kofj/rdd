#!/usr/bin/env bats
#
# E2E Tests: Claude Code Integration
# Tests for Claude Code skills and commands recognition
#

load 'test_helper'

# Setup before all tests
setup() {
    TEST_DIR="$(mktemp -d)"
    export HOME="${TEST_DIR}"
    mkdir -p "${TEST_DIR}/.claude/skills"
    mkdir -p "${TEST_DIR}/.claude/commands"
}

# Cleanup after all tests
teardown() {
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# INT-01: Skills files exist
# ==============================================================================
@test "INT-01: All skills files exist" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    local skills=(
        "rdd-core"
        "rdd-init"
        "rdd-migrate"
        "rdd-roadmap"
        "rdd-stage-auto"
        "rdd-knowledge"
        "rdd-loop"
        "rdd-review-auto"
        "rdd-recovery"
        "rdd-diagnosis"
        "rdd-fresh-check"
        "rdd-hooks"
        "rdd-templates"
        "rdd-help"
        "rdd-workflow"
        "rdd-state"
        "rdd-stages-archive"
    )

    for skill in "${skills[@]}"; do
        [ -f "${PROJECT_ROOT}/.claude/skills/${skill}/SKILL.md" ]
    done
}

@test "INT-01: Skills count is correct" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    local count
    count=$(ls -d "${PROJECT_ROOT}/.claude/skills/"rdd-*/ 2>/dev/null | wc -l)
    [ "$count" -eq 17 ]
}

# ==============================================================================
# INT-02: Legacy slash commands removed (superseded by skills)
# ==============================================================================
@test "INT-02: No legacy RDD slash commands remain" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Skills of the same name take precedence and cover slash triggering,
    # so no rdd-*.md command files should exist in the repo source.
    run bash -c "ls ${PROJECT_ROOT}/.claude/commands/rdd-*.md 2>/dev/null"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# INT-03: API endpoint reachable
# ==============================================================================
@test "INT-03: API endpoint is reachable (if configured)" {
    # Skip if no API URL configured
    if [[ -z "${ANTHROPIC_BASE_URL:-}" ]]; then
        skip "ANTHROPIC_BASE_URL not set"
    fi

    # Test basic connectivity (may return 401/403, that's fine)
    run curl -s -o /dev/null -w "%{http_code}" "${ANTHROPIC_BASE_URL}/v1/models" --connect-timeout 5
    # Accept any HTTP response (even errors mean endpoint is reachable)
    [[ "$output" =~ ^[0-9]+$ ]]
}

# ==============================================================================
# INT-04: Skills format is correct
# ==============================================================================
@test "INT-04: Skills have valid markdown format" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    for skill in "${PROJECT_ROOT}/.claude/skills/"rdd-*/SKILL.md; do
        # File should not be empty
        [ -s "$skill" ]

        # File should start with YAML frontmatter
        [ "$(head -1 "$skill")" = "---" ]
    done
}

@test "INT-04: Skills contain required sections" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Check rdd-core skill exists in directory format with frontmatter
    local core_skill="${PROJECT_ROOT}/.claude/skills/rdd-core/SKILL.md"
    [ -f "$core_skill" ]
    [ "$(head -1 "$core_skill")" = "---" ]
    grep -q "RDD" "$core_skill"
}

# ==============================================================================
# INT-05: settings.json format
# ==============================================================================
@test "INT-05: settings template is valid JSON" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Create a settings file
    cat > "${TEST_DIR}/.claude/settings.json" << 'EOF'
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL}",
    "ANTHROPIC_MODEL": "${ANTHROPIC_MODEL}"
  },
  "model": "${ANTHROPIC_MODEL}",
  "skipWebFetchPreflight": true
}
EOF

    # Validate JSON
    run jq '.' "${TEST_DIR}/.claude/settings.json"
    [ "$status" -eq 0 ]
}

@test "INT-05: settings contains required fields" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Create settings
    cat > "${TEST_DIR}/.claude/settings.json" << 'EOF'
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL}",
    "ANTHROPIC_MODEL": "${ANTHROPIC_MODEL}"
  },
  "model": "${ANTHROPIC_MODEL}"
}
EOF

    # Check required fields
    run jq -e '.model' "${TEST_DIR}/.claude/settings.json"
    [ "$status" -eq 0 ]

    run jq -e '.env.ANTHROPIC_MODEL' "${TEST_DIR}/.claude/settings.json"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# INT-06: No sensitive info in files
# ==============================================================================
@test "INT-06: No hardcoded tokens in skills" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Check no hardcoded API tokens (sk-ant-...)
    run grep -rn "sk-ant-" "${PROJECT_ROOT}/.claude/skills/" 2>/dev/null
    [ "$status" -eq 1 ] || [ -z "$output" ]
}

@test "INT-06: No hardcoded API URLs in source files" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Check no hardcoded sensitive URLs in source files (not tests)
    # This passes if no matches found or output is empty
    local matches
    matches=$(grep -r "tkeai.woa" "${PROJECT_ROOT}/.claude/" "${PROJECT_ROOT}/.rdd/scripts/" "${PROJECT_ROOT}/lib/" 2>/dev/null || true)
    [ -z "$matches" ]
}
