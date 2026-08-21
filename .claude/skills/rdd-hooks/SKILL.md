---
name: rdd-hooks
description: RDD hooks reference: trigger rules and hook invocation utilities
disable-model-invocation: true
---

# RDD Hooks Skill

> **Purpose**: Define Hook trigger rules and provide Hook invocation utilities.

## Overview

Hooks are the notification mechanism in RDD that alert humans when intervention is needed. This skill defines when and how to trigger each hook type.

**When to Use:**
- When a stage completes
- When roadmap changes
- When consecutive failures occur
- When a hypothesis is invalidated
- When model disagreement is detected
- When tech debt threshold is exceeded
- For daily/weekly reports

**Command:** `/rdd-hooks <hook-type> [options]`

---

## Hook Types

| Hook | Trigger | Priority | When to Call |
|------|---------|----------|--------------|
| `stage-complete` | Stage completion | P2 | After Gate 5 passes |
| `roadmap-change` | Roadmap modification | P1 | When roadmap is changed by human |
| `consecutive-failure` | Multiple failures | P0 | After 3+ consecutive failures |
| `hypothesis-invalid` | Hypothesis falsified | P1 | When core hypothesis is proven wrong |
| `model-disagreement` | Model conflict | P2 | When models disagree significantly |
| `tech-debt-threshold` | Debt limit reached | P1 | When tech debt exceeds threshold |
| `daily-report` | Scheduled | P3 | Daily at scheduled time |
| `weekly-report` | Scheduled | P3 | Weekly at scheduled time |

---

## Hook Invocation

### From Skills

In any skill, invoke a hook by:

```bash
# Set environment variables
export RDD_PROJECT_NAME="My Project"
export RDD_STAGE_NUMBER="1"
export RDD_STAGE_NAME="Stage 1 Name"

# Call the hook script
"${PROJECT_ROOT}/.rdd/hooks/stage-complete.sh"
```

### From Commands

```bash
# Using task command
task hooks:stage-complete

# With environment variables
RDD_STAGE_NUMBER=1 RDD_STAGE_NAME="Setup" task hooks:stage-complete
```

### Direct Invocation

```bash
# Direct script call
./.rdd/hooks/stage-complete.sh

# With environment variables
RDD_PROJECT_NAME="MyApp" RDD_STAGE_NUMBER=1 ./.rdd/hooks/stage-complete.sh
```

---

## Hook Integration Points

### Stage Completion Hook

**Trigger Point:** In `rdd-stage-auto.md`, after Gate 5 passes:

```markdown
## GATE 5: Completion Gate Check

### After All Checks Pass

1. Update all documents
2. Mark stage complete
3. **Trigger Hook: stage-complete**
```

**Implementation:**
```bash
# After Gate 5 passes
export RDD_STAGE_NUMBER="${CURRENT_STAGE}"
export RDD_STAGE_NAME="${STAGE_NAME}"
export RDD_STAGE_DURATION="${DURATION}"
export RDD_COVERAGE="${COVERAGE_PERCENT}"
export RDD_PROJECT_NAME="${PROJECT_NAME}"

"${RDD_DIR}/hooks/stage-complete.sh"
```

### Roadmap Change Hook

**Trigger Point:** In `rdd-roadmap.md`, when roadmap is modified:

```markdown
## Roadmap Modification

1. Verify changes
2. Update roadmap file
3. **Trigger Hook: roadmap-change**
4. Wait for human approval (P1)
```

**Implementation:**
```bash
export RDD_CHANGE_TYPE="${CHANGE_TYPE}"  # add/remove/reorder/modify
export RDD_CHANGED_BY="${CHANGED_BY}"     # human/agent
export RDD_PROJECT_NAME="${PROJECT_NAME}"
export RDD_CHANGE_DETAILS="${DETAILS}"

"${RDD_DIR}/hooks/roadmap-change.sh"
```

### Consecutive Failure Hook

**Trigger Point:** In `rdd-loop.md`, after max retries:

