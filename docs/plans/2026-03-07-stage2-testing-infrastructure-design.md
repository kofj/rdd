# Stage 2: Testing Infrastructure Design

**Date**: 2026-03-07
**Status**: Approved
**Related Stage**: Stage 2

---

## Overview

This document describes the design for Stage 2 (Testing Infrastructure) of the RDD framework. The goal is to establish a complete testing system with unit tests, BDD tests, and E2E tests.

---

## Architecture

### Test Layer Structure

```
tests/
├── unit/                    # Unit tests (bats-core)
│   ├── notify.bats          # notify.sh function tests
│   ├── hooks/               # Hook script tests
│   │   ├── stage-complete.bats
│   │   ├── roadmap-change.bats
│   │   ├── consecutive-failure.bats
│   │   ├── hypothesis-invalid.bats
│   │   ├── model-disagreement.bats
│   │   ├── tech-debt-threshold.bats
│   │   ├── daily-report.bats
│   │   └── weekly-report.bats
│   └── helpers/             # Test helpers
│       └── test_helper.bash
├── bdd/                     # BDD tests (bats-core)
│   ├── hook-notification.bats
│   ├── error-handling.bats
│   └── config-loading.bats
├── e2e/                     # E2E tests
│   ├── full-notification-flow.bats
│   └── mock-claude/         # Mock Claude API
│       └── mock_claude.sh
├── fixtures/                # Test fixtures
│   ├── config/
│   │   ├── valid-hooks.yml
│   │   ├── minimal-hooks.yml
│   │   └── invalid-hooks.yml
│   └── templates/
│       └── test-templates.yml
└── lib/                     # Test libraries
    ├── bats-support/        # bats-support library
    ├── bats-assert/         # bats-assert library
    └── bats-mock/           # bats-mock library (optional)
```

### Component Interaction

```
┌─────────────────────────────────────────────────────────────┐
│                     Taskfile.yml                            │
│  test → test:unit, test:bdd, test:e2e, test:coverage       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  Unit Tests   │   │  BDD Tests    │   │  E2E Tests    │
│  (bats-core)  │   │  (bats-core)  │   │  (bats-core)  │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ notify.sh     │   │ Hook flows    │   │ Full workflow │
│ functions     │   │ error paths   │   │ Mock Claude   │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        └───────────────────┴───────────────────┘
                            ▼
                    ┌───────────────┐
                    │ Coverage Report│
                    │ (kcov)        │
                    └───────────────┘
```

---

## Components

### 1. Test Framework (bats-core)

**Installation**: Local installation via git submodule in `tests/lib/`

```bash
# Directory structure
tests/lib/
├── bats-core/           # Core bats framework
├── bats-support/        # Support functions (load, output)
└── bats-assert/         # Assertion functions (assert_equal, etc.)
```

**Version**: bats-core v1.11.0+

### 2. Unit Tests

**Scope**: Individual function testing

**Coverage Target**: >= 80%

**Key Test Files**:
- `notify.bats`: Test all notify.sh functions
  - `log_info`, `log_warn`, `log_error`, `log_debug`
  - `expand_env_vars`
  - `send_wecom`, `send_email`, `send_bark`, `send_telegram`, `send_webhook`
  - `is_quiet_hours`
  - `send_with_retry`
  - `send_notification`
- `hooks/*.bats`: Test each hook script's behavior
  - Environment variable handling
  - Function sourcing
  - Error handling

### 3. BDD Tests

**Scope**: User behavior scenarios

**Format**: Given/When/Then patterns

**Key Scenarios**:
1. **Hook Notification Flow**
   - Given: Configuration is valid
   - When: Hook is triggered
   - Then: Notification is sent to correct channels

2. **Error Handling**
   - Given: Invalid configuration
   - When: Hook tries to send notification
   - Then: Error is logged and appropriate exit code returned

3. **Quiet Hours**
   - Given: Quiet hours are configured
   - When: Notification is triggered during quiet hours
   - Then: Notification is skipped (unless P0)

### 4. E2E Tests

**Scope**: Full integration testing

**Key Tests**:
1. **Full Notification Flow**
   - Trigger stage-complete hook
   - Verify log output
   - Verify notification processing

2. **Mock Claude API** (optional for Stage 2)
   - Simulate agent behavior
   - Trigger hooks from skills
   - Verify end-to-end flow

### 5. Test Fixtures

**Purpose**: Provide consistent test data

**Fixture Files**:
- `fixtures/config/valid-hooks.yml`: Standard valid configuration
- `fixtures/config/minimal-hooks.yml`: Minimal configuration
- `fixtures/config/invalid-hooks.yml`: Invalid configuration for error tests
- `fixtures/templates/test-templates.yml`: Test message templates

### 6. Coverage Reporting

**Tool**: kcov (if available) or custom coverage tracking

**Output**: Coverage report in `tests/coverage/`

**Minimum Coverage**: 80% for notify.sh and hook scripts

---

## Data Flow

### Test Execution Flow

