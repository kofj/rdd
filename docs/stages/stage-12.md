# Stage 12: Installation Flow E2E Testing

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
Verify that the complete installation flow works in a clean environment, ensuring users can install RDD Framework via multiple methods.

## Non-Goals
- Claude Code integration testing (Stage 13)
- Complete workflow testing (Stage 14)
- Performance testing

## Core Hypotheses
- H1: `curl | sh` installation method works in clean environment
- H2: Skills and Commands are correctly installed to ~/.claude/
- H3: `rdd init` can create complete project structure
- H4: `rdd --version` and `task doctor` work properly

## Acceptance Criteria

### curl | sh Installation Test (12.1) ✅
- [x] Simulate curl | sh installation from local file
- [x] Check ~/.rdd-framework/ directory created
- [x] Check PATH configuration correct
- [x] Check rdd command available
- [x] Clean test environment

### Manual Installation Test (12.2) ✅
- [x] Copy skills to ~/.claude/skills/
- [x] Copy commands to ~/.claude/commands/
- [x] Copy scripts to ~/.rdd-framework/scripts/
- [x] Check file permissions correct
- [x] Check all files exist

### npm Installation Test (12.3) ✅
- [x] Verify package.json correct
- [x] Simulate npm install -g flow
- [x] Check postinstall script execution
- [x] Check rdd command available

### Command Functionality Test (12.4) ✅
- [x] `rdd --version` shows version
- [x] `rdd --help` shows help
- [x] `rdd init <name>` creates project
- [x] `rdd init` initializes in current directory
- [x] `rdd doctor` health check passes

### Project Structure Verification (12.5) ✅
- [x] Created project contains .rdd/ directory
- [x] Created project contains docs/ directory
- [x] Created project contains tests/ directory
- [x] Created project contains Taskfile.yml
- [x] Taskfile is executable

## Rollback Plan
- Each test runs independently
- Environment cleaned after testing
- Docker containers can be rebuilt

## Known Limitations
- Tests don't involve real network downloads
- npm publish not executed, using local simulation

## Impact on Subsequent Stages
- Stage 13 needs successful installation environment
- Stage 14 needs usable project

---

## Implementation Notes

### Test Case Design

```bash
# tests/e2e/install-flow.bats

@test "INST-01: curl | sh installation success" {
    # Simulate curl | sh installation
    run bash scripts/install/install.sh --prefix /tmp/rdd-test
    [ "$status" -eq 0 ]
    [ -f "/tmp/rdd-test/bin/rdd" ]
}

@test "INST-02: manual installation success" {
    # Manually copy files
    mkdir -p ~/.claude/{skills,commands}
    cp -r .claude/skills/* ~/.claude/skills/
    cp -r .claude/commands/* ~/.claude/commands/
    [ -f ~/.claude/skills/rdd-init.md ]
    [ -f ~/.claude/commands/rdd-init.md ]
}

@test "INST-03: rdd --version works" {
    run rdd --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.0.0" ]]
}

@test "INST-04: rdd init creates project" {
    run rdd init test-project
    [ "$status" -eq 0 ]
    [ -d "test-project/.rdd" ]
    [ -d "test-project/docs" ]
    [ -f "test-project/Taskfile.yml" ]
}

@test "INST-05: task doctor passes" {
    cd test-project
    run task doctor
    [ "$status" -eq 0 ]
}
```

### Test Execution Flow

```
1. Environment Preparation
   └── docker build -t rdd-test tests/e2e/

2. Installation Tests
   ├── INST-01: curl | sh
   ├── INST-02: manual installation
   └── INST-03: npm installation

3. Functionality Tests
   ├── INST-04: rdd --version
   ├── INST-05: rdd --help
   ├── INST-06: rdd init
   └── INST-07: task doctor

4. Cleanup
   └── docker rm / docker rmi
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
- [ ] All test cases passed
- [ ] Test coverage >= 80%
- [ ] No residual test files

### Gate 4: Code Review Check
- [ ] Test code quality
- [ ] Test independence
- [ ] Cleanup completeness

### Gate 5: Completion Gate Check
- [ ] Installation flow verification complete
- [ ] Documentation updated
- [ ] Stage 13 can start
