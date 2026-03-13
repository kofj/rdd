# Phase 4: User Readiness - Design Document

**Created**: 2026-03-13
**Status**: Planning
**Author**: Claude

---

## Overview

Phase 4 focuses on improving user experience and developer productivity through four key improvements identified from user feedback:

1. **Command hints** - Placeholder hints for better command discoverability
2. **Help & workflow** - Comprehensive guidance system
3. **TDD/BDD setup** - Automated testing framework configuration
4. **Multi-stage progression** - Autonomous execution across multiple stages

---

## Background

### User Feedback Analysis

| Issue | Impact | Priority |
|-------|--------|----------|
| Commands lack input hints | Users don't understand command purpose | P0 |
| No workflow guidance | Users don't know next steps | P0 |
| No TDD/BDD in init | Testing setup is manual, inconsistent | P0 |
| No multi-stage automation | Manual stage progression is tedious | P1 |

### Current State

- Phase 1-3 completed with 909 tests passing
- RDD commands defined in `.claude/commands/`
- Basic workflow exists via `rdd-loop` and `rdd-stage-auto`
- No BDD framework auto-configuration
- Single-stage execution only

---

## Goals

### Primary Goals

1. Users can discover command functionality from input hints
2. Users receive context-aware guidance at every step
3. New projects start with proper TDD/BDD configuration
4. Agents can autonomously execute multiple stages

### Non-Goals

- GUI or web interface (CLI only)
- IDE integrations (future consideration)
- Multi-project orchestration (future consideration)

---

## Core Hypotheses

### Hypothesis 1: Command Hints Improve Discoverability

**Statement**: Adding descriptive hints to commands reduces user confusion and increases adoption rate.

**Validation**: E2E tests verify hint display; user feedback surveys.

### Hypothesis 2: State-Aware Guidance Reduces Onboarding Time

**Statement**: Showing context-aware next steps reduces the time for users to complete their first RDD workflow.

**Validation**: Measure time from init to first stage completion.

### Hypothesis 3: Auto-configured TDD/BDD Increases Test Coverage

**Statement**: Projects initialized with TDD/BDD configuration have higher test coverage than manually configured projects.

**Validation**: Compare coverage of new vs existing projects.

### Hypothesis 4: Multi-stage Automation Increases Productivity

**Statement**: Autonomous multi-stage execution reduces manual intervention by 80%+.

**Validation**: Measure manual interventions per stage before/after.

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interaction Layer                    │
├──────────────┬──────────────┬──────────────┬───────────────┤
│ Command      │ Help &       │ Workflow     │ Progress      │
│ Hints        │ Documentation│ Wizard       │ Dashboard     │
│ (Stage 19)   │ (Stage 20)   │ (Stage 20)   │ (Stage 22)    │
└──────────────┴──────────────┴──────────────┴───────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    Orchestration Layer                       │
├──────────────┬──────────────┬───────────────────────────────┤
│ State        │ Dependency   │ Worktree                      │
│ Machine      │ Graph        │ Pool Manager                  │
│ (Stage 20)   │ (Stage 22)   │ (Stage 22)                    │
└──────────────┴──────────────┴───────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    Foundation Layer                          │
├──────────────┬──────────────┬───────────────────────────────┤
│ RDD Core     │ Test         │ Project                       │
│ Commands     │ Framework    │ Detection                     │
│ (Existing)   │ Config       │ (Stage 21)                    │
└──────────────┴──────────────┴───────────────────────────────┘
```

### Data Flow

```
User Input → Command Parser → Hint Display
                                  ↓
User Execute → Command Handler → State Update → Next Step Hint
                                  ↓
Project Init → Language Detect → BDD Config → Test Scaffolding
                                  ↓
Multi-stage → Dependency Analysis → Worktree Allocation → Parallel Execution
```

---

## Stage Breakdown

### Stage 19: Command Hint System

**Duration**: 1 day
**Dependencies**: None

**Deliverables**:
1. Enhanced command definition format with `description` field
2. All existing commands updated with hints
3. Multi-line hint support with examples
4. E2E tests for hint verification

**Technical Details**:

Command definition format update:
```markdown
---
description: "Initialize RDD framework in a new or existing project"
examples:
  - "/rdd-init my-project"
  - "/rdd-init  # Uses current directory name"
---

# RDD Init Command

