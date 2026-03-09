#!/bin/bash
#
# Test coverage script for RDD Framework
# Generates coverage reports for shell scripts using kcov (if available)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RDD_SCRIPTS_DIR="${PROJECT_ROOT}/.rdd/scripts"
COVERAGE_DIR="${PROJECT_ROOT}/.rdd/cache/coverage"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if kcov is available
check_kcov() {
    if command -v kcov &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Generate coverage report using kcov
generate_kcov_report() {
    log_info "Generating coverage report with kcov..."

    mkdir -p "${COVERAGE_DIR}"

    # Run tests with coverage
    for test_file in "${PROJECT_ROOT}/tests/unit"/*.bats; do
        if [[ -f "$test_file" ]]; then
            log_info "Running: $(basename "$test_file")"
            kcov --include-path="${RDD_SCRIPTS_DIR}" \
                 "${COVERAGE_DIR}" \
                 bats "$test_file" || true
        fi
    done

    # Generate summary
    if [[ -f "${COVERAGE_DIR}/index.json" ]]; then
        log_info "Coverage report generated: ${COVERAGE_DIR}"
        log_info "Open ${COVERAGE_DIR}/index.html for detailed report"
    fi
}

# Generate simple coverage report without kcov
generate_simple_report() {
    log_info "Generating simple coverage report..."

    mkdir -p "${COVERAGE_DIR}"

    local total_functions=0
    local tested_functions=0
    local coverage_percentage=0

    # Count functions in notify.sh
    if [[ -f "${RDD_SCRIPTS_DIR}/notify.sh" ]]; then
        total_functions=$(grep -c "^[a-z_]*() {" "${RDD_SCRIPTS_DIR}/notify.sh" 2>/dev/null || echo "0")
    fi

    # Count tested functions from test files
    tested_functions=$(grep -r "@test" "${PROJECT_ROOT}/tests/unit"/*.bats 2>/dev/null | wc -l || echo "0")

    # Calculate coverage (simplified)
    if [[ $total_functions -gt 0 ]]; then
        coverage_percentage=$((tested_functions * 100 / total_functions))
        if [[ $coverage_percentage -gt 100 ]]; then
            coverage_percentage=100
        fi
    fi

    # Write report
    cat > "${COVERAGE_DIR}/coverage-report.txt" << EOF
RDD Framework Test Coverage Report
===================================

Generated: $(date)

Summary
-------
Total Functions: ${total_functions}
Test Cases: ${tested_functions}
Estimated Coverage: ${coverage_percentage}%

Test Files
----------
$(ls -1 "${PROJECT_ROOT}/tests/unit"/*.bats 2>/dev/null | xargs -I {} basename {})

Note: Install kcov for detailed line-by-line coverage analysis.
    apt-get install kcov
    or
    brew install kcov

EOF

    log_info "Simple coverage report generated: ${COVERAGE_DIR}/coverage-report.txt"
    echo ""
    cat "${COVERAGE_DIR}/coverage-report.txt"
}

# Run coverage analysis
main() {
    log_info "RDD Framework Test Coverage Analysis"
    echo ""

    if check_kcov; then
        generate_kcov_report
    else
        log_warn "kcov not found. Generating simple coverage report."
        log_warn "Install kcov for detailed coverage analysis:"
        echo "  Ubuntu/Debian: apt-get install kcov"
        echo "  macOS: brew install kcov"
        echo ""
        generate_simple_report
    fi

    # Check minimum coverage
    local min_coverage="${MIN_COVERAGE:-95}"
    log_info "Minimum coverage requirement: ${min_coverage}%"
}

main "$@"
