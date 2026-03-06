# RDD Init Skill

> Initialize a new RDD (Roadmap Driven Development) project structure

## Overview

The `rdd-init` skill sets up a complete RDD framework in a new or existing project directory. It creates the required directory structure, configuration files, documentation templates, and agent entry points needed for Roadmap Driven Development.

---

## When to Use This Skill

**Triggers:**
- Starting a new project with RDD paradigm
- Converting an empty directory to an RDD project
- Setting up RDD structure after cloning a template
- After `/rdd-init` command is invoked
- When project lacks `.rdd/` directory

**Prerequisites:**
- Empty or new project directory (for new projects)
- OR existing project directory (for migration - use rdd-migrate instead)
- Write permissions in target directory
- Git repository (recommended but not required)

---

## Initialization Steps

### Step 1: Pre-Initialization Check

Before initializing, verify:

```
[ ] Target directory exists and is accessible
[ ] No existing .rdd/ directory (if exists, skip or use rdd-migrate)
[ ] No conflicting RDD files (check for existing AGENTS.md, CLAUDE.md)
[ ] User has provided project name and description
```

If conflicts exist:
- Ask user if they want to overwrite existing files
- Suggest using rdd-migrate if project already has content

### Step 2: Directory Creation

Create the following directory structure:

```bash
# RDD configuration and cache
mkdir -p .rdd/cache
mkdir -p .rdd/scripts
mkdir -p .rdd/hooks

# Documentation structure
mkdir -p docs/framework
mkdir -p docs/stages
mkdir -p docs/handoff

# Claude Code integration
mkdir -p .claude/skills
mkdir -p .claude/commands
```

**Directory Purpose:**
| Directory | Purpose |
|-----------|---------|
| `.rdd/` | RDD configuration and runtime data |
| `.rdd/cache/` | Checkpoint state, temporary files |
| `.rdd/scripts/` | Hook notification scripts |
| `.rdd/hooks/` | Lifecycle hook scripts |
| `docs/framework/` | Governance and execution specifications |
| `docs/stages/` | Stage design documents |
| `docs/handoff/` | Agent handoff documents |
| `.claude/skills/` | Claude Code skill definitions |
| `.claude/commands/` | Claude Code command definitions |

### Step 3: Configuration Files Setup

#### 3.1 Create `.rdd/config.yml`

```yaml
# RDD Configuration
# This is the main configuration file for RDD (Roadmap Driven Development)

version: "1.0.0"
project:
  name: "{{PROJECT_NAME}}"
  description: "{{PROJECT_DESCRIPTION}}"

# Stage settings
stage:
  # Minimum test coverage requirement (%)
  min_coverage: 20
  # Maximum consecutive failures before pause
  max_failures: 3
  # Tech debt threshold for blocking new stages
  tech_debt_threshold: 3

# Gate settings
gates:
  # Require design document before implementation
  design_required: true
  # Require review before merge
  review_required: true
  # Require E2E tests for stage completion
  e2e_required: true
  # Require documentation updates
  docs_required: true

# Hook settings
hooks:
  enabled: false
  config_file: ".rdd/hooks.yml"
  templates_file: ".rdd/templates.yml"

# Notification settings
notifications:
  quiet_hours:
    enabled: true
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true
```

#### 3.2 Create `.rdd/hooks.yml`

```yaml
# RDD Hooks Configuration
# Configure notification channels and triggers

# Notification channels
channels:
  wecom:
    enabled: false
    webhook_url: ""

  email:
    enabled: false
    smtp_host: ""
    smtp_port: 587
    smtp_user: ""
    smtp_pass: ""
    from_address: ""
    to_addresses: []

  bark:
    enabled: false
    server_url: ""
    device_key: ""

  telegram:
    enabled: false
    bot_token: ""
    chat_id: ""

  webhook:
    enabled: false
    url: ""
    method: "POST"
    headers: {}

# Trigger configurations
triggers:
  roadmap_change:
    enabled: true
    channels: [wecom, email]
    priority: "high"

  consecutive_failure:
    enabled: true
    channels: [wecom, bark, telegram]
    priority: "critical"

  hypothesis_invalid:
    enabled: true
    channels: [wecom, email]
    priority: "high"

  model_disagreement:
    enabled: true
    channels: [wecom]
    priority: "medium"

  tech_debt_threshold:
    enabled: true
    channels: [wecom, email]
    priority: "high"

  stage_complete:
    enabled: true
    channels: [wecom, email]
    priority: "normal"

  daily_report:
    enabled: true
    channels: [email]
    priority: "low"
    schedule: "09:00"
    timezone: "Asia/Shanghai"

  weekly_report:
    enabled: true
    channels: [email]
    priority: "low"
    schedule: "Monday 09:00"
    timezone: "Asia/Shanghai"

# Retry settings
retry:
  max_attempts: 3
  backoff: exponential
  initial_delay: 1s
  max_delay: 30s
```

