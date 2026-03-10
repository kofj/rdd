# Review Practices Guide

> This document defines the timing, methodology, and best practices for Reviews in RDD projects.

---

## Review Timing

### Two Review Types

| Type | Timing | Purpose | Output |
|------|--------|---------|--------|
| Design Review | Before coding | Validate design rationality | Optimized design document |
| Code Review | After E2E passes | Validate implementation quality | Review log |

### Design Review (Before Coding)

**Trigger Conditions**:

- Stage design document completed
- Before implementation begins

**Review Purpose**:

1. Validate if design meets requirements
2. Discover potential design issues
3. Ensure non-goal boundaries are clear
4. Validate assumption rationality

**Review Flow**:

```
1. Trigger multi-model Review
2. First round open, no dimensions/hints provided
3. AI initial screening of findings
4. Rule filtering
5. Independently verify each finding
6. Update design document
7. Record Review log
```

### Code Review (After E2E Passes)

**Trigger Conditions**:

- E2E tests pass
- Before completing Stage

**Review Purpose**:

1. Validate code quality
2. Discover potential bugs
3. Check test coverage
4. Confirm documentation completeness

**Review Flow**:

```
1. Trigger multi-model Review
2. Triangulation: main dev model + independent reviewer + rule check
3. AI initial screening of findings
4. Rule filtering
5. Independently verify each finding
6. Fix blocking findings
7. Record Review log
```

---

## Prompt Design Principles

### Colleague Mode vs Worker Mode

| Mode | Characteristics | Applicable Scenarios |
|------|-----------------|----------------------|
| Colleague Mode | Equal exchange, open discussion | Design Review, design discussion |
| Worker Mode | Clear instructions, execute tasks | Specific implementation, code modification |

**Colleague Mode Prompt Example**:

```
Hello, I'm designing a cache system and would like your help with a review.

Background:
- Need to support 100K QPS
- Data size approximately 100MB
- Need to support expiration policies

Current design:
[Design content]

Please help me review from these perspectives:
1. Is the design reasonable
2. Are there potential issues
3. What improvement suggestions do you have
```

**Worker Mode Prompt Example**:

```
Please implement the following functionality:

1. Add LRU cache implementation in src/cache.rs
2. Support get/put/delete operations
3. Add unit tests, coverage >= 80%

Run tests after completion and ensure they pass.
```

### First Round Openness Principle

**Principle**: Don't provide dimensions/hints in the first Review round, let the model freely explore.

**Reasons**:

1. Avoid guiding the model's thinking
2. Discover unexpected issues
3. Obtain more objective evaluation

**Practice Methods**:

```
First Round Prompt:
"Please review this design document and provide your comments and suggestions."

Do NOT provide in the first round Prompt:
- Check dimensions
- Scoring criteria
- Expected problem types

Second round and after:
Can ask targeted follow-up questions based on first round results.
```

### Review Prompt Templates

#### Design Review Prompt

```markdown
## Design Review Request

**Project Background**: [Project introduction]

**Stage Information**:
- Stage Number: [Stage N]
- Goal: [Stage goal]
- Non-goals: [Stage non-goals]

**Design Document**:
[Attach design document content]

**Please help review**:
1. Does design meet goals
2. Are non-goal boundaries clear
3. Are there potential risks
4. What improvement suggestions
```

#### Code Review Prompt

```markdown
## Code Review Request

**Stage Information**:
- Stage Number: [Stage N]
- Goal: [Stage goal]

**Code Changes**:
[Attach code changes or PR link]

**Please help review**:
1. Code quality
2. Potential bugs
3. Test coverage
4. Documentation completeness
```

---

## False Positive Recognition

### False Positive Rate Explanation

Based on practical experience, **approximately 50% of Review findings are false positives**.

This means:

1. Don't blindly accept all findings
2. Each finding needs independent verification
3. Don't rely on "multi-model consensus" to judge correctness

### Common False Positive Types

| False Positive Type | Description | Example |
|--------------------|-------------|---------|
| Memory Bias | Model "remembers" certain patterns that don't apply to current scenario | "Should use singleton pattern" (actually not needed) |
| Logical Fallacy | Reasoning process has logical issues | "Will crash because no error handling" (actually handled upstream) |
| Over-engineering | Suggested complexity exceeds requirements | "Should use microservices architecture" (actually monolith is sufficient) |
| Incomplete Information | Judgment based on incomplete information | "Missing input validation" (actually handled in other layer) |
| Outdated Version | References outdated best practices | "Should use var declaration" (modern JS recommends let/const) |
| Missing Context | Didn't consider complete context | "This function is too long" (actually generated serialization code) |

### False Positive Identification Methods

```
1. Check if authoritative sources support it
   - Official documentation
   - Standards and specifications
   - Best practice guides

2. Verify in code
   - Run tests
   - Check call chains
   - View context

3. Question the model
   - Request more explanation
   - Ask about specific scenarios
   - Verify reasoning process
```

### False Positive Handling Flow

