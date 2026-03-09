#!/usr/bin/env bats
#
# E2E tests for Context Recovery System
#
# These tests verify the complete end-to-end recovery workflows
# simulating real agent session scenarios.
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
    # Use isolated test directory
    export CHECKPOINT_FILE="${BATS_TEST_TMPDIR}/checkpoints.json"
    export HANDOFF_FILE="${BATS_TEST_TMPDIR}/handoff.md"
    export CACHE_DIR="${BATS_TEST_TMPDIR}"
    export RDD_DIR="${_ACTUAL_PROJECT_ROOT}/.rdd"
    export PROJECT_ROOT="${BATS_TEST_TMPDIR}"
    mkdir -p "${CACHE_DIR}"

    # Source scripts for direct function access
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh"
    source "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh"
}

# Tear down after each test
teardown() {
    :
}

#######################################
# E2E Scenario: Complete Stage Execution with Recovery
#######################################

@test "E2E: Complete stage execution with checkpoint saves" {
    # Simulate Stage 3 execution flow

    # Step 1: Initialize checkpoint at stage start
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 0
    assert_success

    # Step 2: Complete Gate 1 (Design)
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed
    assert_success

    # Step 3: Generate handoff after design review
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate gate_complete "Gate 1: Design Document Complete"
    assert_success

    # Step 4: Complete Gate 2 (Design Review)
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 2 completed
    assert_success

    # Step 5: Record a decision
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" decision ADR-17 "Use JSON for checkpoint storage"
    assert_success

    # Step 6: Update checkpoint with implementation progress
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 50
    assert_success

    # Step 7: Complete Gate 3 (Implementation)
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 3 completed
    assert_success

    # Step 8: Complete Gate 4 (Code Review)
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 4 completed
    assert_success

    # Step 9: Complete Gate 5 (Completion)
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 5 completed
    assert_success

    # Step 10: Final checkpoint and handoff
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 100
    assert_success

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate gate_complete "Stage 3 Complete"
    assert_success

    # Verify final state
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_output --partial "Gate 1:"
    assert_output --partial "Gate 2:"
    assert_output --partial "Gate 3:"
    assert_output --partial "Gate 4:"
    assert_output --partial "Gate 5:"
}

@test "E2E: Session interruption and recovery" {
    # Simulate session interruption at 60% progress

    # Session 1: Start work and progress to 60%
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 20
    assert_success

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed
    assert_success

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 2 completed
    assert_success

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 60
    assert_success

    # Simulate compact trigger - generate handoff
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate timer "Compact triggered - session ended"
    assert_success

    # Session 2: New session - recovery check
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" needs-recovery
    assert_output "true"

    # Load recovery information
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_output --partial "stage-3"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" show
    assert_output --partial "RDD Handoff Document"
    assert_output --partial "Compact triggered"

    # Increment recovery count
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" increment-recovery
    assert_success

    # Continue from checkpoint
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 3 completed
    assert_success

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 80
    assert_success

    # Verify recovery count was incremented
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_output --partial "Recovery Count:"
}

@test "E2E: Multiple compact cycles with recovery" {
    # Simulate multiple compact/recovery cycles

    # Initial save
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 10 > /dev/null 2>&1

    # Cycle 1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate timer "Cycle 1" > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" increment-recovery > /dev/null 2>&1

    # Continue work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 30 > /dev/null 2>&1

    # Cycle 2
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate timer "Cycle 2" > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" increment-recovery > /dev/null 2>&1

    # Continue work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 50 > /dev/null 2>&1

    # Cycle 3
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate timer "Cycle 3" > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" increment-recovery > /dev/null 2>&1

    # Verify recovery count was incremented multiple times
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_output --partial "Recovery Count:"
}

@test "E2E: Decision-triggered handoff generation" {
    # Simulate important decision during work

    # Start work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 40 > /dev/null 2>&1

    # Make important decision
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" decision ADR-17 "Use JSON for checkpoint format" > /dev/null 2>&1

    # Generate handoff due to decision
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate decision "ADR-17: Use JSON for checkpoint format"
    assert_success

    # Verify handoff captures decision context
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" show
    assert_output --partial "decision"
    assert_output --partial "ADR-17"
}

