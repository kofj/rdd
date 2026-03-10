# Stage 11: E2E Test Framework Preparation

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
Prepare the infrastructure needed for E2E testing, including Docker test environment, Claude Code installation, and third-party model API configuration.

## Non-Goals
- Actual installation testing (Stage 12)
- Claude Code integration testing (Stage 13)
- GitHub release (Stage 15+)

## Core Hypotheses
- H1: Docker containers can simulate clean user environments
- H2: Claude Code can run normally in containers
- H3: Third-party model APIs can be accessed in containers
- H4: RDD Skills can be recognized by Claude Code

## Acceptance Criteria

### Docker Test Image (11.1) ✅
- [x] Create `tests/e2e/Dockerfile.claude`
- [x] Based on Ubuntu 22.04 image
- [x] Install required dependencies (bash, curl, git, node, task)
- [x] Install Claude Code CLI
- [x] Configure environment variables
- [x] Image builds successfully

### Claude Code Installation (11.2) ✅
- [x] Claude Code CLI executable
- [x] Version verification passed
- [x] Configuration directory created (~/.claude/)
- [x] settings.json configured correctly

### Third-party Model Configuration (11.3) ✅
- [x] API endpoint configuration (using environment variables)
- [x] Model name configuration
- [x] API connection test passed
- [x] No hardcoded sensitive information in files

### Test Project Template (11.4) ✅
- [x] Create minimal test project
- [x] Includes basic RDD structure
- [x] Can be used for subsequent tests

### Test Scripts (11.5) ✅
- [x] `tests/e2e/setup-test-env.sh` - Environment setup
- [x] `tests/e2e/run-tests.sh` - Test execution
- [x] `tests/e2e/test_helper.bash` - Test helper functions

## Rollback Plan
- Docker images can be deleted and rebuilt
- Test scripts are independent, don't affect main code

## Known Limitations
- Docker containers have no GUI
- Requires network access to third-party APIs
- Some interactive features may be limited

## Impact on Subsequent Stages
- Stage 12 depends on test environment
- Stage 13 depends on Claude Code installation
- Stage 14 depends on complete test framework

---

## Implementation Notes

### Docker Image Architecture

```
tests/e2e/Dockerfile.claude
├── Base image: ubuntu:22.04 or alpine:3.19
├── Dependency installation
│   ├── bash, curl, git
│   ├── nodejs, npm
│   └── go-task
├── Claude Code installation
│   └── npm install -g @anthropic-ai/claude-code
├── Environment configuration
│   └── ~/.claude/settings.json
└── RDD copy
    └── /app/
```

### Environment Variable Configuration

Sensitive information injected via environment variables, not written to files:

```bash
# Passed when starting container
docker run -e ANTHROPIC_AUTH_TOKEN="${TOKEN}" \
           -e ANTHROPIC_BASE_URL="${API_URL}" \
           -e ANTHROPIC_MODEL="${MODEL}" \
           rdd-test:latest
```

### settings.json Template

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL}",
    "ANTHROPIC_MODEL": "${ANTHROPIC_MODEL}"
  },
  "model": "${ANTHROPIC_MODEL}",
  "skipWebFetchPreflight": true
}
```

---

## Verification

### Gate 1: Design Document Check
- [x] Design document complete
- [x] Goals clearly defined
- [x] Non-goals explicitly stated
- [x] Acceptance criteria testable
- [x] Rollback plan exists

### Gate 2: Design Review Check
- [ ] Multi-model review triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [x] Docker image builds successfully
- [x] Claude Code installation verified
- [x] API connection test passed
- [x] Test project created successfully
- [x] E2E tests passed (21/21)

### Gate 4: Code Review Check
- [x] No sensitive information leaked
- [x] Dockerfile best practices
- [x] Script maintainability

### Gate 5: Completion Gate Check
- [x] Test environment ready
- [x] Subsequent Stages can start
- [x] Documentation updated