```
Receive Finding
    │
    ▼
Check if authoritative sources support it?
    │
    ├─ Yes → Verify if authoritative source applies to current scenario
    │         │
    │         ├─ Applies → Accept Finding
    │         │
    │         └─ Doesn't apply → Mark as false positive, record reason
    │
    └─ No → Verify in code
              │
              ├─ Verifiable → Run tests/check code
              │              │
              │              ├─ Problem exists → Accept Finding
              │              │
              │              └─ Problem doesn't exist → Mark as false positive
              │
              └─ Cannot verify → Question model
                              │
                              ├─ Explanation reasonable → Accept Finding
                              │
                              └─ Explanation unreasonable → Mark as false positive
```

---

## Verification Methods

### Verification Priority

```
Authoritative Sources > Code Verification > Model Inquiry
```

### 1. Authoritative Source Verification

**Applicable Scenarios**:

- Issues involving standards, specifications
- Issues related to best practices
- API usage, syntax issues

**Authoritative Source Types**:

| Type | Example |
|------|---------|
| Official Documentation | Rust official docs, Tokio docs |
| Standards/Specifications | RFC, language specifications |
| Best Practices | Official best practice guides |
| Authoritative Books | "The Rust Programming Language" |

**Verification Steps**:

```
1. Identify the topic the Finding relates to
2. Find relevant authoritative sources
3. Confirm authoritative source content
4. Determine if it applies to current scenario
```

**Example**:

```
Finding: "Should use Arc<Mutex<T>> instead of Mutex<T>"

Verification Process:
1. Consult Rust official documentation
2. Documentation states: Arc is for multi-threaded shared ownership
3. Check current code: Currently in single-threaded environment
4. Conclusion: False positive, single-threaded doesn't need Arc

Record: Document rejection reason in review-log.md
```

### 2. Code Verification

**Applicable Scenarios**:

- Reproducible issues
- Logic issues
- Performance issues

**Verification Methods**:

| Method | Description |
|--------|-------------|
| Run Tests | Verify functionality works correctly |
| Add Breakpoints | Check runtime state |
| Log Tracing | Trace problem path |
| Performance Testing | Verify performance assumptions |
| Code Review | Check logic correctness |

**Verification Steps**:

```
1. Understand the problem described in Finding
2. Design verification plan
3. Execute verification
4. Record verification results
```

**Example**:

```
Finding: "Potential null pointer exception here"

Verification Process:
1. Check code: Function returns Option<T>
2. Check call: Used ? operator
3. Run tests: Tests pass, no null pointer
4. Conclusion: False positive, already handled correctly

Record: Document verification process in review-log.md
```

### 3. Model Inquiry Verification

**Applicable Scenarios**:

- First two methods cannot verify
- Need more explanation

**Inquiry Methods**:

```
1. Ask model to explain reasoning process
2. Ask about specific scenarios and conditions
3. Verify if explanation is reasonable
```

**Inquiry Prompt Template**:

```markdown
Regarding your Finding "[Finding content]", I need more information:

1. What is this suggestion based on?
2. In what scenarios would this problem occur?
3. Are there specific code examples?

Current context:
[Related code or design]
```

**Example**:

```
Finding: "This design may have performance issues"

Inquiry Process:
Q: In what scenarios would this performance issue occur?
A: When data exceeds 1 million, iteration becomes slow

Verification:
1. Check current data volume: Expected max 100K
2. Conclusion: Not an issue in current scenario

Record: False positive, but record as technical debt (optimize if data volume grows)
```

---

## Review Log Format

### Review Log Template

```markdown
# Stage N Review Log

## Basic Information
- Review Type: [Design Review / Code Review]
- Review Date: [Date]
- Review Model: [Model name]

## Findings Summary
- Total: [Count]
- Adopted: [Count]
- Rejected: [Count]
- Pending: [Count]

## Findings Details

### Finding 1: [Title]
- **Type**: [Design/Implementation/Testing/Documentation]
- **Severity**: [Blocking/Important/Suggestion]
- **Description**: [Detailed description]
- **Verification Method**: [Authoritative Source/Code Verification/Model Inquiry]
- **Verification Result**: [Adopted/False Positive]
- **Reason**: [Reason for adoption or rejection]

### Finding 2: [Title]
...

## Technical Debt Records
Technical debt extracted from this review:

### TD-XX: [Title]
- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architecture/Module/Local]
- **Source**: Review Finding [Number]
- **Suggested Landing Stage**: [Stage N]
```

---

## Review Best Practices

### DO

```
✓ Don't provide dimension hints in first Review round
✓ Independently verify each Finding
✓ Record verification process and results
✓ Question and clarify uncertain Findings
✓ Extract technical debt from Reviews
✓ Use colleague mode for discussions
```

### DON'T

```
✗ Blindly accept all Findings
✗ Rely on "multi-model consensus" to judge correctness
✗ Skip verification process and directly adopt
✗ Provide check dimensions in first round Prompt
✗ Use worker mode for Reviews
✗ Don't record verification reasons
```

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Key Reminder**: Approximately 50% of Review findings are false positives. Each Finding needs independent verification, verification priority: Authoritative Sources > Code Verification > Model Inquiry.
