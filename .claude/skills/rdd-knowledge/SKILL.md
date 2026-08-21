---
name: rdd-knowledge
description: Manage knowledge artifacts - record ADRs, track technical debt, generate handoff documents
---

# RDD Knowledge Management Skill

> **Core Philosophy**: Technical debt must be visible, not managed as tacit knowledge. New agents can bootstrap from documentation alone.

## Overview

Knowledge management is a critical component of RDD that ensures continuity across sessions and enables seamless handoffs between agents. This skill covers how to record autonomous decisions (ADRs), manage technical debt, generate handoff documents, and maintain context persistence.

**Why Knowledge Management Matters:**
- Enables any agent to pick up where the previous left off
- Makes implicit knowledge explicit and discoverable
- Provides audit trail for decisions and their rationale
- Prevents knowledge loss during transitions
- Supports autonomous operation with minimal human intervention

---

## ADR Management (Architecture Decision Records)

### What is an ADR?

An ADR documents a significant technical decision made autonomously during development. Unlike traditional ADRs, RDD ADRs must always include "Impact on Subsequent Stages" to ensure continuity.

### When to Record an ADR

Record an ADR when:
- Choosing between multiple implementation approaches
- Making a decision that affects future stages
- Introducing a constraint or limitation
- Changing a previous architectural decision
- Deferring work (creating technical debt)
- Selecting a third-party library or dependency
- Modifying the Roadmap

### ADR Workflow

```
1. Decision Point Identified
   |
   v
2. Document Background
   - What circumstances led to this decision
   - What options were considered
   |
   v
3. Record Decision
   - What path was chosen
   - Why it was selected
   |
   v
4. Document Impact (REQUIRED)
   - Specific impact on future work
   - What this enables or constrains
   - Any technical debt introduced
   |
   v
5. Update Related Docs
   - stage-N.md (implementation differences)
   - technical-debt.md (if debt created)
   - next-steps.md (if roadmap affected)
```

### ADR File Location

ADRs are recorded in `docs/08-autonomous-decisions.md` (or `docs/autonomous-decisions.md`).

### ADR Template

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

### ADR Best Practices

1. **Be Specific About Impact**: "Impact on Subsequent Stages" cannot be vague. Include concrete implications.

2. **Record Alternatives**: Always document what alternatives were considered and why they were rejected.

3. **Link to Evidence**: Reference relevant code, discussions, or external resources.

4. **Keep Chronological Order**: Add new ADRs at the end of the file with incrementing decision numbers.

5. **Cross-Reference**: Link to related ADRs, stage documents, and tech debt entries.

### ADR Examples

**Good ADR:**
```markdown
### Decision 3: Use SQLite for Local Caching

**Background**: Stage 2 requires caching API responses to reduce latency and support offline mode. Multiple storage options were available.

**Decision**: Use SQLite as the local caching layer.

**Rationale**: SQLite provides ACID compliance, is built into Python, requires no additional server, and supports the query patterns we need. It's simpler than PostgreSQL for local use and more capable than JSON files.

**Impact on Subsequent Stages**:
- Stage 3 can rely on cached data being available offline
- Migration path needed if we later require multi-process writes (documented as TD-05)
- Cache invalidation strategy will need to be defined in Stage 4

**Date**: 2024-01-15

**Related Stage**: Stage 2

**Alternatives Considered**:
1. JSON files: Too simple, no query support, concurrent access issues
2. PostgreSQL: Overkill for local caching, requires server setup
3. Redis: Requires additional infrastructure, overkill for this use case
```

**Bad ADR (Impact too vague):**
```markdown
### Decision 3: Use SQLite for Local Caching

**Background**: Stage 2 requires caching API responses.

**Decision**: Use SQLite as the local caching layer.

**Rationale**: It's simple and works well.

**Impact on Subsequent Stages**: This will affect future stages. (TOO VAGUE)

**Date**: 2024-01-15
```

---

## Technical Debt Management

### What is Technical Debt?

Technical debt represents compromises made during development that need future attention. RDD requires all known gaps to be explicitly recorded, not managed as tacit knowledge.

### Debt Categories

| Priority | Definition | Examples |
|----------|------------|----------|
| **Blocking** | Prevents other work | Missing API, broken build |
| **Degraded Functionality** | Works but imperfect | Slow performance, missing edge cases |
| **Technical Optimization** | Code quality issues | Missing tests, poor naming |

