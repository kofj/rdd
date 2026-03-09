# Stage 4: Error Handling and Observability

> Design document for error handling, retry, degradation, and observability system

---

## Status

- [x] Planning
- [x] In Progress
- [x] Implementation Complete
- [ ] Testing Complete (199/277 tests passing)
- [ ] Code Review Complete

---

## Goals

**One-line description**: Build a comprehensive error handling and observability system to make the RDD framework production-ready.

**Detailed description**:

This stage implements a robust error handling system with proper error classification, retry mechanisms, degradation strategies, and observability capabilities including structured logging, metrics, and health checks. The goal is to ensure the framework can gracefully handle failures, provide visibility into its operations, and support troubleshooting in production environments.

---

## Non-Goals

- **Distributed tracing**: Not implementing distributed tracing (e.g., Jaeger, Zipkin) - out of scope for single-process framework
- **Complex alerting rules**: Not building a full alerting system - rely on external notification channels
- **Performance profiling**: Not implementing profiling tools - defer to Stage 5
- **Audit logging**: Not implementing comprehensive audit logging - defer to Stage 6 (Security and Permissions)
- **Multi-process coordination**: Not handling multi-process error coordination - framework is single-process

---

## Core Hypotheses

### Hypothesis A: Errors can be classified into recoverable and non-recoverable categories

- **Content**: All errors in the RDD framework can be classified as either recoverable (can be fixed by retry or degradation) or non-recoverable (require human intervention)
- **Verification**: Design error taxonomy covering all known error scenarios
- **Risk**: If classification is incomplete, some errors may not be handled appropriately

### Hypothesis B: Exponential backoff with jitter effectively handles transient failures

- **Content**: Exponential backoff with random jitter can handle most transient network and resource failures
- **Verification**: Test retry mechanism against simulated failures
- **Risk**: If backoff parameters are wrong, may cause thundering herd or excessive delays

### Hypothesis C: Circuit breaker pattern prevents cascading failures

- **Content**: Circuit breaker can detect persistent failures and prevent cascading damage
- **Verification**: Test circuit breaker under high failure rate scenarios
- **Risk**: Circuit breaker may be too sensitive or not sensitive enough

### Hypothesis D: Structured JSON logging enables effective troubleshooting

- **Content**: JSON-formatted logs with consistent fields enable efficient log analysis and debugging
- **Verification**: Use logs to diagnose simulated issues
- **Risk**: Log format may be incompatible with existing log aggregation systems

---

## Design Details

### 1. Error Classification System

#### 1.1 Error Categories

```
Error Classification Taxonomy
==============================

Error
├── Recoverable (Auto-handled)
│   ├── Transient (Retry with backoff)
│   │   ├── Network timeout
│   │   ├── Rate limit exceeded
│   │   ├── Service unavailable (503)
│   │   └── Resource temporarily unavailable
│   ├── Degradable (Fallback behavior)
│   │   ├── Notification channel failure
│   │   ├── Template rendering failure
│   │   ├── Config loading failure (use defaults)
│   │   └── External service timeout
│   └── Circuit Breaker (Fail fast)
│       ├── Persistent notification failures
│       └── Persistent external API failures
│
└── Non-Recoverable (Human intervention required)
    ├── Configuration
    │   ├── Invalid configuration format
    │   ├── Missing required configuration
    │   └── Invalid credentials
    ├── Logic
    │   ├── Invalid hook trigger type
    │   ├── Template syntax error
    │   └── Invalid variable substitution
    ├── Environment
    │   ├── Missing required tools (curl, sendmail)
    │   ├── Insufficient permissions
    │   └── Invalid working directory
    └── System
        ├── Out of memory
        ├── Disk full
        └── Process killed
```

#### 1.2 Error Severity Levels

| Level | Code | Name | Description | Response |
|-------|------|------|-------------|----------|
| P0 | E001 | Critical | System cannot continue, human intervention required | Immediate notification, halt operation |
| P1 | E002 | High | Major functionality degraded, operation may continue | Notification, log and continue with fallback |
| P2 | E003 | Medium | Minor functionality affected | Log warning, continue |
| P3 | E004 | Low | Informational, no functional impact | Log info only |

