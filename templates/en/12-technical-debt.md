# Technical Debt Ledger

> This document records all technical debt in the RDD project, ensuring tech debt is visible, traceable, and manageable.

---

## Debt Management Principles

### What is Technical Debt

Technical debt is conscious compromises made during project development for faster delivery, which will require extra work to fix in the future.

**Characteristics of Technical Debt**:

- Conscious choice (not errors)
- Explicitly recorded
- Clear repayment plan
- Will affect future development efficiency or system quality

### Tech Debt vs Bug vs Todo

| Type | Characteristics | Handling |
|------|----------------|----------|
| Tech Debt | Conscious compromise, needs future extra work | Record in tech debt ledger |
| Bug | Unintended error, needs immediate fix | Create Issue or fix immediately |
| Todo | Planned feature improvements | Record in Roadmap or Backlog |

### Core Tech Debt Management Principles

```
1. Visibility Principle
   - All known tech debt must be explicitly recorded in ledger
   - Don't manage tech debt as implicit knowledge
   - Regularly review tech debt status

2. Classification Principle
   - Classify by priority
   - Classify by impact scope
   - Classify by source

3. Planning Principle
   - Each tech debt has suggested landing Stage
   - Blocking tech debt handled first
   - Regularly evaluate tech debt priority

4. Recording Principle
   - Record source and original description
   - Record impact on subsequent Stages
   - Record verification results after repayment
```

### Four Tech Debt Rules

1. **Must Record**: Discover tech debt must be recorded immediately, no delay
2. **Must Classify**: Classify by priority and impact scope
3. **Must Plan**: Specify suggested landing Stage or dedicated handling
4. **Must Verify**: Verify after repayment that it actually solved the problem

---

## Discovery Channels

### Four Major Discovery Channels

| Channel | Source | Discovery Timing | Recording Requirement |
|---------|--------|-----------------|----------------------|
| A. Stage Docs | "Non-goals" and "Known limitations" sections | Stage planning | Active recording |
| B. Review Log | "Deferred/Rejected" section | Review completion | Extract from review-log |
| C. ADR | "Impact on subsequent Stages" field | When decisions occur | Extract actionable items |
| D. Code Scan | TODO/FIXME/HACK/XXX comments | Stage completion | Auto scan |

### Channel A: Stage Document Extraction

Extract tech debt from these Stage document sections:

**Non-goals Section**:

```markdown
## Non-goals
- Third-party login (defer to Stage 4)
- Multi-factor authentication (defer to future version)

→ Extract as tech debt:
TD-XX: Third-party login feature pending
TD-XX: Multi-factor authentication pending
```

**Known Limitations Section**:

```markdown
## Known Limitations
- Currently only supports single-node deployment, not distributed
- Simple cache expiration policy, only supports TTL

→ Extract as tech debt:
TD-XX: Distributed deployment support
TD-XX: Cache expiration policy optimization
```

### Channel B: Review Log Extraction

Extract from review log's "Deferred/Rejected" section:

```markdown
## Findings Details

### Finding 3: Suggest adding error retry mechanism
- **Verification Result**: Deferred
- **Reason**: Not in current Stage scope, record as tech debt
- **Suggested Stage**: Stage 4

→ Extract as tech debt:
TD-XX: Error retry mechanism
```

### Channel C: ADR Extraction

Extract from ADR's "Impact on subsequent Stages" field:

```markdown
### Decision 2: Use simple TTL expiration policy

**Impact on Subsequent Stages**:
- Current policy is simple, may result in low cache hit rate
- Need to implement smarter expiration policy (e.g., LRU) later
- Impacts Stage 5 cache optimization

→ Extract as tech debt:
TD-XX: Smart cache expiration policy
```

### Channel D: Code Scan

Scan for comment markers in code:

| Marker | Meaning | Handling |
|--------|---------|----------|
| TODO | Features to implement | Evaluate if should record as tech debt |
| FIXME | Known issue to fix | Must record as tech debt |
| HACK | Temporary solution | Must record as tech debt |
| XXX | Dangerous or problematic code | Must record as tech debt |

**Scan Command Example**:

```bash
# Scan all TODO/FIXME/HACK/XXX
grep -rn "TODO\|FIXME\|HACK\|XXX" src/

# Generate report
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ > tech-debt-scan.txt
```

---

## Priority Sorting

### Two-Axis Priority Model

Tech debt is classified by two dimensions:

**Axis One: Impact Domain**

| Impact Domain | Description | Example |
|--------------|-------------|---------|
| Architecture | Affects overall architecture or multiple modules | Database migration, protocol change |
| Module | Affects single module | Module refactoring, interface optimization |
| Local | Affects single file or function | Code optimization, comment supplement |

**Axis Two: Blocking**

| Blocking | Description | Impact |
|----------|-------------|--------|
| Blocks Subsequent Stage | Blocks subsequent development work | Must handle immediately |
| Feature Degradation | Affects feature completeness or quality | Should handle ASAP |
| Tech Optimization | Pure tech improvement, no feature impact | Can defer |

### Sorting Rules

```
Priority sorting (high to low):

1. Blocks Subsequent Stage → Must resolve before next Stage
   - Any impact domain, as long as it blocks subsequent Stage
   - Must schedule in nearest Stage

2. Feature Degradation + Architecture → Dedicated iteration handling
   - Large impact scope, needs dedicated planning
   - Schedule dedicated Stage or iteration

3. Feature Degradation + Module/Local → Handle in related Stage
   - Handle in Stage related to the feature
   - Don't schedule separate Stage

4. Pure Tech Optimization → Bench-driven
   - Handle when there's clear performance need
   - Or schedule in tech debt cleanup iteration
```

