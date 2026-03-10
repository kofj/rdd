# Autonomous Decisions Record (ADR)

> This document records architecture decisions and technology choices in the RDD project, ensuring the decision-making process is traceable and understandable.

---

## ADR Format Description

### What is an ADR

ADR (Architecture Decision Record) is a lightweight document format for recording architecture decisions. Each decision record contains:

- Background and context of the decision
- The decision content made
- The reason for making that decision
- The impact of that decision on subsequent Stages

### ADR Format Template

```markdown
### Decision N: [Decision Title]

**Background**: What triggered this decision

**Decision Content**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (Cannot be empty)
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| Decision Number | Yes | Format: Decision 1, Decision 2, etc. |
| Decision Title | Yes | Concise summary of decision content |
| Background | Yes | Describe the context that triggered this decision |
| Decision Content | Yes | Clearly describe the decision made |
| Reason | Yes | Explain why this decision was made |
| Impact on Subsequent Stages | Yes | Must be filled in, describe impact on subsequent work |

### When to Record an ADR

Record an ADR in the following situations:

1. **Architecture Decisions**: Major decisions affecting system architecture
2. **Technology Selection**: Choosing tech stacks, frameworks, libraries, etc.
3. **Design Trade-offs**: Making trade-offs between multiple options
4. **Assumption Changes**: Core assumptions verified or falsified
5. **Non-goal Declarations**: Explicitly stating what will not be done
6. **Technical Debt Decisions**: Decisions to accept technical debt

### ADR Writing Guidelines

```
DO:
- Record each decision independently
- Clear background description so newcomers can understand
- Unambiguous decision content
- Well-founded reasons
- Specific impact pointing to clear Stages

DON'T:
- Leave "Impact on Subsequent Stages" empty
- Record trivial daily decisions
- Ambiguous decision content
- Not record reasons or impact
```

---

## ADR Index

<!-- Add new ADR index here -->

| Number | Title | Date | Related Stage | Status |
|--------|-------|------|---------------|--------|
| Decision 1 | Hook scripts use source to import shared functions | 2026-03-07 | Stage 1 | Active |
| Decision 2 | Hook triggering managed by rdd-hooks skill | 2026-03-07 | Stage 1 | Active |
| Decision 3 | Use relative paths and PROJECT_ROOT environment variable | 2026-03-07 | Stage 1 | Active |
| Decision 4 | Credentials use ${VAR} environment variable references | 2026-03-07 | Stage 1 | Active |
| Decision 5 | Choose bats-core as Shell testing framework | 2026-03-07 | Stage 2 | Active |
| Decision 6 | Testing strategy: Unit/BDD/E2E three-layer testing | 2026-03-07 | Stage 2 | Active |
| Decision 7 | Error classification system: Recoverable/Non-recoverable two categories | 2026-03-07 | Stage 4 | Active |
| Decision 8 | Retry strategy: Exponential backoff + jitter | 2026-03-07 | Stage 4 | Active |
| Decision 9 | Degradation strategy: Five-level degradation (Level 0-4) | 2026-03-07 | Stage 4 | Active |
| Decision 10 | Log format: Structured JSON logs | 2026-03-07 | Stage 4 | Active |
| Decision 11 | Metrics format: Prometheus text format | 2026-03-07 | Stage 4 | Active |
| Decision 12 | Circuit breaker: Failure count-based circuit breaker pattern | 2026-03-07 | Stage 4 | Active |
| Decision 13 | RBAC permission model: Three-role design (admin/developer/viewer) | 2026-03-07 | Stage 6 | Active |
| Decision 14 | Audit log using file storage + JSON format solution | 2026-03-07 | Stage 6 | Active |
| Decision 15 | Sensitive data handling: Environment variables + optional Vault integration | 2026-03-07 | Stage 6 | Active |
| Decision 16 | Shell script security hardening: Input validation + injection protection | 2026-03-07 | Stage 6 | Active |
| Decision 17 | Performance benchmarking: Custom bash script solution | 2026-03-07 | Stage 5 | Active |
| Decision 18 | Version management: Semantic versioning + compatibility matrix | 2026-03-07 | Stage 5 | Active |
| Decision 19 | Migration strategy: Backup + atomic migration + rollback support | 2026-03-07 | Stage 5 | Active |
| Decision 20 | Compatibility checking: YAML schema validation + breaking change detection | 2026-03-07 | Stage 5 | Active |
| Decision 21 | Installation method: curl \| sh one-click installation priority | 2026-03-09 | Stage 8 | Active |
| Decision 22 | Skills distribution: Copy to ~/.claude/skills/ | 2026-03-09 | Stage 8 | Active |
| Decision 23 | Release channels: GitHub Release + npm | 2026-03-09 | Stage 9 | Active |
| Decision 24 | Command naming: rdd (short command friendly) | 2026-03-09 | Stage 8 | Active |

---

## ADR Records

---

### Decision 1: Hook Scripts Use Source to Import Shared Functions

**Background**: Hook scripts need to call functions defined in notify.sh such as log_info, log_warn, log_error, send_notification. Currently Hook scripts call these functions directly without sourcing notify.sh, resulting in "command not found" errors.

**Decision Content**: All Hook scripts uniformly use `source "${SCRIPTS_DIR}/notify.sh"` at the beginning to import shared functions, ensuring SCRIPTS_DIR is correctly set.

**Reason**:
1. Maintain code DRY (Don't Repeat Yourself)
2. Easy to maintain, function modifications only need to be done in one place
3. Follows Shell script best practices
4. Facilitates unit testing

**Impact on Subsequent Stages**:
- Stage 2 tests can directly test notify.sh functions without copying code
- Future new Hooks only need to source to use all functions
- Stage 3 can rely on stable Hook mechanism for recovery notifications

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. Define functions in each script - Code duplication, difficult maintenance
2. Use symbolic links - Not applicable to functions, only files

---

### Decision 21: Installation Method Using curl | sh One-Click Installation Priority

**Background**: Users need to be able to easily install the RDD Framework, currently there is no installation method. Need to choose the most convenient installation method for users.

**Decision Content**:
1. Preferred installation method: `curl -fsSL https://.../install.sh | sh`
2. Supported platforms: macOS, Linux (x86_64, ARM64)
3. Installation directory: `~/.rdd-framework/`
4. Auto-configure PATH and Skills

