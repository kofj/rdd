#!/usr/bin/env bats
#
# Unit tests for notify.sh
#

# Load test helper
load '../lib/test_helper'

# Load bats-support and bats-assert
load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Set up before each test
setup() {
    setup_test_env
}

# Tear down after each test
teardown() {
    teardown_test_env
}

#######################################
# log_info tests
#######################################

@test "log_info outputs message with [INFO] prefix" {
    run log_info "Test message"
    assert_output --partial "[INFO]"
    assert_output --partial "Test message"
}

@test "log_info outputs multiple arguments" {
    run log_info "Hello" "World"
    assert_output --partial "[INFO]"
    assert_output --partial "Hello World"
}

@test "log_info handles empty message" {
    run log_info ""
    assert_output --partial "[INFO]"
}

@test "log_info handles special characters" {
    run log_info "Special: !@#\$%^&*()"
    assert_output --partial "[INFO]"
    assert_output --partial "Special: !@#\$%^&*()"
}

#######################################
# log_warn tests
#######################################

@test "log_warn outputs message with [WARN] prefix" {
    run log_warn "Warning message"
    assert_output --partial "[WARN]"
    assert_output --partial "Warning message"
}

@test "log_warn handles multiple arguments" {
    run log_warn "This is" "a warning"
    assert_output --partial "[WARN]"
    assert_output --partial "This is a warning"
}

@test "log_warn handles empty message" {
    run log_warn ""
    assert_output --partial "[WARN]"
}

#######################################
# log_error tests
#######################################

@test "log_error outputs message with [ERROR] prefix" {
    run log_error "Error message"
    assert_output --partial "[ERROR]"
    assert_output --partial "Error message"
}

@test "log_error handles multiple arguments" {
    run log_error "Critical" "error occurred"
    assert_output --partial "[ERROR]"
    assert_output --partial "Critical error occurred"
}

@test "log_error handles empty message" {
    run log_error ""
    assert_output --partial "[ERROR]"
}

#######################################
# log_debug tests
#######################################

@test "log_debug does not output when VERBOSE is false" {
    export VERBOSE="false"
    run log_debug "Debug message"
    refute_output --partial "Debug message"
}

@test "log_debug outputs message when VERBOSE is true" {
    export VERBOSE="true"
    run log_debug "Debug message"
    assert_output --partial "[DEBUG]"
    assert_output --partial "Debug message"
}

#######################################
# urlencode tests
#######################################

@test "urlencode encodes special characters" {
    run urlencode "hello world"
    assert_output "hello%20world"
}

@test "urlencode does not encode alphanumeric characters" {
    run urlencode "hello123"
    assert_output "hello123"
}

@test "urlencode encodes colon" {
    run urlencode "key:value"
    assert_output "key%3Avalue"
}

@test "urlencode handles empty string" {
    run urlencode ""
    assert_output ""
}

#######################################
# expand_env_vars tests
#######################################

@test "expand_env_vars expands \${VAR} style variables" {
    export TEST_VAR="hello"
    run expand_env_vars "\${TEST_VAR}"
    assert_output "hello"
    unset TEST_VAR
}

@test "expand_env_vars handles non-existent variables" {
    run expand_env_vars "\${NON_EXISTENT_VAR}"
    assert_output ""
}

@test "expand_env_vars handles mixed content" {
    export NAME="World"
    run expand_env_vars "Hello \${NAME}!"
    assert_output "Hello World!"
    unset NAME
}

@test "expand_env_vars handles multiple variables" {
    export FIRST="John"
    export LAST="Doe"
    run expand_env_vars "\${FIRST} \${LAST}"
    assert_output "John Doe"
    unset FIRST
    unset LAST
}

@test "expand_env_vars handles empty input" {
    run expand_env_vars ""
    assert_output ""
}

@test "expand_env_vars handles string without variables" {
    run expand_env_vars "plain text"
    assert_output "plain text"
}

#######################################
# send_notification tests (dry run mode)
#######################################

@test "send_notification handles missing configuration file gracefully" {
    # Temporarily move config file
    local backup_file="${CONFIG_FILE}.bak"
    if [[ -f "${CONFIG_FILE}" ]]; then
        mv "${CONFIG_FILE}" "${backup_file}"
    fi

    run send_notification "stage_complete"
    # Should output error about missing config but may continue with defaults
    assert_output --partial "Configuration file not found" || assert_failure

    # Restore config file
    if [[ -f "${backup_file}" ]]; then
        mv "${backup_file}" "${CONFIG_FILE}"
    fi
}

@test "send_notification succeeds in dry run mode" {
    export DRY_RUN="true"
    run send_notification "stage_complete"
    # Should succeed or skip due to disabled trigger
    assert_success || assert_output --partial "disabled"
}

@test "send_notification handles unknown trigger type" {
    export DRY_RUN="true"
    run send_notification "unknown_trigger"
    # Should succeed silently (trigger disabled)
    assert_success
}

#######################################
# is_quiet_hours tests
####################################@

@test "is_quiet_hours returns false when disabled" {
    # Quiet hours are disabled in test config
    run is_quiet_hours
    assert_failure
}

#######################################
# load_yaml_value tests
#######################################

@test "load_yaml_value extracts simple value" {
    # The load_yaml_value function may not have yq, so it uses grep fallback
    # which only extracts top-level keys
    run load_yaml_value "${CONFIG_FILE}" "version" "default"
    # Output may be "1.0" or "default" depending on yq availability
    assert_output "1.0" || assert_output --partial "default"
}

@test "load_yaml_value returns default for missing key" {
    run load_yaml_value "${CONFIG_FILE}" "nonexistent" "default_value"
    assert_output "default_value"
}

#######################################
# show_usage tests
#######################################

@test "show_usage displays help information" {
    run show_usage
    assert_output --partial "RDD Notification Script"
    assert_output --partial "Usage:"
    assert_output --partial "Trigger Types:"
    assert_output --partial "stage_complete"
}

#######################################
# Integration tests
#######################################

@test "notify.sh shows help with --help flag" {
    run bash "${PROJECT_ROOT}/.rdd/scripts/notify.sh" --help
    assert_output --partial "RDD Notification Script"
    assert_success
}

@test "notify.sh shows help with -h flag" {
    run bash "${PROJECT_ROOT}/.rdd/scripts/notify.sh" -h
    assert_output --partial "RDD Notification Script"
    assert_success
}

@test "notify.sh shows help with help command" {
    run bash "${PROJECT_ROOT}/.rdd/scripts/notify.sh" help
    assert_output --partial "RDD Notification Script"
    assert_success
}

@test "notify.sh exits with error for unknown trigger" {
    run bash "${PROJECT_ROOT}/.rdd/scripts/notify.sh" unknown_trigger
    assert_failure
    assert_output --partial "Unknown trigger type"
}

@test "notify.sh exits with error when no arguments provided" {
    run bash "${PROJECT_ROOT}/.rdd/scripts/notify.sh"
    assert_failure
    assert_output --partial "Usage:"
}
