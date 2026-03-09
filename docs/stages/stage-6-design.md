# Stage 6: Security and Permissions Design Document

> Security, permissions, and audit system design for RDD Framework

---

## Status

- [x] Design Phase
- [ ] Implementation Phase
- [ ] Testing Phase
- [ ] Complete

---

## Goals

Design and implement a comprehensive security system for the RDD Framework including permission management, audit logging, sensitive data protection, and security hardening.

**One-liner**: Implement access control, audit trails, and security hardening to make RDD Framework production-ready.

**Detailed Goals**:
1. Design and implement a permission model that controls who can perform what actions
2. Create an audit logging system that records all important operations
3. Protect sensitive data through masking and encryption
4. Apply security hardening to prevent common vulnerabilities
5. Provide security configuration and validation tools

---

## Non-Goals

- **Fine-grained ACL**: Complex access control lists with resource-level permissions - defer to future versions
- **Single Sign-On (SSO)**: Integration with external identity providers - out of scope for now
- **Multi-tenant Isolation**: Complete isolation between different projects - requires architecture redesign
- **Real-time Security Monitoring**: SIEM integration and real-time threat detection - future enhancement
- **Advanced Encryption**: Custom encryption algorithms or hardware security modules (HSM) - standard encryption is sufficient

---

## Core Hypotheses

### Hypothesis 1: RBAC Sufficient for RDD Use Cases

- **Assumption**: Role-Based Access Control (RBAC) with 3 roles (admin, developer, viewer) covers all RDD use cases
- **Validation**: Review existing RDD operations and verify they fit into these role categories
- **Risk**: If fine-grained permissions are needed, RBAC may be too coarse; would need ACL extension

### Hypothesis 2: File-based Audit Logs Are Adequate

- **Assumption**: File-based audit logs with rotation meet audit requirements for RDD
- **Validation**: Test log rotation, search performance, and retention policy
- **Risk**: High-volume environments may need database-backed audit logs

### Hypothesis 3: Environment Variables + Optional Vault Covers Credential Security

- **Assumption**: Environment variables (Stage 1) combined with optional Vault integration provide sufficient credential security
- **Validation**: Test Vault integration and verify fallback to environment variables works
- **Risk**: Some organizations may require mandatory Vault/secret manager integration

### Hypothesis 4: Shell Script Security Hardening Is Achievable

- **Assumption**: Input validation and injection prevention can be implemented in Bash without significant performance impact
- **Validation**: Performance test with security checks enabled
- **Risk**: Complex validation logic may slow down Hook execution significantly

---

## Architecture Design

### 1. Permission Model (RBAC)

#### 1.1 Role Definitions

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RBAC Permission Model                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────┐                                                 │
│  │     ADMIN      │ Full control over all RDD operations            │
│  │                │ - Manage users and roles                        │
│  │                │ - Modify configuration                          │
│  │                │ - Execute all hooks and skills                  │
│  │                │ - Access audit logs                             │
│  │                │ - Manage tech debt and roadmap                  │
│  └────────────────┘                                                 │
│           │                                                         │
│           ▼                                                         │
│  ┌────────────────┐                                                 │
│  │   DEVELOPER    │ Execute development operations                   │
│  │                │ - Execute stages                                │
│  │                │ - Run tests                                     │
│  │                │ - Create/edit design documents                  │
│  │                │ - View logs and status                          │
│  │                │ - Cannot modify users or configuration          │
│  └────────────────┘                                                 │
│           │                                                         │
│           ▼                                                         │
│  ┌────────────────┐                                                 │
│  │     VIEWER     │ Read-only access                                │
│  │                │ - View documents and status                     │
│  │                │ - View roadmap and progress                     │
│  │                │ - Cannot execute any operations                 │
│  └────────────────┘                                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

#### 1.2 Permission Matrix

| Operation | Admin | Developer | Viewer |
|-----------|-------|-----------|--------|
| View documents | ✓ | ✓ | ✓ |
| View roadmap | ✓ | ✓ | ✓ |
| View status | ✓ | ✓ | ✓ |
| View audit logs | ✓ | ✗ | ✗ |
| Execute stages | ✓ | ✓ | ✗ |
| Run tests | ✓ | ✓ | ✗ |
| Edit design docs | ✓ | ✓ | ✗ |
| Manage tech debt | ✓ | ✓ | ✗ |
| Modify config | ✓ | ✗ | ✗ |
| Manage users | ✓ | ✗ | ✗ |
| Manage roles | ✓ | ✗ | ✗ |
| Execute hooks | ✓ | ✓ | ✗ |
| Modify roadmap | ✓ | ✗ | ✗ |

#### 1.3 Permission Configuration

File: `.rdd/permissions.yml`

