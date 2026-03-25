#!/bin/bash
#
# RDD Security Utilities Library
# Input validation, injection prevention, and security checks
#
# Usage: source this file to use security functions
#
# Functions:
#   validate_input       - Validate input against injection patterns
#   sanitize_input       - Sanitize input for safe use
#   escape_yaml          - Escape special YAML characters
#   escape_json          - Escape special JSON characters
#   secure_read_file     - Securely read a file
#   secure_write_file    - Securely write a file
#   validate_path        - Validate a file path
#   is_safe_command      - Check if command is safe to execute
#

set -euo pipefail

#######################################
# Helper: Check if string contains null bytes
# Returns: 0 if null byte found, 1 if not
# Note: Bash strings cannot contain null bytes, so we check
#       by comparing length before/after removing null bytes
#######################################
_has_null_byte() {
    local input="$1"
    # If input is empty, no null byte
    if [[ -z "$input" ]]; then
        return 1
    fi
    # Compare length: original vs after removing null bytes
    # Using printf to handle the string properly
    local orig_len=${#input}
    local clean_len
    clean_len=$(printf '%s' "$input" | tr -d '\0' | wc -c)
    # If lengths differ, null bytes were removed
    [[ $clean_len -lt $orig_len ]]
}

#######################################
# Log functions
#######################################
log_security_warn() {
    echo "[SECURITY WARN] $*" >&2
}

log_security_error() {
    echo "[SECURITY ERROR] $*" >&2
}

#######################################
# Validate input against injection patterns
# Arguments:
#   $1 - input to validate
#   $2 - type (alphanumeric, path, command, url, email, integer, text)
# Returns: 0 if valid, 1 if invalid
#######################################
validate_input() {
    local input="$1"
    local type="${2:-text}"

    if [[ -z "$input" ]]; then
        return 0  # Empty input is valid
    fi

    case "$type" in
        alphanumeric)
            # Only alphanumeric, underscore, and hyphen
            if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                log_security_error "Invalid alphanumeric input: contains special characters"
                return 1
            fi
            ;;

        alphanumeric_extended)
            # Alphanumeric plus common safe characters
            if [[ ! "$input" =~ ^[a-zA-Z0-9_.@+-]+$ ]]; then
                log_security_error "Invalid input: contains unsafe characters"
                return 1
            fi
            ;;

        path)
            # Prevent path traversal
            if [[ "$input" == *".."* ]]; then
                log_security_error "Invalid path: path traversal detected"
                return 1
            fi

            # Check for null bytes
            if _has_null_byte "$input"; then
                log_security_error "Invalid path: null byte detected"
                return 1
            fi

            # Check for shell special characters in path
            if [[ "$input" == *'$('* || "$input" == *'`'* || "$input" == *'${'* ]]; then
                log_security_error "Invalid path: shell expansion detected"
                return 1
            fi
            ;;

        command|cmd)
            # Check for command injection patterns
            local dangerous_patterns=(
                ';'     # Command separator
                '\|'    # Pipe
                '&'     # Background/AND
                '\$\('  # Command substitution
                '`'     # Backticks
                '\$\{'  # Variable expansion
                '&&'    # AND
                '\|\|'  # OR (escaped for regex)
                '>'     # Redirect
                '<'     # Redirect
                '>>'    # Append
                '<<'    # Here-doc
                '\$(('  # Arithmetic expansion
            )

            for pattern in "${dangerous_patterns[@]}"; do
                if [[ "$input" =~ $pattern ]]; then
                    log_security_error "Invalid command: potential injection detected (pattern: $pattern)"
                    return 1
                fi
            done
            ;;

        url)
            # Validate URL format
            if [[ ! "$input" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
                log_security_error "Invalid URL format"
                return 1
            fi

            # Check for javascript: protocol
            if [[ "$input" =~ ^[jJ]ava[sS]cript: ]]; then
                log_security_error "Invalid URL: javascript protocol not allowed"
                return 1
            fi

            # Check for data: protocol
            if [[ "$input" =~ ^[dD]ata: ]]; then
                log_security_error "Invalid URL: data protocol not allowed"
                return 1
            fi
            ;;

        email)
            # Validate email format
            if [[ ! "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                log_security_error "Invalid email format"
                return 1
            fi
            ;;

        integer|int)
            # Validate integer
            if [[ ! "$input" =~ ^-?[0-9]+$ ]]; then
                log_security_error "Invalid integer"
                return 1
            fi
            ;;

        positive_int)
            # Validate positive integer
            if [[ ! "$input" =~ ^[0-9]+$ ]] || [[ "$input" -le 0 ]]; then
                log_security_error "Invalid positive integer"
                return 1
            fi
            ;;

        float|number)
            # Validate float/number
            if [[ ! "$input" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
                log_security_error "Invalid number"
                return 1
            fi
            ;;

        boolean|bool)
            # Validate boolean
            local lower
            lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
            if [[ ! "$lower" =~ ^(true|false|yes|no|1|0|on|off)$ ]]; then
                log_security_error "Invalid boolean value"
                return 1
            fi
            ;;

        text)
            # Basic text validation - no control characters
            if [[ "$input" == *$'\n'* ]] || [[ "$input" == *$'\r'* ]]; then
                log_security_error "Invalid text: control characters detected"
                return 1
            fi

            # Check for null byte
            if _has_null_byte "$input"; then
                log_security_error "Invalid text: null byte detected"
                return 1
            fi
            ;;

        multiline)
            # Allow newlines but no other control characters
            # Check for null byte
            if _has_null_byte "$input"; then
                log_security_error "Invalid text: null byte detected"
                return 1
            fi
            ;;

        identifier|id)
            # Valid identifier: starts with letter, alphanumeric + underscore
            if [[ ! "$input" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                log_security_error "Invalid identifier: must start with letter and contain only alphanumeric/underscore"
                return 1
            fi
            ;;

        filename|file)
            # Validate filename (no path separators, no special chars)
            if [[ "$input" == *"/"* || "$input" == *"\\"* ]]; then
                log_security_error "Invalid filename: path separators not allowed"
                return 1
            fi

            if [[ "$input" == ".." || "$input" == "." ]]; then
                log_security_error "Invalid filename: . and .. not allowed"
                return 1
            fi

            # Check for null byte
            if _has_null_byte "$input"; then
                log_security_error "Invalid filename: null byte detected"
                return 1
            fi
            ;;

        *)
            log_security_error "Unknown validation type: $type"
            return 1
            ;;
    esac

    return 0
}

