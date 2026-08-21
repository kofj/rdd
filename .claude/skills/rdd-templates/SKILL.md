---
name: rdd-templates
description: RDD document templates reference (charter, stage, ADR, tech-debt, handoff)
disable-model-invocation: true
---

# RDD Document Templates

All document templates for RDD (Roadmap Driven Development) in one place.

---

## Stage Template

Use this template when creating a new Stage design document at `docs/stages/stage-N.md`.

```markdown
# Stage N: [Title]

## Status
[ ] Planning / [ ] In Progress / [ ] Complete

## Goals
What this stage specifically solves (be precise and limited)

## Non-Goals
What this stage explicitly does NOT do (be explicit about scope boundaries)

## Core Hypotheses
- Hypothesis A: [Description of what you're trying to validate]
- Hypothesis B: [Description of what you're trying to validate]

## Acceptance Criteria
- [ ] Acceptance criterion A (must be testable)
- [ ] Acceptance criterion B (must be testable)
- [ ] Acceptance criterion C (must be testable)

## Rollback Plan
Which version to fall back to if this stage fails

## Known Limitations
- [Limitation A - may become technical debt]
- [Limitation B - may become technical debt]

## Impact on Subsequent Stages
- [Impact A - what this stage enables or constrains for future stages]
- [Impact B - what this stage enables or constrains for future stages]

---

## Implementation Notes (Filled during implementation)

### Implementation Differences
[Document any differences from original design]

### Technical Decisions Made
[Document any technical decisions made during implementation]

### Testing Evidence
- Unit test coverage: X%
- E2E tests: [list test names and what they validate]
- Real environment verification: [description]
- Clean environment verification: [description]

### Handoff Notes
[What the next agent needs to know to continue]
```

---

## ADR Template

Use this template when recording decisions in `docs/08-autonomous-decisions.md`.

```markdown
### Decision N: [Title]

**Background**: What circumstances led to this decision becoming necessary

**Decision**: What path was chosen

**Rationale**: Why this path was selected (consider alternatives considered)

**Impact on Subsequent Stages**: (Cannot be empty - must describe concrete impact)
- [Specific impact on future work]
- [What this enables or constrains]
- [Any technical debt introduced]

**Date**: YYYY-MM-DD

**Related Stage**: Stage N

**Alternatives Considered**:
1. [Alternative 1]: [Why not chosen]
2. [Alternative 2]: [Why not chosen]
```

---

## Tech Debt Template

Use this template when recording technical debt in `docs/12-technical-debt.md`.

```markdown
### TD-NN: Short Title

- **Priority**: [Blocking / Degraded Functionality / Technical Optimization] / [Architecture-level / Module-level / Local]
- **Source**: [Proactive prototype compromise / Review deferred / Autonomous decision compromise] (Stage N)
- **Original Description**: (Quote from original document)
- **Source File**: (File path and line number, if applicable)
- **Suggested Resolution Stage**: (Stage N or "Special iteration" or "As needed")
- **Impact**: [What this debt affects]
- **Resolution Cost Estimate**: [Low / Medium / High]
- **Created Date**: YYYY-MM-DD
- **Resolved Date**: (Empty until resolved)

#### Notes
[Additional context or discussion about this debt]

#### Resolution Plan
[When this debt should be addressed and how]
```

---

## Handoff Template

Use this template when generating handoff documentation at `docs/handoff/handoff-latest.md`.

