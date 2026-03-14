# AGENTS.md - AI Agent Entry Point

> This is the main entry point for AI agents working with this RDD project.
> Read this document first to understand the project context and rules.

---

## Quick Start

**If you are new to this project, follow this reading order:**

1. **docs/11-next-steps.md** - Current status and next steps (READ FIRST)
2. **docs/01-charter.md** - Project vision and boundaries
3. **docs/02-engineering-principles.md** - Development principles and quality standards
4. **docs/03-stage-based-development.md** - Stage progression methodology
5. **docs/10-review-practices.md** - Multi-model review methodology
6. **docs/12-technical-debt.md** - Current technical debt overview
7. **docs/08-autonomous-decisions.md** - Historical autonomous decisions and hypothesis deviations

---

## RDD Core Principles

### The RDD Formula

```
RDD = Roadmap (Human-led)
    + Stage (Minimal Delivery Unit)
    + Gate (Five-Layer Checkpoint)
    + Knowledge (Explicit Knowledge Management)
    + Hook (Human Intervention Notification)
```

### Human-Agent Division

| Domain | Human Responsibility | Agent Responsibility |
|--------|---------------------|----------------------|
| Roadmap | Define vision, plan routes, adjust priorities | Extract goals, execute Stages |
| Stage Boundary | Approve key Stages, handle exceptions | Generate design docs, implement & verify |
| Review | Verify low-confidence findings | AI pre-filter, rule-based filtering |
| Tech Debt | Judge priorities | Auto-discover, ledger management |
| Documentation | Approve key decisions | Auto-generate, sync updates |

---

## Stage Completion Checklist

Before marking any Stage as complete, verify ALL items below:

### Gate 1: Design Document Check

- [ ] Design document is complete
- [ ] Goals are clearly defined
- [ ] Non-goals are explicitly stated
- [ ] Acceptance criteria are testable
- [ ] Rollback plan exists

### Gate 2: Design Review Check

- [ ] Multi-model review has been triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

### Gate 3: Implementation & Testing Check

- [ ] Implementation is complete
- [ ] Unit test coverage >= 20%
- [ ] E2E tests: at least 2 high-signal paths
- [ ] Real environment verification (not mock)
- [ ] Clean environment secondary verification passed

### Gate 4: Code Review Check

- [ ] Triangulation complete: main dev + independent reviewer + rule check
- [ ] All blocking findings resolved
- [ ] All acceptance criteria met

### Gate 5: Completion Gate Check

- [ ] Main hypotheses verified or falsified
- [ ] Tests are reproducible via Task entry point
- [ ] No undocumented manual steps
- [ ] Implementation matches design (differences documented)
- [ ] New capabilities have CLI subcommands (if applicable)
- [ ] Tech debt ledger updated
- [ ] ADR recorded ("Impact on subsequent Stages" MUST NOT be empty)
- [ ] fresh-agent-check passed

---

## Document Update Obligations

When a Stage completes, you MUST update these documents simultaneously:

| Document | Update Content | Timing |
|----------|----------------|--------|
| `docs/stages/stage-N.md` | Implementation differences, acceptance criteria changes | Stage completion |
| `docs/stages/stage-N-review-log.md` | Findings, adoption/rejection reasons | Review completion |
| `docs/08-autonomous-decisions.md` | ADR, hypothesis deviations | When decisions occur |
| `docs/12-technical-debt.md` | New/resolved tech debt | Stage completion |
| `docs/11-next-steps.md` | Progress, next entry conditions | Stage completion |
| `CHANGELOG.md` | Stage change summary | Stage completion |

### Anti-Corrosion Rules for Documentation

1. **Immediate Update**: Update immediately when design deviations are discovered, don't wait for Stage end
2. **Substantive Content**: Must have specific content, cannot just write "TBD"
3. **Version Refresh**: All "current status" fields must be synchronized

---

## Review Rules

### Review Timing

| Type | When | Purpose | Output |
|------|------|---------|--------|
| Design Review | Before coding | Validate design rationality | Optimized design doc |
| Code Review | After E2E passes | Validate implementation quality | Review log |

### False Positive Rate

**Approximately 50% of review findings are false positives.**

This means:
- Do NOT blindly accept all findings
- Each finding must be independently verified
- Do NOT rely on "multi-model consensus" to judge correctness

### Verification Priority

```
Authoritative Sources > Code Verification > Query Model
```

| Method | Description | Applicable Scenarios |
|--------|-------------|----------------------|
| Authoritative Sources | Check official docs, specs, best practices | Standards/specs questions |
| Code Verification | Run tests, check call chains | Reproducible issues |
| Query Model | Ask reviewer for more explanation | Need clarification |

### Review DO/DON'T

```
DO:
- First round review without dimension hints
- Independently verify each finding
- Record verification process and results
- Query clarification for uncertain findings
- Extract tech debt from reviews
- Use colleague mode for discussions

DON'T:
- Blindly accept all findings
- Rely on "multi-model consensus" for correctness
- Skip verification and accept directly
- Give check dimensions in first prompt
- Use worker mode for reviews
- Skip recording verification reasons
```

