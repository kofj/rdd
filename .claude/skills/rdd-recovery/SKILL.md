---
name: rdd-recovery
description: Recover an RDD project from failures, blockers, and interrupted stages
---

# RDD Recovery Skill

> **Purpose**: Recover from failures, blockers, and interrupted stages.

## Overview

This skill provides procedures for recovering from various failure scenarios in RDD. It handles interrupted sessions, blocked stages, failed gates, and other exceptional situations.

**When to Use:**
- Session interrupted during stage execution
- Stage fails to complete
- Gate check fails multiple times
- Blocked by external dependency
- Recovering from errors

**Command:** `/rdd-recovery <scenario>`

---

## Recovery Scenarios

| Scenario | Description |
|----------|-------------|
| `interrupted` | Session ended during stage execution |
| `blocked` | Stage blocked by external dependency |
| `gate-failed` | Gate check failed multiple times |
| `rollback` | Need to rollback to previous stage |
| `corrupted` | Documentation or state corrupted |

---

## Recovery Workflow

```
┌─────────────────┐
│  Detect Failure │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Assess Situation│
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Can Auto-Recover│─────│   Auto Recovery │
│      ?          │ No  │                 │
└────────┬────────┘     └────────┬────────┘
         │ Yes                   │
         │                       ▼
         │              ┌─────────────────┐
         │              │ Escalate to     │
         │              │ Human           │
         │              └─────────────────┘
         ▼
┌─────────────────┐
│ Resume from     │
│ Checkpoint      │
└─────────────────┘
```

---

## Interrupted Session Recovery

### Detection

Session was interrupted if:
- `docs/handoff/handoff-latest.md` exists with recent timestamp
- Stage status is "In Progress" but no activity for extended period
- Last gate progress is recorded but stage not complete

### Recovery Steps

1. **Load Context**

   Read these files in order:
   ```
   1. docs/handoff/handoff-latest.md    # Recent context
   2. docs/stages/stage-roadmap.md      # Overall status
   3. docs/stages/stage-N.md            # Current stage
   4. docs/08-autonomous-decisions.md   # Recent decisions
   5. docs/12-technical-debt.md         # Known issues
   ```

2. **Identify Last Checkpoint**

   From handoff document:
   - Current gate
   - Last completed action
   - Progress percentage
   - Blockers (if any)

3. **Resume from Checkpoint**

   ```
   If at Gate 0: Start from Stage Startup
   If at Gate 1: Resume from Design Document
   If at Gate 2: Resume from Design Review
   If at Gate 3: Resume from Implementation
   If at Gate 4: Resume from Code Review
   If at Gate 5: Resume from Completion Check
   ```

4. **Verify State**

   - Check if files mentioned in handoff still exist
   - Verify tests still pass
   - Confirm no external changes broke progress

5. **Update Progress**

   Log recovery in `docs/11-next-steps.md`:
   ```markdown
   ### Recovery Log

   **Time**: YYYY-MM-DD HH:MM
   **Action**: Session recovered from interruption
   **Last Gate**: Gate N
   **Resuming from**: [Action]
   ```

### Handoff Document Structure

The handoff document should contain:
- Current progress percentage
- Current gate
- Last completed action
- Blockers and risks
- Next single action
- Degradation strategy

If handoff document is missing or incomplete, use `rdd-knowledge context` to rebuild context.

---

## Blocked Stage Recovery

### Detection

Stage is blocked if:
- External dependency is unavailable
- Roadmap change is required
- Human decision is needed
- Resource is not available

### Recovery Steps

1. **Identify Blocker**

   Check `docs/11-next-steps.md` for documented blockers.

2. **Assess Blocker Type**

   | Blocker Type | Auto-Recoverable | Action |
   |--------------|------------------|--------|
   | External API | No | Wait or skip |
   | Missing info | Sometimes | Use defaults |
   | Design flaw | No | Redesign |
   | Human decision | No | Notify and wait |
   | Resource limit | Sometimes | Degrade scope |

3. **Attempt Auto-Recovery**

   If blocker might be resolved:
   ```
   - Wait specified time
   - Retry the blocked operation
   - If still blocked after max retries, escalate
   ```

4. **Escalate if Needed**

   If auto-recovery fails:
   ```
   - Create detailed handoff document
   - Trigger Hook notification (P1)
   - Document blocker clearly
   - Provide options for human
   ```

5. **Degrade if Possible**

   If scope can be reduced:
   ```
   - Document what's being reduced
   - Record as tech debt
   - Continue with reduced scope
   - Update stage goals
   ```

### Blocker Resolution Template

```markdown
## Blocker: [Title]

**Status**: Active / Resolved
**Priority**: P0 / P1 / P2
**Type**: External / Design / Decision / Resource
**Stage**: Stage N
**Gate**: Gate X

### Description
[What is blocking progress]

### Impact
[What is affected]

### Resolution Options
1. [Option 1]
2. [Option 2]
3. [Option 3]

### Recommended Action
[Recommended resolution]

### Resolution
[How it was resolved, if applicable]

**Resolved Date**: YYYY-MM-DD
**Resolution Method**: [How resolved]
```

