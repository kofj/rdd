# RDD Fresh Check Skill

> **Purpose**: Verify that a fresh agent can take over the project from documentation alone.

## Overview

The fresh-agent-check is a critical quality gate that ensures project documentation is complete enough for a new agent to continue work without requiring tacit knowledge from previous sessions.

**When to Use:**
- Before completing a stage (Gate 5)
- After significant documentation changes
- When setting up project handoff
- During quality audits

**Command:** `/rdd-fresh-check [--verbose]`

---

## Why Fresh Agent Check Matters

### The Problem

Without fresh-agent-check, projects accumulate:
- Undocumented decisions
- Missing context
- Assumptions about knowledge
- Broken cross-references
- Stale documentation

### The Solution

Fresh-agent-check simulates a new agent reading only the documentation to verify:
- All context is explicit
- All decisions are recorded
- All dependencies are documented
- All steps are reproducible

---

## Fresh Agent Check Process

```
┌─────────────────────────────────────────────────────────────┐
│                  FRESH AGENT CHECK                          │
├─────────────────────────────────────────────────────────────┤
│  1. Can I understand what this project does?                │
│     Read: docs/01-charter.md                                │
│     Question: What is the vision and goals?                 │
│                                                             │
│  2. Can I understand where we are?                          │
│     Read: docs/stages/stage-roadmap.md                      │
│     Question: What is the current stage and progress?       │
│                                                             │
│  3. Can I understand what to do next?                       │
│     Read: docs/11-next-steps.md                             │
│     Question: What is the immediate next action?            │
│                                                             │
│  4. Can I understand past decisions?                        │
│     Read: docs/08-autonomous-decisions.md                   │
│     Question: Why were key decisions made?                  │
│                                                             │
│  5. Can I understand known issues?                          │
│     Read: docs/12-technical-debt.md                         │
│     Question: What needs to be fixed?                       │
│                                                             │
│  6. Can I understand current stage details?                 │
│     Read: docs/stages/stage-N.md                            │
│     Question: What are we building and why?                 │
│                                                             │
│  7. Can I take over without asking questions?               │
│     Question: Is there any missing context?                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Check Questions

### Project Understanding Check

After reading `docs/01-charter.md`:

```markdown
## Project Understanding Checklist

[ ] I can state the project vision in one sentence
[ ] I can list the primary goals (3-5)
[ ] I know what is explicitly out of scope
[ ] I understand the success criteria
[ ] I know the key stakeholders

If any answer is "No": Charter is incomplete
```

### Progress Understanding Check

After reading `docs/stages/stage-roadmap.md`:

```markdown
## Progress Understanding Checklist

[ ] I know which stage is currently active
[ ] I know the overall progress percentage
[ ] I understand the stage dependencies
[ ] I know what stages are complete
[ ] I know what stages are upcoming

If any answer is "No": Roadmap is incomplete
```

### Next Action Check

After reading `docs/11-next-steps.md`:

```markdown
## Next Action Checklist

[ ] I know exactly what to do next
[ ] The next action is specific and actionable
[ ] I know how to execute the next action
[ ] I understand the expected outcome
[ ] I know about any blockers

If any answer is "No": Next steps are incomplete
```

### Decision History Check

After reading `docs/08-autonomous-decisions.md`:

```markdown
## Decision History Checklist

[ ] Key decisions are documented
[ ] Each decision has background context
[ ] Each decision has rationale
[ ] Each decision has impact on subsequent stages
[ ] Alternatives considered are documented

If any answer is "No": ADRs are incomplete
```

### Known Issues Check

After reading `docs/12-technical-debt.md`:

```markdown
## Known Issues Checklist

[ ] All known issues are listed
[ ] Each issue has priority
[ ] Each issue has resolution plan
[ ] Each issue has source stage
[ ] Critical issues are identified

If any answer is "No": Tech debt ledger is incomplete
```

### Current Stage Check

After reading `docs/stages/stage-N.md`:

```markdown
## Current Stage Checklist

[ ] Goals are clear and specific
[ ] Non-goals are explicit
[ ] Hypotheses are testable
[ ] Acceptance criteria are measurable
[ ] Rollback plan is defined
[ ] Implementation notes are current (if in progress)

If any answer is "No": Stage document is incomplete
```

### Context Completeness Check

Final verification:

```markdown
## Context Completeness Checklist

[ ] I can continue work without asking clarifying questions
[ ] I don't need to read code to understand the project
[ ] I don't need historical knowledge from previous sessions
[ ] All technical terms are explained or linked
[ ] All assumptions are documented