#### 3.3 Create `.rdd/templates.yml`

```yaml
# RDD Notification Templates
# Message templates for notification triggers

templates:
  roadmap_change:
    title: "Roadmap Updated"
    block_message: "Roadmap change requires human review, Agent paused"
    body: |
      The project roadmap has been updated.

      Project: {{project_name}}
      Change Type: {{change_type}}
      Changed By: {{changed_by}}
      Timestamp: {{timestamp}}

      Details:
      {{change_details}}

  failure_alert:
    title: "Consecutive Failures Alert"
    block_message: "{{failure_count}} consecutive failures, Agent paused"
    body: |
      CRITICAL: Multiple consecutive failures detected.

      Project: {{project_name}}
      Stage: {{stage_name}}
      Failure Count: {{failure_count}}
      Last Error: {{last_error}}
      Timestamp: {{timestamp}}

  hypothesis_invalid:
    title: "Hypothesis Invalidated"
    block_message: "Core hypothesis invalidated, Agent paused for decision"
    body: |
      A hypothesis has been invalidated during testing.

      Project: {{project_name}}
      Hypothesis: {{hypothesis_text}}
      Reason: {{invalidation_reason}}
      Evidence: {{evidence}}
      Timestamp: {{timestamp}}

  model_disagreement:
    title: "Model Disagreement Detected"
    block_message: "Model disagreement detected, human review suggested"
    body: |
      Significant disagreement detected between models.

      Project: {{project_name}}
      Models: {{model_names}}
      Context: {{context}}
      Timestamp: {{timestamp}}

  tech_debt_alert:
    title: "Tech Debt Threshold Exceeded"
    block_message: "Tech debt exceeds threshold, Agent paused"
    body: |
      Technical debt has exceeded the configured threshold.

      Project: {{project_name}}
      Current Debt Count: {{debt_count}}
      Threshold: {{threshold}}
      Timestamp: {{timestamp}}

  stage_complete:
    title: "Stage Completed"
    block_message: "Stage {{stage_name}} completed"
    body: |
      A stage has been successfully completed.

      Project: {{project_name}}
      Stage: {{stage_name}}
      Duration: {{duration}}
      Coverage: {{coverage}}%
      Timestamp: {{timestamp}}

  daily_report:
    title: "Daily Progress Report"
    body: |
      Daily progress summary for {{project_name}}.

      Date: {{date}}
      Completed Tasks: {{completed_tasks}}
      In Progress: {{in_progress_tasks}}
      Tech Debt Count: {{tech_debt_count}}

  weekly_report:
    title: "Weekly Progress Report"
    body: |
      Weekly progress summary for {{project_name}}.

      Week: {{week_range}}
      Tasks Completed: {{tasks_completed}}
      Stages Finished: {{stages_finished}}
```

#### 3.4 Create `.rdd/checkpoints.yml`

```yaml
# RDD Checkpoints Configuration
# Define review checkpoints for quality gates

checkpoints:
  stage_complete_review:
    enabled: true
    trigger: "stage_complete"
    requirements:
      - "All tests passing"
      - "Coverage meets minimum threshold"
      - "No unresolved tech debt above threshold"
      - "Documentation updated"
    auto_approve_conditions:
      coverage_above: 80
      no_blockers: true
      tech_debt_below: 1

  adr_review:
    enabled: true
    trigger: "adr_created"
    requirements:
      - "ADR follows template format"
      - "Decision rationale documented"
      - "Alternatives considered"
      - "Impact assessment included"

  new_debt:
    enabled: true
    trigger: "tech_debt_added"
    requirements:
      - "Debt item documented"
      - "Priority assigned"
      - "Resolution plan proposed"
    auto_approve_conditions:
      priority: "low"

  daily_sync:
    enabled: true
    trigger: "scheduled"
    schedule: "daily"
    time: "09:00"
    timezone: "Asia/Shanghai"

state:
  storage_path: ".rdd/cache/checkpoints.json"
  history_retention_days: 30
```