**Reason**:
1. Simplest installation method, no dependencies
2. No need to pre-install Node.js or other runtimes
3. Follows mainstream CLI tool installation habits (like Homebrew, nvm, rustup)
4. Script can check dependencies and provide friendly prompts

**Impact on Subsequent Stages**:
- Stage 8 only needs to write installation script, no extra infrastructure needed
- Stage 9 can extend npm package as alternative installation method
- Users can complete installation and first use within 5 minutes

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. npm package only - Requires Node.js environment, limits user base
2. Homebrew only - macOS users only
3. Manual download - Poor user experience, error-prone

---

### Decision 22: Skills Distributed by Copying to ~/.claude/skills/

**Background**: Claude Code needs to be able to recognize and use RDD skills. Need to determine how to install skills to user systems.

**Decision Content**:
1. Copy skills to `~/.claude/skills/` during installation
2. Copy commands to `~/.claude/commands/`
3. Keep original files unchanged, independent copies
4. Provide `rdd upgrade` command to update skills

**Reason**:
1. Most reliable distribution method, no cross-platform symlink issues
2. Users can customize skills without affecting global settings
3. Claude Code can correctly recognize and load
4. Uninstallation is simply deleting the directory

**Impact on Subsequent Stages**:
- Stage 8 installation script needs to implement copy logic
- Users can override global skills in project `.claude/skills/`
- Supports multi-version coexistence (future)

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. Symbolic links - Windows compatibility issues
2. Runtime dynamic loading - Requires modifying Claude Code
3. Project-level skills - Each project needs separate configuration

---

### Decision 23: Release Channels Using GitHub Release + npm

**Background**: Need to choose release channels for users to obtain the framework.

**Decision Content**:
1. Primary channel: GitHub Release (installation script download source)
2. Secondary channel: npm global package (covers Node.js users)
3. Version management: Semantic versioning, GitHub Releases management

**Reason**:
1. GitHub Release is free, reliable, no extra configuration needed
2. npm covers Node.js developer community
3. No dependency on paid services
4. Simple release process

**Impact on Subsequent Stages**:
- Stage 8 uses GitHub Release as download source
- Stage 9 implements npm package publishing
- CI/CD automated release process

**Date**: 2026-03-09

**Related Stage**: Stage 9

**Alternatives Considered**:
1. GitHub Release only - Limited coverage
2. npm only - Requires Node.js environment
3. Homebrew + npm + GitHub - High maintenance cost

---

### Decision 24: Command Naming Using rdd (Short Command Friendly)

**Background**: Users need to use RDD commands on the command line, need to determine the command name.

**Decision Content**:
1. Main command: `rdd` (short, memorable)
2. Subcommands: `rdd init`, `rdd migrate`, `rdd stage`, `rdd knowledge`
3. Claude Code skills: Keep `/rdd-*` format (determined by Claude Code specification)

**Reason**:
1. Short commands reduce typing, improve efficiency
2. Consistent with other CLI tool naming conventions
3. Clear subcommand structure
4. Easy to remember and use

**Impact on Subsequent Stages**:
- Stage 8 installation script creates `rdd` command
- Documentation uses `rdd` command examples
- Skills keep `/rdd-init` format

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. `rdd-framework` - Too long, inconvenient to type
2. `rdd-cli` - Unnecessary suffix
3. `@kofj/rdd` - npm scope naming, not suitable for CLI

---

