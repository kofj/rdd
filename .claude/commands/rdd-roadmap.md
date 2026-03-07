# RDD Roadmap Command

Manage the project roadmap - view, plan, and modify stages.

## Usage

```
/rdd-roadmap [subcommand] [options]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `status` | Show current roadmap status |
| `list` | List all stages with status |
| `add` | Add a new stage to roadmap |
| `modify` | Modify an existing stage |
| `reorder` | Change stage order/dependencies |
| `complete` | Mark a stage as complete |
| `deps` | Show dependency graph |

## Status Subcommand

```
/rdd-roadmap status
```

Shows:
- Current active stage
- Overall progress percentage
- Current gate
- Blockers (if any)
- Next milestone

## List Subcommand

```
/rdd-roadmap list [--all]
```

Shows:
- Stage number and title
- Status (Planning/In Progress/Complete)
- Priority
- Dependencies
- Progress percentage

Options:
- `--all`: Show completed stages too

## Add Subcommand

```
/rdd-roadmap add --title "Stage Title" --priority P0 --after 3
```

Options:
- `--title`: Stage title (required)
- `--priority`: P0, P1, P2, P3 (default: P1)
- `--after`: Stage number to add after (for ordering)
- `--depends`: Comma-separated dependency stages

## Modify Subcommand

```
/rdd-roadmap modify 5 --title "New Title" --priority P0
```

Options:
- Stage number is required
- Any field can be modified

## Reorder Subcommand

```
/rdd-roadmap reorder 5 --after 3
```

Changes stage order and updates dependencies accordingly.

## Complete Subcommand

```
/rdd-roadmap complete 4
```

Marks a stage as complete and:
- Updates roadmap status
- Adds changelog entry
- Identifies next stage
- Notifies via Hook (if configured)

## Deps Subcommand

```
/rdd-roadmap deps
```

Shows dependency graph as ASCII art:

```
Stage 0 (Complete)
  └── Stage 1 (Complete)
        ├── Stage 2 (Complete)
        │     └── Stage 4 (In Progress)
        └── Stage 3 (Planning)
              └── Stage 5 (Planning)
```

## Examples

```
/rdd-roadmap status                 # Check current status
/rdd-roadmap list                   # List pending stages
/rdd-roadmap add --title "Auth" --priority P0
/rdd-roadmap complete 2             # Mark stage 2 complete
/rdd-roadmap deps                   # View dependencies
```

## Roadmap Modification Rules

**IMPORTANT**: Roadmap changes require human approval because:

1. Roadmap defines strategic direction
2. Changes affect multiple stages
3. Dependencies may create blockers
4. Priority changes affect scheduling

When this command modifies the roadmap:
1. Changes are staged (not immediately saved)
2. Hook notification is sent (P1 priority)
3. Human must approve before saving
4. Changes are logged to roadmap history

## See Also

- `/rdd-stage-auto` - Execute a stage
- `rdd-roadmap` skill in `.claude/skills/rdd-roadmap.md`