```yaml
# RDD Permission Configuration
version: "1.0.0"

# RBAC Configuration
rbac:
  enabled: true

  # Role definitions
  roles:
    admin:
      description: "Full administrative access"
      permissions:
        - "rdd:*"           # All permissions
      priority: 100

    developer:
      description: "Development operations access"
      permissions:
        - "rdd:stage:read"
        - "rdd:stage:execute"
        - "rdd:test:read"
        - "rdd:test:execute"
        - "rdd:doc:read"
        - "rdd:doc:write"
        - "rdd:hook:execute"
        - "rdd:debt:read"
        - "rdd:debt:write"
        - "rdd:status:read"
      priority: 50

    viewer:
      description: "Read-only access"
      permissions:
        - "rdd:stage:read"
        - "rdd:test:read"
        - "rdd:doc:read"
        - "rdd:status:read"
        - "rdd:roadmap:read"
      priority: 10

  # User assignments
  users:
    - username: "${RDD_ADMIN_USER:-admin}"
      role: admin
      source: env  # env, file, or external

    - username: "${RDD_DEVELOPER_USER:-developer}"
      role: developer
      source: env

  # Default role for unauthenticated users
  default_role: viewer

# Permission checking settings
checking:
  # Enable strict mode (deny by default)
  strict_mode: true

  # Cache permission checks for performance
  cache_enabled: true
  cache_ttl: 300  # seconds

  # Log denied operations
  log_denied: true
```

#### 1.4 Permission Checking Implementation

File: `.rdd/scripts/permissions.sh`

```bash
#!/bin/bash
#
# Permission Management Script
# Implements RBAC permission checking for RDD operations
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
PERMISSIONS_FILE="${RDD_DIR}/permissions.yml"
CACHE_DIR="${RDD_DIR}/cache"
PERMISSION_CACHE="${CACHE_DIR}/permission_cache.json"

# Permission levels
PERM_ADMIN=100
PERM_DEVELOPER=50
PERM_VIEWER=10

#######################################
# Get current user
#######################################
get_current_user() {
    # Priority: RDD_USER env > system user
    echo "${RDD_USER:-${USER:-unknown}}"
}

#######################################
# Get user role
#######################################
get_user_role() {
    local user="$1"

    if [[ ! -f "$PERMISSIONS_FILE" ]]; then
        echo "viewer"
        return 0
    fi

    # Check cache first
    if [[ -f "$PERMISSION_CACHE" ]]; then
        local cached_role
        cached_role=$(jq -r ".users[\"${user}\"] // empty" "$PERMISSION_CACHE" 2>/dev/null)
        if [[ -n "$cached_role" ]]; then
            echo "$cached_role"
            return 0
        fi
    fi

    # Load from permissions file
    local role
    if command -v yq &> /dev/null; then
        role=$(yq eval ".rbac.users[] | select(.username == \"${user}\") | .role" "$PERMISSIONS_FILE" 2>/dev/null | head -1)
    fi

    # Default role if not found
    if [[ -z "$role" || "$role" == "null" ]]; then
        role=$(yq eval ".rbac.default_role" "$PERMISSIONS_FILE" 2>/dev/null || echo "viewer")
    fi

    # Update cache
    mkdir -p "$CACHE_DIR"
    if [[ -f "$PERMISSION_CACHE" ]]; then
        jq ".users[\"${user}\"] = \"${role}\"" "$PERMISSION_CACHE" > "${PERMISSION_CACHE}.tmp" 2>/dev/null && \
            mv "${PERMISSION_CACHE}.tmp" "$PERMISSION_CACHE"
    else
        echo "{\"users\":{\"${user}\":\"${role}\"}}" > "$PERMISSION_CACHE"
    fi

    echo "${role:-viewer}"
}

#######################################
# Get role priority
#######################################
get_role_priority() {
    local role="$1"

    case "$role" in
        admin)    echo $PERM_ADMIN ;;
        developer) echo $PERM_DEVELOPER ;;
        viewer)   echo $PERM_VIEWER ;;
        *)        echo $PERM_VIEWER ;;
    esac
}

#######################################
# Check if user has permission
#######################################
has_permission() {
    local operation="$1"
    local user="${2:-$(get_current_user)}"

    # Check if RBAC is enabled
    local rbac_enabled
    rbac_enabled=$(yq eval ".rbac.enabled" "$PERMISSIONS_FILE" 2>/dev/null || echo "false")

    if [[ "$rbac_enabled" != "true" ]]; then
        # RBAC disabled, allow all
        return 0
    fi

    local role
    role=$(get_user_role "$user")

    # Admin has all permissions
    if [[ "$role" == "admin" ]]; then
        return 0
    fi

    # Check specific permission
    local has_perm
    has_perm=$(yq eval ".rbac.roles[\"${role}\"].permissions[] | select(. == \"${operation}\" or . == \"rdd:*\")" "$PERMISSIONS_FILE" 2>/dev/null)

    if [[ -n "$has_perm" ]]; then
        return 0
    fi

    # Permission denied
    if [[ "$(yq eval '.checking.log_denied' "$PERMISSIONS_FILE" 2>/dev/null || echo 'true')" == "true" ]]; then
        log_audit "PERMISSION_DENIED" "user=$user operation=$operation role=$role"
    fi

    return 1
}

#######################################
# Require permission (fail if not authorized)
#######################################
require_permission() {
    local operation="$1"
    local user="${2:-$(get_current_user)}"

    if ! has_permission "$operation" "$user"; then
        echo "[ERROR] Permission denied: user '$user' cannot perform '$operation'" >&2
        exit 1
    fi
}

#######################################
# List user permissions
#######################################
list_permissions() {
    local user="${1:-$(get_current_user)}"
    local role
    role=$(get_user_role "$user")

    echo "User: $user"
    echo "Role: $role"
    echo "Permissions:"

    if command -v yq &> /dev/null; then
        yq eval ".rbac.roles[\"${role}\"].permissions[]" "$PERMISSIONS_FILE" 2>/dev/null | while read -r perm; do
            echo "  - $perm"
        done
    fi
}

# Export functions for use in other scripts
export -f get_current_user get_user_role has_permission require_permission list_permissions
```

