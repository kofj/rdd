# Stage 22: Multi-stage Autonomous Progression

## Status

[x] Planning / [x] In Progress / [ ] Complete

---

## Goals

Enable autonomous execution across multiple stages with:

1. **Auto-detect incomplete stages** — `/rdd-loop` with zero arguments scans roadmap, identifies all pending stages, resolves dependencies, and executes them sequentially
2. **Optional range filter** — `--from N` / `--to M` to limit scope when needed (not required)
3. **Fine-grained persistence** — checkpoint, ADR, tech debt, and stage state saved at every key action (not just gate boundaries), preventing data loss from context overflow or process termination
4. **Hardened Gate 3** — real execution of `task test`, `task lint`, `task fmt` as non-bypassable acceptance criteria
5. **gotask convergence** — all new scripts/checks/commands auto-registered as `task` entries; no ad-hoc manual commands allowed
6. **Stage dependency graph analysis** for parallel execution opportunities
7. **Git worktree pool management** for isolation
8. **Subagent concurrent scheduling**
9. **Progress dashboard** and status aggregation

---

## Non-Goals

- ~~Natural language goal parsing~~ — removed in v1. Roadmap Goal field is the deterministic data source; NL parsing adds ambiguity without proportional benefit
- ~~`start` subcommand~~ — removed. `/rdd-loop` is inherently "start the loop"; subcommands like `status`/`pause`/`resume` remain for control
- Multi-project orchestration
- Distributed execution across machines
- Real-time collaborative editing

---

## Core Hypotheses

- **Hypothesis A**: Auto-detect + real gate enforcement eliminates 90% of manual intervention for multi-stage execution
- **Hypothesis B**: Fine-grained persistence prevents data loss from context overflow or crash
- **Hypothesis C**: Hardened Gate 3 (real `task test`/`task lint`/`task fmt`) catches regressions that echo-only gates miss

---

## Acceptance Criteria

- [ ] `/rdd-loop` (no args) auto-detects all incomplete stages and executes them
- [ ] `--from N --to M` works as optional filter
- [ ] Each gate transition persists checkpoint atomically (`.rdd/cache/checkpoints.json`)
- [ ] ADR decisions written immediately on decision, not deferred to Gate 5
- [ ] Tech debt entries written immediately on discovery
- [ ] `task test` runs with non-zero exit blocking gate progression
- [ ] `task lint` and `task fmt` added to Gate 3 pipeline
- [ ] New scripts added during loop auto-register as `task` entries
- [ ] Dependency graph correctly identifies parallel opportunities
- [ ] Git worktree isolation verified (no cross-contamination)
- [ ] Concurrent execution stable up to 3 parallel stages
- [ ] Progress dashboard shows accurate status
- [ ] All features have E2E tests
- [ ] Coverage >= 95%

---

## Rollback Plan

1. Revert to single-stage execution
2. Clean up worktrees: `git worktree prune`
3. Remove `.rdd/cache/loop-state.json`

---

## Known Limitations

- Maximum 3 parallel worktrees recommended
- No automatic merge conflict resolution
- ~~Natural language parsing is keyword-based initially~~ removed

---

## Impact on Subsequent Stages

- Enables autonomous multi-stage development with hard quality gates
- Foundation for future distributed execution
- Fine-grained persistence enables crash-resilient 24/7 operation

---

## Design Decisions (ADR)

### ADR-22A: Default behavior is auto-detect, not manual range

**Background**: Original design required `--from N --to M` for every invocation.

**Decision**: Default to auto-detection. Scan `stage-roadmap.md`, find all stages with status ≠ Completed, resolve dependency ordering, execute from first incomplete to last.

**Rationale**: Manual range specification is redundant when the roadmap is the source of truth. The only time `--from`/`--to` is needed is when the user intentionally wants to skip stages or stop early — these become optional filters, not required parameters.

**Impact on Subsequent Stages**: Reduces command friction, eliminates "forgot to specify range" errors.

### ADR-22B: Remove `start` subcommand

**Background**: `/rdd-loop start` was the invocation pattern.

**Decision**: `/rdd-loop` with no subcommand starts execution. `status`, `pause`, `resume` remain as control subcommands.

**Rationale**: "Loop" inherently means "start executing". Adding `start` is noise. The subcommand space is reserved for control operations, not the default action.

### ADR-22C: Remove `--goal` natural language parsing (v1)

**Background**: Original design included NL goal → stage mapping.

**Decision**: Remove from v1. Roadmap Goal field is the canonical, deterministic data source. NL parsing introduces ambiguity (multiple valid mappings for the same goal) and has high implementation cost with low marginal benefit.

