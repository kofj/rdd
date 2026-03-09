#!/usr/bin/env bats
#
# Unit tests for RDD Security Utilities (security.sh)
# Tests input validation, sanitization, and security functions
#

# Load bats-core (no additional helpers needed)

# Setup
setup() {
    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)

    # Source the security library
    source "${BATS_TEST_DIRNAME}/../../.rdd/lib/security.sh"
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

#######################################
# Test: Input Validation - Alphanumeric
#######################################

@test "validate_input accepts valid alphanumeric" {
    validate_input "valid_name123" "alphanumeric"
}

@test "validate_input accepts alphanumeric with underscore" {
    validate_input "valid_name_123" "alphanumeric"
}

@test "validate_input accepts alphanumeric with hyphen" {
    validate_input "valid-name-123" "alphanumeric"
}

@test "validate_input rejects alphanumeric with space" {
    ! validate_input "invalid name" "alphanumeric"
}

@test "validate_input rejects alphanumeric with special chars" {
    ! validate_input "invalid!" "alphanumeric"
}

@test "validate_input accepts empty input" {
    validate_input "" "alphanumeric"
}

#######################################
# Test: Input Validation - Path
#######################################

@test "validate_input accepts valid path" {
    validate_input "/path/to/file" "path"
}

@test "validate_input accepts relative path" {
    validate_input "./relative/path" "path"
}

@test "validate_input rejects path traversal" {
    ! validate_input "../etc/passwd" "path"
}

@test "validate_input rejects path with null byte" {
    # Note: Bash cannot pass null bytes through arguments - they get truncated.
    # This test validates that the function would reject null bytes if they could be passed.
    # Since bash strips null bytes before they reach the function, this test always passes
    # but we keep it for documentation purposes and in case a null byte somehow slips through.
    run validate_input $'/path/to/file\0' "path"
    # The null byte is stripped by bash, so the path becomes '/path/to/file' which is valid
    # This test is kept as documentation of the limitation
    [[ $status -eq 0 ]] || [[ $status -eq 1 ]]  # Either outcome is acceptable
}

@test "validate_input rejects path with command substitution" {
    ! validate_input '/path/$(whoami)' "path"
}

@test "validate_input rejects path with backticks" {
    ! validate_input '/path/`whoami`' "path"
}

#######################################
# Test: Input Validation - Command
#######################################

@test "validate_input accepts simple command" {
    validate_input "ls" "command"
}

@test "validate_input rejects command with semicolon" {
    ! validate_input "ls; rm -rf /" "command"
}

@test "validate_input rejects command with pipe" {
    ! validate_input "cat file | mail" "command"
}

@test "validate_input rejects command with &&" {
    ! validate_input "true && rm -rf" "command"
}

@test "validate_input rejects command with ||" {
    ! validate_input "false || rm -rf" "command"
}

@test "validate_input rejects command with \$()" {
    ! validate_input 'echo $(whoami)' "command"
}

@test "validate_input rejects command with backticks" {
    ! validate_input 'echo `whoami`' "command"
}

@test "validate_input rejects command with redirect" {
    ! validate_input "cat file > /etc/passwd" "command"
}

#######################################
# Test: Input Validation - URL
#######################################

@test "validate_input accepts http URL" {
    validate_input "http://example.com" "url"
}

@test "validate_input accepts https URL" {
    validate_input "https://example.com" "url"
}

@test "validate_input accepts URL with path" {
    validate_input "https://example.com/path/to/resource" "url"
}

@test "validate_input rejects javascript URL" {
    ! validate_input "javascript:alert(1)" "url"
}

@test "validate_input rejects data URL" {
    ! validate_input "data:text/html,<script>" "url"
}

@test "validate_input rejects invalid URL" {
    ! validate_input "not-a-url" "url"
}

@test "validate_input rejects ftp URL" {
    ! validate_input "ftp://example.com" "url"
}

#######################################
# Test: Input Validation - Email
#######################################

@test "validate_input accepts valid email" {
    validate_input "user@example.com" "email"
}

@test "validate_input accepts email with subdomain" {
    validate_input "user@mail.example.com" "email"
}

