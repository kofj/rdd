#!/bin/bash
#
# RDD Credential Encryption Utilities
# Provides encryption/decryption for sensitive data and data masking
#
# Usage: crypto.sh <command> [options]
#
# Commands:
#   generate-key              Generate a new encryption key
#   encrypt <data>            Encrypt data
#   decrypt <data>            Decrypt data
#   mask <value> [type]       Mask a sensitive value
#   check-vault               Check if Vault is available
#   get-secret <path> [key]   Get secret from Vault
#   store-secret <path> ...   Store secret in Vault
#
# Can also be sourced to use functions directly
#

set -euo pipefail

RDD_DIR="${RDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
KEY_DIR="${RDD_DIR}/.keys"
KEY_FILE="${KEY_DIR}/encryption.key"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################
# Log functions
#######################################
log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo "[DEBUG] $*"
  fi
}

#######################################
# Generate encryption key
# Creates a 256-bit AES key
#######################################
generate_key() {
  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"

  # Generate 256-bit (32 bytes) key
  if command -v openssl &>/dev/null; then
    openssl rand -hex 32 >"$KEY_FILE"
  else
    log_warn "openssl not found, using fallback key generation"
    # Fallback: use /dev/urandom
    head -c 32 /dev/urandom | base64 >"$KEY_FILE"
  fi

  chmod 600 "$KEY_FILE"
  log_info "Encryption key generated: $KEY_FILE"
  echo "$KEY_FILE"
}

#######################################
# Ensure key file exists
#######################################
ensure_key() {
  if [[ ! -f "$KEY_FILE" ]]; then
    log_warn "Encryption key not found, generating new key"
    generate_key
  fi
}

#######################################
# Encrypt data
# Arguments:
#   $1 - plaintext data to encrypt
#   $2 - key file (optional, defaults to KEY_FILE)
# Returns: encrypted data (base64 encoded)
#######################################
encrypt_data() {
  local plaintext="$1"
  local key_file="${2:-$KEY_FILE}"

  if [[ -z "$plaintext" ]]; then
    log_error "No data to encrypt"
    return 1
  fi

  ensure_key

  if [[ ! -f "$key_file" ]]; then
    log_error "Encryption key not found: $key_file"
    return 1
  fi

  local key
  key=$(cat "$key_file")

  if command -v openssl &>/dev/null; then
    # Use AES-256-CBC with PBKDF2 for key derivation
    echo "$plaintext" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -base64 2>/dev/null
  else
    log_error "openssl not available, encryption not supported"
    return 1
  fi
}

#######################################
# Decrypt data
# Arguments:
#   $1 - ciphertext (base64 encoded)
#   $2 - key file (optional, defaults to KEY_FILE)
# Returns: decrypted plaintext
#######################################
decrypt_data() {
  local ciphertext="$1"
  local key_file="${2:-$KEY_FILE}"

  if [[ -z "$ciphertext" ]]; then
    log_error "No data to decrypt"
    return 1
  fi

  if [[ ! -f "$key_file" ]]; then
    log_error "Encryption key not found: $key_file"
    return 1
  fi

  local key
  key=$(cat "$key_file")

  if command -v openssl &>/dev/null; then
    echo "$ciphertext" | openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$key" -base64 2>/dev/null
  else
    log_error "openssl not available, decryption not supported"
    return 1
  fi
}

#######################################
# Encrypt a file
# Arguments:
#   $1 - input file path
#   $2 - output file path (optional)
# Returns: path to encrypted file
#######################################
encrypt_file() {
  local input_file="$1"
  local output_file="${2:-${input_file}.enc}"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  ensure_key

  local key
  key=$(cat "$KEY_FILE")

  if command -v openssl &>/dev/null; then
    openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$key" -base64 -in "$input_file" -out "$output_file" 2>/dev/null
    chmod 600 "$output_file"
    log_info "File encrypted: $output_file"
    echo "$output_file"
  else
    log_error "openssl not available"
    return 1
  fi
}

#######################################
# Decrypt a file
# Arguments:
#   $1 - input file path (encrypted)
#   $2 - output file path (optional)
# Returns: path to decrypted file
#######################################
decrypt_file() {
  local input_file="$1"
  local output_file="${2:-${input_file%.enc}}"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  if [[ ! -f "$KEY_FILE" ]]; then
    log_error "Encryption key not found"
    return 1
  fi

  local key
  key=$(cat "$KEY_FILE")

  if command -v openssl &>/dev/null; then
    openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$key" -base64 -in "$input_file" -out "$output_file" 2>/dev/null
    log_info "File decrypted: $output_file"
    echo "$output_file"
  else
    log_error "openssl not available"
    return 1
  fi
}