#######################################
# Sanitize input for safe use
# Arguments:
#   $1 - input to sanitize
#   $2 - context (shell, yaml, json, html) - optional
# Returns: sanitized input
#######################################
sanitize_input() {
    local input="$1"
    local context="${2:-shell}"

    if [[ -z "$input" ]]; then
        echo ""
        return 0
    fi

    local sanitized="$input"

    case "$context" in
        shell)
            # Remove dangerous shell characters
            sanitized="${sanitized//;/}"
            sanitized="${sanitized//|/}"
            sanitized="${sanitized//&/}"
            sanitized="${sanitized//\$/}"
            sanitized="${sanitized//\`/}"
            sanitized="${sanitized//\(/}"
            sanitized="${sanitized//\)/}"
            sanitized="${sanitized//</}"
            sanitized="${sanitized//>/}"
            ;;

        yaml)
            # Escape YAML special characters
            sanitized="${sanitized//\\/\\\\}"
            sanitized="${sanitized//\"/\\\"}"
            sanitized="${sanitized//$'\n'/\\n}"
            ;;

        json)
            # Escape JSON special characters
            sanitized="${sanitized//\\/\\\\}"
            sanitized="${sanitized//\"/\\\"}"
            sanitized="${sanitized//$'\n'/\\n}"
            sanitized="${sanitized//$'\t'/\\t}"
            sanitized="${sanitized//$'\r'/\\r}"
            ;;

        html)
            # Escape HTML special characters
            # Use sed for reliable cross-platform behavior
            sanitized=$(echo "$sanitized" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
            ;;

        *)
            # Default: just remove control characters
            sanitized="${sanitized//$'\0'/}"
            ;;
    esac

    echo "$sanitized"
}

