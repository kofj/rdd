---
name: rdd-stage-auto
description: Execute a complete RDD stage autonomously through all 5 quality gates with verification
---

# RDD Stage Auto Skill

> **Purpose**: Execute a complete RDD Stage autonomously with gate verification, design document generation, review triggering, and completion verification.

---

## Overview

This skill guides the autonomous execution of an RDD Stage from start to finish. It ensures all gates are properly verified, documents are generated, reviews are triggered, and completion criteria are met before marking a stage as complete.

**When to Use:**
- Starting a new Stage from the Roadmap
- Resuming an interrupted Stage
- When you need structured, verified Stage execution

**Command:** `/rdd-stage-auto [stage-number]`

---

## Stage Execution Flow

```
GATE 0: Stage Startup Check
    |
    v
GATE 1: Design Document Pre-Check
    |
    v
GATE 2: Design Review (Before Coding)
    |
    v
GATE 3: Implementation & Testing
    |
    v
GATE 4: Code Review (After E2E Pass)
    |
    v
GATE 5: Completion Gate Check
```

---

## GATE 0: Stage Startup Check

### Purpose
Verify all prerequisites are met before starting the Stage.

### Verification Steps

1. **Check Roadmap Exists**
   ```bash
   # Verify roadmap file exists
   ls docs/stages/stage-roadmap.md
   ```

2. **Verify Prerequisites Met**
   - Read `docs/stages/stage-roadmap.md`
   - Identify the target Stage
   - Check all dependency stages are marked "Complete"
   - If dependencies not met, STOP and report blocker

3. **Check for Roadmap Changes**
   - Compare current roadmap with any pending changes
   - If roadmap has changed, verify Stage goals still valid
   - Document any scope changes

4. **Load Context**
   - Read historical ADRs: `docs/08-autonomous-decisions.md`
   - Read technical debt ledger: `docs/12-technical-debt.md`
   - Read previous Stage documents: `docs/stages/stage-N.md`
   - Read next steps: `docs/11-next-steps.md`

5. **Check for Existing Stage Document**
   ```bash
   ls docs/stages/stage-N.md
   ```
   - If exists and status is "Complete", Stage already done
   - If exists and status is "In Progress", resume from last gate
   - If not exists, proceed to Gate 1

### Gate 0 Checklist
- [ ] Roadmap file exists and is readable
- [ ] Target Stage identified from roadmap
- [ ] All dependency stages complete
- [ ] Historical context loaded (ADRs, tech debt, previous stages)
- [ ] Stage document status checked

### Blocker Handling
If prerequisites not met:
1. Document the blocker in `docs/11-next-steps.md`
2. Trigger Hook notification (P1 level)
3. Wait for human intervention or work on unblocked stages

---

## GATE 1: Design Document Pre-Check

### Purpose
Ensure a proper design document exists before any implementation.

### Verification Steps

1. **Check for Existing Design Document**
   ```bash
   ls docs/stages/stage-N.md
   ```

2. **If Design Document Missing**
   - STOP immediately
   - Generate design document using template from `rdd-templates.md`
   - Do NOT proceed to implementation

3. **If Design Document Exists, Verify Completeness**
   - Status field present
   - Goals section defined
   - Non-goals explicitly stated
   - Core hypotheses listed
   - Acceptance criteria are testable
   - Rollback plan defined
   - Known limitations documented
   - Impact on subsequent stages described

### Design Document Generation

Use the Stage Template from `.claude/skills/rdd-templates/SKILL.md`:

```markdown
# Stage N: [Title]

## Status
[ ] Planning / [ ] In Progress / [ ] Complete

## Goals
[What this stage specifically solves - be precise and limited]

## Non-Goals
[What this stage explicitly does NOT do]

## Core Hypotheses
- Hypothesis A: [Description]
- Hypothesis B: [Description]

## Acceptance Criteria
- [ ] [Testable criterion A]
- [ ] [Testable criterion B]

## Rollback Plan
[Which version to fall back to if this stage fails]

## Known Limitations
- [Limitation A]
- [Limitation B]

## Impact on Subsequent Stages
- [Impact A]
- [Impact B]

---
[Implementation Notes section filled during implementation]
```

### Scope Creep Detection
Compare design goals against Roadmap stage definition:
- If goals expanded, STOP and update Roadmap first
- If goals reduced, document in Known Limitations
- Any scope change requires explicit documentation

