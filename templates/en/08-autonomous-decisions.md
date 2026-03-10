# Autonomous Decisions Record (ADR)

> This document records architecture decisions and technology choices in RDD projects, ensuring the decision process is traceable and understandable.

---

## ADR Format Description

### What is an ADR

ADR (Architecture Decision Record) is a lightweight document format for recording architecture decisions. Each decision record contains:

- Background and context of the decision
- The decision content made
- The reason for making this decision
- The impact on subsequent Stages

### ADR Format Template

```markdown
### Decision N: [Decision Title]

**Background**: What triggered this decision

**Decision**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (Cannot be empty)
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| Decision Number | Yes | Format: Decision 1, Decision 2, etc. |
| Decision Title | Yes | Concise summary of decision content |
| Background | Yes | Describe the context that triggered this decision |
| Decision | Yes | Clearly describe the decision made |
| Reason | Yes | Explain why this decision was made |
| Impact on Subsequent Stages | Yes | Must be filled, describe impact on subsequent work |

### When to Record an ADR

Record an ADR in these situations:

1. **Architecture Decision**: Major decisions affecting system architecture
2. **Technology Selection**: Choosing tech stack, frameworks, libraries, etc.
3. **Design Trade-offs**: Making trade-offs between multiple options
4. **Hypothesis Changes**: Core hypotheses verified or falsified
5. **Non-goal Declaration**: Explicitly deciding not to do something
6. **Tech Debt Decision**: Decisions to accept tech debt

### ADR Writing Guidelines

```
DO:
- Record each decision independently
- Clear background description for new team members
- Explicit decision content, no ambiguity
- Sufficient reason with evidence
- Specific impact pointing to clear Stages

DON'T:
- Leave "impact on subsequent Stages" empty
- Record trivial daily decisions
- Ambiguous decision content
- Not record reason or impact
```

---

## ADR Index

<!-- Add new ADR index entries here -->

| ID | Title | Date | Related Stage | Status |
|----|-------|------|---------------|--------|
| Decision 1 | [Example Decision Title] | [Date] | [Stage N] | [Active/Deprecated] |

---

## ADR Details

<!-- Add new ADR records here -->

### Decision 1: [Example Decision Title]

**Background**: What triggered this decision

**Decision**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (Cannot be empty, must describe impact on subsequent work)

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Key Reminder**: The "impact on subsequent Stages" field cannot be empty. This is a mandatory requirement in RDD.
