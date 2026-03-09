#!/usr/bin/env bats
#
# Unit tests for checkpoint.sh
#

# Load test helper
load '../lib/test_helper'

# Load bats-support and bats-assert
load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Get project root (actual project, not temp directory)
_ACTUAL_PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

# Set up before each test
setup() {
    # Use isolated test directory for test files
    export CHECKPOINT_FILE="${BATS_TEST_TMPDIR}/checkpoints.json"
    export CACHE_DIR="${BATS_TEST_TMPDIR}"
    # Keep RDD_DIR pointing to actual project for sourcing scripts
    export RDD_DIR="${_ACTUAL_PROJECT_ROOT}/.rdd"
    # PROJECT_ROOT is used by the script, point it to temp for test isolation
    export PROJECT_ROOT="${BATS_TEST_TMPDIR}"
    mkdir -p "${CACHE_DIR}"

    # Source checkpoint script functions for testing
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh"
}

# Tear down after each test
teardown() {
    :
}

#######################################
# init_checkpoint tests
#######################################

@test "init_checkpoint creates checkpoint file with correct structure" {
    init_checkpoint

    assert_file_exists "${CHECKPOINT_FILE}"
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"version"'
    assert_output --partial '"project"'
    assert_output --partial '"stage"'
    assert_output --partial '"gates"'
    assert_output --partial '"decisions"'
    assert_output --partial '"blockers"'
    assert_output --partial '"tech_debt"'
}

@test "init_checkpoint is idempotent" {
    init_checkpoint
    local first_content
    first_content=$(cat "${CHECKPOINT_FILE}")

    init_checkpoint
    local second_content
    second_content=$(cat "${CHECKPOINT_FILE}")

    assert_equal "$first_content" "$second_content"
}

@test "init_checkpoint creates cache directory if not exists" {
    rm -rf "${CACHE_DIR}"
    init_checkpoint

    assert_dir_exists "${CACHE_DIR}"
}

#######################################
# save_checkpoint tests
#######################################

@test "save_checkpoint creates checkpoint file" {
    save_checkpoint "stage-3" "Context Recovery" 50

    assert_file_exists "${CHECKPOINT_FILE}"
}

@test "save_checkpoint saves stage information" {
    save_checkpoint "stage-3" "Context Recovery" 50

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'stage-3'
}

@test "save_checkpoint saves progress" {
    save_checkpoint "stage-3" "Context Recovery" 50

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"progress"'
}

@test "save_checkpoint saves timestamp" {
    save_checkpoint "stage-3" "Context Recovery" 50

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"timestamp"'
}

@test "save_checkpoint works with empty arguments" {
    run save_checkpoint
    assert_success
}

#######################################
# update_gate tests
#######################################

@test "update_gate updates gate status to completed" {
    init_checkpoint

    update_gate "gate_1" "completed"

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'gate_1'
    assert_output --partial 'completed'
}

@test "update_gate updates gate status to in_progress" {
    init_checkpoint

    update_gate "gate_2" "in_progress"

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'gate_2'
    assert_output --partial 'in_progress'
}

@test "update_gate updates gate status to failed" {
    init_checkpoint

    update_gate "gate_3" "failed"

    # Check that the gate status was updated - grep for the specific pattern
    run grep '"gate_3"' "${CHECKPOINT_FILE}"
    assert_output --partial 'gate_3'
}

@test "update_gate records completed_at timestamp" {
    init_checkpoint

    update_gate "gate_1" "completed"

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'completed_at'
}

#######################################
# load_checkpoint tests
#######################################

@test "load_checkpoint returns 1 if no checkpoint exists" {
    # Ensure no checkpoint file
    rm -f "${CHECKPOINT_FILE}"

    run load_checkpoint
    assert_failure
    assert_output --partial "No checkpoint file found"
}

@test "load_checkpoint succeeds when checkpoint exists" {
    save_checkpoint "stage-3" "Test Stage" 50

    run load_checkpoint
    assert_success
}