```markdown
## Error Handling

After 3 consecutive failures:
1. Stop current work
2. Create handoff document
3. **Trigger Hook: consecutive-failure**
```

**Implementation:**
```bash
export RDD_STAGE_NUMBER="${CURRENT_STAGE}"
export RDD_STAGE_NAME="${STAGE_NAME}"
export RDD_FAILURE_COUNT="${FAILURE_COUNT}"
export RDD_LAST_ERROR="${LAST_ERROR}"
export RDD_PROJECT_NAME="${PROJECT_NAME}"

"${RDD_DIR}/hooks/consecutive-failure.sh"
```

### Hypothesis Invalid Hook

**Trigger Point:** In `rdd-stage-auto.md`, when hypothesis is falsified:

```markdown
## Hypothesis Verification

If hypothesis is proven wrong:
1. Document findings
2. Update ADR
3. **Trigger Hook: hypothesis-invalid**
```

**Implementation:**
```bash
export RDD_STAGE_NUMBER="${CURRENT_STAGE}"
export RDD_HYPOTHESIS="${HYPOTHESIS_TEXT}"
export RDD_REASON="${INVALIDATION_REASON}"
export RDD_EVIDENCE="${EVIDENCE}"
export RDD_PROJECT_NAME="${PROJECT_NAME}"

"${RDD_DIR}/hooks/hypothesis-invalid.sh"
```

### Model Disagreement Hook

**Trigger Point:** In `rdd-review-auto.md`, when models disagree:

```markdown
## Multi-Model Review

If models disagree significantly:
1. Document disagreement
2. **Trigger Hook: model-disagreement**
```

**Implementation:**
```bash
export RDD_MODELS="${MODEL_NAMES}"
export RDD_CONTEXT="${CONTEXT}"
export RDD_FINDING_A="${FINDING_A}"
export RDD_FINDING_B="${FINDING_B}"
export RDD_STAGE_NUMBER="${CURRENT_STAGE}"
export RDD_PROJECT_NAME="${PROJECT_NAME}"

"${RDD_DIR}/hooks/model-disagreement.sh"
```

### Tech Debt Threshold Hook

**Trigger Point:** In `rdd-knowledge.md`, when debt exceeds threshold:

```markdown
## Tech Debt Management

When tech debt count exceeds threshold:
1. Record debt
2. **Trigger Hook: tech-debt-threshold**
```

**Implementation:**
```bash
export RDD_DEBT_COUNT="${DEBT_COUNT}"
export RDD_THRESHOLD="${THRESHOLD}"
export RDD_DEBT_PRIORITY="${PRIORITY}"
export RDD_PROJECT_NAME="${PROJECT_NAME}"

"${RDD_DIR}/hooks/tech-debt-threshold.sh"
```

### Daily Report Hook

**Trigger Point:** Scheduled (typically 09:00 daily):

```bash
# In crontab or scheduled task
0 9 * * * RDD_PROJECT_NAME="MyApp" /path/to/.rdd/hooks/daily-report.sh
```

### Weekly Report Hook

**Trigger Point:** Scheduled (typically Monday 09:00):

```bash
# In crontab or scheduled task
0 9 * * 1 RDD_PROJECT_NAME="MyApp" /path/to/.rdd/hooks/weekly-report.sh
```

---

## Environment Variables

### Common Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_DIR` | RDD configuration directory | No (auto-detected) |
| `RDD_PROJECT_NAME` | Project name | Yes |
| `DRY_RUN` | Skip actual sending | No (default: false) |
| `VERBOSE` | Enable debug output | No (default: false) |

### Hook-Specific Variables

#### stage-complete
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_STAGE_NUMBER` | Stage number | Yes |
| `RDD_STAGE_NAME` | Stage name | Yes |
| `RDD_STAGE_DURATION` | Time taken | No |
| `RDD_COVERAGE` | Test coverage % | No |

#### roadmap-change
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_CHANGE_TYPE` | add/remove/reorder/modify | Yes |
| `RDD_CHANGED_BY` | human/agent | Yes |
| `RDD_CHANGE_DETAILS` | Change description | No |