### Step 4: Documentation Files Setup

#### 4.1 Create `docs/01-charter.md`

```markdown
# Project Charter

**Last Updated**: YYYY-MM-DD

## Vision

[One paragraph describing the project's ultimate goal]

## Goals

1. [Primary goal 1]
2. [Primary goal 2]
3. [Primary goal 3]

## Non-Goals

1. [Explicitly out of scope item 1]
2. [Explicitly out of scope item 2]

## Success Criteria

- [ ] [Measurable success criterion 1]
- [ ] [Measurable success criterion 2]
- [ ] [Measurable success criterion 3]

## Boundaries

**In Scope:**
- [What the project will do]

**Out of Scope:**
- [What the project will NOT do]

## Stakeholders

| Role | Responsibility |
|------|---------------|
| [Role 1] | [Responsibility] |
| [Role 2] | [Responsibility] |

## Timeline

- **Start Date**: YYYY-MM-DD
- **Target MVP**: YYYY-MM-DD
- **Target v1.0**: YYYY-MM-DD
```

#### 4.2 Create `docs/02-engineering-principles.md`

```markdown
# Engineering Principles

**Last Updated**: YYYY-MM-DD

## Core Principles

### 1. Roadmap Driven
- Humans define the roadmap; agents execute autonomously
- Roadmap changes require human approval
- Clear separation of strategy and execution

### 2. Stage as Delivery Unit
- Every stage is verifiable and rollback-capable
- Controlled scope with explicit boundaries
- Each stage validates a small set of hypotheses

### 3. Quality Gates
- Design before implementation
- Review before merge
- Tests before completion
- Docs before handoff

### 4. Explicit Knowledge
- All decisions recorded in ADRs
- All tech debt tracked in ledger
- All assumptions documented

### 5. Continuous Verification
- Multi-model cross-validation
- Real environment testing
- Clean environment verification

## Code Standards

- Follow language-specific style guides
- Write self-documenting code
- Maintain test coverage >= 20%
- Document public APIs

## Review Standards

- All code requires review
- Design documents require review
- Low-confidence findings need human verification
- Use triangulation for critical decisions
```

#### 4.3 Create `docs/03-stage-based-development.md`

```markdown
# Stage-Based Development

**Last Updated**: YYYY-MM-DD

## Overview

Stage-Based Development (SBD) breaks down project work into small, verifiable, and rollback-capable units called Stages.

## Stage Lifecycle

```
[GATE 0] Stage Startup
    |
    v
[GATE 1] Design Document
    |
    v
[GATE 2] Design Review
    |
    v
[GATE 3] Implementation & Testing
    |
    v
[GATE 4] Code Review
    |
    v
[GATE 5] Completion Check
```

## Stage Sizing Rules

- **Duration**: 1-3 days maximum
- **Scope**: Single focused feature or improvement
- **Hypotheses**: 1-3 core hypotheses per stage
- **Deliverables**: Testable, demonstrable output

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Unit tests pass (coverage >= 20%)
- [ ] E2E tests pass (at least 2 high-signal paths)
- [ ] Real environment verified
- [ ] Clean environment verified
- [ ] Design doc matches implementation
- [ ] Tech debt ledger updated
- [ ] ADR recorded
- [ ] fresh-agent-check passed

## Rollback Strategy

Each stage must define:
1. What version to rollback to
2. How to rollback
3. Data migration considerations (if any)
```

#### 4.4 Create `docs/08-autonomous-decisions.md`

```markdown
# Autonomous Decision Records (ADR)

**Last Updated**: YYYY-MM-DD

## Overview

This document records all significant autonomous decisions made during development. Each ADR captures the context, decision, and impact.

## ADR Index

| ID | Title | Stage | Date | Status |
|----|-------|-------|------|--------|
| - | (No decisions yet) | - | - | - |

---

## Decision Template

Use this template for new decisions:

```markdown
### Decision N: [Title]

**Background**: What circumstances led to this decision

**Decision**: What path was chosen

**Rationale**: Why this path was selected

**Impact on Subsequent Stages**: (Cannot be empty)
- [Specific impact on future work]
- [What this enables or constrains]

**Date**: YYYY-MM-DD

**Related Stage**: Stage N

**Alternatives Considered**:
1. [Alternative 1]: [Why not chosen]
2. [Alternative 2]: [Why not chosen]
```
```

#### 4.5 Create `docs/10-review-practices.md`