| Level | Scope |
|-------|-------|
| **Architecture-level** | Affects multiple modules or system structure |
| **Module-level** | Affects a single module or component |
| **Local** | Affects a single file or function |

### Debt Sources

| Source | Description |
|--------|-------------|
| **Proactive prototype compromise** | Intentional shortcut during prototyping |
| **Review deferred** | Issue found in review but deferred |
| **Autonomous decision compromise** | Trade-off made during autonomous work |

### When to Record Tech Debt

Record technical debt when:
- Implementing a known workaround
- Deferring work to a later stage
- Making a compromise for expediency
- Review identifies non-blocking issues
- Design constraints force suboptimal solutions
- Test coverage is intentionally reduced

### Tech Debt Workflow

```
1. Debt Identified
   |
   v
2. Categorize
   - Priority: Blocking / Degraded / Optimization
   - Level: Architecture / Module / Local
   - Source: Prototype / Review / Decision
   |
   v
3. Document
   - Original description (quote from source)
   - Source file and line number
   - Impact and resolution cost
   |
   v
4. Plan Resolution
   - Target stage or "Special iteration"
   - Resolution approach
   |
   v
5. Update Stage Docs
   - Record in stage-N.md known limitations
   - Add to stage roadmap if blocking
```

### Tech Debt File Location

Tech debt is recorded in `docs/12-technical-debt.md` (or `docs/technical-debt.md`).

### Tech Debt Template

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

### Tech Debt Best Practices

1. **Quote Original Source**: Always include the exact text from the document where the debt was identified.

2. **Be Specific About Location**: Include file paths and line numbers when applicable.

3. **Estimate Resolution Stage**: Plan when debt should be resolved to prevent accumulation.

4. **Track Resolution**: Update the "Resolved Date" when debt is addressed.

5. **Regular Review**: During each stage planning, review the debt ledger to decide what to address.

### Resolving Tech Debt

When resolving technical debt:

```markdown
### TD-05: Single-threaded SQLite Access

- **Priority**: Degraded Functionality / Module-level
- **Source**: Autonomous decision compromise (Stage 2)
- **Original Description**: "SQLite may have issues with concurrent writes if multi-process access is needed later"
- **Source File**: `src/cache.py:45`
- **Suggested Resolution Stage**: Stage 4
- **Impact**: Prevents multi-process caching scenarios
- **Resolution Cost Estimate**: Medium
- **Created Date**: 2024-01-15
- **Resolved Date**: 2024-02-01

#### Notes
Initially deferred to focus on single-process use case. Stage 4 introduces worker processes that need cache access.

#### Resolution Plan
Migrate to SQLite WAL mode and implement connection pooling.

#### Resolution (Added 2024-02-01)
Implemented connection pooling with WAL mode. All tests pass. Multi-process caching now supported.
```

---

## Handoff Generation

### When to Generate Handoff

Generate handoff documentation:
- Before ending a development session
- When switching between agents
- When encountering a blocker requiring human intervention
- At stage boundaries
- When requesting review

### Handoff File Location

Handoff documents are saved to `docs/handoff/handoff-latest.md`. Archive previous handoffs as `handoff-YYYY-MM-DD-HHMM.md`.

### Handoff Workflow

```
1. Prepare for Handoff
   |
   v
2. Document Current State
   - Current stage and gate
   - Progress percentage
   - Completed work
   |
   v
3. List Completed Evidence
   - Artifacts created
   - Tests passed
   - Docs updated
   |
   v
4. Identify Blockers
   - Current blockers
   - Known risks
   - Mitigation strategies
   |
   v
5. Define Next Single Action
   - One specific, actionable next step
   - Clear execution instructions
   - Expected outcome
   |
   v
6. Add Context for New Agent
   - Key decisions made
   - Important implicit knowledge
   - Files to read first
```

### Handoff Template

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
1. **First Degradation**: [Specific action]
2. **Second Degradation**: [Specific action]
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

### Handoff Best Practices

1. **Be Specific About Next Action**: The "Next Single Action" should be so clear that any agent can execute it without additional context.

2. **Include Degradation Strategy**: Define what to do if progress stalls, enabling autonomous recovery.

3. **Document Implicit Knowledge**: Write down things that seem obvious but might not be to a new agent.

4. **Archive Previous Handoffs**: Keep history by renaming old handoffs with timestamps.

