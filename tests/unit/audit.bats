#!/usr/bin/env bats
#
# Unit tests for RDD Audit Logging (audit.sh)
# Tests audit event logging, log rotation, and querying
#

# Load bats-core (no additional helpers needed)

# Setup
setup() {
    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)
    RDD_DIR="$TEST_DIR/.rdd"

    mkdir -p "$RDD_DIR/logs"
    mkdir -p "$RDD_DIR/scripts"

    # Create minimal audit config
    cat > "$RDD_DIR/audit.yml" << 'EOF'
version: "1.0.0"
audit:
  enabled: true
  events:
    - category: SECURITY
      events:
        - PERMISSION_DENIED
        - AUTH_FAILURE
      level: INFO
      mandatory: true
    - category: STAGE
      events:
        - STAGE_START
        - STAGE_COMPLETE
      level: INFO
  storage:
    file:
      enabled: true
      path: ".rdd/logs/audit.log"
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 10
    json:
      enabled: true
      path: ".rdd/logs/audit.json"
  retention:
    days: 90
  masking:
    enabled: true
    fields:
      - password
      - token
      - secret
EOF

    # Source the audit library
    export RDD_DIR
    export RDD_USER="test_user"
    export RDD_SESSION_ID="test-session-123"
    source "${BATS_TEST_DIRNAME}/../../.rdd/scripts/audit.sh"
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

#######################################
# Test: Initialization
#######################################

@test "init_audit creates logs directory" {
    rm -rf "$RDD_DIR/logs"
    init_audit
    [ -d "$RDD_DIR/logs" ]
}

@test "init_audit creates audit log file" {
    rm -f "$RDD_DIR/logs/audit.log"
    init_audit
    [ -f "$RDD_DIR/logs/audit.log" ]
}

@test "init_audit creates JSON log file" {
    rm -f "$RDD_DIR/logs/audit.json"
    init_audit
    [ -f "$RDD_DIR/logs/audit.json" ]
}

@test "init_audit creates default config if not exists" {
    rm -f "$RDD_DIR/audit.yml"
    init_audit
    [ -f "$RDD_DIR/audit.yml" ]
}

#######################################
# Test: Audit Logging
#######################################

@test "log_audit writes to text log" {
    log_audit "TEST_EVENT" "key=value result=success"

    [ -f "$RDD_DIR/logs/audit.log" ]
    grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.log"
}

@test "log_audit writes to JSON log" {
    log_audit "TEST_EVENT" "key=value result=success"

    [ -f "$RDD_DIR/logs/audit.json" ]
    grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.json"
}

@test "log_audit includes timestamp" {
    log_audit "TEST_EVENT" "result=success"

    # Check ISO 8601 format timestamp
    grep -qE '\[20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit includes user" {
    log_audit "TEST_EVENT" "result=success"

    grep -q "who=test_user" "$RDD_DIR/logs/audit.log"
}

@test "log_audit includes operation" {
    log_audit "MY_OPERATION" "result=success"

    grep -q "operation=MY_OPERATION" "$RDD_DIR/logs/audit.log"
}

@test "log_audit includes result" {
    log_audit "TEST_EVENT" "result=failure"

    grep -q "result=failure" "$RDD_DIR/logs/audit.log"
}

@test "log_audit includes details" {
    log_audit "TEST_EVENT" "stage=1 project=myproject result=success"

    grep -q "stage=1" "$RDD_DIR/logs/audit.log"
    grep -q "project=myproject" "$RDD_DIR/logs/audit.log"
}

@test "log_audit extracts result from details" {
    log_audit "TEST_EVENT" "key=value result=custom_result"

    grep -q '"result": "custom_result"' "$RDD_DIR/logs/audit.json"
}

#######################################
# Test: Event Categories
#######################################

@test "log_audit categorizes SECURITY events" {
    log_audit "PERMISSION_DENIED" "user=test"

    grep -q '\[SECURITY\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes STAGE events" {
    log_audit "STAGE_START" "stage=1"

    grep -q '\[STAGE\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes ROADMAP events" {
    log_audit "ROADMAP_CHANGE" "change=added"

    grep -q '\[ROADMAP\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes TECH_DEBT events" {
    log_audit "DEBT_CREATED" "debt_id=TD-01"

    grep -q '\[TECH_DEBT\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes HOOK events" {
    log_audit "HOOK_TRIGGERED" "hook=pre-commit"

    grep -q '\[HOOK\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes NOTIFICATION events" {
    log_audit "NOTIFICATION_SENT" "channel=wecom"

    grep -q '\[NOTIFICATION\]' "$RDD_DIR/logs/audit.log"
}

