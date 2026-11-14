# Next Steps

## Current State
- Phase: 5 complete — Claude Code / Codex parity
- Stages 23, 24, 25: all five gates passed within their documented scope
- Last updated: 2026-11-14
- Delivery: v1.3.0 Git release; npm publication is separate

## Next Single Action
Verify the v1.3.0 GitHub release workflow after pushing the tag. No implementation Stage remains in the approved Phase 5 roadmap. npm publication is separate; use the tagged shell installer or local source installation documented in README.

## Local Installation
```bash
bash scripts/install/install.sh --source . --agent both
```
For an existing legacy/unowned installation, explicitly add `--replace-skills` to back it up. Install only Codex with `--agent codex`. See README for prefix, upgrade and uninstall behavior.

## Reproducible Verification
- `task test:clean`: 909 passed / 0 failed (869 unit wrapper tests + 40 E2E). Disposable source copy with notification channels disabled; log: .rdd/cache/clean-test.log.
- `task test:agents`: 25 focused real-filesystem/CLI lifecycle and regression tests passed.
- `task test:agents:coverage`: 89% executed-line coverage of the changed Python manager; no claim of whole-repository shell coverage.
- `task test:clients`: opt-in authenticated Claude Code 2.1.325 / Codex CLI 0.169.0 smoke; Claude writes Stage 23 checkpoint, Codex reads it unchanged, both report failing unconfigured tests as a Gate 3 blocker.
- `task test:linux IMAGE=mirrors.tencent.com/eliolei/python:3.13`: 4 Linux lifecycle tests passed, read-only source/no network; default IMAGE is python:3.13.
- `task lint:check`, `task fmt:check`, `task registry:verify`, `task docs:fresh-check`, `git diff --check`: passed, plus independent scoped fresh-agent review.

## Evidence
- docs/stages/stage-23.md, stage-24.md, stage-25.md and corresponding review logs
- docs/stages/phase-5-design-review.md and phase-5-code-review.md: external review with actual backend model identity
- docs/stages/phase-5-client-smoke.md: client versions, exact workflow, outputs and isolation

## Known Limits / Debt
TD-24: no automatic installer recovery after SIGKILL/power loss; backups retained, parent skill-directory symlinks refused, prefixes per user. TD-25: historical charter template remains for human governance; README/roadmap define Phase 5 goals. TD-26: old shell-wide coverage fallback is only an estimate; Phase 5 uses measured Python coverage. Client smoke does not certify every autonomous model decision or background execution after host exit.

## Completion Notification
2026-11-14 P2: Stage 23 installation, Stage 24 shared workflows and Stage 25 verification complete. Continued automatically through the approved stages. No external notification destination was used.