---

### 2. Audit Logging System

#### 2.1 Audit Log Design

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Audit Logging Architecture                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐        │
│  │   Skills     │     │    Hooks     │     │   Commands   │        │
│  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘        │
│         │                    │                    │                 │
│         └────────────────────┼────────────────────┘                 │
│                              │                                      │
│                              ▼                                      │
│                    ┌──────────────────┐                             │
│                    │   audit_log()    │                             │
│                    │  (log_audit.sh)  │                             │
│                    └────────┬─────────┘                             │
│                             │                                       │
│         ┌───────────────────┼───────────────────┐                   │
│         │                   │                   │                   │
│         ▼                   ▼                   ▼                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │ audit.log   │    │ audit.json  │    │  External   │             │
│  │ (Human)     │    │ (Machine)   │    │  Systems    │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

#### 2.2 Audit Log Format

**Human-readable format (audit.log)**:
```
[2026-03-07T10:30:45Z] [INFO] [AUDIT] who=admin operation=STAGE_START what=stage-2 where=skill:rdd-stage result=success
[2026-03-07T10:31:02Z] [WARN] [AUDIT] who=developer operation=PERMISSION_DENIED what=rdd:config:write where=hook:pre-commit result=denied reason="insufficient_role"
[2026-03-07T10:32:15Z] [INFO] [AUDIT] who=admin operation=ROADMAP_CHANGE what=stage-added where=skill:rdd-roadmap result=success details="Added Stage 5"
```

**JSON format (audit.json)**:
```json
{
  "timestamp": "2026-03-07T10:30:45Z",
  "level": "INFO",
  "category": "AUDIT",
  "event": {
    "who": "admin",
    "operation": "STAGE_START",
    "what": "stage-2",
    "where": "skill:rdd-stage",
    "when": "2026-03-07T10:30:45Z",
    "result": "success",
    "details": {}
  },
  "context": {
    "session_id": "sess-abc123",
    "ip_address": "127.0.0.1",
    "user_agent": "Claude-Agent/1.0"
  }
}
```

#### 2.3 Audit Log Configuration

File: `.rdd/audit.yml`

```yaml
# RDD Audit Configuration
version: "1.0.0"

# Audit settings
audit:
  enabled: true

  # What to audit
  events:
    # Security events (always audited)
    - category: SECURITY
      events:
        - PERMISSION_DENIED
        - AUTH_FAILURE
        - CONFIG_CHANGE
      level: INFO
      mandatory: true

    # Stage operations
    - category: STAGE
      events:
        - STAGE_START
        - STAGE_COMPLETE
        - STAGE_FAIL
        - STAGE_ROLLBACK
      level: INFO

    # Roadmap changes
    - category: ROADMAP
      events:
        - ROADMAP_CHANGE
        - STAGE_ADDED
        - STAGE_REMOVED
        - STAGE_REORDERED
      level: INFO

    # Tech debt operations
    - category: TECH_DEBT
      events:
        - DEBT_CREATED
        - DEBT_RESOLVED
        - DEBT_ESCALATED
      level: INFO

    # Hook executions
    - category: HOOK
      events:
        - HOOK_TRIGGERED
        - HOOK_SUCCESS
        - HOOK_FAILURE
      level: DEBUG

    # Notification events
    - category: NOTIFICATION
      events:
        - NOTIFICATION_SENT
        - NOTIFICATION_FAILED
      level: DEBUG

  # Storage configuration
  storage:
    # Log file settings
    file:
      enabled: true
      path: ".rdd/logs/audit.log"
      format: "text"  # text, json, or both
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 10
        compress: true

    # JSON log for machine processing
    json:
      enabled: true
      path: ".rdd/logs/audit.json"
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 30
        compress: true

    # External webhook (optional)
    webhook:
      enabled: false
      url: "${AUDIT_WEBHOOK_URL:-}"
      method: "POST"
      headers:
        Content-Type: "application/json"
      batch_size: 10
      flush_interval: "5s"

  # Retention policy
  retention:
    # Keep audit logs for 90 days
    days: 90

    # Archive old logs
    archive:
      enabled: true
      path: ".rdd/logs/archive"
      compress: true

  # Sensitive data handling
  masking:
    enabled: true

    # Fields to mask
    fields:
      - password
      - token
      - secret
      - api_key
      - credential

    # Mask pattern
    pattern: "***MASKED***"

    # Exclude from audit (never log)
    exclude:
      - "*.password"
      - "*.token"
      - "*.secret"
```

#### 2.4 Audit Logging Implementation

File: `.rdd/scripts/audit.sh`

