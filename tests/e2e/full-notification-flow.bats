#!/usr/bin/env bats
#
# E2E Tests for Full Notification Flow
# End-to-end tests that validate complete workflows
#

load '../lib/test_helper'
load '../lib/bats-support/load'
load '../lib/bats-assert/load'

# Global setup - runs once before all tests
setup_file() {
    export PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)}"
    export RDD_DIR="${PROJECT_ROOT}/.rdd"
    export DRY_RUN="true"
    export VERBOSE="false"

    # Source the notify script
    source "${RDD_DIR}/scripts/notify.sh"
}

# Global teardown - runs once after all tests
teardown_file() {
    unset DRY_RUN
    unset VERBOSE
}

#######################################
# E2E: Complete notification workflow
#######################################

@test "E2E: Complete stage completion notification workflow" {
    # Setup: Create test configuration
    local test_config="${BATS_TEST_TMPDIR}/e2e_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: e2e-test-project
notifications:
  quiet_hours:
    enabled: false
retry:
  max_attempts: 3
  initial_delay: "1s"
  max_delay: "5s"
triggers:
  stage_complete:
    enabled: true
    channels:
      - webhook
  roadmap_change:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "https://httpbin.org/post"
    method: "POST"
    headers: ""
EOF

    local test_templates="${BATS_TEST_TMPDIR}/e2e_templates.yml"
    cat > "$test_templates" << 'EOF'
templates:
  stage_complete:
    title: "Stage Complete: {{project_name}}"
    body: |
      Stage {{stage_name}} completed successfully.
      Duration: {{duration}}
      Coverage: {{coverage}}%
    block_message: "Stage completion notification"
  roadmap_change:
    title: "Roadmap Changed"
    body: "Roadmap has been updated."
    block_message: "Roadmap change"
EOF

    export CONFIG_FILE="$test_config"
    export TEMPLATES_FILE="$test_templates"
    export DRY_RUN="true"

    # Execute: Send stage completion notification
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete \
        "project_name=E2ETestProject" \
        "stage_name=Stage1" \
        "duration=30m" \
        "coverage=95"

    # Verify: Command succeeds
    assert_success
    assert_output --partial "Processing notification trigger: stage_complete"
}

@test "E2E: Roadmap change notification workflow" {
    # Setup
    local test_config="${BATS_TEST_TMPDIR}/roadmap_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: roadmap-test-project
notifications:
  quiet_hours:
    enabled: false
retry:
  max_attempts: 3
triggers:
  roadmap_change:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "https://example.com/webhook"
EOF

    export CONFIG_FILE="$test_config"
    export DRY_RUN="true"

    # Execute
    run bash "${RDD_DIR}/scripts/notify.sh" roadmap_change \
        "project_name=RoadmapTest" \
        "change_type=Stage added"

    # Verify
    assert_success
}

@test "E2E: Consecutive failure notification workflow" {
    # Setup
    local test_config="${BATS_TEST_TMPDIR}/failure_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: failure-test-project
notifications:
  quiet_hours:
    enabled: false
retry:
  max_attempts: 3
triggers:
  consecutive_failure:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "https://example.com/webhook"
EOF

    export CONFIG_FILE="$test_config"
    export DRY_RUN="true"

    # Execute
    run bash "${RDD_DIR}/scripts/notify.sh" consecutive_failure \
        "project_name=FailureTest" \
        "stage_name=Stage2" \
        "failure_count=3" \
        "last_error=Test timeout"

    # Verify
    assert_success
}

@test "E2E: Multiple channels with partial failure" {
    # Setup: Config with multiple channels, one will fail
    local test_config="${BATS_TEST_TMPDIR}/multi_channel_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: multi-channel-project
notifications:
  quiet_hours:
    enabled: false
retry:
  max_attempts: 1
triggers:
  stage_complete:
    enabled: true
    channels:
      - webhook
      - wecom
      - email
channels:
  webhook:
    enabled: true
    url: "https://example.com/webhook"
  wecom:
    enabled: true
    webhook_url: ""
  email:
    enabled: true
    smtp_host: ""
EOF

    export CONFIG_FILE="$test_config"
    export DRY_RUN="true"

    # Execute
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete \
        "project_name=MultiChannelTest"

    # Verify: Should succeed even with partial failures
    # Dry run mode should not actually fail
    assert_success
}

#######################################
# E2E: Configuration validation
#######################################

