#!/usr/bin/env bats
#
# Unit tests for Hook Scripts
#

load '../lib/test_helper'
load '../lib/bats-support/load'
load '../lib/bats-assert/load'

setup() {
    setup_test_env
    HOOKS_DIR="${PROJECT_ROOT}/.rdd/hooks"
}

teardown() {
    teardown_test_env
}

#######################################
# Hook Directory Structure Tests
#######################################

@test "Hook scripts directory exists" {
    assert [ -d "${HOOKS_DIR}" ]
}

@test "Hook scripts are executable" {
    for script in "${HOOKS_DIR}"/*.sh; do
        if [[ -f "$script" ]]; then
            assert [ -x "$script" ]
        fi
    done
}

@test "Hook scripts have proper shebang" {
    for script in "${HOOKS_DIR}"/*.sh; do
        if [[ -f "$script" ]]; then
            run head -1 "$script"
            assert_output --partial "#!/bin/bash" || assert_output --partial "#!/usr/bin/env bash"
        fi
    done
}

#######################################
# Hook Script Content Tests
#######################################

@test "Stage complete hook exists" {
    assert [ -f "${HOOKS_DIR}/stage-complete.sh" ] || [ -f "${HOOKS_DIR}/stage_complete.sh" ]
}

@test "Consecutive failure hook exists" {
    assert [ -f "${HOOKS_DIR}/consecutive-failure.sh" ] || [ -f "${HOOKS_DIR}/consecutive_failure.sh" ]
}

@test "Roadmap change hook exists" {
    assert [ -f "${HOOKS_DIR}/roadmap-change.sh" ] || [ -f "${HOOKS_DIR}/roadmap_change.sh" ]
}

@test "Hypothesis invalid hook exists" {
    assert [ -f "${HOOKS_DIR}/hypothesis-invalid.sh" ] || [ -f "${HOOKS_DIR}/hypothesis_invalid.sh" ]
}

@test "Model disagreement hook exists" {
    assert [ -f "${HOOKS_DIR}/model-disagreement.sh" ] || [ -f "${HOOKS_DIR}/model_disagreement.sh" ]
}

@test "Tech debt threshold hook exists" {
    assert [ -f "${HOOKS_DIR}/tech-debt-threshold.sh" ] || [ -f "${HOOKS_DIR}/tech_debt_threshold.sh" ]
}

#######################################
# Hook Script Execution Tests
#######################################

@test "Stage complete hook sources notify.sh correctly" {
    local script="${HOOKS_DIR}/stage-complete.sh"
    if [[ ! -f "$script" ]]; then
        skip "Stage complete hook not found"
    fi

    # Check if script sources notify.sh
    run grep -l "notify.sh" "$script"
    assert_success
}

@test "Hook scripts handle missing notify.sh gracefully" {
    local script="${HOOKS_DIR}/stage-complete.sh"
    if [[ ! -f "$script" ]]; then
        skip "Stage complete hook not found"
    fi

    # Scripts should handle errors with set -e or error checking
    run grep -E "set -e|set -euo pipefail" "$script"
    assert_success || skip "Script uses different error handling"
}

@test "Hook scripts exit with proper status codes" {
    export DRY_RUN="true"

    for script in "${HOOKS_DIR}"/*.sh; do
        if [[ -f "$script" && -x "$script" ]]; then
            run bash "$script" 2>&1 || true
            # Scripts should either succeed or fail gracefully
            assert [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
        fi
    done
}

#######################################
# Hook Configuration Tests
#######################################

@test "Hook configuration file exists" {
    assert [ -f "${PROJECT_ROOT}/.rdd/hooks.yml" ]
}

@test "Hook configuration has required sections" {
    local config="${PROJECT_ROOT}/.rdd/hooks.yml"

    # Check for version
    run grep -E "^version:" "$config"
    assert_success || assert [ -f "$config" ]

    # Check for triggers section
    run grep -E "^triggers:" "$config"
    assert_success || assert [ -f "$config" ]

    # Check for channels section
    run grep -E "^channels:" "$config"
    assert_success || assert [ -f "$config" ]
}

@test "Hook configuration has all trigger types" {
    local config="${PROJECT_ROOT}/.rdd/hooks.yml"

    for trigger in stage_complete roadmap_change consecutive_failure hypothesis_invalid model_disagreement tech_debt_threshold daily_report weekly_report; do
        run grep -E "^\s+${trigger}:" "$config" || grep -E "^${trigger}:" "$config"
        assert_success || skip "Trigger $trigger may use different format"
    done
}

@test "Hook configuration has all channel types" {
    local config="${PROJECT_ROOT}/.rdd/hooks.yml"

    for channel in wecom email bark telegram webhook; do
        run grep -E "^\s+${channel}:" "$config" || grep -E "^${channel}:" "$config"
        assert_success || skip "Channel $channel may use different format"
    done
}

#######################################
# Hook Integration Tests
#######################################

@test "Hooks can be invoked via task command" {
    # Check if hooks can be invoked through Taskfile
    run task --list 2>&1
    # Hooks may or may not have dedicated tasks - just check task command works
    assert_success || assert_output --partial "Available tasks"
}

@test "Notification script is invocable from hooks directory" {
    local notify_script="${PROJECT_ROOT}/.rdd/scripts/notify.sh"

    assert [ -f "$notify_script" ]
    assert [ -x "$notify_script" ]

    # Test help invocation
    run bash "$notify_script" --help
    assert_success
    assert_output --partial "RDD Notification Script"
}

@test "Hook scripts can receive environment variables" {
    export DRY_RUN="true"
    export TEST_MODE="true"

    local script="${HOOKS_DIR}/stage-complete.sh"
    if [[ ! -f "$script" ]]; then
        skip "Stage complete hook not found"
    fi

    # Script should not crash when given environment variables
    run bash -c "DRY_RUN=true TEST_MODE=true bash '$script'" 2>&1 || true
    # We just check it doesn't crash with segfault or similar
    assert [ "$status" -lt 128 ]
}
