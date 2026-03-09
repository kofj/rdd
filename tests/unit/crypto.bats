#!/usr/bin/env bats
#
# Unit tests for RDD Crypto Library (crypto.sh)
# Tests encryption, decryption, masking, and Vault integration
#

# Load bats-core (no additional helpers needed)

# Setup
setup() {
    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)
    RDD_DIR="$TEST_DIR/.rdd"

    mkdir -p "$RDD_DIR/.keys"
    mkdir -p "$RDD_DIR/lib"

    # Source the crypto library
    export RDD_DIR
    source "${BATS_TEST_DIRNAME}/../../.rdd/lib/crypto.sh"
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

#######################################
# Test: Key Generation
#######################################

@test "generate_key creates key file" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    generate_key

    [ -f "$RDD_DIR/.keys/encryption.key" ]
}

@test "generate_key creates directory if not exists" {
    rm -rf "$RDD_DIR/.keys"

    generate_key

    [ -d "$RDD_DIR/.keys" ]
}

@test "generate_key sets secure permissions" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    generate_key

    local perms
    perms=$(stat -c "%a" "$RDD_DIR/.keys/encryption.key" 2>/dev/null || stat -f "%Lp" "$RDD_DIR/.keys/encryption.key" 2>/dev/null)
    [ "$perms" == "600" ]
}

@test "generate_key creates non-empty key" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    generate_key

    local key
    key=$(cat "$RDD_DIR/.keys/encryption.key")
    [ -n "$key" ]
}