### Threshold Triggers

When tech debt accumulation reaches threshold, trigger dedicated handling:

| Threshold | Trigger Action |
|-----------|---------------|
| "Feature Degradation + Architecture" exceeds 3 items | Schedule dedicated iteration |
| "Blocks Subsequent Stage" exceeds 1 item | Handle immediately, pause other development |
| Total tech debt exceeds 10 items | Conduct tech debt cleanup iteration |

---

## Ledger Format

### Tech Debt Record Format

```markdown
### TD-NN: Short Title

- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architecture/Module/Local]
- **Source**: [Prototype Compromise / Review Deferred / Self-decided Compromise] (Stage Number)
- **Original Description**: (Quote original document text)
- **Source File**: (File path and line number)
- **Discovery Date**: [Date]
- **Suggested Stage**: (Stage N or "Dedicated" or "As Needed")
- **Current Status**: [ ] Pending / [ ] In Progress / [x] Resolved / [x] N/A
- **Resolution Date**: [Date]
- **Resolution**: [Brief description of resolution]
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| Number | Yes | Format: TD-01, TD-02, etc. |
| Title | Yes | Concise summary of tech debt content |
| Priority | Yes | Fill in "Blocking / Impact Domain" format |
| Source | Yes | Indicate source type and related Stage |
| Original Description | Yes | Quote original text for traceability |
| Source File | Yes | File path and line number (if any) |
| Discovery Date | Yes | Record discovery time |
| Suggested Stage | Yes | Specify planned handling Stage |
| Current Status | Yes | Update handling status |
| Resolution Date | No | Fill in after resolution |
| Resolution | No | Brief description after resolution |

---

## Tech Debt Index

<!-- Add new tech debt records here -->

### Pending Tech Debt

| ID | Title | Priority | Suggested Stage | Status |
|----|-------|----------|-----------------|--------|
| (None) | - | - | - | - |

### In Progress Tech Debt

| ID | Title | Priority | Current Stage | Status |
|----|-------|----------|---------------|--------|
| - | - | - | - | - |

### Resolved Tech Debt

| ID | Title | Priority | Resolution Date | Resolution |
|----|-------|----------|----------------|------------|
| - | - | - | - | - |

---

## Tech Debt Details

<!-- Add tech debt details here -->

### TD-01: [Example Tech Debt Title]

- **Priority**: Feature Degradation / Module-level
- **Source**: Review Deferred (Stage 2)
- **Original Description**: "Suggest adding error retry mechanism, but not in current Stage scope"
- **Source File**: src/client.rs:45
- **Discovery Date**: [Date]
- **Suggested Stage**: Stage 4
- **Current Status**: [ ] Pending
- **Resolution Date**: -
- **Resolution**: -

**Impact Assessment**:

- Current Impact: Error retry needs manual handling
- Potential Risk: May fail when network unstable
- Impact on Subsequent Stages: Stage 4 error handling needs to consider

---

## Tech Debt Statistics

### By Priority

| Priority | Count | Percentage |
|----------|-------|------------|
| Blocks Subsequent Stage | 0 | 0% |
| Feature Degradation + Architecture | 0 | 0% |
| Feature Degradation + Module | 0 | 0% |
| Feature Degradation + Local | 0 | 0% |
| Tech Optimization + Architecture | 0 | 0% |
| Tech Optimization + Module | 0 | 0% |
| Tech Optimization + Local | 0 | 0% |
| **Total** | **0** | **100%** |

### By Source

| Source | Count | Percentage |
|--------|-------|------------|
| Stage Docs (Non-goals/Known Limitations) | 0 | 0% |
| Review Log (Deferred/Rejected) | 0 | 0% |
| ADR (Impact on Subsequent) | 0 | 0% |
| Code Scan (TODO/FIXME/HACK/XXX) | 0 | 0% |
| **Total** | **0** | **100%** |

### By Status

| Status | Count | Percentage |
|--------|-------|------------|
| Pending | 0 | 0% |
| In Progress | 0 | 0% |
| Resolved | 0 | 0% |
| N/A | 0 | 0% |
| **Total** | **0** | **100%** |

### By Stage Distribution

| Stage | Pending | Resolved | Total |
|-------|---------|----------|-------|
| Stage 1 | 0 | 0 | 0 |
| Stage 2 | 0 | 0 | 0 |
| Stage 3+ | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** |

---

## Periodic Review

### Review Frequency

- Each Stage completion: Review tech debt status
- Weekly: Review priority and plans
- Monthly: Comprehensive tech debt ledger review

### Review Content

| Review Item | Description |
|-------------|-------------|
| Status Update | Confirm tech debt status is correct |
| Priority Adjustment | Adjust priority based on latest situation |
| Plan Adjustment | Adjust suggested landing Stage |
| New Identification | Identify new tech debt |
| Resolved Verification | Verify resolved tech debt actually solved the problem |

### Review Records

| Review Date | Reviewer | Review Result | Action Items |
|------------|----------|---------------|--------------|
| [Date] | [Name] | [Result] | [Action Items] |

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Key Reminder**: Tech debt must be explicitly recorded, not managed as implicit knowledge. "Managing tech debt as implicit knowledge" is one of RDD's forbidden behaviors.