```markdown
# Agent Handoff Document

Generated: YYYY-MM-DD HH:MM
Previous Agent: [Agent ID/Session]
Current Stage: Stage N

---

## Current Progress

**Phase**: [Planning / In Progress / Review / Complete]
**Progress Percentage**: X%
**Current Gate**: [Gate 0-5]

### Completed Stages
- Stage 0: [Brief description] - Complete
- Stage 1: [Brief description] - Complete
- ...

### Current Stage Details
- **Stage**: Stage N
- **Status**: [Current status]
- **Current Task**: [What is being worked on right now]

---

## Completed Evidence

### Artifacts
- [Link to design document]
- [Link to implementation]
- [Link to tests]

### Verification
- [ ] Unit tests pass (coverage: X%)
- [ ] E2E tests pass (X tests)
- [ ] Real environment verified
- [ ] Clean environment verified
- [ ] Code review complete

### Documentation Updated
- [ ] stage-N.md
- [ ] stage-N-review-log.md
- [ ] autonomous-decisions.md
- [ ] technical-debt.md
- [ ] next-steps.md
- [ ] CHANGELOG.md

---

## Blockers & Risks

### Current Blockers
1. [Blocker description]
   - **Impact**: [What is blocked]
   - **Suggested Resolution**: [How to unblock]
   - **Priority**: P0/P1/P2

### Known Risks
1. [Risk description]
   - **Likelihood**: High/Medium/Low
   - **Impact**: High/Medium/Low
   - **Mitigation**: [Current mitigation strategy]

---

## Next Single Action

**Immediate Next Step**: [Specific, actionable description]

**How to Execute**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Outcome**: [What success looks like]

**Time Estimate**: [How long this should take]

---

## Degradation Strategy

If no progress for 30 minutes, trigger:
1. **First Degradation**: [Specific action - e.g., "Try alternative approach X"]
2. **Second Degradation**: [Specific action - e.g., "Reduce scope to minimal viable"]
3. **Escalation**: [Specific action - e.g., "Notify human via Hook P0"]

---

## Context for New Agent

### Key Decisions Made
1. [Decision and why]
2. [Decision and why]

### Important Context
- [Context that isn't obvious from documents]
- [Any implicit knowledge that should be explicit]

### Files to Read First
1. [Critical file 1] - [Why it's important]
2. [Critical file 2] - [Why it's important]

### Commands to Know
- `task [command]` - [Description]
- `rdd [command]` - [Description]

---

## Technical Debt Status

### New Debt This Session
| ID | Priority | Description | Stage |
|----|----------|-------------|-------|
| TD-XX | P1 | [Description] | Stage N |

### Debt Resolved This Session
| ID | Description | How Resolved |
|----|-------------|--------------|
| TD-XX | [Description] | [Resolution] |

---

## Hook Notifications Sent This Session

| Time | Level | Trigger | Status |
|------|-------|---------|--------|
| HH:MM | P0/P1/P2/P3 | [Trigger type] | Sent/Failed |
```

---

## Review Log Template

Use this template when creating review documentation at `docs/stages/stage-N-review-log.md`.

```markdown
# Stage N Review Log

**Review Type**: [Design / Code]
**Review Date**: YYYY-MM-DD
**Reviewer**: [Model name or "Human"]
**Stage**: Stage N

---

## Review Summary

**Files Reviewed**:
- [File 1]
- [File 2]

**Overall Assessment**: [Approved / Approved with Changes / Needs Major Revision]

---

## Findings

### Critical (Must Fix)
| ID | Finding | Location | Status |
|----|---------|----------|--------|
| C1 | [Description] | [File:line] | [Pending/Fixed/Wont Fix] |

### High Priority (Should Fix)
| ID | Finding | Location | Status |
|----|---------|----------|--------|
| H1 | [Description] | [File:line] | [Pending/Fixed/Wont Fix] |

### Medium Priority (Consider Fixing)
| ID | Finding | Location | Status |
|----|---------|----------|--------|
| M1 | [Description] | [File:line] | [Pending/Fixed/Wont Fix] |

### Low Priority (Nitpicks)
| ID | Finding | Location | Status |
|----|---------|----------|--------|
| L1 | [Description] | [File:line] | [Pending/Fixed/Wont Fix] |

---

## Finding Details

### C1: [Finding Title]
**Location**: [File:line]
**Description**: [Detailed description of the issue]
**Suggested Fix**: [How to fix it]
**Status**: [Pending/Fixed/Wont Fix]
**Resolution Reason**: (If Wont Fix, explain why)

### H1: [Finding Title]
**Location**: [File:line]
**Description**: [Detailed description of the issue]
**Suggested Fix**: [How to fix it]
**Status**: [Pending/Fixed/Wont Fix]
**Resolution Reason**: (If Wont Fix, explain why)

---

## Deferred Items (Technical Debt)

| Finding ID | Reason for Deferral | Tech Debt ID | Target Stage |
|------------|---------------------|--------------|--------------|
| M1 | [Why deferred] | TD-XX | Stage N+X |

---

## AI Pre-Filter Results

**Model Used**: [Model name]
**Initial Findings**: X
**Filtered as False Positive**: X
**Remaining for Review**: X

### Filtered Findings (Not Escalated)
| ID | Finding | Filter Reason |
|----|---------|---------------|
| F1 | [Description] | [Why filtered - e.g., "Not applicable to this context"] |

---

## Verification Method Used

For each finding, verification method applied:
- [ ] Authoritative source consulted
- [ ] Code verification performed
- [ ] Model inquiry conducted

---

## Resolution Summary

**Total Findings**: X
**Fixed**: X
**Deferred (Tech Debt)**: X
**Wont Fix (with reason)**: X
**False Positives**: X

**All Critical Fixed**: [Yes/No]
**All High Priority Addressed**: [Yes/No]

---

## Sign-Off

**Reviewer Signature**: [Name/Model]
**Date**: YYYY-MM-DD
**Approved**: [Yes/No/Conditional]

**Conditions for Approval**: (If conditional)
- [Condition 1]
- [Condition 2]
```

