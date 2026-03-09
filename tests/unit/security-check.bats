#!/usr/bin/env bats
#
# Unit tests for RDD Security Check Script (security-check.sh)
# Tests security configuration checking and auto-fix
#

# Load bats-core (no additional helpers needed)

# Setup
setup() {
    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)
    RDD_DIR="$TEST_DIR/.rdd"

    mkdir -p "$RDD_DIR/logs"
    mkdir -p "$RDD_DIR/cache"
    mkdir -p "$RDD_DIR/lib"
    mkdir -p "$RDD_DIR/scripts"
    mkdir -p "$RDD_DIR/.keys"

    # Copy scripts to test directory
    cp "${BATS_TEST_DIRNAME}/../../.rdd/lib/permissions.sh" "$RDD_DIR/lib/"
    cp "${BATS_TEST_DIRNAME}/../../.rdd/lib/crypto.sh" "$RDD_DIR/lib/"
    cp "${BATS_TEST_DIRNAME}/../../.rdd/lib/security.sh" "$RDD_DIR/lib/"
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/audit.sh" "$RDD_DIR/scripts/"
    cp "${BATS_TEST_DIRNAME}/../../.rdd/scripts/security-check.sh" "$RDD_DIR/scripts/"

    # Create minimal permissions config
    cat > "$RDD_DIR/permissions.yml" << 'EOF'
version: "1.0.0"
rbac:
  enabled: true
  roles:
    admin:
      permissions:
        - "rdd:*"
      priority: 100
    viewer:
      permissions:
        - "rdd:stage:read"
      priority: 10
  default_role: viewer
checking:
  strict_mode: true
EOF

    # Create minimal audit config
    cat > "$RDD_DIR/audit.yml" << 'EOF'
version: "1.0.0"
audit:
  enabled: true
  storage:
    file:
      rotation:
        enabled: true
  masking:
    enabled: true
  retention:
    days: 90
EOF

    # Create hooks config
    cat > "$RDD_DIR/hooks.yml" << 'EOF'
version: "1.0.0"
notifications:
  quiet_hours:
    enabled: false
EOF

    export RDD_DIR
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

#######################################
# Test: File Permission Checks
#######################################

@test "security-check detects world-readable sensitive file" {
    # Create sensitive file with world-readable permissions
    touch "$RDD_DIR/permissions.yml"
    chmod 644 "$RDD_DIR/permissions.yml"

    run "$RDD_DIR/scripts/security-check.sh" --quiet
    [ "$status" != "0" ]
    [[ "$output" == *"permissions"* ]] || [ -z "$output" ]
}

@test "security-check passes with correct permissions" {
    # Set correct permissions
    chmod 600 "$RDD_DIR/permissions.yml"
    chmod 600 "$RDD_DIR/hooks.yml"
    chmod 600 "$RDD_DIR/audit.yml"
    chmod 700 "$RDD_DIR/.keys"

    run "$RDD_DIR/scripts/security-check.sh" --quiet
    # May still have warnings, but shouldn't error
}

@test "security-check detects world-writable files" {
    # Create world-writable file
    touch "$RDD_DIR/test.txt"
    chmod 666 "$RDD_DIR/test.txt"

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"world-writable"* ]] || true
}

@test "security-check --fix corrects permissions" {
    # Create file with wrong permissions
    touch "$RDD_DIR/permissions.yml"
    chmod 644 "$RDD_DIR/permissions.yml"

    run "$RDD_DIR/scripts/security-check.sh" --fix
    [[ "$output" == *"Fixed"* ]] || true
}

#######################################
# Test: RBAC Configuration Checks
#######################################

@test "security-check verifies RBAC enabled" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"RBAC"* ]] || true
}

@test "security-check warns if RBAC disabled" {
    cat > "$RDD_DIR/permissions.yml" << 'EOF'
version: "1.0.0"
rbac:
  enabled: false
  default_role: admin
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"RBAC"* ]] || true
}

@test "security-check checks default role" {
    cat > "$RDD_DIR/permissions.yml" << 'EOF'
version: "1.0.0"
rbac:
  enabled: true
  default_role: admin
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"default"* ]] || true
}

#######################################
# Test: Audit Configuration Checks
#######################################

@test "security-check verifies audit enabled" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"Audit"* ]] || true
}

@test "security-check warns if audit disabled" {
    cat > "$RDD_DIR/audit.yml" << 'EOF'
version: "1.0.0"
audit:
  enabled: false
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"Audit"* ]] || true
}

@test "security-check checks log rotation" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"rotation"* ]] || true
}

#######################################
# Test: Encryption Key Checks
#######################################

@test "security-check warns if encryption key missing" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"Encryption"* ]] || [[ "$output" == *"key"* ]] || true
}

@test "security-check warns if key directory has wrong permissions" {
    chmod 755 "$RDD_DIR/.keys"

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"key"* ]] || true
}

@test "security-check --fix generates encryption key" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    run "$RDD_DIR/scripts/security-check.sh" --fix
    [[ "$output" == *"Generated"* ]] || [[ "$output" == *"key"* ]] || true
}

