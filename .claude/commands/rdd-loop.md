---
description: "Control autonomous stage execution loop - start, pause, resume, monitor multi-stage progression with parallel execution"
examples:
  - "/rdd-loop start                    # Start autonomous execution"
  - "/rdd-loop start --from 19 --to 22  # Execute stages 19-22"
  - "/rdd-loop start --parallel 2       # Execute up to 2 stages in parallel"
  - "/rdd-loop start --goal \"完成认证功能\"  # Natural language goal parsing"
  - "/rdd-loop status                   # Check current state"
---

# RDD Loop Command

Control autonomous stage execution loop with multi-stage and parallel execution support.

## Usage

```
/rdd-loop [command] [options]
```

## Commands

| Command | Description | Blocking? |
|---------|-------------|-----------|
| `start` | Begin autonomous execution | No |
| `pause` | Pause at next checkpoint (explicit human command) | Yes |
| `resume` | Continue from pause | No |
| `status` | Report current state | No |
| `escalate` | Force escalation to human | Yes (P0) / No (P1/P2) |
| `skip` | Skip current step (with documentation) | No |
| `plan` | Show execution plan without running | No |

## Start Command

Begin autonomous stage execution:

```
/rdd-loop start [options]
```

### Range Execution Options

- `--from N`: Start from stage N
- `--to M`: Execute until stage M
- `--stages N1,N2,...`: Execute specific stages

### Parallel Execution Options

- `--parallel N`: Maximum parallel stages (default: 1, max: 3)
- `--worktree`: Use git worktrees for isolation
- `--no-worktree`: Disable worktree isolation

### Goal-Based Options

- `--goal "description"`: Natural language goal to parse into stages

### General Options

- `--stage N`: Start from specific stage (legacy, use --from)
- `--max-stages N`: Maximum stages to complete (default: 1)
- `--notify`: Enable Hook notifications
- `--dry-run`: Show plan without executing

### Examples

```
# Single stage execution
/rdd-loop start                    # Start from current stage
/rdd-loop start --stage 3          # Start from stage 3

# Range execution
/rdd-loop start --from 19 --to 22  # Execute stages 19-22
/rdd-loop start --stages 19,21,22  # Execute specific stages

# Parallel execution
/rdd-loop start --from 19 --to 22 --parallel 2  # Up to 2 parallel stages
/rdd-loop start --from 19 --to 22 --parallel 2 --worktree  # With worktree isolation

# Goal-based execution
/rdd-loop start --goal "完成用户认证功能"  # Parse goal into stages
/rdd-loop start --goal "Add authentication system"

# Dry run (plan only)
/rdd-loop start --from 19 --to 22 --dry-run  # Show execution plan
```

## Plan Command

Show execution plan without running:

```
/rdd-loop plan --from N --to M [--parallel N]
```

Shows:
- Stage dependency graph
- Parallel execution opportunities
- Estimated duration
- Worktree allocation plan

### Example Output

```
Execution Plan: Stages 19-22

Dependency Graph:
  Stage 19 ─────┐
                ├──► Stage 20 ──┐
  Stage 21 ─────┘               ├──► Stage 22
                               │
                               └──► (final)

Parallel Groups:
  Group 1 (parallel): [Stage 19, Stage 21]
  Group 2 (sequential): [Stage 20]
  Group 3 (sequential): [Stage 22]

Worktree Allocation:
  Stage 19 → .rdd/worktrees/stage-19-abc123/
  Stage 21 → .rdd/worktrees/stage-21-def456/

Estimated Duration:
  Parallel: 3 stages with max 2 parallel = ~2 hours
  Sequential: 4 stages = ~4 hours
```

## Pause Command

Pause execution at next checkpoint (explicit human command only):

```
/rdd-loop pause [--reason "Reason"]
```

Options:
- `--reason`: Why pausing

Pauses at:
- End of current gate (when explicitly requested)
- Before starting next stage (when explicitly requested)
- Before merge operations (in parallel mode)

**Note**: Stage completion and milestones do NOT automatically pause. Use this command explicitly to pause execution.

## Resume Command

Continue from paused state:

```
/rdd-loop resume
```

Continues from last checkpoint.

## Status Command

Report current execution state:

```
/rdd-loop status [--verbose]
```

Options:
- `--verbose`: Show detailed progress

### Output for Parallel Execution

```
RDD Loop Status: RUNNING

Parallel Mode: 2 workers active

┌─────────────────────────────────────────────────────────────┐
│ Stage 19: Command Hints        [████████████] 100% ✅       │
│ Stage 21: TDD/BDD Init         [████████░░░░]  67% 🔄       │
├─────────────────────────────────────────────────────────────┤
│ Stage 20: Help & Workflow      [░░░░░░░░░░░░]   0% ⏳       │
│ Stage 22: Multi-stage          [░░░░░░░░░░░░]   0% ⏳       │
├─────────────────────────────────────────────────────────────┤
│ Progress: 2/4 stages (50%) | ETA: 2h 15m                     │
│ Worktrees: 2/3 active | Merges pending: 0                    │
└─────────────────────────────────────────────────────────────┘

Current Work:
  - Stage 21 Gate 3: Implementation & Testing

Blockers: None
```

## Escalate Command

Force escalation to human:

```
/rdd-loop escalate --reason "Reason" --priority P0
```

Options:
- `--reason`: Why escalating (required)
- `--priority`: P0/P1/P2 (default: P1)