#######################################
# Mask sensitive value
# Arguments:
#   $1 - value to mask
#   $2 - type (password, token, api_key, url, default)
#   $3 - show_first (optional, for custom masking)
#   $4 - show_last (optional, for custom masking)
# Returns: masked value
#######################################
mask_value() {
  local value="$1"
  local type="${2:-default}"
  local show_first="${3:-0}"
  local show_last="${4:-0}"

  if [[ -z "$value" ]]; then
    echo ""
    return 0
  fi

  local len=${#value}

  case "$type" in
    password | pass | pwd)
      # Always fully mask passwords
      echo "********"
      ;;

    token)
      # Show first 4 and last 4 characters
      if [[ $len -gt 8 ]]; then
        echo "${value:0:4}****${value: -4}"
      else
        echo "********"
      fi
      ;;

    api_key | apikey)
      # Show first 8 characters then mask rest with ...
      if [[ $len -gt 8 ]]; then
        echo "${value:0:8}..."
      else
        echo "$value"
      fi
      ;;

    secret | credential | cred)
      # Always fully mask secrets
      echo "[REDACTED]"
      ;;

    url | webhook)
      # Mask credentials in URL
      # Pattern: http://user:pass@host -> http://***:***@host
      echo "$value" | sed -E 's|(https?://)([^:]+):([^@]+)@|\1***:***@|g'
      ;;

    email)
      # Show first char and domain
      if [[ "$value" =~ ^([^@]+)@(.+)$ ]]; then
        local local_part="${BASH_REMATCH[1]}"
        local domain="${BASH_REMATCH[2]}"
        echo "${local_part:0:1}***@${domain}"
      else
        echo "[REDACTED]"
      fi
      ;;

    default)
      if [[ $show_first -gt 0 || $show_last -gt 0 ]]; then
        # Custom masking with specified visible chars
        local first="${value:0:$show_first}"
        local last="${value: -$show_last}"
        local masked_len=$((len - show_first - show_last))

        if [[ $masked_len -gt 0 ]]; then
          local masked
          masked=$(printf '*%.0s' $(seq 1 $masked_len 2>/dev/null) || echo "****")
          echo "${first}${masked}${last}"
        else
          echo "$value"
        fi
      else
        # Default: show nothing
        echo "[REDACTED]"
      fi
      ;;

    *)
      # Unknown type, use default masking
      echo "[REDACTED]"
      ;;
  esac
}

#######################################
# Check if Vault is available
# Returns: 0 if available, 1 if not
#######################################
check_vault() {
  local vault_addr="${VAULT_ADDR:-}"
  local vault_token="${VAULT_TOKEN:-}"

  if [[ -z "$vault_addr" || -z "$vault_token" ]]; then
    log_debug "Vault credentials not set (VAULT_ADDR, VAULT_TOKEN)"
    return 1
  fi

  # Test Vault connection
  if command -v curl &>/dev/null; then
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "X-Vault-Token: $vault_token" \
      "${vault_addr}/v1/sys/health" 2>/dev/null || echo "000")

    if [[ "$response" == "200" || "$response" == "429" || "$response" == "472" || "$response" == "473" ]]; then
      log_debug "Vault is available at $vault_addr"
      return 0
    else
      log_debug "Vault returned status $response"
      return 1
    fi
  else
    log_debug "curl not available for Vault check"
    return 1
  fi
}

#######################################
# Get secret from Vault
# Arguments:
#   $1 - secret path (e.g., "secret/data/rdd/credentials")
#   $2 - key within secret (optional)
# Returns: secret value
#######################################
get_vault_secret() {
  local path="$1"
  local key="${2:-}"

  if ! check_vault; then
    log_error "Vault not available"
    return 1
  fi

  local response
  response=$(curl -s \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "X-Vault-Request: true" \
    "${VAULT_ADDR}/v1/${path}" 2>/dev/null)

  if [[ -z "$response" ]]; then
    log_error "Empty response from Vault"
    return 1
  fi

  if command -v jq &>/dev/null; then
    # KV v2 stores data under .data.data
    if echo "$response" | jq -e '.data.data' >/dev/null 2>&1; then
      if [[ -n "$key" ]]; then
        echo "$response" | jq -r ".data.data.${key}" 2>/dev/null
      else
        echo "$response" | jq -r '.data.data' 2>/dev/null
      fi
    else
      # KV v1 stores data under .data
      if [[ -n "$key" ]]; then
        echo "$response" | jq -r ".data.${key}" 2>/dev/null
      else
        echo "$response" | jq -r '.data' 2>/dev/null
      fi
    fi
  else
    log_error "jq required for Vault integration"
    return 1
  fi
}

