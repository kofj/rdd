---
name: rdd-review-auto
description: Automated multi-model review for RDD design documents and code
---

# RDD Review Auto Skill

> **Purpose**: Automated multi-model review for design documents and code.

## Overview

This skill provides automated review capabilities for RDD stages. It implements multi-model triangulation to catch issues that a single model might miss, while accounting for the expected ~50% false positive rate in AI-generated findings.

**When to Use:**
- Before implementation (Gate 2: Design Review)
- After implementation (Gate 4: Code Review)
- When significant changes are made
- When requested by `/rdd-review-auto` command

**Command:** `/rdd-review-auto <type> --stage N`

---

## Review Types

| Type | Description | Gate |
|------|-------------|------|
| `design` | Review design document before implementation | Gate 2 |
| `code` | Review implementation after E2E pass | Gate 4 |
| `both` | Run both design and code reviews | - |
| `adr` | Review an ADR for completeness | Any |

---

## Multi-Model Triangulation

### Why Triangulation?

Single-model review has significant blind spots:
- Memory bias (reviewing own work)
- Confirmation bias
- Missing context
- Consistent blind spots

Multi-model triangulation uses independent reviewers to catch more issues.

### Triangulation Process

```
┌─────────────────┐
│   Main Model    │ ──► Primary work and initial review
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Independent     │ ──► Fresh perspective review
│ Review Model    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Rule Checking  │ ──► Automated pattern detection
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Triangulation │ ──► Findings merged and filtered
│   Analysis      │
└─────────────────┘
```

### Verification Priority

When findings disagree between models:

| Priority | Verification Method |
|----------|---------------------|
| 1 | Authoritative sources (docs, specs) |
| 2 | Code verification (runtime behavior) |
| 3 | Model inquiry (ask third model) |

**Important**: Do NOT rely on "multi-model consensus" alone. Always verify.

---

## False Positive Handling

### Expected False Positive Rate

AI-generated review findings have approximately **50% false positive rate**. This is expected and normal.

### False Positive Categories

| Category | Description | Action |
|----------|-------------|--------|
| Context Missing | Finding assumes unavailable context | Filter if context confirmed missing |
| Incorrect Assumption | Finding based on wrong premise | Filter if premise disproved |
| Non-Applicable | Finding doesn't apply to this domain | Filter with documented reason |
| Over-Generalization | Finding is too broad | Narrow or filter |
| Misunderstanding | Finding misreads the code/doc | Filter with explanation |

### Pre-Filter Protocol

Before presenting findings:

1. **Check for Context**: Does the finding assume context that doesn't exist?
2. **Check for Accuracy**: Is the finding factually correct?
3. **Check for Applicability**: Does this apply to our project?
4. **Check for Priority**: Is this the right priority level?

Document all filter decisions in the review log.

---

## Design Review (Gate 2)

### Purpose

Validate design document before any implementation begins.

### Prerequisites

- Design document exists at `docs/stages/stage-N.md`
- Goals section is defined
- Acceptance criteria are testable

### Design Review Checklist

```
Design Review Checklist
=======================

## Goals and Scope
[ ] Goals are clear, specific, and limited
[ ] Non-goals are explicitly stated
[ ] Scope is appropriate for single stage

## Hypotheses
[ ] Hypotheses are testable
[ ] Hypotheses are specific
[ ] Success/failure criteria are defined

## Acceptance Criteria
[ ] All criteria are measurable
[ ] All criteria are testable
[ ] Criteria match the goals

## Rollback Plan
[ ] Rollback version is identified
[ ] Rollback procedure is defined
[ ] Data migration considered (if applicable)

## Impact Assessment
[ ] Impact on subsequent stages documented
[ ] Dependencies are identified
[ ] Risks are assessed

## Documentation
[ ] Design is self-contained
[ ] No tacit knowledge required
[ ] Fresh agent can understand
```

### Design Review Workflow