#######################################
# show_checkpoint tests
#######################################

@test "show_checkpoint displays checkpoint information" {
    save_checkpoint "stage-3" "Context Recovery" 50

    run show_checkpoint
    assert_output --partial "RDD Checkpoint State"
    assert_output --partial "Project"
    assert_output --partial "Current Stage"
    assert_output --partial "Gate Status"
}

@test "show_checkpoint shows gate status indicators" {
    save_checkpoint "stage-3" "Context Recovery" 50

    run show_checkpoint
    assert_output --partial "Gate 1"
    assert_output --partial "Gate 2"
    assert_output --partial "Gate 3"
    assert_output --partial "Gate 4"
    assert_output --partial "Gate 5"
}

@test "show_checkpoint returns 1 if no checkpoint" {
    # Ensure no checkpoint file
    rm -f "${CHECKPOINT_FILE}"

    run show_checkpoint
    assert_failure
    assert_output --partial "No checkpoint file found"
}

#######################################
# clear_checkpoint tests
#######################################

@test "clear_checkpoint removes checkpoint file" {
    save_checkpoint "stage-3" "Test" 50

    assert_file_exists "${CHECKPOINT_FILE}"

    run clear_checkpoint
    assert_success

    refute_file_exists "${CHECKPOINT_FILE}"
}

@test "clear_checkpoint succeeds when no checkpoint exists" {
    run clear_checkpoint
    assert_success
}

#######################################
# needs_recovery tests
#######################################

@test "needs_recovery returns false when no checkpoint" {
    run needs_recovery
    assert_output "false"
}

@test "needs_recovery returns true when status is in_progress" {
    save_checkpoint "stage-3" "Test" 50

    run needs_recovery
    assert_output "true"
}

#######################################
# increment_recovery_count tests
#######################################

@test "increment_recovery_count increments counter" {
    save_checkpoint "stage-3" "Test" 50

    increment_recovery_count
    increment_recovery_count

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"recovery_count": 2'
}

#######################################
# get_timestamp tests
#######################################

@test "get_timestamp returns ISO 8601 format" {
    run get_timestamp
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
}

#######################################
# json_escape tests
#######################################

@test "json_escape escapes double quotes" {
    run json_escape 'hello "world"'
    assert_output 'hello \"world\"'
}

@test "json_escape escapes backslashes" {
    run json_escape 'path\to\file'
    assert_output 'path\\to\\file'
}

@test "json_escape handles normal text" {
    run json_escape 'normal text'
    assert_output 'normal text'
}

#######################################
# add_decision tests
#######################################

@test "add_decision records decision" {
    init_checkpoint

    run add_decision "ADR-17" "Use file-based storage"
    assert_success
}

#######################################
# add_blocker tests
#######################################

@test "add_blocker records blocker" {
    init_checkpoint

    run add_blocker "BLK-001" "Test failure" "P0"
    assert_success
}

@test "add_blocker uses default priority" {
    init_checkpoint

    run add_blocker "BLK-002" "Another blocker"
    assert_success
}

#######################################
# clear_blocker tests
#######################################

@test "clear_blocker removes blocker" {
    init_checkpoint

    add_blocker "BLK-001" "Test blocker"
    run clear_blocker "BLK-001"
    assert_success
}

#######################################
# Main entry point tests
#######################################

@test "checkpoint.sh shows help with --help" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" --help
    assert_output --partial "RDD Checkpoint Management Script"
    assert_success
}

@test "checkpoint.sh shows help with -h" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" -h
    assert_output --partial "Usage:"
    assert_success
}

@test "checkpoint.sh exits with error for unknown command" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" unknown_command
    assert_failure
    assert_output --partial "Unknown command"
}

@test "checkpoint.sh exits with error when no arguments" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh"
    assert_failure
    assert_output --partial "Usage:"
}
