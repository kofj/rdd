#!/usr/bin/env bash
# Language and Framework Detection Engine for RDD Init
# Detects project language, type, and recommends appropriate test frameworks

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detection results
DETECTED_LANGUAGE=""
DETECTED_PROJECT_TYPE=""
DETECTED_FRAMEWORKS=()
RECOMMENDED_BDD=""
RECOMMENDED_UNIT=""
RECOMMENDED_COVERAGE=""
RECOMMENDED_E2E=""
RECOMMENDED_API=""

# Print colored output
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Detect Node.js project
detect_nodejs() {
  if [[ -f "package.json" ]]; then
    DETECTED_LANGUAGE="nodejs"

    # Check for frontend frameworks
    if grep -q '"react"' package.json 2>/dev/null ||
      grep -q '"vue"' package.json 2>/dev/null ||
      grep -q '"angular"' package.json 2>/dev/null ||
      [[ -d "src/components" ]] ||
      [[ -f "next.config.js" ]] ||
      [[ -f "nuxt.config.js" ]]; then
      DETECTED_PROJECT_TYPE="frontend"
      RECOMMENDED_E2E="playwright"
    fi

    # Check for backend frameworks
    if grep -q '"express"' package.json 2>/dev/null ||
      grep -q '"fastify"' package.json 2>/dev/null ||
      grep -q '"nest"' package.json 2>/dev/null ||
      grep -q '"koa"' package.json 2>/dev/null; then
      if [[ "$DETECTED_PROJECT_TYPE" == "frontend" ]]; then
        DETECTED_PROJECT_TYPE="fullstack"
      else
        DETECTED_PROJECT_TYPE="backend-api"
      fi
      RECOMMENDED_API="supertest"
    fi

    # Default project type
    if [[ -z "$DETECTED_PROJECT_TYPE" ]]; then
      DETECTED_PROJECT_TYPE="backend-service"
    fi

    # Test frameworks
    RECOMMENDED_BDD="cucumber-js"
    RECOMMENDED_UNIT="jest"
    RECOMMENDED_COVERAGE="nyc"

    return 0
  fi
  return 1
}

# Detect Python project
detect_python() {
  if [[ -f "requirements.txt" ]] ||
    [[ -f "pyproject.toml" ]] ||
    [[ -f "setup.py" ]] ||
    [[ -f "Pipfile" ]]; then
    DETECTED_LANGUAGE="python"

    # Check for web frameworks
    if grep -q "django" requirements.txt 2>/dev/null ||
      [[ -f "settings.py" ]]; then
      DETECTED_PROJECT_TYPE="backend-api"
      DETECTED_FRAMEWORKS+=("django")
    elif grep -q "flask" requirements.txt 2>/dev/null ||
      [[ -f "app.py" ]] && grep -q "flask" app.py 2>/dev/null; then
      DETECTED_PROJECT_TYPE="backend-api"
      DETECTED_FRAMEWORKS+=("flask")
    elif grep -q "fastapi" requirements.txt 2>/dev/null; then
      DETECTED_PROJECT_TYPE="backend-api"
      DETECTED_FRAMEWORKS+=("fastapi")
    else
      DETECTED_PROJECT_TYPE="backend-service"
    fi

    # Test frameworks
    RECOMMENDED_BDD="pytest-bdd"
    RECOMMENDED_UNIT="pytest"
    RECOMMENDED_COVERAGE="coverage.py"
    RECOMMENDED_E2E="playwright"
    RECOMMENDED_API="requests"

    return 0
  fi
  return 1
}

# Detect Go project
detect_go() {
  if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
    DETECTED_LANGUAGE="go"
    DETECTED_PROJECT_TYPE="backend-service"

    # Test frameworks
    RECOMMENDED_BDD="godog"
    RECOMMENDED_UNIT="go test"
    RECOMMENDED_COVERAGE="go cover"
    RECOMMENDED_API="httptest"

    return 0
  fi
  return 1
}

# Detect Rust project
detect_rust() {
  if [[ -f "Cargo.toml" ]]; then
    DETECTED_LANGUAGE="rust"
    DETECTED_PROJECT_TYPE="backend-service"

    # Test frameworks
    RECOMMENDED_BDD="cucumber-rust"
    RECOMMENDED_UNIT="cargo test"
    RECOMMENDED_COVERAGE="tarpaulin"
    RECOMMENDED_API="reqwest"

    return 0
  fi
  return 1
}

