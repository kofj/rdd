# RDD Loop Skill

> **Purpose**: Autonomous stage execution loop with monitoring, progression, exception handling, and human checkpoint notifications.

## Overview

The RDD Loop provides the operational framework for autonomous stage-by-stage execution. It defines how to monitor progress, advance through stages, handle failures gracefully, and notify humans when intervention is required.

---

## State Monitoring

### Progress Tracking

Monitor stage progress through the following indicators:

#### Gate Status
Track which gate the current stage has passed:

| Gate | Status Indicator | Progress |
|------|------------------|----------|
| Gate 0 | Stage Startup | 0% |
| Gate 1 | Design Doc Created | 15% |
| Gate 2 | Design Review Passed | 30% |
| Gate 3 | Implementation Complete | 60% |
| Gate 4 | Code Review Passed | 80% |
| Gate 5 | Completion Gate Passed | 100% |

#### File-Based State Tracking
Use the roadmap file as the source of truth:

```
docs/stages/stage-roadmap.md
```

Key fields to monitor:
- `Current Stage`: Which stage is active
- `Status`: Planning / In Progress / Complete
- `Progress Percentage`: 0-100%
- `Current Gate`: Gate 0-5

#### Heartbeat Indicators

Log progress to `docs/next-steps.md` with timestamps:
```markdown
## Progress Log

### YYYY-MM-DD HH:MM
- **Gate**: Gate N
- **Action**: [What was done]
- **Status**: [Success/In Progress/Blocked]
- **Next**: [What happens next]
```

### Health Checks

Perform periodic health checks during execution:

```markdown
### Health Check Protocol

Every 15 minutes of continuous work:
1. Verify no scope creep has occurred
2. Check all tests still pass
3. Confirm documentation is synchronized
4. Validate against roadmap goals

If any check fails:
- Stop current work
- Document the deviation
- Determine if human notification needed (P1/P2)
- Fix or escalate before continuing
```

### Stale Detection

Detect and handle stalled progress:

| No Progress Duration | Action |
|---------------------|--------|
| 15 minutes | Log warning, attempt alternative approach |
| 30 minutes | Trigger first degradation strategy |
| 45 minutes | Trigger second degradation strategy |
| 60 minutes | Escalate to human via Hook (P0) |

---

## Stage Progression

### Automatic Stage Flow

```
[Previous Stage Complete]
        |
        v
[GATE 0] Stage Startup Check
        |
        v
[Load Context] -- Read roadmap, ADRs, tech debt
        |
        v
[GATE 1] Design Document
        |
        v
[GATE 2] Design Review
        |
        v
[GATE 3] Implementation & Testing
        |
        v
[GATE 4] Code Review
        |
        v
[GATE 5] Completion Check
        |
        v
[Update Documentation]
        |
        v
[Generate Handoff]
        |
        v
[Next Stage Ready]
```

### Stage Transition Criteria

Before advancing to the next stage, verify ALL conditions:

#### Mandatory Checks
- [ ] All acceptance criteria met
- [ ] All tests passing (unit + E2E)
- [ ] Real environment verification complete
- [ ] Clean environment verification complete
- [ ] Design document updated with implementation notes
- [ ] Review log created
- [ ] ADR recorded with "impact on subsequent stages"
- [ ] Technical debt ledger updated
- [ ] fresh-agent-check passed

#### Automated Verification Commands

Run these checks before stage transition:

```bash
# Verify tests pass
task test

# Verify documentation exists
ls docs/stages/stage-N.md
ls docs/stages/stage-N-review-log.md

# Verify fresh agent can take over
# (Read handoff document and verify all context is present)
```

### Progression Sequence

When a stage completes, automatically:

1. **Mark Complete**: Update roadmap status to "Complete"
2. **Record Completion**: Add changelog entry
3. **Identify Next Stage**: Find next stage in roadmap with satisfied dependencies
4. **Initialize Next Stage**: Create stage document from template
5. **Begin Gate 0**: Start the new stage

---

## Exception Handling

### Exception Categories

| Category | Severity | Example | Response |
|----------|----------|---------|----------|
| Recoverable | Low | Test failure, lint error | Auto-fix and retry |
| Degradable | Medium | Feature too complex for one stage | Reduce scope, continue |
| Blockable | High | Missing dependency, design flaw | Stop, escalate to human |
| Fatal | Critical | Data loss, security breach | Stop immediately, P0 notification |

### Recovery Strategies

#### Strategy 1: Auto-Retry (Recoverable)
```
1. Log the error with context
2. Analyze root cause
3. Apply fix
4. Re-run affected tests
5. If success, continue; if 3 failures, escalate to Strategy 2
```

#### Strategy 2: Degradation (Degradable)
```
1. Identify minimum viable scope
2. Document what was reduced
3. Record as technical debt (TD)
4. Continue with reduced scope
5. Add follow-up task to backlog
```

#### Strategy 3: Rollback (Blockable)
```
1. Stop all work
2. Document blocker clearly
3. Attempt rollback to last known good state
4. Create handoff document
5. Notify human via Hook (P0/P1)
```

#### Strategy 4: Emergency Stop (Fatal)
```
1. Stop all work immediately
2. Preserve current state (do not rollback)
3. Document everything
4. Notify human via Hook (P0) immediately
5. Wait for human intervention
```

### Error Logging

Record all exceptions in `docs/stages/stage-N-review-log.md`:

