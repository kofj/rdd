#!/usr/bin/env bats
#
# BDD tests for Context Recovery Flows
#
# These tests verify the behavior of the context recovery system
# using Given/When/Then style scenarios.
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
    export HANDOFF_FILE="${BATS_TEST_TMPDIR}/handoff.md"
    export CACHE_DIR="${BATS_TEST_TMPDIR}"
    export RDD_DIR="${_ACTUAL_PROJECT_ROOT}/.rdd"
    export PROJECT_ROOT="${BATS_TEST_TMPDIR}"
    mkdir -p "${CACHE_DIR}"

    # Source scripts for testing
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh"
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh"
}

# Tear down after each test
teardown() {
    :
}

#######################################
# Feature: Handoff Document Generation
#######################################

# Scenario 1: Generate handoff after gate completion
@test "Given a stage is in progress, When gate 3 completes, Then handoff is generated with gate_complete trigger" {
    # Given
    save_checkpoint "stage-3" "Context Recovery" 60
    update_gate "gate_1" "completed"
    update_gate "gate_2" "completed"
    update_gate "gate_3" "completed"

    # When
    run generate_handoff "gate_complete" "Gate 3 completed successfully"

    # Then
    assert_success
    assert_file_exists "${HANDOFF_FILE}"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "gate_complete"
    assert_output --partial "Gate 3 completed successfully"
}

# Scenario 2: Generate handoff on decision
@test "Given a decision is made, When decision trigger fires, Then handoff captures the decision" {
    # Given - decision trigger

    # When
    run generate_handoff "decision" "ADR-17: Use file-based checkpoint storage"

    # Then
    assert_success
    assert_file_exists "${HANDOFF_FILE}"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "decision"
    assert_output --partial "ADR-17"
}

# Scenario 3: Generate handoff on timer
@test "Given 30 minutes without progress, When timer trigger fires, Then handoff is generated for context preservation" {
    # Given - timer trigger

    # When
    run generate_handoff "timer" "30 minute timeout - no progress detected"

    # Then
    assert_success
    assert_file_exists "${HANDOFF_FILE}"

    run cat "${HANDOFF_FILE}"
    assert_output --partial "timer"
    assert_output --partial "30 minute timeout"
}

#######################################
# Feature: Checkpoint Management
#######################################

# Scenario 4: Save checkpoint during stage progress
@test "Given a stage is active, When checkpoint is saved, Then all state is preserved" {
    # Given - stage active

    # When
    run save_checkpoint "stage-3" "Context Recovery Enhancement" 75

    # Then
    assert_success
    assert_file_exists "${CHECKPOINT_FILE}"

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"stage-3"'
    assert_output --partial '"Context Recovery Enhancement"'
    assert_output --partial '"progress"'
}

# Scenario 5: Update gate status
@test "Given a checkpoint exists, When gate status is updated, Then checkpoint reflects new status" {
    # Given
    save_checkpoint "stage-3" "Test" 50

    # When
    run update_gate "gate_1" "completed"

    # Then
    assert_success

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"gate_1"'
    assert_output --partial 'completed'
}

# Scenario 6: Load checkpoint for recovery
@test "Given a saved checkpoint, When recovery is needed, Then checkpoint loads successfully" {
    # Given
    save_checkpoint "stage-3" "Context Recovery" 60
    update_gate "gate_1" "completed"
    update_gate "gate_2" "completed"

    # When
    run load_checkpoint

    # Then
    assert_success
    assert_output --partial "RDD Checkpoint State"
    assert_output --partial "stage-3"
    assert_output --partial "Gate 1"
    assert_output --partial "Gate 2"
}

#######################################
# Feature: Recovery Detection
#######################################

# Scenario 7: Detect recovery is needed
@test "Given an in-progress checkpoint exists, When checking recovery status, Then needs_recovery returns true" {
    # Given
    save_checkpoint "stage-3" "Test" 50

    # When
    run needs_recovery

    # Then
    assert_output "true"
}

# Scenario 8: No recovery needed when complete
@test "Given no checkpoint exists, When checking recovery status, Then needs_recovery returns false" {
    # Given - no checkpoint
    rm -f "${CHECKPOINT_FILE}"

    # When
    run needs_recovery

    # Then
    assert_output "false"
}

#######################################
# Feature: Full Recovery Flow
#######################################

# Scenario 9: Complete recovery workflow
@test "Given a session ended with checkpoint and handoff, When new session starts, Then recovery information is available" {
    # Given - Simulate session ending
    save_checkpoint "stage-3" "Context Recovery Enhancement" 80
    update_gate "gate_1" "completed"
    update_gate "gate_2" "completed"
    generate_handoff "manual" "Session ended"

    # When - Simulate new session recovery
    run handoff_exists
    assert_output "true"

    run needs_recovery
    assert_output "true"

    # Then
    run show_handoff
    assert_success
    assert_output --partial "RDD Handoff Document"

    run show_checkpoint
    assert_success
    assert_output --partial "stage-3"
}

# Scenario 10: Clear recovery state after successful recovery
@test "Given recovery state exists, When recovery is complete, Then recovery state can be cleared" {
    # Given
    save_checkpoint "stage-3" "Test" 100
    generate_handoff "manual" "Test"

    # When
    run clear_checkpoint
    assert_success

    run clear_handoff
    assert_success

    # Then
    refute_file_exists "${CHECKPOINT_FILE}"
    refute_file_exists "${HANDOFF_FILE}"

    run needs_recovery
    assert_output "false"
}

#######################################
# Feature: Handoff Validation
#######################################