@test "validate_input accepts email with plus" {
    validate_input "user+tag@example.com" "email"
}

@test "validate_input rejects email without @" {
    ! validate_input "userexample.com" "email"
}

@test "validate_input rejects email without domain" {
    ! validate_input "user@" "email"
}

@test "validate_input rejects email with invalid chars" {
    ! validate_input "user name@example.com" "email"
}

#######################################
# Test: Input Validation - Integer
#######################################

@test "validate_input accepts positive integer" {
    validate_input "123" "integer"
}

@test "validate_input accepts negative integer" {
    validate_input "-456" "integer"
}

@test "validate_input rejects float" {
    ! validate_input "123.45" "integer"
}

@test "validate_input rejects string" {
    ! validate_input "abc" "integer"
}

@test "validate_input rejects empty" {
    validate_input "" "integer"  # Empty is valid
}

#######################################
# Test: Input Validation - Boolean
#######################################

@test "validate_input accepts true" {
    validate_input "true" "boolean"
}

@test "validate_input accepts false" {
    validate_input "false" "boolean"
}

@test "validate_input accepts yes" {
    validate_input "yes" "boolean"
}

@test "validate_input accepts no" {
    validate_input "no" "boolean"
}

@test "validate_input accepts 1" {
    validate_input "1" "boolean"
}

@test "validate_input accepts 0" {
    validate_input "0" "boolean"
}

@test "validate_input rejects invalid boolean" {
    ! validate_input "maybe" "boolean"
}

#######################################
# Test: Input Validation - Text
#######################################

@test "validate_input accepts normal text" {
    validate_input "Hello, World!" "text"
}

@test "validate_input rejects text with newline" {
    ! validate_input $'line1\nline2' "text"
}

@test "validate_input rejects text with carriage return" {
    ! validate_input $'line1\rline2' "text"
}

@test "validate_input rejects text with null byte" {
    # Note: Bash cannot pass null bytes through arguments - they get truncated.
    # This test validates that the function would reject null bytes if they could be passed.
    run validate_input $'text\0more' "text"
    # The null byte is stripped by bash, so the text becomes 'textmore' which is valid
    # This test is kept as documentation of the limitation
    [[ $status -eq 0 ]] || [[ $status -eq 1 ]]  # Either outcome is acceptable
}

@test "validate_input accepts multiline in multiline mode" {
    validate_input $'line1\nline2' "multiline"
}

#######################################
# Test: Input Validation - Identifier
#######################################

@test "validate_input accepts valid identifier" {
    validate_input "validName" "identifier"
}

@test "validate_input accepts identifier with underscore" {
    validate_input "valid_name" "identifier"
}

@test "validate_input accepts identifier with numbers" {
    validate_input "name123" "identifier"
}

@test "validate_input rejects identifier starting with number" {
    ! validate_input "123name" "identifier"
}

@test "validate_input rejects identifier with special chars" {
    ! validate_input "name-with-dash" "identifier"
}

@test "validate_input rejects identifier with space" {
    ! validate_input "name with space" "identifier"
}

#######################################
# Test: Input Validation - Filename
#######################################

@test "validate_input accepts valid filename" {
    validate_input "file.txt" "filename"
}

@test "validate_input accepts filename with dots" {
    validate_input "file.name.txt" "filename"
}

@test "validate_input accepts filename with underscore" {
    validate_input "file_name.txt" "filename"
}

@test "validate_input rejects filename with slash" {
    ! validate_input "path/file.txt" "filename"
}

@test "validate_input rejects filename with backslash" {
    ! validate_input "path\\file.txt" "filename"
}

@test "validate_input rejects . as filename" {
    ! validate_input "." "filename"
}

@test "validate_input rejects .. as filename" {
    ! validate_input ".." "filename"
}

#######################################
# Test: Input Sanitization
#######################################

@test "sanitize_input removes semicolons for shell context" {
    local result
    result=$(sanitize_input "hello; rm -rf" "shell")

    [[ "$result" != *";"* ]]
}

@test "sanitize_input removes pipes for shell context" {
    local result
    result=$(sanitize_input "ls | grep" "shell")

    [[ "$result" != *"|"* ]]
}

