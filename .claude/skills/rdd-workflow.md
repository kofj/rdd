# RDD Workflow Skill

> Interactive wizard for guided RDD workflows.

## Overview

The `rdd-workflow` skill provides step-by-step guidance through common RDD workflows. It breaks down complex tasks into manageable steps, checks prerequisites, and tracks progress.

**Command:** `/rdd-workflow <workflow-name>`

---

## When to Use This Skill

**Triggers:**
- User asks for guided workflow
- User invokes `/rdd-workflow` command
- User needs step-by-step guidance for a task

---

## Available Workflows

### new-project

Start a new RDD project from scratch.

**Steps:**

| Step | Name | Actions | Verification |
|------|------|---------|--------------|
| 1 | Initialize | Run `/rdd-init` | `.rdd/` directory exists |
| 2 | Define Vision | Edit `docs/01-charter.md` | Vision section filled |
| 3 | Create Roadmap | Edit `docs/stages/stage-roadmap.md` | At least Stage 0 defined |
| 4 | Start First Stage | Run `/rdd-stage-auto 0` | Gate 0 passed |

**Prerequisites:**
- Empty or new project directory
- Git repository (recommended)

**Duration:** 15-30 minutes

---

### daily-dev

Daily development workflow for active stages.

**Steps:**

| Step | Name | Actions | Verification |
|------|------|---------|--------------|
| 1 | Check Status | Run `/rdd-roadmap status` | Status understood |
| 2 | Execute Stage | Run `/rdd-stage-auto` | Tests pass |
| 3 | Review Progress | Check gate status | Gates passed |
| 4 | Document | Record ADRs, update debt | Docs updated |
| 5 | Commit | Create commit | Changes committed |

**Prerequisites:**
- Active stage in progress
- Tests exist

**Duration:** 30-60 minutes

---

### troubleshooting

Diagnose and fix issues.

**Steps:**

| Step | Name | Actions | Verification |
|------|------|---------|--------------|
| 1 | Diagnose | Run `task doctor` | Issues identified |
| 2 | Identify Cause | Review logs, check deps | Root cause found |
| 3 | Fix Issue | Apply fix | Tests added |
| 4 | Verify Fix | Run tests | Tests pass |
| 5 | Document | Update docs | Docs updated |

**Prerequisites:**
- Issue to troubleshoot

**Duration:** 15-60 minutes

---

### complete-stage

Complete current stage workflow.

**Steps:**

| Step | Name | Actions | Verification |
|------|------|---------|--------------|
| 1 | Verify Tests | Run unit & E2E tests | All tests pass |
| 2 | Update Documents | Update stage docs, ADRs, debt | All docs updated |
| 3 | Run Gate 5 | Verify all criteria | Gate 5 passed |
| 4 | Mark Complete | Update roadmap, changelog | Stage marked complete |

**Prerequisites:**
- Gate 3 and 4 passed
- Tests passing

**Duration:** 15-30 minutes

---

### multi-stage

Execute multiple stages autonomously.

**Steps:**

| Step | Name | Actions | Verification |
|------|------|---------|--------------|
| 1 | Analyze Dependencies | Check stage deps | Dependency graph built |
| 2 | Plan Execution | Create plan | Plan approved |
| 3 | Execute Stages | Run `/rdd-loop` | Stages complete |
| 4 | Aggregate Results | Merge work, update docs | All merged |

**Prerequisites:**
- Multiple pending stages
- Dependencies clear

**Duration:** 1-4 hours

---

## Workflow State

State is tracked in `.rdd/workflow-state.yml`:

```yaml
current_workflow: daily-dev
current_step: 2
total_steps: 5
completed_steps:
  - 1
  - 2
started_at: 2026-03-13T10:00:00Z
last_updated: 2026-03-13T10:15:00Z
```

---

## Interactive Mode

When running without arguments:

```
/rdd-workflow
```

Shows workflow selection menu:

```
📚 Available Workflows:

1. new-project      - Start a new RDD project
2. daily-dev        - Daily development workflow
3. troubleshooting  - Diagnose and fix issues
4. complete-stage   - Complete current stage
5. multi-stage      - Execute multiple stages

Select workflow (1-5):
```

---

## Progress Display

Each step shows:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 2/5: Execute Stage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Prerequisites:
   - Stage document exists
   - Dependencies complete

📋 Current Task:
   Run /rdd-stage-auto to execute the current stage

⏭️  Next Step:
   Review progress and check gate status

Actions:
  [c]ontinue  [s]kip  [a]bort  [h]elp

Progress: ████████████░░░░░░░░░░░░ 40%
```

---

## Step Verification

Each step has verification criteria:

```yaml
step:
  name: "Execute Stage"
  verification:
    - "Tests pass"
    - "Gate 3 passed"
    - "Coverage >= 95%"
  on_failure:
    - "Show error message"
    - "Offer troubleshooting workflow"
    - "Option to retry or skip"
```

---

## Custom Workflows

Projects can define custom workflows in `.rdd/workflows/`:

```yaml
# .rdd/workflows/release.yml
name: release
description: Release preparation workflow
steps:
  - name: Verify tests
    command: "task test"
    verification: "All tests pass"
  - name: Update version
    command: "task version:bump"
    verification: "Version updated in package.json"
  - name: Create release
    command: "task release:create"
    verification: "Release created on GitHub"
```

---

## Error Handling

### Prerequisite Not Met

```
❌ Prerequisite Not Met

Step: Execute Stage
Missing: Stage document does not exist

Suggested Action:
  Run /rdd-roadmap add --title "Stage Title" first

Actions:
  [r]etry  [a]bort  [h]elp
```

### Step Failure

```
❌ Step Failed

Step: Execute Stage
Error: Tests failed

Details:
  - 3 tests failed
  - Coverage: 85% (required: 95%)

Suggested Action:
  Fix failing tests and improve coverage

Actions:
  [r]etry  [s]kip  [t]roubleshoot  [a]bort
```

---

## Integration

- Works with `/rdd-help` for documentation
- Uses `/rdd-stage-auto` for stage execution
- Uses `/rdd-loop` for autonomous execution
- Uses `/rdd-knowledge` for documentation

---

## Reference

For more information:
- `/rdd-help workflow` - Workflow documentation
- `docs/03-stage-based-development.md` - Stage workflow
- `.claude/skills/rdd-stage-auto.md` - Stage execution