#### 1.3 Error Codes and Messages

```yaml
# Error code registry
error_codes:
  # Configuration errors (E1xx)
  E100:
    code: "CONFIG_ERROR"
    severity: "P0"
    message: "Configuration error"
    recoverable: false
    user_message: "Configuration file is invalid. Please check the format and values."

  E101:
    code: "CONFIG_NOT_FOUND"
    severity: "P0"
    message: "Configuration file not found"
    recoverable: false
    user_message: "Configuration file {file} not found. Please create it from the example."

  E102:
    code: "CONFIG_PARSE_ERROR"
    severity: "P0"
    message: "Failed to parse configuration"
    recoverable: false
    user_message: "Failed to parse configuration: {reason}. Please check YAML syntax."

  # Notification errors (E2xx)
  E200:
    code: "NOTIFICATION_FAILED"
    severity: "P1"
    message: "Failed to send notification"
    recoverable: true
    user_message: "Failed to send notification via {channel}. Will retry."

  E201:
    code: "CHANNEL_DISABLED"
    severity: "P2"
    message: "Notification channel is disabled"
    recoverable: true
    user_message: "Channel {channel} is disabled. Skipping."

  E202:
    code: "ALL_CHANNELS_FAILED"
    severity: "P1"
    message: "All notification channels failed"
    recoverable: true
    user_message: "All notification channels failed. Check configuration."

  E203:
    code: "CIRCUIT_BREAKER_OPEN"
    severity: "P2"
    message: "Circuit breaker is open"
    recoverable: true
    user_message: "Circuit breaker open for {channel}. Notification skipped."

  # Network errors (E3xx)
  E300:
    code: "NETWORK_TIMEOUT"
    severity: "P1"
    message: "Network request timed out"
    recoverable: true
    user_message: "Request to {url} timed out. Will retry."

  E301:
    code: "NETWORK_ERROR"
    severity: "P1"
    message: "Network request failed"
    recoverable: true
    user_message: "Network request failed: {reason}. Will retry."

  E302:
    code: "RATE_LIMIT_EXCEEDED"
    severity: "P2"
    message: "Rate limit exceeded"
    recoverable: true
    user_message: "Rate limit exceeded. Waiting {wait_time}s before retry."

  E303:
    code: "SERVICE_UNAVAILABLE"
    severity: "P1"
    message: "Service unavailable"
    recoverable: true
    user_message: "Service {service} unavailable (HTTP {status}). Will retry."

  # Hook errors (E4xx)
  E400:
    code: "HOOK_EXECUTION_FAILED"
    severity: "P1"
    message: "Hook script execution failed"
    recoverable: false
    user_message: "Hook {hook_name} execution failed: {reason}"

  E401:
    code: "HOOK_NOT_FOUND"
    severity: "P1"
    message: "Hook script not found"
    recoverable: false
    user_message: "Hook script {hook_name} not found."

  E402:
    code: "HOOK_PERMISSION_DENIED"
    severity: "P1"
    message: "Hook script not executable"
    recoverable: false
    user_message: "Hook script {hook_name} is not executable. Run: chmod +x {path}"

  # Template errors (E5xx)
  E500:
    code: "TEMPLATE_NOT_FOUND"
    severity: "P2"
    message: "Template not found"
    recoverable: true
    user_message: "Template {template} not found. Using default."

  E501:
    code: "TEMPLATE_RENDER_ERROR"
    severity: "P2"
    message: "Failed to render template"
    recoverable: true
    user_message: "Failed to render template: {reason}. Using fallback."

  # Environment errors (E6xx)
  E600:
    code: "MISSING_TOOL"
    severity: "P0"
    message: "Required tool not found"
    recoverable: false
    user_message: "Required tool '{tool}' not found. Please install it."

  E601:
    code: "PERMISSION_DENIED"
    severity: "P0"
    message: "Permission denied"
    recoverable: false
    user_message: "Permission denied: {operation}. Check file permissions."

  E602:
    code: "INVALID_DIRECTORY"
    severity: "P0"
    message: "Invalid working directory"
    recoverable: false
    user_message: "Working directory {dir} does not exist or is not accessible."
```