If any answer is "No": Context is incomplete
```

---

## Common Issues Found

### Tacit Knowledge

**Symptom**: Documentation refers to things not explained.

**Examples**:
- "As we discussed..."
- "Following the previous approach..."
- "Using the standard pattern..."
- "Like the X module..." (without describing X)

**Fix**: Make implicit knowledge explicit.

### Missing Context

**Symptom**: Decisions or code can't be understood from docs alone.

**Examples**:
- Decision rationale is missing
- Dependencies are not documented
- Configuration is not explained
- External references are not linked

**Fix**: Add the missing context to documentation.

### Stale Documentation

**Symptom**: Documentation doesn't match reality.

**Examples**:
- Status is "In Progress" but stage is complete
- "Next steps" refer to completed work
- Roadmap doesn't reflect actual progress
- Tech debt is resolved but not marked

**Fix**: Update documentation to current state.

### Broken Cross-References

**Symptom**: References to non-existent or wrong documents.

**Examples**:
- "See stage-3.md" but file doesn't exist
- "As decided in ADR-5" but ADR-5 is missing
- "Defined in the roadmap" but not found in roadmap

**Fix**: Fix or remove broken references.

---

## Running the Check

### Manual Check

Read each document in order and answer the check questions:

```
1. Read docs/01-charter.md → Answer Project Understanding questions
2. Read docs/stages/stage-roadmap.md → Answer Progress questions
3. Read docs/11-next-steps.md → Answer Next Action questions
4. Read docs/08-autonomous-decisions.md → Answer Decision History questions
5. Read docs/12-technical-debt.md → Answer Known Issues questions
6. Read docs/stages/stage-N.md → Answer Current Stage questions
7. Answer Context Completeness questions
```

### Automated Check

```bash
# Run automated verification
task rdd:fresh-check

# Or with verbose output
task rdd:fresh-check --verbose
```

### Check Output

```
═══════════════════════════════════════════════════════════════
                   FRESH AGENT CHECK REPORT
═══════════════════════════════════════════════════════════════

Project: [Project Name]
Date: YYYY-MM-DD HH:MM

───────────────────────────────────────────────────────────────
SECTION                           STATUS    ISSUES
───────────────────────────────────────────────────────────────
Project Understanding             ✅ PASS   0
Progress Understanding            ✅ PASS   0
Next Action                       ✅ PASS   0
Decision History                  ⚠️ WARN   2
Known Issues                      ✅ PASS   0
Current Stage                     ✅ PASS   0
Context Completeness              ⚠️ WARN   1
───────────────────────────────────────────────────────────────
OVERALL                           ⚠️ WARN   3 issues

───────────────────────────────────────────────────────────────
ISSUES FOUND
───────────────────────────────────────────────────────────────

1. [Decision History] ADR-3 is missing "Impact on Subsequent Stages"
   File: docs/08-autonomous-decisions.md
   Fix: Add impact section to ADR-3

2. [Decision History] ADR-5 references ADR-2 but ADR-2 doesn't exist
   File: docs/08-autonomous-decisions.md
   Fix: Create ADR-2 or fix reference

3. [Context Completeness] Term "MVP cache layer" used but not explained
   File: docs/stages/stage-2.md
   Fix: Add explanation or link to definition

───────────────────────────────────────────────────────────────
RECOMMENDATION
───────────────────────────────────────────────────────────────
Fix 3 issues before stage completion.
Run fresh-agent-check again after fixes.

═══════════════════════════════════════════════════════════════
```

---

## Pass/Fail Criteria

### Pass

- All sections show ✅ PASS
- No issues found
- OR all issues are Low priority

### Warning

- Some sections show ⚠️ WARN
- Medium priority issues found
- Can proceed but should fix

### Fail

- Any section shows ❌ FAIL
- High priority issues found
- Must fix before stage completion

---

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `rdd-stage-auto` | Run at Gate 5 before completion |
| `rdd-knowledge` | Update documentation based on findings |
| `rdd-diagnosis` | Use for doc diagnosis |

---

## Checklist for Stage Completion

Before completing a stage, run this check:

```markdown
## Fresh Agent Check (Stage Completion)

Before marking stage complete, verify:

[ ] Charter is still accurate
[ ] Roadmap reflects current progress
[ ] Next steps are updated for next stage
[ ] All stage decisions are in ADRs
[ ] All new issues are in tech debt ledger
[ ] Stage document has implementation notes
[ ] No tacit knowledge required to continue

Run: /rdd-fresh-check

If PASS: Stage can be completed
If WARN: Fix issues, then complete stage
If FAIL: Must fix issues before stage completion
```

---

## Reference

For related information, see:
- `/data/works/play/sbd/.claude/skills/rdd-core.md` - Core RDD concepts
- `/data/works/play/sbd/.claude/skills/rdd-knowledge.md` - Knowledge management
- `/data/works/play/sbd/docs/03-stage-based-development.md` - Stage completion criteria
