---
name: rdd-migrate
description: Migrate an existing project to RDD framework, preserving existing structure and documentation
---

# RDD Migration Skill

> Migrate existing projects to RDD (Roadmap Driven Development) paradigm

## Overview

This skill guides the migration of existing projects to the RDD development paradigm. It analyzes project structure, code, and documentation to create a comprehensive RDD-compatible project organization without disrupting existing work.

**When to Use:**
- Converting an existing project to RDD structure
- Onboarding legacy projects to stage-based development
- Establishing RDD practices in projects with existing codebases

---

## Migration Workflow

### Phase 1: Project Analysis

#### 1.1 Structure Discovery

Analyze the existing project structure to understand:

```
Project Analysis Checklist:
- [ ] Identify project type (library, service, application, CLI)
- [ ] Map existing directory structure
- [ ] Identify existing documentation files
- [ ] Find configuration files (package.json, Cargo.toml, go.mod, etc.)
- [ ] Locate test directories and patterns
- [ ] Identify build/deployment scripts
- [ ] Find existing CHANGELOG or version history
- [ ] Identify existing ADRs or decision logs
```

#### 1.2 Code Analysis

Scan the codebase for:

```
Code Analysis Checklist:
- [ ] Main entry points and core modules
- [ ] Key abstractions and interfaces
- [ ] External dependencies
- [ ] Test coverage status
- [ ] TODO/FIXME/HACK comments (technical debt indicators)
- [ ] Configuration patterns
- [ ] Error handling patterns
```

#### 1.3 Documentation Gap Analysis

Identify missing RDD documentation:

```
Documentation Gap Checklist:
- [ ] Is there a project charter? (charter.md)
- [ ] Are engineering principles documented?
- [ ] Is there any roadmap or milestone tracking?
- [ ] Are design decisions recorded? (ADRs)
- [ ] Is technical debt tracked explicitly?
- [ ] Is there a handoff mechanism for agent continuity?
```

#### 1.4 State Assessment

Determine current project state:

```
State Assessment Questions:
- What is the current development phase?
- What features are complete/in-progress/planned?
- Are there any active branches or work-in-progress?
- What are the known issues or blockers?
- What technical debt exists?
```

---

### Phase 2: Migration Planning

#### 2.1 Create Migration Plan Document

Generate a migration plan at `docs/migration/migration-plan.md`:

```markdown
# RDD Migration Plan

**Project**: [Project Name]
**Migration Date**: YYYY-MM-DD
**Current State**: [Description]

## Analysis Summary

### Project Type
[Library/Service/Application/CLI]

### Current Structure
[Brief description of existing structure]

### Key Findings
- Finding 1
- Finding 2
- Finding 3

## Migration Roadmap

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Create RDD directory structure | P0 | [ ] |
| 2 | Create project charter | P0 | [ ] |
| 3 | Document engineering principles | P0 | [ ] |
| 4 | Create initial roadmap | P0 | [ ] |
| 5 | Document existing ADRs | P1 | [ ] |
| 6 | Create technical debt ledger | P1 | [ ] |
| 7 | Create handoff documentation | P1 | [ ] |
| 8 | Set up hooks configuration | P2 | [ ] |

## Existing Technical Debt

| ID | Description | Priority | Source |
|----|-------------|----------|--------|
| TD-01 | [From TODO/FIXME scan] | [Priority] | [File:line] |

## Decisions Required

- [ ] Decision 1: [Description]
- [ ] Decision 2: [Description]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | H/M/L | H/M/L | [Strategy] |
```

#### 2.2 Define Migration Stages

Break migration into stages:

**Stage 0: Foundation Setup**
- Create `.rdd/` directory with configuration
- Create `docs/` directory structure
- Create basic RDD documents (charter, principles)

**Stage 1: Current State Documentation**
- Document existing architecture
- Create initial roadmap from current understanding
- Record known technical debt

**Stage 2: History Capture**
- Convert past decisions to ADRs
- Create Stage 0 design document for completed work
- Update CHANGELOG with historical entries

**Stage 3: Process Integration**
- Create Taskfile.yml entries for RDD workflows
- Set up hook notifications (if applicable)
- Create AGENTS.md and CLAUDE.md entry points

---

### Phase 3: Document Transformation

#### 3.1 Create RDD Directory Structure

Create the standard RDD directory structure:

```
.rdd/
├── config.yml
├── hooks.yml (optional)
└── cache/
    ├── context.json
    └── state.json

docs/
├── framework/
│   ├── project-governance-spec.md
│   ├── agentic-code-execution-spec.md
│   └── standards-authoring-spec.md
├── stages/
│   ├── stage-roadmap.md
│   └── stage-0.md (current/most recent stage)
├── handoff/
│   └── handoff-latest.md
├── 01-charter.md
├── 02-engineering-principles.md
├── 03-stage-based-development.md
├── 08-autonomous-decisions.md
├── 10-review-practices.md
├── 11-next-steps.md
└── 12-technical-debt.md
```

#### 3.2 Create Project Charter (`docs/01-charter.md`)

From existing project documentation, extract:

```markdown
# Project Charter

## Vision
[One paragraph describing what this project aims to achieve]

## Scope
### In Scope
- [What the project does]

### Out of Scope
- [What the project explicitly does not do]

## Success Criteria
- [How success is measured]

## Stakeholders
- [Who cares about this project]

## Timeline
- [High-level timeline or "Continuous Development"]

## Resources
- [Key dependencies, technologies]
```

#### 3.3 Create Engineering Principles (`docs/02-engineering-principles.md`)

Extract or define principles from codebase patterns:

```markdown
# Engineering Principles

## Core Principles
1. [Principle observed in codebase]
2. [Principle observed in codebase]
3. [Principle observed in codebase]

## Coding Standards
- [Standards observed or to be adopted]

## Testing Philosophy
- [Testing patterns observed]

## Documentation Requirements
- [Documentation standards]
```

#### 3.4 Create Initial Roadmap (`docs/stages/stage-roadmap.md`)

From existing features/plans, create roadmap:

```markdown
# Project Roadmap

**Last Updated**: YYYY-MM-DD
**Current Stage**: Stage N
**Overall Progress**: X%

## Vision
[Project vision]

## Stage Overview

| Stage | Title | Status | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| 0 | Foundation | Complete | P0 | None |
| 1 | [Current Work] | In Progress | P0 | Stage 0 |
| 2 | [Next Feature] | Planning | P1 | Stage 1 |

## Current Focus
**Active Stage**: Stage N
**Current Objective**: [What's being worked on]
```

#### 3.5 Document Technical Debt (`docs/12-technical-debt.md`)

From codebase scan, create debt ledger:

```markdown
# Technical Debt Ledger

## Active Debt

### TD-01: [Title from TODO/FIXME]
- **Priority**: [Blocking/Degraded Functionality/Technical Optimization]
- **Source**: [File:line]
- **Original Description**: [Quote from code comment]
- **Suggested Resolution Stage**: [Stage N or "Special iteration"]
- **Created Date**: YYYY-MM-DD

## Resolved Debt
[Empty initially, populated as debt is addressed]
```

#### 3.6 Create ADRs from Past Decisions (`docs/08-autonomous-decisions.md`)

Document significant past decisions:

```markdown
# Autonomous Decisions Log

## Decision History

### Decision 1: [Past Decision Title]

**Background**: [What circumstances led to this decision]

**Decision**: [What path was chosen]

**Rationale**: [Why this path was selected]

**Impact on Subsequent Stages**:
- [How this affects future work]

**Date**: YYYY-MM-DD (approximate if unknown)

**Related Stage**: Stage 0 (Historical)

**Alternatives Considered**:
1. [Alternative 1]: [Why not chosen]
2. [Alternative 2]: [Why not chosen]
```

#### 3.7 Create Handoff Document (`docs/handoff/handoff-latest.md`)

Capture current state for agent continuity:

```markdown
# Agent Handoff Document

Generated: YYYY-MM-DD
Previous Agent: Migration
Current Stage: Stage N

## Current Progress

**Phase**: [Phase description]
**Progress Percentage**: X%
**Current Gate**: Gate 0

## Context for New Agent

### Project Overview
[Brief description of what this project does]

### Key Files to Read First
1. [Critical file 1] - [Why important]
2. [Critical file 2] - [Why important]

### Important Context
- [Context that isn't obvious from documents]
- [Any implicit knowledge that should be explicit]

### Commands to Know
- `task [command]` - [Description]

## Next Single Action

**Immediate Next Step**: [What to do next]

**How to Execute**:
1. [Step 1]
2. [Step 2]
```

#### 3.8 Create Entry Points

**AGENTS.md**:
```markdown
# Agent Entry Point

This project follows RDD (Roadmap Driven Development) paradigm.

## Quick Start

1. Read `docs/stages/stage-roadmap.md` for project overview
2. Read `docs/handoff/handoff-latest.md` for current state
3. Read `docs/12-technical-debt.md` for known issues
4. Proceed with current Stage from appropriate Gate

## Key Documents

| Document | Purpose |
|----------|---------|
| `docs/01-charter.md` | Project vision and scope |
| `docs/stages/stage-roadmap.md` | Current roadmap |
| `docs/08-autonomous-decisions.md` | Decision history |
| `docs/12-technical-debt.md` | Technical debt ledger |

## RDD Skills Available

- `/rdd-core` - Core RDD concepts
- `/rdd-templates` - Document templates
- `/rdd-migrate` - Migration guide
```