---

### 2. Retry Mechanism

#### 2.1 Exponential Backoff Strategy

```bash
# Retry configuration
retry_config:
  max_attempts: 3
  initial_delay: 1s
  max_delay: 30s
  backoff_multiplier: 2
  jitter: true
  jitter_range: 0.5  # +/- 50% randomization

# Retry flow
retry_with_backoff() {
    local attempt=1
    local delay=$initial_delay

    while [[ $attempt -le $max_attempts ]]; do
        if execute_operation; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            # Add jitter to prevent thundering herd
            if [[ "$jitter" == "true" ]]; then
                local jitter_factor=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); print 1 + (rand() - 0.5) * 0.5}')
                delay=$(awk "BEGIN {print int($delay * $jitter_factor)}")
            fi

            log_warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
            sleep "$delay"

            # Exponential backoff
            delay=$((delay * backoff_multiplier))
            if [[ $delay -gt $max_delay ]]; then
                delay=$max_delay
            fi
        fi

        ((attempt++))
    done

    return 1
}
```

#### 2.2 Retry-able vs Non-retry-able Errors

```yaml
retry_policy:
  retryable:
    - E200  # NOTIFICATION_FAILED
    - E300  # NETWORK_TIMEOUT
    - E301  # NETWORK_ERROR
    - E302  # RATE_LIMIT_EXCEEDED
    - E303  # SERVICE_UNAVAILABLE

  non_retryable:
    - E100  # CONFIG_ERROR
    - E101  # CONFIG_NOT_FOUND
    - E102  # CONFIG_PARSE_ERROR
    - E400  # HOOK_EXECUTION_FAILED
    - E401  # HOOK_NOT_FOUND
    - E402  # HOOK_PERMISSION_DENIED
    - E500  # TEMPLATE_NOT_FOUND (use default)
    - E501  # TEMPLATE_RENDER_ERROR (use fallback)
    - E600  # MISSING_TOOL
    - E601  # PERMISSION_DENIED
    - E602  # INVALID_DIRECTORY

  conditional:
    E202:  # ALL_CHANNELS_FAILED
      retry: true
      max_attempts: 1  # Only one retry after a cooling period
      cooling_period: 300s
```

---

### 3. Degradation Strategy

#### 3.1 Feature Degradation Levels

```
Degradation Levels
==================

Level 0: Full Functionality
├── All notification channels active
├── All features available
├── Full retry attempts
└── Complete logging

Level 1: Reduced Redundancy
├── Primary notification channels active
├── Fallback channels on standby
├── Standard retry attempts
└── Complete logging

Level 2: Essential Only
├── Only critical notifications (P0/P1)
├── No retry for non-critical operations
├── Essential logging only
└── Fallback templates

Level 3: Minimal Operation
├── Only P0 notifications
├── No retry, immediate fallback
├── Error logging only
└── Static fallback content

Level 4: Safe Mode
├── No external calls
├── Local logging only
├── No notifications
└── State preservation
```

#### 3.2 Fallback Behaviors

```yaml
fallback_config:
  notification:
    primary_failure:
      action: "use_secondary_channel"
      secondary_channel: "email"

    all_channels_failed:
      action: "log_and_queue"
      queue_file: "${RDD_DIR}/cache/notification_queue.json"
      max_queue_size: 100

    template_missing:
      action: "use_default_template"
      default_template: |
        ## {title}

        {message}

        Timestamp: {timestamp}
        Project: {project_name}

    template_render_failed:
      action: "use_raw_message"
      raw_format: "[{priority}] {title}: {message}"

  configuration:
    config_not_found:
      action: "use_defaults"
      defaults:
        retry:
          max_attempts: 3
          initial_delay: 1s
        notifications:
          quiet_hours:
            enabled: false

    config_parse_error:
      action: "use_cached"
      cache_file: "${RDD_DIR}/cache/config_cache.json"
      fallback: "use_defaults"

  hooks:
    hook_not_found:
      action: "skip_with_warning"
      log_level: "warn"

    hook_failed:
      action: "log_and_continue"
      log_level: "error"
      notify_on_failure: true
```

