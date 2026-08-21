---
name: rdd-diagnosis
description: Diagnose RDD project issues, analyze root causes, and provide remediation recommendations
---

# RDD Diagnosis Skill

> **Purpose**: Diagnose issues, analyze root causes, and provide remediation recommendations.

## Overview

This skill helps diagnose problems in RDD projects by systematically analyzing symptoms, identifying root causes, and recommending remediation steps.

**When to Use:**
- Tests are failing unexpectedly
- Stage is not progressing
- Quality gates are failing
- Something seems wrong but unclear what
- After recovery from interruption

**Command:** `/rdd-diagnosis <area> [--depth N]`

---

## Diagnosis Areas

| Area | Description |
|------|-------------|
| `tests` | Diagnose test failures |
| `stage` | Diagnose stage issues |
| `quality` | Diagnose quality gate failures |
| `docs` | Diagnose documentation issues |
| `all` | Run full diagnostic |

---

## Diagnosis Process

```
┌─────────────────┐
│ Collect Symptoms│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Form Hypotheses│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Test Hypotheses│
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Root Cause Found │─────│  Identify Fix   │
│      ?          │ No  │                 │
└────────┬────────┘     └────────┬────────┘
         │ Yes                   │
         │                       ▼
         │              ┌─────────────────┐
         │              │ Gather More     │
         │              │ Evidence        │
         │              └────────┬────────┘
         │                       │
         │                       └──────────┐
         ▼                                  │
┌─────────────────┐                         │
│ Document Finding│◄────────────────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Recommend Fix   │
└─────────────────┘
```

---

## Test Failure Diagnosis

### Symptom Collection

```
Test Failure Symptoms
=====================

## Which tests are failing?
[ ] Unit tests
[ ] Integration tests
[ ] E2E tests
[ ] All tests

## When do they fail?
[ ] Always
[ ] Intermittently
[ ] In specific environment
[ ] After specific change

## What is the error?
[ ] Assertion failure
[ ] Timeout
[ ] Exception
[ ] Resource unavailable

## What changed recently?
[ ] New code
[ ] Dependency update
[ ] Environment change
[ ] Configuration change
```

### Common Test Failure Patterns

| Pattern | Symptoms | Likely Cause | Diagnosis |
|---------|----------|--------------|-----------|
| Flaky Test | Passes sometimes | Race condition, timing | Check test isolation |
| Missing Mock | External API fails | Unmocked dependency | Check mock coverage |
| State Leak | Order-dependent | Shared state | Check test cleanup |
| Environment | Works locally | Config/env difference | Compare environments |
| Data | Specific data fails | Edge case | Check test data |
| Timeout | Slow operations | Performance issue | Profile operation |

### Test Diagnosis Steps

1. **Isolate the Failure**
   ```bash
   # Run single test
   task test --filter "test_name"

   # Run with verbose output
   task test --verbose
   ```

2. **Check Test Environment**
   ```bash
   # Check dependencies
   task doctor

   # Check environment variables
   env | grep PROJECT
   ```

3. **Analyze Error Message**
   - Read the full stack trace
   - Identify the exact line that fails
   - Check any error codes or messages

4. **Check Recent Changes**
   ```bash
   # Check git log
   git log --oneline -10

   # Check diff
   git diff HEAD~5
   ```

5. **Compare with Working State**
   ```bash
   # Run tests on previous commit
   git stash
   git checkout HEAD~1
   task test
   git checkout main
   git stash pop
   ```

---

## Stage Progression Diagnosis

### Symptom Collection

```
Stage Blockage Symptoms
========================

## Where is it stuck?
[ ] Gate 0: Stage Startup
[ ] Gate 1: Design Document
[ ] Gate 2: Design Review
[ ] Gate 3: Implementation
[ ] Gate 4: Code Review
[ ] Gate 5: Completion

## What is blocking?
[ ] Missing information
[ ] Failed check
[ ] External dependency
[ ] Resource constraint
[ ] Design issue

## How long stuck?
[ ] Minutes
[ ] Hours
[ ] Days
[ ] Weeks

## Retry history?
[ ] Never retried
[ ] Retried 1-2 times
[ ] Retried 3+ times
[ ] Max retries exceeded
```

### Common Stage Blockages

| Gate | Common Blockages | Diagnosis |
|------|------------------|-----------|
| Gate 0 | Missing roadmap, unmet dependencies | Check roadmap, verify dependencies |
| Gate 1 | Incomplete design, scope unclear | Review design template |
| Gate 2 | Review findings, scope creep | Apply pre-filters, check against roadmap |
| Gate 3 | Tests failing, coverage low | Run test diagnosis |
| Gate 4 | Code issues, review findings | Apply code review checklist |
| Gate 5 | Missing docs, fresh-agent-check fails | Run doc diagnosis |

### Stage Diagnosis Steps

1. **Check Stage Status**
   ```
   Read: docs/stages/stage-N.md
   Check: Status field, current gate
   ```

2. **Check Review Log**
   ```
   Read: docs/stages/stage-N-review-log.md
   Check: Unresolved findings
   ```

3. **Check Tech Debt**
   ```
   Read: docs/12-technical-debt.md
   Check: Blocking debt
   ```

4. **Check Handoff**
   ```
   Read: docs/handoff/handoff-latest.md
   Check: Blockers, next action
   ```

5. **Run Gate Check Manually**
   ```
   Manually verify each gate requirement
   Document which check fails
   ```

---

## Quality Gate Diagnosis

### Symptom Collection

