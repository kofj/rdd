# Stage Based Development Specification

> This document defines the development specifications for Stages in RDD projects, including definitions, completion criteria, sizing rules, testing strategies, and artifact requirements.

---

## Stage Definition

### What is a Stage

A Stage is the smallest delivery unit in RDD development with the following characteristics:

- **Verifiable**: Has clear acceptance criteria, can be independently verified upon completion
- **Rollbackable**: Has a rollback plan, can safely roll back on failure
- **Handoffable**: Has complete documentation, can be handed off to other Agents
- **Minimal**: Controls scope, accepts stage-level compromises

### Difference Between Stage and Task

| Dimension | Stage | Task |
|-----------|-------|------|
| Granularity | Minimum delivery unit | Implementation step |
| Duration | 1-3 days | Several hours |
| Acceptance | Has independent acceptance criteria | Belongs to Stage |
| Documentation | Requires complete documentation | No independent documentation needed |
| Rollback | Has independent rollback plan | Rolls back with Stage |

### Stage Lifecycle

```
[Planning] → [In Progress] → [Completed]
     ↓            ↓
  [Blocked]   [Failed] → [Rollback]
```

---

## Stage Completion Criteria

### Gate Checklist

Before completing each Stage, the following gate checks must pass:

#### Gate 1: Design Document Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Design document completed | Must be completed | [ ] |
| Goals clear | Must be clear | [ ] |
| Non-goals explicitly stated | Must be stated | [ ] |
| Acceptance criteria testable | Must be testable | [ ] |
| Rollback plan exists | Must exist | [ ] |

#### Gate 2: Design Review Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Multi-model review triggered | Triggered | [ ] |
| AI initial screening completed | Completed | [ ] |
| High-confidence findings resolved | Resolved | [ ] |

#### Gate 3: Implementation and Testing Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Implementation completed | Completed | [ ] |
| Unit test coverage | >= 20% | [ ] |
| E2E tests | At least 2 high-signal paths | [ ] |
| Real environment verification | Not mock | [ ] |
| Clean environment verification | Passed | [ ] |

#### Gate 4: Code Review Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Triangulation completed | Main dev + independent reviewer + rule check | [ ] |
| All blocking findings resolved | Resolved | [ ] |
| All acceptance criteria met | Met | [ ] |

#### Gate 5: Completion Gate Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Main hypotheses verified or falsified | Recorded | [ ] |
| Tests reproducible via Task entry point | Verified | [ ] |
| No undocumented manual steps | Confirmed | [ ] |
| Implementation consistent with design (differences recorded) | Confirmed | [ ] |
| New capabilities have CLI subcommands (if applicable) | Implemented | [ ] |
| Technical debt ledger updated | Updated | [ ] |
| ADR recorded ("impact on subsequent Stages" cannot be empty) | Recorded | [ ] |
| fresh-agent-check passed | Passed | [ ] |

### Documentation Completion Criteria

Documents that must be synchronously updated when a Stage completes:

| Document | Content Requirements | Check |
|----------|----------------------|-------|
| `stage-N.md` | Implementation differences, acceptance criteria changes | [ ] |
| `stage-N-review-log.md` | Findings, adoption/rejection reasons | [ ] |
| `08-autonomous-decisions.md` | ADR, assumption deviations | [ ] |
| `12-technical-debt.md` | New/resolved technical debt | [ ] |
| `11-next-steps.md` | Progress, next step entry conditions | [ ] |
| `CHANGELOG.md` | This Stage's change summary | [ ] |

---

## Stage Sizing Rules

### Time Sizing

| Size | Workload | Applicable Scenarios |
|------|----------|----------------------|
| Small | 0.5-1 day | Single feature, small optimization, bug fix |
| Medium | 1-2 days | Feature module, medium complexity changes |
| Large | 2-3 days | Larger features, architecture adjustments |

**Rule**: Single Stage should not exceed 3 days of work. If exceeded, it needs to be split.

### Complexity Sizing