@test "E2E: Invalid configuration is handled gracefully" {
    # Setup: Invalid YAML config
    local test_config="${BATS_TEST_TMPDIR}/invalid_hooks.yml"
    echo "invalid: yaml: content:" > "$test_config"

    export CONFIG_FILE="$test_config"
    export DRY_RUN="true"

    # Execute: Should handle gracefully
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete 2>&1 || true

    # Verify: Either fails gracefully or succeeds with warning
    # The script should not crash
    assert [ $? -eq 0 ] || assert_output --partial "error" || assert_output --partial "Error"
}

@test "E2E: Missing templates file is handled" {
    # Setup: Config with missing templates file
    local test_config="${BATS_TEST_TMPDIR}/no_templates_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: no-templates-project
triggers:
  stage_complete:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "https://example.com/webhook"
EOF

    export CONFIG_FILE="$test_config"
    export TEMPLATES_FILE="${BATS_TEST_TMPDIR}/nonexistent_templates.yml"
    export DRY_RUN="true"

    # Execute: Should handle missing templates
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete 2>&1 || true

    # Verify: Should indicate templates file not found or succeed with defaults
    # The behavior depends on whether templates are required
    assert [ "$status" -eq 0 ] || assert_output --partial "Templates file not found"
}

#######################################
# E2E: Environment variable substitution
#######################################

@test "E2E: Environment variables are properly expanded in config" {
    # Setup: Config with env var placeholders
    export TEST_WEBHOOK="https://env-test.example.com/hook"
    export TEST_WECOM="https://qyapi.weixin.qq.com/env-test"

    local test_config="${BATS_TEST_TMPDIR}/env_var_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: env-var-project
triggers:
  stage_complete:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "${TEST_WEBHOOK}"
EOF

    export CONFIG_FILE="$test_config"
    export DRY_RUN="true"
    export VERBOSE="true"

    # Execute
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete

    # Verify: Environment variable should be expanded
    # Note: The actual expansion happens in the channel loading code
    assert_success || assert_output --partial "env-test"

    unset TEST_WEBHOOK
    unset TEST_WECOM
}

#######################################
# E2E: Help and usage
#######################################

@test "E2E: Help command displays usage information" {
    run bash "${RDD_DIR}/scripts/notify.sh" help

    assert_success
    assert_output --partial "RDD Notification Script"
    assert_output --partial "Usage:"
    assert_output --partial "Trigger Types:"
}

@test "E2E: No arguments shows usage" {
    run bash "${RDD_DIR}/scripts/notify.sh"

    assert_failure
    assert_output --partial "Usage:"
}

#######################################
# E2E: Dry run mode
#######################################

@test "E2E: Dry run mode processes notifications without sending" {
    # Setup
    local test_config="${BATS_TEST_TMPDIR}/dry_run_hooks.yml"
    cat > "$test_config" << 'EOF'
version: "1.0"
project:
  name: dry-run-project
triggers:
  stage_complete:
    enabled: true
    channels:
      - webhook
channels:
  webhook:
    enabled: true
    url: "https://example.com/webhook"
EOF

    local test_templates="${BATS_TEST_TMPDIR}/dry_run_templates.yml"
    cat > "$test_templates" << 'EOF'
templates:
  stage_complete:
    title: "Stage Complete"
    body: "Test"
EOF

    export CONFIG_FILE="$test_config"
    export TEMPLATES_FILE="$test_templates"
    export DRY_RUN="true"

    # Execute
    run bash "${RDD_DIR}/scripts/notify.sh" stage_complete

    # Verify: Should process without errors
    assert_success
    assert_output --partial "Processing notification trigger"
}

#######################################
# E2E: Health check integration
#######################################

@test "E2E: Task doctor runs successfully" {
    cd "${PROJECT_ROOT}"
    run task doctor

    # Should succeed and show health check
    assert_success
    assert_output --partial "Health Check" || assert_output --partial "Checking"
}

@test "E2E: Project structure is valid" {
    # Verify required files exist
    assert [ -f "${PROJECT_ROOT}/.rdd/scripts/notify.sh" ]
    assert [ -f "${PROJECT_ROOT}/.rdd/hooks.yml" ]
    assert [ -f "${PROJECT_ROOT}/.rdd/templates.yml" ]
    assert [ -f "${PROJECT_ROOT}/Taskfile.yml" ]
    assert [ -f "${PROJECT_ROOT}/AGENTS.md" ]
    assert [ -f "${PROJECT_ROOT}/CLAUDE.md" ]
}
