# Stage 2: Test Infrastructure Development

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

## Goals
Establish a complete test system to ensure framework reliability. Including unit tests, BDD tests, and E2E tests - a three-layer testing architecture.

## Non-Goals
- Context recovery functionality (Stage 3)
- CI/CD production environment integration (Stage 4)
- Complete Mock Claude API implementation (only basic mock)

## Core Hypotheses
- H1: bats-core can meet Shell script unit testing requirements
- H2: BDD scenarios can verify user behavior expectations
- H3: E2E tests can simulate real Agent workflows
- H4: Test coverage can reach 80%

## Acceptance Criteria
- [x] Unit test framework integrated (bats-core)
- [x] notify.sh unit test coverage >= 80% (34 tests)
- [ ] Hook script unit test coverage >= 80%
- [x] BDD scenario definition complete (Given/When/Then) - 10 tests
- [ ] Gate check automation tests complete
- [x] E2E test project template created - 12 tests
- [ ] Mock Claude API basic implementation
- [x] `task test` executes all tests - 81 tests passing
- [x] Test coverage report generation
- [ ] CI pipeline configuration complete

## Rollback Plan
Test framework is independent of core functionality, can rollback by deleting tests/ directory.

## Known Limitations
- Mock Claude API only has basic implementation, doesn't simulate complete Agent behavior
- Coverage tool kcov may not be available in all environments
- E2E tests use DRY_RUN mode to avoid actual network calls

## Impact on Subsequent Stages
- Stage 3 can rely on test coverage for context recovery implementation
- Stage 4 can rely on CI pipeline for automated deployment

---

## Implementation Notes

### Technical Decisions Made
- Decision 5: Choose bats-core as Shell testing framework (ADR-005)
- Decision 6: Test layering strategy: unit/BDD/E2E three-layer testing (ADR-006)

### Architecture
```
tests/
├── unit/                    # Unit tests (bats-core)
│   ├── notify.bats          # notify.sh function tests
│   ├── hooks/               # Hook script tests
│   └── helpers/             # Test helpers
├── bdd/                     # BDD tests
│   ├── hook-notification.bats
│   ├── error-handling.bats
│   └── config-loading.bats
├── e2e/                     # E2E tests
│   ├── full-notification-flow.bats
│   └── mock-claude/
├── fixtures/                # Test fixtures
└── lib/                     # Test libraries
    ├── bats-core/
    ├── bats-support/
    └── bats-assert/
```

### Testing Strategy
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

---

## Verification

### Gate 1: Design Document Check
- [x] Design document complete
- [x] Goals clearly defined
- [x] Non-goals explicitly stated
- [x] Acceptance criteria testable
- [x] Rollback plan exists

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