# Detect Java project
detect_java() {
  if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
    DETECTED_LANGUAGE="java"
    DETECTED_PROJECT_TYPE="backend-api"

    # Test frameworks
    RECOMMENDED_BDD="cucumber-jvm"
    RECOMMENDED_UNIT="junit"
    RECOMMENDED_COVERAGE="jacoco"
    RECOMMENDED_E2E="selenium"
    RECOMMENDED_API="rest-assured"

    return 0
  fi
  return 1
}

# Main detection function
detect_project() {
  print_info "Detecting project language and type..."

  # Try each language detector
  if detect_nodejs; then
    print_success "Detected Node.js project"
  elif detect_python; then
    print_success "Detected Python project"
  elif detect_go; then
    print_success "Detected Go project"
  elif detect_rust; then
    print_success "Detected Rust project"
  elif detect_java; then
    print_success "Detected Java project"
  else
    print_warning "Could not detect project language"
    print_info "Please specify manually:"
    DETECTED_LANGUAGE="unknown"
    DETECTED_PROJECT_TYPE="unknown"
  fi

  # Print detection results
  echo ""
  echo "=== Detection Results ==="
  echo "Language:      ${DETECTED_LANGUAGE}"
  echo "Project Type:  ${DETECTED_PROJECT_TYPE}"
  echo "Frameworks:    ${DETECTED_FRAMEWORKS[*]:-none}"
  echo ""
  echo "=== Recommended Test Frameworks ==="
  echo "BDD Framework:    ${RECOMMENDED_BDD:-not recommended}"
  echo "Unit Test Runner: ${RECOMMENDED_UNIT:-not recommended}"
  echo "Coverage Tool:    ${RECOMMENDED_COVERAGE:-not recommended}"
  echo "E2E Tool:         ${RECOMMENDED_E2E:-not recommended}"
  echo "API Test Tool:    ${RECOMMENDED_API:-not recommended}"
  echo ""
}

# Generate test configuration
generate_test_config() {
  local output_file="${1:-.rdd/test-config.yml}"

  print_info "Generating test configuration..."

  # Create directory if not exists
  mkdir -p "$(dirname "$output_file")"

  # Generate config based on language
  case "$DETECTED_LANGUAGE" in
    nodejs)
      generate_nodejs_config >"$output_file"
      ;;
    python)
      generate_python_config >"$output_file"
      ;;
    go)
      generate_go_config >"$output_file"
      ;;
    rust)
      generate_rust_config >"$output_file"
      ;;
    java)
      generate_java_config >"$output_file"
      ;;
    *)
      print_warning "Unknown language, generating generic config"
      generate_generic_config >"$output_file"
      ;;
  esac

  print_success "Generated test configuration: $output_file"
}

