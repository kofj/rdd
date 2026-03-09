#!/usr/bin/env bash
#
# E2E Test Runner
# Runs all E2E tests in Docker container
#
# Usage: ./run-tests.sh [--docker] [--local]
#
# Environment Variables:
#   ANTHROPIC_AUTH_TOKEN - API token (required for integration tests)
#   ANTHROPIC_BASE_URL   - API URL (required for integration tests)
#   ANTHROPIC_MODEL      - Model name (required for integration tests)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_NAME="rdd-test"
CONTAINER_NAME="rdd-test-$$"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "\n${BLUE}==>${NC} ${BOLD}$*${NC}"; }

# Check environment variables
check_env() {
    local missing=()

    if [[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        missing+=("ANTHROPIC_AUTH_TOKEN")
    fi

    if [[ -z "${ANTHROPIC_BASE_URL:-}" ]]; then
        missing+=("ANTHROPIC_BASE_URL")
    fi

    if [[ -z "${ANTHROPIC_MODEL:-}" ]]; then
        missing+=("ANTHROPIC_MODEL")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing environment variables (integration tests will be skipped):"
        for var in "${missing[@]}"; do
            echo "  - $var"
        done
        return 1
    fi

    return 0
}

# Build Docker image
build_image() {
    log_step "Building Docker image..."

    cd "${PROJECT_ROOT}"

    if ! docker build -t "${IMAGE_NAME}" -f tests/e2e/Dockerfile.claude .; then
        log_error "Failed to build Docker image"
        exit 1
    fi

    log_info "Docker image built: ${IMAGE_NAME}"
}

# Run tests in Docker
run_docker_tests() {
    log_step "Running E2E tests in Docker..."

    local env_args=()

    # Pass environment variables if set
    if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        env_args+=(-e "ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN}")
    fi

    if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
        env_args+=(-e "ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}")
    fi

    if [[ -n "${ANTHROPIC_MODEL:-}" ]]; then
        env_args+=(-e "ANTHROPIC_MODEL=${ANTHROPIC_MODEL}")
    fi

    # Run tests
    docker run --rm \
        "${env_args[@]}" \
        -e "PROJECT_ROOT=/app" \
        --name "${CONTAINER_NAME}" \
        "${IMAGE_NAME}" \
        bats /app/tests/e2e/

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_info "All E2E tests passed!"
    else
        log_error "Some tests failed"
    fi

    return $exit_code
}

# Run tests locally
run_local_tests() {
    log_step "Running E2E tests locally..."

    cd "${PROJECT_ROOT}"

    # Export project root for tests
    export PROJECT_ROOT="${PROJECT_ROOT}"

    # Run bats
    bats tests/e2e/

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_info "All E2E tests passed!"
    else
        log_error "Some tests failed"
    fi

    return $exit_code
}

# Cleanup
cleanup() {
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
}

# Main
main() {
    local mode="local"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --docker)
                mode="docker"
                shift
                ;;
            --local)
                mode="local"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    trap cleanup EXIT

    log_step "E2E Test Runner"
    echo "Mode: ${mode}"
    echo ""

    check_env || true

    if [[ "$mode" == "docker" ]]; then
        build_image
        run_docker_tests
    else
        run_local_tests
    fi
}

main "$@"