### Decision 2: Hook Triggering Managed by rdd-hooks Skill

**Background**: Currently Hooks scripts exist but there is no mechanism to trigger them. Need to call these scripts at appropriate times.

**Decision Content**: Create rdd-hooks skill to define trigger rules, each skill calls Hook scripts at appropriate times through environment variables passing parameters.

**Reason**:
1. Centrally manage all Hook trigger logic
2. Easy to test and debug
3. Follows RDD single responsibility principle
4. Each skill doesn't need to know Hook implementation details

**Impact on Subsequent Stages**:
- Stage 2 can test Hook trigger flow
- Stage 3 can rely on this mechanism to send recovery notifications
- Stage 4 can extend more Hook types

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. Direct calls in each skill - Scattered, hard to maintain
2. Create independent Hook service - Over-engineering, increases complexity

---

### Decision 3: Use Relative Paths and PROJECT_ROOT Environment Variable

**Background**: Current code has hardcoded `/data/works/play/sbd/` path, making the framework unusable in other projects.

**Decision Content**:
1. All paths use relative paths (relative to script directory)
2. Support PROJECT_ROOT environment variable to override project root directory
3. Use `.` or `${PROJECT_ROOT:-.}` form in skills

**Reason**:
1. Makes framework portable to any project
2. Maintains backward compatibility (defaults to current directory)
3. Follows 12-Factor App principles
4. Simplifies deployment process

**Impact on Subsequent Stages**:
- Stage 2 tests can run in temporary directories
- Stage 4 multi-project support becomes simple
- rdd-init can directly create structure in new projects

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. Absolute path configuration file - Requires separate configuration per project
2. Auto-detect project root - Unreliable, may misjudge

---

### Decision 4: Credentials Use ${VAR} Environment Variable References

**Background**: Current hooks.yml has sensitive information like Webhook URLs, Bot Tokens stored in plaintext, posing security risks.

**Decision Content**: Support ${VAR} and $VAR forms of environment variable references, configuration files only store variable names not actual values.

**Reason**:
1. Follows security best practices
2. Facilitates CI/CD integration
3. Supports different environments with different configurations
4. Avoids sensitive information leaking into version control

**Impact on Subsequent Stages**:
- Stage 2 tests can use mock environment variables
- Stage 4 CI/CD integration can directly use CI environment variables
- Can safely commit configuration file examples

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. Encrypted storage - Increases complexity, needs key management
2. Separate secrets file - Increases configuration complexity
3. Environment variables only - Inconvenient for local development

---

### Decision 5: Choose bats-core as Shell Testing Framework

**Background**: Stage 2 needs to establish a testing system, providing unit testing and BDD testing capabilities for notify.sh and Hook scripts. Currently there is no testing framework.

**Decision Content**: Choose bats-core as the Shell script testing framework for unit testing and BDD testing.

**Reason**:
1. Native BDD style syntax (@test "description"), fits Stage 2 BDD testing needs
2. TAP (Test Anything Protocol) output, easy CI integration
3. Active community and rich documentation
4. Supports environment variable mocking and function overriding
5. Extensible through bats-support, bats-assert libraries

**Impact on Subsequent Stages**:
- Stage 2: Establish complete unit testing and BDD testing system
- Stage 3: Can test context recovery logic
- Stage 4: CI/CD can directly use bats output

**Date**: 2026-03-07

**Related Stage**: Stage 2

**Alternatives Considered**:
1. shunit2 - xUnit style, not suitable for BDD scenarios
2. shellcheck - Static analysis, not a testing framework
3. Custom test scripts - Reinventing the wheel, limited functionality

---

### Decision 6: Testing Strategy: Unit/BDD/E2E Three-Layer Testing

**Background**: Need to establish a complete testing system for the RDD framework, ensuring tests at different levels cover different verification needs.

**Decision Content**: Adopt a three-layer testing strategy:

1. **Unit Test Layer (tests/unit/)**: Test individual functions and script logic
   - notify.sh function tests
   - Hook script tests
   - Utility function tests
   - Target coverage >= 80%

2. **BDD Test Layer (tests/bdd/)**: Test user behavior scenarios
   - Given/When/Then format
   - Verify Hook trigger flow
   - Verify notification sending flow
   - Verify error handling

3. **E2E Test Layer (tests/e2e/)**: End-to-end integration testing
   - Complete workflow testing
   - Real environment verification
   - Agent behavior simulation

**Reason**:
1. Layered testing isolates concerns
2. Unit tests for fast feedback, BDD verifies behavior, E2E verifies integration
3. Follows testing pyramid principle
4. Facilitates problem level identification

**Impact on Subsequent Stages**:
- Stage 2: Implement three-layer testing framework and basic test cases
- Stage 3: Can add context recovery E2E tests
- Stage 4: CI/CD can run tests in layers

**Date**: 2026-03-07

**Related Stage**: Stage 2

