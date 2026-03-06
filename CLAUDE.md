# CLAUDE.md - Claude Code Entry Point

> This is the Claude Code specific entry point for this RDD project.
> Read this document for Claude Code specific commands and workflows.

---

## Quick Start

```bash
# View current status
cat docs/11-next-steps.md

# View current Stage
cat docs/stages/stage-*.md

# Run tests
task test

# View available tasks
task --list
```

---

## Reading Order for New Sessions

When starting a new session, read documents in this order:

1. `docs/11-next-steps.md` - Current progress and next steps
2. `docs/01-charter.md` - Project boundaries
3. Current Stage document - Ongoing work details
4. `docs/08-autonomous-decisions.md` - Key decisions made
5. `docs/12-technical-debt.md` - Known issues

---

## Key Paths

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Main agent entry point (general rules) |
| `CLAUDE.md` | This file (Claude Code specific) |
| `CHANGELOG.md` | Change log |
| `Taskfile.yml` | Unified task entry |
| `docs/11-next-steps.md` | Current status (READ FIRST) |
| `docs/stages/` | Stage documents |
| `docs/08-autonomous-decisions.md` | ADR log |
| `docs/12-technical-debt.md` | Tech debt ledger |

---

## Tool Execution Rules

### File Operations

```
- Use Read tool to read files (not bash cat)
- Use Write tool to create new files
- Use Edit tool to modify existing files
- Use Glob tool to find files by pattern
- Use Grep tool to search file contents
```

### Documentation Updates

When updating documentation:

1. **Read the file first** using Read tool
2. **Make targeted edits** using Edit tool
3. **Preserve formatting** and structure
4. **Update version** in revision record if applicable

### Stage Completion

When completing a Stage, update ALL required documents:

```bash
# Documents to update:
docs/stages/stage-N.md           # Implementation differences
docs/stages/stage-N-review-log.md # Review findings (if exists)
docs/08-autonomous-decisions.md  # ADR entries
docs/12-technical-debt.md        # Tech debt updates
docs/11-next-steps.md            # Progress update
CHANGELOG.md                     # Change summary
```

---

## Common Tasks

### Starting a New Stage

```bash
# 1. Check current status
cat docs/11-next-steps.md

# 2. Check Roadmap
cat docs/stages/stage-roadmap.md

# 3. Create Stage document
# Use the template from docs/stages/

# 4. Run pre-Stage checks
task gate-check
```

### Running Reviews

```bash
# Design Review (before coding)
# Use multiple models independently
# First round: no hints, open questions
# Then: verify each finding

# Code Review (after E2E passes)
# Triangulation: main model + reviewer + rules
# Record in stage-N-review-log.md
```

### Updating Tech Debt

```bash
# 1. Read current tech debt
cat docs/12-technical-debt.md

# 2. Add new entry with proper format:
### TD-NN: Title
- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architectural/Module/Local]
- **Source**: [Source] (Stage N)
- **Original Description**: "..."
- **Source File**: path/to/file:line
- **Suggested Stage**: Stage N
```

### Recording ADR

```bash
# Add to docs/08-autonomous-decisions.md
### Decision N: Title

**Background**: What triggered this decision

**Decision**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (MUST NOT be empty)
```

### Handoff Preparation

When preparing for handoff:

1. Update `docs/11-next-steps.md` with current progress
2. Ensure all Stage documents are complete
3. Update tech debt ledger
4. Run `task fresh-check` to verify new agent can continue

---

## Verification Commands

### Gate Checks

```bash
# Run all gate checks for current Stage
task gate-check

# Run specific gate
task gate-1  # Design document check
task gate-2  # Design review check
task gate-3  # Implementation & testing check
task gate-4  # Code review check
task gate-5  # Completion gate check
```

### Fresh Agent Check

```bash
# Verify new agent can take over
task fresh-check
```

### Test Execution

```bash
# Run all tests
task test

# Run unit tests only
task test-unit

# Run E2E tests
task test-e2e

# Run with coverage
task test-coverage
```

---

## RDD Skills

### Available Skills