**CLAUDE.md**:
```markdown
# Claude Code Entry Point

This project uses RDD (Roadmap Driven Development).

## Getting Started

For Claude Code agents:
1. Start with `docs/handoff/handoff-latest.md`
2. Check `docs/stages/stage-roadmap.md` for current stage
3. Follow the Stage progression through the Gates

## Core Principles

- Humans define Roadmap, Agents execute Stages
- Every Stage is verifiable, rollback-capable, handoff-ready
- Documentation is synchronous - no "docs pending"
- All technical debt must be visible in the ledger

## Reference

See `.claude/skills/rdd-core/SKILL.md` for detailed RDD specification.
```

---

### Phase 4: Configuration Setup

#### 4.1 Create RDD Configuration (`.rdd/config.yml`)

```yaml
# RDD Configuration
project:
  name: [Project Name]
  type: [library|service|application|cli]

stages:
  directory: docs/stages
  current: 0

hooks:
  enabled: false  # Enable after configuring hooks.yml

notifications:
  default_level: P2

documentation:
  auto_sync: true
  templates: .claude/skills/rdd-templates/SKILL.md
```

#### 4.2 Create Hooks Configuration (`.rdd/hooks.yml`)

```yaml
# Hook Notification Configuration
# Uncomment and configure channels as needed

channels:
  # wecom:
  #   webhook_url: ${WECOM_WEBHOOK_URL}
  # email:
  #   smtp_host: ${SMTP_HOST}
  #   smtp_port: 587
  #   from: ${SMTP_FROM}
  #   to: ${SMTP_TO}
  # bark:
  #   server: ${BARK_SERVER}
  #   key: ${BARK_KEY}
  # telegram:
  #   bot_token: ${TELEGRAM_BOT_TOKEN}
  #   chat_id: ${TELEGRAM_CHAT_ID}
  # webhook:
  #   url: ${WEBHOOK_URL}
  #   method: POST
  #   headers:
  #     Content-Type: application/json

triggers:
  roadmap_change:
    level: P0
    channels: [wecom, email]
    block: true

  consecutive_failure:
    level: P0
    channels: [wecom, bark, telegram]
    block: true
    condition:
      failure_count: 3

  stage_complete:
    level: P2
    channels: [wecom]
    block: false
```

#### 4.3 Create Taskfile Entries

Add to `Taskfile.yml`:

```yaml
version: '3'

tasks:
  # RDD Commands
  rdd:status:
    desc: Show RDD project status
    cmds:
      - echo "Current Stage: $(grep 'Current Stage' docs/stages/stage-roadmap.md || echo 'Unknown')"
      - echo "Check docs/handoff/handoff-latest.md for details"

  rdd:roadmap:
    desc: Show project roadmap
    cmds:
      - cat docs/stages/stage-roadmap.md

  rdd:debt:
    desc: Show technical debt
    cmds:
      - cat docs/12-technical-debt.md

  rdd:handoff:
    desc: Show handoff document
    cmds:
      - cat docs/handoff/handoff-latest.md

  rdd:fresh-check:
    desc: Verify new agent can take over
    cmds:
      - echo "Checking if documentation is sufficient for new agent..."
      - test -f docs/stages/stage-roadmap.md || (echo "ERROR: Missing roadmap" && exit 1)
      - test -f docs/handoff/handoff-latest.md || (echo "ERROR: Missing handoff" && exit 1)
      - test -f docs/12-technical-debt.md || (echo "ERROR: Missing tech debt ledger" && exit 1)
      - echo "PASS: All required documents present"
```

---

### Phase 5: Validation

#### 5.1 Pre-Validation Checklist

Before marking migration complete:

```
Migration Validation Checklist:
- [ ] .rdd/ directory created with config.yml
- [ ] docs/ directory structure matches RDD specification
- [ ] Project charter exists and is meaningful
- [ ] Engineering principles documented
- [ ] Initial roadmap created with current stage
- [ ] Technical debt ledger created (even if empty)
- [ ] ADR log created for past decisions
- [ ] Handoff document captures current state
- [ ] AGENTS.md entry point exists
- [ ] CLAUDE.md entry point exists
- [ ] CHANGELOG.md has migration entry
- [ ] Taskfile.yml has RDD commands
```

