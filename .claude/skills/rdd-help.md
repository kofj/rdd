# RDD Help Skill

> Search and display RDD documentation for topics, commands, and guides.

## Overview

The `rdd-help` skill provides comprehensive documentation search capabilities for the RDD framework. It helps users quickly find relevant information about commands, concepts, workflows, and features.

**Command:** `/rdd-help <topic>`

---

## When to Use This Skill

**Triggers:**
- User asks about RDD commands or concepts
- User invokes `/rdd-help` command
- User needs guidance on workflows or troubleshooting

---

## Search Algorithm

### Priority Order

1. **Exact Match**: Direct topic lookup in documentation
2. **Partial Match**: Topics containing the search term
3. **Fuzzy Match**: Similar topics (Levenshtein distance ≤ 3)
4. **Related**: Topics mentioned in found documents

### Search Locations

| Location | Priority | Content Type |
|----------|----------|--------------|
| `.claude/commands/` | High | Command documentation |
| `.claude/skills/` | High | Skill documentation |
| `docs/` | Medium | User documentation |
| `CLAUDE.md` | High | Quick reference |
| `AGENTS.md` | High | Agent entry point |

---

## Topic Categories

### Commands

| Topic | Description | File |
|-------|-------------|------|
| `init` | Project initialization | `rdd-init.md` |
| `migrate` | Project migration | `rdd-migrate.md` |
| `roadmap` | Roadmap management | `rdd-roadmap.md` |
| `stage-auto` | Stage execution | `rdd-stage-auto.md` |
| `loop` | Autonomous loop | `rdd-loop.md` |
| `knowledge` | Knowledge management | `rdd-knowledge.md` |
| `help` | Documentation search | `rdd-help.md` |
| `workflow` | Workflow wizard | `rdd-workflow.md` |

### Concepts

| Topic | Description | File |
|-------|-------------|------|
| `workflow` | Development workflow | `docs/03-stage-based-development.md` |
| `gate` | Quality gates | `docs/03-stage-based-development.md` |
| `ADR` | Autonomous Decision Records | `docs/08-autonomous-decisions.md` |
| `debt` | Technical debt | `docs/12-technical-debt.md` |
| `handoff` | Session handoff | `docs/handoff/` |
| `recovery` | Compact recovery | `CLAUDE.md` |

### Workflows

| Topic | Description |
|-------|-------------|
| `onboarding` | New project setup |
| `daily-dev` | Daily development |
| `troubleshooting` | Issue resolution |
| `complete-stage` | Stage completion |

### Features

| Topic | Description |
|-------|-------------|
| `testing` | Testing strategy |
| `coverage` | Coverage requirements |
| `worktree` | Git worktree management |
| `parallel` | Parallel execution |

---

## Output Format

```markdown
📚 RDD Help: <topic>

Summary:
<Brief description of the topic>

Related Commands:
- /rdd-<command> - <description>

Documentation:
<Link to relevant documentation>

Workflow:
<Step-by-step guide if applicable>

Examples:
<Code examples>

See Also:
<Related topics>
```

---

## Implementation

### Step 1: Parse Topic

```bash
topic="$1"
category=""  # Will be determined by search
```

### Step 2: Search Documentation

1. Check exact match in commands
2. Check exact match in skills
3. Check partial match in docs
4. Apply fuzzy matching if no results

### Step 3: Format Output

1. Extract summary from matching file
2. Find related commands
3. Find related documentation
4. Generate examples

---

## Examples

### Example 1: Command Help

```
/rdd-help init
```

Output:
```markdown
📚 RDD Help: init

Summary:
Initialize RDD framework in a new or existing project with TDD/BDD configuration.

Related Commands:
- /rdd-init - Initialize project
- /rdd-migrate - Migrate existing project

Documentation:
- .claude/commands/rdd-init.md
- .claude/skills/rdd-init.md

Workflow:
1. Run /rdd-init [project-name]
2. Edit docs/01-charter.md with project vision
3. Edit docs/stages/stage-roadmap.md with stages
4. Run task doctor to verify setup

Examples:
  /rdd-init                    # Current directory name
  /rdd-init my-awesome-project # Specific name

See Also:
- migrate, roadmap, workflow
```

### Example 2: Concept Help

```
/rdd-help gate
```

Output:
```markdown
📚 RDD Help: gate

Summary:
Quality gates are checkpoints that must pass before proceeding to the next phase. RDD has 5 gates per stage.

Gate Overview:
- Gate 0: Stage Startup Check
- Gate 1: Design Document Pre-Check
- Gate 2: Design Review (Before Coding)
- Gate 3: Implementation & Testing
- Gate 4: Code Review (After E2E Pass)
- Gate 5: Completion Gate Check

Documentation:
- docs/03-stage-based-development.md

Commands:
- /rdd-stage-auto - Execute stage with gates
- /rdd-loop - Autonomous execution through gates

See Also:
- workflow, stage-auto, testing
```

---

## Error Handling

### Topic Not Found

```markdown
📚 RDD Help: <topic>

No exact match found for "<topic>".

Did you mean:
- <similar_topic_1>
- <similar_topic_2>

Use /rdd-help without arguments to see all topics.
```

### No Arguments

```markdown
📚 RDD Help

Available Topics:

Commands:
  init, migrate, roadmap, stage-auto, loop, knowledge, help, workflow

Concepts:
  workflow, gate, ADR, debt, handoff, recovery

Workflows:
  onboarding, daily-dev, troubleshooting, complete-stage

Features:
  testing, coverage, worktree, parallel

Usage: /rdd-help <topic>
```

---

## Integration

- Works with `/rdd-workflow` for guided workflows
- Links to relevant skill files
- Provides next-step suggestions

---

## Reference

For more information:
- `CLAUDE.md` - Quick reference
- `docs/03-stage-based-development.md` - Stage workflow
- `.claude/commands/` - Command documentation