---

## Forbidden Behaviors (9 Rules)

| # | Forbidden Behavior | Correct Practice |
|---|--------------------|--------------------|
| 1 | Starting implementation without design document | Must complete design doc first, then code |
| 2 | Silent scope expansion | Stop immediately when detected, update docs first |
| 3 | Claiming completion with "docs to be added" status | Docs must be synced, no later additions |
| 4 | Multiple core unknowns in one Stage | Each Stage validates only a small set of clear hypotheses |
| 5 | Relying on "word of mouth" to run tests | Tests must be reproducible via Task entry point |
| 6 | Writing scripts with hidden platform assumptions | Environment assumptions must be explicitly documented |
| 7 | Introducing broad interfaces before understanding runtime constraints | Verify constraints first, then design interfaces |
| 8 | Putting expensive checks into default edit loop early | Expensive checks should be explicitly triggered, not default |
| 9 | Managing tech debt as implicit knowledge | All known gaps MUST be explicitly recorded in ledger |

---

## Notification Triggers

When these situations occur, notifications are sent with different priority levels:

| Trigger | Level | Blocks Agent? | Action |
|---------|-------|---------------|--------|
| Roadmap Change | P0 | ✅ Yes | Pause, wait for human approval |
| Consecutive Failures | P0 | ✅ Yes | Pause, wait for human intervention |
| Hypothesis Falsified | P0 | ✅ Yes | Pause, wait for human decision |
| Model Disagreement | P1 | ❌ No | Notify human, continue execution |
| Tech Debt Threshold | P1 | ❌ No | Notify human, continue execution |
| Stage Complete | P2 | ❌ No | Send notification, **AUTO-CONTINUE** to next stage |
| Daily Report | P3 | ❌ No | Report only, **AUTO-CONTINUE** |
| Weekly Report | P3 | ❌ No | Report only, **AUTO-CONTINUE** |
| Milestone Reached | P3 | ❌ No | Report only, **AUTO-CONTINUE** |

### AUTO-CONTINUE Behavior

For P2/P3 notifications (non-blocking):
1. Send notification to configured channels
2. Log progress to `docs/11-next-steps.md`
3. **Immediately proceed** to next stage/task
4. **Do NOT wait** for human acknowledgment or response

For P0/P1 notifications:
- **P0**: Pause all work, generate handoff document, wait for human response
- **P1**: Continue with caution, log the notification, human may review later

---

## Key Paths

```
project/
├── AGENTS.md                 # This file - agent entry point
├── CLAUDE.md                 # Claude Code specific entry point
├── CHANGELOG.md              # Change log
├── Taskfile.yml              # Unified task entry point
├── docs/
│   ├── 01-charter.md         # Project charter
│   ├── 02-engineering-principles.md  # Engineering principles
│   ├── 03-stage-based-development.md # Stage methodology
│   ├── 08-autonomous-decisions.md    # ADR log
│   ├── 10-review-practices.md        # Review methodology
│   ├── 11-next-steps.md              # Current status (READ FIRST)
│   ├── 12-technical-debt.md          # Tech debt ledger
│   └── stages/                       # Stage documents
│       ├── stage-roadmap.md          # Roadmap
│       └── stage-N.md                # Stage design docs
└── .rdd/                     # RDD configuration
    ├── config.yml            # Main config
    └── hooks.yml             # Hook notifications
```

---

## Quick Reference

### ADR Format

```markdown
### Decision N: [Title]

**Background**: What triggered this decision

**Decision**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (MUST NOT be empty)
```

### Tech Debt Format

```markdown
### TD-NN: Short Title

- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architectural/Module/Local]
- **Source**: [Prototype compromise / Review deferred / Autonomous decision] (Stage N)
- **Original Description**: (Quote original document)
- **Source File**: (File path and line number)
- **Suggested Stage**: (Stage N or "Dedicated" or "As Needed")
```

### Handoff Format

```markdown
## Current Progress
- Stage:
- Progress Percentage:

## Completed Evidence
- [Link 1]
- [Link 2]

## Blockers and Risks
- [Blocker description]

## Next Single Action
- [Specific action description]

## Degradation Strategy
If no progress in 30 minutes, trigger [degradation strategy]
```

---

## For New Agents

If you are a new agent taking over this project:

1. **Read** `docs/11-next-steps.md` to understand current status
2. **Read** `docs/01-charter.md` to understand project vision
3. **Read** current Stage document to understand ongoing work
4. **Check** `docs/08-autonomous-decisions.md` for key decisions
5. **Check** `docs/12-technical-debt.md` for known issues
6. **Verify** you can run tests via `task test`

---

> **Remember**: The core of RDD is "Human lays tracks (Roadmap), Agent moves along tracks automatically." Your job is to execute Stages according to the Roadmap, with full documentation and quality checks.
