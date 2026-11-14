# Phase 5 real-client smoke evidence

Date: 2026-11-14. Reproduce with `task test:clients` (explicit opt-in; uses the user's existing authenticated clients). The runner installs both targets into a temporary user/prefix, creates an isolated project, and copies the installed skill trees into host-specific project discovery directories. It does not install into the real home or alter client settings. Temp project source is removed after the run; logs and checkpoint evidence remain under `.rdd/cache/client-smoke/`.

## Versions

- claude: `2.1.325 (Claude Code)`
- codex: `codex-cli 0.169.0`

## Actual commands and prompts

The reproducible implementation is `tests/client_smoke.py`. Claude is invoked with `-p --tools Read,Bash --allowedTools 'Read,Bash(task *)' --no-session-persistence --output-format json`; Codex uses `exec --ephemeral --sandbox workspace-write --skip-git-repo-check --json`. No permission bypass is used.

Claude prompt: Use `/rdd-help`; run `task checkpoint:save -- 23 fixture 10` then `task checkpoint:show`. Read the shared runtime contract, report pending Stage/Gate and actual skill path. Run `task test:unit` once; report its nonzero exit as blocking Gate 3. No source editing, completion marking or notifications.

Codex prompt: Use `$rdd-help`; run `task checkpoint:show` on Claude's checkpoint without saving/changing it. Perform the same failed-test and runtime-contract check.

Both processes exited 0. The runner asserted `project.current_stage == "23"` and byte-identical checkpoint data after Codex's read. The expected failing test task returned 201 (underlying exit 1), and neither client claimed Gate 3 passed. This verifies the tested shared workflow, not exhaustive model behavior across every skill.

## Claude report

## RDD checkpoint smoke — results

**Skill used:** `/rdd-help`
- Actual path: `/private/var/folders/r1/9_nk7thn63jg5jy_5kr6xq400000gn/T/rdd-client-smoke-zck7mqty/project/.claude/skills/rdd-help/SKILL.md`
- Mirror also installed at `.agents/skills/rdd-help/SKILL.md` (Codex host). Sibling skills resolve under `.claude/skills/rdd-*/`.

**Shared runtime contract read:** `.claude/skills/rdd-core/references/runtime.md` — key points applied: project-relative resolution of `docs/`, `.rdd/`, `Taskfile.yml`; "unconfigured tests are failures, never passes"; no client lifecycle hooks; external notification only if authorized (not authorized here).

### Checkpoint results

`task checkpoint:save -- 23 fixture 10` → `Checkpoint saved at 2026-11-14T11:20:31Z`

`task checkpoint:show`:

| Field | Value |
|---|---|
| Current Stage | 23 |
| Stage name | fixture |
| Progress | 10 |
| Status | in_progress |
| Gates 1–5 | all `[ ] pending` |
| Recovery count | 0 |

(Verified in `.rdd/cache/checkpoints.json`.)

### Pending stage / gate

**Stage 23, Gate 3 (Implementation & Testing) — pending, and now blocking.**

`docs/11-next-steps.md` independently agrees: `Stage: 23. Gate: 3. Tests unconfigured; Gate 3 pending.`

### Test run (once)

`task test:unit` → **non-zero exit (task exit status 1; shell reported 201)**

```
task: [test:unit] echo "Configure test:unit for this project before Gate 3" >&2; exit 1
Configure test:unit for this project before Gate 3
task: Failed to run task "test:unit": exit status 1
```

This is the fixture's deliberate unconfigured-test stub. Per the runtime contract this is a **failure, not a pass**, so it blocks Gate 3.

### Not done (per instruction)

- No source files edited.
- No stage completion or gate status written (`checkpoint:gate` not invoked).
- No commits, no notifications sent.

Next action when you're ready: bind a real `test:unit` command in `Taskfile.yml`, re-run it, then advance Gate 3.

Reported backend model: tokenhub/deepseek-v4-flash. This is evidence about the configured model, not an assumption based on the Claude client name.

## Codex report

I’m using `rdd-help` to read the installed runtime contract and checkpoint, then run `task test:unit` once. I’ll report the pending stage, gate, and test result without changing the checkpoint or source.



- Read `task checkpoint:show`: Stage **23**, `in_progress`; all gates pending. Next steps identify **Gate 3** as the current pending gate.
- Ran `task test:unit` **once**: process exit **201**, underlying task exit **1**—“Configure test:unit for this project before Gate 3.” **Gate 3 is blocked.**
- Actual skill: [`.agents/skills/rdd-help/SKILL.md`](/private/var/folders/r1/9_nk7thn63jg5jy_5kr6xq400000gn/T/rdd-client-smoke-zck7mqty/project/.agents/skills/rdd-help/SKILL.md).
- Read the installed [shared runtime contract](/private/var/folders/r1/9_nk7thn63jg5jy_5kr6xq400000gn/T/rdd-client-smoke-zck7mqty/project/.agents/skills/rdd-core/references/runtime.md).

No checkpoint saves, source edits, commits, completion markings, or notifications.