@test "generate_key creates 64-char hex key" {
    rm -f "$RDD_DIR/.keys/encryption.key"

    generate_key

    local key
    key=$(cat "$RDD_DIR/.keys/encryption.key")
    [ ${#key} -eq 64 ]
}

#######################################
# Test: Encryption/Decryption
#######################################

@test "encrypt_data produces output" {
    ensure_key

    local encrypted
    encrypted=$(encrypt_data "test secret")

    [ -n "$encrypted" ]
}

@test "encrypt_data produces base64 output" {
    ensure_key

    local encrypted
    encrypted=$(encrypt_data "test secret")

    # Base64 only contains alphanumeric, +, /, =
    [[ "$encrypted" =~ ^[A-Za-z0-9+/=]+$ ]]
}

@test "decrypt_data recovers original data" {
    ensure_key

    local original="my secret password"
    local encrypted
    encrypted=$(encrypt_data "$original")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$original" ]
}

@test "encrypt_data produces different output for same input" {
    ensure_key

    local encrypted1
    encrypted1=$(encrypt_data "test")

    local encrypted2
    encrypted2=$(encrypt_data "test")

    # Due to salt, outputs should be different
    [ "$encrypted1" != "$encrypted2" ]
}

@test "decrypt_data fails with wrong key" {
    ensure_key

    local encrypted
    encrypted=$(encrypt_data "secret")

    # Generate a different key
    generate_key

    # Decryption should fail or produce garbage
    run decrypt_data "$encrypted"
    [ "$status" != "0" ] || [[ "$output" != "secret" ]]
}

@test "encrypt_data handles empty string" {
    ensure_key

    run encrypt_data ""
    [ "$status" != "0" ]
}

@test "encrypt_data handles special characters" {
    ensure_key

    local original="hello!@#\$%^&*()_+{}|:<>?~\`-=[]\\;',./"
    local encrypted
    encrypted=$(encrypt_data "$original")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$original" ]
}

@test "encrypt_data handles unicode" {
    ensure_key

    local original="你好世界 🌍"
    local encrypted
    encrypted=$(encrypt_data "$original")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$original" ]
}

@test "encrypt_data handles long strings" {
    ensure_key

    local original
    original=$(printf 'x%.0s' {1..10000})

    local encrypted
    encrypted=$(encrypt_data "$original")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$original" ]
}

@test "encrypt_data handles newlines" {
    ensure_key

    local original=$'line1\nline2\nline3'
    local encrypted
    encrypted=$(encrypt_data "$original")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$original" ]
}

#######################################
# Test: File Encryption
#######################################

@test "encrypt_file creates encrypted file" {
    ensure_key

    local input_file="$TEST_DIR/test.txt"
    echo "secret content" > "$input_file"

    encrypt_file "$input_file"

    [ -f "${input_file}.enc" ]
}

@test "decrypt_file recovers original content" {
    ensure_key

    local input_file="$TEST_DIR/test.txt"
    local original="secret content"
    echo "$original" > "$input_file"

    encrypt_file "$input_file"
    decrypt_file "${input_file}.enc" "$TEST_DIR/decrypted.txt"

    local decrypted
    decrypted=$(cat "$TEST_DIR/decrypted.txt")
    [ "$decrypted" == "$original" ]
}

@test "encrypt_file sets secure permissions" {
    ensure_key

    local input_file="$TEST_DIR/test.txt"
    echo "secret" > "$input_file"

    encrypt_file "$input_file"

    local perms
    perms=$(stat -c "%a" "${input_file}.enc" 2>/dev/null || stat -f "%Lp" "${input_file}.enc" 2>/dev/null)
    [ "$perms" == "600" ]
}

#######################################
# Test: Data Masking
#######################################

@test "mask_value masks password type" {
    local masked
    masked=$(mask_value "my_password123" "password")

    [ "$masked" == "********" ]
}

@test "mask_value masks token type" {
    local masked
    masked=$(mask_value "abcd1234efgh5678ijkl" "token")

    # Should show first 4 and last 4 chars
    [[ "$masked" == "abcd****ijkl" ]]
}

@test "mask_value masks short token" {
    local masked
    masked=$(mask_value "short" "token")

    [ "$masked" == "********" ]
}

@test "mask_value masks api_key type" {
    local masked
    masked=$(mask_value "sk-1234567890abcdef" "api_key")

    # Should show first 8 chars
    [[ "$masked" == "sk-12345..."* ]]
}

@test "mask_value masks url with credentials" {
    local masked
    masked=$(mask_value "https://user:password@example.com/path" "url")

    [[ "$masked" == *"***:***@"* ]]
}

@test "mask_value masks email" {
    local masked
    masked=$(mask_value "user@example.com" "email")

    [[ "$masked" == "u***@example.com" ]]
}

@test "mask_value masks secret type" {
    local masked
    masked=$(mask_value "my_secret_key" "secret")

    [ "$masked" == "[REDACTED]" ]
}

@test "mask_value masks default type" {
    local masked
    masked=$(mask_value "sensitive_data" "default")

    [ "$masked" == "[REDACTED]" ]
}

@test "mask_value with custom show_first and show_last" {
    local masked
    masked=$(mask_value "abcdefghij" "default" 2 2)

    [[ "$masked" == "ab******ij" ]]
}

@test "mask_value handles empty value" {
    local masked
    masked=$(mask_value "" "password")

    [ "$masked" == "" ]
}

@test "mask_value masks credential type" {
    local masked
    masked=$(mask_value "my_credentials" "credential")

    [ "$masked" == "[REDACTED]" ]
}

#######################################
# Test: Hash Functions
#######################################

@test "hash_value produces sha256 hash" {
    local hash
    hash=$(hash_value "test" "sha256")

    # SHA256 produces 64 hex characters
    [ ${#hash} -eq 64 ]
    [[ "$hash" =~ ^[a-f0-9]+$ ]]
}

@test "hash_value produces sha512 hash" {
    local hash
    hash=$(hash_value "test" "sha512")

    # SHA512 produces 128 hex characters
    [ ${#hash} -eq 128 ]
}

@test "hash_value produces md5 hash" {
    local hash
    hash=$(hash_value "test" "md5")

    # MD5 produces 32 hex characters
    [ ${#hash} -eq 32 ]
}

@test "hash_value is deterministic" {
    local hash1
    hash1=$(hash_value "test" "sha256")

    local hash2
    hash2=$(hash_value "test" "sha256")

    [ "$hash1" == "$hash2" ]
}

@test "hash_value produces different hashes for different inputs" {
    local hash1
    hash1=$(hash_value "test1" "sha256")

    local hash2
    hash2=$(hash_value "test2" "sha256")

    [ "$hash1" != "$hash2" ]
}

#######################################
# Test: Password Generation
#######################################

@test "generate_password produces output" {
    local password
    password=$(generate_password)

    [ -n "$password" ]
}

@test "generate_password produces default length" {
    local password
    password=$(generate_password)

    # Default is 32 characters
    [ ${#password} -eq 32 ]
}

@test "generate_password produces custom length" {
    local password
    password=$(generate_password 16)

    [ ${#password} -eq 16 ]
}

@test "generate_password produces unique values" {
    local password1
    password1=$(generate_password)

    local password2
    password2=$(generate_password)

    [ "$password1" != "$password2" ]
}

#######################################
# Test: Vault Integration (Mock)
#######################################

@test "check_vault returns 1 when VAULT_ADDR not set" {
    unset VAULT_ADDR
    unset VAULT_TOKEN

    ! check_vault
}

@test "check_vault returns 1 when VAULT_TOKEN not set" {
    export VAULT_ADDR="http://localhost:8200"
    unset VAULT_TOKEN

    ! check_vault
}

@test "check_vault returns 1 when Vault not reachable" {
    export VAULT_ADDR="http://localhost:8200"
    export VAULT_TOKEN="test-token"

    # Vault is not running, so check should fail
    ! check_vault
}

#######################################
# Test: Local Secret Storage
#######################################

@test "store_secret creates encrypted file" {
    ensure_key

    store_secret "test_secret" "my_password"

    [ -f "$RDD_DIR/.keys/test_secret.enc" ]
}

@test "get_secret retrieves stored secret" {
    ensure_key

    store_secret "test_secret" "my_password"

    local retrieved
    retrieved=$(get_secret "test_secret")

    [ "$retrieved" == "my_password" ]
}

@test "store_secret sets secure permissions" {
    ensure_key

    store_secret "test_secret" "my_password"

    local perms
    perms=$(stat -c "%a" "$RDD_DIR/.keys/test_secret.enc" 2>/dev/null || stat -f "%Lp" "$RDD_DIR/.keys/test_secret.enc" 2>/dev/null)
    [ "$perms" == "600" ]
}

@test "get_secret returns environment variable first" {
    ensure_key

    export test_secret="env_value"
    store_secret "test_secret" "stored_value"

    local retrieved
    retrieved=$(get_secret "test_secret")

    # Environment variable should take precedence
    [ "$retrieved" == "env_value" ]
}

@test "get_secret fails for non-existent secret" {
    ensure_key

    run get_secret "nonexistent_secret"
    [ "$status" != "0" ]
}

#######################################
# Test: Edge Cases
#######################################

@test "encrypt_data with very long input" {
    ensure_key

    local long_input
    long_input=$(head -c 100000 /dev/urandom | base64)

    local encrypted
    encrypted=$(encrypt_data "$long_input")

    local decrypted
    decrypted=$(decrypt_data "$encrypted")

    [ "$decrypted" == "$long_input" ]
}

@test "ensure_key creates key if not exists" {
    rm -rf "$RDD_DIR/.keys"

    ensure_key

    [ -f "$RDD_DIR/.keys/encryption.key" ]
}

@test "ensure_key does not overwrite existing key" {
    generate_key
    local original_key
    original_key=$(cat "$RDD_DIR/.keys/encryption.key")

    ensure_key

    local current_key
    current_key=$(cat "$RDD_DIR/.keys/encryption.key")

    [ "$original_key" == "$current_key" ]
}

@test "mask_value handles very long values" {
    local long_value
    long_value=$(printf 'x%.0s' {1..1000})

    local masked
    masked=$(mask_value "$long_value" "password")

    [ "$masked" == "********" ]
}

@test "hash_value handles empty string" {
    local hash
    hash=$(hash_value "" "sha256")

    [ ${#hash} -eq 64 ]
}

@test "hash_value rejects unknown algorithm" {
    run hash_value "test" "unknown"
    [ "$status" != "0" ]
}
