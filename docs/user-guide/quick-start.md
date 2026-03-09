# RDD Framework Quick Start Guide

> Get up and running with RDD Framework in 5 minutes.

## What is RDD?

RDD (Roadmap-Driven Development) Framework is a structured approach to software development that ensures:
- Clear project boundaries and goals
- Systematic stage-by-stage progression
- Automatic context recovery
- Comprehensive error handling
- Production-ready quality

## Prerequisites

- **Task**: A task runner (go-task)
- **Bash**: Unix shell environment
- **Git**: Version control

```bash
# Install Task (macOS/Linux)
brew install go-task
# or
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

# Verify installation
task --version
```

## Installation

### Option 1: Initialize New Project

```bash
# Create a new project directory
mkdir my-project && cd my-project

# Initialize RDD Framework
task rdd:init

# This creates:
# - .rdd/ directory structure
# - docs/ directory with templates
# - Taskfile.yml with RDD tasks
# - CLAUDE.md entry point
```

### Option 2: Migrate Existing Project

```bash
# Navigate to your existing project
cd existing-project

# Migrate to RDD Framework
task rdd:migrate

# This analyzes your project and:
# - Creates RDD directory structure
# - Generates initial Roadmap
# - Creates documentation templates
# - Preserves existing files
```

## Your First Stage

### 1. Create a Stage Document

```bash
# Create Stage 0 document
cat > docs/stages/stage-0.md << 'EOF'
# Stage 0: Project Setup

## Goals
Set up the initial project structure and configuration.

## Acceptance Criteria
- [ ] Directory structure created
- [ ] Configuration files in place
- [ ] Basic documentation exists

## Verification
- [ ] `task doctor` passes all checks
- [ ] `task test` runs successfully
EOF
```

### 2. Run Stage

```bash
# Auto-execute the stage
task rdd:stage-auto

# This will:
# 1. Verify entry conditions
# 2. Execute implementation
# 3. Run tests
# 4. Perform code review
# 5. Complete the stage
```

### 3. Check Progress

```bash
# View current status
cat docs/11-next-steps.md

# View roadmap progress
task rdd:roadmap show

# Run health check
task doctor
```

## Core Tasks

| Task | Description |
|------|-------------|
| `task rdd:init` | Initialize new RDD project |
| `task rdd:migrate` | Migrate existing project |
| `task rdd:stage-auto` | Auto-execute current stage |
| `task rdd:roadmap show` | View roadmap progress |
| `task doctor` | Health check |
| `task test` | Run all tests |
| `task rdd:backup` | Create backup |
| `task rdd:restore` | Restore from backup |

## Directory Structure

```
project/
├── .rdd/                    # RDD Framework files
│   ├── lib/                 # Core libraries
│   ├── scripts/             # Utility scripts
│   ├── hooks/               # Hook scripts
│   └── cache/               # Cache files
├── docs/                    # Documentation
│   ├── 01-charter.md        # Project charter
│   ├── 02-principles.md     # Engineering principles
│   ├── stages/              # Stage documents
│   └── 11-next-steps.md     # Current status
├── tests/                   # Test files
│   ├── unit/                # Unit tests
│   ├── bdd/                 # BDD tests
│   └── e2e/                 # E2E tests
├── Taskfile.yml             # Task definitions
├── CLAUDE.md                # Claude Code entry point
└── AGENTS.md                # Agent rules
```

## Key Concepts

### Stages

Stages are the fundamental unit of progress in RDD. Each stage:
- Has clear goals and acceptance criteria
- Follows a 5-gate verification process
- Must pass all tests before completion
- Documents all decisions (ADRs)

### Gates

Every stage passes through 5 gates:

1. **Gate 1**: Design document check
2. **Gate 2**: Design review
3. **Gate 3**: Implementation & testing
4. **Gate 4**: Code review
5. **Gate 5**: Completion verification

### Context Recovery

RDD automatically saves context at key points:
- Gate completions
- Important decisions
- Blocker resolutions
- 30-minute intervals

If context is lost (Claude compaction), RDD can recover automatically.

## Next Steps

1. Read [Installation Guide](installation.md) for detailed setup
2. Review [Basic Usage](basic-usage.md) for common workflows
3. Explore [API Reference](../api-reference/README.md) for all commands
4. Check [Best Practices](best-practices.md) for tips

## Getting Help

- Check [Troubleshooting Guide](../operations/troubleshooting.md)
- Review [FAQ](../operations/faq.md)
- Open an issue on GitHub

---

> **Tip**: Start with `task doctor` to verify your setup is correct.
