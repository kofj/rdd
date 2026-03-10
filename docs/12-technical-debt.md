# Technical Debt Ledger

> This document records all technical debts in the RDD project, ensuring technical debt is visible, traceable, and manageable.

---

## Debt Management Principles

### What is Technical Debt

Technical debt is conscious compromises made during project development to enable rapid delivery, which require additional work to fix in the future.

**Characteristics of Technical Debt**:

- Conscious choice (not mistakes)
- Clearly recorded
- Has a clear repayment plan
- Affects future development efficiency or system quality

### Technical Debt vs Bug vs Todo

| Type | Characteristics | Handling |
|------|-----------------|----------|
| Technical Debt | Conscious compromise, requires future extra work | Record in debt ledger |
| Bug | Unexpected error, requires immediate fix | Create Issue or fix immediately |
| Todo | Planned feature improvements | Record in Roadmap or Backlog |

### Core Principles of Debt Management

```
1. Visibility Principle
   - All known technical debt must be explicitly recorded in the ledger
   - Do not manage technical debt as tacit knowledge
   - Regularly review technical debt status

2. Classification Principle
   - Classify by priority
   - Classify by impact scope
   - Classify by source

3. Planning Principle
   - Each technical debt has a suggested landing Stage
   - Blocking technical debt is prioritized
   - Regularly evaluate technical debt priority

4. Recording Principle
   - Record source and original description
   - Record impact on subsequent Stages
   - Record verification results after repayment
```

### Technical Debt Four Rules

1. **Must Record**: Technical debt discovered must be recorded immediately, not delayed
2. **Must Classify**: Classify by priority and impact scope
3. **Must Plan**: Specify suggested landing Stage or dedicated handling
4. **Must Verify**: Verify after repayment that the problem is actually resolved

---

## Discovery Channels

### Four Discovery Channels

| Channel | Source | Discovery Timing | Recording Requirement |
|---------|--------|------------------|------------------------|
| A. Stage Document | "Non-goals" and "Known Limitations" sections | During Stage planning | Proactive recording |
| B. Review Log | "Deferred/Rejected" area | After Review completion | Extract from review-log |
| C. ADR | "Impact on Subsequent Stages" field | When decision occurs | Extract actionable items |
| D. Code Scan | TODO/FIXME/HACK/XXX comments | At Stage completion | Automatic scan |

### Channel A: Stage Document Extraction

Extract technical debt from the following sections of Stage documents:

**Non-goals Section**:

```markdown
## Non-goals
- Third-party login (deferred to Stage 4)
- Multi-factor authentication (deferred to future version)

→ Extract as technical debt:
TD-XX: Third-party login feature to be implemented
TD-XX: Multi-factor authentication feature to be implemented
```

**Known Limitations Section**:

```markdown
## Known Limitations
- Currently only supports standalone deployment, not distributed
- Simple cache expiration strategy, only supports TTL

→ Extract as technical debt:
TD-XX: Distributed deployment support
TD-XX: Cache expiration strategy optimization
```

### Channel B: Review Log Extraction

Extract from Review log's "Deferred/Rejected" area:

```markdown
## Findings Details

### Finding 3: Suggest adding error retry mechanism
- **Verification Result**: Deferred
- **Reason**: Current Stage scope doesn't include, recorded as technical debt
- **Suggested Landing Stage**: Stage 4

→ Extract as technical debt:
TD-XX: Error retry mechanism
```

### Channel C: ADR Extraction

Extract from ADR's "Impact on Subsequent Stages" field:

```markdown
### Decision 2: Use simple TTL expiration strategy

**Impact on Subsequent Stages**:
- Current strategy is simple, may lead to low cache hit rate
- Need to implement smarter expiration strategy later (like LRU)
- Affects Stage 5 cache optimization

→ Extract as technical debt:
TD-XX: Intelligent cache expiration strategy
```

### Channel D: Code Scan

Scan comment markers in code:

| Marker | Meaning | Handling |
|--------|---------|----------|
| TODO | Feature to be implemented | Evaluate if should be recorded as tech debt |
| FIXME | Known issue needing fix | Must record as tech debt |
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

Technical debt is classified along two dimensions:

**Axis One: Impact Domain**

| Impact Domain | Description | Example |
|---------------|-------------|---------|
| Architecture-level | Affects overall architecture or multiple modules | Database migration, protocol changes |
| Module-level | Affects a single module | Module refactoring, interface optimization |
| Local | Affects a single file or function | Code optimization, comment addition |

**Axis Two: Blocking Nature**

