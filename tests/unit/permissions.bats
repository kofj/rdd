#!/usr/bin/env bats
#
# Unit tests for RDD Permission Management (permissions.sh)
# Tests RBAC implementation, permission checking, and role management
#

# Load bats-core (no additional helpers needed)

# Setup
setup() {
    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)
    RDD_DIR="$TEST_DIR/.rdd"

    mkdir -p "$RDD_DIR/cache"
    mkdir -p "$RDD_DIR/lib"

    # Create minimal permissions config that works without yq
    # Use built-in permissions when yq is not available
    cat > "$RDD_DIR/permissions.yml" << 'EOF'
version: "1.0.0"
rbac:
  enabled: true
  roles:
    admin:
      description: "Full administrative access"
      permissions:
        - "rdd:*"
      priority: 100
    developer:
      description: "Development operations access"
      permissions:
        - "rdd:stage:read"
        - "rdd:stage:execute"
        - "rdd:test:read"
        - "rdd:test:execute"
        - "rdd:doc:read"
        - "rdd:doc:write"
      priority: 50
    viewer:
      description: "Read-only access"
      permissions:
        - "rdd:stage:read"
        - "rdd:doc:read"
      priority: 10
  users:
    - username: "admin_user"
      role: admin
    - username: "dev_user"
      role: developer
    - username: "viewer_user"
      role: viewer
  default_role: viewer
checking:
  strict_mode: true
  cache_enabled: true
  log_denied: true
EOF

    # Source the permissions library
    export RDD_DIR
    source "${BATS_TEST_DIRNAME}/../../.rdd/lib/permissions.sh"
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

#######################################
# Test: Initialization
#######################################

@test "init_permissions creates necessary directories" {
    rm -rf "$RDD_DIR/cache"
    init_permissions
    [ -d "$RDD_DIR/cache" ]
}

@test "init_permissions creates default config if not exists" {
    rm -f "$RDD_DIR/permissions.yml"
    init_permissions
    [ -f "$RDD_DIR/permissions.yml" ]
}

@test "init_permissions config has correct permissions" {
    rm -f "$RDD_DIR/permissions.yml"
    init_permissions
    local perms
    perms=$(stat -c "%a" "$RDD_DIR/permissions.yml" 2>/dev/null || stat -f "%Lp" "$RDD_DIR/permissions.yml" 2>/dev/null)
    [ "$perms" == "600" ]
}

#######################################
# Test: User Management
#######################################

@test "get_current_user returns RDD_USER if set" {
    export RDD_USER="test_user"
    [ "$(get_current_user)" == "test_user" ]
}

@test "get_current_user returns USER if RDD_USER not set" {
    unset RDD_USER
    local user
    user=$(get_current_user)
    [ -n "$user" ]
}

@test "get_user_role returns correct role for admin" {
    [ "$(get_user_role "admin_user")" == "admin" ]
}

@test "get_user_role returns correct role for developer" {
    [ "$(get_user_role "dev_user")" == "developer" ]
}

@test "get_user_role returns correct role for viewer" {
    [ "$(get_user_role "viewer_user")" == "viewer" ]
}

@test "get_user_role returns default role for unknown user" {
    [ "$(get_user_role "unknown_user")" == "viewer" ]
}

#######################################
# Test: Role Priority
#######################################

@test "get_role_priority returns 100 for admin" {
    [ "$(get_role_priority "admin")" == "100" ]
}

@test "get_role_priority returns 50 for developer" {
    [ "$(get_role_priority "developer")" == "50" ]
}

@test "get_role_priority returns 10 for viewer" {
    [ "$(get_role_priority "viewer")" == "10" ]
}

@test "get_role_priority returns 0 for unknown role" {
    [ "$(get_role_priority "unknown")" == "0" ]
}

#######################################
# Test: Permission Checking
#######################################

@test "has_permission returns 0 for admin with any permission" {
    has_permission "rdd:stage:execute" "admin_user"
}

@test "has_permission returns 0 for admin with wildcard permission" {
    has_permission "rdd:any:permission" "admin_user"
}

@test "has_permission returns 0 for developer with allowed permission" {
    has_permission "rdd:stage:execute" "dev_user"
}

@test "has_permission returns 1 for developer with denied permission" {
    ! has_permission "rdd:config:write" "dev_user"
}