### Gate 1 Checklist
- [ ] Design document exists at `docs/stages/stage-N.md`
- [ ] All required sections present and filled
- [ ] Goals match Roadmap definition (no silent scope expansion)
- [ ] Non-goals explicitly state what is out of scope
- [ ] Acceptance criteria are testable
- [ ] Rollback plan defined
- [ ] Design document status set to "In Progress"

---

## GATE 2: Design Review (Before Coding)

### Purpose
Validate the design through multi-model review before implementation begins.

### Review Trigger Process

1. **Prepare Review Package**
   - Design document: `docs/stages/stage-N.md`
   - Related ADRs for context
   - Technical debt that may affect this stage
   - Previous stage implementation notes

2. **Trigger Multi-Model Review**

   If the `/rdd-review-auto` skill exists, invoke it:
   ```
   /rdd-review-auto design --stage N
   ```

   Otherwise, perform self-review using these principles:
   - Review as a critical colleague would
   - Check for logical fallacies
   - Verify assumptions are explicit
   - Look for hidden dependencies

3. **Apply Review Filters**

   **AI Pre-Filter** (expect ~50% false positives):
   - Filter findings that are clearly incorrect
   - Filter findings that don't apply to this context
   - Document filter decisions

   **Rule Filtering** (check for common patterns):
   - Memory bias: Does design rely on unstated context?
   - Logical fallacy: Are conclusions well-supported?
   - Scope creep: Is design trying to solve too much?

4. **Verification Method Priority**
   1. **Authoritative sources** - Check documentation, specifications
   2. **Code verification** - Check existing code patterns
   3. **Model inquiry** - Ask follow-up questions

5. **Handle Findings**
   - **Critical/High Priority**: Must fix before proceeding
   - **Medium Priority**: Document and address if time allows
   - **Low Priority**: Document as potential improvement
   - **Low-confidence findings**: Escalate to human review

6. **Create Review Log**

   Use the Review Log Template from `rdd-templates.md`:
   ```markdown
   # Stage N Review Log

   **Review Type**: Design
   **Review Date**: YYYY-MM-DD
   **Reviewer**: [Model name or "Human"]
   **Stage**: Stage N

   ## Review Summary
   [Overall assessment]

   ## Findings
   [Categorized findings with status]

   ## AI Pre-Filter Results
   [What was filtered and why]

   ## Resolution Summary
   [How findings were addressed]
   ```

   Save to: `docs/stages/stage-N-review-log.md`

### Gate 2 Checklist
- [ ] Review package prepared
- [ ] Multi-model review triggered (or self-review performed)
- [ ] AI pre-filter applied to findings
- [ ] Rule filtering applied
- [ ] Critical findings fixed
- [ ] High priority findings addressed
- [ ] Review log created at `docs/stages/stage-N-review-log.md`
- [ ] Design updated based on review feedback

### Proceed to Implementation Only When
- All Critical findings resolved
- All High priority findings addressed or documented
- Review log completed

---

## GATE 3: Implementation & Testing

### Purpose
Implement the design and verify with tests.

### Implementation Process

1. **Update Stage Status**
   ```markdown
   ## Status
   [x] Planning / [x] In Progress / [ ] Complete
   ```

2. **Implement Following Design**
   - Follow the design document precisely
   - Document any deviations in Implementation Notes section
   - If scope changes, STOP and return to Gate 1

3. **Write Unit Tests Alongside Code**
   - Minimum coverage: 20%
   - Focus on critical paths
   - Each test should verify a specific acceptance criterion

4. **Write E2E Tests**
   - At least 2 high-signal test paths
   - Cover the main user workflows
   - Tests must be reproducible

5. **Run All Tests**
   ```bash
   # Run unit tests
   npm test  # or appropriate test command

   # Run E2E tests
   npm run test:e2e  # or appropriate E2E command
   ```

6. **Real Environment Verification**
   - Deploy to real environment (not mock)
   - Verify core functionality works
   - Document verification results

7. **Clean Environment Verification**
   - Test in clean local environment
   - Test in clean CI/staging environment
   - Ensure no hidden dependencies

8. **Document Implementation Differences**

   Update the Implementation Notes section in `docs/stages/stage-N.md`:
   ```markdown
   ## Implementation Notes

   ### Implementation Differences
   [Any differences from original design]

   ### Technical Decisions Made
   [Decisions made during implementation]

   ### Testing Evidence
   - Unit test coverage: X%
   - E2E tests: [list]
   - Real environment verification: [description]
   - Clean environment verification: [description]
   ```

### Testing Requirements