#### 3.3 Circuit Breaker Pattern

```bash
# Circuit breaker states
CIRCUIT_STATES:
  CLOSED:    # Normal operation, requests pass through
  OPEN:      # Failing, requests are blocked
  HALF_OPEN: # Testing if service recovered

# Circuit breaker configuration
circuit_breaker:
  failure_threshold: 5      # Open after 5 failures
  success_threshold: 3      # Close after 3 successes
  timeout: 60s              # Time to wait before trying half-open
  half_open_max_requests: 1 # Requests allowed in half-open state

# Circuit breaker implementation
circuit_breaker_check() {
    local channel="$1"
    local state_file="${RDD_DIR}/cache/circuit_breaker_${channel}.json"

    # Initialize if not exists
    if [[ ! -f "$state_file" ]]; then
        echo '{"state":"CLOSED","failures":0,"successes":0,"last_failure":0}' > "$state_file"
    fi

    local state=$(cat "$state_file")
    local current_state=$(echo "$state" | jq -r '.state')
    local failures=$(echo "$state" | jq -r '.failures')
    local last_failure=$(echo "$state" | jq -r '.last_failure')
    local now=$(date +%s)

    case "$current_state" in
        CLOSED)
            return 0  # Allow request
            ;;
        OPEN)
            # Check if timeout has passed
            if (( now - last_failure > circuit_breaker_timeout )); then
                # Transition to half-open
                update_circuit_state "$channel" "HALF_OPEN" 0 0
                return 0  # Allow test request
            fi
            return 1  # Block request
            ;;
        HALF_OPEN)
            # Allow limited requests
            return 0
            ;;
    esac
}

record_success() {
    local channel="$1"
    local state_file="${RDD_DIR}/cache/circuit_breaker_${channel}.json"

    # Increment success counter
    # If success threshold reached, close circuit
    # Implementation details...
}

record_failure() {
    local channel="$1"
    local state_file="${RDD_DIR}/cache/circuit_breaker_${channel}.json"

    # Increment failure counter
    # If failure threshold reached, open circuit
    # Implementation details...
}
```

---

### 4. Observability Design

#### 4.1 Structured JSON Logging