```markdown
# Review Practices

**Last Updated**: YYYY-MM-DD

## Multi-Model Review Methodology

### Triangulation Approach

1. **Main Model**: Primary development work
2. **Independent Review Model**: Fresh perspective
3. **Rule Checking**: Static analysis

### Verification Priority

When findings disagree:
1. **Authoritative sources** (documentation, specs)
2. **Code verification** (runtime behavior)
3. **Model inquiry** (ask a third model)

### False Positive Handling

- ~50% of findings are false positives
- Verify each finding independently
- Document false positives in review log

## Review Types

### Design Review (Gate 2)

Review design document before implementation:
- [ ] Goals are clear and specific
- [ ] Non-goals are explicitly stated
- [ ] Hypotheses are testable
- [ ] Acceptance criteria are measurable
- [ ] Rollback plan is defined

### Code Review (Gate 4)

Review implementation after E2E pass:
- [ ] Code follows design
- [ ] Tests cover critical paths
- [ ] No undocumented behavior
- [ ] Performance is acceptable
- [ ] Security concerns addressed

## Review Log Template

See `.claude/skills/rdd-templates.md` for the full review log template.
```

#### 4.6 Create `docs/11-next-steps.md`

```markdown
# Next Steps

**Last Updated**: YYYY-MM-DD

## Current Status

**Active Stage**: Stage 0 (Initialization)
**Overall Progress**: 0%

## Immediate Actions

1. [ ] Define project vision and goals
2. [ ] Create initial roadmap
3. [ ] Set up development environment
4. [ ] Create Stage 0 design document

## Upcoming Stages

| Stage | Title | Priority | Status | Dependencies |
|-------|-------|----------|--------|--------------|
| 0 | Initialization | P0 | Planning | None |
| 1 | [TBD] | - | - | Stage 0 |

## Blockers

None currently.

## Notes

- This project was initialized with RDD framework
- Update this document as stages progress
```

#### 4.7 Create `docs/12-technical-debt.md`

```markdown
# Technical Debt Ledger

**Last Updated**: YYYY-MM-DD

## Overview

This document tracks all known technical debt. Each entry includes priority, source, impact, and resolution plan.

## Debt Summary

| Priority | Count | Blocking |
|----------|-------|----------|
| Architecture-level | 0 | 0 |
| Module-level | 0 | 0 |
| Local | 0 | 0 |

## Active Technical Debt

(No technical debt recorded yet)

---

## Tech Debt Template

Use this template for new debt:

```markdown
### TD-NN: Short Title

- **Priority**: [Blocking / Degraded Functionality / Technical Optimization] / [Architecture-level / Module-level / Local]
- **Source**: [Proactive prototype compromise / Review deferred / Autonomous decision compromise] (Stage N)
- **Original Description**: (Quote from original document)
- **Source File**: (File path and line number, if applicable)
- **Suggested Resolution Stage**: (Stage N or "Special iteration" or "As needed")
- **Impact**: [What this debt affects]
- **Resolution Cost Estimate**: [Low / Medium / High]
- **Created Date**: YYYY-MM-DD
- **Resolved Date**: (Empty until resolved)

#### Notes
[Additional context]

#### Resolution Plan
[When and how to address]
```
```

#### 4.8 Create `docs/stages/stage-roadmap.md`

```markdown
# Project Roadmap

**Last Updated**: YYYY-MM-DD
**Current Stage**: Stage 0
**Overall Progress**: 0%

---

## Vision

[Project vision - one paragraph describing the ultimate goal]

---

## Stage Overview

| Stage | Title | Status | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| 0 | Initialization | Planning | P0 | None |

---

## Stage Details

### Stage 0: Initialization

**Status**: Planning
**Goal**: Set up project foundation and infrastructure
**Prerequisites**: None
**Estimated Effort**: Small

---

## Current Focus

**Active Stage**: Stage 0
**Current Objective**: Initialize RDD framework and project structure
**Blockers**: None
**Next Milestone**: Complete Stage 0

---

## Roadmap History

| Date | Change | Reason |
|------|--------|--------|
| YYYY-MM-DD | Initial roadmap created | Project initialization |

---

## Priority Definitions

- **P0**: Must complete for MVP / Core functionality
- **P1**: Important for complete product experience
- **P2**: Nice to have, can be deferred
- **P3**: Future consideration
```

#### 4.9 Create `docs/stages/stage-template.md`