```bash
#!/bin/bash
#
# Audit Logging Script
# Records all significant operations for compliance and debugging
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
AUDIT_CONFIG="${RDD_DIR}/audit.yml"
AUDIT_LOG="${RDD_DIR}/logs/audit.log"
AUDIT_JSON="${RDD_DIR}/logs/audit.json"

#######################################
# Initialize audit logging
#######################################
init_audit() {
    mkdir -p "$(dirname "$AUDIT_LOG")"

    if [[ ! -f "$AUDIT_LOG" ]]; then
        echo "# RDD Audit Log - Created $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$AUDIT_LOG"
    fi
}

#######################################
# Log audit event
#######################################
log_audit() {
    local operation="$1"
    shift
    local details="$*"

    # Check if audit is enabled
    local audit_enabled
    if [[ -f "$AUDIT_CONFIG" ]] && command -v yq &> /dev/null; then
        audit_enabled=$(yq eval '.audit.enabled' "$AUDIT_CONFIG" 2>/dev/null || echo "true")
    else
        audit_enabled="true"
    fi

    if [[ "$audit_enabled" != "true" ]]; then
        return 0
    fi

    init_audit

    local timestamp user session_id result

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    user="${RDD_USER:-${USER:-unknown}}"
    session_id="${RDD_SESSION_ID:-sess-$(date +%s)}"
    result="${details##*result=}"
    result="${result%% *}"
    [[ -z "$result" ]] && result="success"

    # Human-readable format
    local log_line
    log_line="[${timestamp}] [INFO] [AUDIT] who=${user} operation=${operation} ${details}"

    echo "$log_line" >> "$AUDIT_LOG"

    # JSON format
    local json_entry
    json_entry=$(cat <<EOF
{
  "timestamp": "${timestamp}",
  "level": "INFO",
  "category": "AUDIT",
  "event": {
    "who": "${user}",
    "operation": "${operation}",
    "when": "${timestamp}",
    "result": "${result}",
    "details": "${details}"
  },
  "context": {
    "session_id": "${session_id}"
  }
}
EOF
)
    echo "$json_entry" >> "$AUDIT_JSON"

    # Check log rotation
    check_log_rotation
}

#######################################
# Log security event
#######################################
log_security_event() {
    local event_type="$1"
    local user="${2:-${RDD_USER:-${USER:-unknown}}}"
    local details="${3:-}"

    log_audit "$event_type" "who=$user $details"
}

#######################################
# Check and rotate logs
#######################################
check_log_rotation() {
    local max_size="10485760"  # 10MB
    local max_files=10

    # Check text log
    if [[ -f "$AUDIT_LOG" ]]; then
        local size
        size=$(stat -f%z "$AUDIT_LOG" 2>/dev/null || stat -c%s "$AUDIT_LOG" 2>/dev/null || echo "0")
        if [[ "$size" -gt "$max_size" ]]; then
            rotate_log "$AUDIT_LOG" "$max_files"
        fi
    fi

    # Check JSON log
    if [[ -f "$AUDIT_JSON" ]]; then
        local size
        size=$(stat -f%z "$AUDIT_JSON" 2>/dev/null || stat -c%s "$AUDIT_JSON" 2>/dev/null || echo "0")
        if [[ "$size" -gt "$max_size" ]]; then
            rotate_log "$AUDIT_JSON" "$max_files"
        fi
    fi
}

#######################################
# Rotate log file
#######################################
rotate_log() {
    local log_file="$1"
    local max_files="$2"

    # Compress and rotate
    for ((i=max_files; i>=1; i--)); do
        if [[ -f "${log_file}.${i}.gz" ]]; then
            if [[ $i -eq $max_files ]]; then
                rm "${log_file}.${i}.gz"
            else
                mv "${log_file}.${i}.gz" "${log_file}.$((i+1)).gz"
            fi
        fi
    done

    # Compress current log
    if [[ -f "${log_file}.1" ]]; then
        mv "${log_file}.1" "${log_file}.1.tmp"
        gzip "${log_file}.1.tmp"
        mv "${log_file}.1.tmp.gz" "${log_file}.1.gz"
    fi

    # Move current log
    mv "$log_file" "${log_file}.1"

    # Create new log
    touch "$log_file"
}

#######################################
# Query audit logs
#######################################
query_audit() {
    local filter="${1:-}"
    local start_date="${2:-}"
    local end_date="${3:-}"

    if [[ -n "$filter" ]]; then
        grep -E "$filter" "$AUDIT_LOG"
    else
        cat "$AUDIT_LOG"
    fi
}

#######################################
# Export audit logs
#######################################
export_audit() {
    local format="${1:-json}"
    local output="${2:-audit-export.$format}"

    case "$format" in
        json)
            cp "$AUDIT_JSON" "$output"
            ;;
        csv)
            # Convert JSON to CSV
            jq -r '[.timestamp, .level, .event.who, .event.operation, .event.result] | @csv' "$AUDIT_JSON" > "$output"
            ;;
        text)
            cp "$AUDIT_LOG" "$output"
            ;;
        *)
            echo "Unknown format: $format" >&2
            return 1
            ;;
    esac

    echo "Audit exported to $output"
}

# Export functions
export -f log_audit log_security_event query_audit export_audit
```

---

### 3. Sensitive Data Handling

#### 3.1 Data Masking Strategy

```yaml
# Data Masking Rules
masking:
  # Field-level masking
  fields:
    # Passwords - always mask
    - pattern: "password"
      mask: "********"
      scope: all

    # Tokens - show first/last 4 chars
    - pattern: "token"
      mask: "****...****"
      show_first: 4
      show_last: 4

    # API Keys - show first 8 chars
    - pattern: "api_key"
      mask: "********..."
      show_first: 8

    # Secrets - always mask
    - pattern: "secret"
      mask: "[SECRET]"
      scope: all

    # Webhook URLs - mask credentials
    - pattern: "webhook_url"
      regex: "(https?://)([^:]+):([^@]+)@(.*)"
      replace: "\\1***:***@\\4"

  # Log masking
  logs:
    enabled: true
    # Patterns to mask in logs
    patterns:
      - "password=\\S+"
      - "token=\\S+"
      - "secret=\\S+"
      - "api_key=\\S+"
```