| Blocking Nature | Description | Impact |
|-----------------|-------------|--------|
| Blocks Subsequent Stage | Blocks subsequent development work | Must handle immediately |
| Feature Degradation | Affects feature completeness or quality | Should handle as soon as possible |
| Tech Optimization | Pure technical improvement, doesn't affect features | Can defer handling |

### Sorting Rules

```
Priority Sorting (from high to low):

1. Blocks Subsequent Stage → Must resolve before next Stage
   - Any impact domain, as long as it blocks subsequent Stage
   - Must be scheduled for the nearest Stage

2. Feature Degradation + Architecture-level → Dedicated iteration handling
   - Large impact scope, needs dedicated planning
   - Schedule dedicated Stage or iteration

3. Feature Degradation + Module-level/Local → Handle in relevant Stage
   - Handle in Stage related to the feature
   - No separate Stage needed

4. Pure Tech Optimization → Driven by benchmarks
   - Handle when there are clear performance requirements
   - Or schedule in tech debt cleanup iteration
```

### Threshold Triggers

When technical debt accumulation reaches threshold, trigger dedicated handling:

| Threshold | Trigger Action |
|-----------|----------------|
| "Feature Degradation + Architecture-level" backlog exceeds 3 items | Schedule dedicated iteration handling |
| "Blocks Subsequent Stage" exceeds 1 item | Handle immediately, pause other development |
| Total tech debt exceeds 10 items | Conduct tech debt cleanup iteration |

---

## Ledger Format

### Technical Debt Record Format

