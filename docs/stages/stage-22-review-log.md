# Stage 22 Review Log

**Review Type**: Design
**Review Date**: 2026-07-10
**Reviewer**: Claude (self-review)
**Stage**: Stage 22 v2.0

---

## Review Summary

Design v2.0 is structurally sound — auto-detection, persistence, hardened gates, and convergence are all correct architectural directions. However, three blocking issues were found: implementation language mismatch, unsuitable lint/fmt tool selection, and checkpoint schema conflict with existing infrastructure.

---

## Findings

### F-1: Implementation language mismatch — Python in a bash project [CRITICAL]

**Description**: Tasks 3 (LoopPersistence), 5 (TaskRegistry), and 7 (WorktreePool) are specified in Python, but the project has **zero Python files** — it is 100% bash + bats. Running `find` for `*.py` returned nothing.

```python
# Design says:
class LoopPersistence:
    CHECKPOINT_FILE = ".rdd/cache/checkpoints.json"
    def on_gate_enter(self, stage_id: int, gate: int):
        ...

# Project reality:
# All scripts are in .rdd/scripts/*.sh
# All tests are in tests/unit/*.bats
```

**Fix**: Either:
- (A) Redesign in bash — align with existing codebase (`checkpoint.sh`, `handoff.sh` patterns)
- (B) Add Python as a dependency with `pip install` in bootstrap — but this adds complexity with no precedent in the project

**Recommendation**: Option A. The existing `checkpoint.sh` already implements the patterns needed. The persistence layer should extend it, not replace it.

**Verification**: `find . -name "*.py" -not -path "*/tests/lib/*"` returned empty.

---

### F-2: Gate 3 lint/fmt tools mismatch with project tech stack [HIGH]

**Description**: The hardened Gate 3 (`lint:check`, `fmt:check`) references Go-specific tools (`golangci-lint`, `gofmt`, `goimports`) and `shellcheck`, but:

| Tool | Installed? | Project has matching files? |
|------|-----------|---------------------------|
| `golangci-lint` | ✅ Yes | ❌ No Go files (`go.mod` not found) |
| `gofmt` | ✅ Yes | ❌ No Go files |
| `goimports` | ❌ **No** | ❌ No Go files |
| `shellcheck` | ❌ **No** | ✅ Yes (all scripts are `.sh`) |

The current `lint:check` task guards with `test -f go.mod` to skip Go checks, which is correct. But `fmt:check` passes `shellcheck` on `.sh` files **without checking if shellcheck is installed**, and Go formatting checks are irrelevant.

**Fix**:
1. Replace `gofmt`/`goimports` with `shfmt` (shell formatter, aligns with actual codebase)
2. Add `shellcheck` as a required dependency (check at bootstrap)
3. Remove all Go-specific lint/fmt except the guard-skipped `golangci-lint` (keep as optional)
4. Add `bats` syntax check for test files: `bats --formatter pretty --count-only`

**Verification**:
```
$ which shellcheck → (not found)
$ which goimports → (not found)
$ find . -name "*.go" -not -path "*/tests/lib/*" → (empty)
```

---

### F-3: checkpoints.json schema conflict with existing infrastructure [HIGH]

**Description**: ADR-22D specifies atomic writes to `.rdd/cache/checkpoints.json`, but this file already exists and `checkpoint.sh` has its own schema (`version`, `project`, `stage`, `gates`, `decisions`...). The design adds a new `.rdd/cache/loop-state.yaml` but doesn't explain:
1. Relationship between `checkpoints.json` and `loop-state.yaml`
2. Migration path for existing checkpoint data
3. Which file is authoritative for recovery

**Fix**:
1. Use `loop-state.yaml` as the **single source of truth** for loop execution state
2. Keep `checkpoints.json` for single-stage gate tracking (backward compatible)
3. Recovery protocol reads `loop-state.yaml` first, falls back to `checkpoints.json`
4. Add a `task loop:migrate` to convert old checkpoint to new loop state

---

### F-4: No `Taskfile.yml` lint task exists [MEDIUM]

**Description**: The hardened Gate 3 references `task lint:check` and `task fmt:check`, but these tasks don't exist in the current `Taskfile.yml`. They're defined inline in the design but not registered.

**Fix**: Add `lint:check` and `fmt:check` as real tasks during Stage 22 implementation (Task 5: gotask convergence applies here too).

---

### F-5: Parallel worktree subagent — token budget not addressed [MEDIUM]

**Description**: The design supports up to 3 parallel worktrees with subagents, but doesn't address token budget management. Three concurrent subagents could exhaust token quotas quickly.

**Fix**: Add `--parallel` default of 1 (sequential), with explicit opt-in to higher concurrency. Document that `--parallel 2` roughly doubles token consumption.

---

### F-6: `task:check` orphan detection is fuzzy [LOW]

**Description**: The `verify_no_orphans` function in Task 5 "scans `.rdd/scripts/` and `.claude/` for executable files not referenced in Taskfile.yml" — but `.claude/` contains skill/command markdown files that are never referenced in Taskfile, making this check noisy.

**Fix**: Limit orphan detection to `scripts/` and `.rdd/scripts/` only.

---

## AI Filter Results

| Finding | Initial Verdict | After Verification |
|---------|----------------|-------------------|
| Python in bash project | Plausible mismatch | **CONFIRMED** — zero Python files in repo |
| Go tools for bash project | Plausible mismatch | **CONFIRMED** — no Go files, shellcheck not installed |
| checkpoints.json conflict | Needs verification | **CONFIRMED** — schema exists in checkpoint.sh:106-143 |
| Missing lint task | Self-evident | **CONFIRMED** — grep confirms no `lint:check` in Taskfile.yml |

---

## Resolution Summary

| # | Severity | Fix Strategy | Status |
|---|----------|-------------|--------|
| F-1 | Critical | Redesigned Task 3/5/7 in bash (extending checkpoint.sh) | ✅ Fixed |
| F-2 | High | Replaced Go tools with shellcheck/shfmt, added bootstrap:deps | ✅ Fixed |
| F-3 | High | loop-state.yaml canonical, checkpoints.json backward compat | ✅ Fixed |
| F-4 | Medium | lint:check / fmt:check implemented as real Taskfile tasks | ✅ Fixed |
| F-5 | Medium | Default --parallel 1, token implications documented | ✅ Fixed |
| F-6 | Low | Orphan scan limited to scripts/ directories | ✅ Fixed |

**Total Findings**: 6
**Fixed**: 6
**All Critical Fixed**: Yes
**All High Priority Addressed**: Yes

---

## Design Review Conclusion (Updated)

**Verdict**: ✅ Approved — all critical and high findings resolved. Design v2.0 now aligns with the bash-based codebase.

**Gate 2 Status**: ✅ Passed
