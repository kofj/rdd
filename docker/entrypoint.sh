#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "\n${BLUE}==>${NC} $*"; }

run_unit_tests() {
    log_step "Running unit tests..."
    cd "${PROJECT_ROOT}"
    if command -v task &> /dev/null; then
        task test:unit
    elif [ -d "tests/unit" ]; then
        bats tests/unit/
    else
        log_info "No unit tests found, skipping..."
    fi
}

run_e2e_tests() {
    log_step "Running E2E tests..."
    cd "${PROJECT_ROOT}"
    export PROJECT_ROOT RDD_FRAMEWORK_HOME
    if [ -d "tests/e2e" ]; then
        bats tests/e2e/
    else
        log_info "No E2E tests found, skipping..."
    fi
}

run_install_test() {
    log_step "Testing installation in clean environment..."
    local test_dir="/tmp/rdd-test-$$"
    mkdir -p "${test_dir}"
    export INSTALL_PREFIX="${test_dir}/.rdd-framework"
    export HOME="${test_dir}"
    export PATH="${INSTALL_PREFIX}/bin:${PATH}"
    cd "${PROJECT_ROOT}"

    if bash scripts/install/install.sh; then
        log_info "Installation test passed!"
        [ -x "${INSTALL_PREFIX}/bin/rdd" ] && log_info "rdd command installed successfully"
        (command -v task &> /dev/null || [ -x "${INSTALL_PREFIX}/bin/task" ]) && log_info "go-task installed successfully"
        return 0
    else
        log_error "Installation test failed!"
        return 1
    fi
}

run_all_tests() {
    log_step "Running all tests..."
    local failed=0
    run_unit_tests || ((failed++))
    run_e2e_tests || ((failed++))
    run_install_test || ((failed++))
    echo ""
    log_step "Test Results"
    if [ ${failed} -eq 0 ]; then
        log_info "All tests passed!"
        return 0
    else
        log_error "${failed} test suite(s) failed"
        return 1
    fi
}

main() {
    local command="${1:-test}"
    case "${command}" in
        test|all) run_all_tests ;;
        unit) run_unit_tests ;;
        e2e) run_e2e_tests ;;
        install) run_install_test ;;
        shell) exec /bin/bash ;;
        *)
            echo "Usage: $0 {test|unit|e2e|install|shell}"
            exit 1 ;;
    esac
}

main "$@"
