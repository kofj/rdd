#!/usr/bin/env bats
#
# Unit tests for stages-archive.sh
# Tests stages archive functionality

load '../lib/bats-support/load'
load '../lib/bats-assert/load'

setup() {
  RDD_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.rdd"
  export RDD_DIR

  # Create temp workspace
  TEST_ROOT="$(mktemp -d)"
  export TEST_ROOT

  mkdir -p "$TEST_ROOT/docs/stages"
  mkdir -p "$TEST_ROOT/.rdd"

  # Write a minimal roadmap with some completed and some incomplete stages
  cat > "$TEST_ROOT/docs/stages/stage-roadmap.md" <<'ROADMAP'
# Stage Roadmap

## Phase 1

| Stage | Status | Title |
|-------|--------|-------|
| Stage 1 | ✅ Completed | First stage |
| Stage 2 | ✅ Completed | Second stage |
| Stage 3 | ✅ Completed | Third stage |
| Stage 4 | ❌ In Progress | Fourth (not done) |
| Stage 5 | ✅ Completed | Fifth stage |

## Phase 2

| Stage | Status | Title |
|-------|--------|-------|
| Stage 6 | ✅ Completed | Sixth stage |
| Stage 7 | ✅ Completed | Seventh stage |
| Stage 8 | ✅ Completed | Eighth stage |
ROADMAP

  # Override paths for testing
  export STAGES_DIR="$TEST_ROOT/docs/stages"
  export ROADMAP_FILE="$TEST_ROOT/docs/stages/stage-roadmap.md"
  export ARCHIVE_DIR="$STAGES_DIR/archived"

  # Source the script (won't run main due to source guard)
  source "${RDD_DIR}/scripts/stages-archive.sh"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

#######################################
# get_completed_stages tests
#######################################

@test "stages-archive: get_completed_stages returns completed stage numbers" {
  run get_completed_stages
  [ "$status" -eq 0 ]
  # Completed: 1,2,3,5,6,7,8  (not 4)
  [[ "$output" =~ "1" ]]
  [[ "$output" =~ "5" ]]
  [[ "$output" =~ "8" ]]
  # Stage 4 is not completed
  ! [[ "$output" =~ "4" ]]
}

@test "stages-archive: get_completed_stages errors on missing roadmap" {
  ROADMAP_FILE="/nonexistent/roadmap.md"
  run get_completed_stages
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

#######################################
# get_stage_files tests
#######################################

@test "stages-archive: get_stage_files returns only pure numeric stage-N.md" {
  # Create stage files
  touch "$STAGES_DIR/stage-1.md"
  touch "$STAGES_DIR/stage-2.md"
  touch "$STAGES_DIR/stage-6-design.md"
  touch "$STAGES_DIR/stage-7-audit.md"
  touch "$STAGES_DIR/stage-roadmap.md"
  touch "$STAGES_DIR/stage-template.md"

  run get_stage_files

  [[ "$output" =~ "stage-1.md" ]]
  [[ "$output" =~ "stage-2.md" ]]
  ! [[ "$output" =~ "stage-6-design" ]]
  ! [[ "$output" =~ "stage-7-audit" ]]
  ! [[ "$output" =~ "stage-roadmap" ]]
  ! [[ "$output" =~ "stage-template" ]]
}

@test "stages-archive: get_stage_files returns empty when no stage files" {
  run get_stage_files
  [ "$status" -eq 0 ]
  [[ -z "$output" ]]
}

#######################################
# Archive logic tests (integration)
#######################################

@test "stages-archive: keeps 5 most recent completed and all incomplete" {
  # Create stage files: 1-8 with completed: 1,2,3,5,6,7,8 (not 4)
  for i in 1 2 3 4 5 6 7 8; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  # Run archive (keeping top 5 completed)
  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  # Completed sorted desc: 8,7,6,5,3,2,1
  # Keep top 5: 8,7,6,5,3
  # Archive: 1,2
  # Incomplete kept: 4

  # Kept files
  [ -f "$STAGES_DIR/stage-8.md" ]
  [ -f "$STAGES_DIR/stage-7.md" ]
  [ -f "$STAGES_DIR/stage-6.md" ]
  [ -f "$STAGES_DIR/stage-5.md" ]
  [ -f "$STAGES_DIR/stage-3.md" ]
  [ -f "$STAGES_DIR/stage-4.md" ]  # incomplete → kept

  # Archived files
  [ -f "$ARCHIVE_DIR/stage-1.md" ]
  [ -f "$ARCHIVE_DIR/stage-2.md" ]
}

@test "stages-archive: fewer than keep_count completed stages keeps all" {
  # Only 2 completed stages, 1 incomplete
  cat > "$ROADMAP_FILE" <<'ROADMAP'
| Stage | Status | Title |
|-------|--------|-------|
| Stage 1 | ✅ Completed | First |
| Stage 2 | ✅ Completed | Second |
| Stage 3 | ❌ Planning | Third |
ROADMAP

  for i in 1 2 3; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  # All 3 should be kept (2 completed < 5 keep, 1 incomplete)
  [ -f "$STAGES_DIR/stage-1.md" ]
  [ -f "$STAGES_DIR/stage-2.md" ]
  [ -f "$STAGES_DIR/stage-3.md" ]

  # Nothing archived
  ! [ -d "$ARCHIVE_DIR" ] || [ -z "$(ls -A "$ARCHIVE_DIR" 2>/dev/null)" ]
}

@test "stages-archive: all incomplete stages kept — nothing archived" {
  cat > "$ROADMAP_FILE" <<'ROADMAP'
| Stage | Status | Title |
|-------|--------|-------|
| Stage 1 | ❌ Planning | Not done |
| Stage 2 | ❌ In Progress | Also not done |
ROADMAP

  for i in 1 2; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  # Both should be kept
  [ -f "$STAGES_DIR/stage-1.md" ]
  [ -f "$STAGES_DIR/stage-2.md" ]

  # Nothing in archive
  [[ "$output" =~ "nothing to archive" ]]
}

@test "stages-archive: non-stage-N.md files untouched" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done
  touch "$STAGES_DIR/stage-6-design.md"
  touch "$STAGES_DIR/stage-7-audit.md"
  touch "$STAGES_DIR/stage-roadmap.md"

  KEEP_COUNT=3
  run do_archive
  [ "$status" -eq 0 ]

  # Non-numeric files should stay
  [ -f "$STAGES_DIR/stage-6-design.md" ]
  [ -f "$STAGES_DIR/stage-7-audit.md" ]
  [ -f "$STAGES_DIR/stage-roadmap.md" ]
}

@test "stages-archive: creates archive directory if missing" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  [ -d "$ARCHIVE_DIR" ]
}

