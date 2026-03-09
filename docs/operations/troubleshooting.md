# Troubleshooting Guide

> Common issues and solutions for RDD Framework.

## Quick Diagnostics

Run the health check first:

```bash
task doctor
```

This checks:
- Required tools (task, bash, git)
- Directory structure
- Configuration files
- Hook permissions
- Test framework

## Common Issues

### 1. "task: command not found"

**Problem**: Task runner is not installed or not in PATH.

**Solution**:
```bash
# Install Task
brew install go-task  # macOS
# or
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

# Add to PATH
export PATH="$PATH:~/.local/bin"

# Verify
task --version
```

### 2. "bats: command not found"

**Problem**: Bats testing framework is not installed.

**Solution**:
```bash
# Install bats-core locally
git clone https://github.com/bats-core/bats-core.git tests/lib/bats-core

# Run tests
task test
```

### 3. "Permission denied" for hooks

**Problem**: Hook scripts don't have execute permission.

**Solution**:
```bash
# Fix permissions
chmod +x .rdd/hooks/*.sh

# Verify
ls -la .rdd/hooks/
```

### 4. Tests failing with "unbound variable"

**Problem**: Scripts using `set -u` with undefined variables.

**Solution**:
```bash
# Check for undefined variables
grep -r 'set -u' .rdd/

# Fix by using default values
# Before: if [[ "$VAR" == "value" ]]; then
# After:  if [[ "${VAR:-}" == "value" ]]; then
```

### 5. "Context lost" after Claude compaction

**Problem**: Session context was compacted and progress lost.

**Solution**:
```bash
# RDD automatically detects recovery mode
# Just run:
task recovery:check

# If recovery is needed:
task recovery:load

# View last checkpoint
task checkpoint:show
```

### 6. Hook not triggering

**Problem**: Hooks are not being executed.

**Solution**:
```bash
# Check hook configuration
cat .rdd/hooks.yml

# Verify hook is enabled
grep -A5 "hooks:" .rdd/hooks.yml

# Test hook manually
.rdd/hooks/pre-commit.sh

# Check hook logs
cat .rdd/logs/hooks.log
```

### 7. Notification not sending

**Problem**: Notifications are not being delivered.

**Solution**:
```bash
# Check notification configuration
cat .rdd/config.yml | grep -A20 "notifications:"

# Verify credentials are set
env | grep RDD_

# Test notification manually
task notify:test

# Check notification logs
cat .rdd/logs/notify.log
```

### 8. Permission denied errors

**Problem**: RBAC blocking operations.

**Solution**:
```bash
# Check current user permissions
task permissions:list

# Check RBAC configuration
cat .rdd/permissions.yml

# Temporarily disable RBAC for debugging
# In .rdd/permissions.yml:
# rbac:
#   enabled: false
```

### 9. Audit log not recording

**Problem**: Audit events are not being logged.

**Solution**:
```bash
# Check audit configuration
cat .rdd/audit.yml

# Verify audit is enabled
grep "enabled: true" .rdd/audit.yml

# Check audit log
cat .rdd/logs/audit.log

# Test audit logging
source .rdd/scripts/audit.sh
log_audit "TEST_EVENT" "test=true"
```

### 10. Checkpoint not saving

**Problem**: Checkpoints are not being created.

**Solution**:
```bash
# Check cache directory
ls -la .rdd/cache/

# Manually save checkpoint
task checkpoint:save

# View checkpoint
cat .rdd/cache/checkpoints.json

# Check for disk space
df -h .rdd/
```

## Error Codes Reference

| Code | Category | Description | Solution |
|------|----------|-------------|----------|
| E100 | Configuration | Missing config file | Create .rdd/config.yml |
| E101 | Configuration | Invalid YAML syntax | Validate YAML syntax |
| E200 | Notification | Missing credentials | Set RDD_WECOM_WEBHOOK |
| E201 | Notification | Invalid webhook URL | Check webhook configuration |
| E300 | Network | Connection timeout | Check network connectivity |
| E400 | Hook | Hook not found | Verify hook exists |
| E401 | Hook | Hook permission denied | Fix execute permission |
| E500 | Stage | Invalid stage number | Check roadmap |
| E600 | Permission | Permission denied | Check RBAC configuration |
| E700 | Audit | Audit log write failed | Check disk space/permissions |
| E800 | Degradation | Service degraded | Check system health |
| E900 | State | Checkpoint corrupted | Restore from backup |

## Debug Mode

Enable verbose output:

```bash
# Enable debug mode
export RDD_DEBUG=true
export VERBOSE=true

# Run with debug
task --verbose test

# View debug logs
tail -f .rdd/logs/debug.log
```

## Log Files

| Log File | Purpose |
|----------|---------|
| `.rdd/logs/audit.log` | Audit trail |
| `.rdd/logs/notify.log` | Notification history |
| `.rdd/logs/hooks.log` | Hook execution |
| `.rdd/logs/error.log` | Error events |
| `.rdd/logs/debug.log` | Debug output |

## Health Check Commands

```bash
# Full health check
task doctor

# Quick check
task doctor --quick

# Check specific component
task doctor --component hooks
task doctor --component tests
task doctor --component permissions

# Verbose output
task doctor --verbose
```

## Recovery Procedures

### Full System Recovery

```bash
# 1. Check if recovery is needed
task recovery:check

# 2. Load recovery state
task recovery:load

# 3. Verify environment
task doctor

# 4. Run tests
task test

# 5. Continue from checkpoint
task rdd:stage-auto
```

### Restore from Backup

```bash
# List available backups
ls -la .rdd/backups/

# Restore from backup
task rdd:restore BACKUP_FILE=.rdd/backups/backup-2026-03-08.tar.gz

# Verify restoration
task doctor
task test
```

## Still Having Issues?

1. Check the [FAQ](faq.md)
2. Search [GitHub Issues](https://github.com/your-org/rdd-framework/issues)
3. Open a new issue with:
   - Output of `task doctor`
   - Relevant log files
   - Steps to reproduce