# Scenario 11: Validate complete handoff document
@test "Given a complete handoff document, When validation runs, Then all checks pass" {
    # Given
    generate_handoff "manual" "Test validation"

    # When
    run validate_handoff

    # Then
    assert_success
    assert_output --partial "valid"
}

# Scenario 12: Handoff contains essential sections
@test "Given a generated handoff, When content is examined, Then all required sections are present" {
    # Given
    generate_handoff "manual" "Test sections"

    # When/Then
    run cat "${HANDOFF_FILE}"

    # Required sections
    assert_output --partial "## Current Progress"
    assert_output --partial "## Completed Evidence"
    assert_output --partial "## Blockers and Risks"
    assert_output --partial "## Next Single Action"
    assert_output --partial "## Degradation Strategy"
    assert_output --partial "## Recovery Instructions"
    assert_output --partial "## Verification Checklist"

    # Required information
    assert_output --partial "task doctor"
    assert_output --partial "task test"
    assert_output --partial "docs/11-next-steps.md"
    assert_output --partial "docs/08-autonomous-decisions.md"
}

#######################################
# Feature: Recovery Counter
#######################################

# Scenario 13: Track recovery attempts
@test "Given multiple recovery attempts, When incrementing recovery count, Then counter increases" {
    # Given
    save_checkpoint "stage-3" "Test" 50

    # When - First recovery
    increment_recovery_count
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"recovery_count": 1'

    # Second recovery
    increment_recovery_count
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"recovery_count": 2'

    # Third recovery
    increment_recovery_count
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"recovery_count": 3'
}

#######################################
# Feature: Decision History
#######################################

# Scenario 14: Record decisions during stage
@test "Given decisions are made, When adding to checkpoint, Then decisions are preserved" {
    # Given
    init_checkpoint

    # When
    run add_decision "ADR-17" "Use file-based checkpoint storage"
    assert_success

    run add_decision "ADR-18" "Use JSON format for checkpoints"
    assert_success

    # Then
    assert_file_exists "${CHECKPOINT_FILE}"
}

#######################################
# Feature: Blocker Tracking
#######################################

# Scenario 15: Track blockers
@test "Given a blocker is encountered, When adding to checkpoint, Then blocker is recorded" {
    # Given
    init_checkpoint

    # When
    run add_blocker "BLK-001" "Test environment unavailable" "P0"
    assert_success

    # Then
    assert_file_exists "${CHECKPOINT_FILE}"
}

# Scenario 16: Clear resolved blocker
@test "Given a blocker exists, When it is resolved, Then blocker can be cleared" {
    # Given
    init_checkpoint
    add_blocker "BLK-001" "Test blocker"

    # When
    run clear_blocker "BLK-001"

    # Then
    assert_success
}

#######################################
# Feature: Integration with Task System
#######################################

# Scenario 17: Task recovery:check command
@test "Given checkpoint exists, When running recovery:check, Then recovery status is shown" {
    # Given
    export CHECKPOINT_FILE="${CHECKPOINT_FILE}"
    export CACHE_DIR="${CACHE_DIR}"
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 50 > /dev/null 2>&1

    # When
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" needs-recovery

    # Then
    assert_output "true"
}

# Scenario 18: Task recovery:load command
@test "Given checkpoint and handoff exist, When running recovery:load, Then both are displayed" {
    # Given
    export CHECKPOINT_FILE="${CHECKPOINT_FILE}"
    export HANDOFF_FILE="${HANDOFF_FILE}"
    export CACHE_DIR="${CACHE_DIR}"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 50 > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Test" > /dev/null 2>&1

    # When
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_success
    assert_output --partial "RDD Checkpoint State"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" show
    assert_success
    assert_output --partial "RDD Handoff Document"
}

# Scenario 19: Task recovery:save command
@test "Given a session is active, When running recovery:save, Then both checkpoint and handoff are saved" {
    # Given - active session
    export CHECKPOINT_FILE="${CHECKPOINT_FILE}"
    export HANDOFF_FILE="${HANDOFF_FILE}"
    export CACHE_DIR="${CACHE_DIR}"

    # When
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery" 50
    assert_success
    assert_file_exists "${CHECKPOINT_FILE}"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Manual save"
    assert_success
    assert_file_exists "${HANDOFF_FILE}"

    # Then
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial '"stage-3"'

    run cat "${HANDOFF_FILE}"
    assert_output --partial "manual"
}

#######################################
# Feature: Gate Status Tracking
#######################################

# Scenario 20: All gates start as pending
@test "Given a new checkpoint, When examining gates, Then all gates are pending" {
    # Given
    init_checkpoint

    # When
    run cat "${CHECKPOINT_FILE}"

    # Then
    assert_output --partial '"gate_1": {"status": "pending"'
    assert_output --partial '"gate_2": {"status": "pending"'
    assert_output --partial '"gate_3": {"status": "pending"'
    assert_output --partial '"gate_4": {"status": "pending"'
    assert_output --partial '"gate_5": {"status": "pending"'
}

# Scenario 21: Track gate completion order
@test "Given gates are completed in order, When checking status, Then progress is tracked" {
    # Given
    save_checkpoint "stage-3" "Test" 20

    # When - Gate 1 complete
    update_gate "gate_1" "completed"

    # Verify gate_1 is marked as completed
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'completed'
    assert_output --partial 'gate_1'

    # Gate 2 complete
    update_gate "gate_2" "completed"

    # Verify both gates are marked
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'gate_2'

    # Gate 3 complete
    update_gate "gate_3" "completed"

    # Verify gate_3 is marked
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial 'gate_3'
}
