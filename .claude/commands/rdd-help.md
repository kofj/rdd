---
description: "Search RDD documentation for topics, commands, workflows, and troubleshooting guides"
examples:
  - "/rdd-help workflow          # Find workflow documentation"
  - "/rdd-help testing           # Find testing guides"
  - "/rdd-help ADR               # Find ADR documentation"
  - "/rdd-help troubleshooting   # Find troubleshooting guides"
---

# RDD Help Command

Search and display RDD documentation for topics, commands, and guides.

## Usage

```
/rdd-help <topic>
```

## Description

This command searches through all RDD documentation to find relevant information about the specified topic. It returns:

- Topic summary
- Related commands
- Workflow guides
- Code examples
- Troubleshooting tips

## Arguments

- `<topic>` (required): The topic to search for. Can be:
  - Command name (e.g., `init`, `stage-auto`)
  - Concept (e.g., `workflow`, `gate`, `ADR`)
  - Workflow (e.g., `onboarding`, `daily-dev`, `troubleshooting`)
  - Feature (e.g., `testing`, `coverage`, `worktree`)

## Topic Categories

### Commands

| Topic | Description |
|-------|-------------|
| `init` | Project initialization |
| `migrate` | Project migration |
| `roadmap` | Roadmap management |
| `stage-auto` | Stage execution |
| `loop` | Autonomous loop |
| `knowledge` | Knowledge management |

### Concepts

| Topic | Description |
|-------|-------------|
| `workflow` | Development workflow overview |
| `gate` | Quality gates explanation |
| `ADR` | Autonomous Decision Records |
| `debt` | Technical debt management |
| `handoff` | Session handoff process |
| `recovery` | Compact recovery protocol |

### Workflows

| Topic | Description |
|-------|-------------|
| `onboarding` | New project setup guide |
| `daily-dev` | Daily development workflow |
| `troubleshooting` | Common issues and solutions |
| `advanced` | Advanced features (worktrees, parallel execution) |

### Features

| Topic | Description |
|-------|-------------|
| `testing` | Testing strategy and coverage |
| `coverage` | Coverage requirements and gates |
| `worktree` | Git worktree management |
| `parallel` | Parallel stage execution |

## Output Format

```
📚 RDD Help: <topic>

Summary:
<brief description>

Related Commands:
- /rdd-<command> - <description>

Workflow:
<step-by-step guide>

Examples:
<code examples>

See Also:
<related topics>
```

## Search Algorithm

1. **Exact match**: Direct topic lookup
2. **Partial match**: Topics containing search term
3. **Fuzzy match**: Similar topics (Levenshtein distance)
4. **Related**: Topics mentioned in found documents

## Examples

```
/rdd-help workflow
# Returns: Complete workflow overview with gates and stages

/rdd-help testing
# Returns: Testing strategy, coverage requirements, BDD setup

/rdd-help gate
# Returns: Gate descriptions, checklists, and verification

/rdd-help troubleshooting
# Returns: Common issues, error messages, solutions
```

## Integration

- Works with `/rdd-workflow` for guided workflows
- Links to relevant skill files
- Provides next-step suggestions

## See Also

- `/rdd-workflow` - Interactive workflow wizard
- `rdd-core` skill in `.claude/skills/rdd-core.md`
- Documentation in `docs/` directory
