# Stage 25 Review Log

Status: Complete (2026-11-14). Review history and final evidence below.

## Independent design review
Reviewer: separate agent context; different model identity not verified. Adopted after source inspection: manifest ownership and modified-file preservation, transactional replacement, fresh project test templates, real workflow smoke test beyond discovery, scheduler stdout/worktree retention, wrapper Bash handling and per-stage tests. Evidence: uninstall.sh removed whole trees; init.sh emitted echo-only tests; scheduler captured logging stdout. No findings rejected; multi-model review requested separately via Claude CLI and pending.

## External model review and verification
Claude CLI returned modelUsage `tokenhub/deepseek-v4-flash`; full response in phase-5-design-review.md. Accepted: manifest/digests, distinct stage hypotheses, reference namespaces, Python execution coverage, real-client work and explicit scheduler scope. Codex directory concern resolved by official skill docs already fetched. Rejected blanket prohibition on remote bootstrap: user explicitly requested one-command installation; HTTPS release bootstrap remains supported with visible source. Rejected claiming Stage 25 complete without host verification: keep Gate open instead. npm postinstall side effects removed in favor of explicit install subcommand. Gate 2 design review passed after these revisions; implementation subsequently verified; see final evidence.

## Code review verification
- Independent reviewer reproduced dry-run uninstall mutation, new-runtime-file collisions and stale retired skills. All accepted; regression cases now exercise them.
- Wrapper uninstall from a temporary download and version-tag identity: accepted and covered by `test_temporary_bootstrap_uninstall_and_version_identity`.
- External model review (`tokenhub/deepseek-v4-flash`, phase-5-code-review.md): accepted installed-runtime reconfiguration, per-home manifest validation, unchanged-tree no-op, lifecycle locking, template replacement count and project runtime paths. Implemented and tested.
- Rejected target shrinking: additive target selection is an explicit design contract, documented in README. Users are not silently opted out on upgrade.
- Retained refusal of symlinked parent directories as a documented supported-environment limit, not a claim that all dotfile layouts are supported. Explicit skill symlinks can be backed up without following their target.
- Rejected deletion of modified assets/cache on uninstall and silent append to existing user guidance: preserving user content is the agreed contract.
- Runtime's bundled skill source is intentional: it supports offline `rdd install --agent codex` and is distinct from the clients' discovery copies.
- Generic instruction to recover automatically after SIGKILL is beyond the exception-rollback contract: backups remain, but no durable transaction journal is claimed. Track this operational limit in debt ledger.

## Verification commands
`task test:agents`: 25 tests passed, including real shell/npm packaged installation, lifecycle, user-file protection, scheduler retention and state persistence.
`task test:agents:coverage`: executing Python lines measured with trace --missing; final measured result 89% (383 executable lines in manage.py; shell/Node wrappers covered by subprocess E2E).
`git diff --check`, changed-shell `shellcheck -S error`, and `task registry:verify`: passed.
`task test:clean` passed: 869 unit wrapper tests + 40 E2E = 909, zero failures; earlier inherited macOS failures were reproduced on HEAD and bounded portability corrections passed all 177 relevant tests.

## Final verification evidence
- `task test:clean`: **909 passed, 0 failed, exit 0**. Runner in tests/run_clean.py copies sources into a disposable directory, disables notification channels, and runs the real `task test` entry. Raw output: .rdd/cache/clean-test.log.
- `task test:agents`: **25 passed** in the final suite; the earlier 23-test suite also passed independently in a clean temporary copy. This count is separate from the Bats wrapper count above.
- `task test:agents:coverage`: **89%** executed-line coverage of the changed Python lifecycle manager. This is not a whole-repository shell coverage claim.
- `task test:linux IMAGE=mirrors.tencent.com/eliolei/python:3.13`: **4 passed** in a cached Linux amd64 Python container under emulation, with source mounted read-only and network disabled. Default portable image selector is python:3.13; IMAGE is an explicit environment choice. Linux npm was not separately exercised; npm packaged installation passed on macOS.
- `task test:clients`: real Claude Code 2.1.325 and Codex CLI 0.169.0; explicit Stage 23 checkpoint saved by Claude and read unchanged by Codex, unconfigured unit test correctly blocks Gate 3. Full prompts, versions, outputs and limitations: [phase-5-client-smoke.md](phase-5-client-smoke.md).
- `task lint:check`, `task fmt:check`, `task registry:verify`, `git diff --check`: passed. Shared skill frontmatter validated 17/17 after excluding Claude-specific policy field for the generic validator; matching Codex policy retained.
- Independent Gate 4 recheck passed, including the final offline-add-client version regression. No unresolved blocking review finding remains.

## Fresh-agent handoff review
Independent reviewer continued using only project instructions/current docs and reproduced 23/23 focused tests in a temporary source copy. Its findings were verified and addressed: corrected the fresh-check Task name, added detailed real-client evidence, added task test:clean, and synchronized debt/current state. Final scoped documentation recheck passed; Gate 5 closed.

## Final closure
- Independent fresh-agent-check: passed for Phase 5; historical charter/whole-repository coverage limits are TD-25/TD-26.
- Final additional regressions: backup client-directory symlinks rejected before writes; backups outside discovery roots; CLI knowledge arguments reach real ADR/debt Task commands. 25 focused tests pass and measured manager coverage remains 89%.
- Independent reviewer confirmed these final local fixes; no blocking findings remain.
- P2 completion notification delivered in-session; no external channel was authorized. Auto-continued through Stages 23→24→25; all approved Phase 5 work is now complete. Release publication remains a separate action.