---

## Gate Failed Recovery

### Detection

Gate check failed if:
- Required files are missing
- Tests are failing
- Review found critical issues
- Verification failed

### Recovery Steps

1. **Identify Failed Gate**

   | Gate | Common Failures |
   |------|-----------------|
   | Gate 0 | Missing roadmap, unmet dependencies |
   | Gate 1 | Missing/incomplete design doc |
   | Gate 2 | Design issues, scope creep |
   | Gate 3 | Tests failing, coverage low |
   | Gate 4 | Code issues, review findings |
   | Gate 5 | Missing docs, fresh-agent-check failed |

2. **Analyze Failure**

   ```
   - What specific check failed?
   - What is the error message?
   - Can it be fixed automatically?
   ```

3. **Fix or Degrade**

   **Fix**: If issue can be resolved:
   - Make the fix
   - Re-run gate check
   - Document in review log

   **Degrade**: If issue requires scope change:
   - Document what can't be fixed
   - Record as tech debt
   - Update design doc
   - Re-run gate check

4. **Max Retry Handling**

   After max retries (3 for tests, 2 for gates):
   ```
   - Stop current work
   - Create handoff document
   - Notify via Hook (P1)
   - Wait for human intervention
   ```

### Gate Retry Limits

| Check Type | Max Retries | After Max |
|------------|-------------|-----------|
| Unit test | 3 | Degrade scope |
| Gate check | 2 | Escalate |
| Implementation | 2 | Try alternative |
| Full stage | 1 | Rollback |

---

## Rollback Recovery

### When to Rollback

- Stage failed after max retries
- Critical design flaw discovered
- Dependencies changed
- Human requested rollback

### Rollback Procedure

1. **Identify Rollback Target**

   From stage document:
   ```markdown
   ## Rollback Plan
   Version: vX.Y.Z
   Commit: abc123
   Procedure: [Steps]
   ```

2. **Execute Rollback**

   ```bash
   # If using git
   git checkout [rollback-commit]

   # Or follow documented procedure
   ```

3. **Update Documentation**

   ```markdown
   ## Rollback Log

   **Time**: YYYY-MM-DD HH:MM
   **From**: Stage N (Gate X)
   **To**: Stage M (Complete)
   **Reason**: [Why rollback was needed]
   **Data Migration**: [If applicable]
   ```

4. **Update Roadmap**

   Mark stage as "Rolled back" in roadmap.

5. **Create Tech Debt**

   If rollback leaves unresolved issues:
   ```
   Create tech debt entry for:
   - Root cause of failure
   - What needs to be fixed before retry
   ```

6. **Notify**

   Trigger Hook notification (P1):
   ```
   Stage N rolled back to Stage M
   Reason: [Reason]
   Next steps: [What needs to happen]
   ```

---

## Corrupted State Recovery

### Detection

State is corrupted if:
- Required files are missing
- Files contain invalid content
- Inconsistent state between files
- Cache is out of sync

### Recovery Steps

1. **Assess Corruption**

   Check which files are affected:
   ```
   - Roadmap file
   - Stage documents
   - ADRs
   - Tech debt ledger
   - Handoff documents
   ```

2. **Restore from Backup**

   If backups exist:
   ```bash
   # Restore from git
   git checkout HEAD -- [file]

   # Or restore from backup directory
   cp .rdd/cache/backup/[file] [destination]
   ```

3. **Rebuild from Scratch**

   If no backup:
   ```
   - Use templates to recreate files
   - Reconstruct from git history
   - Document what was lost
   ```

4. **Verify Integrity**

   After restoration:
   ```
   - All required files exist
   - Files are valid format
   - Cross-references are correct
   - Status is consistent
   ```

5. **Run fresh-agent-check**

   ```
   /rdd-fresh-check
   ```

### File Recovery Templates

If you need to recreate files from scratch, use templates from:
- `rdd-init` skill for structure
- `rdd-templates` skill for content

---

## Recovery Checklist

After any recovery:

```markdown
## Recovery Checklist

### Context
[ ] Read handoff document
[ ] Read roadmap
[ ] Read current stage document
[ ] Read recent ADRs
[ ] Read tech debt ledger

### State
[ ] Verified current gate
[ ] Verified test status
[ ] Verified file integrity
[ ] Verified documentation sync

### Actions
[ ] Resumed from correct checkpoint
[ ] Logged recovery in next-steps
[ ] Updated handoff document
[ ] Notified if needed

### Prevention
[ ] Identified what caused interruption
[ ] Documented how to prevent recurrence
[ ] Updated degradation strategy if needed
```

---

## Integration with Other Skills

| Skill | When to Use |
|-------|-------------|
| `rdd-knowledge` | For handoff generation and context loading |
| `rdd-stage-auto` | For resuming stage execution |
| `rdd-diagnosis` | For diagnosing root cause of failures |

---

## Reference

For related information, see:
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-loop/SKILL.md` - Loop control and state machine
- `.claude/skills/rdd-knowledge/SKILL.md` - Handoff generation