```bash
# Log format specification
log_format:
  version: "1.0"
  format: "json"
  fields:
    # Required fields
    timestamp:
      type: "string"
      format: "ISO8601"
      required: true
      example: "2026-03-07T10:30:00.000Z"

    level:
      type: "string"
      enum: ["DEBUG", "INFO", "WARN", "ERROR", "CRITICAL"]
      required: true

    message:
      type: "string"
      required: true

    # Context fields
    component:
      type: "string"
      description: "Module/component name"
      example: "notify.sh", "hook.stage_complete"

    trace_id:
      type: "string"
      description: "Unique identifier for tracking related log entries"
      example: "abc123-def456-ghi789"

    span_id:
      type: "string"
      description: "Identifier for sub-operations"

    # Error fields
    error_code:
      type: "string"
      description: "Error code from error registry"
      example: "E200"

    error_category:
      type: "string"
      description: "Error category"
      example: "RECOVERABLE", "NON_RECOVERABLE"

    # Additional context
    context:
      type: "object"
      description: "Additional contextual information"

    # Performance fields
    duration_ms:
      type: "number"
      description: "Operation duration in milliseconds"

    # RDD-specific fields
    rdd_stage:
      type: "string"
      description: "Current RDD stage"

    rdd_project:
      type: "string"
      description: "Project name"

# Example log entries
log_examples:
  - timestamp: "2026-03-07T10:30:00.000Z"
    level: "INFO"
    message: "Notification sent successfully"
    component: "notify.sh"
    trace_id: "abc123-def456"
    context:
      channel: "wecom"
      trigger_type: "stage_complete"

  - timestamp: "2026-03-07T10:30:01.000Z"
    level: "ERROR"
    message: "Failed to send notification"
    component: "notify.sh"
    trace_id: "abc123-def457"
    error_code: "E200"
    error_category: "RECOVERABLE"
    context:
      channel: "telegram"
      attempt: 1
      max_attempts: 3
    duration_ms: 150

# Log function implementation
log_json() {
    local level="$1"
    local message="$2"
    shift 2
    local context_vars=("$@")

    local log_entry
    log_entry=$(cat <<EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")",
    "level": "$level",
    "message": "$message",
    "component": "${COMPONENT_NAME:-unknown}",
    "trace_id": "${TRACE_ID:-}",
    "span_id": "${SPAN_ID:-}"
EOF
)

    # Add error fields if present
    if [[ -n "${ERROR_CODE:-}" ]]; then
        log_entry+=",\"error_code\":\"${ERROR_CODE}\""
        log_entry+=",\"error_category\":\"${ERROR_CATEGORY:-unknown}\""
    fi

    # Add context
    if [[ ${#context_vars[@]} -gt 0 ]]; then
        log_entry+=",\"context\":{"
        local first=true
        for var in "${context_vars[@]}"; do
            local key="${var%%=*}"
            local value="${var#*=}"
            if [[ "$first" != "true" ]]; then
                log_entry+=","
            fi
            log_entry+="\"${key}\":\"${value}\""
            first=false
        done
        log_entry+="}"
    fi

    log_entry+="}"

    # Output to appropriate stream
    case "$level" in
        DEBUG|INFO)
            echo "$log_entry" >&2
            ;;
        WARN|ERROR|CRITICAL)
            echo "$log_entry" >&2
            ;;
    esac
}
```

#### 4.2 Prometheus Metrics Format

```bash
# Metrics exposed via file or HTTP endpoint

# Counter metrics
# HELP rdd_notifications_total Total number of notifications sent
# TYPE rdd_notifications_total counter
rdd_notifications_total{channel="wecom",status="success"} 100
rdd_notifications_total{channel="wecom",status="failed"} 5
rdd_notifications_total{channel="email",status="success"} 50
rdd_notifications_total{channel="email",status="failed"} 2

# HELP rdd_hook_executions_total Total number of hook executions
# TYPE rdd_hook_executions_total counter
rdd_hook_executions_total{hook="stage_complete",status="success"} 25
rdd_hook_executions_total{hook="stage_complete",status="failed"} 0
rdd_hook_executions_total{hook="consecutive_failure",status="success"} 3
rdd_hook_executions_total{hook="consecutive_failure",status="failed"} 0

# HELP rdd_errors_total Total number of errors by code
# TYPE rdd_errors_total counter
rdd_errors_total{code="E200",category="recoverable"} 10
rdd_errors_total{code="E300",category="recoverable"} 5
rdd_errors_total{code="E100",category="non_recoverable"} 1

# Gauge metrics
# HELP rdd_circuit_breaker_state Circuit breaker state (0=closed, 1=open, 2=half_open)
# TYPE rdd_circuit_breaker_state gauge
rdd_circuit_breaker_state{channel="wecom"} 0
rdd_circuit_breaker_state{channel="telegram"} 1

# HELP rdd_degradation_level Current degradation level (0-4)
# TYPE rdd_degradation_level gauge
rdd_degradation_level 0

# Histogram metrics
# HELP rdd_notification_duration_seconds Time to send notifications
# TYPE rdd_notification_duration_seconds histogram
rdd_notification_duration_seconds_bucket{channel="wecom",le="0.01"} 50
rdd_notification_duration_seconds_bucket{channel="wecom",le="0.05"} 80
rdd_notification_duration_seconds_bucket{channel="wecom",le="0.1"} 90
rdd_notification_duration_seconds_bucket{channel="wecom",le="0.5"} 98
rdd_notification_duration_seconds_bucket{channel="wecom",le="1"} 99
rdd_notification_duration_seconds_bucket{channel="wecom",le="+Inf"} 100
rdd_notification_duration_seconds_sum{channel="wecom"} 15.5
rdd_notification_duration_seconds_count{channel="wecom"} 100

# Metrics collection implementation
collect_metrics() {
    local metrics_file="${RDD_DIR}/cache/metrics.prom"

    # Write metrics header
    cat > "$metrics_file" << EOF
# RDD Framework Metrics
# Generated at $(date -u +"%Y-%m-%dT%H:%M:%SZ")

EOF

    # Append notification metrics
    append_notification_metrics "$metrics_file"

    # Append hook metrics
    append_hook_metrics "$metrics_file"

    # Append error metrics
    append_error_metrics "$metrics_file"

    # Append circuit breaker metrics
    append_circuit_breaker_metrics "$metrics_file"

    # Append degradation metrics
    append_degradation_metrics "$metrics_file"
}
```

