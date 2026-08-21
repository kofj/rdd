---
name: rdd-core
description: RDD core philosophy and paradigm reference: humans lay the roadmap, agents execute autonomously
disable-model-invocation: true
---

# RDD (Roadmap Driven Development) Core Skill

> **Core Philosophy**: Humans lay the tracks (Roadmap), Agents move along the tracks autonomously

## Overview

RDD (Roadmap Driven Development) is a development paradigm designed to minimize human intervention and achieve near-fully-autonomous Agent-driven development. It combines Stage-Based Development principles with structured knowledge management, multi-model verification, and automated notification systems.

**Why RDD Matters:**
- Reduces human intervention to minimum while maintaining quality
- Enables seamless handoff between different AI agents
- Provides structured approach to technical debt management
- Ensures documentation stays synchronized with implementation
- Supports automatic recovery and 24/7 autonomous progression

---

## Core Principles

### 1. Roadmap Driven
- Humans lay the tracks, defining the Stage route
- Agents move along the tracks autonomously
- Roadmap changes require human approval
- Clear separation of human strategy and agent execution

### 2. Stage as Minimal Delivery Unit
- Every Stage is verifiable, rollback-capable, and handoff-ready
- Controlled scope with acceptance of staged compromises
- Natural support for interruption recovery and multi-agent collaboration
- Each Stage validates a small set of clear hypotheses

### 3. Anti-Corruption Mechanism Priority
- Explicit prohibition list (9 rules)
- Four-gate enforcement system
- Synchronous document updates - no "documentation to be added later"

### 4. Explicit Knowledge Management
- Technical debt must be visible, not managed as tacit knowledge
- ADRs must record "impact on subsequent Stages"
- New agents can bootstrap from documentation alone

### 5. Multi-Model Cross-Validation
- Main development model + Independent review model + Rule checking
- ~50% of findings are false positives; verify each independently
- Verification priority: Authoritative sources > Code verification > Model inquiry

### 6. Hook Notification Mechanism
- Automatic notification when human intervention needed
- Multi-channel support: WeCom, Email, Bark, Telegram, Webhook
- Tiered notifications: P0 Urgent / P1 Important / P2 Info / P3 Report

---

## RDD Formula

```
RDD = Roadmap (Human-led)
    + Stage (Minimal Delivery Unit)
    + Gate (Four-Gate System)
    + Knowledge (Explicit Knowledge Management)
    + Hook (Human Intervention Notification)
```

---

## Human-Agent Division

| Domain | Human Responsibility | Agent Responsibility |
|--------|---------------------|---------------------|
| Roadmap | Define vision, plan routes, adjust priorities | Extract goals, execute Stages |
| Stage Boundaries | Review critical Stages, handle exceptions | Generate design docs, implement & verify |
| Review | Verify low-confidence findings | AI pre-filter, rule filtering |
| Technical Debt | Judge priorities | Auto-discover, ledger management |
| Documentation | Review key decisions | Auto-generate, sync updates |

---

## When to Use This Skill

**Triggers:**
- Starting a new project with RDD paradigm
- Migrating existing project to RDD structure
- Creating or modifying Roadmap
- Beginning a new Stage
- Conducting design or code review
- Managing technical debt
- Generating handoff documentation
- Diagnosing project issues

**Commands:**
- `/rdd-init` - Initialize new RDD project
- `/rdd-migrate` - Migrate existing project
- `/rdd-roadmap` - Manage Roadmap
- `/rdd-stage-auto` - Execute Stage with gates
- `/rdd-review-auto` - Automated review
- `/rdd-knowledge` - Knowledge management
- `/rdd-diagnosis` - Diagnose issues
- `/rdd-fresh-check` - Verify new agent can take over

---

## Core Workflow: Stage Progression