@test "has_permission returns 0 for viewer with read permission" {
    has_permission "rdd:stage:read" "viewer_user"
}

@test "has_permission returns 1 for viewer with execute permission" {
    ! has_permission "rdd:stage:execute" "viewer_user"
}

@test "has_permission returns 0 for unknown user with read permission" {
    # Unknown user gets viewer role
    has_permission "rdd:stage:read" "unknown_user"
}

@test "has_permission returns 1 for unknown user with write permission" {
    ! has_permission "rdd:stage:execute" "unknown_user"
}

#######################################
# Test: Permission Patterns
#######################################

@test "permission_matches exact match" {
    permission_matches "rdd:stage:read" "rdd:stage:read"
}

@test "permission_matches wildcard match" {
    permission_matches "rdd:stage:read" "rdd:*"
}

@test "permission_matches partial wildcard match" {
    permission_matches "rdd:stage:execute" "rdd:stage:*"
}

@test "permission_matches no match" {
    ! permission_matches "rdd:stage:execute" "rdd:config:*"
}

#######################################
# Test: require_permission
#######################################

@test "require_permission succeeds with permission" {
    run require_permission "rdd:stage:read" "admin_user"
    [ "$status" == "0" ]
}

@test "require_permission fails without permission" {
    run require_permission "rdd:config:write" "viewer_user"
    [ "$status" == "1" ]
    [[ "$output" == *"Permission denied"* ]]
}

#######################################
# Test: Role Checking
#######################################

@test "is_admin returns 0 for admin user" {
    is_admin "admin_user"
}

@test "is_admin returns 1 for non-admin user" {
    ! is_admin "dev_user"
}

@test "is_developer returns 0 for developer user" {
    is_developer "dev_user"
}

@test "is_developer returns 0 for admin user (inherits)" {
    is_developer "admin_user"
}

@test "is_developer returns 1 for viewer user" {
    ! is_developer "viewer_user"
}

@test "is_viewer returns 0 for viewer user" {
    is_viewer "viewer_user"
}

@test "is_viewer returns 0 for developer user (inherits)" {
    is_viewer "dev_user"
}

@test "is_viewer returns 0 for admin user (inherits)" {
    is_viewer "admin_user"
}

#######################################
# Test: List Permissions
#######################################

@test "list_permissions shows user role" {
    run list_permissions "admin_user"
    [[ "$output" == *"Role: admin"* ]]
}

@test "list_permissions shows permissions for role" {
    run list_permissions "dev_user"
    [[ "$output" == *"rdd:stage:read"* ]]
    [[ "$output" == *"rdd:stage:execute"* ]]
}

#######################################
# Test: Cache
#######################################

@test "clear_permission_cache removes cache file" {
    # Create cache
    get_user_role "admin_user"
    [ -f "$RDD_DIR/cache/permission_cache.json" ]

    # Clear cache
    clear_permission_cache
    [ ! -f "$RDD_DIR/cache/permission_cache.json" ]
}

@test "permission cache is populated after first check" {
    [ ! -f "$RDD_DIR/cache/permission_cache.json" ]
    get_user_role "admin_user"
    [ -f "$RDD_DIR/cache/permission_cache.json" ]
}

#######################################
# Test: RBAC Disabled
#######################################

@test "has_permission returns 0 when RBAC disabled" {
    # Modify config to disable RBAC
    cat > "$RDD_DIR/permissions.yml" << 'EOF'
version: "1.0.0"
rbac:
  enabled: false
  roles:
    viewer:
      permissions:
        - "rdd:stage:read"
  default_role: viewer
EOF

    # Should allow all when RBAC disabled
    has_permission "rdd:any:permission" "unknown_user"
}

#######################################
# Test: Edge Cases
#######################################

@test "empty user defaults to current user" {
    export RDD_USER="test_user"
    [ "$(get_user_role "")" == "viewer" ]
}

@test "special characters in username are handled" {
    run get_user_role "user@example.com"
    [ "$status" == "0" ]
}

@test "concurrent permission checks work" {
    # Run multiple permission checks
    for i in {1..10}; do
        has_permission "rdd:stage:read" "dev_user" &
    done
    wait
}

@test "permission check with long permission name" {
    has_permission "rdd:very:long:permission:name:that:goes:on" "admin_user"
}

@test "permission check with special characters in permission" {
    has_permission "rdd:stage-read_test" "admin_user"
}
