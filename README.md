# RDD (Roadmap Driven Development) Framework

A disciplined development framework for AI agents, inspired by Gary's Stage-Based Development methodology.

## Overview

RDD (Roadmap Driven Development) provides a structured approach to software development where:

- **Humans define the Roadmap** - Strategic direction and priorities
- **Agents execute Stages** - Autonomous implementation with quality gates
- **Quality is built-in** - Multi-model review, explicit knowledge, and continuous verification

### Core Principles

1. **Roadmap Driven** - Human controls strategy at Roadmap level, agents execute autonomously
2. **Stage as Delivery Unit** - Small, verifiable, rollback-capable increments
3. **Five-Layer Gate Check** - Quality gates at every stage transition
4. **Explicit Knowledge** - No tacit knowledge, everything documented
5. **Multi-Model Verification** - Triangulation with ~50% false positive filtering
6. **Hook Notifications** - Proactive human notification at checkpoints

## Quick Start

### Initialize a New Project

```bash
# Initialize RDD in current directory
/rdd-init

# Or with project name
/rdd-init my-project
```

### Migrate Existing Project

```bash
# Migrate existing project to RDD
/rdd-migrate
```

### Execute a Stage

```bash
# Execute current stage with all gates
/rdd-stage-auto

# Execute specific stage
/rdd-stage-auto 3
```

### Manage Knowledge

```bash
# Record a decision
/rdd-knowledge adr --title "Use SQLite for caching"

# Record technical debt
/rdd-knowledge debt --title "Single-threaded cache" --priority high

# Generate handoff document
/rdd-knowledge handoff

# Run fresh-agent-check
/rdd-knowledge check
```

## Directory Structure

```
project/
├── .rdd/                          # RDD configuration
│   ├── config.yml                 # Main configuration
│   ├── hooks.yml                  # Notification channels
│   ├── templates.yml              # Message templates
│   ├── checkpoints.yml            # Checkpoint definitions
│   ├── cache/                     # Runtime cache
│   ├── scripts/                   # Hook scripts
│   │   └── notify.sh              # Notification dispatcher
│   └── hooks/                     # Lifecycle hooks
│       ├── stage-complete.sh
│       ├── roadmap-change.sh
│       ├── consecutive-failure.sh
│       └── ...
├── .claude/                       # Claude Code integration
│   ├── skills/                    # Skill definitions
│   │   ├── rdd-core.md
│   │   ├── rdd-init.md
│   │   ├── rdd-stage-auto.md
│   │   ├── rdd-knowledge.md
│   │   ├── rdd-loop.md
│   │   ├── rdd-review-auto.md
│   │   ├── rdd-recovery.md
│   │   ├── rdd-diagnosis.md
│   │   └── rdd-fresh-check.md
│   └── commands/                  # Command definitions
│       ├── rdd-init.md
│       ├── rdd-migrate.md
│       ├── rdd-roadmap.md
│       ├── rdd-stage-auto.md
│       ├── rdd-knowledge.md
│       └── rdd-loop.md
├── docs/
│   ├── framework/                 # Governance documents
│   │   ├── project-governance-spec.md
│   │   ├── agentic-code-execution-spec.md
│   │   └── standards-authoring-spec.md
│   ├── stages/                    # Stage documents
│   │   ├── stage-roadmap.md       # Project roadmap
│   │   ├── stage-template.md      # Stage template
│   │   └── stage-N.md             # Individual stages
│   ├── handoff/                   # Handoff documents
│   │   └── handoff-latest.md
│   ├── 01-charter.md              # Project charter
│   ├── 02-engineering-principles.md
│   ├── 03-stage-based-development.md
│   ├── 08-autonomous-decisions.md  # ADRs
│   ├── 10-review-practices.md
│   ├── 11-next-steps.md
│   └── 12-technical-debt.md       # Tech debt ledger
├── AGENTS.md                      # Agent entry point
├── CLAUDE.md                      # Claude Code quick reference
├── CHANGELOG.md                   # Project history
└── Taskfile.yml                   # Task commands
```

## Five-Layer Gate Check

RDD implements five quality gates for each stage:

| Gate | Name | Purpose |
|------|------|---------|
| Gate 0 | Stage Startup | Verify prerequisites |
| Gate 1 | Design Document | Ensure design exists before coding |
| Gate 2 | Design Review | Validate design with multi-model review |
| Gate 3 | Implementation | Execute and test |
| Gate 4 | Code Review | Validate implementation |
| Gate 5 | Completion | Verify all criteria met |

### Gate Flow

```
Gate 0: Stage Startup
    ↓
Gate 1: Design Document Created
    ↓
Gate 2: Design Review Passed
    ↓
Gate 3: Implementation + Tests Pass
    ↓
Gate 4: Code Review Passed
    ↓
Gate 5: All Criteria Verified
    ↓
Stage Complete
```

## Hook Notifications

RDD supports multiple notification channels for proactive human notification:

### Supported Channels

| Channel | Use Case |
|---------|----------|
| WeChat (WeCom) | Team notifications |
| Email | Detailed reports |
| iOS Bark | Mobile push |
| Telegram | Instant messaging |
| Webhook | Custom integrations |

### Trigger Types

| Trigger | Priority | Description |
|---------|----------|-------------|
| `roadmap_change` | P1 | Roadmap updated by human |
| `consecutive_failure` | P0 | Multiple failures detected |
| `hypothesis_invalid` | P1 | Core hypothesis invalidated |
| `model_disagreement` | P2 | Significant model disagreement |
| `tech_debt_threshold` | P1 | Tech debt exceeds threshold |
| `stage_complete` | P2 | Stage completed successfully |
| `daily_report` | P3 | Daily progress report |
| `weekly_report` | P3 | Weekly progress report |

