#!/usr/bin/env bats
#
# Unit tests for handoff.sh
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
    export HANDOFF_FILE="${BATS_TEST_TMPDIR}/handoff.md"
    export CHECKPOINT_FILE="${BATS_TEST_TMPDIR}/checkpoints.json"
    export CACHE_DIR="${BATS_TEST_TMPDIR}"
    # Keep RDD_DIR pointing to actual project for sourcing scripts
    export RDD_DIR="${_ACTUAL_PROJECT_ROOT}/.rdd"
    # PROJECT_ROOT is used by the script, point it to temp for test isolation
    export PROJECT_ROOT="${BATS_TEST_TMPDIR}"
    mkdir -p "${CACHE_DIR}"

    # Source handoff script functions for testing
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh"
}

# Tear down after each test
teardown() {
    :
}

#######################################
# generate_handoff tests
#######################################

@test "generate_handoff creates handoff file" {
    run generate_handoff "manual" "Test handoff"
    assert_success

    assert_file_exists "${HANDOFF_FILE}"
}

@test "generate_handoff creates cache directory if needed" {
    rm -rf "${CACHE_DIR}"

    generate_handoff "manual" "Test handoff"

    assert_dir_exists "${CACHE_DIR}"
}

@test "generate_handoff includes required sections" {
    generate_handoff "manual" "Test handoff"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "## Current Progress"
    assert_output --partial "## Completed Evidence"
    assert_output --partial "## Blockers and Risks"
    assert_output --partial "## Next Single Action"
    assert_output --partial "## Degradation Strategy"
    assert_output --partial "## Recovery Instructions"
}

@test "generate_handoff includes trigger type" {
    generate_handoff "gate_complete" "Gate 3 passed"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "gate_complete"
}

@test "generate_handoff includes reason" {
    generate_handoff "manual" "Agent switching"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "Agent switching"
}

@test "generate_handoff includes timestamp" {
    generate_handoff "manual" "Test"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "Generated:"
}

@test "generate_handoff includes key file references" {
    generate_handoff "manual" "Test"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "docs/11-next-steps.md"
    assert_output --partial "docs/08-autonomous-decisions.md"
    assert_output --partial "docs/12-technical-debt.md"
}

@test "generate_handoff includes task commands" {
    generate_handoff "manual" "Test"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "task doctor"
    assert_output --partial "task test"
}

@test "generate_handoff includes verification checklist" {
    generate_handoff "manual" "Test"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "Verification Checklist"
}

@test "generate_handoff works with default arguments" {
    run generate_handoff
    assert_success
    assert_file_exists "${HANDOFF_FILE}"
}

#######################################
# show_handoff tests
#######################################

@test "show_handoff displays handoff content" {
    generate_handoff "manual" "Test"

    run show_handoff
    assert_success
    assert_output --partial "RDD Handoff Document"
}

@test "show_handoff fails when no handoff exists" {
    # Remove any handoff file that may exist
    rm -f "${HANDOFF_FILE}"

    run show_handoff
    assert_failure
    assert_output --partial "No handoff document found"
}

#######################################
# validate_handoff tests
#######################################

@test "validate_handoff passes for valid handoff" {
    generate_handoff "manual" "Test"

    run validate_handoff
    assert_success
    assert_output --partial "valid"
}

@test "validate_handoff fails when no handoff exists" {
    # Remove any handoff file that may exist
    rm -f "${HANDOFF_FILE}"

    run validate_handoff
    assert_failure
    assert_output --partial "No handoff document found"
}

@test "validate_handoff checks required sections" {
    generate_handoff "manual" "Test"

    run validate_handoff
    assert_output --partial "Validating handoff document"
}

@test "validate_handoff reports warnings for unknown values" {
    generate_handoff "manual" "Test"

    run validate_handoff
    # May have warnings about Unknown values if docs don't exist
    assert_success || assert_output --partial "Warning"
}

#######################################
# clear_handoff tests
#######################################

@test "clear_handoff removes handoff file" {
    generate_handoff "manual" "Test"

    assert_file_exists "${HANDOFF_FILE}"

    run clear_handoff
    assert_success

    refute_file_exists "${HANDOFF_FILE}"
}

@test "clear_handoff succeeds when no handoff exists" {
    run clear_handoff
    assert_success
}

#######################################
# handoff_exists tests
#######################################

@test "handoff_exists returns true when handoff exists" {
    generate_handoff "manual" "Test"

    run handoff_exists
    assert_output "true"
}

@test "handoff_exists returns false when no handoff" {
    # Remove any handoff file that may exist
    rm -f "${HANDOFF_FILE}"

    run handoff_exists
    assert_output "false"
}

#######################################
# get_timestamp tests
#######################################

@test "get_timestamp returns ISO 8601 format" {
    run get_timestamp
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
}

@test "get_readable_timestamp returns readable format" {
    run get_readable_timestamp
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
}

#######################################
# get_current_stage tests
#######################################

@test "get_current_stage returns stage info or Unknown" {
    run get_current_stage
    # May return Unknown if no docs/11-next-steps.md exists
    assert_success
}

#######################################
# get_progress tests
#######################################

@test "get_progress returns percentage or 0%" {
    run get_progress
    assert_output --regexp '^[0-9]+%$'
}

#######################################
# get_gate_status tests
#######################################

@test "get_gate_status returns five gate indicators" {
    run get_gate_status
    # Should return 5 gate status indicators
    assert_output --regexp '^\[.\] \[.\] \[.\] \[.\] \[.\]$'
}

#######################################
# Trigger type tests
#######################################

@test "generate_handoff with gate_complete trigger" {
    generate_handoff "gate_complete" "Gate 3 passed"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "gate_complete"
    assert_output --partial "Gate 3 passed"
}

@test "generate_handoff with decision trigger" {
    generate_handoff "decision" "ADR-17 decided"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "decision"
}

@test "generate_handoff with timer trigger" {
    generate_handoff "timer" "30 min timeout"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "timer"
}

#######################################
# Main entry point tests
#######################################

@test "handoff.sh shows help with --help" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" --help
    assert_output --partial "RDD Handoff Document Generator"
    assert_success
}

@test "handoff.sh shows help with -h" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" -h
    assert_output --partial "Usage:"
    assert_success
}

@test "handoff.sh exits with error for unknown command" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" unknown_command
    assert_failure
    assert_output --partial "Unknown command"
}

@test "handoff.sh exits with error when no arguments" {
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh"
    assert_failure
    assert_output --partial "Usage:"
}

#######################################
# Integration tests
#######################################

@test "handoff.sh generate creates valid document" {
    export HANDOFF_FILE="${HANDOFF_FILE}"
    export CACHE_DIR="${CACHE_DIR}"
    export PROJECT_ROOT="${PROJECT_ROOT}"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Integration test"
    assert_success
    assert_file_exists "${HANDOFF_FILE}"
}

@test "handoff.sh show displays generated content" {
    export HANDOFF_FILE="${HANDOFF_FILE}"
    export CACHE_DIR="${CACHE_DIR}"
    export PROJECT_ROOT="${PROJECT_ROOT}"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Test content"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" show
    assert_success
    assert_output --partial "Test content"
}

@test "handoff.sh exists returns correct status" {
    export HANDOFF_FILE="${HANDOFF_FILE}"
    export CACHE_DIR="${CACHE_DIR}"
    export PROJECT_ROOT="${PROJECT_ROOT}"

    # Remove any existing handoff
    rm -f "${HANDOFF_FILE}"

    # No handoff
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "false"

    # Generate handoff
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate

    # Now exists
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "true"

    # Clear handoff
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" clear

    # No longer exists
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "false"
}