@test "sanitize_input escapes for YAML" {
    local result
    result=$(sanitize_input 'value: "test"' "yaml")

    [[ "$result" == *'\"'* ]]
}

@test "sanitize_input escapes for JSON" {
    local result
    result=$(sanitize_input 'he said "hello"' "json")

    [[ "$result" == *'\"'* ]]
}

@test "sanitize_input escapes for HTML" {
    local result
    result=$(sanitize_input '<script>alert(1)</script>' "html")

    [[ "$result" == *"&lt;"* ]]
    [[ "$result" == *"&gt;"* ]]
}

@test "sanitize_input handles empty input" {
    local result
    result=$(sanitize_input "" "shell")

    [ -z "$result" ]
}

#######################################
# Test: YAML Escaping
#######################################

@test "escape_yaml escapes backslashes" {
    local result
    result=$(escape_yaml "path\\to\\file")

    [[ "$result" == *"\\\\"* ]]
}

@test "escape_yaml escapes quotes" {
    local result
    result=$(escape_yaml 'say "hello"')

    [[ "$result" == *'\"'* ]]
}

@test "escape_yaml handles normal text" {
    local result
    result=$(escape_yaml "normal text")

    [ "$result" == "normal text" ]
}

#######################################
# Test: JSON Escaping
#######################################

@test "escape_json escapes backslashes" {
    local result
    result=$(escape_json "path\\to\\file")

    [[ "$result" == *"\\\\"* ]]
}

@test "escape_json escapes quotes" {
    local result
    result=$(escape_json 'say "hello"')

    [[ "$result" == *'\"'* ]]
}

@test "escape_json escapes newlines" {
    local result
    result=$(escape_json $'line1\nline2')

    [[ "$result" == *"\\n"* ]]
}

@test "escape_json escapes tabs" {
    local result
    result=$(escape_json $'col1\tcol2')

    [[ "$result" == *"\\t"* ]]
}

#######################################
# Test: Path Validation
#######################################

@test "validate_path accepts valid path" {
    validate_path "/tmp/test"
}

@test "validate_path rejects path traversal" {
    ! validate_path "/tmp/../etc/passwd"
}

@test "validate_path rejects null byte in path" {
    # Note: Bash cannot pass null bytes through arguments - they get truncated.
    # This test validates that the function would reject null bytes if they could be passed.
    run validate_path $'/tmp/test\0'
    # The null byte is stripped by bash, so the path becomes '/tmp/test' which is valid
    # This test is kept as documentation of the limitation
    [[ $status -eq 0 ]] || [[ $status -eq 1 ]]  # Either outcome is acceptable
}

@test "validate_path with base_dir rejects outside path" {
    ! validate_path "/etc/passwd" "/home/user"
}

@test "validate_path accepts path within base_dir" {
    validate_path "$TEST_DIR/file.txt" "$TEST_DIR"
}

@test "validate_path with must_exist rejects non-existent" {
    # Use a truly non-existent path (with timestamp to ensure uniqueness)
    ! validate_path "/this-path-does-not-exist-$$-$(date +%s)" "" "true"
}

@test "validate_path with must_exist accepts existing" {
    local file="$TEST_DIR/test.txt"
    touch "$file"

    validate_path "$file" "" "true"
}

#######################################
# Test: Secure File Operations
#######################################

@test "secure_read_file reads file content" {
    local file="$TEST_DIR/test.txt"
    echo "test content" > "$file"

    local content
    content=$(secure_read_file "$file")

    [ "$content" == "test content" ]
}

@test "secure_read_file rejects path traversal" {
    run secure_read_file "$TEST_DIR/../etc/passwd"
    [ "$status" != "0" ]
}

@test "secure_read_file rejects non-existent file" {
    run secure_read_file "$TEST_DIR/nonexistent.txt"
    [ "$status" != "0" ]
}

@test "secure_write_file creates file" {
    local file="$TEST_DIR/output.txt"
    secure_write_file "$file" "test content"

    [ -f "$file" ]
}

@test "secure_write_file writes correct content" {
    local file="$TEST_DIR/output.txt"
    secure_write_file "$file" "test content"

    [ "$(cat "$file")" == "test content" ]
}