---

## Roadmap Template

Use this template when creating the roadmap at `docs/stages/stage-roadmap.md`.

```markdown
# Project Roadmap

**Last Updated**: YYYY-MM-DD
**Current Stage**: Stage N
**Overall Progress**: X%

---

## Vision

[One paragraph describing the project's ultimate goal]

---

## Stage Overview

| Stage | Title | Status | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| 0 | [Title] | Complete | P0 | None |
| 1 | [Title] | In Progress | P0 | Stage 0 |
| 2 | [Title] | Planning | P1 | Stage 1 |
| 3 | [Title] | Planning | P2 | Stage 1, Stage 2 |

---

## Stage Details

### Stage 0: [Title]
**Status**: Complete
**Goal**: [What this stage achieved]
**Completed**: YYYY-MM-DD
**Key Decisions**: [Link to ADRs]
**Technical Debt Introduced**: [Link to TD entries]

### Stage 1: [Title]
**Status**: In Progress
**Goal**: [What this stage will achieve]
**Started**: YYYY-MM-DD
**Blocked By**: [Any blockers]
**Est. Completion**: [Date or "TBD"]

### Stage 2: [Title]
**Status**: Planning
**Goal**: [What this stage will achieve]
**Prerequisites**: [What must be done first]
**Estimated Effort**: [Small/Medium/Large]

---

## Current Focus

**Active Stage**: Stage N
**Current Objective**: [Specific goal]
**Blockers**: [Any blockers or "None"]
**Next Milestone**: [What needs to be achieved]

---

## Roadmap History

| Date | Change | Reason |
|------|--------|--------|
| YYYY-MM-DD | [Stage added/removed/reordered] | [Why] |

---

## Priority Definitions

- **P0**: Must complete for MVP / Core functionality
- **P1**: Important for complete product experience
- **P2**: Nice to have, can be deferred
- **P3**: Future consideration

---

## Dependency Graph

```
Stage 0 (Foundation)
    |
    v
Stage 1 (Core Feature A) --+--> Stage 3 (Integration)
    |                       |
    v                       |
Stage 2 (Core Feature B) --+
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Strategy] | [Stage] |

---

## Notes

[Any additional context about the roadmap]
```

---

## Changelog Entry Template

Use this template when updating `CHANGELOG.md`.

```markdown
## [Stage N] - YYYY-MM-DD

### Added
- [New feature or capability]

### Changed
- [Changes to existing functionality]

### Deprecated
- [Features marked for removal]

### Removed
- [Features removed this stage]

### Fixed
- [Bug fixes]

### Technical Debt
- Introduced: TD-XX [Brief description]
- Resolved: TD-XX [Brief description]

### Breaking Changes
- [Any breaking changes and migration guide]

### ADRs
- Decision N: [Title] - [Link to ADR]

### Review Log
- [Link to stage-N-review-log.md]
```

---

## Usage Instructions

### When to Use Each Template

| Template | When to Use | File Path |
|----------|-------------|-----------|
| Stage | Starting a new stage | `docs/stages/stage-N.md` |
| ADR | Making a significant decision | `docs/08-autonomous-decisions.md` |
| Tech Debt | Discovering or resolving debt | `docs/12-technical-debt.md` |
| Handoff | Ending a session or handing off | `docs/handoff/handoff-latest.md` |
| Review Log | Completing a design or code review | `docs/stages/stage-N-review-log.md` |
| Roadmap | Creating or updating project roadmap | `docs/stages/stage-roadmap.md` |
| Changelog | Completing a stage | `CHANGELOG.md` |

### Template Variable Guide

When filling templates, replace:
- `[Title]` - With actual title
- `[Description]` - With actual description
- `N` or `NN` - With actual stage or decision number
- `X` - With actual count or percentage
- `YYYY-MM-DD` - With actual date
- `[ ]` - Checkboxes to mark when complete

---

## Reference

For detailed RDD specification, see:
- `prompt.md` - Full RDD specification
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