| Dimension | Low Complexity | Medium Complexity | High Complexity |
|-----------|----------------|-------------------|-----------------|
| Dependencies | No external dependencies | 1-2 dependencies | 3+ dependencies |
| Unknowns | No unknowns | 1 core unknown | 2+ core unknowns |
| Impact Scope | Local modifications | Module level | Architecture level |
| Rollback Difficulty | Simple rollback | Requires data migration | Requires multi-step rollback |

**Rule**: High complexity Stages need further splitting or buffer time added.

### Scope Rules

```
DO:
- Each Stage only validates a small set of clear hypotheses
- Explicitly state non-goals
- Accept stage-level compromises
- Leave clear next steps

DON'T:
- Put multiple Stage core unknowns in one Stage
- Silently expand scope
- Pursue perfectionism
- Skip non-goal declaration
```

### Splitting Guidelines

When a Stage is too large, split according to these principles:

1. **Split by Function**: Break large features into smaller features
2. **Split by Layer**: Break architecture layers into multiple Stages
3. **Split by Risk**: Isolate high-risk parts as independent Stages
4. **Split by Dependency**: Break dependencies into multiple Stages

---

## Testing Strategy

### Testing Layers

```
        ┌─────────────────┐
        │    E2E Tests    │  ← At least 2 high-signal paths
        │ (Real Env)      │
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        │ Integration     │  ← Key path integration
        │ Tests           │
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        │   Unit Tests    │  ← Coverage >= 20%
        │ (Function level)│
        └─────────────────┘
```

### Unit Test Requirements

| Requirement | Description |
|-------------|-------------|
| Coverage | >= 20% (minimum) / >= 80% (target) |
| Isolation | Tests are independent of each other |
| Repeatability | Consistent results across multiple runs |
| Naming | Test names describe behavior |

### E2E Test Requirements

| Requirement | Description |
|-------------|-------------|
| Quantity | At least 2 high-signal paths |
| Environment | Real environment, not mock |
| Verification | Verify complete business flow |
| Cleanup | Clean up environment after test |

### Test Environment Requirements

| Environment | Purpose | Requirements |
|-------------|---------|--------------|
| Local Environment | Development and debugging | Fast iteration |
| Clean Environment | Secondary verification | No residual state |
| Real Environment | E2E testing | Close to production |

### Test Entry Points

All tests must be reproducible via Task entry point:

```yaml
# Taskfile.yml example
tasks:
  test:
    desc: Run all tests
    cmds:
      - cargo test

  test-unit:
    desc: Run unit tests
    cmds:
      - cargo test --lib

  test-e2e:
    desc: Run E2E tests
    cmds:
      - cargo test --test e2e
```

---

## Stage Artifacts

### Required Artifacts

Each Stage must leave the following artifacts upon completion:

#### 1. Code Artifacts

| Artifact | Description | Check |
|----------|-------------|-------|
| Implementation code | Code implementing the feature | [ ] |
| Unit tests | Coverage >= 20% | [ ] |
| E2E tests | At least 2 high-signal paths | [ ] |
| Configuration files | Related configuration changes | [ ] |

#### 2. Documentation Artifacts

| Document | Description | Check |
|----------|-------------|-------|
| `stage-N.md` | Stage design and implementation record | [ ] |
| `stage-N-review-log.md` | Review record | [ ] |
| ADR update | Architecture decision record | [ ] |
| Technical debt update | New/resolved record | [ ] |
| Progress update | next-steps.md | [ ] |
| Change log | CHANGELOG.md | [ ] |

#### 3. Verifiable Artifacts

| Artifact | Description | Check |
|----------|-------------|-------|
| Runnable functionality | Feature runs normally | [ ] |
| Reproducible tests | Tests can run via Task | [ ] |
| Rollbackable version | Has clear rollback point | [ ] |

### Optional Artifacts

Depending on Stage type, optionally leave the following artifacts:

| Artifact | Applicable Scenarios |
|----------|----------------------|
| Performance benchmarks | Performance optimization Stage |
| API documentation | API development Stage |
| Deployment scripts | Deployment-related Stage |
| Migration scripts | Data migration Stage |

---

## Example Stage Flow

### Example Stage: Implement User Login Functionality

#### Stage Planning

```markdown
# Stage 2: Implement User Login Functionality

## Status
[ ] Planning / [x] In Progress / [ ] Completed

## Goals
Implement basic user login functionality with username and password support.

## Non-Goals
- Third-party login (GitHub, WeChat, etc.)
- Multi-factor authentication
- Password reset functionality
- Remember login state

## Core Assumptions
- Users have completed registration through Stage 1
- Passwords are encrypted and stored
- JWT is used for authentication

## Acceptance Criteria
- [ ] Users can log in with correct username and password
- [ ] Clear error messages returned on login failure
- [ ] Valid JWT Token returned on successful login
- [ ] Unit test coverage >= 20%
- [ ] E2E tests pass

## Rollback Plan
Delete login-related code, revert to Stage 1 completion state.

## Known Limitations
- Only supports username and password login
- Token validity fixed at 24 hours
- No concurrent login restriction support

## Impact on Subsequent Stages
- Stage 3 will implement Token refresh mechanism based on this
- Stage 4 will extend to support third-party login
```

#### Gate 1: Design Document Check

```
[✓] Design document completed → Completed
[✓] Goals clear → Clear goal: Implement user login functionality
[✓] Non-goals explicitly stated → Stated: third-party login, MFA, etc.
[✓] Acceptance criteria testable → 5 testable criteria
[✓] Rollback plan exists → Delete code and revert
```

#### Gate 2: Design Review

```
Trigger Review → Receive findings → AI initial screening → Verify each finding

Finding 1: Recommend using bcrypt instead of SHA256
Verify: Consult authoritative sources, bcrypt is indeed better for password storage
Decision: Adopt, update design

Finding 2: JWT should include expiration time
Verify: Code verification, 24-hour validity already declared in design
Decision: Already satisfied, no changes needed
```

#### Gate 3: Implementation and Testing

```
[✓] Implementation completed
[✓] Unit test coverage: 35%
[✓] E2E tests: 3 high-signal paths
[✓] Real environment verification: Passed
[✓] Clean environment verification: Passed
```

#### Gate 4: Code Review

```
[✓] Triangulation completed
[✓] Blocking findings resolved
[✓] Acceptance criteria met
```

#### Gate 5: Completion Gate

```
[✓] Hypotheses verified: Users can log in normally
[✓] Tests reproducible via Task entry point
[✓] No undocumented manual steps
[✓] Implementation consistent with design
[✓] Technical debt recorded: Token refresh mechanism to be implemented
[✓] ADR recorded: Selected bcrypt as password hashing algorithm
[✓] fresh-agent-check passed
```

#### Documentation Update

```markdown
# stage-2.md update

## Implementation Differences
- Used bcrypt instead of SHA256 for password verification
- Token validity configurable, read from environment variable

## Acceptance Criteria Changes
- Added: Token validity period configurable

# stage-2-review-log.md

## Findings
1. Recommend using bcrypt → Adopted
2. JWT should include expiration time → Already satisfied, no changes needed

# 08-autonomous-decisions.md

### Decision 2: Use bcrypt as Password Hashing Algorithm

**Background**: Review recommended using bcrypt instead of SHA256

**Decision Content**: Adopt bcrypt for password hashing

**Reason**: bcrypt is designed for password storage, includes salt and adjustable cost

**Impact on Subsequent Stages**: Stage 3's Token verification needs to be compatible with bcrypt

# 12-technical-debt.md

### TD-01: Token Refresh Mechanism to be Implemented
- Priority: Feature Degradation / Module-level
- Source: Stage 2 non-goals
- Original Description: "Token validity fixed at 24 hours, no refresh support"
- Suggested Landing Stage: Stage 3
```

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Note**: This specification is the core guidance for RDD development. Any changes require recording the decision process through ADR.