#### 4.3 Health Check Endpoints

```bash
# Health check implementation

# Basic health check
health_check() {
    local status="healthy"
    local checks=()

    # Check 1: Configuration files
    if [[ -f "${RDD_DIR}/hooks.yml" ]]; then
        checks+=("config:pass")
    else
        checks+=("config:fail")
        status="unhealthy"
    fi

    # Check 2: Scripts executable
    if [[ -x "${RDD_DIR}/scripts/notify.sh" ]]; then
        checks+=("scripts:pass")
    else
        checks+=("scripts:fail")
        status="unhealthy"
    fi

    # Check 3: Cache directory writable
    if [[ -d "${RDD_DIR}/cache" && -w "${RDD_DIR}/cache" ]]; then
        checks+=("cache:pass")
    else
        checks+=("cache:fail")
        status="degraded"
    fi

    # Check 4: Required tools
    local missing_tools=()
    for tool in curl jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        checks+=("tools:pass")
    else
        checks+=("tools:fail:${missing_tools[*]}")
        status="unhealthy"
    fi

    # Output health status
    cat << EOF
{
    "status": "$status",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "${RDD_VERSION:-unknown}",
    "checks": [$(IFS=,; echo "${checks[*]}" | sed 's/\([^,]*\)/"\1"/g')]
}
EOF

    [[ "$status" == "healthy" ]] && return 0 || return 1
}

# Readiness check (can handle traffic)
readiness_check() {
    # Check if all critical components are ready
    local ready=true

    # Check circuit breakers
    for channel in wecom email telegram bark webhook; do
        local state
        state=$(get_circuit_breaker_state "$channel" 2>/dev/null || echo "CLOSED")
        if [[ "$state" == "OPEN" ]]; then
            log_warn "Circuit breaker open for $channel"
            # Circuit breaker open is degraded, not not-ready
        fi
    done

    # Check degradation level
    local level
    level=$(get_degradation_level 2>/dev/null || echo "0")
    if [[ $level -ge 4 ]]; then
        ready=false
    fi

    if [[ "$ready" == "true" ]]; then
        echo '{"status":"ready"}'
        return 0
    else
        echo '{"status":"not_ready","reason":"degradation_level_4"}'
        return 1
    fi
}

# Liveness check (process is alive)
liveness_check() {
    # Simple check that process can respond
    echo '{"status":"alive","timestamp":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}'
    return 0
}

# Dependency check
dependency_check() {
    local deps=()

    # Check notification channels
    for channel in wecom email telegram bark webhook; do
        local enabled
        enabled=$(load_yaml_value "${RDD_DIR}/hooks.yml" "channels.${channel}.enabled" "false")
        if [[ "$enabled" == "true" ]]; then
            deps+=("notification_${channel}:configured")
        fi
    done

    # Check templates
    if [[ -f "${RDD_DIR}/templates.yml" ]]; then
        deps+=("templates:configured")
    else
        deps+=("templates:missing")
    fi

    cat << EOF
{
    "dependencies": [$(IFS=,; echo "${deps[*]}" | sed 's/\([^,]*\)/"\1"/g')],
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}
```

