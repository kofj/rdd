#!/bin/bash
#
# Kind E2E Test Runner
# Runs RDD Framework tests in a clean Kind cluster
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  local missing=0

  if ! command -v kind &>/dev/null; then
    log_error "kind is not installed"
    missing=1
  fi

  if ! command -v kubectl &>/dev/null; then
    log_error "kubectl is not installed"
    missing=1
  fi

  if ! command -v docker &>/dev/null; then
    log_error "docker is not installed"
    missing=1
  fi

  if [[ $missing -eq 1 ]]; then
    log_error "Please install missing prerequisites"
    exit 1
  fi

  log_info "All prerequisites satisfied"
}

# Create Kind cluster
create_cluster() {
  log_info "Creating Kind cluster..."

  if kind get clusters 2>/dev/null | grep -q "rdd-test-cluster"; then
    log_warn "Cluster rdd-test-cluster already exists, deleting..."
    kind delete cluster --name rdd-test-cluster
  fi

  kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"

  log_info "Kind cluster created successfully"
}

# Run tests in Kind
run_tests() {
  log_info "Running tests in Kind cluster..."

  # Create test pod
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: rdd-test-runner
  namespace: default
spec:
  containers:
  - name: test-runner
    image: bats/bats:latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      apk add --no-cache bash curl git jq
      cd /rdd-framework
      echo "=== Running Unit Tests ==="
      bats tests/unit/
      echo "=== Running BDD Tests ==="
      bats tests/bdd/
      echo "=== Running E2E Tests ==="
      bats tests/e2e/
    volumeMounts:
    - name: rdd-code
      mountPath: /rdd-framework
    env:
    - name: RDD_PROJECT_NAME
      value: "KindTest"
    - name: DRY_RUN
      value: "true"
  volumes:
  - name: rdd-code
    hostPath:
      path: ${PROJECT_ROOT}
      type: Directory
  restartPolicy: Never
EOF

  # Wait for pod to complete
  log_info "Waiting for tests to complete..."
  kubectl wait --for=condition=Ready pod/rdd-test-runner --timeout=60s || true
  kubectl logs -f pod/rdd-test-runner || true

  # Get exit code
  local phase=$(kubectl get pod rdd-test-runner -o jsonpath='{.status.phase}')
  if [[ "$phase" == "Succeeded" ]]; then
    log_info "All tests passed in Kind cluster"
    return 0
  else
    log_error "Tests failed in Kind cluster"
    return 1
  fi
}

# Cleanup
cleanup() {
  log_info "Cleaning up..."

  kubectl delete pod rdd-test-runner --ignore-not-found=true

  if [[ "${CLEANUP_CLUSTER:-true}" == "true" ]]; then
    kind delete cluster --name rdd-test-cluster
  fi

  log_info "Cleanup complete"
}

# Main
main() {
  log_info "=== RDD Framework Kind E2E Tests ==="

  check_prerequisites
  create_cluster

  # Run tests
  local result=0
  run_tests || result=1

  cleanup

  if [[ $result -eq 0 ]]; then
    log_info "=== All Kind E2E tests passed ==="
  else
    log_error "=== Some Kind E2E tests failed ==="
  fi

  exit $result
}

# Run main
main "$@"