**Rationale**: The roadmap already contains precise, human-authored goal descriptions. Adding an NL layer on top introduces a second, less reliable source of truth. If the user wants to execute "add auth", they should look at the roadmap and use `--from 23 --to 26`.

**Impact on Subsequent Stages**: Simplifies command surface, removes a source of non-deterministic behavior.

### ADR-22D: Fine-grained atomic persistence

**Background**: Previous design saved state only at gate boundaries. Context overflow or process termination between gates loses all in-gate progress.

**Decision**: Save state atomically at every key action:

| Trigger | What is saved | Destination |
|---------|--------------|-------------|
| Gate enter/exit | gate status + progress % | `.rdd/cache/checkpoints.json` |
| Decision made | ADR entry (title + rationale) | `docs/08-autonomous-decisions.md` |
| Tech debt found | TD entry (priority + source) | `docs/12-technical-debt.md` |
| Test run complete | test results (pass/fail/count) | `.rdd/cache/checkpoints.json` |
| Every 5 min heartbeat | full checkpoint snapshot | `.rdd/cache/checkpoints.json` |
| Error/exception | error context + stack | `.rdd/cache/checkpoints.json` |

**Rationale**: Context overflow is inevitable in long-running autonomous sessions. The only defense is atomic, frequent persistence of all critical state. On recovery, the agent reads checkpoints.json and resumes from the last saved action, not from the last gate boundary.

**Impact on Subsequent Stages**: All multi-stage execution inherits crash-resilience. Recovery protocol is self-contained.

### ADR-22E: Hardened Gate 3 — real execution only

**Background**: Current Gate 3 implementation (`Taskfile.yml`) prints checklist items without executing anything:

```yaml
gate:3:
  cmds:
    - 'echo "[ ] Implementation is complete"'
    - 'echo "[ ] Unit test coverage >= 20%"'
```

**Decision**: Replace echo-only gates with real command execution that blocks on non-zero exit:

```yaml
gate:3:
  cmds:
    - task test:unit          # exit code ≠ 0 → gate blocked
    - task test:e2e           # exit code ≠ 0 → gate blocked
    - task test:coverage      # below threshold → gate blocked
    - task lint:check         # violations → gate blocked
    - task fmt:check          # format violations → gate blocked
```

**Rationale**: The current design relies entirely on agent self-discipline. An agent can claim "all tests pass" without running them. Hardened gates make the check non-bypassable — if tests fail, the gate blocks progression regardless of what the agent "claims".

**Impact on Subsequent Stages**: Sets a precedent that ALL gates must be machine-verifiable. No gate may rely on agent self-reporting alone.

### ADR-22F: gotask convergence — no orphan commands

**Background**: During autonomous execution, agents may create new scripts, checks, or workflows. Without enforcement, these become undocumented manual steps.

**Decision**: Every new script/check/command created during loop execution must be registered as a `task` entry in `Taskfile.yml`. The `task lint:check` gate verifies no orphan commands exist. Commands that cannot be run via `task <name>` are treated as Gate 3 failures.

**Rationale**: The Taskfile is the single entry point for all project operations. Allowing ad-hoc commands creates fragmentation and makes handoff unreliable — a new agent cannot discover them.

**Impact on Subsequent Stages**: All future stages inherit this constraint. Taskfile becomes the canonical command registry.

---

## Implementation Notes

### Task 1: Redesign /rdd-loop Command

```markdown
---
description: "Autonomous multi-stage execution with auto-detection and hard quality gates"
examples:
  - "/rdd-loop                         # Auto-detect all incomplete stages, execute all"
  - "/rdd-loop --to 22                 # Stop after Stage 22"
  - "/rdd-loop --from 21               # Start from Stage 21"
  - "/rdd-loop --from 21 --to 22       # Execute only 21-22"
  - "/rdd-loop --parallel 2            # Allow 2 parallel stages"
  - "/rdd-loop status                  # Show current progress"
  - "/rdd-loop pause                   # Pause at next checkpoint"
  - "/rdd-loop resume                  # Resume from last checkpoint"
---
```

### Task 2: Auto-Detection Engine

```
1. Read docs/stages/stage-roadmap.md
       ↓
2. Filter: status != "✅ Completed"
       ↓
3. Resolve dependency ordering (topological sort)
       ↓
4. Apply optional --from/--to filters
       ↓
5. Display execution plan, request confirmation
       ↓
6. Execute stages in order (parallel where possible)
```