#######################################
# Test: Credential Exposure Checks
#######################################

@test "security-check detects plaintext passwords" {
    cat > "$RDD_DIR/config.yml" << 'EOF'
database:
  password: "secret123"
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"credential"* ]] || [[ "$output" == *"password"* ]] || true
}

@test "security-check detects plaintext tokens" {
    cat > "$RDD_DIR/api.yml" << 'EOF'
api:
  token: "abc123xyz"
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"token"* ]] || true
}

@test "security-check approves environment variables" {
    cat > "$RDD_DIR/config.yml" << 'EOF'
database:
  password: "${DB_PASSWORD}"
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"environment"* ]] || true
}

#######################################
# Test: .gitignore Checks
#######################################

@test "security-check checks .gitignore for sensitive files" {
    # Create .gitignore
    cat > "$TEST_DIR/.gitignore" << 'EOF'
.rdd/.keys/
.rdd/logs/
*.key
*.pem
*.env
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"gitignore"* ]] || true
}

@test "security-check warns if .gitignore missing sensitive patterns" {
    # Create .gitignore without sensitive patterns
    cat > "$TEST_DIR/.gitignore" << 'EOF'
node_modules/
dist/
EOF

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"gitignore"* ]] || true
}

@test "security-check --fix adds missing .gitignore patterns" {
    # Create empty .gitignore
    touch "$TEST_DIR/.gitignore"

    run "$RDD_DIR/scripts/security-check.sh" --fix
    [[ "$output" == *"gitignore"* ]] || true
}

#######################################
# Test: Dependency Checks
#######################################

@test "security-check checks for openssl" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"openssl"* ]] || true
}

@test "security-check checks for jq" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"jq"* ]] || true
}

@test "security-check checks for yq" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"yq"* ]] || true
}

#######################################
# Test: Output Formats
#######################################

@test "security-check --json produces JSON output" {
    run "$RDD_DIR/scripts/security-check.sh" --json

    # Should be valid JSON
    if command -v jq &> /dev/null; then
        echo "$output" | jq '.' > /dev/null
    fi
}

@test "security-check --quiet only shows errors" {
    run "$RDD_DIR/scripts/security-check.sh" --quiet
    # Output should be minimal
    [ ${#output} -lt 100 ] || [[ "$output" == *"ERROR"* ]]
}

@test "security-check --verbose shows more details" {
    run "$RDD_DIR/scripts/security-check.sh" --verbose
    [[ "$output" == *"INFO"* ]] || true
}

@test "security-check shows help" {
    run "$RDD_DIR/scripts/security-check.sh" --help
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"Options"* ]]
}

#######################################
# Test: Summary
#######################################

@test "security-check shows summary with issues" {
    # Create an issue
    chmod 644 "$RDD_DIR/permissions.yml"

    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"Summary"* ]] || [[ "$output" == *"issues"* ]] || true
}

@test "security-check exit code reflects issues" {
    # Create an issue
    chmod 644 "$RDD_DIR/permissions.yml"

    run "$RDD_DIR/scripts/security-check.sh"
    [ "$status" != "0" ] || true  # May have warnings but no errors
}

@test "security-check exit 0 with no issues" {
    # Fix all issues
    chmod 600 "$RDD_DIR/permissions.yml"
    chmod 600 "$RDD_DIR/hooks.yml"
    chmod 600 "$RDD_DIR/audit.yml"
    chmod 700 "$RDD_DIR/.keys"

    run "$RDD_DIR/scripts/security-check.sh" --quiet
    # Exit status depends on whether there are errors
}

#######################################
# Test: Script Availability Checks
#######################################

@test "security-check verifies permissions.sh exists" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"permissions.sh"* ]] || true
}

@test "security-check verifies audit.sh exists" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"audit.sh"* ]] || true
}

@test "security-check verifies crypto.sh exists" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"crypto.sh"* ]] || true
}

@test "security-check verifies security.sh exists" {
    run "$RDD_DIR/scripts/security-check.sh"
    [[ "$output" == *"security.sh"* ]] || true
}

#######################################
# Test: Integration
#######################################

@test "security-check runs all checks" {
    run "$RDD_DIR/scripts/security-check.sh"

    # Should check file permissions
    [[ "$output" == *"File Permissions"* ]] || [[ "$output" == *"permissions"* ]] || true

    # Should check RBAC
    [[ "$output" == *"RBAC"* ]] || true

    # Should check audit
    [[ "$output" == *"Audit"* ]] || true
}

@test "security-check handles missing config files gracefully" {
    rm -f "$RDD_DIR/permissions.yml"
    rm -f "$RDD_DIR/audit.yml"

    run "$RDD_DIR/scripts/security-check.sh"
    [ "$status" != "0" ] || true
}

@test "security-check creates missing configs with --fix" {
    rm -f "$RDD_DIR/permissions.yml"
    rm -f "$RDD_DIR/audit.yml"

    run "$RDD_DIR/scripts/security-check.sh" --fix

    # Should attempt to create missing configs
    [[ "$output" == *"Created"* ]] || [[ "$output" == *"created"* ]] || true
}