**Blocking behavior by priority**:
- `P0`: Blocks execution, transitions to ESCALATED state, waits for human response
- `P1`: Sends notification, continues execution (does not block)
- `P2`: Sends notification, continues execution (does not block)

In parallel mode, P0 escalation affects all active stages.

## Skip Command

Skip current step with documentation:

```
/rdd-loop skip --reason "Reason" --document
```

Options:
- `--reason`: Why skipping (required)
- `--document`: Record as tech debt

## State Machine

```
┌─────────────┐
│    IDLE     │
└──────┬──────┘
       │ start
       ▼
┌─────────────┐
│ INITIALIZING│ ──► Parse stages, build dependency graph
└──────┬──────┘
       │
       ▼
┌─────────────┐     P2/P3       ┌─────────────┐
│   RUNNING   │────(checkpoint)─►│  CHECKPOINT │
└──────┬──────┘     notification │ (auto-continue)
       │                         └──────┬──────┘
       │                                │ auto-continue
       │ pause (P0)                     │
       ▼                                ▼
┌─────────────┐                  ┌─────────────┐
│   PAUSED    │                  │   RUNNING   │
└──────┬──────┘                  └─────────────┘
       │ error/retry
       ▼
┌─────────────┐
│ RECOVERING  │◄── Retry attempted
└──────┬──────┘
       │ max retries
       ▼
┌─────────────┐     human      ┌─────────────┐
│  ESCALATED  │◄──response──── │   PAUSED    │
└──────┬──────┘                └─────────────┘
       │
       │ human response
       ▼
┌─────────────┐
│   RUNNING   │
└──────┬──────┘
       │
       │ all stages complete
       ▼
┌─────────────┐
│  COMPLETE   │
└─────────────┘
```

### State Definitions

| State | Description | Blocks? |
|-------|-------------|---------|
| IDLE | Loop not started | N/A |
| INITIALIZING | Loading context and validating | N/A |
| RUNNING | Actively executing gates | No |
| CHECKPOINT | Non-blocking checkpoint (P2/P3) | No - auto-continue |
| PAUSED | Blocking pause (P0, human pause cmd) | Yes |
| RECOVERING | Attempting recovery from error | N/A |
| ESCALATED | Waiting for human intervention | Yes |
| COMPLETE | All stages finished | N/A |

## Dependency Analysis

The loop automatically analyzes stage dependencies:

```
Stage Dependencies:
  Stage 19: [] (no dependencies)
  Stage 20: [19] (depends on Stage 19)
  Stage 21: [] (no dependencies, can run parallel with 19)
  Stage 22: [19, 20] (depends on Stages 19 and 20)

Execution Order:
  Parallel Group 1: [Stage 19, Stage 21]
  Parallel Group 2: [Stage 20]
  Parallel Group 3: [Stage 22]
```

## Worktree Management

When using `--worktree`, each parallel stage runs in isolation:

```
.rdd/worktrees/
├── pool.json              # Pool state
├── stage-19-abc123/       # Worktree for Stage 19
│   └── .git               # Git worktree
├── stage-21-def456/       # Worktree for Stage 21
│   └── .git
└── stage-20-ghi789/       # Worktree for Stage 20
    └── .git
```

### Worktree Pool Operations

1. **Allocation**: Create worktree before stage starts
2. **Isolation**: Stage runs in dedicated worktree
3. **Merge**: After stage completes, merge to main
4. **Cleanup**: Remove worktree after successful merge

### Conflict Handling

If merge conflicts occur:
1. Log conflict details
2. Send P1 notification (non-blocking)
3. Continue with other parallel stages if possible
4. Human may resolve at convenience (does not block execution)

## Stale Detection

Automatic escalation based on no progress:

| Duration | Action |
|----------|--------|
| 15 min | Warning, try alternative |
| 30 min | First degradation |
| 45 min | Second degradation |
| 60 min | Escalate (P0) |

In parallel mode, stale detection applies per stage.

## Integration with Hooks

The loop automatically triggers Hook notifications:

| Event | Priority | Blocks? | Behavior |
|-------|----------|---------|----------|
| Stage complete | P2 | ❌ No | Send notification, AUTO-CONTINUE |
| Stage failed | P1 | ❌ No | Send notification, continue with caution |
| Max retries exceeded | P1 | ❌ No | Send notification, continue with caution |
| Escalation (P0) | P0 | ✅ Yes | Pause, wait for human response |
| Escalation (P1/P2) | P1/P2 | ❌ No | Send notification, continue |
| Merge conflict | P1 | ❌ No | Send notification, continue with caution |
| All stages complete | P2 | ❌ No | Send notification, AUTO-CONTINUE |
| Daily summary | P3 | ❌ No | Send notification, AUTO-CONTINUE |
| Milestone reached | P3 | ❌ No | Send notification, AUTO-CONTINUE |

### AUTO-CONTINUE Behavior

For P2/P3 events (stage complete, milestones, reports):
1. Send notification to configured channels
2. Log progress to `docs/11-next-steps.md`
3. **Immediately continue** to next stage/task
4. **Do NOT wait** for human acknowledgment

## See Also

- `/rdd-stage-auto` - Execute single stage
- `/rdd-roadmap deps` - View stage dependencies
- `rdd-loop` skill in `.claude/skills/rdd-loop.md`
- `/rdd-knowledge handoff` - Generate handoff when paused