1. **Read Design Document**
   ```
   Read: docs/stages/stage-N.md
   ```

2. **Run Checklist**
   - Go through each item
   - Note any issues or concerns

3. **Multi-Model Review** (if available)
   - Send design to independent model
   - Collect findings
   - Compare with your findings

4. **Apply Pre-Filters**
   - Filter false positives
   - Document filter decisions

5. **Verify Critical Findings**
   - For each critical/high finding
   - Verify with authoritative sources
   - Or verify with code/runtime

6. **Create Review Log**
   ```
   Create: docs/stages/stage-N-review-log.md
   ```

7. **Update Design Document**
   - Fix critical issues
   - Address high priority issues
   - Document deferred issues

### Design Review Log Template

```markdown
# Stage N Design Review Log

**Review Type**: Design
**Review Date**: YYYY-MM-DD
**Reviewer**: [Model name or "Human"]
**Stage**: Stage N

## Summary

- **Total Findings**: X
- **Critical**: X
- **High**: X
- **Medium**: X
- **Low**: X
- **False Positives Filtered**: X

## Checklist Results

| Section | Status | Notes |
|---------|--------|-------|
| Goals and Scope | ✅/❌ | [Notes] |
| Hypotheses | ✅/❌ | [Notes] |
| Acceptance Criteria | ✅/❌ | [Notes] |
| Rollback Plan | ✅/❌ | [Notes] |
| Impact Assessment | ✅/❌ | [Notes] |
| Documentation | ✅/❌ | [Notes] |

## Findings

### Critical

1. **[Finding Title]**
   - **Location**: [Section/Line]
   - **Description**: [What's wrong]
   - **Recommendation**: [How to fix]
   - **Status**: [Fixed/Deferred/Wont Fix]

### High

[Same format as Critical]

### Medium

[Same format as Critical]

### Low

[Same format as Critical]

## AI Pre-Filter Results

| Finding | Filter Reason | Action |
|---------|---------------|--------|
| [Finding] | [Why filtered] | [Kept/Removed] |

## Verification Results

| Finding | Verification Method | Result |
|---------|---------------------|--------|
| [Finding] | [Method] | [Confirmed/Rejected] |

## Resolution Summary

- **Critical Fixed**: X/X
- **High Addressed**: X/X
- **Medium Documented**: X/X
- **Low Noted**: X/X

**Design Ready for Implementation**: Yes/No
```

---

## Code Review (Gate 4)

### Purpose

Validate implementation through comprehensive code review.

### Prerequisites

- All tests pass
- E2E tests verified in real environment
- E2E tests verified in clean environment
- Implementation matches design

### Code Review Dimensions

```
Code Review Dimensions
======================

## Correctness
[ ] Code does what design specifies
[ ] Edge cases are handled
[ ] Error handling is appropriate
[ ] No obvious bugs

## Code Quality
[ ] Code is readable and maintainable
[ ] Naming is clear and consistent
[ ] No code duplication
[ ] Appropriate abstractions

## Performance
[ ] No obvious performance issues
[ ] Resource usage is appropriate
[ ] Caching is used where appropriate
[ ] No unnecessary operations

## Security
[ ] No injection vulnerabilities
[ ] Input validation is present
[ ] Sensitive data is protected
[ ] Access control is appropriate

## Testability
[ ] Code is testable
[ ] Tests cover critical paths
[ ] Tests are meaningful
[ ] Test coverage meets threshold

## Documentation
[ ] Public APIs are documented
[ ] Complex logic is explained
[ ] README is up to date
```

### Code Review Workflow

1. **Prepare Review Package**
   ```
   Files to review:
   - Implementation files (list)
   - Test files (list)
   - Design document (for comparison)
   - Previous review log (design review)
   ```

2. **Run Static Analysis** (if available)
   ```bash
   # Linting
   npm run lint  # or appropriate lint command

   # Type checking
   npm run typecheck  # if TypeScript

   # Security scanning
   npm audit  # or appropriate security scan
   ```

