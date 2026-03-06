# RDD Roadmap Management Skill

> **Purpose**: Operational guide for creating, modifying, and tracking the project roadmap

## Overview

The roadmap (`docs/stages/stage-roadmap.md`) is the central artifact for RDD. It defines the sequence of stages, their dependencies, and tracks overall project progress. This skill provides step-by-step instructions for roadmap operations.

---

## Creating the Roadmap

### Initial Creation

When starting a new RDD project, create the roadmap file at `docs/stages/stage-roadmap.md`.

**Steps:**

1. **Create the directory structure:**
   ```bash
   mkdir -p docs/stages
   ```

2. **Initialize the roadmap file** using the template from `rdd-templates.md`:
   - Copy the Roadmap Template section
   - Fill in the vision statement (one paragraph describing the ultimate goal)
   - Define initial stages (usually Stage 0 for foundation)

3. **Essential sections to include:**
   - Vision: Clear, one-paragraph project goal
   - Stage Overview table: All stages with status, priority, dependencies
   - Stage Details: Each stage with goals and current status
   - Current Focus: Active stage and blockers
   - Roadmap History: Log of all changes with reasons
   - Dependency Graph: Visual representation of stage dependencies

### Minimum Viable Roadmap

A minimal roadmap should have at least:
- Stage 0: Foundation/Setup
- Stage 1: First meaningful feature
- Clear dependency between them

---

## Adding New Stages

### When to Add a Stage

Add a new stage when:
- New feature or capability is identified
- Technical debt requires a dedicated resolution stage
- Scope expansion is approved (requires human approval for roadmap changes)
- A large stage needs to be split for better manageability

### Steps to Add a Stage

1. **Determine the stage number:**
   - Use the next available sequential number
   - If inserting between stages, renumber subsequent stages (see Reordering)

2. **Identify dependencies:**
   - What stages must complete before this can start?
   - What stages depend on this one?

3. **Update the Stage Overview table:**
   - Add a new row with all required columns
   - Status starts as "Planning"
   - Priority: P0-P3 (see Priority Definitions below)

4. **Add Stage Details section:**
   - Goal: What this stage will achieve
   - Prerequisites: Dependencies on other stages
   - Estimated Effort: Small/Medium/Large

5. **Update the Dependency Graph:**
   - Add the new stage to the visual diagram
   - Show connections to dependent stages

6. **Record in Roadmap History:**
   - Date of change
   - Description: "Added Stage N: [Title]"
   - Reason: Why this stage was added

### Example: Adding Stage 3

```markdown
## Stage Overview (Updated)

| Stage | Title | Status | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| 0 | Foundation | Complete | P0 | None |
| 1 | Core Feature A | Complete | P0 | Stage 0 |
| 2 | Core Feature B | In Progress | P0 | Stage 1 |
| 3 | Integration | Planning | P1 | Stage 1, Stage 2 |

### Stage 3: Integration
**Status**: Planning
**Goal**: Integrate Feature A and Feature B for end-to-end workflow
**Prerequisites**: Stage 1 and Stage 2 must complete
**Estimated Effort**: Medium

## Roadmap History

| Date | Change | Reason |
|------|--------|--------|
| 2026-03-06 | Added Stage 3: Integration | Needed to connect completed features |
```

---

## Reordering Stages

### When to Reorder

Reorder stages when:
- Business priorities change
- A dependency is discovered or resolved
- Technical constraints require a different sequence
- A blocking stage needs to be prioritized

### Reordering Process

**IMPORTANT**: Reordering stages may require renumbering, which affects:
- Stage file names (`stage-N.md`)
- Review logs (`stage-N-review-log.md`)
- ADR references to stages
- Technical debt references to stages

**Steps:**

1. **Assess impact:**
   - List all files that reference the stage numbers being changed
   - Check: `docs/stages/stage-*.md`, `docs/08-autonomous-decisions.md`, `docs/12-technical-debt.md`, `CHANGELOG.md`

2. **Create a mapping table:**
   ```
   Old Number -> New Number
   Stage 2    -> Stage 3
   Stage 3    -> Stage 2
   ```

3. **Rename stage files:**
   ```bash
   # Temporarily move to avoid conflicts
   mv docs/stages/stage-2.md docs/stages/stage-2-temp.md
   mv docs/stages/stage-3.md docs/stages/stage-2.md
   mv docs/stages/stage-2-temp.md docs/stages/stage-3.md
   # Also rename review logs if they exist
   ```

4. **Update internal references:**
   - Update stage numbers within each file
   - Update references in ADRs and technical debt

