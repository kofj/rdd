---
description: "Execute a complete RDD stage autonomously through all 5 quality gates with verification"
examples:
  - "/rdd-stage-auto              # Execute current stage"
  - "/rdd-stage-auto 3            # Execute stage 3"
  - "/rdd-stage-auto --resume     # Resume interrupted stage"
---

# RDD Stage Auto Command

Execute a complete RDD Stage autonomously with gate verification.

## Usage

```
/rdd-stage-auto [stage-number] [--resume] [--gate N]
```

## Description

This command executes a complete stage from start to finish, following all RDD gates:

```
GATE 0: Stage Startup Check
    ↓
GATE 1: Design Document Pre-Check
    ↓
GATE 2: Design Review (Before Coding)
    ↓
GATE 3: Implementation & Testing
    ↓
GATE 4: Code Review (After E2E Pass)
    ↓
GATE 5: Completion Gate Check
```

## Arguments

- `stage-number`: The stage to execute (uses current stage if not specified)
- `--resume`: Resume from last gate if interrupted
- `--gate N`: Start from specific gate (for debugging/resume)

## Behavior

### Gate 0: Stage Startup Check

- Verify roadmap exists
- Check dependencies are complete
- Load context (ADRs, tech debt, previous stages)
- Check for existing stage document

### Gate 1: Design Document Pre-Check

- Verify design document exists
- Check completeness of all required sections
- Detect scope creep
- Generate design doc if missing

### Gate 2: Design Review

- Trigger multi-model review
- Apply AI pre-filter (expect ~50% false positives)
- Verify findings independently
- Create review log
- Fix critical/high findings

### Gate 3: Implementation & Testing

- Implement following design
- Write unit tests (>= 20% coverage)
- Write E2E tests (>= 2 high-signal paths)
- Verify in real environment
- Verify in clean environment
- Document implementation differences

### Gate 4: Code Review

- Trigger multi-model code review
- Apply filters and verify findings
- Fix critical/high issues
- Update review log

### Gate 5: Completion Check

- Verify all acceptance criteria
- Verify test reproducibility
- Check design-implementation alignment
- Update all documents
- Run fresh-agent-check
- Trigger Hook notification

## Examples

```
/rdd-stage-auto              # Execute current stage
/rdd-stage-auto 3            # Execute stage 3
/rdd-stage-auto --resume     # Resume interrupted stage
/rdd-stage-auto --gate 3     # Start from implementation
```

## Interrupted Execution

If execution is interrupted:

1. Handoff document is generated at `docs/handoff/handoff-latest.md`
2. Hook notification sent (P2)
3. Resume with `--resume` flag

## Error Handling

| Error Type | Action |
|------------|--------|
| Gate failure | Stop, document, retry or escalate |
| Test failure | Auto-retry 3 times, then degrade |
| Blocker | Stop, create handoff, notify (P1) |
| Fatal | Stop immediately, notify (P0) |

## Stage Completion

Upon successful completion:

1. Status updated to "Complete"
2. Changelog entry added
3. Tech debt ledger updated
4. ADR recorded
5. Next stage identified
6. Hook notification sent (P2)

## See Also

- `/rdd-roadmap` - View and manage roadmap
- `/rdd-review-auto` - Trigger review separately
- `/rdd-knowledge` - Record decisions and debt
- `rdd-stage-auto` skill in `.claude/skills/rdd-stage-auto.md`