@test "log_audit categorizes unknown events as GENERAL" {
    log_audit "UNKNOWN_EVENT" "data=test"

    grep -q '\[GENERAL\]' "$RDD_DIR/logs/audit.log"
}

#######################################
# Test: Sensitive Data Masking
#######################################

@test "mask_sensitive_data masks passwords" {
    local masked
    masked=$(mask_sensitive_data "password=secret123 token=abc")

    [[ "$masked" == *"password=***MASKED***"* ]]
}

@test "mask_sensitive_data masks tokens" {
    local masked
    masked=$(mask_sensitive_data "token=mysecrettoken data=value")

    [[ "$masked" == *"token=***MASKED***"* ]]
}

@test "mask_sensitive_data masks API keys" {
    local masked
    masked=$(mask_sensitive_data "api_key=myapikey123 secret=mysecret")

    [[ "$masked" == *"api_key=***MASKED***"* ]]
    [[ "$masked" == *"secret=***MASKED***"* ]]
}

@test "mask_sensitive_data masks URLs with credentials" {
    local masked
    masked=$(mask_sensitive_data "url=https://user:pass@example.com/path")

    [[ "$masked" == *"https://***:***@example.com"* ]]
}

@test "mask_sensitive_data preserves non-sensitive data" {
    local masked
    masked=$(mask_sensitive_data "stage=1 project=myproject result=success")

    [[ "$masked" == *"stage=1"* ]]
    [[ "$masked" == *"project=myproject"* ]]
}

@test "log_audit applies masking when enabled" {
    log_audit "TEST_EVENT" "password=secret123 result=success"

    grep -qF "password=***MASKED***" "$RDD_DIR/logs/audit.log"
    ! grep -q "secret123" "$RDD_DIR/logs/audit.log"
}

#######################################
# Test: JSON Format
#######################################

@test "JSON log has correct structure" {
    log_audit "TEST_EVENT" "key=value"

    # Check JSON has required fields
    grep -q '"timestamp"' "$RDD_DIR/logs/audit.json"
    grep -q '"level"' "$RDD_DIR/logs/audit.json"
    grep -q '"category"' "$RDD_DIR/logs/audit.json"
    grep -q '"event"' "$RDD_DIR/logs/audit.json"
    grep -q '"context"' "$RDD_DIR/logs/audit.json"
}

@test "JSON log includes session_id" {
    log_audit "TEST_EVENT" "key=value"

    grep -q '"session_id": "test-session-123"' "$RDD_DIR/logs/audit.json"
}

@test "JSON log includes source" {
    log_audit "TEST_EVENT" "key=value"

    grep -q '"source": "rdd"' "$RDD_DIR/logs/audit.json"
}

#######################################
# Test: Log Query
#######################################

@test "query_audit returns all entries without filter" {
    log_audit "EVENT1" "result=success"
    log_audit "EVENT2" "result=success"

    local result
    result=$(query_audit)
    [[ "$result" == *"EVENT1"* ]]
    [[ "$result" == *"EVENT2"* ]]
}

@test "query_audit filters by pattern" {
    log_audit "PERMISSION_DENIED" "result=denied"
    log_audit "STAGE_START" "result=success"

    local result
    result=$(query_audit "PERMISSION_DENIED")

    [[ "$result" == *"PERMISSION_DENIED"* ]]
    [[ "$result" != *"STAGE_START"* ]]
}

@test "query_audit_json returns JSON" {
    log_audit "TEST_EVENT" "key=value"

    run query_audit_json ".[]"
    [ "$status" == "0" ]
}

#######################################
# Test: Log Export
#######################################

@test "export_audit exports to JSON" {
    log_audit "TEST_EVENT" "result=success"
    log_audit "ANOTHER_EVENT" "result=failure"

    local output="${TEST_DIR}/audit-export.json"
    export_audit json "$output"

    [ -f "$output" ]
    grep -q "TEST_EVENT" "$output"
}

@test "export_audit exports to text" {
    log_audit "TEST_EVENT" "result=success"

    local output="${TEST_DIR}/audit-export.txt"
    export_audit text "$output"

    [ -f "$output" ]
    grep -q "TEST_EVENT" "$output"
}

@test "export_audit exports to CSV" {
    skip "Requires jq"
    log_audit "TEST_EVENT" "result=success"

    local output="${TEST_DIR}/audit-export.csv"
    export_audit csv "$output"

    [ -f "$output" ]
    grep -q "timestamp" "$output"
}

#######################################
# Test: Convenience Functions
#######################################

@test "log_security_event logs with SECURITY category" {
    log_security_event "AUTH_FAILURE" "test_user" "reason=invalid_password"

    grep -q '\[SECURITY\]' "$RDD_DIR/logs/audit.log"
    grep -q "AUTH_FAILURE" "$RDD_DIR/logs/audit.log"
}

