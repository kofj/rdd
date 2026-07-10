# Autonomous Decisions Record (ADR)

> This document records architecture decisions and technology choices in the RDD project, ensuring the decision-making process is traceable and understandable.

---

## ADR Format Description

### What is an ADR

ADR (Architecture Decision Record) is a lightweight document format for recording architecture decisions. Each decision record contains:

- Background and context of the decision
- The decision content made
- The reason for making that decision
- The impact of that decision on subsequent Stages

### ADR Format Template

```markdown
### Decision N: [Decision Title]

**Background**: What triggered this decision

**Decision Content**: What path was chosen

**Reason**: Why this choice was made

**Impact on Subsequent Stages**: (Cannot be empty)
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| Decision Number | Yes | Format: Decision 1, Decision 2, etc. |
| Decision Title | Yes | Concise summary of decision content |
| Background | Yes | Describe the context that triggered this decision |
| Decision Content | Yes | Clearly describe the decision made |
| Reason | Yes | Explain why this decision was made |
| Impact on Subsequent Stages | Yes | Must be filled in, describe impact on subsequent work |

### When to Record an ADR

Record an ADR in the following situations:

1. **Architecture Decisions**: Major decisions affecting system architecture
2. **Technology Selection**: Choosing tech stacks, frameworks, libraries, etc.
3. **Design Trade-offs**: Making trade-offs between multiple options
4. **Assumption Changes**: Core assumptions verified or falsified
5. **Non-goal Declarations**: Explicitly stating what will not be done
6. **Technical Debt Decisions**: Decisions to accept technical debt

### ADR Writing Guidelines

```
DO:
- Record each decision independently
- Clear background description so newcomers can understand
- Unambiguous decision content
- Well-founded reasons
- Specific impact pointing to clear Stages