| Test Type | Minimum Requirement |
|-----------|---------------------|
| Unit Tests | 20% coverage |
| E2E Tests | 2 high-signal paths |
| Real Env | Core functionality verified |
| Clean Env | Local + CI/Staging |

### Gate 3 Checklist
- [ ] Implementation follows design document
- [ ] Any deviations documented
- [ ] Unit tests written with >= 20% coverage
- [ ] E2E tests written (min 2 high-signal paths)
- [ ] All tests pass
- [ ] Real environment verification done
- [ ] Clean environment verification done
- [ ] Implementation notes updated in stage document

---

## GATE 4: Code Review (After E2E Pass)

### Purpose
Validate the implementation through multi-model code review.

### Prerequisite
- All tests must pass (Gate 3 complete)
- E2E tests verified in real and clean environments

### Review Process

1. **Prepare Review Package**
   - Implementation files changed
   - Test files created/modified
   - Design document (for comparison)
   - Previous review log (design review)

2. **Trigger Multi-Model Review**

   If the `/rdd-review-auto` skill exists, invoke it:
   ```
   /rdd-review-auto code --stage N
   ```

   Otherwise, perform self-review using:
   - Code quality review
   - Security review
   - Performance review
   - Test adequacy review

3. **Triangulation Verification**

   Use three sources of verification:
   - **Main Model**: Primary implementation review
   - **Independent Review Model**: Fresh perspective
   - **Rule Checking**: Automated pattern detection

   **Important**: Do NOT rely on "multi-model consensus" alone.
   Verify each finding independently.

4. **Apply Filters**
   - AI pre-filter for false positives
   - Rule filter for common issues
   - Document all filter decisions

5. **Verify Each Finding**

   For each finding, determine:
   - Is this a real issue? (verify with code)
   - What is the severity? (Critical/High/Medium/Low)
   - What is the fix? (specific remediation)
   - Should this be deferred? (becomes tech debt)

6. **Handle Findings**
   - **Critical**: Block, must fix immediately
   - **High**: Should fix before stage completion
   - **Medium**: Document, fix if time allows
   - **Low**: Document as tech debt or future improvement

7. **Update Review Log**

   Add code review section to `docs/stages/stage-N-review-log.md`:
   ```markdown
   ---

   ## Code Review (Stage N)

   **Review Type**: Code
   **Review Date**: YYYY-MM-DD
   **Reviewer**: [Model name]

   ### Files Reviewed
   - [file1]
   - [file2]

   ### Findings
   [Categorized with severity]

   ### Resolution Summary
   [How each finding was addressed]
   ```

### Finding Categories

| Severity | Action | Blocking |
|----------|--------|----------|
| Critical | Fix immediately | Yes |
| High | Fix before completion | Yes |
| Medium | Fix or defer to tech debt | No |
| Low | Document only | No |

### Gate 4 Checklist
- [ ] All tests pass (prerequisite)
- [ ] Review package prepared
- [ ] Multi-model review triggered
- [ ] AI pre-filter applied
- [ ] Rule filtering applied
- [ ] Each finding verified independently
- [ ] Critical findings fixed
- [ ] High priority findings fixed
- [ ] Medium/Low findings documented or deferred
- [ ] Review log updated with code review results

---

## GATE 5: Completion Gate Check

### Purpose
Verify all stage completion criteria are met before marking complete.

### Completion Verification Checklist

1. **Hypotheses Verification**
   - [ ] Main hypotheses verified or falsified
   - [ ] Results documented in stage document
   - [ ] If falsified, document implications

2. **Test Reproducibility**
   - [ ] Tests can be run via Task entry
   - [ ] No undocumented manual steps
   - [ ] All test commands documented

3. **Design-Implementation Alignment**
   - [ ] Implementation matches design
   - [ ] Differences documented in Implementation Notes
   - [ ] Scope changes recorded

4. **CLI Subcommands** (if new capabilities added)
   - [ ] New capabilities have CLI entry points
   - [ ] CLI documented in README or help

5. **Technical Debt Ledger**
   - [ ] All known gaps recorded in `docs/12-technical-debt.md`
   - [ ] Debt entries have priority and resolution stage
   - [ ] Format follows Tech Debt Template

6. **ADR Recording**
   - [ ] Significant decisions recorded in `docs/08-autonomous-decisions.md`
   - [ ] "Impact on Subsequent Stages" field is NOT empty
   - [ ] Format follows ADR Template

