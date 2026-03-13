# Stage 21: TDD/BDD Initialization Enhancement

## Status

[ ] Planning / [ ] In Progress / [ ] Complete

---

## Goals

Enhance RDD initialization to automatically configure testing frameworks:
1. Auto-detect project language and type (frontend/backend/API)
2. Recommend appropriate BDD frameworks
3. Generate test configuration with 95%+ coverage requirement
4. Create example feature files and step definitions
5. Configure pre-commit hooks for test enforcement

---

## Non-Goals

- IDE test runner integration
- CI/CD pipeline configuration (separate stage)
- Test migration for existing projects

---

## Core Hypotheses

- **Hypothesis A**: Auto-configured testing increases adoption by 80%
- **Hypothesis B**: 95% coverage threshold improves code quality measurably

---

## Acceptance Criteria

- [ ] Language detection works for Node.js, Python, Go, Rust, Java
- [ ] Framework recommendations match project type
- [ ] Generated test configuration passes validation
- [ ] Example BDD tests execute successfully
- [ ] Pre-commit hooks block commits with <95% coverage
- [ ] Gate enforcement requires passing tests
- [ ] All features have E2E tests
- [ ] Coverage >= 95%

---

## Rollback Plan

1. Remove test configuration from init
2. Users manually configure testing
3. Coverage enforcement disabled via config

---

## Known Limitations

- Detection relies on file patterns, may miss edge cases
- BDD examples are generic, need customization per project

---

## Impact on Subsequent Stages

- All future projects will have testing configured by default
- Stage 22 can rely on test enforcement for multi-stage safety

---

## Implementation Notes

### Task 1: Language Detection Engine

Detection strategy:
```yaml
nodejs:
  indicators:
    - package.json
    - node_modules/
  frameworks:
    - react: src/**/*.{jsx,tsx}
    - vue: src/**/*.vue
    - express: app.js, server.js
    - nest: nest-cli.json

python:
  indicators:
    - requirements.txt
    - pyproject.toml
    - setup.py
  frameworks:
    - django: settings.py, urls.py
    - flask: app.py
    - fastapi: main.py

go:
  indicators:
    - go.mod
    - go.sum

rust:
  indicators:
    - Cargo.toml
    - Cargo.lock

java:
  indicators:
    - pom.xml
    - build.gradle
```

### Task 2: BDD Framework Configuration

```yaml
# .rdd/test-config.yml (generated)
language: nodejs
type: backend-api

test_framework:
  bdd: cucumber-js
  runner: jest
  coverage: nyc
  coverage_threshold: 95
  api_test: supertest

structure:
  features: tests/features/
  steps: tests/steps/
  unit: tests/unit/
  e2e: tests/e2e/

hooks:
  pre_commit: true
  pre_push: true
  coverage_gate: true
```

### Task 3: Generate Example Tests

For each language, generate:

**Feature file** (Gherkin):
```gherkin
# tests/features/example.feature
Feature: Example feature
  As a developer
  I want to verify testing setup
  So that I can write BDD tests

  Scenario: Basic test execution
    Given the test framework is configured
    When I run the example test
    Then it should pass
```

**Step definitions**:
```javascript
// tests/steps/example.steps.js (Node.js)
const { Given, When, Then } = require('@cucumber/cucumber');

Given('the test framework is configured', function () {
  // Setup code
});

When('I run the example test', function () {
  // Action code
});

Then('it should pass', function () {
  // Assertion code
});
```

### Task 4: Pre-commit Hooks

```yaml
# .pre-commit-config.yaml (generated)
repos:
  - repo: local
    hooks:
      - id: test-coverage
        name: Test Coverage Check
        entry: npm run test:coverage -- --threshold 95
        language: system
        pass_filenames: false
```

### Task 5: Gate Enforcement

Update `.rdd/config.yml`:
```yaml
gates:
  min_coverage: 95
  coverage_fail_gate: true
  bdd_required: true
  test_commands:
    unit: "npm test"
    e2e: "npm run test:e2e"
    coverage: "npm run test:coverage"
```

---

## Technical Design

### Framework Matrix

| Language | Project Type | BDD Framework | Test Runner | Coverage Tool | API Testing |
|----------|-------------|---------------|-------------|---------------|-------------|
| Node.js | Frontend | cucumber-js | jest | nyc | - |
| Node.js | Backend API | cucumber-js | jest | nyc | supertest |
| Python | Any | pytest-bdd | pytest | coverage.py | requests |
| Go | Any | godog | go test | go cover | httptest |
| Rust | Any | cucumber-rust | cargo test | tarpaulin | reqwest |
| Java | Any | cucumber-jvm | junit | jacoco | rest-assured |

### Generated Structure

```
project/
├── .rdd/
│   ├── config.yml          # Updated with test config
│   └── test-config.yml     # Test framework details
├── tests/
│   ├── features/           # BDD feature files
│   │   └── example.feature
│   ├── steps/              # Step definitions
│   │   └── example.steps.js
│   ├── unit/               # Unit tests
│   └── e2e/                # E2E tests
├── .pre-commit-config.yaml
└── package.json / requirements.txt / ...
```

---

## Test Plan

### Unit Tests

```bash
tests/unit/detection/test_language_detection.bats
tests/unit/detection/test_framework_recommendation.bats
tests/unit/generation/test_config_generation.bats
```

### E2E Tests

```bash
tests/e2e/test_nodejs_init.bats
tests/e2e/test_python_init.bats
tests/e2e/test_go_init.bats
tests/e2e/test_coverage_enforcement.bats
```

---

## Dependencies

- None (can run parallel with Stage 19)

---

## Estimated Effort

Medium (2 days)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-13 | Initial design |