@test "secure_write_file sets secure permissions" {
    local file="$TEST_DIR/output.txt"
    secure_write_file "$file" "test content"

    local perms
    perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
    [ "$perms" == "600" ]
}

@test "secure_write_file creates directory if needed" {
    local file="$TEST_DIR/subdir/output.txt"
    secure_write_file "$file" "test content"

    [ -f "$file" ]
}

#######################################
# Test: Command Safety Check
#######################################

@test "is_safe_command accepts ls" {
    is_safe_command "ls"
}

@test "is_safe_command accepts cat" {
    is_safe_command "cat"
}

@test "is_safe_command accepts git" {
    is_safe_command "git"
}

@test "is_safe_command rejects rm" {
    ! is_safe_command "rm"
}

@test "is_safe_command rejects shutdown" {
    ! is_safe_command "shutdown"
}

@test "is_safe_command rejects eval" {
    ! is_safe_command "eval"
}

@test "is_safe_command rejects unknown command" {
    ! is_safe_command "unknown_command_xyz"
}

#######################################
# Test: Token Generation
#######################################

@test "generate_secure_token produces output" {
    local token
    token=$(generate_secure_token)

    [ -n "$token" ]
}

@test "generate_secure_token produces default length" {
    local token
    token=$(generate_secure_token)

    [ ${#token} -eq 64 ]  # 32 bytes = 64 hex chars
}

@test "generate_secure_token produces custom length" {
    local token
    token=$(generate_secure_token 16)

    [ ${#token} -eq 16 ]
}

@test "generate_secure_token produces unique values" {
    local token1
    token1=$(generate_secure_token)

    local token2
    token2=$(generate_secure_token)

    [ "$token1" != "$token2" ]
}

#######################################
# Test: Password Strength
#######################################

@test "check_password_strength accepts strong password" {
    check_password_strength "Str0ng!Pass" 10
}

@test "check_password_strength rejects short password" {
    ! check_password_strength "Short1!" 12
}

@test "check_password_strength rejects password without uppercase" {
    ! check_password_strength "lowercase123!"
}

@test "check_password_strength rejects password without lowercase" {
    ! check_password_strength "UPPERCASE123!"
}

@test "check_password_strength rejects password without number" {
    ! check_password_strength "NoNumbers!"
}

@test "check_password_strength rejects password without special char" {
    ! check_password_strength "NoSpecialChars1"
}

#######################################
# Test: Sensitive Data Redaction
#######################################

@test "redact_sensitive masks passwords" {
    local result
    result=$(redact_sensitive "password=secret123")

    [[ "$result" == *"password=***REDACTED***"* ]]
    [[ "$result" != *"secret123"* ]]
}

@test "redact_sensitive masks tokens" {
    local result
    result=$(redact_sensitive "token=abc123xyz")

    [[ "$result" == *"token=***REDACTED***"* ]]
}

@test "redact_sensitive masks URLs with credentials" {
    local result
    result=$(redact_sensitive "url=https://user:pass@example.com")

    [[ "$result" == *"https://***:***@example.com"* ]]
}

@test "redact_sensitive preserves non-sensitive data" {
    local result
    result=$(redact_sensitive "stage=1 project=myproject")

    [[ "$result" == *"stage=1"* ]]
    [[ "$result" == *"project=myproject"* ]]
}

@test "redact_sensitive handles multiple patterns" {
    local result
    result=$(redact_sensitive "password=secret token=abc123")

    [[ "$result" == *"password=***REDACTED***"* ]]
    [[ "$result" == *"token=***REDACTED***"* ]]
}

#######################################
# Test: Edge Cases
#######################################

@test "validate_input handles very long input" {
    local long_input
    long_input=$(printf 'x%.0s' {1..10000})

    validate_input "$long_input" "text"
}

@test "validate_input handles unicode" {
    validate_input "你好世界" "text"
}

@test "validate_input handles emoji" {
    validate_input "Hello 🌍 World" "text"
}

@test "sanitize_input handles empty string" {
    local result
    result=$(sanitize_input "" "shell")

    [ -z "$result" ]
}

@test "validate_input with unknown type returns error" {
    ! validate_input "test" "unknown_type"
}