**Alternatives Considered**:
1. Unit tests only - Cannot verify behavior and integration
2. E2E tests only - Slow feedback, difficult debugging
3. No layers - Testing chaos, unclear responsibilities

---

### Decision 7: Error Classification System Using Recoverable/Non-recoverable Two Categories

**Background**: Stage 4 needs to establish a comprehensive error handling mechanism, need to classify errors to determine handling strategies.

**Decision Content**: Adopt a two-level error classification system:
1. **Recoverable Errors**: Can be automatically handled through retry, degradation, or circuit breaker
   - Temporary errors: Network timeout, service unavailable, rate limiting
   - Degradeable errors: Notification channel failure, template rendering failure
   - Circuit breaker needed errors: Continuously failing notification channels

2. **Non-Recoverable Errors**: Require human intervention
   - Configuration errors: Format errors, missing required configuration
   - Logic errors: Invalid trigger type, template syntax errors
   - Environment errors: Missing tools, insufficient permissions
   - System errors: Out of memory, disk full

**Reason**:
1. Simplifies error handling logic, binary classification is clear and easy to understand
2. Recoverable errors can be handled automatically, reducing human intervention
3. Non-recoverable errors clearly need human involvement
4. Follows industry best practices

**Impact on Subsequent Stages**:
- Stage 5 can perform performance analysis based on error classification
- Stage 6 audit logs can record error classification
- All subsequent Stages need to use unified error classification

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. Three-level classification (Recoverable/Partially Recoverable/Non-recoverable) - Too complex
2. Multi-label classification - Not convenient for decision making
3. No classification - Chaotic, difficult to handle

---

### Decision 8: Retry Strategy Using Exponential Backoff + Jitter

**Background**: Operations like notification sending may fail due to temporary faults, need automatic retry mechanism.

**Decision Content**: Adopt exponential backoff plus jitter retry strategy:
- Initial delay: 1 second
- Maximum delay: 30 seconds
- Backoff multiplier: 2
- Jitter range: ±50% randomization
- Maximum retry count: 3

**Reason**:
1. Exponential backoff avoids resource waste from immediate retries
2. Jitter prevents thundering herd (multiple clients retrying simultaneously)
3. Maximum delay limit avoids overly long waits
4. Maximum retry count limit avoids infinite retries
5. Follows AWS/Google Cloud best practices

**Impact on Subsequent Stages**:
- Stage 5 performance testing needs to consider retry impact on latency
- All network operations should use unified retry strategy
- Stage 7 documentation needs to explain retry behavior

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. Fixed interval retry - May cause thundering herd
2. Linear backoff - Not fast enough recovery or too long wait
3. No retry - Poor reliability

---

### Decision 9: Degradation Strategy Using Five-Level Degradation (Level 0-4)

**Background**: When parts of the system are unavailable, need graceful degradation to maintain core functionality availability.

**Decision Content**: Adopt five-level degradation strategy:
- **Level 0 (Full)**: All functionality available, all notification channels normal
- **Level 1 (Reduced)**: Primary channels normal, standby channels on standby
- **Level 2 (Essential)**: Only critical notifications (P0/P1), reduced retries
- **Level 3 (Minimal)**: Only P0 notifications, no retries, static content
- **Level 4 (Safe Mode)**: No external calls, local logs only

**Reason**:
1. Progressive degradation avoids sudden failure
2. Clear levels, easy to monitor and alert
3. Level 4 safe mode ensures minimum availability
4. Can automatically adjust degradation level based on failure rate
5. Easy for operators to quickly understand system state

**Impact on Subsequent Stages**:
- Stage 5 performance testing needs to verify degradation behavior at each level
- Stage 6 permission system can link with degradation level
- Stage 7 operations manual needs to explain handling for each degradation level

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. Two-level degradation (Normal/Degraded) - Too coarse
2. Infinite levels - Too complex
3. No degradation mechanism - Poor reliability

---

### Decision 10: Log Format Using Structured JSON Logs

**Background**: Need observability support for troubleshooting and performance analysis.

**Decision Content**: Adopt structured JSON log format:
- Required fields: timestamp, level, message
- Context fields: component, trace_id, span_id
- Error fields: error_code, error_category
- Performance fields: duration_ms
- RDD fields: rdd_stage, rdd_project

**Reason**:
1. JSON format is machine-readable, easy for log aggregation
2. Structured fields easy for searching and filtering
3. trace_id supports tracing individual requests
4. Compatible with mainstream log systems like ELK, Loki
5. Facilitates later analysis and monitoring

**Impact on Subsequent Stages**:
- Stage 5 can use duration_ms for performance analysis
- Stage 6 audit logs can reuse same format
- Stage 7 operations manual needs to explain log format

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. Plain text logs - Not easy to parse and search
2. CSV format - Inconvenient field expansion
3. Binary format - Not easy for debugging

---

### Decision 11: Metrics Format Using Prometheus Text Format