```
1. test:unit
   ├── Load bats-support
   ├── Load bats-assert
   ├── Load test_helper.bash
   ├── Set TEST_FIXTURES_DIR
   ├── Run unit tests
   └── Generate coverage report

2. test:bdd
   ├── Load test environment
   ├── Load fixtures
   ├── Run BDD scenarios
   └── Report results

3. test:e2e
   ├── Setup mock environment
   ├── Run full workflows
   ├── Verify outputs
   └── Cleanup
```

### Coverage Collection

```
tests/
├── unit/
│   └── *.bats → kcov → coverage/
├── coverage/
│   ├── index.html
│   └── *.json
└── reports/
    └── junit/
```

---

## Error Handling

### Test Failures

1. **Unit Test Failure**: Individual test fails, report details
2. **Fixture Missing**: Skip test with warning
3. **Coverage Below Threshold**: Exit with error after tests complete

### CI Integration

- Exit code 0: All tests pass, coverage meets threshold
- Exit code 1: Some tests failed
- Exit code 2: Coverage below threshold
- TAP output for CI parsing

---

## Testing Strategy

### What We Test

| Component | Test Type | Priority |
|-----------|-----------|----------|
| log_* functions | Unit | High |
| expand_env_vars | Unit | High |
| send_* functions | Unit | High |
| is_quiet_hours | Unit | Medium |
| send_notification | Unit | High |
| Hook scripts | Unit | High |
| Hook trigger flow | BDD | High |
| Error handling | BDD | Medium |
| Full notification | E2E | Medium |

### What We Don't Test (Stage 2)

- Actual network calls (use DRY_RUN=true)
- Claude API integration (Stage 4)
- Multi-project scenarios (Stage 4)

---

## Taskfile Integration

```yaml
# Added to Taskfile.yml

tasks:
  test:
    desc: Run all tests
    deps: [test:unit, test:bdd, test:e2e]
    cmds:
      - echo "All tests completed"

  test:unit:
    desc: Run unit tests with bats
    cmds:
      - tests/lib/bats-core/bin/bats tests/unit/

  test:bdd:
    desc: Run BDD tests with bats
    cmds:
      - tests/lib/bats-core/bin/bats tests/bdd/

  test:e2e:
    desc: Run E2E tests with bats
    cmds:
      - tests/lib/bats-core/bin/bats tests/e2e/

  test:coverage:
    desc: Generate coverage report
    cmds:
      - kcov --include-pattern=.rdd tests/coverage tests/lib/bats-core/bin/bats tests/unit/ || echo "kcov not available, skipping coverage"

  test:install-bats:
    desc: Install bats-core and libraries
    cmds:
      - git clone https://github.com/bats-core/bats-core.git tests/lib/bats-core
      - git clone https://github.com/bats-core/bats-support.git tests/lib/bats-support
      - git clone https://github.com/bats-core/bats-assert.git tests/lib/bats-assert
```

---

## Acceptance Criteria Mapping

| Criteria | Implementation |
|----------|----------------|
| Unit test framework integrated | bats-core installed in tests/lib/ |
| notify.sh coverage >= 80% | Unit tests for all functions |
| Hook scripts coverage >= 80% | Unit tests for each hook |
| BDD scenarios defined | tests/bdd/*.bats files |
| Gate check automation tests | BDD tests for gate checks |
| E2E test project template | tests/e2e/ structure |
| Mock Claude API integration | tests/e2e/mock-claude/ (basic) |
| `task test` runs all tests | Taskfile.yml tasks |
| Coverage report generated | kcov integration |
| CI pipeline configured | .github/workflows/test.yml |

---

## Implementation Phases

### Phase 1: Setup (1 day)
- Install bats-core and libraries
- Create test directory structure
- Add test fixtures
- Update Taskfile.yml

### Phase 2: Unit Tests (2-3 days)
- notify.sh unit tests
- Hook scripts unit tests
- Achieve 80% coverage

### Phase 3: BDD Tests (1-2 days)
- Hook notification scenarios
- Error handling scenarios
- Config loading scenarios

### Phase 4: E2E Tests (1 day)
- Full workflow tests
- Mock environment setup

### Phase 5: CI Integration (1 day)
- GitHub Actions workflow
- Coverage reporting
- Quality gates

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| bats-core installation issues | Low | Medium | Use git submodule, document installation |
| Coverage tool not available | Medium | Low | Fallback to manual coverage tracking |
| Mock complexity | Medium | Medium | Keep mocks simple, use DRY_RUN mode |
| Test flakiness | Low | High | Use deterministic fixtures, avoid race conditions |

---

## Dependencies

- **External**: bats-core, bats-support, bats-assert
- **Optional**: kcov (for coverage reporting)
- **Internal**: notify.sh, hook scripts (completed in Stage 1)

---

## Notes

- Tests use DRY_RUN=true to avoid actual network calls
- Fixtures provide consistent, deterministic test data
- Coverage threshold enforced in CI
- BDD tests document expected behavior
