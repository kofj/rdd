# Stage N: [Title]

> Stage design document template - each Stage is verifiable, rollbackable, and handoffable

---

## Status

- [ ] Planning
- [ ] In Progress
- [ ] Complete

> Select current status, check when complete

---

## Goals

> What this stage solves only (control scope, define boundaries)

**One-liner**: [Concise goal description]

**Detailed Description**:

[Describe the problems to solve and goals to achieve in this Stage. Note:
1. Each Stage only validates a small set of clear hypotheses
2. Control scope, accept stage compromises
3. Goals must be verifiable and measurable]

**Example**:

> This stage's goal is to implement user authentication functionality, including login, registration, and logout operations. Does not involve permission management, third-party login, and other advanced features.

---

## Non-Goals

> What this stage explicitly does not do (prevent scope creep)

- [Non-goal 1]: [Description and reason]
- [Non-goal 2]: [Description and reason]
- [Non-goal 3]: [Description and reason]

**Example**:

- **Permission Management System**: Handled in Stage 3, this stage only needs to distinguish "logged in/not logged in"
- **Third-party Login**: Requires additional API integration work, deferred to later Stage
- **Password Recovery**: Depends on email service configuration, not in this Stage

---

## Core Hypotheses

> Each Stage only validates a small set of clear hypotheses

### Hypothesis A: [Hypothesis Name]

- **Content**: [Describe hypothesis]
- **Verification**: [How to verify this hypothesis]
- **Risk**: [Impact if hypothesis doesn't hold]

### Hypothesis B: [Hypothesis Name]

- **Content**: [Describe hypothesis]
- **Verification**: [How to verify this hypothesis]
- **Risk**: [Impact if hypothesis doesn't hold]

**Example**:

### Hypothesis A: Users accept email registration

- **Content**: Users are willing to use email as the only registration method
- **Verification**: Verify registration flow through E2E testing
- **Risk**: If users don't accept, need to add phone number registration

---

## Acceptance Criteria

> Must be testable and verifiable

- [ ] [Acceptance Criteria A]: [Specific description]
- [ ] [Acceptance Criteria B]: [Specific description]
- [ ] [Acceptance Criteria C]: [Specific description]
- [ ] Unit test coverage >= 20%
- [ ] E2E tests passed (at least 2 high-signal paths)
- [ ] No undocumented manual steps
- [ ] Implementation matches design (differences documented)

**Example**:

- [ ] User can complete registration flow via email
- [ ] User can login via email and password
- [ ] User can logout normally
- [ ] Login state persists after page refresh
- [ ] Password stored in encrypted form
- [ ] All interfaces have corresponding unit tests

---

## Rollback Plan

> Which version to fall back to if failed

**Rollback Strategy**: [Describe rollback plan]

**Rollback Steps**:

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Example**:

Rollback to code version at Stage N-1 completion (commit: `abc123`):

1. `git revert HEAD~N` to rollback code
2. Execute database migration rollback script
3. Restart service and verify

---

## Known Limitations

> Document known limitations in this Stage, these should be tracked in tech debt ledger

- **Limitation A**: [Description] - Plan to resolve in [Stage X]
- **Limitation B**: [Description] - Plan to resolve in [Stage X]
- **Limitation C**: [Description] - Accept as long-term limitation

**Example**:

- **Simple password strength requirement**: Only requires 6+ characters - Plan to strengthen in Stage 4
- **No login failure limit**: Brute force risk exists - Plan to resolve in Stage 3
- **Fixed session expiration**: 24 hours fixed - Accept as long-term limitation

---

## Impact on Subsequent Stages

> How this Stage's decisions and implementation affect subsequent Stages (required, cannot be empty)

- **Impact A**: [Describe impact and recommendations]
- **Impact B**: [Describe impact and recommendations]

**Example**:

- **Authentication interface design**: Subsequent Stages need to add permission checks on top of this, recommend keeping interface simple
- **Password encryption method**: Using bcrypt, if need to change later need to provide migration plan
- **Session management**: Memory-based, need to replace with Redis for distributed deployment later

---

## Implementation vs Design Differences

> [Fill in after implementation] Document differences between implementation and design document

**Fill in timing**: After Stage completion, during Gate 5 check

### Difference Record

| Design Content | Actual Implementation | Difference Reason | Need Doc Update |
|----------------|----------------------|-------------------|-----------------|
| [Design A] | [Implementation A] | [Reason] | [Yes/No] |
| [Design B] | [Implementation B] | [Reason] | [Yes/No] |

**Example**:

| Design Content | Actual Implementation | Difference Reason | Need Doc Update |
|----------------|----------------------|-------------------|-----------------|
| Use JWT auth | Use Session auth | JWT requires extra config, simpler initial implementation | Yes |
| Password uses SHA256 | Use bcrypt | SHA256 not secure enough | No (design doc needs update) |

---

## Review Record

> See detailed review log: [stage-N-review-log.md](./stage-N-review-log.md)

### Review Summary

- **Design Review Date**: YYYY-MM-DD
- **Code Review Date**: YYYY-MM-DD
- **Participating Models**: [Model list]
- **Total Findings**: N
- **Adopted**: N
- **Not Adopted**: N
- **Status**: ✅ Passed / 🔄 Pending

---

## Retrospective

> [Optional] Retrospective summary after Stage completion

### What Went Well

- [Point 1]
- [Point 2]

### What Could Be Improved

- [Point 1]
- [Point 2]

### Lessons Learned

- [Lesson 1]
- [Lesson 2]

---

## Appendix

### Related Documents

- [Stage Roadmap](./stage-roadmap.md)
- [ADR Log](../08-autonomous-decisions.md)
- [Tech Debt Ledger](../12-technical-debt.md)
- [Next Steps](../11-next-steps.md)

### Notes

1. **Document Sync Updates**: Update immediately when design deviation found, don't wait for Stage end
2. **Substantive Content**: Must have specific content, cannot just write "TBD"
3. **Version Refresh**: All "current status" fields sync refresh
4. **Prohibited Actions**: Refer to 9 prohibited actions in RDD core principles

### Gate Checklist

**Gate 1: Design Document Check**
- [ ] Goals are clear and specific
- [ ] Non-goals are explicitly stated
- [ ] Acceptance criteria are testable
- [ ] Rollback plan exists

**Gate 2: Solution Review**
- [ ] Multi-model review triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

**Gate 3: Implementation & Testing**
- [ ] E2E tests passed
- [ ] Unit test coverage >= 20%
- [ ] Clean environment verification passed

**Gate 4: Code Review**
- [ ] All blocking findings resolved
- [ ] All acceptance criteria met

**Gate 5: Completion Check**
- [ ] 6 documents updated
- [ ] fresh-agent-check passed