```markdown
## Exception Log

### Exception N: [Title]
**Time**: YYYY-MM-DD HH:MM
**Category**: [Recoverable/Degradable/Blockable/Fatal]
**Context**: [What was being attempted]
**Error**: [Error message or description]
**Root Cause**: [Analysis of why it happened]
**Resolution**: [How it was resolved or "Escalated to human"]
**Hook Sent**: [Yes/No - if yes, include level]
```

### Retry Limits

Maximum retry attempts before escalation:

| Operation | Max Retries | Escalation Action |
|-----------|-------------|-------------------|
| Single test | 3 | Move to Strategy 2 (Degradation) |
| Gate check | 2 | Notify human (P1) |
| Implementation approach | 2 | Try alternative approach |
| Full stage | 1 | Rollback and notify human (P0) |

---

## Human Checkpoint Handling

### When to Notify Humans

Trigger Hook notifications at these checkpoints:

#### Automatic P0 (Urgent) Notifications
- Fatal exception occurred
- Stage failed after all retry attempts
- Security vulnerability detected
- Data corruption risk identified
- Roadmap change required

#### Automatic P1 (Important) Notifications
- Blockable exception with no automated recovery
- Scope change required
- Technical debt priority exceeds threshold
- Dependency on external decision needed

#### Automatic P2 (Info) Notifications
- Stage completed successfully
- Significant ADR made
- Technical debt introduced

#### Automatic P3 (Report) Notifications
- Daily progress summary
- Milestone reached

### Notification Content

Hook notifications must include:

```markdown
## Hook Notification

**Level**: [P0/P1/P2/P3]
**Type**: [Checkpoint Type]
**Stage**: Stage N
**Gate**: Gate X
**Summary**: [One-line summary]

### Details
[Detailed description of the situation]

### Action Required
[What the human needs to do, if anything]

### Context
- **File**: [Relevant file path]
- **Related ADR**: [If applicable]
- **Related TD**: [If applicable]

### Recovery Options
1. [Option 1]
2. [Option 2]
3. [Option 3]

### Time Sensitivity
[How quickly this needs attention]
```

### Checkpoint Protocol

At each checkpoint, perform:

```markdown
### Checkpoint Protocol

1. Assess current state
   - Gate status
   - Test results
   - Documentation completeness
   - Any errors or warnings

2. Determine notification level
   - P0: Blocking, needs immediate attention
   - P1: Important, needs attention within hours
   - P2: Informational, review when convenient
   - P3: Report, for records only

3. If P0 or P1:
   - Stop current work
   - Generate detailed notification
   - Send via configured Hook channel
   - Wait for response (P0) or continue with caution (P1)

4. If P2 or P3:
   - Send notification
   - Continue autonomous operation
```

### Human Response Integration

When human provides input:

```markdown
### Human Response Handling

1. **Acknowledge receipt**
   - Log the response time
   - Record the decision

2. **Integrate decision**
   - If approval: Continue with proposed action
   - If rejection: Document and try alternative
   - If new direction: Update roadmap first (P0 notification)

3. **Document decision**
   - Add to ADR if significant
   - Update handoff notes
   - Log in stage review document

4. **Resume execution**
   - Pick up from checkpoint
   - Apply new context
   - Continue autonomous operation
```

---

## Autonomous Loop Control

### Loop State Machine

```
        +----------------+
        |     IDLE       |
        +-------+--------+
                |
                v
        +-------+--------+
        |   INITIALIZING |
        +-------+--------+
                |
                v
        +-------+--------+
        |    RUNNING     |<----+
        +-------+--------+     |
                |              |
                v              |
        +-------+--------+     |
        |    PAUSED      |     |
        +-------+--------+     |
                |              |
                v              |
        +-------+--------+     |
        |   RECOVERING   |-----+
        +-------+--------+
                |
                v
        +-------+--------+
        |   ESCALATED    |
        +-------+--------+
                |
                v
        +-------+--------+
        |   COMPLETE     |
        +----------------+
```

### State Transitions

| From | To | Trigger |
|------|-----|---------|
| IDLE | INITIALIZING | Start command received |
| INITIALIZING | RUNNING | Context loaded successfully |
| RUNNING | PAUSED | Checkpoint reached or error |
| PAUSED | RECOVERING | Retry attempted |
| RECOVERING | RUNNING | Recovery successful |
| RECOVERING | ESCALATED | Max retries exceeded |
| ESCALATED | RUNNING | Human response received |
| RUNNING | COMPLETE | Stage passed Gate 5 |

### Loop Commands

Commands to control the autonomous loop:

| Command | Description |
|---------|-------------|
| `start` | Begin autonomous execution |
| `pause` | Pause at next checkpoint |
| `resume` | Continue from pause |
| `status` | Report current state |
| `escalate` | Force escalation to human |
| `skip` | Skip current step (with documentation) |

---

## Integration with RDD Core

This skill integrates with rdd-core.md as follows:

1. **Gates**: Implements the gate checking mechanisms from RDD Core
2. **Templates**: Uses document templates from rdd-templates.md
3. **Anti-Patterns**: Enforces the 9 prohibited behaviors
4. **Notifications**: Uses Hook mechanism defined in RDD Core

### Command Integration

| RDD Core Command | Loop Skill Action |
|------------------|-------------------|
| `/rdd-stage-auto` | Execute full loop for current stage |
| `/rdd-review-auto` | Pause at Gate 2 or Gate 4 for review |
| `/rdd-diagnosis` | Enter ESCALATED state for diagnosis |

---

## Reference

For related information, see:
- `/data/works/play/sbd/.claude/skills/rdd-core.md` - Core RDD concepts and gates
- `/data/works/play/sbd/.claude/skills/rdd-templates.md` - Document templates
- `/data/works/play/sbd/prompt.md` - Full RDD specification