#### 3.2 Credential Encryption

File: `.rdd/scripts/crypto.sh`

```bash
#!/bin/bash
#
# Credential Encryption Utilities
# Provides encryption/decryption for sensitive data
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"
KEY_FILE="${RDD_DIR}/.keys/encryption.key"

#######################################
# Generate encryption key
#######################################
generate_key() {
    mkdir -p "$(dirname "$KEY_FILE")"

    # Generate 256-bit key
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32 > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "Encryption key generated: $KEY_FILE"
    else
        echo "openssl not found, using fallback key generation" >&2
        # Fallback: use /dev/urandom
        head -c 32 /dev/urandom | base64 > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
    fi
}

#######################################
# Encrypt data
#######################################
encrypt_data() {
    local plaintext="$1"

    if [[ ! -f "$KEY_FILE" ]]; then
        generate_key
    fi

    local key
    key=$(cat "$KEY_FILE")

    if command -v openssl &> /dev/null; then
        echo "$plaintext" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -base64
    else
        echo "openssl not available, data will not be encrypted" >&2
        echo "$plaintext"
    fi
}

#######################################
# Decrypt data
#######################################
decrypt_data() {
    local ciphertext="$1"

    if [[ ! -f "$KEY_FILE" ]]; then
        echo "Encryption key not found" >&2
        return 1
    fi

    local key
    key=$(cat "$KEY_FILE")

    if command -v openssl &> /dev/null; then
        echo "$ciphertext" | openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$key" -base64
    else
        echo "openssl not available" >&2
        return 1
    fi
}

#######################################
# Mask sensitive value
#######################################
mask_value() {
    local value="$1"
    local type="${2:-default}"
    local show_first="${3:-0}"
    local show_last="${4:-0}"

    local len=${#value}

    case "$type" in
        password)
            echo "********"
            ;;
        token)
            if [[ $len -gt 8 ]]; then
                echo "${value:0:4}****${value: -4}"
            else
                echo "********"
            fi
            ;;
        api_key)
            if [[ $len -gt 8 ]]; then
                echo "${value:0:8}..."
            else
                echo "********"
            fi
            ;;
        url)
            # Mask credentials in URL
            echo "$value" | sed -E 's|(https?://)([^:]+):([^@]+)@|\1***:***@|g'
            ;;
        *)
            if [[ $show_first -gt 0 || $show_last -gt 0 ]]; then
                local first="${value:0:$show_first}"
                local last="${value: -$show_last}"
                local masked_len=$((len - show_first - show_last))
                local masked=$(printf '*%.0s' $(seq 1 $masked_len))
                echo "${first}${masked}${last}"
            else
                echo "[REDACTED]"
            fi
            ;;
    esac
}

#######################################
# Check if Vault is available
#######################################
check_vault() {
    local vault_addr="${VAULT_ADDR:-}"
    local vault_token="${VAULT_TOKEN:-}"

    if [[ -n "$vault_addr" && -n "$vault_token" ]]; then
        # Test Vault connection
        if command -v curl &> /dev/null; then
            local response
            response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "X-Vault-Token: $vault_token" \
                "${vault_addr}/v1/sys/health" 2>/dev/null || echo "000")

            if [[ "$response" == "200" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}

#######################################
# Get secret from Vault
#######################################
get_vault_secret() {
    local path="$1"
    local key="${2:-}"

    if ! check_vault; then
        echo "Vault not available" >&2
        return 1
    fi

    local response
    response=$(curl -s \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        "${VAULT_ADDR}/v1/${path}" 2>/dev/null)

    if [[ -n "$key" ]]; then
        echo "$response" | jq -r ".data.${key}" 2>/dev/null
    else
        echo "$response" | jq -r '.data' 2>/dev/null
    fi
}

#######################################
# Store secret in Vault
#######################################
store_vault_secret() {
    local path="$1"
    shift
    local key_values=("$@")

    if ! check_vault; then
        echo "Vault not available" >&2
        return 1
    fi

    local data="{\"data\":{"
    local first=true
    for kv in "${key_values[@]}"; do
        local k="${kv%%=*}"
        local v="${kv#*=}"
        if [[ "$first" == "true" ]]; then
            first=false
        else
            data+=","
        fi
        data+="\"${k}\":\"${v}\""
    done
    data+="}}"

    curl -s \
        -X POST \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${VAULT_ADDR}/v1/${path}" >/dev/null 2>&1
}

# Export functions
export -f generate_key encrypt_data decrypt_data mask_value check_vault get_vault_secret store_vault_secret
```

#### 3.3 Vault Integration (Optional)

File: `.rdd/vault.yml`

