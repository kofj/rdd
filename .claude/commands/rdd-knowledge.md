---
description: "Manage knowledge artifacts - record ADRs, track technical debt, generate handoff documents"
examples:
  - "/rdd-knowledge adr --title \"Decision\" --stage 3"
  - "/rdd-knowledge debt --title \"Issue\" --priority high"
  - "/rdd-knowledge handoff --reason \"Session ending\""
  - "/rdd-knowledge check                  # Verify docs complete"
---

# RDD Knowledge Command

Manage knowledge artifacts - ADRs, technical debt, and handoff documents.

## Usage

```
/rdd-knowledge [subcommand] [options]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `adr` | Record a new ADR |
| `debt` | Record new technical debt |
| `handoff` | Generate handoff document |
| `check` | Run fresh-agent-check |
| `context` | Load full context |

## ADR Subcommand

Record an Autonomous Decision Record:

```
/rdd-knowledge adr --title "Decision Title" --stage 3
```

Options:
- `--title`: Decision title (required)
- `--stage`: Related stage number
- `--background`: Background context
- `--decision`: The decision made
- `--rationale`: Why this decision
- `--impact`: Impact on subsequent stages (REQUIRED)
- `--alternatives`: Alternatives considered

### ADR Template

```markdown
### Decision N: [Title]

**Background**: [What circumstances led to this decision]
**Decision**: [What path was chosen]
**Rationale**: [Why this path was selected]
**Impact on Subsequent Stages**: (Cannot be empty)
- [Specific impact on future work]
**Date**: YYYY-MM-DD
**Related Stage**: Stage N
**Alternatives Considered**:
1. [Alternative 1]: [Why not chosen]
```

## Debt Subcommand

Record technical debt:

```
/rdd-knowledge debt --title "Short Title" --priority high
```

Options:
- `--title`: Debt title (required)
- `--priority`: Blocking / Degraded / Optimization
- `--level`: Architecture / Module / Local
- `--source`: Prototype / Review / Decision
- `--stage`: Source stage number
- `--description`: Original description
- `--file`: Source file path
- `--resolution-stage`: Target resolution stage

### Debt Template

```markdown
### TD-NN: [Title]

- **Priority**: [Priority] / [Level]
- **Source**: [Source] (Stage N)
- **Original Description**: [Quote]
- **Source File**: [Path:line]
- **Suggested Resolution Stage**: [Stage N]
- **Impact**: [What this affects]
- **Resolution Cost Estimate**: Low/Medium/High
- **Created Date**: YYYY-MM-DD
```

## Handoff Subcommand

Generate handoff document for session transition:

```
/rdd-knowledge handoff [--reason "Reason for handoff"]
```

Options:
- `--reason`: Why handoff is happening
- `--archive`: Archive previous handoff with timestamp

The handoff document includes:
- Current progress and gate
- Completed evidence
- Blockers and risks
- Next single action
- Degradation strategy
- Context for new agent

### Handoff Location

```
docs/handoff/handoff-latest.md  # Current handoff
docs/handoff/handoff-YYYY-MM-DD-HHMM.md  # Archives
```

## Check Subcommand

Run fresh-agent-check to verify documentation completeness:

```
/rdd-knowledge check
```

Verifies:
- [ ] A new agent can understand project purpose
- [ ] Current stage is clear
- [ ] Next actions are clear
- [ ] Past decisions are documented
- [ ] Technical debt is visible
- [ ] No tacit knowledge required

## Context Subcommand

Load full project context:

```
/rdd-knowledge context
```

Reads in order:
1. `docs/stages/stage-roadmap.md` - Project overview
2. `docs/handoff/handoff-latest.md` - Recent context
3. `docs/stages/stage-N.md` - Current stage
4. `docs/08-autonomous-decisions.md` - Key decisions
5. `docs/12-technical-debt.md` - Known issues
6. `docs/11-next-steps.md` - Immediate actions

## Examples

```
/rdd-knowledge adr --title "Use SQLite for caching" --stage 2
/rdd-knowledge debt --title "Single-threaded cache" --priority high --stage 2
/rdd-knowledge handoff --reason "Session ending"
/rdd-knowledge check
/rdd-knowledge context
```

## Integration with Other Commands

- After `/rdd-stage-auto` completes: Use `adr` to record decisions
- When creating workarounds: Use `debt` to track them
- Before ending session: Use `handoff` to document state
- Before stage completion: Use `check` to verify docs

## See Also

- `rdd-knowledge` skill in `.claude/skills/rdd-knowledge.md`
- `rdd-core` skill for knowledge management principles
