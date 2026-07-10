#!/bin/bash
#
# RDD Permission Management Library
# Implements RBAC (Role-Based Access Control) for RDD operations
#
# Usage: source this file to use permission functions
#
# Functions:
#   get_current_user    - Get the current user name
#   get_user_role       - Get the role for a user
#   get_role_priority   - Get the priority level for a role
#   has_permission      - Check if user has a permission
#   require_permission  - Fail if user lacks permission
#   list_permissions    - List all permissions for a user
#   load_permissions_config - Load permissions configuration
#

set -euo pipefail

# Configuration paths
RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PERMISSIONS_FILE="${RDD_DIR}/permissions.yml"
CACHE_DIR="${RDD_DIR}/cache"
PERMISSION_CACHE="${CACHE_DIR}/permission_cache.json"

# Permission levels (higher = more permissions)
readonly PERM_ADMIN=100
readonly PERM_DEVELOPER=50
readonly PERM_VIEWER=10
readonly PERM_NONE=0

# Default roles and their permissions
declare -A ROLE_PERMISSIONS=(
  ["admin"]="rdd:*"
  ["developer"]="rdd:stage:read rdd:stage:execute rdd:test:read rdd:test:execute rdd:doc:read rdd:doc:write rdd:hook:execute rdd:debt:read rdd:debt:write rdd:status:read"
  ["viewer"]="rdd:stage:read rdd:test:read rdd:doc:read rdd:status:read rdd:roadmap:read"
)

# Permission hierarchy (admin inherits from developer, developer from viewer)
declare -A ROLE_INHERITANCE=(
  ["admin"]="developer"
  ["developer"]="viewer"
  ["viewer"]=""
)

#######################################
# Initialize permissions system
#######################################
init_permissions() {
  mkdir -p "$CACHE_DIR"

  # Create default permissions config if not exists
  if [[ ! -f "$PERMISSIONS_FILE" ]]; then
    create_default_permissions_config
  fi
}

#######################################
# Create default permissions configuration
#######################################
create_default_permissions_config() {
  cat >"$PERMISSIONS_FILE" <<'EOF'
# RDD Permission Configuration
version: "1.0.0"

# RBAC Configuration
rbac:
  enabled: true

  # Role definitions
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
        - "rdd:hook:execute"
        - "rdd:debt:read"
        - "rdd:debt:write"
        - "rdd:status:read"
      priority: 50

    viewer:
      description: "Read-only access"
      permissions:
        - "rdd:stage:read"
        - "rdd:test:read"
        - "rdd:doc:read"
        - "rdd:status:read"
        - "rdd:roadmap:read"
      priority: 10

  # User assignments
  users:
    - username: "${RDD_ADMIN_USER:-admin}"
      role: admin
      source: env

    - username: "${RDD_DEVELOPER_USER:-developer}"
      role: developer
      source: env

  # Default role for unauthenticated users
  default_role: viewer

# Permission checking settings
checking:
  # Enable strict mode (deny by default)
  strict_mode: true

  # Cache permission checks for performance
  cache_enabled: true
  cache_ttl: 300

  # Log denied operations
  log_denied: true
EOF
  chmod 600 "$PERMISSIONS_FILE"
}

#######################################
# Get current user
# Returns: username from RDD_USER env or system USER
#######################################
get_current_user() {
  echo "${RDD_USER:-${USER:-unknown}}"
}

#######################################
# Load permissions configuration
# Returns: config content or empty
#######################################
load_permissions_config() {
  if [[ ! -f "$PERMISSIONS_FILE" ]]; then
    return 1
  fi
  cat "$PERMISSIONS_FILE"
}

#######################################
# Get a value from YAML config
# Arguments:
#   $1 - YAML path (e.g., "rbac.enabled")
#   $2 - default value
# Returns: value or default
#######################################
get_yaml_value() {
  local path="$1"
  local default="${2:-}"
  local file="$PERMISSIONS_FILE"

  if [[ ! -f "$file" ]]; then
    echo "$default"
    return 0
  fi

  if command -v yq &>/dev/null; then
    local value
    value=$(yq eval ".${path}" "$file" 2>/dev/null)
    # Return default if yq returns null or empty
    if [[ -z "$value" || "$value" == "null" ]]; then
      echo "$default"
    else
      echo "$value"
    fi
  else
    # Fallback: simple grep for top-level keys
    local key="${path##*.}"
    local value
    value=$(grep -E "^\s*${key}:" "$file" 2>/dev/null | head -1 | sed 's/[^:]*: *//' | tr -d '"')
    if [[ -z "$value" ]]; then
      echo "$default"
    else
      echo "$value"
    fi
  fi
}