#### consecutive-failure
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_STAGE_NUMBER` | Current stage | Yes |
| `RDD_STAGE_NAME` | Stage name | No |
| `RDD_FAILURE_COUNT` | Number of failures | Yes |
| `RDD_LAST_ERROR` | Last error message | No |

#### hypothesis-invalid
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_STAGE_NUMBER` | Current stage | Yes |
| `RDD_HYPOTHESIS` | Invalidated hypothesis | Yes |
| `RDD_REASON` | Why invalidated | Yes |
| `RDD_EVIDENCE` | Supporting evidence | No |

#### model-disagreement
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_MODELS` | Model names | Yes |
| `RDD_CONTEXT` | Disagreement context | Yes |
| `RDD_FINDING_A` | First finding | No |
| `RDD_FINDING_B` | Second finding | No |

#### tech-debt-threshold
| Variable | Description | Required |
|----------|-------------|----------|
| `RDD_DEBT_COUNT` | Current debt count | Yes |
| `RDD_THRESHOLD` | Configured threshold | Yes |
| `RDD_DEBT_PRIORITY` | New debt priority | No |

---

## Configuration

Hooks read configuration from `.rdd/hooks.yml`:

```yaml
channels:
  wecom:
    enabled: true
    webhook_url: "${WECOM_WEBHOOK_URL}"
  email:
    enabled: false
  bark:
    enabled: false
  telegram:
    enabled: false
  webhook:
    enabled: false

triggers:
  stage_complete:
    enabled: true
    channels: [wecom]
  consecutive_failure:
    enabled: true
    channels: [wecom, email]
```

### Environment Variable Substitution

Configuration values support `${VAR}` syntax for environment variables:

```yaml
channels:
  wecom:
    webhook_url: "${WECOM_WEBHOOK_URL}"  # Will use $WECOM_WEBHOOK_URL
  telegram:
    bot_token: "${TELEGRAM_BOT_TOKEN}"   # Will use $TELEGRAM_BOT_TOKEN
```

---

## Testing Hooks

### Dry Run Mode

```bash
# Test without sending notifications
DRY_RUN=true ./.rdd/hooks/stage-complete.sh

# With verbose output
DRY_RUN=true VERBOSE=true ./.rdd/hooks/stage-complete.sh
```

### Manual Trigger

```bash
# Using task command
task hooks:test stage-complete

# Direct invocation
RDD_PROJECT_NAME="Test" \
RDD_STAGE_NUMBER="1" \
RDD_STAGE_NAME="Test Stage" \
DRY_RUN=true \
./.rdd/hooks/stage-complete.sh
```

---

## Hook Priority and Blocking

| Priority | Description | Blocks Agent? |
|----------|-------------|---------------|
| P0 | Critical - needs immediate attention | Yes |
| P1 | Important - needs attention within hours | No, but notify |
| P2 | Normal - review when convenient | No |
| P3 | Low - for records only | No |

### P0/P1 Notification Behavior

When a P0 or P1 hook fires:
1. Agent should pause current work
2. Handoff document is generated (for P0)
3. Human is notified via configured channels
4. Agent waits for response (P0) or continues with caution (P1)

---

## Troubleshooting

### Hook Not Firing

1. Check hook script is executable: `ls -la .rdd/hooks/`
2. Check environment variables are set
3. Check notify.sh is sourced correctly
4. Run with VERBOSE=true for debug output

### Notification Not Sent

1. Check channel is enabled in hooks.yml
2. Check channel credentials are configured
3. Run with DRY_RUN=true to test locally
4. Check network connectivity

### Variable Not Substituted

1. Ensure variable is exported: `export RDD_PROJECT_NAME="MyApp"`
2. Check variable name spelling
3. Run with VERBOSE=true to see parsed values

---

## Reference

- `.rdd/hooks.yml` - Channel configuration
- `.rdd/templates.yml` - Message templates
- `.rdd/scripts/notify.sh` - Notification dispatcher