Initialize RDD (Roadmap Driven Development) framework...
```

### Stage 20: Help & Workflow System

**Duration**: 2 days
**Dependencies**: Stage 19

**Deliverables**:
1. `/rdd-help <topic>` command with fuzzy search
2. State machine for tracking user progress
3. Next-step prompts after each command
4. `/rdd-workflow` interactive wizard
5. Scenario-based guides

**Technical Details**:

State machine:
```yaml
states:
  - init        # Project just initialized
  - planning    # Roadmap being defined
  - developing  # Active stage execution
  - reviewing   # Code review in progress
  - complete    # Stage completed

transitions:
  init → planning: roadmap_created
  planning → developing: stage_started
  developing → reviewing: tests_passed
  reviewing → complete: review_passed
```

### Stage 21: TDD/BDD Initialization Enhancement

**Duration**: 2 days
**Dependencies**: None (can run parallel with Stage 19)

**Deliverables**:
1. Language detection engine
2. BDD framework recommendation matrix
3. Test configuration templates
4. Example feature/step files
5. Pre-commit hook configuration
6. Coverage enforcement in gates

**Technical Details**:

Framework recommendation matrix:
```yaml
nodejs:
  bdd: cucumber-js
  test_runner: jest
  coverage: nyc/istanbul
  e2e: playwright (optional)
  api_test: supertest

python:
  bdd: pytest-bdd
  test_runner: pytest
  coverage: coverage.py
  e2e: playwright (optional)
  api_test: requests/httpx

go:
  bdd: godog
  test_runner: go test
  coverage: go cover
  api_test: httptest

rust:
  bdd: cucumber-rust
  test_runner: cargo test
  coverage: tarpaulin
  api_test: reqwest

java:
  bdd: cucumber-jvm
  test_runner: junit
  coverage: jacoco
  api_test: rest-assured
```

Coverage enforcement:
```yaml
# .rdd/config.yml
gates:
  min_coverage: 95
  coverage_fail_gate: true
  bdd_required: true
```

### Stage 22: Multi-stage Autonomous Progression

**Duration**: 3 days
**Dependencies**: Stage 19, Stage 20

**Deliverables**:
1. Extended `/rdd-loop` with range execution
2. Dependency graph analyzer
3. Worktree pool manager
4. Subagent scheduler
5. Natural language goal parser
6. Progress dashboard

**Technical Details**:

Dependency graph:
```yaml
# .rdd/dependency-graph.yml
stages:
  19:
    depends_on: []
    can_parallel: true
  20:
    depends_on: [19]
    can_parallel: false
  21:
    depends_on: []
    can_parallel: true
  22:
    depends_on: [19, 20]
    can_parallel: false
```

Worktree pool:
```bash
.rdd/worktrees/
├── stage-19-abc123/  # Worktree for Stage 19
├── stage-21-def456/  # Worktree for Stage 21 (parallel)
└── pool.json         # Pool state
```

Extended loop command:
```
/rdd-loop start --from 19 --to 22 --parallel 2
/rdd-loop start --goal "完成用户认证功能"  # Natural language
```

---

## Testing Strategy

### Unit Tests

- Command hint parsing: 100% coverage
- State machine transitions: 100% coverage
- Language detection: 95%+ coverage
- Dependency graph analysis: 95%+ coverage

### E2E Tests

- Command hint display verification
- Complete workflow wizard execution
- TDD/BDD initialization for each language
- Multi-stage execution with parallel stages
- Worktree isolation verification

### Coverage Requirements

- Minimum: 95%
- Target: 98%
- Critical paths: 100%

---

## Rollback Plan

If Phase 4 causes issues:

1. **Stage-level rollback**: Each stage is independently deployable
2. **Feature flags**: New features can be disabled via config
3. **Migration scripts**: Revert configuration changes
4. **Documentation sync**: Keep docs in sync with features

---

## Impact on Subsequent Stages

- **Stage 19** enables better command UX for all future commands
- **Stage 20** provides foundation for state-aware features
- **Stage 21** ensures all new projects have proper testing
- **Stage 22** enables autonomous development at scale

---

## Open Questions

1. Should natural language goal parsing require LLM or use simple keyword matching?
2. What is the maximum number of parallel worktrees?
3. Should worktrees be cleaned up automatically after stage completion?

---

## References

- User feedback from 2026-03-13 session
- Existing RDD commands: `.claude/commands/`
- Stage roadmap: `docs/stages/stage-roadmap.md`
- ADR: Decision to use incremental enhancement approach
