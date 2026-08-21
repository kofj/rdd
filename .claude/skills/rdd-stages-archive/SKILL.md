---
name: rdd-stages-archive
description: Archive old RDD stage documents to keep the working directory clean and focused
---

# RDD Stages Archive Skill

> Archive old stage documents to keep the working directory clean and focused on current work.

---

## Overview

The `stages:archive` skill archives old `stage-N.md` files from `docs/stages/` to `docs/stages/archived/`. It keeps the 5 most recently completed stages (by stage number) plus any incomplete stages, ensuring your working directory stays focused on current work.

**Command:** `task stages:archive`

---

## When to Use This Skill

**Triggers:**
- After completing several stages and wanting to declutter `docs/stages/`
- Before starting a new phase or major milestone
- When `docs/stages/` has accumulated too many stage files
- User explicitly asks to "archive old stages" or "clean up stage files"

---

## Behavior

### What Gets Archived

Only `stage-N.md` files (pure numeric pattern, e.g. `stage-1.md`, `stage-15.md`) are considered for archiving. All other files in `docs/stages/` remain untouched, including:
- `stage-N-design.md` — design documents
- `stage-N-review-log.md` — review logs
- `stage-roadmap.md` — roadmap
- `stage-template.md` — template
- Any other non-numeric files

### Keep Rule

1. The 5 highest-numbered **completed** stages are always kept
2. All **incomplete** stages are kept regardless of count
3. Everything else (older completed stages) moves to `docs/stages/archived/`

Completion status is determined from the roadmap table in `docs/stages/stage-roadmap.md`.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dry-run` | Preview changes without making them | off |
| `--keep N`  | Number of recent completed stages to keep | 5 |
| `--help, -h` | Show help message | — |

---

## Examples

```bash
# Preview what would be archived
task stages:archive -- --dry-run

# Archive, keeping only 3 recent completed stages
task stages:archive -- --keep 3

# Done — archive normally
task stages:archive
```

---

## Implementation

When invoked:
1. Reads `docs/stages/stage-roadmap.md` to determine completed stages
2. Scans `docs/stages/` for `stage-N.md` files (pure numeric only)
3. Sorts completed by number descending, keeps top N
4. Keeps all incomplete stages
5. Moves the rest to `docs/stages/archived/`
6. Reports results

### Script

`.rdd/scripts/stages-archive.sh` — core archive logic, usable standalone or via task.

### Taskfile Entries

| Task | Description |
|------|-------------|
| `stages:archive` | Archive old stages |
| `stages:archive:dry-run` | Preview without moving files |

---

## Reference

- [RDD Core Skill](rdd-core.md) — Core RDD concepts
- [RDD Help Skill](rdd-help.md) — Full command reference
