# Review Practices Guide

> This document defines the timing, methodology, and best practices for reviews in RDD projects.

---

## Review Timing

### Two Review Types

| Type | Timing | Purpose | Output |
|------|--------|---------|--------|
| Design Review | Before coding | Validate design soundness | Optimized design document |
| Code Review | After E2E passes | Validate implementation quality | Review log |

### Design Review (Before Coding)

**Trigger Conditions**:

- Stage design document complete
- Ready to start implementation

**Review Purpose**:

1. Validate design meets requirements
2. Discover potential design issues
3. Ensure non-goal boundaries are clear
4. Validate hypothesis soundness

**Review Process**:

```
1. Trigger multi-model review
2. First round open, no dimensions/hints
3. AI filter findings
4. Rule filtering
5. Independently verify each finding
6. Update design document
7. Record review log
```

### Code Review (After E2E Passes)

**Trigger Conditions**:

- E2E tests pass
- Ready to complete Stage

**Review Purpose**:

1. Validate code quality
2. Discover potential bugs
3. Check test coverage
4. Confirm documentation completeness

**Review Process**:

```
1. Trigger multi-model review
2. Triangulation: main dev + independent review + rule check
3. AI filter findings
4. Rule filtering
5. Independently verify each finding
6. Fix blocking findings
7. Record review log
```

---

## Prompt Design Principles

### Peer Mode vs Worker Mode

| Mode | Characteristics | Applicable Scenarios |
|------|----------------|---------------------|
| Peer Mode | Equal exchange, open discussion | Design review, design discussion |
| Worker Mode | Explicit instructions, execute tasks | Specific implementation, code modification |

**Peer Mode Prompt Example**:

```
Hi, I'm designing a cache system and would like your help reviewing it.

Background:
- Need to support 100K QPS
- Data size about 100MB
- Need expiration policy support

Current design:
[Design content]

Please help me look at:
1. Is the design reasonable
2. Are there potential issues
3. Any improvement suggestions
```

**Worker Mode Prompt Example**:

```
Please implement the following:

1. Add LRU cache implementation in src/cache.rs
2. Support get/put/delete operations
3. Add unit tests, coverage >= 80%

After completion, run tests and ensure they pass.
```

### First Round Open Principle

**Principle**: First review round gives no dimensions/hints, let the model think freely.

**Reasons**:

1. Avoid guiding model thinking
2. Discover unexpected issues
3. Get more objective evaluation

**Practice Method**:

```
First Round Prompt:
"Please review this design document and give your opinions and suggestions."

Don't provide in first round Prompt:
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

**Project Background**: [Project intro]

**Stage Info**:
- Stage Number: [Stage N]
- Goal: [Stage goal]
- Non-goals: [Stage non-goals]

**Design Document**:
[Attach design document content]

**Please help review**:
1. Does design meet goals
2. Are non-goal boundaries clear
3. Are there potential risks
4. Any improvement suggestions
```

#### Code Review Prompt

```markdown
## Code Review Request

**Stage Info**:
- Stage Number: [Stage N]
- Goal: [Stage goal]

**Code Changes**:
[Attach code change content or PR link]

**Please help review**:
1. Code quality
2. Potential bugs
3. Test coverage
4. Documentation completeness
```

---

## False Positive Recognition

### False Positive Rate

Based on practice, **approximately 50% of review findings are false positives**.

This means:

1. Don't blindly accept all findings
2. Each finding needs independent verification
3. Don't rely on "multi-model consensus" to judge correctness

### Common False Positive Types

| False Positive Type | Description | Example |
|--------------------|-------------|---------|
| Memory Bias | Model "remembered" patterns that don't apply to current scenario | "Should use singleton pattern" (actually not needed) |
| Logic Fallacy | Flawed reasoning process | "Will crash because no error handling" (actually handled upstream) |
| Over-engineering | Suggested complexity exceeds requirements | "Should use microservices architecture" (actually monolith is enough) |
| Incomplete Info | Judgment based on incomplete information | "Missing input validation" (actually handled in other layer) |
| Outdated Version | Referenced outdated best practices | "Should use var declaration" (modern JS recommends let/const) |
| Missing Context | Didn't consider full context | "This function is too long" (actually generated serialization code) |

### False Positive Identification Methods

```
1. Check if authoritative source supports it
   - Official documentation
   - Standards and specs
   - Best practice guides

2. Verify in code
   - Run tests
   - Check call chain
   - View context

3. Follow up with model
   - Request more explanation
   - Ask about specific scenarios
   - Verify reasoning process
```

### False Positive Handling Process

