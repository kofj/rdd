# Stage 20: Help & Workflow System

## Status

[x] Planning / [x] In Progress / [x] Complete

---

## Goals

Build a comprehensive guidance system that provides:
1. `/rdd-help` command for deep documentation search
2. State-aware next-step prompts after each command
3. `/rdd-workflow` interactive wizard for common tasks
4. Scenario-based guides for different user contexts

---

## Non-Goals

- IDE integration
- Web-based documentation site
- Video tutorials

---

## Core Hypotheses

- **Hypothesis A**: State-aware prompts reduce user onboarding time by 40%
- **Hypothesis B**: Interactive wizards increase successful workflow completion by 60%

---

## Acceptance Criteria

- [ ] `/rdd-help <topic>` returns relevant documentation
- [ ] State machine tracks user progress correctly
- [ ] Next-step hints appear after command execution
- [ ] `/rdd-workflow` guides through complete workflows
- [ ] Scenario guides cover onboarding, daily dev, troubleshooting
- [ ] All features have E2E tests
- [ ] Coverage >= 95%

---

## Rollback Plan

1. Disable state tracking via config flag
2. Remove `/rdd-help` and `/rdd-workflow` commands
3. Revert to basic command-only interface

---

## Known Limitations

- State tracking is session-based, not persistent across sessions
- Natural language search is keyword-based, not semantic

---

## Impact on Subsequent Stages

- **Stage 22**: Uses state machine for progress tracking
- Future features can build on state-aware infrastructure

---

## Implementation Notes

### Task 1: Implement State Machine

```yaml
# .rdd/state.yml
current_state: init
history:
  - state: init
    timestamp: 2026-03-13T10:00:00Z
    command: /rdd-init
```

States:
- `init` - Project just initialized
- `planning` - Roadmap being defined
- `developing` - Active stage execution
- `reviewing` - Code review in progress
- `complete` - Stage completed

### Task 2: Create /rdd-help Command

```markdown
---
description: "Search RDD documentation for topics, commands, and guides"
examples:
  - "/rdd-help workflow"
  - "/rdd-help testing"
  - "/rdd-help ADR"
---
```

Features:
- Fuzzy search across all documentation
- Topic categories: commands, workflows, concepts, troubleshooting
- Return top 5 results with summaries

### Task 3: Create /rdd-workflow Command

```markdown
---
description: "Interactive wizard to guide through common RDD workflows"
examples:
  - "/rdd-workflow new-project"
  - "/rdd-workflow daily-development"
  - "/rdd-workflow troubleshooting"
---
```

Workflows:
1. **new-project**: init → roadmap → first-stage → complete
2. **daily-development**: status → stage-auto → review → commit
3. **troubleshooting**: diagnose → fix → verify → document

### Task 4: Implement Next-Step Prompts

After each command, analyze state and suggest:

```python
# Pseudocode
def get_next_step(current_state, last_command):
    transitions = {
        ("init", "rdd-init"): "Run 'task doctor' to verify setup",
        ("init", "task doctor"): "Create roadmap with '/rdd-roadmap add'",
        ("planning", "rdd-roadmap"): "Start first stage with '/rdd-stage-auto'",
        ("developing", "rdd-stage-auto"): "Review results or continue to next gate",
        ("complete", "rdd-stage-auto"): "Start next stage or generate handoff"
    }
    return transitions.get((current_state, last_command), "Check docs with '/rdd-help'")
```

### Task 5: Create Scenario Guides

Guides to create:
1. **Onboarding**: New user getting started
2. **Daily Development**: Typical development workflow
3. **Troubleshooting**: Common issues and solutions
4. **Advanced**: Multi-stage automation, worktrees

---

## Technical Design

### Architecture

```
┌─────────────────┐
│  /rdd-help      │───→ Search Engine ───→ Doc Index
└─────────────────┘
┌─────────────────┐
│  /rdd-workflow  │───→ Workflow Engine ───→ Step Executor
└─────────────────┘
┌─────────────────┐
│  State Machine  │───→ State Tracker ───→ Next Step Generator
└─────────────────┘
```

### File Structure

```
.claude/
├── commands/
│   ├── rdd-help.md
│   └── rdd-workflow.md
├── skills/
│   ├── rdd-help.md
│   ├── rdd-workflow.md
│   └── rdd-state.md
└── data/
    └── guides/
        ├── onboarding.md
        ├── daily-dev.md
        ├── troubleshooting.md
        └── advanced.md
```

---

## Test Plan

### Unit Tests

```bash
tests/unit/state/test_state_machine.bats
tests/unit/help/test_search_engine.bats
tests/unit/workflow/test_workflow_engine.bats
```

### E2E Tests

```bash
tests/e2e/test_help_search.bats
tests/e2e/test_workflow_wizard.bats
tests/e2e/test_next_step_prompts.bats
```

---

## Dependencies

- Stage 19 (Command Hint System)

---

## Estimated Effort

Medium (2 days)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-13 | Initial design |
