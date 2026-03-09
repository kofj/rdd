#!/usr/bin/env bats
#
# Unit tests for version.sh
#
# Run with: bats tests/unit/test-version.bats
#

# Setup test environment
setup() {
    # Set RDD_DIR to test directory
    export RDD_DIR="$(mktemp -d)"
    export SCRIPTS_DIR="${RDD_DIR}/scripts"

    # Create directories
    mkdir -p "$SCRIPTS_DIR"

    # Copy scripts to test directory
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/version.sh" "$SCRIPTS_DIR/"
    chmod +x "${SCRIPTS_DIR}/version.sh"

    # Create VERSION file
    cat > "${RDD_DIR}/VERSION" <<EOF
VERSION=1.0.0
COMPAT_MIN=0.9.0
COMPAT_MAX=2.0.0
EOF
}

# Cleanup test environment
teardown() {
    rm -rf "${RDD_DIR}"
}

#######################################
# Test: Script exists and is executable
#######################################
@test "version.sh exists and is executable" {
    [[ -x "${SCRIPTS_DIR}/version.sh" ]]
}

#######################################
# Test: Help output
#######################################
@test "version.sh shows help" {
    run "${SCRIPTS_DIR}/version.sh" --help
    [[ $status -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Commands"* ]]
}

#######################################
# Test: read_version_file
#######################################
@test "read_version_file reads VERSION correctly" {
    source "${SCRIPTS_DIR}/version.sh"

    read_version_file

    [[ "$CURRENT_VERSION" == "1.0.0" ]]
    [[ "$COMPAT_MIN" == "0.9.0" ]]
    [[ "$COMPAT_MAX" == "2.0.0" ]]
}

#######################################
# Test: read_version_file handles missing file
#######################################
@test "read_version_file handles missing VERSION file" {
    rm "${RDD_DIR}/VERSION"

    source "${SCRIPTS_DIR}/version.sh"

    read_version_file

    [[ "$CURRENT_VERSION" == "0.0.0" ]]
}

#######################################
# Test: parse_version extracts components
#######################################
@test "parse_version extracts major minor patch" {
    source "${SCRIPTS_DIR}/version.sh"

    local major minor patch prerelease
    read -r major minor patch prerelease <<< "$(parse_version "1.2.3")"

    [[ "$major" == "1" ]]
    [[ "$minor" == "2" ]]
    [[ "$patch" == "3" ]]
    [[ -z "$prerelease" ]]
}

#######################################
# Test: parse_version handles prerelease
#######################################
@test "parse_version handles prerelease" {
    source "${SCRIPTS_DIR}/version.sh"

    local major minor patch prerelease
    read -r major minor patch prerelease <<< "$(parse_version "1.2.3-alpha.1")"

    [[ "$major" == "1" ]]
    [[ "$minor" == "2" ]]
    [[ "$patch" == "3" ]]
    [[ "$prerelease" == "alpha.1" ]]
}

#######################################
# Test: parse_version handles v prefix
#######################################
@test "parse_version handles v prefix" {
    source "${SCRIPTS_DIR}/version.sh"

    local major minor patch prerelease
    read -r major minor patch prerelease <<< "$(parse_version "v1.2.3")"

    [[ "$major" == "1" ]]
    [[ "$minor" == "2" ]]
    [[ "$patch" == "3" ]]
}

#######################################
# Test: compare_versions - equal
#######################################
@test "compare_versions returns 0 for equal versions" {
    source "${SCRIPTS_DIR}/version.sh"

    compare_versions "1.0.0" "1.0.0"
    [[ $? -eq 0 ]]
}

#######################################
# Test: compare_versions - greater
#######################################
@test "compare_versions returns 1 when first is greater" {
    source "${SCRIPTS_DIR}/version.sh"

    run compare_versions "1.1.0" "1.0.0"
    [[ $status -eq 1 ]]

    run compare_versions "2.0.0" "1.9.9"
    [[ $status -eq 1 ]]

    run compare_versions "1.0.1" "1.0.0"
    [[ $status -eq 1 ]]
}

#######################################
# Test: compare_versions - less
#######################################
@test "compare_versions returns 2 when first is less" {
    source "${SCRIPTS_DIR}/version.sh"

    run compare_versions "1.0.0" "1.1.0"
    [[ $status -eq 2 ]]

    run compare_versions "1.9.9" "2.0.0"
    [[ $status -eq 2 ]]

    run compare_versions "1.0.0" "1.0.1"
    [[ $status -eq 2 ]]
}

#######################################
# Test: validate_version - valid versions
#######################################
@test "validate_version accepts valid versions" {
    source "${SCRIPTS_DIR}/version.sh"

    validate_version "1.0.0"
    [[ $? -eq 0 ]]

    validate_version "0.0.1"
    [[ $? -eq 0 ]]

    validate_version "10.20.30"
    [[ $? -eq 0 ]]

    validate_version "1.0.0-alpha"
    [[ $? -eq 0 ]]

    validate_version "1.0.0-alpha.1"
    [[ $? -eq 0 ]]
}

#######################################
# Test: validate_version - invalid versions
#######################################
@test "validate_version rejects invalid versions" {
    source "${SCRIPTS_DIR}/version.sh"

    run validate_version "1.0"
    [[ $status -eq 1 ]]

    run validate_version "1"
    [[ $status -eq 1 ]]

    run validate_version "abc"
    [[ $status -eq 1 ]]

    run validate_version ""
    [[ $status -eq 1 ]]
}

#######################################
# Test: check_compatibility - within range
#######################################
@test "check_compatibility passes within range" {
    source "${SCRIPTS_DIR}/version.sh"

    run check_compatibility "1.0.0" "0.9.0" "2.0.0"
    [[ $status -eq 0 ]]
}

#######################################
# Test: check_compatibility - below minimum
#######################################
@test "check_compatibility fails below minimum" {
    source "${SCRIPTS_DIR}/version.sh"

    run check_compatibility "0.8.0" "0.9.0" "2.0.0"
    [[ $status -eq 1 ]]
}

#######################################
# Test: check_compatibility - above maximum
#######################################
@test "check_compatibility fails above maximum" {
    source "${SCRIPTS_DIR}/version.sh"

    run check_compatibility "3.0.0" "0.9.0" "2.0.0"
    [[ $status -eq 1 ]]
}

#######################################
# Test: bump_version - patch
#######################################
@test "bump_version increments patch correctly" {
    source "${SCRIPTS_DIR}/version.sh"

    local new_version
    new_version=$(bump_version "patch" "1.0.0")

    [[ "$new_version" == "1.0.1" ]]
}

#######################################
# Test: bump_version - minor
#######################################
@test "bump_version increments minor and resets patch" {
    source "${SCRIPTS_DIR}/version.sh"

    local new_version
    new_version=$(bump_version "minor" "1.2.3")

    [[ "$new_version" == "1.3.0" ]]
}

#######################################
# Test: bump_version - major
#######################################
@test "bump_version increments major and resets minor and patch" {
    source "${SCRIPTS_DIR}/version.sh"

    local new_version
    new_version=$(bump_version "major" "1.2.3")

    [[ "$new_version" == "2.0.0" ]]
}

#######################################
# Test: bump_version - prerelease
#######################################
@test "bump_version handles prerelease" {
    source "${SCRIPTS_DIR}/version.sh"

    local new_version
    new_version=$(bump_version "prerelease" "1.0.0")

    # Should increment patch and add prerelease
    [[ "$new_version" == "1.0.1-alpha.1" ]]
}

#######################################
# Test: cmd_current shows current version
#######################################
@test "cmd_current shows current version" {
    run "${SCRIPTS_DIR}/version.sh" current
    [[ $status -eq 0 ]]
    [[ "$output" == *"Current version: 1.0.0"* ]]
}

#######################################
# Test: cmd_validate valid version
#######################################
@test "cmd_validate accepts valid version" {
    run "${SCRIPTS_DIR}/version.sh" validate --version "1.0.0"
    [[ $status -eq 0 ]]
    [[ "$output" == *"Valid version"* ]]
}

#######################################
# Test: cmd_validate invalid version
#######################################
@test "cmd_validate rejects invalid version" {
    run "${SCRIPTS_DIR}/version.sh" validate --version "invalid"
    [[ $status -eq 1 ]]
    [[ "$output" == *"Invalid version"* ]]
}

#######################################
# Test: cmd_check compatible version
#######################################
@test "cmd_check accepts compatible version" {
    run "${SCRIPTS_DIR}/version.sh" check --version "1.0.0"
    [[ $status -eq 0 ]]
    [[ "$output" == *"compatible"* ]]
}

#######################################
# Test: cmd_check incompatible version
#######################################
@test "cmd_check rejects incompatible version" {
    run "${SCRIPTS_DIR}/version.sh" check --version "3.0.0"
    [[ $status -eq 1 ]]
    [[ "$output" == *"above maximum"* ]]
}

#######################################
# Test: cmd_matrix shows compatibility matrix
#######################################
@test "cmd_matrix shows compatibility matrix" {
    run "${SCRIPTS_DIR}/version.sh" matrix
    [[ $status -eq 0 ]]
    [[ "$output" == *"Compatibility Matrix"* ]]
    [[ "$output" == *"Current Version"* ]]
}

#######################################
# Test: cmd_matrix JSON output
#######################################
@test "cmd_matrix outputs JSON" {
    run "${SCRIPTS_DIR}/version.sh" matrix --format json
    [[ $status -eq 0 ]]
    [[ "$output" == *"\"current\""* ]]
    [[ "$output" == *"\"compatibility\""* ]]
}

#######################################
# Test: write_version_file updates VERSION
#######################################
@test "write_version_file creates VERSION file" {
    source "${SCRIPTS_DIR}/version.sh"

    write_version_file "1.2.3" "1.0.0" "2.0.0"

    [[ -f "${RDD_DIR}/VERSION" ]]
    grep -q "VERSION=1.2.3" "${RDD_DIR}/VERSION"
    grep -q "COMPAT_MIN=1.0.0" "${RDD_DIR}/VERSION"
    grep -q "COMPAT_MAX=2.0.0" "${RDD_DIR}/VERSION"
}

#######################################
# Test: parse_args handles --version
#######################################
@test "parse_args handles --version flag" {
    source "${SCRIPTS_DIR}/version.sh"

    parse_args --version "1.5.0"

    [[ "$CHECK_VERSION" == "1.5.0" ]]
    [[ "$VALIDATE_VERSION" == "1.5.0" ]]
}

#######################################
# Test: parse_args handles --format
#######################################
@test "parse_args handles --format flag" {
    source "${SCRIPTS_DIR}/version.sh"

    parse_args --format json

    [[ "$OUTPUT_FORMAT" == "json" ]]
}

#######################################
# Test: Unknown command shows error
#######################################
@test "unknown command shows error" {
    run "${SCRIPTS_DIR}/version.sh" unknown_command
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown command"* ]]
}

#######################################
# Test: No command shows usage
#######################################
@test "no command shows usage" {
    run "${SCRIPTS_DIR}/version.sh"
    [[ $status -eq 1 ]]
    [[ "$output" == *"Usage"* ]]
}
