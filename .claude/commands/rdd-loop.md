---
description: "Autonomous multi-stage execution — auto-detects incomplete stages from roadmap, executes with hard quality gates"
examples:
  - "/rdd-loop                    # Auto-detect all incomplete stages, execute all"
  - "/rdd-loop --to 22            # Stop after Stage 22"
  - "/rdd-loop --from 21          # Start from Stage 21"
  - "/rdd-loop --from 21 --to 22  # Execute only Stage 21-22"
  - "/rdd-loop --parallel 2       # Allow 2 parallel stages (default: 1)"
  - "/rdd-loop status             # Show current progress"
  - "/rdd-loop pause              # Pause at next checkpoint"
  - "/rdd-loop resume             # Resume from last checkpoint"
---

# RDD Loop Command

Autonomous multi-stage execution. Scans roadmap for incomplete stages, resolves dependencies, and executes with hard quality gates.

## Usage

```
/rdd-loop [options]
/rdd-loop status|pause|resume
```

## Default Behavior

**No arguments = auto-detect all incomplete stages from roadmap and execute them.**

```
/rdd-loop
```

Scans `docs/stages/stage-roadmap.md`, finds all stages not marked `✅ Completed`, resolves dependency ordering, and executes from first incomplete to last.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--from N` | Start from stage N | first incomplete |
| `--to M` | Stop after stage M | last incomplete |
| `--parallel N` | Max parallel stages | 1 (sequential) |

`--from` and `--to` are **optional filters**. Omit them to execute all pending stages.

## Control Commands

| Command | Description |
|---------|-------------|
| `/rdd-loop status` | Show progress dashboard |
| `/rdd-loop pause` | Pause at next checkpoint |
| `/rdd-loop resume` | Resume from last checkpoint |

## Execution Pipeline (per stage)

```
Gate 0: Startup Check → Gate 1: Design → Gate 2: Design Review
  → Gate 3: Implementation & Testing (hardened: real test/lint/fmt)
  → Gate 4: Code Review → Gate 5: Completion
```

**Gate 3 is hardened**: runs `task test:unit`, `task test:e2e`, `task test:coverage`, `task lint:check`, `task fmt:check`. Non-zero exit blocks progression.

## Persistence

State saved atomically at every key action:

| Trigger | What |
|---------|------|
| Gate enter/exit | checkpoint (`loop-state.yaml`) |
| Decision made | ADR (`docs/08-autonomous-decisions.md`) |
| Tech debt found | ledger (`docs/12-technical-debt.md`) |
| Every 5 min | heartbeat snapshot |
| Error/crash | full state preserved for recovery |

Recovery reads `loop-state.yaml` (canonical), falls back to `checkpoints.json` (single-stage compat).

## gotask Convergence

All new scripts created during execution must be registered as `task` entries in `Taskfile.yml`. The `task registry:verify` check runs in Gate 3. Orphan commands block progression.

## Examples

```
# Default: execute all pending stages
/rdd-loop

# Execute stages 19 through 22, 2 in parallel
/rdd-loop --from 19 --to 22 --parallel 2

# Show progress dashboard
/rdd-loop status

# Pause at next gate boundary
/rdd-loop pause

# Resume from checkpoint
/rdd-loop resume
```

## Notification Levels

| Level | Behavior |
|-------|----------|
| P2 (stage complete) | Send notification, **auto-continue** |
| P1 (failure, retries exceeded) | Send notification, continue with caution |
| P0 (fatal, core falsified) | **Block**, wait for human |

## See Also

- `/rdd-stage-auto` — Execute single stage
- `/rdd-roadmap` — View roadmap
- `docs/stages/stage-22.md` — Design document
- `docs/stages/stage-22-review-log.md` — Review findings
