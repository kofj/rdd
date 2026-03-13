---
description: "Interactive wizard to guide through common RDD workflows step-by-step"
examples:
  - "/rdd-workflow new-project      # Start a new RDD project"
  - "/rdd-workflow daily-dev       # Daily development workflow"
  - "/rdd-workflow troubleshooting # Diagnose and fix issues"
  - "/rdd-workflow complete-stage  # Complete current stage"
---

# RDD Workflow Command

Interactive wizard that guides users through common RDD workflows.

## Usage

```
/rdd-workflow <workflow-name>
```

## Description

This command provides step-by-step guidance for common RDD workflows. Each workflow:

- Breaks down complex tasks into manageable steps
- Checks prerequisites at each step
- Provides guidance and examples
- Tracks progress through the workflow
- Suggests next steps

## Available Workflows

### new-project

Start a new RDD project from scratch:

```
/rdd-workflow new-project
```

Steps:
1. **Initialize Project**
   - Run `/rdd-init` with project name
   - Verify setup with `task doctor`

2. **Define Vision**
   - Edit `docs/01-charter.md`
   - Set goals and non-goals
   - Define success criteria

3. **Create Roadmap**
   - Plan initial stages
   - Define dependencies
   - Set priorities

4. **Start First Stage**
   - Create stage document
   - Run `/rdd-stage-auto 0`

### daily-dev

Daily development workflow:

```
/rdd-workflow daily-dev
```

Steps:
1. **Check Status**
   - Run `/rdd-roadmap status`
   - Review blockers

2. **Execute Stage**
   - Run `/rdd-stage-auto`
   - Or resume with `--resume`

3. **Review Progress**
   - Check gate status
   - Review findings

4. **Document**
   - Record ADRs
   - Update tech debt

5. **Commit Changes**
   - Verify all tests pass
   - Create commit

### troubleshooting

Diagnose and fix issues:

```
/rdd-workflow troubleshooting
```

Steps:
1. **Diagnose**
   - Run `task doctor`
   - Check error logs

2. **Identify Cause**
   - Review recent changes
   - Check dependencies

3. **Fix Issue**
   - Apply fix
   - Write/update tests

4. **Verify Fix**
   - Run tests
   - Check gates

5. **Document**
   - Record in tech debt if workaround
   - Update documentation

### complete-stage

Complete current stage workflow:

```
/rdd-workflow complete-stage
```

Steps:
1. **Verify Tests**
   - Run unit tests
   - Run E2E tests
   - Check coverage

2. **Update Documents**
   - Stage document
   - ADRs
   - Tech debt
   - Next steps

3. **Run Gate 5**
   - Verify all criteria
   - Run fresh-agent-check

4. **Mark Complete**
   - Update roadmap
   - Create changelog entry

### multi-stage

Execute multiple stages autonomously:

```
/rdd-workflow multi-stage --from 19 --to 22
```

Steps:
1. **Analyze Dependencies**
   - Check stage dependencies
   - Identify parallel opportunities

2. **Plan Execution**
   - Create execution plan
   - Allocate worktrees

3. **Execute Stages**
   - Run parallel if possible
   - Monitor progress

4. **Aggregate Results**
   - Merge completed work
   - Update documentation

## Workflow State

Workflows track state in `.rdd/workflow-state.yml`:

```yaml
current_workflow: daily-dev
current_step: 2
completed_steps:
  - 1
  - 2
started_at: 2026-03-13T10:00:00Z
```

## Interactive Mode

When running a workflow without a name:

```
/rdd-workflow
```

Shows available workflows and prompts for selection.

## Progress Tracking

Each step shows:

```
Step 2/5: Execute Stage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 40%

✅ Prerequisites: Stage document exists
📋 Current: Run /rdd-stage-auto
⏭️  Next: Review progress

Actions:
  [c]ontinue  [s]kip  [a]bort
```

## Custom Workflows

Projects can define custom workflows in `.rdd/workflows/`:

```yaml
# .rdd/workflows/custom.yml
name: release
description: Release preparation workflow
steps:
  - name: Verify tests
    command: task test
  - name: Update version
    command: task version:bump
  - name: Create release
    command: task release:create
```

## Integration

- Works with `/rdd-help` for topic documentation
- Uses `/rdd-stage-auto` for stage execution
- Uses `/rdd-loop` for autonomous execution

## See Also

- `/rdd-help` - Search documentation
- `/rdd-stage-auto` - Execute single stage
- `/rdd-loop` - Autonomous multi-stage execution
