#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-rdd-test}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-rdd-test-$$}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_step() { echo -e "${BLUE}==>${NC} $*"; }

build_image() {
    log_step "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."
    docker build -f "${PROJECT_ROOT}/docker/Dockerfile.test" -t "${IMAGE_NAME}:${IMAGE_TAG}" "${PROJECT_ROOT}"
    log_info "Image built successfully"
}

run_container() {
    local command="${1:-test}"
    log_step "Running tests in container..."
    docker run --rm --name "${CONTAINER_NAME}" -v "${PROJECT_ROOT}:/workspace" "${IMAGE_NAME}:${IMAGE_TAG}" "${command}"
}

main() {
    local command="${1:-test}"
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed"
        exit 1
    fi

    build_image

    case "${command}" in
        build) log_info "Image built: ${IMAGE_NAME}:${IMAGE_TAG}" ;;
        shell) docker run --rm -it --name "${CONTAINER_NAME}" -v "${PROJECT_ROOT}:/workspace" "${IMAGE_NAME}:${IMAGE_TAG}" shell ;;
        *) run_container "${command}" ;;
    esac
}

main "$@"