#######################################
# Get user role
# Arguments:
#   $1 - username
# Returns: role name (admin, developer, viewer)
#######################################
get_user_role() {
  local user="$1"

  # Check if RBAC is enabled
  local rbac_enabled
  rbac_enabled=$(get_yaml_value "rbac.enabled" "false")

  if [[ "$rbac_enabled" != "true" ]]; then
    echo "admin"
    return 0
  fi

  # Check cache first
  local cache_enabled
  cache_enabled=$(get_yaml_value "checking.cache_enabled" "true")

  if [[ "$cache_enabled" == "true" && -f "$PERMISSION_CACHE" ]]; then
    local cached_role
    if command -v jq &>/dev/null; then
      cached_role=$(jq -r ".users[\"${user}\"] // empty" "$PERMISSION_CACHE" 2>/dev/null)
      if [[ -n "$cached_role" && "$cached_role" != "null" ]]; then
        echo "$cached_role"
        return 0
      fi
    fi
  fi

  # Load from permissions file
  local role=""

  if command -v yq &>/dev/null && [[ -f "$PERMISSIONS_FILE" ]]; then
    # Use yq to directly find the user's role
    # First, try exact match
    role=$(yq eval ".rbac.users[] | select(.username == \"$user\") | .role" "$PERMISSIONS_FILE" 2>/dev/null | head -1)

    # If not found, try with environment variable expansion
    if [[ -z "$role" || "$role" == "null" ]]; then
      # Get all usernames and expand environment variables
      while IFS= read -r entry; do
        local entry_user entry_role
        entry_user=$(echo "$entry" | yq eval '.username' - 2>/dev/null)
        entry_role=$(echo "$entry" | yq eval '.role' - 2>/dev/null)

        # Expand environment variables in username
        if [[ "$entry_user" =~ \$\{(.+)\} ]]; then
          local var_name="${BASH_REMATCH[1]}"
          entry_user="${!var_name:-$entry_user}"
        elif [[ "$entry_user" =~ \$([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
          local var_name="${BASH_REMATCH[1]}"
          entry_user="${!var_name:-$entry_user}"
        fi

        if [[ "$entry_user" == "$user" ]]; then
          role="$entry_role"
          break
        fi
      done < <(yq eval '.rbac.users[]' -o=json "$PERMISSIONS_FILE" 2>/dev/null | jq -c '.' 2>/dev/null || yq eval '.rbac.users' -o=json "$PERMISSIONS_FILE" 2>/dev/null | jq -c '.[]' 2>/dev/null)
    fi
  elif [[ -f "$PERMISSIONS_FILE" ]]; then
    # Fallback: simple grep-based parsing for users section
    local in_users_section=false
    while IFS= read -r line; do
      # Check if we're entering the users section
      if [[ "$line" =~ ^[[:space:]]*users: ]]; then
        in_users_section=true
        continue
      fi

      # Check if we're leaving the users section (another top-level key)
      if [[ "$in_users_section" == true && "$line" =~ ^[a-zA-Z] && ! "$line" =~ ^[[:space:]] ]]; then
        in_users_section=false
        break
      fi

      if [[ "$in_users_section" == true ]]; then
        # Look for username and role
        if [[ "$line" =~ username: ]]; then
          local entry_user
          entry_user=$(echo "$line" | sed 's/.*username:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')

          # Handle environment variable expansion
          if [[ "$entry_user" =~ \$\{(.+)\} ]]; then
            local var_name="${BASH_REMATCH[1]}"
            entry_user="${!var_name:-$entry_user}"
          elif [[ "$entry_user" =~ \$([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            entry_user="${!var_name:-$entry_user}"
          fi

          if [[ "$entry_user" == "$user" ]]; then
            # Look for role in the next line
            read -r role_line
            if [[ "$role_line" =~ role: ]]; then
              role=$(echo "$role_line" | sed 's/.*role:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')
              break
            fi
          fi
        fi
      fi
    done <"$PERMISSIONS_FILE"
  fi

  # Default role if not found
  if [[ -z "$role" || "$role" == "null" ]]; then
    role=$(get_yaml_value "rbac.default_role" "viewer")
  fi

  # Update cache
  if [[ "$cache_enabled" == "true" ]]; then
    update_permission_cache "$user" "$role"
  fi

  echo "${role:-viewer}"
}

#######################################
# Update permission cache
# Arguments:
#   $1 - username
#   $2 - role
#######################################
update_permission_cache() {
  local user="$1"
  local role="$2"

  mkdir -p "$CACHE_DIR"

  if [[ -f "$PERMISSION_CACHE" ]] && command -v jq &>/dev/null; then
    local tmp_file="${PERMISSION_CACHE}.tmp"
    jq ".users[\"${user}\"] = \"${role}\"" "$PERMISSION_CACHE" >"$tmp_file" 2>/dev/null &&
      mv "$tmp_file" "$PERMISSION_CACHE"
  else
    echo "{\"users\":{\"${user}\":\"${role}\"}}" >"$PERMISSION_CACHE"
  fi
}

#######################################
# Get role priority
# Arguments:
#   $1 - role name
# Returns: priority number (100=admin, 50=developer, 10=viewer)
#######################################
get_role_priority() {
  local role="$1"

  case "$role" in
    admin) echo $PERM_ADMIN ;;
    developer) echo $PERM_DEVELOPER ;;
    viewer) echo $PERM_VIEWER ;;
    *) echo $PERM_NONE ;;
  esac
}

#######################################
# Get permissions for a role
# Arguments:
#   $1 - role name
# Returns: space-separated list of permissions
#######################################
get_role_permissions() {
  local role="$1"

  if command -v yq &>/dev/null && [[ -f "$PERMISSIONS_FILE" ]]; then
    yq eval ".rbac.roles[\"${role}\"].permissions[]" "$PERMISSIONS_FILE" 2>/dev/null | tr '\n' ' '
  else
    # Fallback to built-in permissions based on role
    case "$role" in
      admin)
        echo "rdd:*"
        ;;
      developer)
        echo "rdd:stage:read rdd:stage:execute rdd:test:read rdd:test:execute rdd:doc:read rdd:doc:write rdd:hook:execute rdd:debt:read rdd:debt:write rdd:status:read"
        ;;
      viewer)
        echo "rdd:stage:read rdd:test:read rdd:doc:read rdd:status:read rdd:roadmap:read"
        ;;
      *)
        echo ""
        ;;
    esac
  fi
}

