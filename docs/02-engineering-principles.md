# Engineering Principles

> This document defines the core engineering principles for the RDD project, guiding all technical decisions and implementation choices.

---

## Core Principles

### 1. Roadmap Driven

**Principle Description**: Humans lay the tracks, defining the Stage sequence; Agents move along the tracks automatically. Roadmap changes require human review.

**Practice Points**:

- Roadmap is defined by humans, containing a clear Stage sequence
- Agents execute Stages in the order defined by the Roadmap
- Any Roadmap changes require human confirmation
- After each Stage completion, update progress and prepare for the next Stage

**Key Rules**:

```
- Agents cannot modify the Roadmap themselves
- Adding, removing, or modifying Stages requires human approval
- Priority adjustments require human decision-making
```

### 2. Stage as Minimum Delivery Unit

**Principle Description**: Each Stage is a minimum delivery unit that is verifiable, rollbackable, and handoffable. Control scope, accept阶段性 compromises.

**Practice Points**:

- Each Stage must have clear goals and non-goals
- Each Stage must have verifiable acceptance criteria
- Each Stage must have a rollback plan
- Stage completion must produce deliverable outcomes

**Key Rules**:

```
- Single Stage workload should be 1-3 days
- Each Stage only validates a small set of clear hypotheses
- Naturally supports interruption recovery and multi-Agent collaboration
```

### 3. Anti-Corruption Mechanism First

**Principle Description**: Prevent project corruption through a list of prohibited behaviors, four gates, and documentation update obligations.

**Practice Points**:

- Adhere to the 9 prohibited behaviors list
- Must pass four gate checks before entering the next phase
- Documentation must be updated synchronously, "documentation pending" state is not allowed

**Prohibited Behaviors List**:

| ID | Prohibited Behavior | Correct Practice |
|----|---------------------|------------------|
| 1 | Starting implementation without design document | Must complete design document before coding |
| 2 | Silently expanding scope | Stop immediately when detected, update documentation first |
| 3 | Claiming completion with "documentation pending" | Documentation must be completed synchronously, not retroactively |
| 4 | Putting multiple Stage core unknowns in one Stage | Each Stage only validates a small set of clear hypotheses |
| 5 | Relying on "word of mouth" to run tests | Tests must be reproducible via Task entry point |
| 6 | Writing scripts with hidden platform assumptions | Environment assumptions must be explicitly documented |
| 7 | Introducing broad interfaces before understanding runtime constraints | Validate constraints first, then design interfaces |
| 8 | Prematurely putting expensive checks in default edit loop | Expensive checks should be explicitly triggered, not default behavior |
| 9 | Managing technical debt as tacit knowledge | All known gaps must be explicitly recorded in the ledger |

### 4. Explicit Knowledge Management

**Principle Description**: Technical debt must be visible, not managed as tacit knowledge; ADRs must record "impact on subsequent Stages"; new Agents can onboard using documentation alone.

**Practice Points**:

- All technical debt must be recorded in the ledger
- ADR (Architecture Decision Records) must be complete
- Documentation must be sufficient for new Agents to understand project state

**Documentation Update Obligations**:

| Document | Update Content | Timing |
|----------|---------------|--------|
| `stage-N.md` | Implementation differences, acceptance criteria changes | Stage completion |
| `stage-N-review-log.md` | Findings, adoption/rejection reasons | Review completion |
| `08-autonomous-decisions.md` | ADR, assumption deviations | Decision occurrence |
| `12-technical-debt.md` | New/resolved technical debt | Stage completion |
| `11-next-steps.md` | Progress, next step entry conditions | Stage completion |
| `CHANGELOG.md` | This Stage's change summary | Stage completion |

### 5. Multi-Model Cross-Validation

**Principle Description**: Main development model + independent review model + rule checking. Approximately 50% of findings are false positives, verify each independently.

**Practice Points**:

- Use multiple models for Review
- First round is open, no dimensions/hints provided
- Independently verify each finding

**Verification Priority**:

```
Authoritative Sources > Code Verification > Model Inquiry
```

**Verification Methods**:

| Method | Description | Applicable Scenarios |
|--------|-------------|---------------------|
| Authoritative Sources | Consult official documentation, specifications, best practices | Issues involving standards, specifications |
| Code Verification | Verify through code execution, testing | Reproducible issues |
| Model Inquiry | Request more explanation from the review model | Need further clarification |

### 6. Hook Notification Mechanism

**Principle Description**: Automatic notification when human intervention is needed, supporting multiple channels, tiered notifications.

**Practice Points**:

- Configure notification channels (WeChat Work, Email, Bark, Telegram, Webhook)
- Tiered notifications by priority
- P0 level blocks Agent waiting for human intervention

**Notification Tiers**:

| Level | Blocking Behavior | Default Channels | Examples |
|-------|------------------|------------------|----------|
| P0 | Agent pauses, waits for human intervention | All channels | Consecutive failures, hypothesis falsified, Roadmap changes |
| P1 | Agent continues, suggests prompt handling | Primary channels | Model disagreement, tech debt exceeds threshold |
| P2 | Non-blocking, information sync | Instant channels | Stage completion, new ADR |
| P3 | Non-blocking, periodic summary | Batch channels | Daily reports, weekly reports |

---

## Quality Standards

### Code Quality Standards

| Metric | Target Value | Minimum Value | Verification Method |
|--------|--------------|---------------|---------------------|
| Unit Test Coverage | >= 80% | >= 20% | CI report |
| E2E Tests | At least 2 high-signal paths | - | Tests pass |
| Code Review | 100% code reviewed | - | Review records |
| Static Analysis | No Critical/High issues | - | CI report |

### Documentation Quality Standards

| Document Type | Quality Standards |
|---------------|-------------------|
| Stage Document | Clear goals, explicit non-goals, testable acceptance criteria |
| ADR | "Impact on subsequent Stages" cannot be empty |
| Technical Debt Ledger | Clear priority, source, suggested landing Stage |
| Handoff | Clear current progress, blocking risks, next actions |

### Test Quality Standards

```
- All tests must be reproducible via Task entry point
- E2E tests must run in real environment (not mock)
- New features must have corresponding test cases
- Bug fixes must have regression tests
```

---

## Decision Principles

### Architecture Decision Principles

1. **Simplicity First**: Choose the simplest solution that meets requirements
2. **Evolutionary Design**: Don't abstract prematurely, wait for requirements to become clear
3. **Rollbackable**: Every decision must consider failure rollback plan
4. **Explicit over Implicit**: Explicit declarations over implicit conventions

### Technology Selection Principles

1. **Mature and Stable**: Prefer mature and stable technical solutions
2. **Team Familiarity**: Prefer technology stacks the team is familiar with
3. **Complete Ecosystem**: Prefer technologies with complete ecosystems
4. **Maintainability**: Consider long-term maintenance costs

### Trade-off Principles

```
When weighing the following dimensions:

1. Functionality vs Stability → Prefer stability
2. Performance vs Maintainability → Prefer maintainability
3. Perfection vs Deliverable → Prefer deliverable (record technical debt)
4. Generic vs Specific → Prefer specific (avoid premature abstraction)
```

---

## Good/Bad Case Examples

### Good Case 1: Stage Boundary Control

**Scenario**: Need to implement user authentication functionality

**Good**:

```
Stage 1: User Registration and Login
- Goal: Implement basic registration and login functionality
- Non-goals: Third-party login, multi-factor authentication
- Workload: 1 day

Stage 2: Token Management
- Goal: Implement JWT Token generation and validation
- Non-goals: Token refresh mechanism
- Workload: 0.5 day

Stage 3: Third-party Login
- Goal: Support GitHub login
- Non-goals: Other third-party platforms
- Workload: 1 day
```

**Bad**:

```
Stage 1: Complete User Authentication System
- Goal: Registration, login, third-party login, multi-factor authentication, token management
- Non-goals: None
- Problem: Scope too large, contains multiple core unknowns
```

### Good Case 2: Technical Debt Management

**Scenario**: Discovered areas in code that need optimization

**Good**:

```
TD-01: Missing error retry mechanism
- Priority: Feature Degradation / Module-level
- Source: Stage 2 review deferred
- Original Description: "Suggested adding error retry, but current Stage scope doesn't include it"
- Source File: src/client.rs:45
- Suggested Landing Stage: Stage 4

Action: Record in technical debt ledger, handle uniformly in Stage 4
```

**Bad**:

```
Issue: Discovered missing error retry mechanism
Action: Keep in mind, will handle later
Problem: Not explicitly recorded, likely to be forgotten
```

### Good Case 3: Review Verification

**Scenario**: Review finds "async IO should be used here"

**Good**:

```
Finding: Suggest using async IO to improve performance

Verification Process:
1. Consult authoritative sources: Rust official documentation indicates current scenario doesn't need async
2. Code verification: Run benchmark tests, sync and async performance difference < 5%
3. Conclusion: False positive, current implementation meets performance requirements

Record: Document rejection reason in review-log.md
```

**Bad**:

```
Finding: Suggest using async IO to improve performance

Verification Process:
1. Model says it's needed, so change it
2. No verification of actual performance difference
3. Problem: May introduce unnecessary complexity
```

### Good Case 4: Synchronous Documentation Update

**Scenario**: During implementation, discovered design needs adjustment

**Good**:

```
1. Immediately stop coding
2. Update design document in stage-N.md
3. Record reason for change and impact
4. Continue coding
5. When Stage completes, all documentation is already synchronized
```

**Bad**:

```
1. Continue coding, design has changed
2. Think "will update documentation later"
3. Claim completion when Stage ends
4. Problem: Documentation inconsistent with code, difficult future maintenance
```

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Note**: This principles document is the core guiding document for the RDD project. Any changes require recording the decision process through ADR.
