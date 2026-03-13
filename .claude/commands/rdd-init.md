---
description: "Initialize RDD framework in a new or existing project with TDD/BDD configuration"
examples:
  - "/rdd-init                    # Initialize with current directory name"
  - "/rdd-init my-project         # Initialize with specific project name"
---

# RDD Init Command

Initialize RDD (Roadmap Driven Development) framework in a new project.

## Usage

```
/rdd-init [project-name]
```

## Description

This command sets up a complete RDD framework structure in a new or existing project directory. It creates:

- RDD configuration files (`.rdd/`)
- Documentation templates (`docs/`)
- Agent entry points (`AGENTS.md`, `CLAUDE.md`)
- Stage templates (`docs/stages/`)
- Hook configuration for notifications

## Arguments

- `project-name` (optional): Name of the project. If not provided, uses the directory name.

## Behavior

1. **Pre-check**: Verifies no existing `.rdd/` directory exists
2. **Directory creation**: Creates all required directories
3. **Configuration setup**: Creates `.rdd/config.yml`, `hooks.yml`, `templates.yml`
4. **Documentation setup**: Creates documentation templates
5. **Entry points**: Creates `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`
6. **Validation**: Verifies all files created correctly

## Examples

```
/rdd-init                    # Initialize with current directory name
/rdd-init my-awesome-project # Initialize with specific name
```

## Post-Initialization

After running this command:

1. Edit `docs/01-charter.md` with your project vision
2. Edit `docs/stages/stage-roadmap.md` with your stages
3. Configure notifications in `.rdd/hooks.yml` (optional)
4. Run `task doctor` to verify setup

## See Also

- `/rdd-migrate` - Migrate existing project to RDD
- `rdd-init` skill in `.claude/skills/rdd-init.md`
