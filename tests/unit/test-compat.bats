#!/usr/bin/env bats
#
# Unit tests for compat.sh
#
# Run with: bats tests/unit/test-compat.bats
#

# Setup test environment
setup() {
    # Set RDD_DIR to test directory
    export RDD_DIR="$(mktemp -d)"
    export SCRIPTS_DIR="${RDD_DIR}/scripts"
    export CONFIG_FILE="${RDD_DIR}/config.yml"
    export HOOKS_FILE="${RDD_DIR}/hooks.yml"
    export TEMPLATES_FILE="${RDD_DIR}/templates.yml"
    export VERSION_FILE="${RDD_DIR}/VERSION"

    # Create directories
    mkdir -p "$SCRIPTS_DIR"

    # Copy scripts to test directory
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/compat.sh" "$SCRIPTS_DIR/"
    chmod +x "${SCRIPTS_DIR}/compat.sh"

    # Create VERSION file
    cat > "${VERSION_FILE}" <<EOF
VERSION=1.0.0
COMPAT_MIN=0.9.0
COMPAT_MAX=2.0.0
EOF

    # Create valid config.yml
    cat > "${CONFIG_FILE}" <<EOF
version: "1.0.0"
project:
  name: "Test Project"
  description: "Test Description"

stage:
  min_coverage: 20
  max_failures: 3
  tech_debt_threshold: 3

gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

hooks:
  enabled: false

notifications:
  quiet_hours:
    enabled: false
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true
EOF

    # Create valid hooks.yml
    cat > "${HOOKS_FILE}" <<EOF
triggers:
  stage_complete:
    enabled: true
    channels:
      - wecom

channels:
  wecom:
    enabled: true
    webhook_url: "https://example.com/webhook"

retry:
  max_attempts: 3
  initial_delay: "1s"
  max_delay: "30s"
EOF

    # Create valid templates.yml
    cat > "${TEMPLATES_FILE}" <<EOF
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
@test "compat.sh exists and is executable" {
    [[ -x "${SCRIPTS_DIR}/compat.sh" ]]
}

#######################################
# Test: Help output
#######################################
@test "compat.sh shows help" {
    run "${SCRIPTS_DIR}/compat.sh" --help
    [[ $status -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Commands"* ]]
}

#######################################
# Test: read_current_version
#######################################
@test "read_current_version reads VERSION correctly" {
    source "${SCRIPTS_DIR}/compat.sh"

    local version
    version=$(read_current_version)

    [[ "$version" == "1.0.0" ]]
}

#######################################
# Test: parse_version
#######################################
@test "parse_version extracts components" {
    source "${SCRIPTS_DIR}/compat.sh"

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
    source "${SCRIPTS_DIR}/compat.sh"

    compare_versions "1.0.0" "1.0.0"
    [[ $? -eq 0 ]]
}

#######################################
# Test: compare_versions - greater
#######################################
@test "compare_versions returns 1 when first is greater" {
    source "${SCRIPTS_DIR}/compat.sh"

    run compare_versions "1.1.0" "1.0.0"
    [[ $status -eq 1 ]]
}

#######################################
# Test: compare_versions - less
#######################################
@test "compare_versions returns 2 when first is less" {
    source "${SCRIPTS_DIR}/compat.sh"

    run compare_versions "1.0.0" "1.1.0"
    [[ $status -eq 2 ]]
}

#######################################
# Test: has_yq function
#######################################
@test "has_yq returns true if yq is installed" {
    source "${SCRIPTS_DIR}/compat.sh"

    if command -v yq &> /dev/null; then
        run has_yq
        [[ $status -eq 0 ]]
    else
        run has_yq
        [[ $status -eq 1 ]]
    fi
}

#######################################
# Test: get_yaml_value retrieves value
#######################################
@test "get_yaml_value retrieves value from YAML" {
    source "${SCRIPTS_DIR}/compat.sh"

    local value
    value=$(get_yaml_value "$CONFIG_FILE" "version")

    [[ "$value" == "1.0.0" ]]
}

#######################################
# Test: get_yaml_value returns default for missing key
#######################################
@test "get_yaml_value returns default for missing key" {
    source "${SCRIPTS_DIR}/compat.sh"

    local value
    value=$(get_yaml_value "$CONFIG_FILE" "nonexistent" "default_value")

    [[ "$value" == "default_value" ]]
}

#######################################
# Test: validate_config passes with valid config
#######################################
@test "validate_config passes with valid config" {
    source "${SCRIPTS_DIR}/compat.sh"

    run validate_config
    [[ $status -eq 0 ]]
}

#######################################
# Test: validate_config warns about missing field
#######################################
@test "validate_config warns about missing required field" {
    source "${SCRIPTS_DIR}/compat.sh"

    # Remove a required field
    sed -i '/min_coverage/d' "$CONFIG_FILE"

    # Call function directly to capture array changes
    validate_config

    # Should have warnings - check the array directly
    [[ ${#COMPAT_WARNINGS[@]} -gt 0 ]]
}

#######################################
# Test: validate_hooks passes with valid hooks
#######################################
@test "validate_hooks passes with valid hooks" {
    source "${SCRIPTS_DIR}/compat.sh"

    run validate_hooks
    [[ $status -eq 0 ]]
}

#######################################
# Test: validate_hooks handles missing file
#######################################
@test "validate_hooks handles missing hooks.yml" {
    rm "$HOOKS_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    # Call function directly to capture array changes
    validate_hooks

    # Should have info message about missing hooks.yml
    [[ ${#COMPAT_INFO[@]} -gt 0 ]]
}

#######################################
# Test: validate_templates passes with valid templates
#######################################
@test "validate_templates passes with valid templates" {
    source "${SCRIPTS_DIR}/compat.sh"

    run validate_templates
    [[ $status -eq 0 ]]
}

#######################################
# Test: validate_version_file passes with valid VERSION
#######################################
@test "validate_version_file passes with valid VERSION" {
    source "${SCRIPTS_DIR}/compat.sh"

    run validate_version_file
    [[ $status -eq 0 ]]
}

#######################################
# Test: validate_version_file fails with missing VERSION
#######################################
@test "validate_version_file fails with missing VERSION" {
    rm "$VERSION_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    # Call function directly to capture array changes
    # Use || true to avoid exit on failure with set -e
    validate_version_file || true

    [[ ${#COMPAT_ISSUES[@]} -gt 0 ]]
}

#######################################
# Test: validate_version_file fails with invalid version
#######################################
@test "validate_version_file fails with invalid version format" {
    echo "VERSION=invalid" > "$VERSION_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    # Call function directly to capture array changes
    validate_version_file

    [[ ${#COMPAT_ISSUES[@]} -gt 0 ]]
}

#######################################
# Test: add_issue adds to issues array
#######################################
@test "add_issue adds to issues array" {
    source "${SCRIPTS_DIR}/compat.sh"

    add_issue "Test issue"

    [[ ${#COMPAT_ISSUES[@]} -eq 1 ]]
    [[ "${COMPAT_ISSUES[0]}" == "Test issue" ]]
}

#######################################
# Test: add_warning adds to warnings array
#######################################
@test "add_warning adds to warnings array" {
    source "${SCRIPTS_DIR}/compat.sh"

    add_warning "Test warning"

    [[ ${#COMPAT_WARNINGS[@]} -eq 1 ]]
    [[ "${COMPAT_WARNINGS[0]}" == "Test warning" ]]
}

#######################################
# Test: add_info adds to info array
#######################################
@test "add_info adds to info array" {
    source "${SCRIPTS_DIR}/compat.sh"

    add_info "Test info"

    [[ ${#COMPAT_INFO[@]} -eq 1 ]]
    [[ "${COMPAT_INFO[0]}" == "Test info" ]]
}

#######################################
# Test: cmd_check runs all validations
#######################################
@test "cmd_check runs all validations" {
    run "${SCRIPTS_DIR}/compat.sh" check
    [[ $status -eq 0 ]]
    [[ "$output" == *"Validating config.yml"* ]]
    [[ "$output" == *"Validating hooks.yml"* ]]
    [[ "$output" == *"Validating templates.yml"* ]]
}

#######################################
# Test: cmd_check passes with valid setup
#######################################
@test "cmd_check passes with valid setup" {
    run "${SCRIPTS_DIR}/compat.sh" check
    [[ $status -eq 0 ]]
    [[ "$output" == *"All compatibility checks passed"* ]]
}

#######################################
# Test: cmd_check fails with missing VERSION
#######################################
@test "cmd_check fails with missing VERSION" {
    rm "$VERSION_FILE"

    run "${SCRIPTS_DIR}/compat.sh" check
    [[ $status -eq 1 ]]
}

#######################################
# Test: cmd_check fails with missing config
#######################################
@test "cmd_check fails with missing config.yml" {
    rm "$CONFIG_FILE"

    run "${SCRIPTS_DIR}/compat.sh" check
    [[ $status -eq 1 ]]
    [[ "$output" == *"config"* ]] || [[ "$output" == *"not found"* ]] || [[ "$output" == *"error"* ]] || [[ "$output" == *"ERROR"* ]]
}

#######################################
# Test: generate_report outputs text
#######################################
@test "generate_report outputs text format" {
    source "${SCRIPTS_DIR}/compat.sh"

    OUTPUT_FORMAT="text"
    run generate_report

    [[ "$output" == *"RDD Compatibility Report"* ]]
}

#######################################
# Test: generate_report outputs JSON
#######################################
@test "generate_report outputs JSON format" {
    source "${SCRIPTS_DIR}/compat.sh"

    OUTPUT_FORMAT="json"
    run generate_report

    [[ "$output" == *"\"version\""* ]]
    [[ "$output" == *"\"timestamp\""* ]]
    [[ "$output" == *"\"summary\""* ]]
}

#######################################
# Test: check_deprecations runs
#######################################
@test "check_deprecations runs without error" {
    source "${SCRIPTS_DIR}/compat.sh"

    run check_deprecations
    [[ $status -eq 0 ]]
}

#######################################
# Test: check_deprecations finds deprecated file
#######################################
@test "check_deprecations finds deprecated .rddrc file" {
    source "${SCRIPTS_DIR}/compat.sh"

    # Create deprecated file
    touch "${RDD_DIR}/.rddrc"

    # Call function directly to capture array changes
    check_deprecations

    [[ ${#COMPAT_WARNINGS[@]} -gt 0 ]]
}

#######################################
# Test: cmd_deprecations shows warnings
#######################################
@test "cmd_deprecations shows deprecation warnings" {
    run "${SCRIPTS_DIR}/compat.sh" deprecations
    [[ $status -eq 0 ]]
}

#######################################
# Test: auto_fix_issues creates missing VERSION
#######################################
@test "auto_fix_issues creates missing VERSION file" {
    rm "$VERSION_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    run auto_fix_issues

    [[ -f "$VERSION_FILE" ]]
}

#######################################
# Test: auto_fix_issues creates missing config.yml
#######################################
@test "auto_fix_issues creates missing config.yml" {
    rm "$CONFIG_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    run auto_fix_issues

    [[ -f "$CONFIG_FILE" ]]
    grep -q "min_coverage" "$CONFIG_FILE"
}

#######################################
# Test: auto_fix_issues creates missing hooks.yml
#######################################
@test "auto_fix_issues creates missing hooks.yml" {
    rm "$HOOKS_FILE"

    source "${SCRIPTS_DIR}/compat.sh"

    run auto_fix_issues

    [[ -f "$HOOKS_FILE" ]]
    grep -q "triggers" "$HOOKS_FILE"
}

#######################################
# Test: cmd_fix runs auto-fix and check
#######################################
@test "cmd_fix runs auto-fix and check" {
    rm "$VERSION_FILE" "$CONFIG_FILE"

    run "${SCRIPTS_DIR}/compat.sh" fix
    [[ $status -eq 0 ]]
    [[ -f "$VERSION_FILE" ]]
    [[ -f "$CONFIG_FILE" ]]
}

#######################################
# Test: parse_args handles --format
#######################################
@test "parse_args handles --format flag" {
    source "${SCRIPTS_DIR}/compat.sh"

    parse_args --format json

    [[ "$OUTPUT_FORMAT" == "json" ]]
}

#######################################
# Test: parse_args handles --config
#######################################
@test "parse_args handles --config flag" {
    source "${SCRIPTS_DIR}/compat.sh"

    parse_args --config "/path/to/config.yml"

    [[ "$VALIDATE_FILE" == "/path/to/config.yml" ]]
}

#######################################
# Test: cmd_report generates report
#######################################
@test "cmd_report generates compatibility report" {
    run "${SCRIPTS_DIR}/compat.sh" report
    [[ $status -eq 0 ]]
    [[ "$output" == *"RDD Compatibility Report"* ]]
}

#######################################
# Test: Unknown command shows error
#######################################
@test "unknown command shows error" {
    run "${SCRIPTS_DIR}/compat.sh" unknown_command
    [[ $status -eq 1 ]]
    [[ "$output" == *"Unknown command"* ]]
}

#######################################
# Test: No command shows usage
#######################################
@test "no command shows usage" {
    run "${SCRIPTS_DIR}/compat.sh"
    [[ $status -eq 1 ]]
    [[ "$output" == *"Usage"* ]]
}

#######################################
# Test: Breaking changes detection
#######################################
@test "cmd_breaking checks for breaking changes" {
    run "${SCRIPTS_DIR}/compat.sh" breaking --from 1.0.0 --to 1.0.1
    # Exit code 0 means no breaking changes, 1 means breaking changes found
    # Either is acceptable for this test - we just want to verify it runs
    [[ $status -eq 0 || $status -eq 1 ]]
    [[ "$output" == *"Checking for breaking changes"* ]]
}
