# RDD Loop Skill

> **Purpose**: Autonomous stage execution loop with auto-detection, fine-grained persistence, hard quality gates, and crash-resilient recovery.

## Overview

The RDD Loop provides the operational framework for autonomous multi-stage execution. It auto-detects incomplete stages from the roadmap, resolves dependencies, executes each stage through all 5 gates, and persists state at every key action to survive context overflow and process termination.

**Key design decisions (ADR 22A-22F)**:
- **Auto-detect**: No arguments required — scans roadmap for incomplete stages
- **No `start` subcommand**: `/rdd-loop` is inherently "start"
- **No `--goal` NL parsing**: Roadmap Goal field is the authoritative data source
- **Fine-grained persistence**: State saved at every action, not just gate boundaries
- **Hardened Gate 3**: Real `task test`/`task lint`/`task fmt` execution
- **gotask convergence**: All scripts must be registered as `task` entries

---

## Command Interface

```
/rdd-loop [options]
/rdd-loop status|pause|resume
```

| Option | Description | Default |
|--------|-------------|---------|
| (none) | Auto-detect all incomplete stages, execute all | — |
| `--from N` | Start from stage N | first incomplete |
| `--to M` | Stop after stage M | last incomplete |
| `--parallel N` | Max parallel stages | 1 |

---

## Stage Execution Flow

```
/rdd-loop invoked
      │
      ▼
Read stage-roadmap.md → auto-detect incomplete stages
      │
      ▼
Apply --from/--to filter (if specified)
      │
      ▼
Topological sort by dependencies
      │
      ▼
Display execution plan → request confirmation
      │
      ▼
For each stage (parallel groups where possible):
  │
  ├─→ GATE 0: Stage Startup Check
  │     ├─ Verify roadmap exists
  │     ├─ Check dependencies complete
  │     ├─ Load ADRs, tech debt, previous stages
  │     └─ [persist: gate-enter]
  │
  ├─→ GATE 1: Design Document Pre-Check
  │     ├─ Verify design doc exists
  │     ├─ Check section completeness
  │     ├─ Detect scope creep
  │     └─ [persist: gate-exit]
  │
  ├─→ GATE 2: Design Review
  │     ├─ Multi-model review
  │     ├─ AI pre-filter (expect ~50% false positives)
  │     ├─ Fix critical/high findings
  │     └─ [persist: gate-exit]
  │
  ├─→ GATE 3: Implementation & Testing (HARDENED)
  │     ├─ task test:unit        ← non-zero exit = BLOCK
  │     ├─ task test:e2e         ← non-zero exit = BLOCK
  │     ├─ task test:coverage    ← below threshold = BLOCK
  │     ├─ task lint:check       ← errors = BLOCK, warnings pass
  │     ├─ task fmt:check        ← violations = BLOCK
  │     ├─ task registry:verify  ← orphans = BLOCK
  │     └─ [persist: test results, gate-exit]
  │
  ├─→ GATE 4: Code Review
  │     ├─ Multi-model code review
  │     ├─ Triangulation verification
  │     ├─ Fix critical/high findings
  │     └─ [persist: gate-exit]
  │
  ├─→ GATE 5: Completion Check
  │     ├─ Verify acceptance criteria
  │     ├─ Check test reproducibility
  │     ├─ Update all documents (stage-N.md, roadmap, ADR, tech-debt, next-steps, CHANGELOG)
  │     ├─ Run fresh-agent-check
  │     └─ [persist: gate-exit, send P2 notification]
  │
  └─→ Mark stage complete in roadmap → proceed to next
```

---

## Persistence Architecture

### Files

| File | Purpose | Update Frequency |
|------|---------|-----------------|
| `.rdd/cache/loop-state.yaml` | **Canonical** loop execution state | every key action |
| `.rdd/cache/checkpoints.json` | Backward compat (single-stage) | gate transitions |
| `.rdd/cache/heartbeat/*.yaml` | Timestamped snapshots | every 5 min |
| `docs/08-autonomous-decisions.md` | ADR log | on decision |
| `docs/12-technical-debt.md` | Tech debt ledger | on debt discovery |

### Recovery Protocol

```
Session restart
    │
    ▼
.rdd/cache/loop-state.yaml exists?
    ├─ Yes → Recovery Mode
    │   ├─ Read loop-state.yaml → determine current stage + gate
    │   ├─ Read ADR log → decisions since session start
    │   ├─ Read debt ledger → debt discovered
    │   ├─ Run task test → verify environment intact
    │   └─ Resume from last saved action (not last gate boundary)
    │
    └─ No  → checkpoints.json exists?
        ├─ Yes → Fallback to single-stage recovery
        └─ No  → Fresh start (scan roadmap)
```

**Maximum data loss window**: 5 minutes (heartbeat interval).

---

## Gate 3: Hardened Checks

Gate 3 is the critical quality barrier. **No check is bypassable**.

```bash
task test:unit        # exit ≠ 0 → gate blocked
task test:e2e         # exit ≠ 0 → gate blocked
task test:coverage    # below threshold → gate blocked
task lint:check       # errors → gate blocked, warnings pass
task fmt:check        # violations → gate blocked
task registry:verify  # orphans → gate blocked
```

All pass → Gate 3 approved → proceed to Gate 4.

---

## gotask Convergence

Every script must be registered as a `task` entry. The `task registry:verify` check ensures zero orphans.

```
scripts/health.sh  →  task health:check
scripts/metrics.sh →  task metrics:show
scripts/logger.sh  →  task logger:test
... and so on for all scripts/ and .rdd/scripts/
```

---

## Error Handling

| Category | Example | Response |
|----------|---------|----------|
| Recoverable | Test failure, lint warning | Auto-fix, retry up to 3 times |
| Degradable | Feature too complex for one stage | Reduce scope, record as tech debt |
| Blockable | Missing dependency, design flaw | Pause, notify human (P0) |
| Fatal | Data loss, security issue | Stop immediately, notify (P0) |

### Stale Detection

| No progress | Action |
|-------------|--------|
| 15 min | Warning, try alternative |
| 30 min | First degradation strategy |
| 45 min | Second degradation strategy |
| 60 min | Escalate to human (P0) |

---

## Notification Tiering

| Level | Trigger | Blocks? |
|-------|---------|---------|
| P3 | Daily summary, milestone reached | ❌ No — auto-continue |
| P2 | Stage complete, handoff generated | ❌ No — auto-continue |
| P1 | Stage failed, retries exceeded, merge conflict | ❌ No — continue with caution |
| P0 | Fatal error, core hypothesis falsified, max retries exceeded across stages | ✅ **Yes — wait for human** |

---

## Integration

This skill integrates with:

| Component | Script |
|-----------|--------|
| Auto-detection | `.rdd/scripts/auto-detect.sh` |
| Persistence | `.rdd/scripts/loop-persist.sh` |
| Task registry | `.rdd/scripts/task-registry.sh` |
| Worktree pool | `.rdd/scripts/worktree-pool.sh` |
| Subagent scheduler | `.rdd/scripts/subagent-scheduler.sh` |
| Progress dashboard | `.rdd/scripts/progress-dashboard.sh` |
| Checkpoint (backward compat) | `.rdd/scripts/checkpoint.sh` |

---

## Reference

- `docs/stages/stage-22.md` — Stage 22 design document (v2.1)
- `docs/stages/stage-22-review-log.md` — Design & code review findings
- `docs/08-autonomous-decisions.md` — ADR 22A-22F
- `docs/operations/release-guide.md` — Release & version upgrade
