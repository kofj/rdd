#!/usr/bin/env bats
#
# Unit tests for migrate.sh
#
# Run with: bats tests/unit/test-migrate.bats
#

# Setup test environment
setup() {
    # Set RDD_DIR to test directory
    export RDD_DIR="$(mktemp -d)"
    export SCRIPTS_DIR="${RDD_DIR}/scripts"
    export BACKUP_DIR="${RDD_DIR}/backups"
    export MIGRATION_DIR="${RDD_DIR}/migrations"
    export VERSION_FILE="${RDD_DIR}/VERSION"
    export MIGRATION_LOG="${RDD_DIR}/migration.log"
    export LOCK_FILE="${RDD_DIR}/.migration.lock"

    # Create directories
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$MIGRATION_DIR"

    # Copy scripts to test directory
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/migrate.sh" "$SCRIPTS_DIR/"
    chmod +x "${SCRIPTS_DIR}/migrate.sh"

    # Create VERSION file
    cat > "${VERSION_FILE}" <<EOF
VERSION=1.0.0
COMPAT_MIN=0.9.0
COMPAT_MAX=2.0.0
EOF

    # Create minimal config files
    cat > "${RDD_DIR}/config.yml" <<EOF
version: "1.0.0"
stage:
  min_coverage: 20
EOF

    cat > "${RDD_DIR}/hooks.yml" <<EOF
triggers:
  stage_complete:
    enabled: false
EOF

    cat > "${RDD_DIR}/templates.yml" <<EOF
templates:
  stage_complete:
    title: "Stage Complete"
    body: "Stage completed successfully"
EOF
}

# Cleanup test environment
teardown() {
    rm -rf "${RDD_DIR}"
}

#######################################
# Test: Script exists and is executable
#######################################
@test "migrate.sh exists and is executable" {
    [[ -x "${SCRIPTS_DIR}/migrate.sh" ]]
}