```markdown
# Stage Template

Use this template when creating new stage documents at `docs/stages/stage-N.md`.

---

# Stage N: [Title]

## Status
[ ] Planning / [ ] In Progress / [ ] Complete

## Goals
What this stage specifically solves (be precise and limited)

## Non-Goals
What this stage explicitly does NOT do (be explicit about scope boundaries)

## Core Hypotheses
- Hypothesis A: [Description of what you're trying to validate]
- Hypothesis B: [Description of what you're trying to validate]

## Acceptance Criteria
- [ ] Acceptance criterion A (must be testable)
- [ ] Acceptance criterion B (must be testable)

## Rollback Plan
Which version to fall back to if this stage fails

## Known Limitations
- [Limitation A - may become technical debt]
- [Limitation B - may become technical debt]

## Impact on Subsequent Stages
- [Impact A - what this stage enables or constrains]
- [Impact B - what this stage enables or constrains]

---

## Implementation Notes (Filled during implementation)

### Implementation Differences
[Document any differences from original design]

### Technical Decisions Made
[Document any technical decisions made during implementation]

### Testing Evidence
- Unit test coverage: X%
- E2E tests: [list test names]
- Real environment verification: [description]
- Clean environment verification: [description]

### Handoff Notes
[What the next agent needs to know]
```

### Step 5: Agent Entry Points Setup

#### 5.1 Create `AGENTS.md`

```markdown
# Agent Entry Point

> This is the primary entry point for all AI agents working on this project.

## Mandatory Reading Order

1. **Start Here**: `docs/01-charter.md` - Project vision and goals
2. **Process**: `docs/03-stage-based-development.md` - How we work
3. **Principles**: `docs/02-engineering-principles.md` - Engineering standards
4. **Current State**: `docs/stages/stage-roadmap.md` - Where we are
5. **Next Actions**: `docs/11-next-steps.md` - What to do next
6. **Decisions**: `docs/08-autonomous-decisions.md` - Past decisions
7. **Debt**: `docs/12-technical-debt.md` - Known issues

## RDD Skills

- **rdd-core**: Core RDD concepts and workflow
- **rdd-templates**: Document templates for all artifacts
- **rdd-init**: Initialize new RDD projects
- **rdd-migrate**: Migrate existing projects to RDD

## Document Update Obligations

When completing work, you MUST update:

1. **Stage document** (`docs/stages/stage-N.md`) - Implementation differences
2. **Review log** (`docs/stages/stage-N-review-log.md`) - Review findings
3. **Decisions** (`docs/08-autonomous-decisions.md`) - New ADRs
4. **Tech debt** (`docs/12-technical-debt.md`) - New or resolved debt
5. **Next steps** (`docs/11-next-steps.md`) - Progress update
6. **Changelog** (`CHANGELOG.md`) - Change summary

## Stage Promotion Rules

Before completing a stage, verify:

- [ ] All acceptance criteria met
- [ ] Tests pass (unit + E2E)
- [ ] Real environment verified
- [ ] Clean environment verified
- [ ] Design doc matches implementation
- [ ] Tech debt ledger updated
- [ ] ADR recorded with impact
- [ ] fresh-agent-check passed

## Review Rules

- Use multi-model triangulation
- Verify ~50% false positive rate
- Document findings in review log
- Escalate low-confidence findings
```

#### 5.2 Create `CLAUDE.md`

```markdown
# Claude Code Entry Point

> Quick reference for Claude Code when working with this RDD project.

## Quick Start

```
# Initialize project (first time)
task bootstrap

# Check project health
task doctor

# Verify current stage
task stage:verify

# Run gate checks
task stage:gate
```

## RDD Commands

| Command | Purpose |
|---------|---------|
| `/rdd-init` | Initialize new RDD project |
| `/rdd-migrate` | Migrate existing project |
| `/rdd-roadmap` | Manage roadmap |
| `/rdd-stage-auto` | Execute stage with gates |
| `/rdd-review-auto` | Automated review |
| `/rdd-knowledge` | Knowledge management |
| `/rdd-diagnosis` | Diagnose issues |
| `/rdd-fresh-check` | Verify fresh agent can take over |

## Key Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent entry point (start here) |
| `docs/01-charter.md` | Project vision |
| `docs/stages/stage-roadmap.md` | Current status |
| `docs/11-next-steps.md` | Immediate actions |
| `.rdd/config.yml` | RDD configuration |

## Gate Checklist

- **Gate 0**: Prerequisites verified
- **Gate 1**: Design doc created
- **Gate 2**: Design reviewed
- **Gate 3**: Implementation + tests
- **Gate 4**: Code reviewed
- **Gate 5**: Completion verified

## Tool Usage Rules

1. Read existing files before editing
2. Use Grep for searching code
3. Use Glob for finding files
4. Use Bash for git operations
5. Create commits with descriptive messages
```