**Background**: Need to expose system metrics to support monitoring and alerting.

**Decision Content**: Adopt Prometheus text format to expose metrics:
- Counter type: rdd_notifications_total, rdd_errors_total
- Gauge type: rdd_circuit_breaker_state, rdd_degradation_level
- Histogram type: rdd_notification_duration_seconds
- Output file: ${RDD_DIR}/cache/metrics.prom

**Reason**:
1. Prometheus is the de facto standard for cloud-native monitoring
2. Text format is simple, no dependencies
3. Supports Counter/Gauge/Histogram types
4. Compatible with visualization tools like Grafana
5. Can be directly scraped by Prometheus

**Impact on Subsequent Stages**:
- Stage 5 performance testing can use Histogram data
- Stage 7 can provide Grafana Dashboard templates
- Future can add HTTP endpoint for real-time scraping

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. StatsD format - Requires statsd exporter
2. OpenTelemetry - Too complex
3. Custom format - Poor compatibility

---

### Decision 12: Circuit Breaker Using Failure Count-Based Circuit Breaker Pattern

**Background**: When a notification channel continuously fails, need fast failure to avoid resource waste.

**Decision Content**: Adopt failure count-based circuit breaker pattern:
- **CLOSED**: Normal state, requests pass through
- **OPEN**: Circuit breaker state, requests fail directly
- **HALF_OPEN**: Half-open state, allows test requests

Parameter configuration:
- Failure threshold: Open after 5 consecutive failures
- Success threshold: Close after 3 consecutive successes
- Timeout: Try half-open after 60 seconds
- State storage: JSON file

**Reason**:
1. Circuit breaker prevents cascading failures
2. Three-state model is simple and reliable
3. Count-based rather than time window, simple implementation
4. JSON file storage requires no external dependencies
5. Can be used independently of other features

**Impact on Subsequent Stages**:
- Stage 5 can perform performance analysis based on circuit breaker state
- Stage 7 operations manual needs to explain circuit breaker states
- Later can extend to distributed circuit breaker

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. No circuit breaker - Failures will continuously affect system
2. Time window circuit breaker - Complex implementation, needs sliding window
3. Token bucket - Suitable for rate limiting, not circuit breaking

---

### Decision 5: Use Rust as Main Development Language

**Background**: Project needs high-performance, memory-safe backend services, team has Rust development experience.

**Decision Content**: Choose Rust as the main development language, with Tokio async runtime.

**Reason**:
1. Rust provides memory safety guarantees, reduces runtime errors
2. Tokio ecosystem is mature, suitable for building high-performance network services
3. Team has Rust development experience, low learning cost
4. Static type system benefits large project maintenance

**Impact on Subsequent Stages**:
- Stage 2: Need to introduce Tokio and related async libraries
- Stage 3: Need to design async API interfaces
- Stage 4: Need to consider Rust deployment and distribution solutions

---

### Decision 2: Use etcd as Distributed Configuration Storage

**Background**: Project needs distributed configuration management, supports multi-node deployment.

**Decision Content**: Choose etcd as distributed configuration storage, with etcd-client library.

**Reason**:
1. etcd provides CP properties, suitable for configuration management scenarios
2. Supports Watch mechanism, real-time configuration change awareness
3. Provides Lease mechanism, supports distributed locks
4. Compatible with Kubernetes ecosystem

**Impact on Subsequent Stages**:
- Stage 5: Need to implement etcd connection pool management
- Stage 6: Need to design configuration change notification mechanism
- Stage 7: Need to implement distributed locks for consistency

---

### Example ADR

Below is a complete ADR example:

### Decision 3: Adopt Layered Architecture Design

**Background**: Project needs to determine overall architecture style in the early stage to support subsequent feature expansion and maintenance.

**Decision Content**: Adopt layered architecture, divided into the following layers:

```
┌─────────────────────────────────────┐
│           API Layer                 │  ← External interfaces
├─────────────────────────────────────┤
│         Service Layer               │  ← Business logic
├─────────────────────────────────────┤
│         Repository Layer            │  ← Data access
├─────────────────────────────────────┤
│         Infrastructure Layer        │  ← Infrastructure
└─────────────────────────────────────┘
```

**Reason**:
1. Layered architecture has clear responsibilities, facilitates team collaboration
2. Each layer can be tested independently, improves code quality
3. Facilitates future replacement of underlying implementations (like databases)
4. Matches team's familiar architecture style

**Impact on Subsequent Stages**:
- Stage 1: Define interfaces and dependencies for each layer
- Stage 2: Implement Infrastructure Layer (logging, configuration)
- Stage 3: Implement Repository Layer (data access)
- Stage 4: Implement Service Layer (core business)
- Stage 5: Implement API Layer (external interfaces)
- Subsequent Stages: Each layer can evolve independently, but need attention to interface compatibility