#######################################
# Store secret in Vault
# Arguments:
#   $1 - secret path
#   $2... - key=value pairs
#######################################
store_vault_secret() {
  local path="$1"
  shift
  local key_values=("$@")

  if ! check_vault; then
    log_error "Vault not available"
    return 1
  fi

  if [[ ${#key_values[@]} -eq 0 ]]; then
    log_error "No key-value pairs provided"
    return 1
  fi

  # Build JSON data
  local data="{\"data\":{"
  local first=true
  for kv in "${key_values[@]}"; do
    local k="${kv%%=*}"
    local v="${kv#*=}"

    if [[ "$first" == "true" ]]; then
      first=false
    else
      data+=","
    fi

    # Escape quotes in value
    v=$(echo "$v" | sed 's/"/\\"/g')
    data+="\"${k}\":\"${v}\""
  done
  data+="}}"

  local response
  response=$(curl -s \
    -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Vault-Request: true" \
    -d "$data" \
    "${VAULT_ADDR}/v1/${path}" 2>/dev/null)

  if [[ -n "$response" ]]; then
    log_info "Secret stored at $path"
    return 0
  else
    log_error "Failed to store secret"
    return 1
  fi
}

#######################################
# Get secret with fallback
# Tries Vault first, then environment variable, then local encrypted file
# Arguments:
#   $1 - secret name
#   $2 - vault path (optional)
# Returns: secret value
#######################################
get_secret() {
  local name="$1"
  local vault_path="${2:-secret/data/rdd/${name}}"

  # Try Vault first
  if check_vault; then
    local vault_value
    vault_value=$(get_vault_secret "$vault_path" "$name" 2>/dev/null)
    if [[ -n "$vault_value" && "$vault_value" != "null" ]]; then
      echo "$vault_value"
      return 0
    fi
  fi

  # Try environment variable
  local env_value="${!name:-}"
  if [[ -n "$env_value" ]]; then
    echo "$env_value"
    return 0
  fi

  # Try local encrypted file
  local secret_file="${RDD_DIR}/.keys/${name}.enc"
  if [[ -f "$secret_file" ]]; then
    decrypt_data "$(cat "$secret_file")" 2>/dev/null
    return 0
  fi

  log_error "Secret not found: $name"
  return 1
}

#######################################
# Store secret locally with encryption
# Arguments:
#   $1 - secret name
#   $2 - secret value
#######################################
store_secret() {
  local name="$1"
  local value="$2"

  ensure_key

  local secret_file="${RDD_DIR}/.keys/${name}.enc"
  local encrypted
  encrypted=$(encrypt_data "$value")

  echo "$encrypted" >"$secret_file"
  chmod 600 "$secret_file"

  log_info "Secret stored: $name"
}

#######################################
# Generate a secure random password
# Arguments:
#   $1 - length (default: 32)
# Returns: random password
#######################################
generate_password() {
  local length="${1:-32}"

  if command -v openssl &>/dev/null; then
    openssl rand -base64 "$((length * 3 / 4))" | head -c "$length"
  else
    # Fallback: use /dev/urandom
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' </dev/urandom | head -c "$length"
  fi
  echo
}

#######################################
# Hash a value
# Arguments:
#   $1 - value to hash
#   $2 - algorithm (sha256, sha512, md5) - default: sha256
# Returns: hashed value
#######################################
hash_value() {
  local value="$1"
  local algorithm="${2:-sha256}"

  case "$algorithm" in
    sha256)
      echo -n "$value" | sha256sum | cut -d' ' -f1
      ;;
    sha512)
      echo -n "$value" | sha512sum | cut -d' ' -f1
      ;;
    md5)
      echo -n "$value" | md5sum | cut -d' ' -f1
      ;;
    *)
      log_error "Unknown hash algorithm: $algorithm"
      return 1
      ;;
  esac
}

