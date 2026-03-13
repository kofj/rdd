# RDD Framework - Stage Roadmap

> The actual development roadmap for the RDD Framework

---

## Current Status

### Current Stage

- **Stage**: Phase 4 Started 🔄
- **Status**: Planning Stage 19

### Overall Progress

```
Phase 1 Core Development: ████████████████████ 100% (11/11 Stage)
Phase 2 E2E Testing:      ████████████████████ 100% (5/5 Stage)
Phase 3 Release & Ops:    ████████████████████ 100% (3/3 Stage)
Phase 4 User Readiness:   ░░░░░░░░░░░░░░░░░░░░   0% (0/4 Stage)
```

---

## Stage Roadmap

### Phase 1: Core Development ✅ (Completed)

| Stage | Status | Goal | Completion Date |
|-------|--------|------|-----------------|
| Stage 0 | ✅ Completed | Framework foundation setup | 2026-03-06 |
| Stage 1 | ✅ Completed | Critical bug fixes | 2026-03-07 |
| Stage 2 | ✅ Completed | Testing system establishment | 2026-03-07 |
| Stage 3 | ✅ Completed | Context recovery enhancement | 2026-03-08 |
| Stage 4 | ✅ Completed | Error handling & observability | 2026-03-08 |
| Stage 5 | ✅ Completed | Performance & compatibility | 2026-03-08 |
| Stage 6 | ✅ Completed | Security & permissions | 2026-03-08 |
| Stage 7 | ✅ Completed | Documentation & ops refinement | 2026-03-08 |
| Stage 8 | ✅ Completed | User installation experience | 2026-03-09 |
| Stage 9 | ✅ Completed | Package manager support | 2026-03-09 |
| Stage 10 | ✅ Completed | Developer experience optimization | 2026-03-09 |

### Phase 2: E2E Testing & Release ✅ (Completed)

| Stage | Status | Goal | Completion Date |
|-------|--------|------|-----------------|
| Stage 11 | ✅ Completed | E2E test framework setup | 2026-03-09 |
| Stage 12 | ✅ Completed | Installation flow E2E tests | 2026-03-09 |
| Stage 13 | ✅ Completed | Claude Code integration tests | 2026-03-09 |
| Stage 14 | ✅ Completed | Complete workflow E2E tests | 2026-03-09 |
| Stage 15 | ✅ Completed | Code commit & release preparation | 2026-03-09 |

### Phase 3: Release & Operations ✅ (Completed)

| Stage | Status | Goal | Completion Date |
|-------|--------|------|-----------------|
| Stage 16 | ✅ Completed | Installation script fixes (Banner + go-task) | 2026-03-10 |
| Stage 17 | ✅ Completed | GitHub Actions CI/CD | 2026-03-10 |
| Stage 18 | ✅ Completed | Docker test environment | 2026-03-10 |

### Phase 4: User Readiness 🔄 (In Progress)

| Stage | Status | Goal | Dependencies |
|-------|--------|------|--------------|
| Stage 19 | ⏳ Planning | Command hint system | None |
| Stage 20 | ⏳ Pending | Help & workflow system | Stage 19 |
| Stage 21 | ⏳ Pending | TDD/BDD initialization enhancement | None |
| Stage 22 | ⏳ Pending | Multi-stage autonomous progression | Stage 19, 20 |

### Status Icons

- ✅ Completed - Stage has met all acceptance criteria
- 🔄 In Progress - Stage is being developed
- ⏳ Pending - Stage has not started

---

## Phase 4 Details

### Stage 19: Command Hint System

**Goal**: Add placeholder hints to all RDD commands for better discoverability

**Features**:
- Add `description` field to command definitions
- Claude Code automatically reads description as input hint
- Update all existing commands with clear descriptions
- Support multi-line hints with examples

**Acceptance Criteria**:
- [ ] All RDD commands have descriptive hints
- [ ] Hints show command purpose and common usage
- [ ] E2E tests verify hint display
- [ ] Documentation updated

### Stage 20: Help & Workflow System

**Goal**: Provide comprehensive guidance and workflow support

**Features**:
- `/rdd-help <topic>` - Deep documentation search
- State-aware next-step prompts after each command
- `/rdd-workflow` - Interactive workflow wizard
- Scenario-based guides (onboarding, daily dev, troubleshooting)

**Acceptance Criteria**:
- [ ] `/rdd-help` command implemented
- [ ] State machine tracks user progress
- [ ] Workflow wizard guides common tasks
- [ ] All guides have E2E tests

### Stage 21: TDD/BDD Initialization Enhancement

**Goal**: Auto-configure testing frameworks during project initialization

**Features**:
- Auto-detect project language and type
- Recommend appropriate BDD frameworks
- Generate test configuration with 95%+ coverage requirement
- Create example feature files and step definitions
- Configure pre-commit hooks for test enforcement

**Acceptance Criteria**:
- [ ] Language detection works for Node/Python/Go/Rust/Java
- [ ] BDD framework recommendations appropriate
- [ ] Coverage threshold enforced in gates
- [ ] Example tests pass
- [ ] Pre-commit hooks functional

### Stage 22: Multi-stage Autonomous Progression

**Goal**: Enable autonomous execution across multiple stages

**Features**:
- Extended `/rdd-loop` with range execution (`--from N --to M`)
- Stage dependency graph analysis
- Git worktree pool management
- Subagent concurrent scheduling
- Natural language goal → stage breakdown (intelligent planning)
- Progress dashboard and status aggregation

**Acceptance Criteria**:
- [ ] Range execution works end-to-end
- [ ] Dependency graph correctly identifies parallel stages
- [ ] Worktree isolation verified
- [ ] Concurrent execution stable
- [ ] Progress tracking accurate
- [ ] E2E tests for multi-stage scenarios

---

## Test Statistics

| Type | Count | Pass Rate |
|------|-------|-----------|
| Unit Tests | 867 | 100% |
| E2E Tests | 42 | 100% |
| **Total** | **909** | **100%** |

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v6.0 | 2026-03-13 | Phase 4 initiated, added Stage 19-22 | Claude |
| v5.0 | 2026-03-09 | Stage 11-15 completed, all E2E tests passed | Claude |
| v4.0 | 2026-03-09 | Added Stage 11-15 E2E test plan | Claude |
| v3.0 | 2026-03-09 | v1.0.0 released, Stage 0-10 completed | Claude |