#######################################
# Check if a permission matches a pattern
# Arguments:
#   $1 - permission to check (e.g., "rdd:stage:execute")
#   $2 - pattern to match against (e.g., "rdd:*" or "rdd:stage:*")
# Returns: 0 if matches, 1 if not
#######################################
permission_matches() {
  local permission="$1"
  local pattern="$2"

  # Exact match
  if [[ "$permission" == "$pattern" ]]; then
    return 0
  fi

  # Wildcard match
  if [[ "$pattern" == *"*" ]]; then
    local prefix="${pattern%\*}"
    if [[ "$permission" == "$prefix"* ]]; then
      return 0
    fi
  fi

  return 1
}

#######################################
# Check if user has permission
# Arguments:
#   $1 - operation (e.g., "rdd:stage:execute")
#   $2 - username (optional, defaults to current user)
# Returns: 0 if permitted, 1 if denied
#######################################
has_permission() {
  local operation="$1"
  local user="${2:-$(get_current_user)}"

  # Check if RBAC is enabled
  local rbac_enabled
  rbac_enabled=$(get_yaml_value "rbac.enabled" "false")

  if [[ "$rbac_enabled" != "true" ]]; then
    # RBAC disabled, allow all
    return 0
  fi

  local role
  role=$(get_user_role "$user")

  # Admin has all permissions
  if [[ "$role" == "admin" ]]; then
    return 0
  fi

  # Get permissions for this role
  local permissions
  permissions=$(get_role_permissions "$role")

  # Check each permission
  for perm in $permissions; do
    if permission_matches "$operation" "$perm"; then
      return 0
    fi
  done

  # Check inherited roles
  local inherited_role=""
  case "$role" in
    admin) inherited_role="developer" ;;
    developer) inherited_role="viewer" ;;
    *) inherited_role="" ;;
  esac

  if [[ -n "$inherited_role" ]]; then
    local inherited_perms
    inherited_perms=$(get_role_permissions "$inherited_role")
    for perm in $inherited_perms; do
      if permission_matches "$operation" "$perm"; then
        return 0
      fi
    done
  fi

  # Permission denied
  local log_denied
  log_denied=$(get_yaml_value "checking.log_denied" "true")

  if [[ "$log_denied" == "true" ]]; then
    # Log the denial if audit.sh is available
    if declare -f log_audit &>/dev/null; then
      log_audit "PERMISSION_DENIED" "user=$user operation=$operation role=$role"
    fi
  fi

  return 1
}