```
Receive Finding
    │
    ▼
Check if authoritative source supports?
    │
    ├─ Yes → Verify if authoritative source applies to current scenario
    │         │
    │         ├─ Applies → Adopt Finding
    │         │
    │         └─ Doesn't apply → Mark as false positive, record reason
    │
    └─ No → Verify in code
              │
              ├─ Verifiable → Run tests/check code
              │              │
              │              ├─ Issue exists → Adopt Finding
              │              │
              │              └─ Issue doesn't exist → Mark as false positive
              │
              └─ Cannot verify → Follow up with model
                              │
                              ├─ Reasonable explanation → Adopt Finding
                              │
                              └─ Unreasonable explanation → Mark as false positive
```

---

## Verification Methods

### Verification Priority

```
Authoritative Sources > Code Verification > Model Follow-up
```

### 1. Authoritative Source Verification

**Applicable Scenarios**:

- Issues involving standards, specifications
- Best practice-related issues
- API usage, syntax issues

**Authoritative Source Types**:

| Type | Example |
|------|---------|
| Official Documentation | Rust official docs, Tokio docs |
| Standards | RFC, language specs |
| Best Practices | Official best practice guides |
| Authoritative Books | "The Rust Programming Language" |

**Verification Steps**:

```
1. Identify the topic the finding involves
2. Find relevant authoritative sources
3. Confirm authoritative source content
4. Determine if it applies to current scenario
```

**Example**:

```
Finding: "Should use Arc<Mutex<T>> instead of Mutex<T>"

Verification:
1. Check Rust official documentation
2. Docs show: Arc for multi-thread shared ownership
3. Check current code: Currently in single-thread environment
4. Conclusion: False positive, single-thread doesn't need Arc

Record: Document non-adoption reason in review-log.md
```

### 2. Code Verification

**Applicable Scenarios**:

- Reproducible issues
- Logic issues
- Performance issues

**Verification Methods**:

| Method | Description |
|--------|-------------|
| Run tests | Verify functionality works |
| Add breakpoints | Check runtime state |
| Log tracing | Trace issue path |
| Performance testing | Verify performance assumptions |
| Code review | Check logic correctness |

**Verification Steps**:

```
1. Understand the issue the finding describes
2. Design verification plan
3. Execute verification
4. Record verification results
```

**Example**:

```
Finding: "Potential null pointer exception here"

Verification:
1. Check code: Function returns Option<T>
2. Check call: Uses ? operator
3. Run test: Tests pass, no null pointer
4. Conclusion: False positive, already handled correctly

Record: Document verification process in review-log.md
```

### 3. Model Follow-up Verification

**Applicable Scenarios**:

- First two methods cannot verify
- Need more explanation

**Follow-up Methods**:

```
1. Request model to explain reasoning process
2. Ask about specific scenarios and conditions
3. Verify if explanation is reasonable
```

**Follow-up Prompt Template**:

```markdown
Regarding your finding "[Finding content]", I need more information:

1. What is this suggestion based on?
2. In what scenarios would this issue appear?
3. Do you have specific code examples?

Current context:
[Related code or design]
```

**Example**:

```
Finding: "This design might have performance issues"

Follow-up:
Q: In what scenarios would this performance issue appear?
A: When data exceeds 1 million, iteration becomes slow

Verification:
1. Check current data volume: Expected max 100K
2. Conclusion: Not an issue in current scenario

Record: False positive, but record as tech debt (optimize if data grows)
```

---

## Review Log Format

### Review Log Template

```markdown
# Stage N Review Log

## Basic Info
- Review Type: [Design Review / Code Review]
- Review Date: [Date]
- Review Model: [Model name]

## Findings Summary
- Total: [Count]
- Adopted: [Count]
- Not Adopted: [Count]
- Pending: [Count]

## Findings Details

### Finding 1: [Title]
- **Type**: [Design/Implementation/Test/Documentation]
- **Severity**: [Blocking/Important/Suggestion]
- **Description**: [Detailed description]
- **Verification Method**: [Authoritative Source/Code Verification/Model Follow-up]
- **Verification Result**: [Adopted/False Positive]
- **Reason**: [Reason for adoption or non-adoption]

### Finding 2: [Title]
...

## Tech Debt Records
Tech debt extracted from this review:

### TD-XX: [Title]
- **Priority**: [Blocking/Feature Degradation/Tech Optimization] / [Architecture/Module/Local]
- **Source**: Review Finding [Number]
- **Suggested Stage**: [Stage N]
```

---

## Review Best Practices

### DO

```
✓ First review round without dimension hints
✓ Independently verify each Finding
✓ Record verification process and results
✓ Follow up for clarification on uncertain Findings
✓ Extract tech debt from reviews
✓ Use peer mode for discussions
```

### DON'T

```
✗ Blindly accept all Findings
✗ Rely on "multi-model consensus" to judge correctness
✗ Skip verification and adopt directly
✗ Give check dimensions in first round Prompt
✗ Use worker mode for reviews
✗ Not record verification reasons
```

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | [Date] | Initial version | [Name] |

---

> **Key Reminder**: Approximately 50% of review findings are false positives. Each Finding needs independent verification. Verification priority: Authoritative Sources > Code Verification > Model Follow-up.
