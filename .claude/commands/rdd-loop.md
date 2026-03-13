---
description: "Control autonomous stage execution loop - start, pause, resume, monitor multi-stage progression"
examples:
  - "/rdd-loop start                    # Start autonomous execution"
  - "/rdd-loop start --max-stages 3     # Complete up to 3 stages"
  - "/rdd-loop status                   # Check current state"
  - "/rdd-loop pause                    # Pause at checkpoint"
---

# RDD Loop Command

Control the autonomous stage execution loop.

## Usage

```
/rdd-loop [command] [options]
```

## Commands

| Command | Description |
|---------|-------------|
| `start` | Begin autonomous execution |
| `pause` | Pause at next checkpoint |
| `resume` | Continue from pause |
| `status` | Report current state |
| `escalate` | Force escalation to human |
| `skip` | Skip current step (with documentation) |

## Start Command

Begin autonomous stage execution:

```
/rdd-loop start [--stage N] [--max-stages N]
```

Options:
- `--stage N`: Start from specific stage
- `--max-stages N`: Maximum stages to complete (default: 1)
- `--notify`: Enable Hook notifications

### Behavior

```
[IDLE] → [INITIALIZING] → [RUNNING]
                              ↓
                         [PAUSED] ←→ [RECOVERING]
                              ↓           ↓
                         [ESCALATED] ←────┘
                              ↓
                         [COMPLETE]
```

## Pause Command

Pause execution at next checkpoint:

```
/rdd-loop pause [--reason "Reason"]
```

Options:
- `--reason`: Why pausing

Pauses at:
- End of current gate
- Before starting next stage
- After completing a task

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

Output includes:
- Current state (IDLE/RUNNING/PAUSED/ESCALATED/COMPLETE)
- Current stage and gate
- Progress percentage
- Time since last action
- Recent actions log
- Any blockers

## Escalate Command

Force escalation to human:

```
/rdd-loop escalate --reason "Reason" --priority P0
```

Options:
- `--reason`: Why escalating (required)
- `--priority`: P0/P1/P2 (default: P1)

Behavior:
1. Stops current work
2. Creates handoff document
3. Sends Hook notification
4. Enters ESCALATED state
5. Waits for human input

## Skip Command

Skip current step with documentation:

```
/rdd-loop skip --reason "Reason" --document
```

Options:
- `--reason`: Why skipping (required)
- `--document`: Record as tech debt

Use sparingly - skipping should only happen when:
- Step is blocked by external dependency
- Alternative path is available
- Step is no longer relevant

## State Machine

```
┌─────────────┐
│    IDLE     │
└──────┬──────┘
       │ start
       ▼
┌─────────────┐
│ INITIALIZING│
└──────┬──────┘
       │
       ▼
┌─────────────┐     pause     ┌─────────────┐
│   RUNNING   │──────────────▶│   PAUSED    │
└──────┬──────┘               └──────┬──────┘
       │                              │
       │ error/retry                  │ resume
       ▼                              ▼
┌─────────────┐               ┌─────────────┐
│ RECOVERING  │◄──────────────│   PAUSED    │
└──────┬──────┘               └─────────────┘
       │
       │ max retries
       ▼
┌─────────────┐     human     ┌─────────────┐
│  ESCALATED  │◄──────────────│   PAUSED    │
└──────┬──────┘               └─────────────┘
       │
       │ human response
       ▼
┌─────────────┐
│   RUNNING   │
└──────┬──────┘
       │
       │ stage complete
       ▼
┌─────────────┐
│  COMPLETE   │
└─────────────┘
```

## Stale Detection

Automatic escalation based on no progress:

| Duration | Action |
|----------|--------|
| 15 min | Warning, try alternative |
| 30 min | First degradation |
| 45 min | Second degradation |
| 60 min | Escalate (P0) |

## Examples

```
/rdd-loop start                    # Start autonomous execution
/rdd-loop start --max-stages 3     # Complete up to 3 stages
/rdd-loop pause                    # Pause at checkpoint
/rdd-loop status                   # Check current state
/rdd-loop escalate --reason "Blocked by API" --priority P0
/rdd-loop resume                   # Continue after pause
```

## Integration with Hooks

The loop automatically triggers Hook notifications:

| Event | Priority |
|-------|----------|
| Stage complete | P2 |
| Stage failed | P1 |
| Max retries exceeded | P1 |
| Escalation | P0/P1 |
| Daily summary | P3 |

## See Also

- `/rdd-stage-auto` - Execute single stage
- `rdd-loop` skill in `.claude/skills/rdd-loop.md`
- `/rdd-knowledge handoff` - Generate handoff when paused