#######################################
# Require permission (fail if not authorized)
# Arguments:
#   $1 - operation (e.g., "rdd:stage:execute")
#   $2 - username (optional, defaults to current user)
# Exits: 1 if permission denied
#######################################
require_permission() {
  local operation="$1"
  local user="${2:-$(get_current_user)}"

  if ! has_permission "$operation" "$user"; then
    echo "[ERROR] Permission denied: user '$user' cannot perform '$operation'" >&2
    echo "  Role: $(get_user_role "$user")" >&2
    echo "  Required permission: $operation" >&2
    exit 1
  fi
}

#######################################
# List user permissions
# Arguments:
#   $1 - username (optional, defaults to current user)
# Output: User, role, and list of permissions
#######################################
list_permissions() {
  local user="${1:-$(get_current_user)}"
  local role
  role=$(get_user_role "$user")

  echo "User: $user"
  echo "Role: $role"
  echo "Priority: $(get_role_priority "$role")"
  echo ""
  echo "Permissions:"

  local permissions
  permissions=$(get_role_permissions "$role")

  if [[ -n "$permissions" ]]; then
    for perm in $permissions; do
      echo "  - $perm"
    done
  else
    echo "  (none)"
  fi

  # Show inherited permissions
  local inherited_role=""
  case "$role" in
    admin) inherited_role="developer" ;;
    developer) inherited_role="viewer" ;;
    *) inherited_role="" ;;
  esac
  if [[ -n "$inherited_role" ]]; then
    echo ""
    echo "Inherited from $inherited_role:"
    local inherited_perms
    inherited_perms=$(get_role_permissions "$inherited_role")
    for perm in $inherited_perms; do
      echo "  - $perm"
    done
  fi
}

#######################################
# Clear permission cache
#######################################
clear_permission_cache() {
  if [[ -f "$PERMISSION_CACHE" ]]; then
    rm -f "$PERMISSION_CACHE"
  fi
}

#######################################
# Check if user is admin
# Arguments:
#   $1 - username (optional)
# Returns: 0 if admin, 1 if not
#######################################
is_admin() {
  local user="${1:-$(get_current_user)}"
  local role
  role=$(get_user_role "$user")
  [[ "$role" == "admin" ]]
}

#######################################
# Check if user is developer or above
# Arguments:
#   $1 - username (optional)
# Returns: 0 if developer+, 1 if not
#######################################
is_developer() {
  local user="${1:-$(get_current_user)}"
  local role
  role=$(get_user_role "$user")
  local priority
  priority=$(get_role_priority "$role")
  [[ $priority -ge $PERM_DEVELOPER ]]
}

#######################################
# Check if user is viewer or above
# Arguments:
#   $1 - username (optional)
# Returns: 0 if viewer+, 1 if not
#######################################
is_viewer() {
  local user="${1:-$(get_current_user)}"
  local role
  role=$(get_user_role "$user")
  local priority
  priority=$(get_role_priority "$role")
  [[ $priority -ge $PERM_VIEWER ]]
}

# Initialize on source
init_permissions

# Export functions for use in subshells
export -f get_current_user get_user_role get_role_priority has_permission
export -f require_permission list_permissions clear_permission_cache
export -f is_admin is_developer is_viewer get_yaml_value
export -f permission_matches get_role_permissions update_permission_cache
export -f init_permissions create_default_permissions_config load_permissions_config