#### 5.2 Fresh Agent Check

Verify migration success with fresh-agent-check:

```
Fresh Agent Check:
1. Can a new agent understand the project from docs/01-charter.md?
2. Can a new agent identify current work from docs/handoff/handoff-latest.md?
3. Can a new agent understand what to do next from docs/stages/stage-roadmap.md?
4. Can a new agent identify known issues from docs/12-technical-debt.md?
5. Can a new agent understand past decisions from docs/08-autonomous-decisions.md?
```

#### 5.3 Migration Completion

When validation passes:

1. Update `docs/stages/stage-roadmap.md`:
   - Set Stage 0 status to "Complete"
   - Set Stage 1 (next stage) to "Planning"

2. Create migration ADR in `docs/08-autonomous-decisions.md`:
   ```markdown
   ### Decision N: RDD Migration

   **Background**: Project migrated to RDD paradigm for improved agent-driven development

   **Decision**: Adopted RDD structure with full documentation suite

   **Rationale**: Enables near-fully-autonomous agent-driven development with minimal human intervention

   **Impact on Subsequent Stages**:
   - All future work follows Stage-based progression
   - Technical debt must be explicitly tracked
   - Documentation updates are synchronous with code changes

   **Date**: YYYY-MM-DD
   ```

3. Update `CHANGELOG.md`:
   ```markdown
   ## [Migration] - YYYY-MM-DD

   ### Added
   - RDD directory structure (.rdd/)
   - Project charter (docs/01-charter.md)
   - Engineering principles (docs/02-engineering-principles.md)
   - Initial roadmap (docs/stages/stage-roadmap.md)
   - Technical debt ledger (docs/12-technical-debt.md)
   - ADR log (docs/08-autonomous-decisions.md)
   - Handoff documentation (docs/handoff/handoff-latest.md)
   - Entry points (AGENTS.md, CLAUDE.md)
   - Taskfile RDD commands

   ### Changed
   - Project structure aligned with RDD specification
   ```

---

## Migration Patterns

### Pattern 1: Greenfield Project

For new projects with minimal existing code:
- Focus on creating complete RDD structure
- Set Stage 0 as "Foundation" with project setup tasks
- Technical debt ledger starts empty

### Pattern 2: Active Development

For projects in active development:
- Document current state as Stage N
- Create Stage 0 for historical work
- Capture in-progress work as current Stage
- Document all known TODOs as technical debt

### Pattern 3: Maintenance Mode

For mature projects in maintenance:
- Document completed features as historical Stages
- Create minimal roadmap focused on maintenance
- Focus technical debt ledger on known issues

### Pattern 4: Rescue Project

For projects needing significant refactoring:
- Document current state honestly
- Create roadmap focused on stabilization
- Technical debt ledger is critical - capture everything
- Plan remediation Stages explicitly

---

## Common Issues and Solutions

### Issue: Missing Historical Context

**Symptom**: Don't know why decisions were made

**Solution**:
- Document what is known
- Mark unknowns explicitly
- Create ADRs for implicit decisions discovered during analysis
- Note gaps in handoff document

### Issue: Inconsistent Existing Documentation

**Symptom**: Multiple README files, outdated docs

**Solution**:
- Consolidate into RDD structure
- Keep historical docs in archive folder
- Extract relevant info into RDD docs
- Update or remove outdated docs

### Issue: No Clear Stage Boundaries

**Symptom**: Hard to define what constitutes a Stage

**Solution**:
- Use feature releases as Stage boundaries
- Focus on current work + near-term plans
- Stages can be coarse-grained initially
- Refine as project progresses

### Issue: Too Much Technical Debt

**Symptom**: Overwhelming number of TODOs/FIXMEs

**Solution**:
- Prioritize by impact (blocking vs. degraded vs. optimization)
- Focus on "blocking" debt first
- Create remediation Stages in roadmap
- Accept that some debt will be "as needed"

---

## Post-Migration

After successful migration:

1. **Verify Hook Notifications** (if configured)
   - Test P2 notification with stage complete trigger
   - Verify channels are working

2. **Begin RDD Workflow**
   - Start with current Stage
   - Follow Gate progression
   - Update documents synchronously

3. **Iterate on Documentation**
   - Refine charter as understanding improves
   - Add ADRs for new decisions
   - Keep tech debt ledger current

---

## Reference

For detailed RDD specification, see:
- `prompt.md` - Full RDD specification
- `.claude/skills/rdd-core/SKILL.md` - Core RDD concepts
- `.claude/skills/rdd-templates/SKILL.md` - Document templates