```yaml
# HashiCorp Vault Integration (Optional)
version: "1.0.0"

# Vault configuration
vault:
  enabled: false  # Set to true to enable Vault integration

  # Connection settings
  address: "${VAULT_ADDR:-http://localhost:8200}"
  token: "${VAULT_TOKEN:-}"
  namespace: "${VAULT_NAMESPACE:-}"

  # Secret paths
  paths:
    # Credentials
    credentials: "secret/data/rdd/credentials"
    # Configuration secrets
    config: "secret/data/rdd/config"
    # API keys
    api_keys: "secret/data/rdd/api_keys"

  # Secret engines
  engines:
    # KV v2 for static secrets
    kv:
      enabled: true
      version: 2
      mount: "secret"

    # Transit for encryption as a service
    transit:
      enabled: false
      mount: "transit"
      key_name: "rdd-encryption"

  # Auto-renewal
  renewal:
    enabled: true
    interval: "1h"

  # Fallback behavior when Vault is unavailable
  fallback:
    # Use environment variables
    use_env: true
    # Use local encrypted storage
    use_local: true
    # Cache TTL
    cache_ttl: "5m"
```

---

### 4. Security Hardening

#### 4.1 Input Validation

File: `.rdd/scripts/security.sh`

```bash
#!/bin/bash
#
# Security Utilities
# Input validation, injection prevention, and security checks
#

set -euo pipefail

#######################################
# Validate input against injection patterns
#######################################
validate_input() {
    local input="$1"
    local type="${2:-text}"

    case "$type" in
        alphanumeric)
            if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                echo "Invalid input: only alphanumeric characters, underscores, and hyphens allowed" >&2
                return 1
            fi
            ;;

        path)
            # Prevent path traversal
            if [[ "$input" =~ \.\. ]]; then
                echo "Invalid path: path traversal detected" >&2
                return 1
            fi
            # Check for null bytes
            if [[ "$input" == *$'\0'* ]]; then
                echo "Invalid path: null byte detected" >&2
                return 1
            fi
            ;;

        command)
            # Check for command injection patterns
            local dangerous_patterns=(
                ';' '\|' '&' '\$\(' '\`' '\$\{' '&&' '||'
                '>' '<' '>>' '<<' '\$(' '$(('
            )

            for pattern in "${dangerous_patterns[@]}"; do
                if [[ "$input" =~ $pattern ]]; then
                    echo "Invalid input: potential command injection detected" >&2
                    return 1
                fi
            done
            ;;

        url)
            # Validate URL format
            if [[ ! "$input" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
                echo "Invalid URL format" >&2
                return 1
            fi
            ;;

        email)
            # Validate email format
            if [[ ! "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                echo "Invalid email format" >&2
                return 1
            fi
            ;;

        integer)
            if [[ ! "$input" =~ ^-?[0-9]+$ ]]; then
                echo "Invalid integer" >&2
                return 1
            fi
            ;;

        text)
            # Basic text validation - no control characters
            if [[ "$input" == *$'\n'* ]] || [[ "$input" == *$'\r'* ]]; then
                echo "Invalid input: control characters detected" >&2
                return 1
            fi
            ;;
    esac

    return 0
}

#######################################
# Sanitize input for safe use
#######################################
sanitize_input() {
    local input="$1"

    # Remove dangerous characters
    local sanitized
    sanitized=$(echo "$input" | sed 's/[;&|`$(){}<>]//g')

    # Escape special characters for shell
    sanitized=$(printf '%q' "$sanitized")

    echo "$sanitized"
}