@test "stages-archive: no-op when nothing to archive" {
  # All stages within keep threshold
  cat > "$ROADMAP_FILE" <<'ROADMAP'
| Stage | Status | Title |
|-------|--------|-------|
| Stage 1 | ✅ Completed | Only stage |
ROADMAP

  touch "$STAGES_DIR/stage-1.md"
  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Nothing to archive" ]]
}

@test "stages-archive: handles empty stages directory" {
  run do_archive
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nothing to do" ]]
}

@test "stages-archive: skips files already in archive" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  # Pre-create archive with stage-1 already there
  mkdir -p "$ARCHIVE_DIR"
  touch "$ARCHIVE_DIR/stage-1.md"

  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  # stage-1 should have been skipped (already in archive)
  [[ "$output" =~ "skipping" ]]
  [[ "$output" =~ "stage-1" ]]
}

#######################################
# Dry-run tests
#######################################

@test "stages-archive: dry-run does not move files" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  DRY_RUN=true
  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  # Files should still be in stages dir
  [ -f "$STAGES_DIR/stage-1.md" ]
  [ -f "$STAGES_DIR/stage-2.md" ]

  # Archive dir should not exist (we never mkdir in dry-run)
  [[ "$output" =~ "DRY-RUN" ]]
}

@test "stages-archive: dry-run shows preview messages" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  DRY_RUN=true
  KEEP_COUNT=5
  run do_archive
  [ "$status" -eq 0 ]

  [[ "$output" =~ "DRY-RUN" ]]
  [[ "$output" =~ "Would move" ]]
}

#######################################
# CLI interface tests
#######################################

@test "stages-archive: --help shows usage" {
  run main --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Options:" ]]
}

@test "stages-archive: unknown flag exits with error" {
  run main --unknown-flag 2>&1
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "stages-archive: --keep with non-numeric value exits with error" {
  run main --keep abc 2>&1
  [ "$status" -eq 1 ]
  [[ "$output" =~ "positive integer" ]]
}

@test "stages-archive: --keep with valid value accepts it" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    touch "$STAGES_DIR/stage-${i}.md"
  done

  # With keep=3, only the top 3 completed are kept
  run main --keep 3
  [ "$status" -eq 0 ]

  # Completed (1,2,3,5,6,7,8,9,10). Top 3 kept: 10,9,8. Also kept: 4 (incomplete)
  # So 1,2,3,5,6,7 archived
  [ -f "$STAGES_DIR/stage-10.md" ]
  [ -f "$STAGES_DIR/stage-9.md" ]
  [ -f "$STAGES_DIR/stage-8.md" ]
  [ -f "$STAGES_DIR/stage-4.md" ]

  [ -f "$ARCHIVE_DIR/stage-1.md" ]
}

#######################################
# Taskfile integration tests
#######################################

@test "stages-archive: task stages:archive --dry-run exits 0" {
  # Use the real script with --dry-run against a temp dir via env vars
  STAGES_DIR="$TEST_ROOT/docs/stages" \
  ROADMAP_FILE="$TEST_ROOT/docs/stages/stage-roadmap.md" \
  run bash "${RDD_DIR}/scripts/stages-archive.sh" --dry-run
  [ "$status" -eq 0 ]
}

@test "stages-archive: task stages:archive --help exits 0" {
  run bash "${RDD_DIR}/scripts/stages-archive.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}