| Skill | Purpose |
|-------|---------|
| `rdd-init` | Initialize new RDD project |
| `rdd-migrate` | Migrate existing project to RDD |
| `rdd-roadmap` | Manage Roadmap |
| `rdd-stage-auto` | Auto-execute Stage with gates |
| `rdd-review-auto` | Auto-review with AI filtering |
| `rdd-recovery` | Auto-recovery from failures |
| `rdd-knowledge` | Manage ADR/tech debt/handoff |
| `rdd-diagnosis` | Diagnose RDD issues |
| `rdd-fresh-check` | Verify new agent can continue |
| `rdd-loop` | 7x24 auto progression |

### Using Skills

```bash
# Initialize new project
rdd init [--template <template>] [--enable-hooks]

# Migrate existing project
rdd migrate [--analyze] [--plan]

# Roadmap management
rdd roadmap show
rdd roadmap add-stage <name>
rdd roadmap progress

# Stage management
rdd stage new <name>
rdd stage verify <id>
rdd stage complete <id>
rdd stage handoff

# Knowledge management
rdd adr add
rdd debt add
rdd handoff generate

# Diagnostics
rdd diagnose [--fix]

# Auto loop
rdd loop start [--dry-run]
rdd loop status
```

---

## Forbidden Actions

Do NOT:

1. **Start coding without design doc** - Gate 1 must pass first
2. **Expand scope silently** - Update docs immediately if detected
3. **Claim completion with pending docs** - Docs must be synced
4. **Skip gates** - All 5 gates must pass before Stage completion
5. **Accept all review findings blindly** - 50% are false positives, verify each
6. **Hide tech debt** - All gaps must be in the ledger
7. **Leave ADR "impact" empty** - Impact on subsequent Stages is required

---

## Notification Integration

When human intervention is needed:

| Situation | Level | Action |
|-----------|-------|--------|
| Roadmap change | P0 | Pause, notify human, wait for approval |
| 3 consecutive failures | P0 | Pause, notify human |
| Core hypothesis falsified | P0 | Pause, notify human |
| Model disagreement | P1 | Continue, notify human for review |
| Tech debt threshold | P1 | Continue, notify human |
| Stage complete | P2 | Notify human |

---

## Stage Execution Workflow

```
1. Read docs/11-next-steps.md
   ↓
2. Check entry conditions for next Stage
   ↓
3. Create/read Stage design document
   ↓
4. [Gate 1] Design document check
   ↓
5. Design Review (before coding)
   ↓
6. [Gate 2] Design review check
   ↓
7. Implementation
   ↓
8. Unit tests (coverage >= 20%)
   ↓
9. E2E tests (>= 2 high-signal paths)
   ↓
10. Real environment verification
   ↓
11. Clean environment verification
   ↓
12. [Gate 3] Implementation & testing check
   ↓
13. Code Review (after E2E passes)
   ↓
14. [Gate 4] Code review check
   ↓
15. Update all required documents
   ↓
16. [Gate 5] Completion gate check
   ↓
17. Update docs/11-next-steps.md
   ↓
18. Run fresh-agent-check
   ↓
19. Mark Stage complete
```

---

## Tips for Claude Code

### Efficient Reading

- Use `Read` tool with `offset` and `limit` for large files
- Use `Grep` to find specific content quickly
- Read key documents first, detailed docs as needed

### Documentation Updates

- Always read file before editing
- Use `Edit` tool for targeted changes
- Preserve existing formatting
- Update revision records

### Review Findings

- Don't accept all findings blindly
- Verify using authoritative sources first
- Then code verification
- Finally, query model if needed
- Record all verification in review log

### Knowledge Management

- Record ADR for significant decisions
- Update tech debt ledger for any compromise
- Keep next-steps.md up to date
- Use handoff format for context transfer

---

## Emergency Procedures

### If Blocked

1. Document the blocker in `docs/11-next-steps.md`
2. Check if it's a P0 situation (requires human intervention)
3. If P0: trigger notification and wait
4. If not P0: try alternative approaches, document attempts

### If Hypothesis Falsified

1. Stop current work
2. Document findings in ADR
3. Assess impact on subsequent Stages
4. Trigger P0 notification
5. Wait for human decision

### If Consecutive Failures (3+)

1. Stop and document all attempts
2. Trigger P0 notification
3. Wait for human intervention

---

> **Remember**: Your role is to execute Stages according to the Roadmap. When in doubt, refer to `AGENTS.md` for detailed rules, and `docs/11-next-steps.md` for current status.