# Node.js test configuration
generate_nodejs_config() {
  cat <<'EOF'
# RDD Test Configuration
# Auto-generated for Node.js project

language: nodejs
project_type: NODEJS_PROJECT_TYPE

test_framework:
  bdd: cucumber-js
  bdd_version: latest
  unit: jest
  unit_version: latest
  coverage: nyc
  e2e: NODEJS_E2E_TOOL
  api: NODEJS_API_TOOL

coverage:
  minimum: 95
  fail_gate: true
  report_format: lcov
  output_dir: coverage
  include:
    - "src/**/*"
  exclude:
    - "**/*.test.*"
    - "**/*.spec.*"
    - "**/test/**"

directories:
  features: tests/features
  steps: tests/steps
  unit: tests/unit
  integration: tests/integration
  e2e: tests/e2e
  fixtures: tests/fixtures

commands:
  unit: npm test
  e2e: npm run test:e2e
  coverage: npm run test:coverage
  bdd: npm run test:bdd
  all: npm run test:all

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Python test configuration
generate_python_config() {
  cat <<'EOF'
# RDD Test Configuration
# Auto-generated for Python project

language: python
project_type: PYTHON_PROJECT_TYPE

test_framework:
  bdd: pytest-bdd
  bdd_version: latest
  unit: pytest
  unit_version: latest
  coverage: coverage.py
  e2e: playwright
  api: requests

coverage:
  minimum: 95
  fail_gate: true
  report_format: xml
  output_dir: coverage
  include:
    - "src/**/*"
    - "app/**/*"
  exclude:
    - "**/test_*.py"
    - "**/tests/**"

directories:
  features: tests/features
  steps: tests/steps
  unit: tests/unit
  integration: tests/integration
  e2e: tests/e2e
  fixtures: tests/fixtures

commands:
  unit: pytest tests/unit
  e2e: pytest tests/e2e
  coverage: pytest --cov=src --cov-report=xml
  bdd: pytest tests/features
  all: pytest

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Go test configuration
generate_go_config() {
  cat <<'EOF'
# RDD Test Configuration
# Auto-generated for Go project

language: go
project_type: backend-service

test_framework:
  bdd: godog
  bdd_version: latest
  unit: go test
  unit_version: native
  coverage: go cover
  api: httptest

coverage:
  minimum: 95
  fail_gate: true
  report_format: html
  output_dir: coverage
  include:
    - "**/*.go"
  exclude:
    - "**/*_test.go"
    - "**/test/**"

directories:
  features: tests/features
  steps: tests/steps
  unit: tests/unit
  integration: tests/integration
  fixtures: tests/fixtures

commands:
  unit: go test ./...
  e2e: go test -tags=e2e ./...
  coverage: go test -coverprofile=coverage.out ./...
  bdd: godog run
  all: go test -coverprofile=coverage.out ./...

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Rust test configuration
generate_rust_config() {
  cat <<'EOF'
# RDD Test Configuration
# Auto-generated for Rust project

language: rust
project_type: backend-service

test_framework:
  bdd: cucumber-rust
  bdd_version: latest
  unit: cargo test
  unit_version: native
  coverage: tarpaulin
  api: reqwest

coverage:
  minimum: 95
  fail_gate: true
  report_format: xml
  output_dir: coverage
  include:
    - "src/**/*.rs"
  exclude:
    - "src/**/*_test.rs"
    - "tests/**"

directories:
  features: tests/features
  steps: tests/steps
  unit: tests/unit
  integration: tests/integration
  fixtures: tests/fixtures

commands:
  unit: cargo test
  e2e: cargo test --test e2e
  coverage: cargo tarpaulin --out Xml
  bdd: cargo test --test cucumber
  all: cargo test

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Java test configuration
generate_java_config() {
  cat <<'EOF'
# RDD Test Configuration
# Auto-generated for Java project

language: java
project_type: backend-api

test_framework:
  bdd: cucumber-jvm
  bdd_version: latest
  unit: junit
  unit_version: 5
  coverage: jacoco
  e2e: selenium
  api: rest-assured

coverage:
  minimum: 95
  fail_gate: true
  report_format: xml
  output_dir: target/coverage
  include:
    - "src/main/java/**"
  exclude:
    - "src/test/java/**"

directories:
  features: src/test/resources/features
  steps: src/test/java/steps
  unit: src/test/java/unit
  integration: src/test/java/integration
  e2e: src/test/java/e2e
  fixtures: src/test/resources/fixtures

commands:
  unit: mvn test
  e2e: mvn test -Pe2e
  coverage: mvn test jacoco:report
  bdd: mvn test -Pcucumber
  all: mvn verify

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Generic test configuration
generate_generic_config() {
  cat <<'EOF'
# RDD Test Configuration
# Generic template - please customize for your project

language: unknown
project_type: unknown

test_framework:
  bdd: ""
  unit: ""
  coverage: ""

coverage:
  minimum: 95
  fail_gate: true

directories:
  features: tests/features
  steps: tests/steps
  unit: tests/unit
  integration: tests/integration
  e2e: tests/e2e
  fixtures: tests/fixtures

commands:
  unit: ""
  e2e: ""
  coverage: ""
  bdd: ""
  all: ""

pre_commit:
  enabled: true
  run_unit_tests: true
  run_coverage_check: true
  run_lint: true
  minimum_coverage: 95

ci:
  run_on_pr: true
  run_on_push: true
  fail_on_coverage_drop: true
EOF
}

# Generate example BDD feature file
generate_example_feature() {
  local output_dir="${1:-tests/features}"
  local output_file="$output_dir/example.feature"

  mkdir -p "$output_dir"

  cat >"$output_file" <<'EOF'
Feature: Example feature
  As a developer
  I want to verify testing setup
  So that I can write BDD tests with confidence

  Scenario: Basic test execution
    Given the test framework is configured
    When I run the example test
    Then it should pass

  Scenario: Coverage threshold enforcement
    Given tests with coverage reporting
    When I run the test suite
    Then coverage should meet the minimum threshold
    And the gate should pass
EOF

  print_success "Generated example feature file: $output_file"
}

# Generate example step definitions (Node.js)
generate_nodejs_steps() {
  local output_dir="${1:-tests/steps}"
  local output_file="$output_dir/example.steps.js"

  mkdir -p "$output_dir"

  cat >"$output_file" <<'EOF'
const { Given, When, Then } = require('@cucumber/cucumber');

Given('the test framework is configured', function () {
  // Setup code
  this.frameworkConfigured = true;
});

When('I run the example test', function () {
  // Action code
  this.testResult = 'pass';
});

Then('it should pass', function () {
  // Assertion code
  if (this.testResult !== 'pass') {
    throw new Error('Expected test to pass');
  }
});

Given('tests with coverage reporting', function () {
  this.coverageEnabled = true;
});

When('I run the test suite', function () {
  this.coveragePercent = 96; // Example coverage
});

Then('coverage should meet the minimum threshold', function () {
  if (this.coveragePercent < 95) {
    throw new Error(`Coverage ${this.coveragePercent}% is below minimum 95%`);
  }
});

Then('the gate should pass', function () {
  // Gate logic
  console.log('Gate passed with coverage:', this.coveragePercent + '%');
});
EOF

  print_success "Generated example steps file: $output_file"
}

# Generate example step definitions (Python)
generate_python_steps() {
  local output_dir="${1:-tests/steps}"
  local output_file="$output_dir/example_steps.py"

  mkdir -p "$output_dir"

  cat >"$output_file" <<'EOF'
from pytest_bdd import given, when, then

@given('the test framework is configured')
def framework_configured():
    return {'configured': True}

@when('I run the example test')
def run_test(framework_configured):
    return {'result': 'pass'}

@then('it should pass')
def verify_pass(run_test):
    assert run_test['result'] == 'pass'

@given('tests with coverage reporting')
def coverage_enabled():
    return {'coverage_enabled': True}

@when('I run the test suite')
def run_suite(coverage_enabled):
    return {'coverage_percent': 96}

@then('coverage should meet the minimum threshold')
def verify_coverage(run_suite):
    assert run_suite['coverage_percent'] >= 95

@then('the gate should pass')
def gate_passed(run_suite):
    print(f"Gate passed with coverage: {run_suite['coverage_percent']}%")
EOF

  print_success "Generated example steps file: $output_file"
}

# Main entry point
main() {
  local command="${1:-detect}"
  shift 2>/dev/null || true

  case "$command" in
    detect)
      detect_project
      ;;
    config)
      generate_test_config "$@"
      ;;
    feature)
      generate_example_feature "$@"
      ;;
    steps)
      case "$DETECTED_LANGUAGE" in
        nodejs)
          generate_nodejs_steps "$@"
          ;;
        python)
          generate_python_steps "$@"
          ;;
        *)
          print_warning "No step template for $DETECTED_LANGUAGE"
          ;;
      esac
      ;;
    all)
      detect_project
      generate_test_config "$@"
      generate_example_feature
      case "$DETECTED_LANGUAGE" in
        nodejs)
          generate_nodejs_steps
          ;;
        python)
          generate_python_steps
          ;;
      esac
      ;;
    *)
      echo "Usage: $0 {detect|config|feature|steps|all}"
      echo ""
      echo "Commands:"
      echo "  detect  - Detect project language and type"
      echo "  config  - Generate test configuration"
      echo "  feature - Generate example BDD feature file"
      echo "  steps   - Generate example step definitions"
      echo "  all     - Run all setup steps"
      exit 1
      ;;
  esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