#######################################
# Escape for YAML
#######################################
escape_yaml() {
    local input="$1"

    # Escape special YAML characters
    local escaped
    escaped=$(echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g')

    echo "$escaped"
}

#######################################
# Escape for JSON
#######################################
escape_json() {
    local input="$1"

    # Escape special JSON characters
    local escaped
    escaped=$(echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')

    echo "$escaped"
}

#######################################
# Secure file operations
#######################################
secure_read_file() {
    local filepath="$1"

    # Validate path
    if ! validate_input "$filepath" "path"; then
        return 1
    fi

    # Check file exists and is readable
    if [[ ! -f "$filepath" ]]; then
        echo "File not found: $filepath" >&2
        return 1
    fi

    if [[ ! -r "$filepath" ]]; then
        echo "File not readable: $filepath" >&2
        return 1
    fi

    # Check file permissions (should not be world-writable)
    local perms
    perms=$(stat -c "%a" "$filepath" 2>/dev/null || stat -f "%Lp" "$filepath" 2>/dev/null)
    if [[ "$((perms & 002))" -ne 0 ]]; then
        echo "Warning: file is world-writable: $filepath" >&2
    fi

    # Read file
    cat "$filepath"
}

#######################################
# Secure file write
#######################################
secure_write_file() {
    local filepath="$1"
    local content="$2"

    # Validate path
    if ! validate_input "$filepath" "path"; then
        return 1
    fi

    # Create directory if needed
    local dir
    dir=$(dirname "$filepath")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    # Write to temp file first
    local tmp_file="${filepath}.tmp.$$"
    echo "$content" > "$tmp_file"

    # Set secure permissions
    chmod 600 "$tmp_file"

    # Move to final location
    mv "$tmp_file" "$filepath"
}

#######################################
# Security configuration check
#######################################
security_check() {
    local issues=0

    echo "=== RDD Security Check ==="
    echo ""

    # Check file permissions
    echo "[1] Checking file permissions..."

    local sensitive_files=(
        ".rdd/permissions.yml"
        ".rdd/hooks.yml"
        ".rdd/config.yml"
    )

    for file in "${sensitive_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms
            perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)

            if [[ "$((perms & 077))" -ne 0 ]]; then
                echo "  [WARN] $file has group/other permissions: $perms"
                echo "         Recommended: chmod 600 $file"
                ((issues++))
            else
                echo "  [OK] $file permissions are secure"
            fi
        fi
    done

    # Check for exposed credentials
    echo ""
    echo "[2] Checking for exposed credentials..."

    if grep -rq "password\s*=" .rdd/ 2>/dev/null; then
        echo "  [WARN] Potential password exposure in .rdd/ files"
        ((issues++))
    else
        echo "  [OK] No obvious password exposure"
    fi

    # Check RBAC configuration
    echo ""
    echo "[3] Checking RBAC configuration..."

    if [[ -f ".rdd/permissions.yml" ]]; then
        if grep -q "enabled: true" .rdd/permissions.yml; then
            echo "  [OK] RBAC is enabled"
        else
            echo "  [WARN] RBAC is disabled"
            ((issues++))
        fi
    else
        echo "  [WARN] RBAC configuration not found"
        ((issues++))
    fi

    # Check audit logging
    echo ""
    echo "[4] Checking audit logging..."

    if [[ -f ".rdd/audit.yml" ]]; then
        if grep -q "enabled: true" .rdd/audit.yml; then
            echo "  [OK] Audit logging is enabled"
        else
            echo "  [WARN] Audit logging is disabled"
            ((issues++))
        fi
    else
        echo "  [WARN] Audit configuration not found"
        ((issues++))
    fi

    # Summary
    echo ""
    echo "=== Security Check Complete ==="
    if [[ $issues -eq 0 ]]; then
        echo "No security issues found."
    else
        echo "Found $issues security issue(s). Please review and fix."
    fi

    return $issues
}

# Export functions
export -f validate_input sanitize_input escape_yaml escape_json \
         secure_read_file secure_write_file security_check
```

#### 4.2 Security Configuration Checklist

File: `.rdd/security-checklist.md`

```markdown
# RDD Security Configuration Checklist

## Pre-deployment Security Checklist

### 1. File Permissions

- [ ] Set restrictive permissions on sensitive files
  ```bash
  chmod 600 .rdd/permissions.yml
  chmod 600 .rdd/hooks.yml
  chmod 600 .rdd/config.yml
  chmod 700 .rdd/logs
  chmod 700 .rdd/cache
  chmod 700 .rdd/.keys
  ```

- [ ] Verify no world-readable sensitive files
  ```bash
  find .rdd -type f -perm /004 -ls
  ```

- [ ] Verify no world-writable files
  ```bash
  find .rdd -type f -perm /002 -ls
  ```

### 2. Credential Security

- [ ] No credentials in version control
  ```bash
  # Check .gitignore includes
  grep -E "credentials|secrets|keys" .gitignore
  ```

- [ ] Use environment variables for secrets
  ```bash
  # Verify hooks.yml uses env vars
  grep -E '\$\{.*\}' .rdd/hooks.yml
  ```

- [ ] Encryption keys are protected
  ```bash
  ls -la .rdd/.keys/
  # Should show 600 permissions
  ```

### 3. RBAC Configuration

- [ ] RBAC is enabled
  ```yaml
  # .rdd/permissions.yml
  rbac:
    enabled: true
  ```

- [ ] Default role is restrictive
  ```yaml
  default_role: viewer  # or none
  ```

- [ ] Admin users are properly assigned
  ```yaml
  users:
    - username: "${RDD_ADMIN_USER}"
      role: admin
  ```

### 4. Audit Logging

- [ ] Audit logging is enabled
  ```yaml
  # .rdd/audit.yml
  audit:
    enabled: true
  ```

- [ ] Log rotation is configured
  ```yaml
  retention:
    days: 90
    archive:
      enabled: true
  ```

- [ ] Sensitive data masking is enabled
  ```yaml
  masking:
    enabled: true
  ```

### 5. Input Validation

- [ ] All user inputs are validated
- [ ] Path traversal is prevented
- [ ] Command injection is prevented
- [ ] File paths are sanitized

### 6. Network Security (if using webhooks)

- [ ] HTTPS endpoints only
- [ ] TLS certificate validation enabled
- [ ] Timeout configured for all requests

### 7. Vault Integration (if used)

- [ ] Vault address configured
  ```bash
  export VAULT_ADDR="https://vault.example.com"
  ```

- [ ] Vault token secured
  ```bash
  export VAULT_TOKEN="..."
  # Token should not be in version control
  ```

- [ ] Fallback strategy defined
  ```yaml
  fallback:
    use_env: true
    use_local: true
  ```

## Runtime Security Checks

### Run security check script

```bash
# Run automated security check
task rdd:security-check

# Or manually
.rdd/scripts/security.sh
```

### Check for security issues

```bash
# Check file permissions
find .rdd -type f -perm /007 -ls

# Check for exposed secrets
grep -r "password" .rdd/*.yml
grep -r "secret" .rdd/*.yml
grep -r "token" .rdd/*.yml

# Check audit logs
tail -100 .rdd/logs/audit.log | grep DENIED
```

## Security Incident Response

### If credentials are exposed

1. Rotate affected credentials immediately
2. Update configuration to use new credentials
3. Review audit logs for unauthorized access
4. Document incident in security log

### If RBAC is bypassed

1. Check for configuration errors
2. Review user assignments
3. Enable strict mode
4. Audit all permission changes

### If audit logs are tampered

1. Restore from backup
2. Check file permissions
3. Review system logs
4. Implement tamper-evident logging
```

---

## Acceptance Criteria

- [ ] Permission model designed and documented
  - [ ] RBAC with 3 roles defined
  - [ ] Permission matrix created
  - [ ] Permission checking mechanism implemented

- [ ] Audit logging implemented
  - [ ] Audit log format defined (who, when, what, where)
  - [ ] Audit log storage configured with rotation
  - [ ] Audit log retention policy implemented

- [ ] Sensitive data handling implemented
  - [ ] Data masking strategy defined
  - [ ] Credential encryption implemented
  - [ ] Vault integration (optional) designed

- [ ] Security hardening applied
  - [ ] Input validation implemented
  - [ ] Injection prevention implemented
  - [ ] Security configuration checklist created

- [ ] Unit tests for security functions
  - [ ] Permission checking tests
  - [ ] Audit logging tests
  - [ ] Input validation tests
  - [ ] Encryption/decryption tests

- [ ] Integration tests
  - [ ] RBAC workflow test
  - [ ] Audit log workflow test
  - [ ] Vault integration test (if enabled)

- [ ] Documentation complete
  - [ ] Security configuration guide
  - [ ] Permission management guide
  - [ ] Audit log query guide

---

## Known Limitations

- **RBAC Only**: No fine-grained ACL - will add complexity
- **File-based Audit**: May not scale for high-volume environments
- **No SSO**: External identity provider integration not included
- **No Real-time Monitoring**: Security events logged but not monitored in real-time
- **No MFA**: Multi-factor authentication not implemented

---

## Impact on Subsequent Stages

- **Stage 7 (Documentation)**: Security documentation needs to be included
- **Future Versions**: May need ACL extension if RBAC proves insufficient
- **Production Deployment**: Security checklist must be verified before deployment

---

## Implementation Plan

### Phase 1: Permission System (Day 1)

1. Create permissions.yml configuration
2. Implement permission.sh script
3. Add permission checks to existing scripts
4. Test RBAC workflow

### Phase 2: Audit Logging (Day 1-2)

1. Create audit.yml configuration
2. Implement audit.sh script
3. Integrate audit logging into hooks
4. Test audit log rotation

### Phase 3: Sensitive Data (Day 2)

1. Implement crypto.sh for encryption
2. Add data masking functions
3. Design Vault integration
4. Test encryption/decryption

### Phase 4: Security Hardening (Day 2-3)

1. Implement security.sh validation
2. Create security checklist
3. Add security check command
4. Test security validation

### Phase 5: Testing & Documentation (Day 3)

1. Write unit tests
2. Write integration tests
3. Create security documentation
4. Final review

---

## Review Log

> Design review details will be recorded here

---

## Appendix

### A. Permission Operations Reference

| Permission Code | Description | Role Required |
|-----------------|-------------|---------------|
| rdd:* | All permissions | admin |
| rdd:stage:read | View stage status | viewer |
| rdd:stage:execute | Execute stages | developer |
| rdd:stage:write | Modify stage configuration | admin |
| rdd:test:read | View test results | viewer |
| rdd:test:execute | Run tests | developer |
| rdd:doc:read | View documents | viewer |
| rdd:doc:write | Edit documents | developer |
| rdd:hook:execute | Execute hooks | developer |
| rdd:debt:read | View tech debt | viewer |
| rdd:debt:write | Manage tech debt | developer |
| rdd:config:read | View configuration | developer |
| rdd:config:write | Modify configuration | admin |
| rdd:user:read | View users | admin |
| rdd:user:write | Manage users | admin |
| rdd:audit:read | View audit logs | admin |

### B. Audit Event Types

| Category | Event | Description |
|----------|-------|-------------|
| SECURITY | PERMISSION_DENIED | Permission check failed |
| SECURITY | AUTH_FAILURE | Authentication failed |
| SECURITY | CONFIG_CHANGE | Configuration modified |
| STAGE | STAGE_START | Stage execution started |
| STAGE | STAGE_COMPLETE | Stage completed successfully |
| STAGE | STAGE_FAIL | Stage execution failed |
| STAGE | STAGE_ROLLBACK | Stage rollback triggered |
| ROADMAP | ROADMAP_CHANGE | Roadmap modified |
| ROADMAP | STAGE_ADDED | New stage added |
| ROADMAP | STAGE_REMOVED | Stage removed |
| TECH_DEBT | DEBT_CREATED | New tech debt recorded |
| TECH_DEBT | DEBT_RESOLVED | Tech debt resolved |
| HOOK | HOOK_TRIGGERED | Hook execution started |
| HOOK | HOOK_SUCCESS | Hook completed successfully |
| HOOK | HOOK_FAILURE | Hook execution failed |

### C. Security Commands

```bash
# Check permissions
task rdd:check-permission <operation> [user]

# List user permissions
task rdd:list-permissions [user]

# Query audit logs
task rdd:audit-query [filter] [start_date] [end_date]

# Export audit logs
task rdd:audit-export <format> [output]

# Run security check
task rdd:security-check

# Encrypt credential
task rdd:encrypt <plaintext>

# Decrypt credential
task rdd:decrypt <ciphertext>
```