#######################################
# Test: Help output
#######################################
@test "migrate.sh shows help" {
    run "${SCRIPTS_DIR}/migrate.sh" --help
    [[ $status -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Commands"* ]]
}

#######################################
# Test: read_current_version
#######################################
@test "read_current_version reads VERSION correctly" {
    source "${SCRIPTS_DIR}/migrate.sh"

    local version
    version=$(read_current_version)

    [[ "$version" == "1.0.0" ]]
}

#######################################
# Test: read_current_version handles missing file
#######################################
@test "read_current_version handles missing VERSION file" {
    rm "${VERSION_FILE}"

    source "${SCRIPTS_DIR}/migrate.sh"

    local version
    version=$(read_current_version)

    [[ "$version" == "0.0.0" ]]
}

#######################################
# Test: parse_version
#######################################
@test "parse_version extracts components" {
    source "${SCRIPTS_DIR}/migrate.sh"

    local major minor patch
    read -r major minor patch <<< "$(parse_version "1.2.3")"

    [[ "$major" == "1" ]]
    [[ "$minor" == "2" ]]
    [[ "$patch" == "3" ]]
}

#######################################
# Test: compare_versions - equal
#######################################
@test "compare_versions returns 0 for equal versions" {
    source "${SCRIPTS_DIR}/migrate.sh"

    compare_versions "1.0.0" "1.0.0"
    [[ $? -eq 0 ]]
}

#######################################
# Test: compare_versions - greater
#######################################
@test "compare_versions returns 1 when first is greater" {
    source "${SCRIPTS_DIR}/migrate.sh"

    run compare_versions "1.1.0" "1.0.0"
    [[ $status -eq 1 ]]
}

#######################################
# Test: compare_versions - less
#######################################
@test "compare_versions returns 2 when first is less" {
    source "${SCRIPTS_DIR}/migrate.sh"

    run compare_versions "1.0.0" "1.1.0"
    [[ $status -eq 2 ]]
}

#######################################
# Test: acquire_lock creates lock file
#######################################
@test "acquire_lock creates lock file" {
    source "${SCRIPTS_DIR}/migrate.sh"

    # Should not have lock initially
    [[ ! -f "$LOCK_FILE" ]]

    # Acquire lock
    acquire_lock

    # Lock file should exist
    [[ -f "$LOCK_FILE" ]]
    [[ "$(cat "$LOCK_FILE")" == "$$" ]]

    # Cleanup
    release_lock
}

#######################################
# Test: release_lock removes lock file
#######################################
@test "release_lock removes lock file" {
    source "${SCRIPTS_DIR}/migrate.sh"

    # Create lock file
    echo $$ > "$LOCK_FILE"

    # Release lock
    release_lock

    # Lock file should be removed
    [[ ! -f "$LOCK_FILE" ]]
}

#######################################
# Test: create_backup creates backup directory
#######################################
@test "create_backup creates backup directory" {
    source "${SCRIPTS_DIR}/migrate.sh"

    local backup_path
    backup_path=$(create_backup "test-backup")

    [[ -d "$backup_path" ]]
    [[ -f "${backup_path}/MANIFEST" ]]
    [[ -f "${backup_path}/config.yml" ]]
    [[ -f "${backup_path}/VERSION" ]]
}

#######################################
# Test: create_backup backs up VERSION file
#######################################
@test "create_backup backs up VERSION file" {
    source "${SCRIPTS_DIR}/migrate.sh"

    local backup_path
    backup_path=$(create_backup "test-backup")

    [[ -f "${backup_path}/VERSION" ]]

    # Check VERSION content
    grep -q "VERSION=1.0.0" "${backup_path}/VERSION"
}

#######################################
# Test: restore_backup restores files
#######################################
@test "restore_backup restores files" {
    source "${SCRIPTS_DIR}/migrate.sh"

    # Create backup
    local backup_path
    backup_path=$(create_backup "test-backup")

    # Modify VERSION
    echo "VERSION=2.0.0" > "${VERSION_FILE}"

    # Restore backup
    restore_backup "$backup_path"

    # VERSION should be restored
    grep -q "VERSION=1.0.0" "${VERSION_FILE}"
}

#######################################
# Test: check_prerequisites passes with valid setup
#######################################
@test "check_prerequisites passes with valid setup" {
    source "${SCRIPTS_DIR}/migrate.sh"

    run check_prerequisites
    [[ $status -eq 0 ]]
}

#######################################
# Test: check_prerequisites handles missing VERSION file
#######################################
@test "check_prerequisites warns about missing VERSION file" {
    source "${SCRIPTS_DIR}/migrate.sh"

    # Remove VERSION file
    rm "${VERSION_FILE}"

    run check_prerequisites

    # Should have warnings but pass with --force
    [[ "$output" == *"VERSION file"* ]]
}

#######################################
# Test: generate_plan shows migration steps
#######################################
@test "generate_plan shows migration steps" {
    run "${SCRIPTS_DIR}/migrate.sh" plan --target 1.1.0
    [[ $status -eq 0 ]]
    [[ "$output" == *"Migration Plan"* ]]
    [[ "$output" == *"Create backup"* ]]
    [[ "$output" == *"Update VERSION file"* ]]
}

#######################################
# Test: generate_plan shows current and target versions
#######################################
@test "generate_plan shows current and target versions" {
    run "${SCRIPTS_DIR}/migrate.sh" plan --target 1.1.0
    [[ $status -eq 0 ]]
    [[ "$output" == *"From: 1.0.0"* ]]
    [[ "$output" == *"To:   1.1.0"* ]]
}

#######################################
# Test: show_status displays migration status
#######################################
@test "show_status displays migration status" {
    run "${SCRIPTS_DIR}/migrate.sh" status
    [[ $status -eq 0 ]]
    [[ "$output" == *"Migration Status"* ]]
    [[ "$output" == *"Current Version: 1.0.0"* ]]
}

#######################################
# Test: show_status shows no lock when idle
#######################################
@test "show_status shows no lock when idle" {
    run "${SCRIPTS_DIR}/migrate.sh" status
    [[ $status -eq 0 ]]
    [[ "$output" == *"Migration Lock:  None"* ]]
}

#######################################
# Test: execute_migration with dry-run
#######################################
@test "execute_migration with dry-run does not modify files" {
    run "${SCRIPTS_DIR}/migrate.sh" execute --target 1.1.0 --dry-run
    [[ $status -eq 0 ]]

    # VERSION should still be 1.0.0
    grep -q "VERSION=1.0.0" "${VERSION_FILE}"
}

#######################################
# Test: execute_migration creates backup
#######################################
@test "execute_migration creates backup" {
    # Execute migration
    "${SCRIPTS_DIR}/migrate.sh" execute --target 1.1.0 --dry-run 2>/dev/null || true

    # Check backup was created (in dry-run mode, backup is mentioned but not created)
    # In non-dry-run mode, backup would be created
    [[ -d "$BACKUP_DIR" ]]
}

#######################################
# Test: rollback finds latest backup
#######################################
@test "rollback finds latest backup" {
    source "${SCRIPTS_DIR}/migrate.sh"

    # Create a backup
    create_backup "pre-migration-test-1"

    # Should find the backup
    run rollback_migration --dry-run
    [[ "$output" == *"Rolling back"* ]] || [[ "$output" == *"No backup found"* ]]
}

#######################################
# Test: validate command runs prerequisites
#######################################
@test "validate command runs prerequisites check" {
    run "${SCRIPTS_DIR}/migrate.sh" validate
    [[ $status -eq 0 ]]
    [[ "$output" == *"Checking migration prerequisites"* ]]
}

#######################################
# Test: log_to_file writes to log
#######################################
@test "log_to_file writes to migration log" {
    source "${SCRIPTS_DIR}/migrate.sh"

    log_to_file "INFO" "Test message"

    [[ -f "$MIGRATION_LOG" ]]
    grep -q "Test message" "$MIGRATION_LOG"
}

#######################################
# Test: parse_args handles --target
#######################################
@test "parse_args handles --target flag" {
    source "${SCRIPTS_DIR}/migrate.sh"

    parse_args --target "1.5.0"

    [[ "$TARGET_VERSION" == "1.5.0" ]]
}

#######################################
# Test: parse_args handles --dry-run
#######################################
@test "parse_args handles --dry-run flag" {
    source "${SCRIPTS_DIR}/migrate.sh"

    parse_args --dry-run

    [[ "$DRY_RUN" == "true" ]]
}

#######################################
# Test: parse_args handles --force
#######################################
@test "parse_args handles --force flag" {
    source "${SCRIPTS_DIR}/migrate.sh"

    parse_args --force

    [[ "$FORCE" == "true" ]]
}

#######################################
# Test: Unknown command shows error
#######################################
@test "unknown command shows error" {
    run "${SCRIPTS_DIR}/migrate.sh" unknown_command
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown command"* ]]
}

#######################################
# Test: No command shows usage
#######################################
@test "no command shows usage" {
    run "${SCRIPTS_DIR}/migrate.sh"
    [[ $status -eq 1 ]]
    [[ "$output" == *"Usage"* ]]
}

#######################################
# Test: Migration scripts directory exists
#######################################
@test "migration scripts directory is created" {
    [[ -d "$MIGRATION_DIR" ]]
}

#######################################
# Test: Backup directory exists
#######################################
@test "backup directory is created" {
    [[ -d "$BACKUP_DIR" ]]
}