### Configuration

Edit `.rdd/hooks.yml` to configure notification channels:

```yaml
channels:
  wecom:
    enabled: true
    webhook_url: "${WECOM_WEBHOOK_URL}"

  email:
    enabled: true
    smtp_host: "${SMTP_HOST}"
    # ...

triggers:
  stage_complete:
    enabled: true
    channels: [wecom, email]
    priority: "normal"
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `/rdd-init` | Initialize new RDD project |
| `/rdd-migrate` | Migrate existing project |
| `/rdd-roadmap` | Manage roadmap |
| `/rdd-stage-auto` | Execute stage with gates |
| `/rdd-knowledge` | Manage ADRs, tech debt, handoffs |
| `/rdd-loop` | Control autonomous execution |
| `/rdd-review-auto` | Run multi-model review |
| `/rdd-recovery` | Recover from failures |
| `/rdd-diagnosis` | Diagnose issues |
| `/rdd-fresh-check` | Verify documentation completeness |

## Skills Reference

| Skill | Description |
|-------|-------------|
| `rdd-core` | Core RDD concepts and workflow |
| `rdd-templates` | Document templates |
| `rdd-init` | Project initialization |
| `rdd-migrate` | Project migration |
| `rdd-roadmap` | Roadmap management |
| `rdd-stage-auto` | Autonomous stage execution |
| `rdd-knowledge` | Knowledge management |
| `rdd-loop` | Execution loop control |
| `rdd-review-auto` | Automated review |
| `rdd-recovery` | Failure recovery |
| `rdd-diagnosis` | Issue diagnosis |
| `rdd-fresh-check` | Documentation verification |

## Anti-Corruption Mechanisms

RDD enforces nine prohibited behaviors to prevent project corruption:

1. **No Silent Roadmap Changes** - Roadmap changes require human approval
2. **No Scope Creep** - Stage scope must match roadmap definition
3. **No Tacit Knowledge** - All context must be documented
4. **No Skipping Gates** - All gates must pass in order
5. **No Undocumented Decisions** - All decisions recorded as ADRs
6. **No Hidden Debt** - All issues tracked in tech debt ledger
7. **No Consensus Trust** - Verify findings, don't trust consensus
8. **No Silent Failures** - All failures logged and handled
9. **No Review Bypass** - Critical findings must be addressed

## Technical Debt Management

### Debt Categories

| Priority | Definition |
|----------|------------|
| **Blocking** | Prevents other work |
| **Degraded Functionality** | Works but imperfect |
| **Technical Optimization** | Code quality issues |

### Debt Levels

| Level | Scope |
|-------|-------|
| **Architecture-level** | Affects multiple modules |
| **Module-level** | Single module/component |
| **Local** | Single file/function |

### Discovery Channels

1. Proactive prototype compromise
2. Review deferred
3. Autonomous decision compromise
4. fresh-agent-check failure

## Multi-Model Review

RDD uses triangulation for verification:

```
Main Model → Primary implementation
     ↓
Independent Review Model → Fresh perspective
     ↓
Rule Checking → Automated patterns
     ↓
Triangulation → Merge findings, filter false positives
```

### False Positive Handling

Expect ~50% false positives in AI review findings. Pre-filter:

1. Check for context - does finding assume unavailable context?
2. Check for accuracy - is finding factually correct?
3. Check for applicability - does this apply to our project?
4. Check for priority - is severity appropriate?

Document all filter decisions in review log.

## Knowledge Management

### ADR (Autonomous Decision Record)

Every significant decision must be recorded:

```markdown
### Decision N: [Title]

**Background**: What circumstances led to this decision
**Decision**: What path was chosen
**Rationale**: Why this path was selected
**Impact on Subsequent Stages**: (Cannot be empty!)
- [Specific impact on future work]
**Date**: YYYY-MM-DD
**Related Stage**: Stage N
```

### Handoff Document

For session transitions:

```markdown
# Agent Handoff Document

## Current Progress
- Phase: [Planning/In Progress/Review/Complete]
- Current Gate: Gate X
- Progress: X%

## Completed Evidence
- [Artifacts created]
- [Tests passed]

## Blockers
- [Current blockers]

## Next Single Action
- [Specific, actionable step]
```

## Configuration

### config.yml

Main RDD configuration:

```yaml
version: "1.0.0"
project:
  name: "My Project"
  description: "Project description"

stage:
  min_coverage: 20
  max_failures: 3
  tech_debt_threshold: 3

gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

hooks:
  enabled: true
  config_file: ".rdd/hooks.yml"
```

## Task Commands

RDD includes a Taskfile with useful commands:

```bash
# Verify project health
task doctor

# Run tests
task test

# Run specific stage verification
task stage:verify

# Run gate checks
task stage:gate

# Generate reports
task report:daily
task report:weekly
```

## Contributing

1. Read the framework documentation in `docs/framework/`
2. Understand the stage-based development model
3. Follow the gate check procedures
4. Record all decisions as ADRs
5. Track all issues as tech debt

## License

[Specify your license here]

## References

- [Stage-Based Development](docs/03-stage-based-development.md)
- [Engineering Principles](docs/02-engineering-principles.md)
- [Review Practices](docs/10-review-practices.md)
- [Project Charter](docs/01-charter.md)