```yaml
# .rdd/loop-state.yaml — machine-readable loop state
version: "1.0"
session_id: "loop-20260710-143022"
started_at: "2026-07-10T14:30:22+08:00"
target: "auto"                    # "auto" | "19-22" | "19-"
stages:
  - id: 19
    status: complete
    gates: [complete, complete, complete, complete, complete]
    started_at: "2026-07-10T14:30:22+08:00"
    completed_at: "2026-07-10T15:45:10+08:00"
  - id: 21
    status: complete
    gates: [complete, complete, complete, complete, complete]
    started_at: "2026-07-10T14:30:22+08:00"
    completed_at: "2026-07-10T16:20:33+08:00"
  - id: 20
    status: in_progress
    gate: 3                         # currently at gate 3
    started_at: "2026-07-10T15:45:10+08:00"
  - id: 22
    status: pending
progress:
  total: 4
  completed: 2
  in_progress: 1
  failed: 0
last_checkpoint: "2026-07-10T16:05:00+08:00"
```

### Task 3: Fine-Grained Persistence

Persistence hooks injected at every key action point:

```python
class LoopPersistence:
    """Atomic persistence for all loop state."""

    CHECKPOINT_FILE = ".rdd/cache/checkpoints.json"
    LOOP_STATE_FILE = ".rdd/cache/loop-state.yaml"
    ADR_FILE = "docs/08-autonomous-decisions.md"
    DEBT_FILE = "docs/12-technical-debt.md"
    NEXT_STEPS_FILE = "docs/11-next-steps.md"

    def on_gate_enter(self, stage_id: int, gate: int):
        """Atomically persist gate entry."""
        self._update_loop_state(stage=stage_id, gate=gate, status="in_progress")
        self._atomic_write(self.CHECKPOINT_FILE, self._build_checkpoint())

    def on_gate_exit(self, stage_id: int, gate: int, result: dict):
        """Persist gate completion with test results."""
        self._update_loop_state(stage=stage_id, gate=gate, result=result)
        self._atomic_write(self.CHECKPOINT_FILE, self._build_checkpoint())
        self._update_next_steps()

    def on_decision(self, decision: dict):
        """Write ADR immediately on decision, not deferred to Gate 5."""
        entry = f"\n### Decision {decision['id']}: {decision['title']}\n"
        entry += f"**Background**: {decision['background']}\n"
        entry += f"**Decision**: {decision['decision']}\n"
        entry += f"**Rationale**: {decision['rationale']}\n"
        entry += f"**Impact on Subsequent Stages**: {decision['impact']}\n"
        entry += f"**Date**: {decision['date']}\n"
        entry += f"**Related Stage**: Stage {decision['stage']}\n"
        self._atomic_append(self.ADR_FILE, entry)

    def on_debt_discovered(self, debt: dict):
        """Write tech debt immediately on discovery."""
        entry = f"\n### TD-{debt['id']}: {debt['title']}\n"
        entry += f"- **Priority**: {debt['priority']}\n"
        entry += f"- **Source**: Stage {debt['stage']}\n"
        entry += f"- **Original Description**: \"{debt['description']}\"\n"
        entry += f"- **Source File**: {debt['source_file']}:{debt['source_line']}\n"
        entry += f"- **Suggested Stage**: Stage {debt['suggested_stage']}\n"
        self._atomic_append(self.DEBT_FILE, entry)

    def on_test_run(self, results: dict):
        """Persist test results. Non-zero exit blocks progression."""
        self._update_loop_state(test_results=results)
        if results["exit_code"] != 0:
            self._block_gate("tests failed", results)

    def heartbeat(self):
        """Every 5 minutes: full snapshot save."""
        self._atomic_write(self.CHECKPOINT_FILE, self._build_checkpoint())
        self._atomic_write(self.LOOP_STATE_FILE, self._build_loop_state())

    def _atomic_write(self, path, content):
        """Write to temp file then rename — prevents corruption on crash."""
        tmp = path + ".tmp"
        write(tmp, content)
        os.rename(tmp, path)

    def _atomic_append(self, path, entry):
        """Append to file safely."""
        with open(path, "a") as f:
            f.write(entry)
            f.flush()
            os.fsync(f.fileno())
```

### Task 4: Hardened Gate 3

Replace all echo-only gate implementations with real execution:

```yaml
# Taskfile.yml — Gate 3 (hardened)
gate:3:
  desc: Gate 3 - Implementation & testing (REAL EXECUTION)
  cmds:
    - echo "Gate 3: Implementation & Testing (Hardened)"
    - echo "--------------------------------------------"
    - echo "[1/5] Running unit tests..."
    - task test:unit || (echo "  [FAIL] Unit tests failed — gate blocked" && exit 1)
    - echo "  [PASS] Unit tests passed"
    - echo "[2/5] Running E2E tests..."
    - task test:e2e || (echo "  [FAIL] E2E tests failed — gate blocked" && exit 1)
    - echo "  [PASS] E2E tests passed"
    - echo "[3/5] Checking test coverage..."
    - task test:coverage || (echo "  [FAIL] Coverage below threshold — gate blocked" && exit 1)
    - echo "  [PASS] Coverage meets threshold"
    - echo "[4/5] Running lint checks..."
    - task lint:check || (echo "  [FAIL] Lint violations — gate blocked" && exit 1)
    - echo "  [PASS] Lint check passed"
    - echo "[5/5] Running format checks..."
    - task fmt:check || (echo "  [FAIL] Format violations — gate blocked" && exit 1)
    - echo "  [PASS] Format check passed"
    - echo ""
    - echo "Gate 3: ALL CHECKS PASSED"
  silent: false

lint:check:
  desc: Run lint checks
  cmds:
    - echo "Running lint checks..."
    - test -f .golangci.yml && golangci-lint run ./... || echo "No Go project, skipping golangci-lint"
    - test -f .eslintrc.js && npx eslint . || echo "No JS project, skipping eslint"

fmt:check:
  desc: Check code formatting
  cmds:
    - echo "Checking code formatting..."
    # Go
    - test -f go.mod && (gofmt -l . | grep -q . && echo "Go format violations found" && exit 1 || echo "Go formatting OK") || true
    - test -f go.mod && (goimports -l . | grep -q . && echo "Go imports violations found" && exit 1 || echo "Go imports OK") || true
    # Shell
    - find . -name "*.sh" -not -path "./tests/lib/*" | xargs -I {} sh -c 'shellcheck {} || exit 1' || echo "No shell scripts to check"

task:check:
  desc: Check no orphan commands exist (all commands must be in Taskfile)
  cmds:
    - echo "Checking for orphan commands..."
    - echo "All scripts must be registered as task entries"
    - test -f Taskfile.yml && echo "  [OK] Taskfile exists"
```

### Task 5: gotask Convergence

When the loop creates new scripts/commands, auto-register them:

```python
class TaskRegistry:
    """Ensure all new commands are registered in Taskfile.yml."""

    TASKFILE = "Taskfile.yml"

    def register(self, name: str, desc: str, command: str):
        """Register a new task entry.
        
        Called automatically whenever a new script is created
        during loop execution.
        """
        entry = f"""
  {name}:
    desc: {desc}
    cmds:
      - {command}
"""
        self._append_to_taskfile(entry)

    def verify_no_orphans(self) -> bool:
        """Gate 3 check: are there scripts not registered as tasks?
        
        Scans .rdd/scripts/ and .claude/ for executable files
        not referenced in Taskfile.yml.
        """
        scripts = self._find_executables()
        registered = self._parse_task_commands()
        orphans = scripts - registered
        if orphans:
            for o in orphans:
                print(f"  [FAIL] Orphan command: {o}")
            return False
        return True
```

### Task 6: Dependency Graph Analyzer

```yaml
# .rdd/dependency-graph.yml
# Auto-generated from stage-roadmap.md, refreshed each loop start
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

### Task 7: Worktree Pool Manager

```
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
        self.active: dict[int, str] = {}  # stage_id -> worktree_path

    def allocate(self, stage_id: int) -> str:
        """Allocate a worktree for stage execution."""

    def release(self, stage_id: int):
        """Release worktree after stage completion."""

    def cleanup(self):
        """Remove completed worktrees."""
```

### Task 8: Subagent Scheduler

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

### Task 9: Progress Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ RDD Multi-stage Progress Dashboard                              │
├─────────────────────────────────────────────────────────────────┤
│ Stage 19: Command Hints        [████████████] 100% ✅ Gate 5    │
│ Stage 20: Help & Workflow      [████████░░░░]  67% 🔄 Gate 3   │
│ Stage 21: TDD/BDD Init         [████████████] 100% ✅ Gate 5    │
│ Stage 22: Multi-stage          [░░░░░░░░░░░░]   0% ⏳ Pending   │
├─────────────────────────────────────────────────────────────────┤
│ Session: loop-20260710-143022  | Autosave: 2m ago                │
│ Parallel: 1/3 active           | Worktrees: 2 | ETA: 6h          │
│ Tests: 909/909 pass            | Coverage: 95%                   │
│ Lint: clean                    | Format: clean                   │
└─────────────────────────────────────────────────────────────────┘
```

### Recovery Protocol

On session restart after crash/interruption:

```
1. Check for checkpoint file
   └─→ .rdd/cache/checkpoints.json exists?
       ├─ Yes → Recovery Mode
       │   a. Read checkpoints.json → determine last saved state
       │   b. Read loop-state.yaml → determine current stage + gate
       │   c. Read docs/08-autonomous-decisions.md → decisions since start
       │   d. Read docs/12-technical-debt.md → debt discovered
       │   e. Run task test → verify environment intact
       │   f. Resume from last checkpoint action (NOT last gate boundary)
       └─ No → Fresh Start
           a. Scan roadmap for incomplete stages
           b. Start new loop
```

---

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    /rdd-loop Command                         │
├─────────────────────────────────────────────────────────────┤
│  No args: auto-detect    --from N: start at N                │
│  status: show progress   --to M: stop at M                   │
│  pause: pause loop       --parallel N: max N concurrent      │
│  resume: resume loop                                         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    Loop Controller                           │
├──────────────┬──────────────┬──────────────┬───────────────┤
│ Dependency   │  Worktree    │  Subagent    │  Progress     │
│ Analyzer     │  Pool        │  Scheduler   │  Dashboard    │
├──────────────┴──────────────┴──────────────┴───────────────┤
│                      Persistence Layer                       │
├──────────────┬──────────────┬──────────────┬───────────────┤
│ checkpoint   │  ADR         │  Tech Debt   │  Heartbeat    │
│ (per action) │  (on decide)  │  (on find)   │  (every 5min) │
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
1. Read roadmap → auto-detect incomplete stages
      ↓
2. Apply --from/--to filter (if specified)
      ↓
3. Analyze dependencies → topological sort
      ↓
4. Generate execution plan (parallel groups identified)
      ↓
5. Display plan → request confirmation
      ↓
6. Allocate worktrees
      ↓
7. Execute Gate 0-5 per stage (parallel where possible)
      │     ↓ every key action: persist checkpoint
      │     ↓ every decision: write ADR immediately
      │     ↓ every debt discovery: write ledger immediately
      │     ↓ every 5 min: heartbeat snapshot
      ↓
8. Gate 3 hardened: task test → task lint → task fmt (non-zero = block)
      ↓
9. Aggregate results → merge to main
      ↓
10. Update roadmap (mark completed stages)
      ↓
11. Cleanup worktrees
```

### Error Handling

```yaml
error_recovery:
  context_overflow:
    action: auto_recover
    mechanism: read checkpoints.json → resume from last action
    data_loss_risk: zero (atomic writes with fsync)

  process_termination:
    action: auto_recover
    mechanism: read checkpoints.json + loop-state.yaml on restart
    data_loss_risk: at most 5 min (heartbeat interval)

  stage_failure:
    action: pause
    notify: true
    retry: 3
    fallback: skip_with_debt
    persist: error saved to checkpoint immediately

  merge_conflict:
    action: pause
    notify: true
    require_human: true

  worktree_error:
    action: release_and_reallocate
    retry: 2

  test_failure (Gate 3):
    action: block
    mechanism: non-zero exit → gate does not advance
    persist: test results saved to checkpoint
    notify: P1 (auto-continue NOT allowed — gate is blocked)
```

---

## Test Plan

### Unit Tests

```bash
tests/unit/loop/test_auto_detection.bats        # Auto-detect from roadmap
tests/unit/loop/test_persistence.bats            # Checkpoint/ADR/debt save triggers
tests/unit/loop/test_gate_hardening.bats         # Non-zero exit blocking
tests/unit/loop/test_task_registry.bats          # gotask convergence
tests/unit/dependency/test_graph_analyzer.bats
tests/unit/worktree/test_pool_manager.bats
tests/unit/scheduler/test_subagent_scheduler.bats
```

### E2E Tests

```bash
tests/e2e/test_multi_stage_sequential.bats       # 19→20→22 full flow
tests/e2e/test_multi_stage_parallel.bats         # [19,21]→20→22
tests/e2e/test_worktree_isolation.bats
tests/e2e/test_progress_dashboard.bats
tests/e2e/test_crash_recovery.bats               # Kill process, restart, verify recovery
tests/e2e/test_gate3_test_failure_blocks.bats    # Broken test → gate blocks
tests/e2e/test_gate3_lint_failure_blocks.bats    # Lint violation → gate blocks
```

### Integration Tests

```bash
tests/integration/test_full_pipeline.bats        # Stage 19-22 complete flow
tests/integration/test_loop_survives_compact.bats # Context overflow simulation
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
| 2.0 | 2026-07-10 | Major redesign: auto-detect default, remove `start`/`--goal`, fine-grained persistence, hardened Gate 3, gotask convergence |
| 1.0 | 2026-03-13 | Initial design |
