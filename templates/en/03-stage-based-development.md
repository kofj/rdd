# Stage Based Development Specification

> This document defines the development specifications for Stages in RDD projects, including definitions, completion criteria, sizing rules, testing strategies, and artifact requirements.

---

## Stage Definition

### What is a Stage

A Stage is the minimum delivery unit in RDD development with the following characteristics:

- **Verifiable**: Has clear acceptance criteria, can be independently verified upon completion
- **Rollbackable**: Has rollback plan, can safely roll back on failure
- **Handoffable**: Has complete documentation, can be handed off to other Agents
- **Minimal**: Controls scope, accepts staged compromises

### Stage vs Task

| Dimension | Stage | Task |
|-----------|-------|------|
| Granularity | Minimum delivery unit | Implementation step |
| Time | 1-3 days | Hours |
| Acceptance | Has independent acceptance criteria | Belongs to Stage |
| Documentation | Requires complete docs | No independent docs needed |
| Rollback | Has independent rollback plan | Rolls back with Stage |

### Stage Lifecycle

```
[Planning] → [In Progress] → [Complete]
     ↓             ↓
  [Blocked]    [Failed] → [Rollback]
```

---

## Stage Completion Criteria

### Gate Checklist

Each Stage must pass these gate checks before completion:

#### Gate 1: Design Document Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Design doc complete | Must be complete | [ ] |
| Goals clear | Must be explicit | [ ] |
| Non-goals explicitly declared | Must be declared | [ ] |
| Acceptance criteria testable | Must be testable | [ ] |
| Rollback plan exists | Must exist | [ ] |

#### Gate 2: Design Review Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Multi-model review triggered | Triggered | [ ] |
| AI filtering complete | Complete | [ ] |
| High-confidence findings addressed | Addressed | [ ] |

#### Gate 3: Implementation & Testing Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Implementation complete | Complete | [ ] |
| Unit test coverage | >= 20% | [ ] |
| E2E tests | At least 2 high-signal paths | [ ] |
| Real environment verification | Not mock | [ ] |
| Clean environment verification | Passed | [ ] |

#### Gate 4: Code Review Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Triangulation complete | Main dev + independent review + rule check | [ ] |
| All blocking findings addressed | Addressed | [ ] |
| All acceptance criteria met | Met | [ ] |

#### Gate 5: Completion Gate Check

| Check Item | Requirement | Status |
|------------|-------------|--------|
| Main hypotheses verified or falsified | Recorded | [ ] |
| Tests reproducible via Task entry | Verified | [ ] |
| No undocumented manual steps | Confirmed | [ ] |
| Implementation matches design (differences recorded) | Confirmed | [ ] |
| New capabilities have CLI subcommands (if applicable) | Implemented | [ ] |
| Tech debt ledger updated | Updated | [ ] |
| ADR recorded ("impact on subsequent Stages" not empty) | Recorded | [ ] |
| fresh-agent-check passed | Passed | [ ] |

### Documentation Completion Criteria

Documents that must be updated when Stage completes:

| Document | Content Required | Check |
|----------|-----------------|-------|
| `stage-N.md` | Implementation differences, acceptance criteria changes | [ ] |
| `stage-N-review-log.md` | Findings, adoption/rejection reasons | [ ] |
| `08-autonomous-decisions.md` | ADRs, hypothesis deviations | [ ] |
| `12-technical-debt.md` | New/resolved tech debt | [ ] |
| `11-next-steps.md` | Progress, next Stage entry conditions | [ ] |
| `CHANGELOG.md` | This Stage's change summary | [ ] |

---

## Stage Sizing Rules

### Time Sizing

| Size | Effort | Applicable Scenarios |
|------|--------|---------------------|
| Small | 0.5-1 day | Single feature, small optimization, bug fix |
| Medium | 1-2 days | Feature module, medium complexity changes |
| Large | 2-3 days | Larger features, architecture adjustments |

**Rule**: Single Stage should not exceed 3 days of work. If larger, split it.

### Complexity Sizing

| Dimension | Low Complexity | Medium Complexity | High Complexity |
|-----------|---------------|-------------------|-----------------|
| Dependencies | No external deps | 1-2 dependencies | 3+ dependencies |
| Unknowns | No unknowns | 1 core unknown | 2+ core unknowns |
| Impact Scope | Local changes | Module level | Architecture level |
| Rollback Difficulty | Simple rollback | Needs data migration | Needs multi-step rollback |

**Rule**: High complexity Stages need further splitting or buffer time.

### Scope Rules

```
DO:
- Each Stage validates only a small set of clear hypotheses
- Explicitly declare non-goals
- Accept staged compromises
- Leave clear next steps

DON'T:
- Put multiple core unknowns in one Stage
- Silently expand scope
- Pursue perfectionism
- Skip non-goal declarations
```

### Splitting Guidelines

When Stage is too large, split by these principles:

1. **By Feature**: Split large feature into smaller features
2. **By Layer**: Split architecture layers into multiple Stages
3. **By Risk**: Isolate high-risk parts as separate Stages
4. **By Dependency**: Split dependencies into multiple Stages

---

## Testing Strategy

### Testing Layers

```
        ┌─────────────────┐
        │    E2E Tests    │  ← At least 2 high-signal paths
        │  (Real Env)     │
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        │ Integration     │  ← Key path integration
        │    Tests        │
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        │   Unit Tests    │  ← Coverage >= 20%
        │  (Function)     │
        └─────────────────┘
```

### Unit Test Requirements

| Requirement | Description |
|-------------|-------------|
| Coverage | >= 20% (minimum) / >= 80% (target) |
| Isolation | Tests are independent of each other |
| Reproducibility | Consistent results across runs |
| Naming | Test names describe behavior |