5. **Update the roadmap:**
   - Reorder rows in Stage Overview table
   - Update all Stage Details sections
   - Update the Dependency Graph

6. **Update cross-references:**
   - Search and replace stage references in all documentation
   - Update CHANGELOG.md if needed

7. **Record in Roadmap History:**
   ```markdown
   | 2026-03-06 | Reordered: Stage 2 <-> Stage 3 | Dependency resolution required integration first |
   ```

### Safe Reordering Checklist

- [ ] All stage files renamed correctly
- [ ] Internal file references updated
- [ ] ADR references updated
- [ ] Technical debt references updated
- [ ] Dependency Graph updated
- [ ] Stage Overview table reordered
- [ ] Roadmap History updated
- [ ] No broken references remain

---

## Progress Tracking

### Updating Stage Status

Stage status transitions follow this lifecycle:

```
Planning -> In Progress -> Review -> Complete
                  |
                  v
               Blocked
```

**Status Definitions:**
- **Planning**: Stage is defined but not started
- **In Progress**: Active development underway
- **Review**: Implementation complete, under review
- **Blocked**: Cannot proceed due to external dependency
- **Complete**: All acceptance criteria met, documented, and verified

### When to Update Progress

Update progress at these checkpoints:

1. **Starting a stage:**
   - Change status from "Planning" to "In Progress"
   - Add "Started: YYYY-MM-DD" to Stage Details
   - Update "Current Stage" in header

2. **Stage blocked:**
   - Change status to "Blocked"
   - Add blocker description to Stage Details
   - Update "Blockers" in Current Focus section

3. **Stage unblocked:**
   - Change status back to "In Progress"
   - Remove blocker description
   - Update "Blockers" in Current Focus

4. **Stage complete:**
   - Change status to "Complete"
   - Add "Completed: YYYY-MM-DD" to Stage Details
   - Add links to key artifacts (design doc, ADRs, tech debt)
   - Update "Overall Progress" percentage

### Updating Overall Progress

Calculate progress as:
```
Progress = (Completed Stages / Total Stages) * 100
```

Or more nuanced:
```
Progress = (Sum of stage weights * completion) / Total weight
```

**Example:**
```markdown
**Overall Progress**: 40% (2/5 stages complete)

| Stage | Weight | Status | Progress |
|-------|--------|--------|----------|
| 0 | 1 | Complete | 100% |
| 1 | 2 | Complete | 100% |
| 2 | 3 | In Progress | 60% |
| 3 | 2 | Planning | 0% |
| 4 | 1 | Planning | 0% |

Weighted Progress: (1*1 + 2*1 + 3*0.6 + 2*0 + 1*0) / (1+2+3+2+1) = 4.8/9 = 53%
```

### Updating Current Focus

The "Current Focus" section should always reflect the active work:

```markdown
## Current Focus

**Active Stage**: Stage 2
**Current Objective**: Implementing user authentication
**Blockers**: None
**Next Milestone**: Complete auth flow E2E tests
```

Update this section whenever:
- Active stage changes
- Current objective changes
- Blockers are added or removed
- A milestone is reached

---

## Roadmap Maintenance Best Practices

### Keep It Updated

- Update at every stage transition
- Review weekly even if no changes
- Always record changes in Roadmap History

### Keep It Honest

- If a stage is stuck, mark it "Blocked" and explain why
- Don't artificially inflate progress
- Record actual dependencies, not aspirational ones

### Keep It Visible

- The roadmap is the first thing a new agent should read
- Current Focus should answer "what do I do next?"
- Dependency Graph should be clear and accurate

---

## Quick Reference

### Roadmap File Location
```
docs/stages/stage-roadmap.md
```

### Status Values
| Status | Meaning |
|--------|---------|
| Planning | Not started |
| In Progress | Active development |
| Review | Implementation done, under review |
| Blocked | Cannot proceed |
| Complete | Finished and verified |

### Priority Levels
| Priority | Meaning |
|----------|---------|
| P0 | Must complete for MVP |
| P1 | Important for complete experience |
| P2 | Nice to have |
| P3 | Future consideration |

### Key Update Triggers
- Stage starts -> Update status to "In Progress"
- Stage blocked -> Update status to "Blocked", add blocker description
- Stage completes -> Update status to "Complete", add completion date
- Stage added -> Update all sections, record in history
- Stage reordered -> Renumber files, update all references, record in history

---

## Reference

For templates and related skills:
- `/data/works/play/sbd/.claude/skills/rdd-templates.md` - Document templates including Roadmap Template
- `/data/works/play/sbd/.claude/skills/rdd-core.md` - Core RDD concepts and workflow