DON'T:
- Leave "Impact on Subsequent Stages" empty
- Record trivial daily decisions
- Ambiguous decision content
- Not record reasons or impact
```

---

## ADR Index

| Number | Title | Date | Related Stage | Status |
|--------|-------|------|---------------|--------|
| Decision 1 | Hook scripts use source to import shared functions | 2026-03-07 | Stage 1 | Active |
| Decision 2 | Hook triggering managed by rdd-hooks skill | 2026-03-07 | Stage 1 | Active |
| Decision 3 | Use relative paths and PROJECT_ROOT environment variable | 2026-03-07 | Stage 1 | Active |
| Decision 4 | Credentials use ${VAR} environment variable references | 2026-03-07 | Stage 1 | Active |
| Decision 5 | Choose bats-core as Shell testing framework | 2026-03-07 | Stage 2 | Active |
| Decision 6 | Testing strategy: Unit/BDD/E2E three-layer testing | 2026-03-07 | Stage 2 | Active |
| Decision 7 | Error classification system: Recoverable/Non-recoverable two categories | 2026-03-07 | Stage 4 | Active |
| Decision 8 | Retry strategy: Exponential backoff + jitter | 2026-03-07 | Stage 4 | Active |
| Decision 9 | Degradation strategy: Five-level degradation (Level 0-4) | 2026-03-07 | Stage 4 | Active |
| Decision 10 | Log format: Structured JSON logs | 2026-03-07 | Stage 4 | Active |
| Decision 11 | Metrics format: Prometheus text format | 2026-03-07 | Stage 4 | Active |
| Decision 12 | Circuit breaker: Failure count-based circuit breaker pattern | 2026-03-07 | Stage 4 | Active |
| Decision 13 | RBAC permission model: Three-role design (admin/developer/viewer) | 2026-03-07 | Stage 6 | Active |
| Decision 14 | Audit log using file storage + JSON format solution | 2026-03-07 | Stage 6 | Active |
| Decision 15 | Sensitive data handling: Environment variables + optional Vault integration | 2026-03-07 | Stage 6 | Active |
| Decision 16 | Shell script security hardening: Input validation + injection protection | 2026-03-07 | Stage 6 | Active |
| Decision 17 | Performance benchmarking: Custom bash script solution | 2026-03-07 | Stage 5 | Active |
| Decision 18 | Version management: Semantic versioning + compatibility matrix | 2026-03-07 | Stage 5 | Active |
| Decision 19 | Migration strategy: Backup + atomic migration + rollback support | 2026-03-07 | Stage 5 | Active |
| Decision 20 | Compatibility checking: YAML schema validation + breaking change detection | 2026-03-07 | Stage 5 | Active |
| Decision 21 | Installation method: curl | sh one-click installation priority | 2026-03-09 | Stage 8 | Active |
| Decision 22 | Skills distribution: Copy to ~/.claude/skills/ | 2026-03-09 | Stage 8 | Active |
| Decision 23 | Release channels: GitHub Release + npm | 2026-03-09 | Stage 9 | Active |
| Decision 24 | Command naming: rdd (short command friendly) | 2026-03-09 | Stage 9 | Active |
| Decision 25 | Phase 4 architecture: Incremental enhancement approach | 2026-03-13 | Stage 19 | Active |
| Decision 26 | Command hints: Description field in command definitions | 2026-03-13 | Stage 19 | Active |
| Decision 27 | Help & workflow: Combined approach (state-aware + wizard + help center) | 2026-03-13 | Stage 20 | Active |
| Decision 28 | TDD/BDD: Auto-configuration with 95% coverage requirement | 2026-03-13 | Stage 21 | Active |
| Decision 29 | Multi-stage: Extended rdd-loop with worktree pool and subagent scheduling | 2026-03-13 | Stage 22 | Active |

---

## Decision Details

### Decision 1: Hook Scripts Use Source to Import Shared Functions

**Background**: Stage 1 needs to implement Hook notification functionality, multiple Hook scripts need to share some common functions (such as logging, error handling, etc.).

**Decision Content**:
1. Create `scripts/lib/common.sh` to store shared functions
2. All Hook scripts import via `source "${PROJECT_ROOT}/scripts/lib/common.sh"`
3. Common functions include: logging, error handling, retry mechanism, configuration reading

**Reason**:
1. Avoid code duplication
2. Easy to maintain and update
3. Consistent behavior
4. Easy to test

**Impact on Subsequent Stages**:
- All subsequent stages can use these shared functions
- If shared function behavior needs to change, need to evaluate impact on all Hook scripts
- Need to ensure backward compatibility of shared functions

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. Copy code to each script - High maintenance cost
2. Create independent executable files - Increased call overhead
3. Use environment variables to transfer functions - Not secure and error-prone

---

### Decision 21: Installation Method Using curl | sh One-Click Installation Priority

**Background**: Stage 8 needs to implement user installation experience optimization, need to choose the main installation method.

**Decision Content**:
1. curl | sh is the main recommended installation method
2. GitHub Release is the release channel
3. Installation script automatically detects OS and architecture
4. Installation script verifies SHA256 checksum

**Reason**:
1. curl | sh is the simplest user experience
2. GitHub Release provides reliable download source
3. Automatic detection reduces user decisions
4. Checksum ensures security

**Impact on Subsequent Stages**:
- Stage 9 (Package Manager Support) needs to ensure consistency with this method
- Stage 10 (Developer Experience Optimization) needs to optimize this installation process
- All releases need to pass through GitHub Release

**Date**: 2026-03-09

**Related Stage**: Stage 8

---

### Decision 22: Skills Distributed by Copying to ~/.claude/skills/

**Background**: Stage 8 needs to decide how to distribute RDD Skills to users.

**Decision Content**:
1. Installation script copies .claude/skills/ directory to user's ~/.claude/skills/
2. Each Skill is an independent .md file
3. Update mechanism: overwrite old files

**Reason**:
1. Claude Code automatically loads ~/.claude/skills/ directory
2. Simple structure, easy to understand and maintain
3. No additional runtime dependencies required
4. Easy to debug and customize

**Impact on Subsequent Stages**:
- Future Skill updates need to ensure backward compatibility
- Need to consider migration mechanism when adding new Skills
- May need version checking mechanism

**Date**: 2026-03-09

**Related Stage**: Stage 8

---

### Decision 23: Release Channels Using GitHub Release + npm

**Background**: Stage 9 needs to choose release channels and package manager support.

**Decision Content**:
1. GitHub Release as the main release channel
2. npm as secondary package manager channel
3. PyPI support as future consideration
4. Homebrew support as future consideration

**Reason**:
1. GitHub Release provides reliable release management
2. npm is the preferred package manager for Node.js ecosystem
3. Simple release process, automation possible
4. Easy to integrate with CI/CD

**Impact on Subsequent Stages**:
- Need to maintain consistency between two channels
- Need to ensure version synchronization
- Need to test two installation methods

**Date**: 2026-03-09

**Related Stage**: Stage 9

---

### Decision 24: Command Naming Using rdd (Short Command Friendly)

**Background**: Stage 9 needs to determine the naming convention for RDD CLI commands.

**Decision Content**:
1. Use rdd as the main command prefix
2. Subcommands use hyphen naming: rdd-init, rdd-stage-auto, etc.
3. Both long and short forms are supported

**Reason**:
1. rdd is short and memorable
2. Hyphen naming is clear and readable
3. Consistent with Unix conventions
4. Easy to type

**Impact on Subsequent Stages**:
- All command documents need to follow this naming
- Need to maintain command naming consistency
- Future new commands need to follow this convention

**Date**: 2026-03-09

**Related Stage**: Stage 9

---

### Decision 25: Phase 4 Architecture Using Incremental Enhancement Approach

**Background**: Phase 4 needs to implement user readiness improvements. Two architectural approaches were considered: incremental enhancement vs. full refactor.

**Decision Content**:
1. Use incremental enhancement approach
2. Build new features on existing architecture
3. Maintain backward compatibility
4. Each stage can be independently delivered

**Reason**:
1. Lower risk, each stage can be independently verified
2. Maintain backward compatibility, existing users are not affected
3. Can quickly deliver partial value
4. Aligns with RDD incremental development philosophy

**Impact on Subsequent Stages**:
- Stage 19-22 will build on existing command/skill infrastructure
- Future phases can continue to enhance on this foundation
- Need to ensure each stage's interfaces are stable

**Date**: 2026-03-13

**Related Stage**: Phase 4

**Alternatives Considered**:
1. Full architecture refactor - Higher risk, longer timeline
2. Parallel development of new system - Maintenance burden

---

### Decision 26: Command Hints Using Description Field in Command Definitions

**Background**: Stage 19 needs to add input hints for RDD commands. Claude Code reads command file frontmatter to display hints.

**Decision Content**:
1. Add `description` field to command definitions (YAML frontmatter)
2. Include one-line summary and usage examples
3. Support multi-line descriptions for complex commands
4. All existing commands will be updated with hints

**Reason**:
1. Claude Code natively supports frontmatter descriptions
2. Simple implementation, no additional infrastructure needed
3. Consistent with existing command format
4. Easy to maintain and update

**Impact on Subsequent Stages**:
- Stage 20 state-aware hints will use same format
- Stage 22 progress hints will build on this
- All new commands must include description field

**Date**: 2026-03-13

**Related Stage**: Stage 19

**Alternatives Considered**:
1. Separate hints file - Additional maintenance burden
2. Dynamic hints based on context - Too complex for initial implementation

---

### Decision 27: Help & Workflow Using Combined Approach

**Background**: Stage 20 needs to provide comprehensive user guidance. Three approaches were considered.

**Decision Content**:
1. Implement `/rdd-help` command for deep documentation search
2. Add state-aware next-step prompts after each command
3. Create `/rdd-workflow` interactive wizard for common tasks
4. All three approaches combined for comprehensive coverage

**Reason**:
1. Each approach addresses different user needs
2. State-aware prompts provide proactive guidance
3. Help center provides deep reference
4. Wizard guides complex workflows
5. Combination provides best user experience

**Impact on Subsequent Stages**:
- Stage 22 will use state machine for progress tracking
- Future features can build on state-aware infrastructure
- Need to maintain consistency across all guidance systems

**Date**: 2026-03-13

**Related Stage**: Stage 20

**Alternatives Considered**:
1. Help center only - No proactive guidance
2. Wizard only - Not flexible enough
3. State prompts only - No deep reference

---

### Decision 28: TDD/BDD Auto-Configuration with 95% Coverage Requirement

**Background**: Stage 21 needs to enhance RDD initialization with testing framework configuration.

**Decision Content**:
1. Auto-detect project language and type (frontend/backend/API)
2. Recommend appropriate BDD framework based on detection
3. Generate test configuration with 95% minimum coverage requirement
4. Create example feature files and step definitions
5. Configure pre-commit hooks for test enforcement

**Reason**:
1. High coverage ensures code quality
2. Auto-configuration reduces setup friction
3. BDD provides clear acceptance criteria
4. Pre-commit hooks prevent low-quality commits

**Impact on Subsequent Stages**:
- All new projects will have testing configured by default
- Stage 22 can rely on test enforcement for multi-stage safety
- Future stages can extend coverage requirements

**Date**: 2026-03-13

**Related Stage**: Stage 21

**Alternatives Considered**:
1. 80% coverage threshold - Lower quality guarantee
2. No auto-configuration - Higher barrier to adoption
3. Optional BDD - Inconsistent testing practices

---

### Decision 29: Multi-stage Using Extended rdd-loop with Worktree Pool and Subagent Scheduling

**Background**: Stage 22 needs to enable autonomous execution across multiple stages.

**Decision Content**:
1. Extend `/rdd-loop` with range execution (`--from N --to M`)
2. Implement dependency graph analysis for parallel execution
3. Use git worktree pool for isolation (max 3 parallel)
4. Subagent scheduler for concurrent execution
5. Natural language goal parsing for intelligent planning

**Reason**:
1. Extended command is familiar to existing users
2. Worktree isolation prevents conflicts
3. Subagent scheduling enables parallelism
4. Natural language parsing improves usability
5. Builds on existing RDD infrastructure

**Impact on Subsequent Stages**:
- Enables large-scale autonomous development
- Foundation for future distributed execution
- Need to handle merge conflicts gracefully

**Date**: 2026-03-13

**Related Stage**: Stage 22

**Alternatives Considered**:
1. New `/rdd-progress` command - Additional learning curve
2. Single-threaded execution only - Slower
3. No worktree isolation - Merge conflict risks

---

## ADR Deprecation Records

When decisions are no longer applicable, record the deprecation reason here:

### [Decision Number] Deprecation Record

**Deprecation Date**: [Date]

**Deprecation Reason**: [Explain why this decision is deprecated]

**Alternative Solution**: [New decision or solution]

**Impact Assessment**: [Impact on existing code after deprecation]

---

## Revision History

| Version | Date | Revision Content | Author |
|---------|------|------------------|--------|
| v2.0 | 2026-03-13 | Added Phase 4 decisions (25-29), cleaned up invalid entries | Claude |
| v1.0 | 2026-03-06 | Initial version | Claude |

### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-13
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-14
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-14
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-14
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-14
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-14
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-25
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-25
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-25
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision 22A: Default behavior is auto-detect, not manual range

**Background**: Original Stage 22 design required `--from N --to M` for every invocation of `/rdd-loop`.

**Decision**: Default to auto-detection. Scan `stage-roadmap.md`, find all stages with status ≠ Completed, resolve dependency ordering, execute from first incomplete to last. `--from` / `--to` become optional filters.

**Rationale**: Manual range specification is redundant when the roadmap is the source of truth. The only time `--from`/`--to` is needed is when the user intentionally wants to skip stages or stop early.

**Impact on Subsequent Stages**: Reduces command friction, eliminates "forgot to specify range" errors. Self-healing runs (recovery) can resume without knowing which stage they were on.

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision 22B: Remove `start` subcommand

**Background**: `/rdd-loop start` was the invocation pattern in v1 design.

**Decision**: `/rdd-loop` with no subcommand starts execution. `status`, `pause`, `resume` remain as control subcommands.

**Rationale**: "Loop" inherently means "start executing". Adding `start` is noise. The subcommand space is reserved for control operations, not the default action.

**Impact on Subsequent Stages**: Simplified command surface. New control subcommands can be added without ambiguity.

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision 22C: Remove `--goal` natural language parsing (v1)

**Background**: Original design included NL goal → stage mapping.

**Decision**: Remove from v1. Roadmap Goal field is the canonical, deterministic data source. NL parsing introduces ambiguity and has high implementation cost with low marginal benefit.

**Rationale**: The roadmap already contains precise, human-authored goal descriptions. Adding an NL layer on top introduces a second, less reliable source of truth.

**Impact on Subsequent Stages**: Simplifies command surface, removes a source of non-deterministic behavior. Revisit if users demand it.

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision 22D: Fine-grained atomic persistence

**Background**: Previous design saved state only at gate boundaries. Context overflow or process termination between gates loses all in-gate progress.

**Decision**: Save state atomically at every key action: gate enter/exit, decision made, tech debt found, test run complete, every 5 min heartbeat. `loop-state.yaml` is canonical; `checkpoints.json` for backward compat.

**Rationale**: Context overflow is inevitable in long-running autonomous sessions. The only defense is atomic, frequent persistence of all critical state. On recovery, the agent reads the last saved action, not the last gate boundary.

**Impact on Subsequent Stages**: All multi-stage execution inherits crash-resilience. Recovery protocol is self-contained. Maximum data loss window: 5 minutes (heartbeat interval).

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision 22E: Hardened Gate 3 — real execution only

**Background**: Current Gate 3 implementation printed checklist items without executing anything. An agent could claim "all tests pass" without running them.

**Decision**: Replace echo-only gates with real command execution that blocks on non-zero exit: `task test:unit`, `task test:e2e`, `task test:coverage`, `task lint:check`, `task fmt:check`.

**Rationale**: Gates must be machine-verifiable. No gate may rely on agent self-reporting alone. If tests fail, the gate blocks progression regardless of what the agent "claims".

**Impact on Subsequent Stages**: Sets a precedent that ALL gates must be non-bypassable. Future stages must add their checks to the hardened pipeline.

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision 22F: gotask convergence — no orphan commands

**Background**: During autonomous execution, agents may create new scripts, checks, or workflows. Without enforcement, these become undocumented manual steps invisible to new agents.

**Decision**: Every script created during loop execution must be registered as a `task` entry in `Taskfile.yml`. The `task registry:verify` gate checks for orphans. Scripts without task entries are treated as Gate 3 failures.

**Rationale**: The Taskfile is the single entry point for all project operations. Allowing ad-hoc commands creates fragmentation and makes handoff unreliable.

**Impact on Subsequent Stages**: All future stages inherit this constraint. Taskfile becomes the canonical command registry.

**Date**: 2026-07-10
**Related Stage**: Stage 22

### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown


### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-07-10
**Related Stage**: Stage unknown