### E2E Test Requirements

| Requirement | Description |
|-------------|-------------|
| Count | At least 2 high-signal paths |
| Environment | Real environment, not mock |
| Verification | Verify complete business flow |
| Cleanup | Clean up environment after test |

### Test Environment Requirements

| Environment | Purpose | Requirements |
|-------------|---------|--------------|
| Local | Development and debugging | Fast iteration |
| Clean | Secondary verification | No residual state |
| Real | E2E testing | Production-like |

### Test Entry Point

All tests must be reproducible via Task entry:

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

Each Stage completion must produce these artifacts:

#### 1. Code Artifacts

| Artifact | Description | Check |
|----------|-------------|-------|
| Implementation code | Code implementing features | [ ] |
| Unit tests | Coverage >= 20% | [ ] |
| E2E tests | At least 2 high-signal paths | [ ] |
| Config files | Related config changes | [ ] |

#### 2. Documentation Artifacts

| Document | Description | Check |
|----------|-------------|-------|
| `stage-N.md` | Stage design and implementation record | [ ] |
| `stage-N-review-log.md` | Review record | [ ] |
| ADR updates | Architecture decision records | [ ] |
| Tech debt updates | New/resolved records | [ ] |
| Progress update | next-steps.md | [ ] |
| Change log | CHANGELOG.md | [ ] |

#### 3. Verifiable Artifacts

| Artifact | Description | Check |
|----------|-------------|-------|
| Runnable functionality | Features work correctly | [ ] |
| Reproducible tests | Tests runnable via Task | [ ] |
| Rollbackable version | Clear rollback point | [ ] |

### Optional Artifacts

Depending on Stage type, optionally leave these artifacts:

| Artifact | Applicable Scenarios |
|----------|---------------------|
| Performance benchmarks | Performance optimization Stage |
| API documentation | API development Stage |
| Deployment scripts | Deployment-related Stage |
| Migration scripts | Data migration Stage |

---

## Example Stage Flow

### Example Stage: Implement User Login

#### Stage Planning

```markdown
# Stage 2: Implement User Login

## Status
[ ] Planning / [x] In Progress / [ ] Complete

## Goal
Implement basic user login functionality, support username/password login.

## Non-goals
- Third-party login (GitHub, WeChat, etc.)
- Multi-factor authentication
- Password reset
- Remember login state

## Core Hypotheses
- Users have registered through Stage 1
- Passwords are stored encrypted
- Use JWT for authentication

## Acceptance Criteria
- [ ] Users can login with correct username/password
- [ ] Login failure returns clear error message
- [ ] Login success returns valid JWT Token
- [ ] Unit test coverage >= 20%
- [ ] E2E tests pass

## Rollback Plan
Delete login-related code, rollback to Stage 1 completion state.

## Known Limitations
- Only supports username/password login
- Token validity fixed at 24 hours
- No concurrent login restrictions

## Impact on Subsequent Stages
- Stage 3 will implement Token refresh based on this
- Stage 4 will extend to support third-party login
```

#### Gate 1: Design Document Check

```
[✓] Design doc complete → Complete
[✓] Goals clear → Clear: implement user login
[✓] Non-goals explicitly declared → Declared: third-party login, MFA, etc.
[✓] Acceptance criteria testable → 5 testable criteria
[✓] Rollback plan exists → Delete code and rollback
```

#### Gate 2: Design Review

```
Trigger Review → Received findings → AI filter → Verify each

Finding 1: Suggest bcrypt instead of SHA256
Verify: Check authoritative source, bcrypt indeed better for passwords
Decision: Adopt, update design

Finding 2: JWT should include expiration time
Verify: Code check, 24-hour validity already declared in design
Decision: Already satisfied, no change needed
```

#### Gate 3: Implementation & Testing

```
[✓] Implementation complete
[✓] Unit test coverage: 35%
[✓] E2E tests: 3 high-signal paths
[✓] Real environment verification: Passed
[✓] Clean environment verification: Passed
```

#### Gate 4: Code Review

```
[✓] Triangulation complete
[✓] Blocking findings addressed
[✓] Acceptance criteria met
```

#### Gate 5: Completion Gate

```
[✓] Hypotheses verified: Users can login normally
[✓] Tests reproducible via Task entry
[✓] No undocumented manual steps
[✓] Implementation matches design
[✓] Tech debt recorded: Token refresh mechanism pending
[✓] ADR recorded: Chose bcrypt as password hash algorithm
[✓] fresh-agent-check passed
```

#### Documentation Updates

```markdown
# stage-2.md update

## Implementation Differences
- Using bcrypt instead of SHA256 for password verification
- Token validity configurable from environment variable

## Acceptance Criteria Changes
- Added: Token validity configurable

# stage-2-review-log.md

## Findings
1. Suggest bcrypt → Adopted
2. JWT should include expiration → Already satisfied, no change

# 08-autonomous-decisions.md

### Decision 2: Use bcrypt as password hash algorithm

**Background**: Review suggested bcrypt instead of SHA256

**Decision**: Adopt bcrypt for password hashing

**Reason**: bcrypt designed for password storage, includes salt and adjustable cost

**Impact on Subsequent Stages**: Stage 3 Token verification needs to be compatible with bcrypt

# 12-technical-debt.md

### TD-01: Token refresh mechanism pending
- Priority: Feature Degradation / Module-level
- Source: Stage 2 non-goal
- Original description: "Token validity fixed at 24 hours, no refresh"
- Suggested Stage: Stage 3
```

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Note**: This specification is the core guidance for RDD development. Any changes require recording through ADR.
