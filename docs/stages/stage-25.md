# Stage 25: Parity verification and delivery

## Status
Complete — all five Phase 5 gates passed. Date: 2026-11-14. Phase 5 authorized by user.

## Goal
Prove installation and shared workflow behavior with reproducible tests and document the limits of host verification.

## Non-goals
No release publication, Windows-native shell support, host authentication changes, host permission bypasses, or new notification integrations. No promise of identical LLM outputs or uninterrupted background execution after the host exits.

## Hypothesis
Both installed clients can discover shared workflows and perform the same persistent-state operation in an isolated project.

## Design and Acceptance Criteria
- task test:agents runs focused unit tests and real local installation E2E paths for codex-only and both, rerun, upgrade and uninstall.
- Run the tests again from a clean copied source and temporary user directory. No tests write into the real user skills or project state.
- Verify all 17 installed skill names/content, sibling reference resolution, CLI init/status/help and shared Task scripts; test collisions and unrelated-file preservation.
- Verify npm packed installation as well as shell installation.
- Run repository tests through task test in an isolated copy, with external notifications disabled. Record baseline failures separately; do not convert failure to success.
- Run actual installed client discovery/help smoke tests when credentials and client capabilities allow. Do not claim host execution parity on file assertions alone.
- Coverage evidence must measure executed code, not test-count estimates. Gate 3 remains open if measurement or real-client checks cannot be obtained.
- Update README, CHANGELOG, ADR, debt, next steps, stage designs and review logs together; run an independent fresh-agent handoff check.

## Verification
Use Task entry points with temporary install/user directories and a clean source copy. Installation tests run real filesystem/CLI operations; host smoke tests are separately identified. Record commands, results and unavailable evidence in stage-25-review-log.md.

## Rollback
Revert Phase 5 source changes; remove only installer-owned skill directories and runtime prefix. Restore explicitly backed-up prior skills if replacement was requested. Existing project documents and client settings are preserved.

## Gates
- Gate 1: passed; goals, non-goals, acceptance and rollback documented.
- Gate 2: passed; independent-context and external-model findings verified.
- Gate 3: passed; clean full suite 909/909, focused lifecycle 25/25, changed Python executed-line coverage 89%, Linux lifecycle 4/4 and real-client checkpoint smoke.
- Gate 4: passed; main developer, independent reviewer, external model and rule checks; all verified blocking findings resolved.
- Gate 5: passed; hypothesis supported within stated scope, reproducible Task entries, synchronized documents/debt/ADR, independent Phase 5 fresh-agent-check passed.

## Implementation differences
See the verified design-review resolutions and bounded deviations below. Both clients share one implementation; no separate workflow fork was introduced.

## Design review resolutions (2026-11-14)
- Use a Python 3 standard-library lifecycle manager shared by shell and npm; Python 3 is an explicit prerequisite checked before mutation. Bash bootstrap remains compatible with macOS Bash 3.2. No dependency auto-install or permission bypass.
- Manifest records ownership, client selection and tree digests. Preflight all destinations; modified/unowned skills require explicit --replace-skills and are backed up. Stage runtime and skill trees before replacement; restore prior trees on commit failure. Never follow destination skill symlinks.
- Generate fresh project state, copy runtime, and fail closed for unconfigured tests. Preserve existing files during migration; place Task definitions in Taskfile.rdd.yml when a user Taskfile exists and document task -t Taskfile.rdd.yml.
- Stage 23/24 include focused tests before code review; Stage 25 aggregates clean environment and real-client evidence. A missing real model/coverage result is an open Gate, not a pass.
- Scheduler stays a host-consumed request protocol; only schedule one sequential request at a time, retain worktrees, fix path-only stdout contract. Native host delegation performs actual execution and gates; no unvalidated shell launch backend.

## Contract clarifications
- Codex location and invocation verified against https://learn.chatgpt.com/docs/build-skills (2026-11-14): ~/.agents/skills, $skill-name, required name/description. Canonical skills use these common fields; do not install duplicate global and project copies in client smoke tests.
- Skill sibling references resolve relative to the current SKILL.md; docs/ and .rdd/ refer to the active user project; rdd resolves the installed runtime. These three namespaces must not be interchanged.
- Coverage denominator is executable Python lifecycle-manager lines measured by Python trace; Bash/Node thin wrappers are exercised by subprocess E2E. Baseline shell coverage remains separate.
- npm postinstall prints instructions only; `npx @kofj/rdd install --agent both` is the explicit one-command lifecycle entry. Shell entry supports remote tagged sources and local --source; no credential/host-setting changes.
- Target selection is additive on an existing prefix: selecting codex later adds it without removing an installed Claude target. Uninstall removes all unmodified assets owned by that prefix; user modifications are preserved and reported.
- Scheduler correctness is explicitly within Stage 24 scope because both clients rely on the same scheduling semantics.
- Rollback order: uninstall using the new manager first, then revert source. Restorable skill backups are never auto-deleted.

## Verified implementation differences: macOS runtime portability
A clean full-suite run exposed 19 failures; selected suites reproduced them on unmodified HEAD. To verify the shared runtime on this supported macOS host, Stage 25 includes bounded portability fixes: GNU head -n -1 and sed -i assumptions, Bash 4 script interpreter selection, numeric ps whitespace, grep no-match count handling and find -executable portability. These preserve intended functionality and use existing regression tests; no new product capability is introduced.

Final gate inspection also corrected the inherited lint exit-code assumption: xargs maps child failures, so checking only exit 2 could accept lint errors. The task now selects shellcheck error severity and propagates any tool failure. Formatting normalization of two pre-existing scripts (checkpoint/archive) is included solely to pass the repository-wide format gate.

## Completion evidence
2026-11-14: acceptance criteria met within the documented environment and host-behavior limits. See the corresponding review log for commands, verification reasons and retained debt. Publication is outside this Stage; the changes are an unreleased working-tree implementation. No further Phase 5 Stage remains.
