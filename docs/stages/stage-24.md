# Stage 24: Shared RDD workflows

## Status
Complete — all five Phase 5 gates passed. Date: 2026-11-14. Phase 5 authorized by user.

## Goal
Both clients expose the same 17 skills and use the same scripts, project instructions, tests and persisted state.

## Non-goals
No release publication, Windows-native shell support, host authentication changes, host permission bypasses, or new notification integrations. No promise of identical LLM outputs or uninterrupted background execution after the host exits.

## Hypothesis
A single set of skill instructions and project runtime supports both hosts without client-specific workflow forks.

## Design and Acceptance Criteria
- Keep .claude/skills as the canonical source to avoid breaking existing consumers; repository .agents/skills links to it; distribution copies actual directories.
- Replace internal .claude/skills references with relative sibling references so installed skills resolve in either host.
- Explain /rdd-name in Claude and $rdd-name in Codex, with natural language as an equivalent entry. Shared runtime guidance governs all workflows.
- Generate AGENTS.md for both clients and a CLAUDE.md bridge; initialization copies runnable framework scripts, configuration and Task entries. Never overwrite existing user entry points or Taskfile during migration.
- Agent-hosted orchestration uses the host's available delegation tools. A shell scheduler trigger is a pending request, never evidence of completed execution. Sequential scheduling must not release a worktree before its task is actually completed.
- Review records distinguish independent same-model review from verified multi-model review. Missing independent model availability is recorded, never fabricated.
- Same hook scripts are callable through Task; installation does not silently register host lifecycle hooks or send external messages.

## Verification
Use Task entry points with temporary install/user directories and a clean source copy. Installation tests run real filesystem/CLI operations; host smoke tests are separately identified. Record commands, results and unavailable evidence in stage-24-review-log.md.

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

### Verified implementation deviation
The new persistence E2E exposed a pre-existing Stage 22 bug: yq returns success for an empty select, so stage-start never inserts a new stage. Correct the existence check with yq -e and retain this regression test as part of shared state recovery parity. This is a bounded fix to Stage 24's persistent-state contract, not a roadmap expansion.

## Completion evidence
2026-11-14: acceptance criteria met within the documented environment and host-behavior limits. See the corresponding review log for commands, verification reasons and retained debt. Publication is outside this Stage; the changes are an unreleased working-tree implementation. No further Phase 5 Stage remains.
