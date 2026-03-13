---
description: "Migrate an existing project to RDD framework, preserving existing structure and documentation"
examples:
  - "/rdd-migrate                    # Migrate and convert existing docs"
  - "/rdd-migrate --preserve-existing # Keep original docs unchanged"
---

# RDD Migrate Command

Migrate an existing project to use RDD (Roadmap Driven Development) framework.

## Usage

```
/rdd-migrate [--preserve-existing]
```

## Description

This command converts an existing project to use RDD methodology. Unlike `/rdd-init`, it:

- Preserves existing documentation
- Analyzes current project structure
- Creates RDD structure around existing code
- Generates initial roadmap from existing codebase
- Creates initial technical debt ledger from code analysis

## Options

- `--preserve-existing`: Keep existing documentation files (don't overwrite)

## Behavior

1. **Analysis**: Scan existing project structure and documentation
2. **Planning**: Determine how to integrate RDD with existing patterns
3. **Migration**:
   - Create `.rdd/` directory structure
   - Convert existing docs to RDD format
   - Create `AGENTS.md` and `CLAUDE.md`
   - Generate initial roadmap from code analysis
   - Create initial technical debt entries
4. **Integration**: Update any build/test tools if needed
5. **Validation**: Verify migration success

## Migration Steps

### Step 1: Analyze Existing Structure

```
Read existing:
- README.md (if exists) -> Convert to charter
- CHANGELOG.md (if exists) -> Preserve
- Any existing docs/ -> Convert to RDD format
```

### Step 2: Generate Roadmap

```
From code analysis:
- Identify existing features
- Create completed stages for implemented features
- Create pending stages for TODO items
- Document technical debt
```

### Step 3: Create RDD Structure

```
Create:
- .rdd/ configuration
- docs/ with converted content
- Stage documents for completed work
```

## Examples

```
/rdd-migrate                    # Migrate and convert existing docs
/rdd-migrate --preserve-existing # Migrate but keep original docs
```

## Post-Migration Tasks

After migration:

1. Review `docs/stages/stage-roadmap.md` for accuracy
2. Verify `docs/08-autonomous-decisions.md` captures key decisions
3. Update `docs/12-technical-debt.md` with known issues
4. Configure notifications in `.rdd/hooks.yml` (optional)
5. Run `task doctor` to verify setup

## See Also

- `/rdd-init` - Initialize new RDD project
- `/rdd-roadmap` - Manage roadmap after migration
