#!/usr/bin/env bash
#
# Test helper for RDD Framework tests
#

# Get the project root directory
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)}"

# Set up test environment
setup_test_env() {
    export RDD_DIR="${PROJECT_ROOT}/.rdd"
    export CONFIG_FILE="${RDD_DIR}/hooks.yml"
    export TEMPLATES_FILE="${RDD_DIR}/templates.yml"
    export CACHE_DIR="${RDD_DIR}/cache"
    export DRY_RUN="true"
    export VERBOSE="false"

    # Source the notify script after setting up environment
    # Use a flag to prevent double-sourcing
    if [[ -z "${_NOTIFY_SOURCED:-}" ]]; then
        source "${PROJECT_ROOT}/.rdd/scripts/notify.sh"
        _NOTIFY_SOURCED=1
    fi
}

# Set up isolated test environment for checkpoint/handoff tests
setup_isolated_test_env() {
    export RDD_DIR="${BATS_TEST_TMPDIR}/.rdd"
    export CACHE_DIR="${RDD_DIR}/cache"
    export PROJECT_ROOT="${BATS_TEST_TMPDIR}"
    export DRY_RUN="true"
    export VERBOSE="false"

    mkdir -p "${CACHE_DIR}"
    mkdir -p "${RDD_DIR}/scripts"

    # Copy scripts to isolated environment
    cp "${PROJECT_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)}/.rdd/scripts/checkpoint.sh" "${RDD_DIR}/scripts/" 2>/dev/null || true
    cp "${PROJECT_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)}/.rdd/scripts/handoff.sh" "${RDD_DIR}/scripts/" 2>/dev/null || true
}

# Clean up test environment
teardown_test_env() {
    unset DRY_RUN
    unset VERBOSE
}

#######################################
# File assertion helpers
#######################################

# Assert file exists
assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "Expected file to exist: $1" >&2
        return 1
    fi
    return 0
}

# Assert file does not exist
refute_file_exists() {
    if [[ -f "$1" ]]; then
        echo "Expected file to NOT exist: $1" >&2
        return 1
    fi
    return 0
}

# Assert directory exists
assert_dir_exists() {
    if [[ ! -d "$1" ]]; then
        echo "Expected directory to exist: $1" >&2
        return 1
    fi
    return 0
}

# Assert directory does not exist
refute_dir_exists() {
    if [[ -d "$1" ]]; then
        echo "Expected directory to NOT exist: $1" >&2
        return 1
    fi
    return 0
}

# Create a custom config for testing
create_test_config() {
    local tmp_file="$1"
    cat > "$tmp_file" << 'EOF'
version: "1.0"
project:
  name: test-project

notifications:
  quiet_hours:
    enabled: false
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true

retry:
  max_attempts: 3
  initial_delay: "1s"
  max_delay: "30s"

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
    url: "https://example.com/webhook"
    method: "POST"
    headers: ""
  wecom:
    enabled: false
    webhook_url: ""
  email:
    enabled: false
  bark:
    enabled: false
  telegram:
    enabled: false
EOF
    export CONFIG_FILE="$tmp_file"
}

# Create templates file for testing
create_test_templates() {
    local tmp_file="$1"
    cat > "$tmp_file" << 'EOF'
templates:
  stage_complete:
    title: "Stage Complete: {{project_name}}"
    body: |
      Stage {{stage_name}} completed successfully.
      Duration: {{duration}}
      Coverage: {{coverage}}%
    block_message: null
    continue_message: "✅ Stage completed, auto-continuing..."
  roadmap_change:
    title: "Roadmap Changed: {{project_name}}"
    body: |
      Roadmap has been updated.
      Change type: {{change_type}}
    block_message: "⏳ Roadmap change requires human review, agent paused"
EOF
    export TEMPLATES_FILE="$tmp_file"
}

# Create a temporary config file for testing
create_test_config() {
    local tmp_file="$1"
    cat > "$tmp_file" << 'EOF'
version: "1.0"
project:
  name: test-project

notifications:
  quiet_hours:
    enabled: false
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true

retry:
  max_attempts: 3
  initial_delay: "1s"
  max_delay: "30s"

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
    url: "https://example.com/webhook"
    method: "POST"
    headers: ""
  wecom:
    enabled: false
    webhook_url: ""
  email:
    enabled: false
  bark:
    enabled: false
  telegram:
    enabled: false
EOF
}

# Create a temporary templates file for testing
create_test_templates() {
    local tmp_file="$1"
    cat > "$tmp_file" << 'EOF'
templates:
  stage_complete:
    title: "Stage Complete: {{project_name}}"
    body: |
      Stage {{stage_name}} completed successfully.
      Duration: {{duration}}
      Coverage: {{coverage}}%
    block_message: null
    continue_message: "✅ Stage completed, auto-continuing..."
  roadmap_change:
    title: "Roadmap Changed: {{project_name}}"
    body: |
      Roadmap has been updated.
      Change type: {{change_type}}
    block_message: "⏳ Roadmap change requires human review, agent paused"
EOF
}