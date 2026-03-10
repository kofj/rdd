# Engineering Principles

> This document defines the core engineering principles for RDD projects, guiding all technical decisions and implementation choices.

---

## Core Principles

### 1. Roadmap Driven

**Principle Description**: Humans lay the tracks and define Stage routes; Agents move along the tracks automatically. Roadmap changes require human review.

**Key Practices**:

- Roadmap is defined by humans, containing clear Stage sequences
- Agents execute Stages in the order defined by the Roadmap
- Any Roadmap changes require human confirmation
- After each Stage completion, update progress and prepare for the next Stage

**Key Rules**:

```
- Agents cannot modify the Roadmap themselves
- Adding/removing/modifying Stages requires human approval
- Priority adjustments require human decisions
```

### 2. Stage as Minimum Delivery Unit

**Principle Description**: Each Stage is a verifiable, rollbackable, and handoffable minimum delivery unit. Control scope, accept staged compromises.

**Key Practices**:

- Each Stage must have clear goals and non-goals
- Each Stage must have verifiable acceptance criteria
- Each Stage must have a rollback plan
- Stage completion must produce deliverable outcomes

**Key Rules**:

```
- Single Stage work limited to 1-3 days
- Each Stage validates only a small set of clear hypotheses
- Naturally supports interruption recovery and multi-Agent collaboration
```

### 3. Anti-Corruption Mechanisms First

**Principle Description**: Prevent project corruption through forbidden behavior list, four gates, and documentation update obligations.

**Key Practices**:

- Follow the 9-item forbidden behavior list
- Pass gate checks before entering the next phase
- Documentation must be updated synchronously, no "docs to be added" state allowed

**Forbidden Behavior List**:

| ID | Forbidden Behavior | Correct Approach |
|----|-------------------|------------------|
| 1 | Starting implementation without design doc | Must complete design doc before coding |
| 2 | Silent scope expansion | Stop immediately, update docs first |
| 3 | Claiming completion with pending docs | Docs must be complete, no backfilling |
| 4 | Multiple core unknowns in one Stage | Each Stage validates only one small set of hypotheses |
| 5 | Relying on oral instructions to run tests | Tests must be reproducible via Task entry |
| 6 | Writing scripts with hidden platform assumptions | Environment assumptions must be explicitly documented |
| 7 | Introducing broad interfaces before understanding runtime constraints | Verify constraints first, then design interfaces |
| 8 | Putting expensive checks in default edit loops | Expensive checks should be explicitly triggered |
| 9 | Managing tech debt as implicit knowledge | All known gaps must be explicitly recorded in ledger |

### 4. Explicit Knowledge Management

**Principle Description**: Tech debt must be visible, not managed as implicit knowledge; ADRs must record "impact on subsequent Stages"; new Agents can bootstrap from docs.

**Key Practices**:

- All tech debt must be recorded in the ledger
- ADRs (Architecture Decision Records) must be complete
- Documentation sufficient for new Agents to understand project state

**Documentation Update Obligations**:

| Document | Update Content | Timing |
|----------|----------------|--------|
| `stage-N.md` | Implementation differences, acceptance criteria changes | Stage completion |
| `stage-N-review-log.md` | Findings, adoption/rejection reasons | Review completion |
| `08-autonomous-decisions.md` | ADRs, hypothesis deviations | When decisions occur |
| `12-technical-debt.md` | New/resolved tech debt | Stage completion |
| `11-next-steps.md` | Progress, next Stage entry conditions | Stage completion |
| `CHANGELOG.md` | This Stage's change summary | Stage completion |

### 5. Multi-Model Cross-Validation

**Principle Description**: Main dev model + independent review model + rule checks. ~50% of findings are false positives, verify each independently.

**Key Practices**:

- Use multiple models for review
- First round open, no dimensions/hints given
- Independently verify each finding

**Verification Priority**:

```
Authoritative Sources > Code Verification > Model Follow-up
```

**Verification Methods**:

| Method | Description | Applicable Scenarios |
|--------|-------------|---------------------|
| Authoritative Sources | Consult official docs, standards, best practices | Standards/specs-related issues |
| Code Verification | Run code, tests to verify | Reproducible issues |
| Model Follow-up | Request more explanation from review model | Need further clarification |

### 6. Hook Notification Mechanism

**Principle Description**: Automatic notification when human intervention needed, multi-channel support, tiered notifications.

**Key Practices**:

- Configure notification channels (WeCom, Email, Bark, Telegram, Webhook)
- Tiered notifications by priority
- P0 level blocks Agent waiting for human intervention

**Notification Tiers**:

| Level | Blocking Behavior | Default Channels | Examples |
|-------|------------------|------------------|----------|
| P0 | Agent pauses, waits for human | All channels | Consecutive failures, hypothesis falsified, Roadmap change |
| P1 | Agent continues, recommend handling ASAP | Main channels | Model disagreement, tech debt threshold exceeded |
| P2 | Non-blocking, info sync | Instant channels | Stage complete, new ADR |
| P3 | Non-blocking, periodic summary | Batch channels | Daily/weekly reports |

---

## Quality Standards

### Code Quality Standards

| Metric | Target | Minimum | Verification |
|--------|--------|---------|--------------|
| Unit Test Coverage | >= 80% | >= 20% | CI report |
| E2E Tests | At least 2 high-signal paths | - | Tests pass |
| Code Review | 100% code reviewed | - | Review records |
| Static Analysis | No Critical/High issues | - | CI report |

### Documentation Quality Standards

| Doc Type | Quality Standard |
|----------|-----------------|
| Stage Docs | Clear goals, explicit non-goals, testable acceptance criteria |
| ADR | "Impact on subsequent Stages" cannot be empty |
| Tech Debt Ledger | Priority, source, suggested Stage clear |
| Handoff | Current progress, blocking risks, next steps clear |

### Testing Quality Standards

```
- All tests must be reproducible via Task entry
- E2E tests must run in real environment (not mock)
- New features must have corresponding test cases
- Bug fixes must have regression tests
```

---

## Decision Principles

### Architecture Decision Principles

1. **Simplicity First**: Choose the simplest solution that meets requirements
2. **Evolutionary Design**: Don't prematurely abstract, wait for requirements to clarify
3. **Rollbackable**: Every decision should consider failure rollback plan
4. **Explicit Over Implicit**: Explicit declarations over implicit conventions

### Technology Selection Principles

1. **Mature and Stable**: Prefer mature, stable technology solutions
2. **Team Familiarity**: Prefer technology stack the team is familiar with
3. **Rich Ecosystem**: Prefer technologies with rich ecosystems
4. **Maintainability**: Consider long-term maintenance costs

### Trade-off Principles

```
When trading off between dimensions:

1. Function vs Stability → Prefer Stability
2. Performance vs Maintainability → Prefer Maintainability
3. Perfect vs Deliverable → Prefer Deliverable (record tech debt)
4. Generic vs Specific → Prefer Specific (avoid premature abstraction)
```

---

## Good/Bad Case Examples

### Good Case 1: Stage Boundary Control

**Scenario**: Need to implement user authentication

**Good**:

```
Stage 1: User Registration and Login
- Goal: Implement basic registration and login
- Non-goals: Third-party login, MFA
- Effort: 1 day

Stage 2: Token Management
- Goal: Implement JWT Token generation and validation
- Non-goals: Token refresh mechanism
- Effort: 0.5 day

Stage 3: Third-party Login
- Goal: Support GitHub login
- Non-goals: Other third-party platforms
- Effort: 1 day
```

**Bad**:

```
Stage 1: Complete User Authentication System
- Goals: Registration, login, third-party login, MFA, token management
- Non-goals: None
- Problem: Scope too large, contains multiple core unknowns
```

### Good Case 2: Tech Debt Management

**Scenario**: Found code that needs optimization

**Good**:

```
TD-01: Missing error retry mechanism
- Priority: Feature Degradation / Module-level
- Source: Stage 2 review deferred
- Original description: "Suggest adding error retry, but not in current Stage scope"
- Source file: src/client.rs:45
- Suggested Stage: Stage 4

Action: Record in tech debt ledger, handle in Stage 4
```

**Bad**:

```
Issue: Found missing error retry mechanism
Action: Keep in mind, will handle later
Problem: Not explicitly recorded, might be forgotten
```

### Good Case 3: Review Verification

**Scenario**: Review suggests "should use async IO here"

**Good**:

```
Finding: Suggest using async IO for performance

Verification:
1. Check authoritative source: Rust docs show current scenario doesn't need async
2. Code verification: Run benchmark, sync vs async diff < 5%
3. Conclusion: False positive, current implementation meets performance needs

Record: Document non-adoption reason in review-log.md
```

**Bad**:

```
Finding: Suggest using async IO for performance

Verification:
1. Model says it's needed, so change it
2. Didn't verify actual performance difference
3. Problem: Might introduce unnecessary complexity
```

### Good Case 4: Documentation Sync

**Scenario**: During implementation, design needs adjustment

**Good**:

```
1. Stop coding immediately
2. Update design in stage-N.md
3. Record change reason and impact
4. Continue coding
5. Stage complete, all docs already synced
```

**Bad**:

```
1. Continue coding, design already changed
2. Think "will add docs later"
3. Claim completion when Stage done
4. Problem: Docs inconsistent with code, hard to maintain
```

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Note**: This principles document is the core guidance for RDD projects. Any changes require recording through ADR.