```markdown
### TD-NN: Short Title

- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architecture-level/Module-level/Local]
- **Source**: [Prototype active compromise / Review deferred / Autonomous decision compromise] (Stage Number)
- **Original Description**: (Quote original document statement)
- **Source File**: (File path and line number)
- **Discovery Date**: [Date]
- **Suggested Landing Stage**: (Stage N or "Dedicated" or "As Needed")
- **Current Status**: [ ] Pending / [ ] In Progress / [x] Resolved / [x] Not Applicable
- **Resolution Date**: [Date]
- **Resolution**: [Brief description of resolution]
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| Number | Yes | Format: TD-01, TD-02, etc. |
| Title | Yes | Concise summary of technical debt content |
| Priority | Yes | Fill in "Blocking Nature / Impact Domain" format |
| Source | Yes | Identify source type and related Stage |
| Original Description | Yes | Quote original statement, maintain traceability |
| Source File | Yes | File path and line number (if applicable) |
| Discovery Date | Yes | Record discovery time |
| Suggested Landing Stage | Yes | Specify planned handling Stage |
| Current Status | Yes | Update handling status |
| Resolution Date | No | Fill in after resolution |
| Resolution | No | Brief description after resolution |

---

## Technical Debt Index

<!-- Add new technical debt records here -->

### Pending Technical Debt

| Number | Title | Priority | Suggested Stage | Status |
|--------|-------|----------|-----------------|--------|
| (None) | - | - | - | - |

### In Progress Technical Debt

| Number | Title | Priority | Current Stage | Status |
|--------|-------|----------|---------------|--------|
| - | - | - | - | - |

### Resolved Technical Debt

| Number | Title | Priority | Resolution Date | Resolution |
|--------|-------|----------|-----------------|------------|
| TD-01 | Hook scripts not correctly sourcing notify.sh | Blocking / Module-level | 2026-03-07 | Added source statement to all Hook scripts |
| TD-02 | No Hook trigger mechanism | Blocking / Module-level | 2026-03-07 | Created rdd-hooks skill to define trigger rules |
| TD-03 | Scripts may lack execute permission | Blocking / Local | 2026-03-07 | chmod +x all .sh files |
| TD-04 | Hardcoded paths | Feature Degradation / Module-level | 2026-03-07 | Use RDD_DIR environment variable and relative paths |
| TD-05 | Unit test coverage at 0% | Blocking / Module-level | 2026-03-07 | Implemented bats-core testing framework, 500+ test cases |
| TD-06 | No E2E tests | Blocking / Module-level | 2026-03-07 | Created tests/e2e/ directory, 21 E2E tests |
| TD-07 | No BDD tests | Feature Degradation / Module-level | 2026-03-07 | Created tests/bdd/ directory, 10+ BDD tests |
| TD-08 | No automatic context recovery | Feature Degradation / Architecture-level | 2026-03-08 | Implemented checkpoint.sh and handoff.sh scripts |
| TD-09 | Credentials stored in plaintext | Blocking / Module-level | 2026-03-07 | Added expand_env_vars function supporting ${VAR} |
| TD-10 | No state persistence | Feature Degradation / Architecture-level | 2026-03-08 | Implemented checkpoint.sh state persistence |
| TD-11 | Taskfile YAML parsing issue | Feature Degradation / Local | 2026-03-08 | Fixed YAML syntax issues |

---

---

## Technical Debt Details

---

### TD-05: Unit Test Coverage at 0% ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Feature logic untested"
- **Source File**: .rdd/scripts/notify.sh, .rdd/hooks/*.sh
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 2
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Implemented bats-core testing framework, created 500+ test cases, coverage >= 95%

**Impact Assessment**:
- After resolution: All core scripts have complete unit test coverage
- Verification: task test:unit passes 500+ tests

---

### TD-06: No E2E Tests ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "No end-to-end tests"
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 2
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Created tests/e2e/ directory, implemented 21 E2E test scenarios

**Impact Assessment**:
- After resolution: Complete workflows can be automatically verified
- Verification: task test:e2e passes 21 E2E tests

---

### TD-07: No BDD Tests ✅ Resolved

- **Priority**: Feature Degradation / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "No behavior-driven tests"
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 2
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Created tests/bdd/ directory, implemented 10+ BDD test scenarios

**Impact Assessment**:
- After resolution: User behavior expectations can be automatically verified
- Verification: task test:bdd passes all BDD tests

---

### TD-08: No Automatic Context Recovery ✅ Resolved

- **Priority**: Feature Degradation / Architecture-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Cannot automatically recover work state after Compact"
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 3
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-08
- **Resolution**: Implemented checkpoint.sh and handoff.sh scripts, supporting automatic state persistence and recovery

**Impact Assessment**:
- After resolution: Agent can automatically recover context after Compact
- Verification: E2E tests verify recovery process

---

### TD-10: No State Persistence ✅ Resolved

- **Priority**: Feature Degradation / Architecture-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Work progress cannot be persistently saved"
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 3
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-08
- **Resolution**: Implemented checkpoint.sh state persistence, supporting Gate state save and restore

**Impact Assessment**:
- After resolution: Work progress can be persistently saved
- Verification: task checkpoint:save/show commands available

---

### TD-01: Hook Scripts Not Correctly Sourcing notify.sh ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Hook scripts call undefined functions"
- **Source File**: .rdd/hooks/*.sh
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 1
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: All Hook scripts added `source "${SCRIPTS_DIR}/notify.sh"`

**Impact Assessment**:
- After resolution: Hook scripts can correctly call notify.sh functions
- Verification: Manual testing confirms all Hook scripts execute normally

---

### TD-02: No Hook Trigger Mechanism ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Hooks scripts exist but no way to trigger them"
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 1
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Created rdd-hooks skill defining trigger rules

**Impact Assessment**:
- After resolution: Skills can trigger Hooks via environment variables
- Verification: rdd-hooks skill documentation fully defines trigger timing

---

### TD-03: Scripts May Lack Execute Permission ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Local
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Scripts may not have execute permission"
- **Source File**: .rdd/scripts/*.sh, .rdd/hooks/*.sh
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 1
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: chmod +x all .sh files

**Impact Assessment**:
- After resolution: All scripts are executable
- Verification: ls -la shows all .sh have x permission

---

### TD-04: Hardcoded Paths ✅ Resolved

- **Priority**: Feature Degradation / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Paths hardcoded to `/data/works/play/sbd/`"
- **Source File**: Multiple files
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 1
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Use RDD_DIR environment variable and relative paths

**Impact Assessment**:
- After resolution: Framework can run in any project directory
- Verification: notify.sh uses `RDD_DIR="${RDD_DIR:-$(dirname "$0")/..}"`

---

### TD-09: Credentials Stored in Plaintext ✅ Resolved

- **Priority**: Blocks Subsequent Stage / Module-level
- **Source**: Stage 0 Known Limitations (Stage 0)
- **Original Description**: "Sensitive information in hooks.yml stored in plaintext"
- **Source File**: .rdd/hooks.yml
- **Discovery Date**: 2026-03-06
- **Suggested Landing Stage**: Stage 1
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-07
- **Resolution**: Added expand_env_vars function supporting ${VAR} environment variable references

**Impact Assessment**:
- After resolution: Configuration files can use environment variables like ${WECOM_WEBHOOK_URL}
- Verification: expand_env_vars function tests pass

---

### TD-11: Taskfile YAML Parsing Issue ✅ Resolved

- **Priority**: Feature Degradation / Local
- **Source**: Code Scan (Stage 2)
- **Original Description**: "Taskfile.yml cannot be parsed in some task versions, echo commands with colons cause YAML parsing errors"
- **Source File**: Taskfile.yml
- **Discovery Date**: 2026-03-07
- **Suggested Landing Stage**: Stage 2
- **Current Status**: [x] Resolved
- **Resolution Date**: 2026-03-08
- **Resolution**: Fixed YAML syntax, using correct multi-line string format

**Impact Assessment**:
- After resolution: All task commands work normally
- Verification: task --list shows all tasks

---

### TD-01: [Example Technical Debt Title]

- **Priority**: Feature Degradation / Module-level
- **Source**: Review Deferred (Stage 2)
- **Original Description**: "Suggest adding error retry mechanism, but current Stage scope doesn't include"
- **Source File**: src/client.rs:45
- **Discovery Date**: [Date]
- **Suggested Landing Stage**: Stage 4
- **Current Status**: [ ] Pending
- **Resolution Date**: -
- **Resolution**: -

**Impact Assessment**:

- Current Impact: Error retry needs manual handling
- Potential Risk: May fail when network is unstable
- Impact on Subsequent Stages: Stage 4 error handling needs consideration

---

### TD-02: [Example Technical Debt Title]

- **Priority**: Tech Optimization / Local
- **Source**: Code Scan (Stage 3)
- **Original Description**: "TODO: Optimize time complexity of this algorithm"
- **Source File**: src/utils.rs:120
- **Discovery Date**: [Date]
- **Suggested Landing Stage**: As Needed
- **Current Status**: [ ] Pending
- **Resolution Date**: -
- **Resolution**: -

**Impact Assessment**:

- Current Impact: Performance acceptable for small data volumes
- Potential Risk: May slow down for large data volumes
- Impact on Subsequent Stages: No direct impact, can optimize as needed

---

## Technical Debt Statistics

### By Priority

| Priority | Count | Percentage |
|----------|-------|------------|
| Blocks Subsequent Stage | 0 | 0% |
| Feature Degradation + Architecture-level | 0 | 0% |
| Feature Degradation + Module-level | 0 | 0% |
| Feature Degradation + Local | 0 | 0% |
| Tech Optimization + Architecture-level | 0 | 0% |
| Tech Optimization + Module-level | 0 | 0% |
| Tech Optimization + Local | 0 | 0% |
| **Resolved** | **11** | **100%** |
| **Total** | **11** | **100%** |

### By Source

| Source | Count | Percentage |
|--------|-------|------------|
| Stage Document (Non-goals/Known Limitations) | 10 | 90.9% |
| Review Log (Deferred/Rejected) | 0 | 0% |
| ADR (Impact on Subsequent) | 0 | 0% |
| Code Scan (TODO/FIXME/HACK/XXX) | 1 | 9.1% |
| **Total** | **11** | **100%** |

### By Status

| Status | Count | Percentage |
|--------|-------|------------|
| Pending | 0 | 0% |
| In Progress | 0 | 0% |
| Resolved | 11 | 100% |
| Not Applicable | 0 | 0% |
| **Total** | **11** | **100%** |

### By Stage Distribution

| Stage | Pending | Resolved | Total |
|-------|---------|----------|-------|
| Stage 0 | 0 | 0 | 0 |
| Stage 1 | 0 | 5 | 5 |
| Stage 2 | 0 | 4 | 4 |
| Stage 3 | 0 | 2 | 2 |
| Stage 4+ | 0 | 0 | 0 |
| **Total** | **0** | **11** | **11** |

---

## Regular Review

### Review Frequency

- At each Stage completion: Review technical debt status
- Weekly: Review priority and plans
- Monthly: Comprehensive review of technical debt ledger

### Review Content

| Review Item | Description |
|-------------|-------------|
| Status Update | Confirm if technical debt status is correct |
| Priority Adjustment | Adjust priority based on latest situation |
| Plan Adjustment | Adjust suggested landing Stage |
| New Identification | Identify new technical debt |
| Resolved Verification | Verify resolved technical debt actually resolved the problem |

### Review Records

| Review Date | Reviewer | Review Result | Action Items |
|-------------|----------|---------------|--------------|
| [Date] | [Name] | [Result] | [Action Items] |

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Key Reminder**: Technical debt must be explicitly recorded, not managed as tacit knowledge. "Managing technical debt as tacit knowledge" is one of the prohibited behaviors in RDD.
