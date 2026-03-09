# RDD Security Configuration Checklist

> Pre-deployment security checklist for RDD Framework

---

## Pre-deployment Security Checklist

### 1. File Permissions

- [ ] Set restrictive permissions on sensitive files
  ```bash
  chmod 600 .rdd/permissions.yml
  chmod 600 .rdd/hooks.yml
  chmod 600 .rdd/config.yml
  chmod 600 .rdd/audit.yml
  chmod 600 .rdd/vault.yml
  chmod 700 .rdd/logs
  chmod 700 .rdd/cache
  chmod 700 .rdd/.keys
  ```

- [ ] Verify no world-readable sensitive files
  ```bash
  find .rdd -type f -perm /004 -ls
  # Should return nothing
  ```

- [ ] Verify no world-writable files
  ```bash
  find .rdd -type f -perm /002 -ls
  # Should return nothing
  ```

- [ ] Verify key directory permissions
  ```bash
  ls -la .rdd/.keys/
  # Should show 700 permissions
  ```

### 2. Credential Security

- [ ] No credentials in version control
  ```bash
  # Check .gitignore includes
  grep -E "credentials|secrets|keys|\.env" .gitignore
  ```

- [ ] Use environment variables for secrets
  ```bash
  # Verify hooks.yml uses env vars
  grep -E '\$\{.*\}' .rdd/hooks.yml
  ```

- [ ] Encryption keys are protected
  ```bash
  ls -la .rdd/.keys/
  # Files should have 600 permissions
  ```

- [ ] No plaintext passwords in config
  ```bash
  # Search for potential password exposure
  grep -rE "password\s*=\s*['\"][^'\"]+" .rdd/
  # Should return nothing
  ```

### 3. RBAC Configuration

- [ ] RBAC is enabled
  ```yaml
  # .rdd/permissions.yml
  rbac:
    enabled: true
  ```

- [ ] Default role is restrictive
  ```yaml
  default_role: viewer  # or none
  ```

- [ ] Admin users are properly assigned
  ```yaml
  users:
    - username: "${RDD_ADMIN_USER}"
      role: admin
  ```

- [ ] Strict mode is enabled
  ```yaml
  checking:
    strict_mode: true
  ```

### 4. Audit Logging

- [ ] Audit logging is enabled
  ```yaml
  # .rdd/audit.yml
  audit:
    enabled: true
  ```

- [ ] Log rotation is configured
  ```yaml
  storage:
    file:
      rotation:
        enabled: true
        max_size: "10MB"
        max_files: 10
  ```

- [ ] Sensitive data masking is enabled
  ```yaml
  masking:
    enabled: true
  ```

- [ ] Retention policy is set
  ```yaml
  retention:
    days: 90
  ```

### 5. Input Validation

- [ ] All user inputs are validated
- [ ] Path traversal is prevented
- [ ] Command injection is prevented
- [ ] File paths are sanitized
- [ ] YAML/JSON inputs are escaped

### 6. Network Security (if using webhooks)

- [ ] HTTPS endpoints only
- [ ] TLS certificate validation enabled
- [ ] Timeout configured for all requests
- [ ] Rate limiting considered

### 7. Vault Integration (if used)

- [ ] Vault address configured
  ```bash
  export VAULT_ADDR="https://vault.example.com"
  ```

- [ ] Vault token secured
  ```bash
  export VAULT_TOKEN="..."
  # Token should not be in version control
  ```

- [ ] Fallback strategy defined
  ```yaml
  fallback:
    use_env: true
    use_local: true
  ```

- [ ] Vault health check enabled
  ```yaml
  health_check:
    enabled: true
  ```

### 8. Dependencies

- [ ] openssl is installed (for encryption)
- [ ] jq is installed (for JSON processing)
- [ ] yq is installed (for YAML processing)
- [ ] curl is installed (for Vault integration)

---

## Runtime Security Checks

### Run security check script

```bash
# Run automated security check
.rdd/scripts/security-check.sh

# Run with auto-fix
.rdd/scripts/security-check.sh --fix

# JSON output for CI/CD
.rdd/scripts/security-check.sh --json

# Verbose output
.rdd/scripts/security-check.sh --verbose
```

### Check for security issues

```bash
# Check file permissions
find .rdd -type f -perm /007 -ls

# Check for exposed secrets
grep -r "password" .rdd/*.yml
grep -r "secret" .rdd/*.yml
grep -r "token" .rdd/*.yml

# Check audit logs for denied operations
tail -100 .rdd/logs/audit.log | grep DENIED

# Check RBAC configuration
cat .rdd/permissions.yml | grep "enabled:"
```

---

## Security Incident Response

### If credentials are exposed

1. Rotate affected credentials immediately
2. Update configuration to use new credentials
3. Review audit logs for unauthorized access
4. Document incident in security log
5. Notify security team

### If RBAC is bypassed

1. Check for configuration errors
2. Review user assignments
3. Enable strict mode
4. Audit all permission changes
5. Review audit logs

### If audit logs are tampered

1. Restore from backup
2. Check file permissions
3. Review system logs
4. Implement tamper-evident logging
5. Report incident

### If encryption key is compromised

1. Generate new encryption key
2. Re-encrypt all sensitive data
3. Rotate all secrets stored with old key
4. Update all systems with new key
5. Audit access logs

---

## Security Best Practices

### For Administrators

1. Use RBAC to limit access
2. Enable audit logging
3. Rotate credentials regularly
4. Monitor audit logs
5. Keep security dependencies updated

### For Developers

1. Never commit secrets
2. Use environment variables
3. Validate all inputs
4. Use secure file operations
5. Report security issues

### For CI/CD

1. Run security checks in pipeline
2. Fail on security issues
3. Auto-fix where possible
4. Audit all deployments
5. Keep credentials in vault

---

## Security Commands Quick Reference

```bash
# Security check
task rdd:security-check

# Generate encryption key
.rdd/lib/crypto.sh generate-key

# Encrypt a secret
.rdd/lib/crypto.sh encrypt "my-secret"

# Decrypt a secret
.rdd/lib/crypto.sh decrypt "U2FsdGVkX1..."

# Mask a token
.rdd/lib/crypto.sh mask "abcd1234efgh5678" token

# Check Vault status
.rdd/lib/crypto.sh check-vault

# View audit status
.rdd/scripts/audit.sh status

# Query audit logs
.rdd/scripts/audit.sh query "PERMISSION_DENIED"

# Export audit logs
.rdd/scripts/audit.sh export csv audit-report.csv
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-07 | Initial security checklist |
