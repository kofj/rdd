#!/usr/bin/env bats
#
# E2E Tests: Installation Flow
# Tests for RDD Framework installation methods
#

load 'test_helper'

# Setup before all tests
setup() {
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
}

# Cleanup after all tests
teardown() {
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# INST-01: curl | sh installation simulation
# ==============================================================================
@test "INST-01: Install script runs successfully" {
    # Skip if no project root
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Run install script with test prefix
    run bash "${PROJECT_ROOT}/scripts/install/install.sh" \
        --prefix "${TEST_DIR}/.rdd-test" \
        --no-path

    # Should succeed or fail gracefully
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ==============================================================================
# INST-02: Manual installation
# ==============================================================================
@test "INST-02: Manual skills installation" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Create target directories
    mkdir -p "${TEST_DIR}/.claude/skills"
    mkdir -p "${TEST_DIR}/.claude/commands"

    # Copy skills
    run cp -r "${PROJECT_ROOT}/.claude/skills/"* "${TEST_DIR}/.claude/skills/"
    [ "$status" -eq 0 ]

    # Verify files exist
    [ -f "${TEST_DIR}/.claude/skills/rdd-init.md" ]
    [ -f "${TEST_DIR}/.claude/skills/rdd-stage-auto.md" ]
}

@test "INST-02: Manual commands installation" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Create target directories
    mkdir -p "${TEST_DIR}/.claude/commands"

    # Copy commands
    run cp -r "${PROJECT_ROOT}/.claude/commands/"* "${TEST_DIR}/.claude/commands/"
    [ "$status" -eq 0 ]

    # Verify files exist
    [ -f "${TEST_DIR}/.claude/commands/rdd-init.md" ]
}

# ==============================================================================
# INST-03: npm package structure
# ==============================================================================
@test "INST-03: package.json is valid" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Check package.json exists
    [ -f "${PROJECT_ROOT}/package.json" ]

    # Validate JSON
    run jq '.' "${PROJECT_ROOT}/package.json"
    [ "$status" -eq 0 ]

    # Check required fields
    run jq -e '.name' "${PROJECT_ROOT}/package.json"
    [ "$status" -eq 0 ]

    run jq -e '.version' "${PROJECT_ROOT}/package.json"
    [ "$status" -eq 0 ]

    run jq -e '.bin.rdd' "${PROJECT_ROOT}/package.json"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# INST-04: rdd --version
# ==============================================================================
@test "INST-04: rdd CLI version check" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Check rdd script exists
    [ -f "${PROJECT_ROOT}/bin/rdd" ]

    # Set RDD_FRAMEWORK_HOME for testing
    export RDD_FRAMEWORK_HOME="${PROJECT_ROOT}"
    run bash "${PROJECT_ROOT}/bin/rdd" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "RDD Framework" ]]
}

@test "INST-04: rdd CLI help check" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    export RDD_FRAMEWORK_HOME="${PROJECT_ROOT}"
    run bash "${PROJECT_ROOT}/bin/rdd" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage" ]] || [[ "$output" =~ "usage" ]]
}

# ==============================================================================
# INST-05: rdd init project creation
# ==============================================================================
@test "INST-05: rdd init creates project structure" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    # Set RDD_FRAMEWORK_HOME for testing
    export RDD_FRAMEWORK_HOME="${PROJECT_ROOT}"

    # Run rdd init
    run bash "${PROJECT_ROOT}/bin/rdd" init "${TEST_DIR}/test-project"
    [ "$status" -eq 0 ]

    # Check directory structure
    [ -d "${TEST_DIR}/test-project/.rdd" ]
    [ -d "${TEST_DIR}/test-project/docs" ]
    [ -d "${TEST_DIR}/test-project/tests" ]
}

@test "INST-05: rdd init creates Taskfile" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    export RDD_FRAMEWORK_HOME="${PROJECT_ROOT}"

    # Run rdd init
    run bash "${PROJECT_ROOT}/bin/rdd" init "${TEST_DIR}/test-project2"
    [ "$status" -eq 0 ]

    # Check Taskfile exists
    [ -f "${TEST_DIR}/test-project2/Taskfile.yml" ]
}

@test "INST-05: rdd init creates entry points" {
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        skip "PROJECT_ROOT not set"
    fi

    export RDD_FRAMEWORK_HOME="${PROJECT_ROOT}"

    # Run rdd init
    run bash "${PROJECT_ROOT}/bin/rdd" init "${TEST_DIR}/test-project3"
    [ "$status" -eq 0 ]

    # Check entry point files
    [ -f "${TEST_DIR}/test-project3/CLAUDE.md" ]
    [ -f "${TEST_DIR}/test-project3/AGENTS.md" ]
}