#######################################
# Escape for YAML
# Arguments:
#   $1 - input string
# Returns: YAML-escaped string
#######################################
escape_yaml() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo ""
        return 0
    fi

    # Escape backslashes and quotes
    local escaped="${input//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"

    # If string contains special YAML characters, wrap in quotes
    if [[ "$escaped" == *":"* || "$escaped" == *"#"* || "$escaped" == *"-"* || "$escaped" == *$'\n'* ]]; then
        escaped="${escaped//$'\n'/\\n}"
        echo "\"$escaped\""
    else
        echo "$escaped"
    fi
}

#######################################
# Escape for JSON
# Arguments:
#   $1 - input string
# Returns: JSON-escaped string
#######################################
escape_json() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo ""
        return 0
    fi

    # Escape special JSON characters
    local escaped="${input//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    escaped="${escaped//$'\n'/\\n}"
    escaped="${escaped//$'\t'/\\t}"
    escaped="${escaped//$'\r'/\\r}"

    echo "$escaped"
}

#######################################
# Validate a file path
# Arguments:
#   $1 - path to validate
#   $2 - base directory (optional, for restricting paths)
#   $3 - must_exist (true/false, optional)
# Returns: 0 if valid, 1 if invalid
#######################################
validate_path() {
    local path="$1"
    local base_dir="${2:-}"
    local must_exist="${3:-false}"

    # Check for path traversal
    if [[ "$path" == *".."* ]]; then
        log_security_error "Path traversal detected: $path"
        return 1
    fi

    # Check for null bytes
    if _has_null_byte "$path"; then
        log_security_error "Null byte in path: $path"
        return 1
    fi

    # Resolve to absolute path
    local abs_path
    if [[ "$path" == /* ]]; then
        abs_path="$path"
    else
        abs_path="$(pwd)/$path"
    fi

    # Normalize path (remove . and redundant /)
    abs_path=$(cd "$(dirname "$abs_path")" 2>/dev/null && pwd)/$(basename "$abs_path") 2>/dev/null || abs_path="$path"

    # Check if path is within base directory
    if [[ -n "$base_dir" ]]; then
        local abs_base
        abs_base=$(cd "$base_dir" 2>/dev/null && pwd) || abs_base="$base_dir"

        if [[ "$abs_path" != "$abs_base"* ]]; then
            log_security_error "Path outside base directory: $path"
            return 1
        fi
    fi

    # Check if file must exist
    if [[ "$must_exist" == "true" && ! -e "$path" ]]; then
        log_security_error "Path does not exist: $path"
        return 1
    fi

    return 0
}

#######################################
# Secure file read
# Arguments:
#   $1 - file path
# Returns: file contents
#######################################
secure_read_file() {
    local filepath="$1"

    # Validate path
    if ! validate_path "$filepath"; then
        return 1
    fi

    # Check file exists
    if [[ ! -f "$filepath" ]]; then
        log_security_error "File not found: $filepath"
        return 1
    fi

    # Check file is readable
    if [[ ! -r "$filepath" ]]; then
        log_security_error "File not readable: $filepath"
        return 1
    fi

    # Check file permissions (warn if world-readable)
    local perms
    if [[ -e "$filepath" ]]; then
        perms=$(stat -c "%a" "$filepath" 2>/dev/null || stat -f "%Lp" "$filepath" 2>/dev/null || echo "644")
        if [[ "$((perms & 004))" -ne 0 ]]; then
            log_security_warn "File is world-readable: $filepath (permissions: $perms)"
        fi
    fi

    # Read file
    cat "$filepath"
}

#######################################
# Secure file write
# Arguments:
#   $1 - file path
#   $2 - content to write
#   $3 - permissions (optional, default 600)
#######################################
secure_write_file() {
    local filepath="$1"
    local content="$2"
    local permissions="${3:-600}"

    # Validate path
    if ! validate_path "$filepath"; then
        return 1
    fi

    # Create directory if needed
    local dir
    dir=$(dirname "$filepath")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chmod 700 "$dir"
    fi

    # Write to temp file first
    local tmp_file="${filepath}.tmp.$$"
    echo "$content" > "$tmp_file"

    # Set permissions before moving
    chmod "$permissions" "$tmp_file"

    # Move to final location (atomic)
    mv "$tmp_file" "$filepath"
}

#######################################
# Check if a command is safe to execute
# Arguments:
#   $1 - command name
# Returns: 0 if safe, 1 if unsafe
#######################################
is_safe_command() {
    local cmd="$1"

    # List of safe commands
    local safe_commands=(
        "ls" "cat" "head" "tail" "grep" "sed" "awk" "cut"
        "sort" "uniq" "wc" "tr" "echo" "printf"
        "mkdir" "touch" "cp" "mv" "chmod" "chown"
        "date" "basename" "dirname" "pwd" "whoami"
        "git" "task" "bats"
        "jq" "yq"
    )

    # List of dangerous commands
    local dangerous_commands=(
        "rm" "rmdir" "dd" "mkfs" "fdisk" "format"
        "shutdown" "reboot" "halt" "poweroff"
        "useradd" "userdel" "usermod" "passwd"
        "visudo" "su" "sudo"
        "eval" "exec"
        "curl" "wget"  # Should be controlled
    )

    # Check safe list
    for safe in "${safe_commands[@]}"; do
        if [[ "$cmd" == "$safe" ]]; then
            return 0
        fi
    done

    # Check dangerous list
    for dangerous in "${dangerous_commands[@]}"; do
        if [[ "$cmd" == "$dangerous" ]]; then
            log_security_warn "Potentially dangerous command: $cmd"
            return 1
        fi
    done

    # Command not in any list, require explicit approval
    log_security_warn "Unknown command: $cmd (not in safe list)"
    return 1
}

#######################################
# Generate a secure random token
# Arguments:
#   $1 - length (default: 32)
# Returns: random token
#######################################
generate_secure_token() {
    local length="${1:-64}"  # Default to 64 hex chars (32 bytes)

    if command -v openssl &> /dev/null; then
        # openssl rand -hex N outputs 2*N hex characters (N bytes)
        # To get 'length' hex characters, we need length/2 bytes
        local bytes=$((length / 2))
        openssl rand -hex "$bytes" 2>/dev/null
    else
        # Fallback: use /dev/urandom
        tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c "$length"
    fi
}

#######################################
# Check password strength
# Arguments:
#   $1 - password to check
# Returns: 0 if strong enough, 1 if weak
#######################################
check_password_strength() {
    local password="$1"
    local min_length="${2:-12}"

    # Check length
    if [[ ${#password} -lt $min_length ]]; then
        log_security_error "Password too short (minimum: $min_length characters)"
        return 1
    fi

    # Check for uppercase
    if [[ ! "$password" =~ [A-Z] ]]; then
        log_security_error "Password must contain uppercase letters"
        return 1
    fi

    # Check for lowercase
    if [[ ! "$password" =~ [a-z] ]]; then
        log_security_error "Password must contain lowercase letters"
        return 1
    fi

    # Check for numbers
    if [[ ! "$password" =~ [0-9] ]]; then
        log_security_error "Password must contain numbers"
        return 1
    fi

    # Check for special characters
    if [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
        log_security_error "Password must contain special characters"
        return 1
    fi

    return 0
}

#######################################
# Redact sensitive data from string
# Arguments:
#   $1 - input string
# Returns: string with sensitive data redacted
#######################################
redact_sensitive() {
    local input="$1"

    # Redact common sensitive patterns
    local result="$input"

    # Passwords
    result=$(echo "$result" | sed -E 's/(password|passwd|pwd)[=:][^ ]+/\1=***REDACTED***/gi')

    # Tokens
    result=$(echo "$result" | sed -E 's/(token|api_key|apikey|secret)[=:][^ ]+/\1=***REDACTED***/gi')

    # Credentials in URLs
    result=$(echo "$result" | sed -E 's|(https?://)([^:]+):([^@]+)@|\1***:***@|g')

    echo "$result"
}

# Note: Functions are available when script is sourced
# No export needed for library usage