#######################################
# Show usage
#######################################
show_usage() {
  cat <<'EOF'
RDD Credential Encryption Utilities

Usage: crypto.sh <command> [options]

Commands:
  generate-key               Generate a new encryption key
  encrypt <data>             Encrypt data and print result
  decrypt <data>             Decrypt data and print result
  encrypt-file <in> [out]    Encrypt a file
  decrypt-file <in> [out]    Decrypt a file
  mask <value> [type]        Mask a sensitive value
                             Types: password, token, api_key, url, email
  check-vault                Check if HashiCorp Vault is available
  get-secret <name> [path]   Get secret (Vault -> env -> local)
  store-secret <name> <val>  Store secret locally with encryption
  get-vault-secret <path> [key]  Get secret from Vault
  store-vault-secret <path> <k=v>... Store secret in Vault
  generate-password [len]    Generate a secure random password
  hash <value> [algo]        Hash a value (sha256, sha512, md5)

Environment Variables:
  RDD_DIR       RDD configuration directory
  VAULT_ADDR    HashiCorp Vault address
  VAULT_TOKEN   HashiCorp Vault token

Examples:
  # Generate encryption key
  crypto.sh generate-key

  # Encrypt a secret
  crypto.sh encrypt "my-secret-password"

  # Decrypt a secret
  crypto.sh decrypt "U2FsdGVkX1..."

  # Mask a token
  crypto.sh mask "abcd1234efgh5678" token
  # Output: abcd****5678

  # Mask a password
  crypto.sh mask "my-password" password
  # Output: ********

  # Mask a URL with credentials
  crypto.sh mask "https://user:pass@example.com" url
  # Output: https://***:***@example.com

  # Get secret from Vault
  export VAULT_ADDR="http://localhost:8200"
  export VAULT_TOKEN="s.1234567890"
  crypto.sh get-vault-secret "secret/data/rdd/credentials" "api_key"

  # Store secret locally
  crypto.sh store-secret "db_password" "my-secret-password"

EOF
}

#######################################
# Main entry point
#######################################
main() {
  if [[ $# -lt 1 ]]; then
    show_usage
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    generate-key | gen-key)
      generate_key
      ;;
    encrypt | enc)
      if [[ $# -lt 1 ]]; then
        echo "Error: data to encrypt required" >&2
        exit 1
      fi
      encrypt_data "$1"
      ;;
    decrypt | dec)
      if [[ $# -lt 1 ]]; then
        echo "Error: data to decrypt required" >&2
        exit 1
      fi
      decrypt_data "$1"
      ;;
    encrypt-file)
      if [[ $# -lt 1 ]]; then
        echo "Error: input file required" >&2
        exit 1
      fi
      encrypt_file "$1" "${2:-}"
      ;;
    decrypt-file)
      if [[ $# -lt 1 ]]; then
        echo "Error: input file required" >&2
        exit 1
      fi
      decrypt_file "$1" "${2:-}"
      ;;
    mask)
      if [[ $# -lt 1 ]]; then
        echo "Error: value to mask required" >&2
        exit 1
      fi
      mask_value "$1" "${2:-default}" "${3:-0}" "${4:-0}"
      ;;
    check-vault)
      if check_vault; then
        log_info "Vault is available at ${VAULT_ADDR}"
        exit 0
      else
        log_error "Vault is not available"
        exit 1
      fi
      ;;
    get-secret)
      if [[ $# -lt 1 ]]; then
        echo "Error: secret name required" >&2
        exit 1
      fi
      get_secret "$1" "${2:-}"
      ;;
    store-secret)
      if [[ $# -lt 2 ]]; then
        echo "Error: secret name and value required" >&2
        exit 1
      fi
      store_secret "$1" "$2"
      ;;
    get-vault-secret)
      if [[ $# -lt 1 ]]; then
        echo "Error: secret path required" >&2
        exit 1
      fi
      get_vault_secret "$1" "${2:-}"
      ;;
    store-vault-secret)
      if [[ $# -lt 2 ]]; then
        echo "Error: secret path and key=value pairs required" >&2
        exit 1
      fi
      store_vault_secret "$@"
      ;;
    generate-password | gen-pass)
      generate_password "${1:-32}"
      ;;
    hash)
      if [[ $# -lt 1 ]]; then
        echo "Error: value to hash required" >&2
        exit 1
      fi
      hash_value "$1" "${2:-sha256}"
      ;;
    -h | --help | help)
      show_usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      show_usage
      exit 1
      ;;
  esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi

# Export functions for use in other scripts
export -f generate_key encrypt_data decrypt_data
export -f encrypt_file decrypt_file
export -f mask_value check_vault
export -f get_vault_secret store_vault_secret
export -f get_secret store_secret
export -f generate_password hash_value
