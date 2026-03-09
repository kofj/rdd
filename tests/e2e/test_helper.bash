#!/usr/bin/env bash
#
# Test helper for E2E tests
# Provides common functions and setup for bats tests
#

# Get project root directory
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Export for bats tests
export PROJECT_ROOT

# Create a temporary test directory
create_test_dir() {
    local test_dir
    test_dir="$(mktemp -d)"
    echo "$test_dir"
}

# Cleanup test directory
cleanup_test_dir() {
    local test_dir="$1"
    if [[ -d "$test_dir" ]]; then
        rm -rf "$test_dir"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Wait for a condition with timeout
wait_for() {
    local timeout="${1}"
    local condition="${2}"
    local interval="${3:-1}"

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if eval "$condition"; then
            return 0
        fi
        sleep "$interval"
        ((elapsed += interval))
    done
    return 1
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file to exist: $file"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Expected directory to exist: $dir"
        return 1
    fi
}

# Assert file contains
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    if ! grep -q "$pattern" "$file"; then
        echo "Expected file $file to contain: $pattern"
        return 1
    fi
}
