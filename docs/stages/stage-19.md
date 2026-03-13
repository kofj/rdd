# Stage 19: Command Hint System

## Status

[ ] Planning / [ ] In Progress / [ ] Complete

---

## Goals

Add descriptive placeholder hints to all RDD commands to improve discoverability and user understanding. When users type commands in Claude Code, they should see helpful hints explaining the command's purpose and usage.

---

## Non-Goals

- GUI or web interface for command hints
- Auto-completion system (future consideration)
- Command validation or error messages (existing functionality)

---

## Core Hypotheses

- **Hypothesis A**: Adding descriptive hints reduces the time users spend reading documentation
- **Hypothesis B**: Clear command hints increase successful first-time command usage by 50%+

---

## Acceptance Criteria

- [ ] All RDD commands have `description` field with clear purpose
- [ ] Hints include usage examples where applicable
- [ ] Multi-line hints supported for complex commands
- [ ] E2E tests verify hint content display
- [ ] Documentation updated with hint examples
- [ ] Coverage >= 95%

---

## Rollback Plan

If hints cause issues:
1. Remove `description` fields from command definitions
2. Revert to basic command format
3. No data migration needed

---

## Known Limitations

- Claude Code's hint display depends on its implementation
- Hints are static text, not dynamic based on project state

---

## Impact on Subsequent Stages

- **Stage 20**: State-aware hints will build on this foundation
- **Stage 22**: Progress hints will use same description format

---

## Implementation Notes

### Task 1: Define Command Description Format

Update command definition format to include:

```markdown
---
description: "One-line description of command purpose"
examples:
  - "/command arg1"
  - "/command --option value"
---

# Command Title

Detailed command documentation...
```

### Task 2: Update All Existing Commands

Commands to update:
1. `/rdd-init` - Project initialization
2. `/rdd-migrate` - Project migration
3. `/rdd-roadmap` - Roadmap management
4. `/rdd-stage-auto` - Stage execution
5. `/rdd-loop` - Loop control
6. `/rdd-knowledge` - ADR/debt management

### Task 3: Write E2E Tests

Test cases:
- Verify each command has description
- Verify description is non-empty
- Verify examples are valid command syntax

### Task 4: Update Documentation

- Update CLAUDE.md with hint examples
- Update AGENTS.md with new command format
- Update README.md if needed

---

## Technical Design

### Command File Structure

```
.claude/commands/
├── rdd-init.md        # description + examples
├── rdd-migrate.md     # description + examples
├── rdd-roadmap.md     # description + examples
├── rdd-stage-auto.md  # description + examples
├── rdd-loop.md        # description + examples
└── rdd-knowledge.md   # description + examples
```

### Description Guidelines

1. **One-line summary**: Clear, concise purpose statement
2. **Action verb start**: Use "Initialize", "Execute", "Manage", etc.
3. **Include key benefit**: Why use this command?
4. **Examples**: Show common usage patterns

### Example Descriptions

| Command | Description |
|---------|-------------|
| rdd-init | "Initialize RDD framework in a new or existing project with TDD/BDD configuration" |
| rdd-migrate | "Migrate an existing project to RDD framework structure" |
| rdd-roadmap | "View and manage project roadmap stages" |
| rdd-stage-auto | "Execute a complete RDD stage autonomously with gate verification" |
| rdd-loop | "Control autonomous stage execution loop for multi-stage progression" |
| rdd-knowledge | "Record ADRs and manage technical debt ledger" |

---

## Test Plan

### Unit Tests

```bash
# Test: Command description parser
tests/unit/commands/test_description_parser.bats

# Test: Description validation
tests/unit/commands/test_description_validation.bats
```

### E2E Tests

```bash
# Test: All commands have descriptions
tests/e2e/test_command_hints.bats
```

---

## Dependencies

- None (can start immediately)

---

## Estimated Effort

Small (1 day)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-13 | Initial design |