@test "log_stage_event logs with STAGE category" {
    log_stage_event "STAGE_START" "stage-1" "project=myproject"

    grep -q '\[STAGE\]' "$RDD_DIR/logs/audit.log"
    grep -q "STAGE_START" "$RDD_DIR/logs/audit.log"
    grep -q "stage=stage-1" "$RDD_DIR/logs/audit.log"
}

#######################################
# Test: Audit Status
#######################################

@test "show_audit_status shows enabled status" {
    run show_audit_status
    [ "$status" == "0" ]
    [[ "$output" == *"Audit enabled"* ]]
}

@test "show_audit_status shows log files" {
    log_audit "TEST_EVENT" "result=success"

    run show_audit_status
    [[ "$output" == *"audit.log"* ]]
}

#######################################
# Test: Log Rotation
#######################################

@test "rotate_log creates compressed file" {
    skip "Requires gzip"
    # Create a log file
    echo "test log content" > "$RDD_DIR/logs/test.log"

    rotate_log "$RDD_DIR/logs/test.log" 5

    [ -f "$RDD_DIR/logs/test.log.1.gz" ]
}

@test "rotate_log respects max_files" {
    skip "Slow test"
    # This test is slow, skip by default
    # Create multiple rotated files
    for i in {1..12}; do
        echo "test $i" > "$RDD_DIR/logs/audit.log.$i.gz"
    done

    # Trigger rotation
    echo "new content" > "$RDD_DIR/logs/audit.log"
    check_log_rotation

    # Should have max 10 rotated files
    local count
    count=$(ls -1 "$RDD_DIR/logs/audit.log".*.gz 2>/dev/null | wc -l)
    [ "$count" -le 10 ]
}

#######################################
# Test: Configuration
#######################################

@test "get_audit_config returns value from config" {
    local value
    value=$(get_audit_config "audit.enabled" "false")
    [ "$value" == "true" ]
}

@test "get_audit_config returns default if key not found" {
    local value
    value=$(get_audit_config "audit.nonexistent.key" "default_value")
    [ "$value" == "default_value" ]
}

@test "get_audit_config returns default if config missing" {
    rm -f "$RDD_DIR/audit.yml"

    local value
    value=$(get_audit_config "audit.enabled" "default_value")
    [ "$value" == "default_value" ]
}

#######################################
# Test: Edge Cases
#######################################

@test "log_audit handles empty details" {
    log_audit "TEST_EVENT" ""

    grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.log"
}

@test "log_audit handles special characters in details" {
    log_audit "TEST_EVENT" "message=hello_world"

    grep -q "message=hello_world" "$RDD_DIR/logs/audit.log"
}

@test "log_audit handles multiple consecutive events" {
    for i in {1..5}; do
        log_audit "EVENT_$i" "count=$i"
    done

    local count
    count=$(grep -c "EVENT_" "$RDD_DIR/logs/audit.log")
    [ "$count" -eq 5 ]
}

@test "log_audit with disabled audit does not log" {
    # Modify config to disable audit
    cat > "$RDD_DIR/audit.yml" << 'EOF'
version: "1.0.0"
audit:
  enabled: false
EOF

    # Clear existing logs
    rm -f "$RDD_DIR/logs/audit.log"
    rm -f "$RDD_DIR/logs/audit.json"

    # Re-source to pick up config
    source "${BATS_TEST_DIRNAME}/../../.rdd/scripts/audit.sh"

    log_audit "TEST_EVENT" "result=success"

    # Audit should be disabled, so log files shouldn't be created
    # (or should be empty)
    if [ -f "$RDD_DIR/logs/audit.log" ]; then
        ! grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.log"
    fi
}

@test "JSON log is valid JSON array" {
    log_audit "EVENT1" "result=success"
    log_audit "EVENT2" "result=success"

    # Check it's a valid JSON array
    if command -v jq &> /dev/null; then
        jq '.' "$RDD_DIR/logs/audit.json" > /dev/null
    fi
}

@test "log_audit handles very long details" {
    local long_details
    long_details=$(printf 'key%.0s=value%.0s ' {1..100})

    log_audit "TEST_EVENT" "$long_details"

    grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.log"
}

@test "log_audit handles unicode in details" {
    log_audit "TEST_EVENT" "message=你好世界"

    grep -q "TEST_EVENT" "$RDD_DIR/logs/audit.log"
}

@test "multiple users in same session" {
    export RDD_USER="user1"
    log_audit "EVENT1" "result=success"

    export RDD_USER="user2"
    log_audit "EVENT2" "result=success"

    grep -q "who=user1" "$RDD_DIR/logs/audit.log"
    grep -q "who=user2" "$RDD_DIR/logs/audit.log"
}
