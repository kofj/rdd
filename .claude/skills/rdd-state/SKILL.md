---
name: rdd-state
description: RDD state machine reference for tracking user progress and context-aware guidance
disable-model-invocation: true
---

# RDD State Skill

> State machine for tracking user progress and providing context-aware guidance.

## Overview

The `rdd-state` skill manages the state machine that tracks user progress through the RDD workflow. It provides context-aware next-step prompts after each command.

---

## When to Use This Skill

**Triggers:**
- After any RDD command execution
- When user asks "what's next?"
- When generating handoff documents
- When starting a new session

---

## State Machine

### States

| State | Description | Entry Criteria |
|-------|-------------|----------------|
| `init` | Project just initialized | After `/rdd-init` or `/rdd-migrate` |
| `planning` | Roadmap being defined | After init, before first stage |
| `developing` | Active stage execution | Stage started, tests not passed |
| `reviewing` | Code review in progress | Tests passed, review pending |
| `complete` | Stage completed | Gate 5 passed |

### Transitions

```
init ──────► planning ──────► developing ──────► reviewing ──────► complete
  │              │                │                  │               │
  │              │                │                  │               │
  └──────────────┴────────────────┴──────────────────┴───────────────┘
                         (can return to earlier states on failure)
```

### Transition Triggers

| From | To | Trigger |
|------|----|---------|
| `init` | `planning` | Roadmap created |
| `planning` | `developing` | Stage started |
| `developing` | `reviewing` | Tests passed |
| `reviewing` | `complete` | Review passed |
| `reviewing` | `developing` | Review failed |
| `complete` | `planning` | Next stage started |

---

## State File

State is stored in `.rdd/state.yml`:

```yaml
current_state: developing
previous_state: planning
last_command: /rdd-stage-auto
last_updated: 2026-03-13T10:30:00Z

current_stage: 19
current_gate: 3

history:
  - state: init
    timestamp: 2026-03-13T09:00:00Z
    command: /rdd-init
  - state: planning
    timestamp: 2026-03-13T09:15:00Z
    command: /rdd-roadmap
  - state: developing
    timestamp: 2026-03-13T10:00:00Z
    command: /rdd-stage-auto

next_steps:
  - "Run tests to verify implementation"
  - "Write additional tests if coverage < 95%"
  - "Proceed to Gate 4 when tests pass"
```

---

## Next-Step Generation

### Rules

After each command, generate context-aware next steps:

```python
def get_next_steps(state, last_command):
    rules = {
        ("init", "/rdd-init"): [
            "Run 'task doctor' to verify setup",
            "Edit docs/01-charter.md with your project vision",
            "Create roadmap with '/rdd-roadmap add'"
        ],
        ("planning", "/rdd-roadmap"): [
            "Start first stage with '/rdd-stage-auto 0'",
            "Review stage document before starting"
        ],
        ("developing", "/rdd-stage-auto"): [
            "Run tests to verify implementation",
            "Check coverage with 'task test:coverage'",
            "Proceed to Gate 4 when tests pass"
        ],
        ("reviewing", None): [
            "Review code changes",
            "Address any findings",
            "Run '/rdd-stage-auto --resume' to continue"
        ],
        ("complete", "/rdd-stage-auto"): [
            "Start next stage with '/rdd-stage-auto'",
            "Update roadmap with '/rdd-roadmap complete'",
            "Generate handoff with '/rdd-knowledge handoff'"
        ]
    }
    return rules.get((state, last_command), ["Check '/rdd-help' for guidance"])
```

---

## Next-Step Prompts

### Format

After each command, display:

```
📍 Current State: <state>
📍 Current Stage: <stage> | Gate: <gate>

✅ Completed: <last_command>

⏭️  Next Steps:
  1. <next_step_1>
  2. <next_step_2>
  3. <next_step_3>

💡 Tip: <contextual_tip>
```

### Example

After `/rdd-init`:

```
📍 Current State: init
📍 Current Stage: - | Gate: -

✅ Completed: /rdd-init my-project

⏭️  Next Steps:
  1. Run 'task doctor' to verify setup
  2. Edit docs/01-charter.md with your project vision
  3. Create roadmap with '/rdd-roadmap add --title "First Stage"'

💡 Tip: A clear charter helps agents understand your project goals.
```

---

## State Transitions

### Automatic Transitions

```python
def detect_transition(command, result):
    if command == "/rdd-init":
        return "init"
    elif command == "/rdd-roadmap" and result.has_roadmap:
        return "planning"
    elif command == "/rdd-stage-auto" and result.stage_started:
        return "developing"
    elif result.tests_passed:
        return "reviewing"
    elif result.gate_5_passed:
        return "complete"
```

### Manual Transitions

```bash
/rdd-state set <state>  # Force state transition
/rdd-state reset        # Reset to init
```

---

## Integration

### Command Hooks

Each RDD command should call state update:

```bash
# After command execution
rdd-state update --command "/rdd-init" --result "success"
```

### Handoff Integration

State is included in handoff documents:

```yaml
# Handoff includes:
current_state: developing
current_stage: 19
current_gate: 3
next_steps: [...]
```

---

## API

### Get Current State

```bash
rdd-state get
# Output: developing
```

### Get Next Steps

```bash
rdd-state next-steps
# Output:
# 1. Run tests to verify implementation
# 2. Check coverage with 'task test:coverage'
# 3. Proceed to Gate 4 when tests pass
```

### Update State

```bash
rdd-state update --command "/rdd-stage-auto" --result "success"
```

### Reset State

```bash
rdd-state reset
# Resets to init state
```

---

## Testing

### Unit Tests

```bash
tests/unit/state/test_state_machine.bats
tests/unit/state/test_transitions.bats
tests/unit/state/test_next_steps.bats
```

### E2E Tests

```bash
tests/e2e/test_state_tracking.bats
tests/e2e/test_next_step_prompts.bats
```

---

## Reference

For more information:
- `rdd-workflow` skill - Uses state for workflow steps
- `rdd-knowledge` skill - Includes state in handoff
- `CLAUDE.md` - State documentation