---

### 5. Implementation Structure

```
.rdd/
├── scripts/
│   ├── notify.sh              # Main notification script (enhanced)
│   ├── error_handler.sh       # Error handling utilities (NEW)
│   ├── retry.sh               # Retry mechanism (NEW)
│   ├── circuit_breaker.sh     # Circuit breaker implementation (NEW)
│   ├── logger.sh              # Structured logging (NEW)
│   ├── metrics.sh             # Metrics collection (NEW)
│   └── health.sh              # Health checks (NEW)
│
├── lib/
│   ├── error_codes.sh         # Error code definitions (NEW)
│   ├── fallback_templates.sh  # Fallback templates (NEW)
│   └── degradation.sh         # Degradation logic (NEW)
│
├── cache/
│   ├── circuit_breaker/       # Circuit breaker state files (NEW)
│   ├── notification_queue.json # Failed notification queue (NEW)
│   ├── config_cache.json      # Cached configuration (NEW)
│   └── metrics.prom           # Prometheus metrics file (NEW)
│
└── config/
    └── error_handling.yml     # Error handling configuration (NEW)
```

---

## Acceptance Criteria

- [ ] Error classification system with all error codes documented
- [ ] Retry mechanism with exponential backoff and jitter
- [ ] Circuit breaker implementation for notification channels
- [ ] Degradation strategy with 5 levels (0-4)
- [ ] Fallback behaviors for all non-critical failures
- [ ] Structured JSON logging with trace IDs
- [ ] Prometheus-compatible metrics file output
- [ ] Health check commands (health, readiness, liveness)
- [ ] Dependency check command
- [ ] Error handling test coverage >= 80%
- [ ] Documentation: troubleshooting guide created
- [ ] All existing tests pass with new error handling

---

## Rollback Plan

**Rollback strategy**: Remove error handling enhancements, restore original notify.sh

**Rollback steps**:

1. Restore original notify.sh from backup: `git checkout HEAD~1 -- .rdd/scripts/notify.sh`
2. Remove new scripts: `rm -rf .rdd/scripts/{error_handler,retry,circuit_breaker,logger,metrics,health}.sh`
3. Remove new lib directory: `rm -rf .rdd/lib/`
4. Remove new cache directories: `rm -rf .rdd/cache/circuit_breaker .rdd/cache/metrics.prom`
5. Remove error handling config: `rm .rdd/config/error_handling.yml`
6. Run existing tests to verify rollback: `task test`
7. Verify notifications still work: `DRY_RUN=true .rdd/scripts/notify.sh stage_complete`

---

## Known Limitations

- **No distributed tracing**: Single-process framework, no cross-service tracing
- **Metrics are file-based**: No real-time HTTP metrics endpoint (could be added in future)
- **Circuit breaker state is local**: Does not persist across restarts (could be enhanced)
- **No automatic escalation**: Degradation level changes require manual intervention
- **Log aggregation not included**: Users must integrate with their own log aggregation system

---

## Impact on Subsequent Stages

- **Stage 5 (Performance)**: Can leverage metrics for performance analysis, error handling provides baseline measurements
- **Stage 6 (Security)**: Audit logging will build on structured logging infrastructure
- **Stage 7 (Documentation)**: Troubleshooting guide and health check documentation needed
- **All stages**: Consistent error handling and logging will improve debugging across all features

---

## Implementation Notes

### Technical Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Retry strategy | Exponential backoff with jitter | Prevents thundering herd, industry standard |
| Circuit breaker state storage | JSON files | Simple, no external dependencies |
| Log format | JSON | Machine-parseable, compatible with common log aggregators |
| Metrics format | Prometheus text format | Industry standard, wide tooling support |
| Error codes | Numeric codes (E001-E999) | Compact, sortable, easy to reference |

### Dependencies

| Dependency | Purpose | Version | Install |
|------------|---------|---------|---------|
| jq | JSON processing | >= 1.5 | Required (already used) |
| curl | HTTP requests | >= 7.0 | Required (already used) |
| bc | Arithmetic for backoff | >= 1.0 | Optional (fallback to awk) |