7. **Fresh Agent Check**
   - [ ] A new agent could take over from documentation alone
   - [ ] No tacit knowledge required
   - [ ] All context is explicit in documents

### Document Update Obligations

All documents must be updated synchronously (no "docs pending"):

| Document | File Path | What to Update |
|----------|-----------|----------------|
| Stage Document | `docs/stages/stage-N.md` | Implementation differences, status to Complete |
| Review Log | `docs/stages/stage-N-review-log.md` | Final resolution summary |
| ADRs | `docs/08-autonomous-decisions.md` | Any decisions made |
| Tech Debt | `docs/12-technical-debt.md` | New debt, resolved debt |
| Next Steps | `docs/11-next-steps.md` | Progress update |
| Changelog | `CHANGELOG.md` | Stage changes |

### Update Each Document

1. **Stage Document** (`docs/stages/stage-N.md`)
   ```markdown
   ## Status
   [x] Planning / [x] In Progress / [x] Complete

   ## Implementation Notes
   [All sections filled]
   ```

2. **Review Log** (`docs/stages/stage-N-review-log.md`)
   ```markdown
   ## Resolution Summary
   **Total Findings**: X
   **Fixed**: X
   **Deferred**: X
   **Wont Fix**: X

   **All Critical Fixed**: Yes
   **All High Priority Addressed**: Yes
   ```

3. **ADRs** (`docs/08-autonomous-decisions.md`)
   ```markdown
   ### Decision N: [Title]
   **Background**: ...
   **Decision**: ...
   **Rationale**: ...
   **Impact on Subsequent Stages**: [MUST NOT BE EMPTY]
   **Date**: YYYY-MM-DD
   **Related Stage**: Stage N
   ```

4. **Tech Debt** (`docs/12-technical-debt.md`)
   ```markdown
   ### TD-NN: [Title]
   - **Priority**: [Priority]
   - **Source**: Stage N
   - **Suggested Resolution Stage**: Stage N+X
   ...
   ```

5. **Next Steps** (`docs/11-next-steps.md`)
   ```markdown
   ## Current Progress
   - Stage N: Complete
   - Next: Stage N+1

   ## Immediate Actions
   [What the next stage should focus on]
   ```

6. **Changelog** (`CHANGELOG.md`)
   ```markdown
   ## [Stage N] - YYYY-MM-DD

   ### Added
   - [New features]

   ### Changed
   - [Changes]

   ### Technical Debt
   - Introduced: TD-XX [Description]
   - Resolved: TD-XX [Description]
   ```

### Gate 5 Checklist
- [ ] Main hypotheses verified or falsified
- [ ] Tests reproducible via documented commands
- [ ] No undocumented manual steps
- [ ] Implementation matches design (differences recorded)
- [ ] New capabilities have CLI subcommands (if applicable)
- [ ] Technical debt ledger updated
- [ ] ADRs recorded with impact on subsequent stages
- [ ] Fresh-agent-check passed (new agent can take over)
- [ ] stage-N.md updated and status = Complete
- [ ] stage-N-review-log.md finalized
- [ ] autonomous-decisions.md updated
- [ ] technical-debt.md updated
- [ ] next-steps.md updated
- [ ] CHANGELOG.md updated

---

## Complete Gate Summary

| Gate | Purpose | Key Output |
|------|---------|------------|
| Gate 0 | Stage Startup | Prerequisites verified, context loaded |
| Gate 1 | Design Pre-Check | Design document complete |
| Gate 2 | Design Review | Design validated, review log created |
| Gate 3 | Implementation | Code written, tests passing |
| Gate 4 | Code Review | Code validated, issues resolved |
| Gate 5 | Completion | All docs updated, stage complete |

---

## Error Handling

### Gate Failure
If any gate fails:
1. Document the failure reason
2. Identify what needs to be fixed
3. Either fix and retry, or escalate to human
4. Update `docs/11-next-steps.md` with blocker status

### Blocker Escalation
If blocked for more than 30 minutes:
1. Document all attempted solutions
2. Create handoff document at `docs/handoff/handoff-latest.md`
3. Trigger Hook notification (P1 level)
4. Wait for human intervention

### Recovery
When resuming an interrupted stage:
1. Read `docs/handoff/handoff-latest.md` if exists
2. Read `docs/stages/stage-N.md` for current status
3. Determine which gate was in progress
4. Resume from that gate's checklist

---

## Reference

For templates and detailed specifications, see:
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-templates/SKILL.md` - Document templates
- `prompt.md` - Full RDD specification