```
Quality Gate Failure Symptoms
==============================

## Which quality gate failed?
[ ] Test coverage
[ ] Code quality (lint)
[ ] Security scan
[ ] Documentation
[ ] fresh-agent-check

## What is the metric?
Current: X
Required: Y
Gap: Z

## When did it start failing?
[ ] After recent change
[ ] After dependency update
[ ] Suddenly (no change)
[ ] Always failed

## Can it be fixed quickly?
[ ] Yes, simple fix
[ ] Maybe, need investigation
[ ] No, requires significant work
```

### Quality Gate Thresholds

| Gate | Threshold | Typical Failure |
|------|-----------|-----------------|
| Test Coverage | >= 20% | Not enough tests |
| Lint | 0 errors | Code style issues |
| Security | 0 high/critical | Vulnerabilities |
| Docs | Complete sections | Missing documentation |
| Fresh Agent | Pass | Tacit knowledge |

### Quality Diagnosis Steps

1. **Get Current Metrics**
   ```bash
   # Test coverage
   task test:coverage

   # Lint
   task lint

   # Security
   task security:scan
   ```

2. **Identify Gap**
   - Compare current vs required
   - Calculate what's needed to close gap

3. **Find Low-Hanging Fruit**
   - Easiest fixes to close gap
   - Quick wins that add coverage/quality

4. **Plan Remediation**
   - If quick fix: fix and retry
   - If significant: record tech debt, plan resolution

---

## Documentation Diagnosis

### Symptom Collection

```
Documentation Issue Symptoms
=============================

## What's wrong?
[ ] Missing sections
[ ] Outdated information
[ ] Inconsistent state
[ ] Tacit knowledge
[ ] fresh-agent-check fails

## Which documents affected?
[ ] Roadmap
[ ] Stage documents
[ ] ADRs
[ ] Tech debt ledger
[ ] Handoff documents

## How severe?
[ ] Blocking progress
[ ] Causing confusion
[ ] Minor inconsistency
[ ] Future maintenance issue
```

### Documentation Health Checks

```
Documentation Health Checklist
==============================

## Roadmap (stage-roadmap.md)
[ ] Vision is clear
[ ] Stages are listed
[ ] Current stage identified
[ ] Dependencies clear
[ ] Progress accurate

## Stage Documents (stage-N.md)
[ ] Goals defined
[ ] Non-goals explicit
[ ] Hypotheses testable
[ ] Acceptance criteria measurable
[ ] Status current
[ ] Implementation notes complete (if in progress)

## ADRs (autonomous-decisions.md)
[ ] Decisions are numbered
[ ] Background is clear
[ ] Rationale is explained
[ ] Impact on subsequent stages is NOT empty
[ ] Dates are present

## Tech Debt (technical-debt.md)
[ ] Each debt has ID
[ ] Priority is assigned
[ ] Source is documented
[ ] Resolution stage is planned

## fresh-agent-check
[ ] New agent can understand project purpose
[ ] Current stage is clear
[ ] Next actions are clear
[ ] No tacit knowledge required
```

### Doc Diagnosis Steps

1. **Run fresh-agent-check**
   ```
   /rdd-fresh-check
   ```

2. **Check Template Compliance**
   ```
   Compare each doc against templates in rdd-templates.md
   ```

3. **Check Cross-References**
   ```
   Verify all references between documents are valid
   ```

4. **Check Timestamps**
   ```
   Ensure documents are not stale
   ```

---

## Full Diagnostic

### Run All Checks

```
Full Diagnostic
===============

## 1. Test Health
[ ] All tests pass
[ ] Coverage meets threshold
[ ] No flaky tests

## 2. Stage Health
[ ] Current stage identified
[ ] Gate progression normal
[ ] No blockers

## 3. Quality Health
[ ] Lint passes
[ ] Security scan passes
[ ] No high debt

## 4. Documentation Health
[ ] All docs present
[ ] All docs current
[ ] fresh-agent-check passes

## 5. Configuration Health
[ ] .rdd/config.yml valid
[ ] .rdd/hooks.yml valid
[ ] .rdd/templates.yml valid

## 6. Integration Health
[ ] Hook scripts executable
[ ] Notification channels configured
[ ] Task commands work
```

### Diagnostic Report Template

```markdown
# RDD Diagnostic Report

**Date**: YYYY-MM-DD HH:MM
**Project**: [Project Name]

## Summary

| Area | Status | Issues |
|------|--------|--------|
| Tests | ✅/❌ | X |
| Stage | ✅/❌ | X |
| Quality | ✅/❌ | X |
| Docs | ✅/❌ | X |
| Config | ✅/❌ | X |
| Integration | ✅/❌ | X |

## Detailed Findings

### Tests
[Findings and recommendations]

### Stage
[Findings and recommendations]

### Quality
[Findings and recommendations]

### Docs
[Findings and recommendations]

### Config
[Findings and recommendations]

### Integration
[Findings and recommendations]

## Recommended Actions

1. [Priority 1 action]
2. [Priority 2 action]
3. [Priority 3 action]

## Next Steps

[What to do next]
```

---

## Integration with Other Skills

| Skill | When to Use |
|-------|-------------|
| `rdd-recovery` | After diagnosis, to recover from issues |
| `rdd-knowledge` | To record findings as tech debt |
| `rdd-fresh-check` | As part of doc diagnosis |

---

## Reference

For related information, see:
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-recovery/SKILL.md` - Recovery procedures
- `.claude/skills/rdd-stage-auto/SKILL.md` - Stage execution