### Configuration Schema

```yaml
# .rdd/config/error_handling.yml
error_handling:
  # Error classification settings
  classification:
    default_severity: "P2"
    unknown_error_recoverable: false

  # Retry settings
  retry:
    enabled: true
    max_attempts: 3
    initial_delay: 1s
    max_delay: 30s
    backoff_multiplier: 2
    jitter: true
    jitter_range: 0.5

  # Circuit breaker settings
  circuit_breaker:
    enabled: true
    failure_threshold: 5
    success_threshold: 3
    timeout: 60s
    half_open_max_requests: 1

  # Degradation settings
  degradation:
    enabled: true
    auto_level_adjustment: false
    notification_failure_threshold: 10
    recovery_check_interval: 300s

  # Logging settings
  logging:
    format: "json"
    level: "INFO"
    include_trace_id: true
    include_context: true
    output_file: ""  # Empty = stderr

  # Metrics settings
  metrics:
    enabled: true
    output_file: "${RDD_DIR}/cache/metrics.prom"
    collection_interval: 60s

  # Health check settings
  health:
    detailed_checks: true
    include_dependencies: true
```

---

## Verification

### Gate 1: Design Document Check
- [x] Goals clearly defined
- [x] Non-goals explicitly stated
- [x] Acceptance criteria testable
- [x] Rollback plan exists
- [x] Impact on subsequent stages documented

### Gate 2: Design Review Check
- [ ] Multi-model review triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [ ] Implementation complete
- [ ] Unit test coverage >= 80%
- [ ] E2E tests (2+ high-signal paths)
- [ ] Real environment verification
- [ ] Clean environment verification

### Gate 4: Code Review Check
- [ ] Triangulation complete
- [ ] All blocking findings resolved
- [ ] All acceptance criteria met

### Gate 5: Completion Gate Check
- [ ] Main hypotheses verified
- [ ] Tests reproducible via Task
- [ ] No undocumented manual steps
- [ ] Implementation matches design
- [ ] Tech debt ledger updated
- [ ] ADR recorded
- [ ] fresh-agent-check passed

---

## Appendix

### Test Scenarios

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| Transient network failure | Network timeout on first attempt | Retry with backoff, succeed on second attempt |
| Persistent network failure | Network timeout on all attempts | Fail after max retries, log error, queue notification |
| Circuit breaker open | 5 consecutive failures | Circuit opens, subsequent requests fail fast |
| Circuit breaker half-open | Circuit open, timeout passed | Allow one test request, close if success |
| All notification channels fail | All channels return errors | Queue notification, log error, do not halt |
| Invalid configuration | Missing required field | Log error, use defaults if possible, otherwise halt |
| Missing required tool | curl not found | Log error with clear message, halt with exit code 1 |
| Degradation level change | Multiple channels fail | Increase degradation level, log change |

### Error Handling Flow Diagram

```
Operation Start
       │
       ▼
┌─────────────────┐
│  Circuit Breaker │
│     Check       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
   OPEN    CLOSED/HALF_OPEN
    │         │
    ▼         ▼
 Fail    Execute Operation
    │         │
    │    ┌────┴────┐
    │    │         │
    │ Success   Failure
    │    │         │
    │    ▼         ▼
    │  Record   Classify Error
    │  Success      │
    │    │     ┌────┴────┐
    │    │     │         │
    │    │ Recoverable Non-Recoverable
    │    │     │         │
    │    │     ▼         ▼
    │    │   Retry?    Fail Fast
    │    │     │      Log Error
    │    │  ┌──┴──┐   Notify
    │    │  │     │   (if P0/P1)
    │    │ Yes   No
    │    │  │     │
    │    │  ▼     ▼
    │    │ Backoff Fallback
    │    │  │     │
    │    │  └──┬──┘
    │    │     │
    │    │     ▼
    │    │  Record
    │    │  Failure
    │    │     │
    │    └─────┴───────┐
    │                  │
    └──────────────────┘
```