5. **Include Time Estimates**: Help the next agent understand the scope of work remaining.

---

## Context Persistence

### What is Context Persistence?

Context persistence ensures that critical information survives across sessions, enabling any agent to continue work without requiring human explanation of history.

### Files for Context Persistence

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `docs/stages/stage-roadmap.md` | Overall project plan | When stages change |
| `docs/stages/stage-N.md` | Current stage details | During stage execution |
| `docs/autonomous-decisions.md` | ADRs | When decisions made |
| `docs/technical-debt.md` | Tech debt ledger | When debt created/resolved |
| `docs/handoff/handoff-latest.md` | Session handoff | Every session |
| `docs/next-steps.md` | Immediate next actions | Frequently |
| `CHANGELOG.md` | Project history | Every stage completion |

### Context Loading Sequence

When starting a new session, read files in this order:

```
1. docs/stages/stage-roadmap.md
   - Understand overall project state
   - Identify current stage

2. docs/handoff/handoff-latest.md
   - Get immediate context
   - Find next single action
   - Understand blockers

3. docs/stages/stage-N.md
   - Deep dive into current stage
   - Review goals and acceptance criteria

4. docs/autonomous-decisions.md
   - Understand key decisions
   - Learn why choices were made

5. docs/technical-debt.md
   - Identify pending debt
   - Plan debt resolution

6. docs/next-steps.md
   - Get specific next actions
```

### Context Update Triggers

Update context files when:

| Event | Files to Update |
|-------|-----------------|
| Starting a stage | stage-roadmap.md, stage-N.md, next-steps.md |
| Making a decision | autonomous-decisions.md, stage-N.md |
| Creating debt | technical-debt.md, stage-N.md |
| Resolving debt | technical-debt.md, CHANGELOG.md |
| Completing a gate | stage-N.md, next-steps.md |
| Ending a session | handoff-latest.md, next-steps.md |
| Completing a stage | All files, CHANGELOG.md |

### fresh-agent-check

Before completing a stage, verify that a fresh agent can take over:

```
fresh-agent-check:
  1. Read only the documentation (no code)
  2. Can you understand:
     - What the project does?
     - What the current stage is?
     - What needs to be done next?
     - Why previous decisions were made?
  3. If any question is "no", update documentation
```

### Context Persistence Best Practices

1. **Update Synchronously**: Never leave docs pending. Update documentation as part of the work, not after.

2. **Be Comprehensive**: Include enough detail that someone unfamiliar with the project can understand.

3. **Cross-Reference**: Link related documents so context is discoverable.

4. **Keep History**: Don't delete old information; mark it as historical or superseded.

5. **Use Consistent Format**: Follow templates so agents know where to find information.

---

## Integration with Other Skills

This skill integrates with:

- **rdd-core**: Core RDD principles and workflow
- **rdd-templates**: Document templates for all file types

### Commands

| Command | Purpose |
|---------|---------|
| `/rdd-knowledge adr` | Record a new ADR |
| `/rdd-knowledge debt` | Record new tech debt |
| `/rdd-knowledge handoff` | Generate handoff document |
| `/rdd-knowledge check` | Run fresh-agent-check |

---

## Checklist: Knowledge Management

### When Making a Decision
- [ ] Document background and circumstances
- [ ] Record the decision clearly
- [ ] Explain rationale with alternatives considered
- [ ] Include specific impact on subsequent stages
- [ ] Link to related stage document
- [ ] Add to autonomous-decisions.md

### When Creating Tech Debt
- [ ] Categorize priority and level
- [ ] Identify source (prototype/review/decision)
- [ ] Quote original description
- [ ] Specify source file and line
- [ ] Estimate resolution stage
- [ ] Document impact and resolution cost
- [ ] Add to technical-debt.md

### When Generating Handoff
- [ ] Document current progress and gate
- [ ] List all completed evidence
- [ ] Identify blockers and risks
- [ ] Define single next action with steps
- [ ] Include degradation strategy
- [ ] Add context for new agent
- [ ] Update tech debt status
- [ ] Archive previous handoff

### When Updating Context
- [ ] Update appropriate files synchronously
- [ ] Maintain cross-references
- [ ] Follow templates consistently
- [ ] Run fresh-agent-check before stage completion

---

## Reference

For detailed specifications, see:
- `prompt.md` - Full RDD specification
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-templates/SKILL.md` - Document templates