#### 5.3 Create `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- RDD framework initialized
- Project structure created
- Documentation templates added

## [0.1.0] - YYYY-MM-DD

### Added
- Initial project setup
- RDD framework integration
```

### Step 6: Placeholder Files

Create `.gitkeep` files for empty directories:

```bash
touch .rdd/cache/.gitkeep
touch .rdd/scripts/.gitkeep
touch .rdd/hooks/.gitkeep
```

### Step 7: Skills and Commands Setup

Create placeholder files for skills and commands directories:

```bash
touch .claude/skills/.gitkeep
touch .claude/commands/.gitkeep
```

---

## Validation Checklist

After initialization, verify:

### Directory Structure

```bash
# Verify all directories exist
[ ] .rdd/
[ ] .rdd/cache/
[ ] .rdd/scripts/
[ ] .rdd/hooks/
[ ] docs/
[ ] docs/framework/
[ ] docs/stages/
[ ] docs/handoff/
[ ] .claude/
[ ] .claude/skills/
[ ] .claude/commands/
```

### Configuration Files

```bash
# Verify configuration files exist and are valid YAML
[ ] .rdd/config.yml
[ ] .rdd/hooks.yml
[ ] .rdd/templates.yml
[ ] .rdd/checkpoints.yml
```

### Documentation Files

```bash
# Verify documentation files exist
[ ] docs/01-charter.md
[ ] docs/02-engineering-principles.md
[ ] docs/03-stage-based-development.md
[ ] docs/08-autonomous-decisions.md
[ ] docs/10-review-practices.md
[ ] docs/11-next-steps.md
[ ] docs/12-technical-debt.md
[ ] docs/stages/stage-roadmap.md
[ ] docs/stages/stage-template.md
```

### Entry Point Files

```bash
# Verify entry point files exist
[ ] AGENTS.md
[ ] CLAUDE.md
[ ] CHANGELOG.md
```

### Content Validation

```bash
# Verify key content is present
[ ] .rdd/config.yml has project name placeholder
[ ] docs/01-charter.md has vision section
[ ] docs/stages/stage-roadmap.md has Stage 0
[ ] docs/11-next-steps.md has initialization tasks
[ ] AGENTS.md has mandatory reading order
```

### Optional Git Setup

```bash
# If using git
[ ] .gitignore includes .rdd/cache/
[ ] Initial commit created
```

---

## Post-Initialization

After successful initialization:

1. **Update project information**:
   - Edit `.rdd/config.yml` with actual project name and description
   - Edit `docs/01-charter.md` with project vision
   - Edit `docs/stages/stage-roadmap.md` with initial stages

2. **Configure notifications** (optional):
   - Edit `.rdd/hooks.yml` to enable notification channels
   - Set environment variables for credentials

3. **Create first stage**:
   - Copy `docs/stages/stage-template.md` to `docs/stages/stage-0.md`
   - Fill in Stage 0 details for project initialization

4. **Run health check**:
   - Execute `task doctor` to verify setup
   - Fix any reported issues

---

## Troubleshooting

### Directory Already Exists

If `.rdd/` directory already exists:
- Check if project is already initialized
- Use `/rdd-migrate` instead for existing projects
- Or manually remove `.rdd/` and reinitialize (WARNING: loses configuration)

### Permission Denied

If write permissions are missing:
- Check directory ownership: `ls -la`
- Fix permissions: `chmod -R u+w .`
- Run from correct directory

### YAML Parse Errors

If configuration files have syntax errors:
- Validate YAML: `python -c "import yaml; yaml.safe_load(open('.rdd/config.yml'))"`
- Check for tab characters (use spaces)
- Verify indentation is consistent

### Missing Dependencies

If Task commands fail:
- Install Task: `sh -c "$(curl --location https://taskfile.dev/install.sh)"`
- Verify installation: `task --version`

---

## Reference

For more information:
- `/data/works/play/sbd/.claude/skills/rdd-core.md` - Core RDD concepts
- `/data/works/play/sbd/.claude/skills/rdd-templates.md` - Document templates
- `/data/works/play/sbd/docs/plans/2026-03-06-rdd-framework.md` - Implementation plan