**Technical Debt Record**:
- TD-02: May have cross-layer calls initially, need refactoring in subsequent Stages
- Suggest Stage 6 specifically handle code standardization

---

### Decision 13: RBAC Permission Model: Three-Role Design (admin/developer/viewer)

**Background**: RDD Framework needs a permission control system to manage different users' access to framework operations, ensuring security and compliance.

**Decision Content**: Adopt Role-Based Access Control (RBAC) model, defining three roles:

1. **Admin**:
   - Full control permissions
   - User and role management
   - Configuration modification
   - Audit log access

2. **Developer**:
   - Execute Stages and tests
   - Edit design documents
   - Manage technical debt
   - Execute Hooks

3. **Viewer**:
   - Read-only access
   - View documents and status
   - View roadmap and progress

**Reason**:
1. Three-role design covers RDD main use cases
2. Simple implementation, configuration file management
3. Easy to understand and maintain
4. Extensible to finer-grained ACL

**Impact on Subsequent Stages**:
- Stage 7: Need to explain permission configuration in documentation
- Production deployment: Must configure RBAC before deployment
- Future versions: May need to extend to finer-grained permission control

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. ACL (Access Control List) - Too complex, not needed initially
2. ABAC (Attribute-Based Access Control) - Complex implementation, over-engineering
3. No permission control - Doesn't meet security compliance requirements

---

### Decision 14: Audit Log Using File Storage + JSON Format Solution

**Background**: RDD Framework needs audit logs to record all important operations, meeting security audit and compliance requirements.

**Decision Content**:
1. Use file storage for audit logs, supporting dual format:
   - Text format (audit.log): Human readable
   - JSON format (audit.json): Machine parseable

2. Audit log format includes:
   - who: Operator
   - when: Timestamp
   - what: Operation object
   - where: Operation source
   - result: Operation result

3. Log rotation strategy:
   - Single file max 10MB
   - Keep last 10 log files
   - Automatic compression archiving

**Reason**:
1. File storage is simple and reliable, no extra dependencies
2. JSON format facilitates log analysis and integration
3. Dual format balances human reading and machine processing
4. Rotation strategy prevents disk space exhaustion

**Impact on Subsequent Stages**:
- Stage 7: Need to provide log query and export tools
- High-frequency scenarios: May need database storage solution
- Log analysis: Can integrate with log platforms like ELK

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. Database storage - Adds dependency, not needed initially
2. Text format only - Not good for machine parsing
3. JSON format only - Not convenient for human viewing
4. Syslog - Increases configuration complexity

---

### Decision 15: Sensitive Data Handling: Environment Variables + Optional Vault Integration

**Background**: Stage 1 implemented environment variable references, but need stronger sensitive data protection mechanisms, including encrypted storage and optional Vault integration.

**Decision Content**:
1. Environment variables as primary credential storage method (implemented in Stage 1)
2. Add strong sensitive data encryption capability:
   - AES-256-CBC encryption
   - Automatic key generation and management
   - Encrypt/decrypt command line tools

3. Optional HashiCorp Vault integration:
   - Support KV v2 secret engine
   - Support Transit encryption service
   - Automatic fallback to environment variables

4. Data masking strategy:
   - Passwords completely masked
   - Tokens show first and last 4 characters
   - URLs mask credential portion

**Reason**:
1. Environment variables are cloud-native standard practice
2. Vault is industry-standard secret management solution
3. Optional integration lowers barrier to use
4. Layered security strategy meets different security needs

**Impact on Subsequent Stages**:
- Stage 7: Need documentation explaining Vault configuration method
- Production deployment: Recommend enabling Vault integration
- Security audit: Need to verify sensitive data protection measures

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. Environment variables only - Insufficient security, no rotation support
2. Mandatory Vault - Increases deployment complexity
3. Custom key management - Reinventing the wheel, security risk
4. Configuration file encryption - Not convenient for CI/CD integration

---

### Decision 16: Shell Script Security Hardening: Input Validation + Injection Protection

**Background**: RDD Framework's core logic is implemented by Shell scripts, need to prevent common Shell script security vulnerabilities, especially command injection and path traversal.

**Decision Content**:
1. Input validation mechanism:
   - Alphanumeric validation
   - Path validation (prevent path traversal)
   - Command validation (prevent command injection)
   - URL/Email format validation

2. Injection protection:
   - Dangerous character filtering (;, |, &, $(), `` etc.)
   - YAML/JSON escaping
   - Safe file operations

3. Security configuration checking:
   - File permission checking
   - Credential exposure checking
   - RBAC configuration checking
   - Audit log checking

**Reason**:
1. Shell scripts are security weak points
2. Input validation is first line of defense against injection
3. Automated checking ensures security configuration consistency
4. Follows security best practices

**Impact on Subsequent Stages**:
- Stage 2: Tests need to cover security validation scenarios
- Stage 7: Need to provide security configuration guide
- All scripts: Need to apply security validation functions

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. Rewrite in Python/Rust - Large workload, affects compatibility
2. Rely only on external security scanning - Cannot prevent runtime attacks
3. Sandbox execution - Increases complexity, limits functionality

