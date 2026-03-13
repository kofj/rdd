# Stage 22: Multi-stage Autonomous Progression

## Status

[x] Planning / [x] In Progress / [ ] Complete

---

## Goals

Enable autonomous execution across multiple stages with:
1. Extended `/rdd-loop` with range execution (`--from N --to M`)
2. Stage dependency graph analysis for parallel execution
3. Git worktree pool management for isolation
4. Subagent concurrent scheduling
5. Natural language goal parsing (intelligent planning)
6. Progress dashboard and status aggregation

---

## Non-Goals

- Multi-project orchestration
- Distributed execution across machines
- Real-time collaborative editing

---

## Core Hypotheses

- **Hypothesis A**: Autonomous multi-stage reduces manual intervention by 80%
- **Hypothesis B**: Parallel execution reduces total development time by 40%

---

## Acceptance Criteria

- [ ] `/rdd-loop --from N --to M` executes stages in sequence
- [ ] Dependency graph correctly identifies parallel opportunities
- [ ] Git worktree isolation verified (no cross-contamination)
- [ ] Concurrent execution stable up to 3 parallel stages
- [ ] Natural language goals parsed into stage plans
- [ ] Progress dashboard shows accurate status
- [ ] All features have E2E tests
- [ ] Coverage >= 95%

---

## Rollback Plan

1. Revert to single-stage execution
2. Clean up worktrees: `git worktree prune`
3. Remove dependency graph file

---

## Known Limitations

- Maximum 3 parallel worktrees recommended
- Natural language parsing is keyword-based initially
- No automatic merge conflict resolution

---

## Impact on Subsequent Stages

- Enables large-scale autonomous development
- Foundation for future distributed execution

---

## Implementation Notes

### Task 1: Extend /rdd-loop Command

New options:
```markdown
---
description: "Control autonomous stage execution with multi-stage and parallel support"
examples:
  - "/rdd-loop start --from 19 --to 22"
  - "/rdd-loop start --parallel 2"
  - "/rdd-loop start --goal \"实现用户认证功能\""
---
```

### Task 2: Dependency Graph Analyzer

```yaml
# .rdd/dependency-graph.yml
stages:
  19:
    name: "Command Hint System"
    depends_on: []
    can_parallel: true
    estimated_hours: 8
  20:
    name: "Help & Workflow System"
    depends_on: [19]
    can_parallel: false
    estimated_hours: 16
  21:
    name: "TDD/BDD Initialization"
    depends_on: []
    can_parallel: true
    estimated_hours: 16
  22:
    name: "Multi-stage Progression"
    depends_on: [19, 20]
    can_parallel: false
    estimated_hours: 24

execution_plan:
  parallel_groups:
    - [19, 21]  # Can run in parallel
    - [20]      # Depends on 19
    - [22]      # Depends on 19, 20
```

### Task 3: Worktree Pool Manager

```bash
.rdd/worktrees/
├── pool.json           # Pool state
├── stage-19-abc123/    # Worktree for Stage 19
├── stage-21-def456/    # Worktree for Stage 21 (parallel)
└── stage-20-ghi789/    # Worktree for Stage 20
```

Pool management:
```python
class WorktreePool:
    def __init__(self, max_parallel=3):
        self.max_parallel = max_parallel
        self.active = {}  # stage_id -> worktree_path

    def allocate(self, stage_id):
        """Allocate a worktree for stage execution"""

    def release(self, stage_id):
        """Release worktree after stage completion"""

    def cleanup(self):
        """Remove completed worktrees"""
```

### Task 4: Subagent Scheduler

```yaml
# Execution flow
parallel_execution:
  - stage: 19
    agent: agent-1
    worktree: .rdd/worktrees/stage-19-abc123
  - stage: 21
    agent: agent-2
    worktree: .rdd/worktrees/stage-21-def456

sequential_execution:
  - stage: 20
    agent: agent-1
    worktree: .rdd/worktrees/stage-20-ghi789
    wait_for: [19]
  - stage: 22
    agent: agent-1
    worktree: .rdd/worktrees/stage-22-jkl012
    wait_for: [19, 20]
```

### Task 5: Natural Language Goal Parser

```python
def parse_goal(goal_text: str) -> List[Stage]:
    """
    Parse natural language goal into stage plan.

    Examples:
    - "完成用户认证功能" → [auth-setup, auth-model, auth-api, auth-test]
    - "优化性能" → [profile, optimize-db, cache, benchmark]
    """
    # Keyword matching (initial version)
    keywords = {
        "认证": ["auth-setup", "auth-model", "auth-api"],
        "性能": ["profile", "optimize"],
        "测试": ["test-setup", "test-write"],
    }
    # LLM-based parsing (future enhancement)
```

### Task 6: Progress Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│ RDD Multi-stage Progress Dashboard                           │
├─────────────────────────────────────────────────────────────┤
│ Stage 19: Command Hints        [████████████] 100% ✅       │
│ Stage 20: Help & Workflow      [████████░░░░]  67% 🔄       │
│ Stage 21: TDD/BDD Init         [████████████] 100% ✅       │
│ Stage 22: Multi-stage          [░░░░░░░░░░░░]   0% ⏳       │
├─────────────────────────────────────────────────────────────┤
│ Parallel: 1/3 active | Worktrees: 2 | ETA: 8h               │
│ Current: Stage 20 Gate 3                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    /rdd-loop Command                         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    Loop Controller                           │
├──────────────┬──────────────┬──────────────┬───────────────┤
│ Dependency   │ Worktree     │ Subagent     │ Progress      │
│ Analyzer     │ Pool         │ Scheduler    │ Dashboard     │
└──────────────┴──────────────┴──────────────┴───────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    Execution Layer                           │
├──────────────┬──────────────┬───────────────────────────────┤
│ Worktree 1   │ Worktree 2   │ Worktree 3                    │
│ (Stage 19)   │ (Stage 21)   │ (Stage 20)                    │
└──────────────┴──────────────┴───────────────────────────────┘
```

### Execution Flow

```
1. Parse goal or range
      ↓
2. Analyze dependencies
      ↓
3. Generate execution plan
      ↓
4. Allocate worktrees
      ↓
5. Launch subagents (parallel if possible)
      ↓
6. Monitor progress
      ↓
7. Aggregate results
      ↓
8. Merge to main (with conflict handling)
      ↓
9. Cleanup worktrees
```

### Error Handling

```yaml
error_recovery:
  stage_failure:
    action: pause
    notify: true
    retry: 3
    fallback: skip_with_debt

  merge_conflict:
    action: pause
    notify: true
    require_human: true

  worktree_error:
    action: release_and_reallocate
    retry: 2
```

---

## Test Plan

### Unit Tests

```bash
tests/unit/dependency/test_graph_analyzer.bats
tests/unit/worktree/test_pool_manager.bats
tests/unit/scheduler/test_subagent_scheduler.bats
tests/unit/parser/test_goal_parser.bats
```

### E2E Tests

```bash
tests/e2e/test_multi_stage_sequential.bats
tests/e2e/test_multi_stage_parallel.bats
tests/e2e/test_worktree_isolation.bats
tests/e2e/test_progress_dashboard.bats
tests/e2e/test_goal_parsing.bats
```

### Integration Tests

```bash
tests/integration/test_full_pipeline.bats  # Stage 19-22 complete flow
```

---

## Dependencies

- Stage 19 (Command Hint System)
- Stage 20 (Help & Workflow System)

---

## Estimated Effort

Large (3 days)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-13 | Initial design |