```
[GATE 0] Stage Startup Check
    - Verify prerequisites are met
    - Check for Roadmap changes
    - Load context (historical ADRs, technical debt)

[GATE 1] Design Document Pre-Check
    - Prohibit: Implementation without design doc
    - Prohibit: Scope creep
    - Generate Stage design document from template

[GATE 2] Design Review (Before Coding)
    - Trigger multi-model review
    - Apply prompt design principles (colleague mode)
    - AI pre-filter findings (expect ~50% filtered)
    - Rule filtering (memory bias, logical fallacy patterns)
    - Verification method: Authoritative sources > Code verification > Model inquiry
    - Low-confidence findings -> Human review

[GATE 3] Implementation & Testing
    - Implementation
    - Unit tests (coverage >= 20%)
    - E2E tests (at least 2 high-signal paths)
    - Real environment verification (not mock)
    - Clean environment secondary verification (local + clean env)

[GATE 4] Code Review (After E2E Pass)
    - Trigger multi-model review
    - Triangulation: Main model + Independent review model + Rule checking
    - AI pre-filter + Rule filtering
    - Verify each finding (don't rely on "multi-model consensus")

[GATE 5] Completion Gate Check
    - Main hypotheses verified or falsified
    - Tests reproducible via Task entry
    - No undocumented manual steps
    - Implementation matches design (differences recorded)
    - New capabilities have CLI subcommands
    - Technical debt ledger updated
    - ADR recorded ("impact on subsequent Stages" cannot be empty)
    - fresh-agent-check passed

Document Update Obligations (synchronous, no "docs pending"):
    - stage-N.md (implementation differences)
    - stage-N-review-log.md (review record with acceptance/rejection reasons)
    - autonomous-decisions.md (ADR)
    - technical-debt.md (technical debt)
    - next-steps.md (progress)
    - CHANGELOG.md (changes)
```

---

## Anti-Patterns (What to Avoid)

**9 Prohibited Behaviors:**

1. **No design document before implementation** - Must complete design doc before coding
2. **Silent scope expansion** - Stop immediately if scope changes, update docs first
3. **Claiming completion with "docs pending"** - Docs must be synchronized, no future补
4. **Multiple core unknowns in one Stage** - Each Stage validates one small set of hypotheses
5. **Relying on "word of mouth" for test execution** - Tests must be reproducible via Task entry
6. **Writing scripts with hidden platform assumptions** - Environment assumptions must be explicitly documented
7. **Introducing broad interfaces before understanding runtime constraints** - Verify constraints first, then design interfaces
8. **Putting expensive checks in default edit loop too early** - Expensive checks should be explicitly triggered, not default behavior
9. **Managing technical debt as tacit knowledge** - All known gaps must be explicitly recorded in ledger

---

## Checklist: RDD Compliance

### Before Starting a Stage
- [ ] Prerequisites from Roadmap are satisfied
- [ ] Previous Stage's handoff is complete
- [ ] Design document template is ready
- [ ] Rollback plan is defined

### During Stage Design
- [ ] Goals are clear and specific
- [ ] Non-goals are explicitly stated
- [ ] Core hypotheses are defined
- [ ] Acceptance criteria are testable
- [ ] Known limitations are documented

### Before Implementation
- [ ] Design review is complete
- [ ] Low-confidence findings are verified
- [ ] Scope has not expanded silently

### During Implementation
- [ ] Following design document
- [ ] Any deviations are documented
- [ ] Unit tests written alongside code
- [ ] E2E tests cover high-signal paths

### Before Completing Stage
- [ ] All tests pass (unit + E2E)
- [ ] Real environment verification done
- [ ] Clean environment verification done
- [ ] Code review complete
- [ ] All findings verified

### Stage Completion
- [ ] stage-N.md updated with implementation differences
- [ ] stage-N-review-log.md created with findings
- [ ] autonomous-decisions.md updated with ADRs
- [ ] technical-debt.md updated
- [ ] next-steps.md updated with progress
- [ ] CHANGELOG.md updated with changes
- [ ] fresh-agent-check passed

---

## Reference

For detailed specifications, see:
- `prompt.md` - Full RDD specification
- `.claude/skills/rdd-templates/SKILL.md` - Document templates