---

### Decision 17: Performance Benchmarking Using Custom Bash Script Solution

**Background**: Stage 5 needs to establish a performance benchmarking system, measuring Hook trigger latency, notification sending latency, and memory usage, ensuring performance metrics meet standards.

**Decision Content**: Use custom bash scripts (benchmark.sh) to implement performance benchmarking:
- Use bash built-in date +%s%N to get nanosecond timestamps
- Get memory usage through /proc/$PID/status
- Support multiple iterations to calculate statistics (min/max/avg/median/p95/p99)
- Output JSON format report for CI integration

**Reason**:
1. No extra dependencies needed, bash native support
2. Consistent with RDD existing script style
3. Lightweight, doesn't increase deployment complexity
4. Can be directly integrated into Taskfile
5. JSON output supports CI/CD pipelines

**Impact on Subsequent Stages**:
- Stage 7: Can automatically run performance regression tests in CI
- Performance data can be used to generate performance reports
- Can integrate with monitoring systems for continuous performance tracking

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. Use hyperfine - Need to install external tool
2. Use Python + timeit - Adds Python dependency
3. Use shell built-in time - Insufficient precision

---

### Decision 18: Version Management Using Semantic Versioning + Compatibility Matrix

**Background**: RDD Framework needs a version management system to track release versions, manage compatibility, and support upgrade migrations.

**Decision Content**: Adopt Semantic Versioning (SemVer) with compatibility matrix:
- Version format: MAJOR.MINOR.PATCH[-PRERELEASE]
- VERSION file stores current version and compatibility range
- Provide version comparison, compatibility checking, version upgrade utility functions
- Compatibility matrix defines compatibility relationships between versions

**Reason**:
1. SemVer is industry standard, developers are familiar with it
2. Compatibility matrix clarifies version upgrade paths
3. VERSION file is simple and reliable, no external dependencies
4. Version comparison logic can be fully implemented in bash
5. Supports pre-release versions (alpha/beta/rc)

**Impact on Subsequent Stages**:
- Stage 7: CI/CD can automatically update version numbers
- Release process can automate version upgrades
- Users can choose upgrade version based on compatibility matrix

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. Git tags as versions - Requires git environment
2. Auto-increment version numbers - Cannot express breaking changes
3. Date versioning (CalVer) - Not suitable for libraries/frameworks

---

### Decision 19: Migration Strategy Using Backup + Atomic Migration + Rollback Support

**Background**: Users need a safe and reliable migration mechanism when upgrading RDD versions, ensuring no data loss and rollback capability.

**Decision Content**: Adopt three-phase migration strategy:
1. **Pre-check phase**: Check prerequisites, disk space, permissions
2. **Backup phase**: Create complete backup, record migration metadata
3. **Execution phase**: Atomic update, automatic rollback on failure

Supported features:
- Automatic backup of key configurations before migration
- Migration scripts organized by version (.rdd/migrations/)
- Migration log records all operations
- Support one-click rollback to previous version

**Reason**:
1. Backup ensures data safety, recoverable
2. Atomic migration guarantees consistency
3. Rollback mechanism reduces upgrade risk
4. Migration logs facilitate audit and troubleshooting
5. Phased design facilitates debugging and extension

**Impact on Subsequent Stages**:
- Stage 7: Can automatically test migration process in CI
- Provide migration documentation and best practice guides
- Can extend to support database migration (if needed)

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. Only prompt user for manual backup - Poor user experience
2. Migration without rollback support - High risk
3. External migration tools - Adds dependencies

---

### Decision 20: Compatibility Checking Using YAML Schema Validation + Breaking Change Detection

**Background**: Need to verify user configuration files are compatible with current RDD version, timely discover configuration issues and potential breaking changes.

**Decision Content**: Implement multi-dimensional compatibility checking:
1. **Schema Validation**: Check required fields, field types, valid values
2. **Version Compatibility**: Check configuration version compatibility with framework version
3. **Breaking Change Detection**: Identify breaking changes between versions
4. **Deprecation Warnings**: Prompt for features about to be removed
5. **Auto-fix**: Provide auto-fix capability for simple issues

**Reason**:
1. Schema validation discovers configuration errors early
2. Breaking change detection helps users plan upgrades
3. Deprecation warnings give users migration time
4. Auto-fix reduces user manual operations
5. Comprehensive checking improves system stability

**Impact on Subsequent Stages**:
- Stage 7: Can integrate into CI flow for automatic checking
- Configuration validation can prevent runtime errors
- Can extend to support more configuration formats

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. Version number check only - Cannot discover configuration issues
2. External schema validation tools - Adds dependencies
3. No compatibility checking - Poor user experience, error-prone

---