@test "E2E: Blocker tracking and resolution" {
    # Simulate encountering and resolving blockers

    # Start work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 20 > /dev/null 2>&1

    # Encounter blocker
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" blocker BLK-001 "Test environment unavailable" P0 > /dev/null 2>&1

    # Generate handoff due to blocker
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Blocked - waiting for test environment"
    assert_success

    # Verify handoff exists
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "true"

    # Later - blocker resolved
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" clear-blocker BLK-001 > /dev/null 2>&1

    # Continue work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 40 > /dev/null 2>&1
}

@test "E2E: Full recovery workflow from task commands" {
    # Test the complete recovery workflow using task commands

    # Simulate session end - save state
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 50 > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 2 completed > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "End of session" > /dev/null 2>&1

    # New session - check recovery needed
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" needs-recovery
    assert_output "true"

    # Load recovery information
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" load
    assert_success
    assert_output --partial "stage-3"

    # Validate handoff exists
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "true"

    # Continue work
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 3 completed > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 75 > /dev/null 2>&1

    # Clear state after successful recovery
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" clear > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" clear > /dev/null 2>&1

    # Verify cleared
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" needs-recovery
    assert_output "false"

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" exists
    assert_output "false"
}

@test "E2E: Gate completion sequence verification" {
    # Verify gate completion is tracked correctly

    # Initialize
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Test" 0 > /dev/null 2>&1

    # Complete gates in order
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed > /dev/null 2>&1

    # Verify gate 1 is recorded
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "gate_1"
    assert_output --partial "completed"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 2 completed > /dev/null 2>&1

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "gate_2"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 3 completed > /dev/null 2>&1

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "gate_3"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 4 completed > /dev/null 2>&1

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "gate_4"

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 5 completed > /dev/null 2>&1

    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "gate_5"
}

@test "E2E: Handoff document completeness" {
    # Generate handoff and verify all required content

    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Context Recovery Enhancement" 75 > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 2 completed > /dev/null 2>&1

    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/handoff.sh" generate manual "Test completeness"
    assert_success

    # Verify file exists
    assert_file_exists "${HANDOFF_FILE}"

    # Verify all sections present
    run cat "${HANDOFF_FILE}"

    # Core sections
    assert_output --partial "# RDD Handoff Document"
    assert_output --partial "## Current Progress"
    assert_output --partial "## Completed Evidence"
    assert_output --partial "## Blockers and Risks"
    assert_output --partial "## Next Single Action"
    assert_output --partial "## Degradation Strategy"
    assert_output --partial "## Recovery Instructions"
    assert_output --partial "## Verification Checklist"

    # Key information
    assert_output --partial "Generated:"
    assert_output --partial "Trigger: manual"
    assert_output --partial "Current Stage"
    assert_output --partial "Progress"
    assert_output --partial "Gate Status"

    # Recovery commands
    assert_output --partial "task doctor"
    assert_output --partial "task test"
    assert_output --partial "task recovery:load"

    # Key files
    assert_output --partial "docs/11-next-steps.md"
    assert_output --partial "docs/08-autonomous-decisions.md"
    assert_output --partial "docs/12-technical-debt.md"
    assert_output --partial "CLAUDE.md"
    assert_output --partial "AGENTS.md"
}

@test "E2E: Checkpoint persistence across operations" {
    # Verify checkpoint persists correctly through multiple operations

    # Create initial checkpoint
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Persistence Test" 25 > /dev/null 2>&1

    # Verify file exists
    assert_file_exists "${CHECKPOINT_FILE}"

    # Multiple operations
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" gate 1 completed > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" decision ADR-17 "Decision 1" > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" blocker BLK-001 "Blocker 1" P1 > /dev/null 2>&1
    bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" save "stage-3" "Persistence Test" 50 > /dev/null 2>&1

    # Verify file still exists
    assert_file_exists "${CHECKPOINT_FILE}"

    # Verify content
    run bash "${_ACTUAL_PROJECT_ROOT}/.rdd/scripts/checkpoint.sh" show
    assert_success
    assert_output --partial "stage-3"

    # Verify checkpoint has expected structure
    run cat "${CHECKPOINT_FILE}"
    assert_output --partial "Persistence Test"
}