3. **Review by Dimension**
   - Go through each dimension
   - Note issues with file:line references

4. **Multi-Model Review** (if available)
   - Send code to independent model
   - Collect findings
   - Compare with your findings

5. **Apply Pre-Filters**
   - Filter false positives
   - Document filter decisions

6. **Verify Each Finding**
   - Open the file
   - Navigate to the line
   - Confirm the issue exists
   - Assess severity

7. **Update Review Log**
   ```
   Update: docs/stages/stage-N-review-log.md
   Add Code Review section
   ```

8. **Fix Issues**
   - Fix all Critical issues immediately
   - Fix all High issues before stage completion
   - Document Medium/Low as tech debt

### Code Review Log Template

Add this to the existing review log:

```markdown
---

## Code Review (Stage N)

**Review Type**: Code
**Review Date**: YYYY-MM-DD
**Reviewer**: [Model name]

### Files Reviewed

- `path/to/file1.ext`
- `path/to/file2.ext`

### Summary

- **Total Findings**: X
- **Critical**: X
- **High**: X
- **Medium**: X
- **Low**: X

### Static Analysis Results

| Tool | Findings | Notes |
|------|----------|-------|
| Lint | X | [Summary] |
| TypeCheck | X | [Summary] |
| Security | X | [Summary] |

### Findings by Dimension

#### Correctness

1. **[Finding Title]**
   - **Location**: `file.ext:line`
   - **Description**: [What's wrong]
   - **Recommendation**: [How to fix]
   - **Status**: [Fixed/Deferred/Wont Fix]

[Continue for each dimension]

### AI Pre-Filter Results

| Finding | Filter Reason | Action |
|---------|---------------|--------|
| [Finding] | [Why filtered] | [Kept/Removed] |

### Verification Results

| Finding | Verification | Result |
|---------|--------------|--------|
| [Finding] | Line checked | [Confirmed/Rejected] |

### Resolution Summary

- **Critical Fixed**: X/X
- **High Fixed**: X/X
- **Medium Deferred**: X (to TD-XX)
- **Low Noted**: X

**Code Ready for Merge**: Yes/No
```

---

## ADR Review

### Purpose

Ensure ADRs (Autonomous Decision Records) are complete and useful.

### ADR Review Checklist

```
ADR Review Checklist
====================

[ ] Background explains why decision was needed
[ ] Decision is clear and specific
[ ] Rationale explains why this choice over alternatives
[ ] Impact on Subsequent Stages is NOT empty
[ ] Impact is specific, not vague
[ ] Date is present
[ ] Related Stage is identified
[ ] Alternatives considered are documented
[ ] No tacit knowledge required
```

### Common ADR Issues

| Issue | Description | Fix |
|-------|-------------|-----|
| Empty Impact | "Impact on Subsequent Stages" is empty | Add specific impacts |
| Vague Impact | Impact is too generic | Add concrete examples |
| Missing Alternatives | No alternatives considered | Document alternatives and why rejected |
| Missing Context | Background is insufficient | Add more context |
| Wrong Date | Date is missing or wrong | Add correct date |

---

## Integration with RDD Core

### When to Review

| Gate | Review Type | Trigger |
|------|-------------|---------|
| Gate 2 | Design Review | After design doc complete |
| Gate 4 | Code Review | After E2E tests pass |
| Any | ADR Review | After ADR recorded |

### Blocking Rules

- **Critical findings**: Block stage progression
- **High findings**: Block until addressed or documented
- **Medium findings**: Can defer to tech debt
- **Low findings**: Note only

### After Review

1. Update review log
2. Fix critical/high issues
3. Create tech debt entries for deferred items
4. Update design/implementation documentation
5. Run fresh-agent-check if design changed

---

## Reference

For related information, see:
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-knowledge/SKILL.md` - Knowledge management
- `docs/10-review-practices.md` - Review practices document