### Decision 17: Handoff Document Using Markdown Format Stored in .rdd/cache/handoff.md

**Background**: Stage 3 needs to implement a context recovery system, need to determine the storage format and location of Handoff documents.

**Decision Content**:
1. **Storage Format**: Use Markdown format, easy for Agent and human reading
2. **Storage Location**: `.rdd/cache/handoff.md`, same directory as Checkpoint files
3. **Document Structure**:
   - Current Progress
   - Completed Evidence
   - Blockers and Risks
   - Next Single Action
   - Degradation Strategy
   - Recovery Instructions

**Reason**:
1. Markdown format is easy for Agent to parse and generate
2. Plain text format requires no extra dependencies
3. Consistent with CLAUDE.md style
4. Facilitates version control and diff comparison
5. Storing in cache directory can be gitignored

**Impact on Subsequent Stages**:
- Stage 4 CI/CD can directly read Handoff status
- Future can extend to support multi-project Handoff
- Can integrate with notification system

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. JSON format - Not convenient for human reading
2. YAML format - Requires YAML parser
3. Store in docs directory - Would pollute version history

---

### Decision 18: Checkpoint Using JSON Format Stored in .rdd/cache/checkpoints.json

**Background**: Stage 3 needs to save execution state for recovery, need to determine Checkpoint storage format and structure.

**Decision Content**:
1. **Storage Format**: JSON format, easy for program parsing
2. **Storage Location**: `.rdd/cache/checkpoints.json`
3. **Data Structure**:
   - version: Format version
   - project: Project information
   - stage: Current Stage information
   - gates: Gate completion status
   - decisions: Decision history
   - blockers: Blocking items
   - tech_debt: Technical debt status
   - next_steps: Next steps
   - timestamp: Timestamp
   - recovery_count: Recovery count

**Reason**:
1. JSON is a standard format parsable by Shell scripts
2. Structured data easy for program processing
3. Supports incremental updates
4. Extensible to add new fields
5. Complements Handoff document

**Impact on Subsequent Stages**:
- Stage 4 can implement checkpoint resume based on Checkpoint
- Stage 5 can generate progress reports based on Checkpoint
- Future can support distributed Checkpoint sync

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. SQLite database - Adds dependency
2. Plain text format - Not convenient for structured queries
3. Multi-file storage - Increases management complexity

---

### Decision 19: Recovery Protocol Defined in CLAUDE.md Session Startup Protocol

**Background**: Stage 3 needs to implement automatic recovery after Compact, need to determine where to define the recovery protocol and trigger mechanism.

**Decision Content**:
1. **Protocol Location**: Define Compact Recovery Protocol section in CLAUDE.md
2. **Detection Mechanism**: Check if `.rdd/cache/handoff.md` exists to determine if recovery is needed
3. **Recovery Steps**:
   - Read Handoff document
   - Load Checkpoint state
   - Verify environment consistency
   - Resume from last interruption point
   - Confirm recovery complete

**Reason**:
1. CLAUDE.md is the Agent's entry document
2. CLAUDE.md is always read at session startup
3. Detection mechanism is simple and reliable
4. No need to modify Agent core logic
5. Documentation facilitates understanding and maintenance

**Impact on Subsequent Stages**:
- All Agents can automatically support recovery
- Can extend to support more recovery scenarios
- Future can integrate into Agent training

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. Independent recovery script - Agent needs to actively call
2. Environment variable marker - May be overwritten
3. Git hook trigger - Coupled with version control

---

### Decision 20: Handoff Auto-Trigger Using Three Trigger Mechanisms

**Background**: Stage 3 needs to determine when to automatically generate Handoff documents to ensure context is not lost.

**Decision Content**: Implement three automatic trigger mechanisms:
1. **Gate Completion Trigger**: Auto-generate Handoff after any Gate completes
2. **Decision Trigger**: Update Handoff after recording important decisions (ADR)
3. **Timer Trigger**: Auto-generate after 30 minutes without Checkpoint update

**Reason**:
1. Gate completion is an important milestone, should be recorded
2. Decisions affect subsequent work, need to record context
3. Timer trigger prevents losing progress in long-running tasks
4. Three trigger mechanisms complement each other, covering different scenarios
5. Can be manually triggered via task command

**Impact on Subsequent Stages**:
- Stage 4 can extend more trigger conditions
- Future can support custom trigger rules
- Can integrate into CI/CD pipeline

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. Manual trigger only - Easy to forget
2. Timer trigger only - May miss important milestones
3. Trigger after every operation - Too frequent, affects performance

---

## ADR Deprecation Records

When decisions are no longer applicable, record the deprecation reason here:

### [Decision Number] Deprecation Record

**Deprecation Date**: [Date]

**Deprecation Reason**: [Explain why this decision is deprecated]

**Alternative Solution**: [New decision or solution]

**Impact Assessment**: [Impact on existing code after deprecation]

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-10
**Related Stage**: Stage unknown

