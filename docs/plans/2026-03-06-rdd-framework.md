# RDD Framework Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete RDD (Roadmap Driven Development) framework with Claude Code Skills, Commands, and Hook notification system.

**Architecture:** The framework consists of: (1) Directory structure and configuration files for RDD projects, (2) Specification documents for governance and execution, (3) Claude Code skills for RDD operations, (4) Commands for quick RDD actions, (5) Hook notification system with multiple channels.

**Tech Stack:** Claude Code Skills/Commands, YAML configuration, Markdown documentation, Shell scripts for hooks

---

## Phase 1: Core Framework (P0)

### Task 1: Create RDD Directory Structure

**Files:**
- Create: `.rdd/config.yml`
- Create: `.rdd/hooks.yml`
- Create: `.rdd/templates.yml`
- Create: `.rdd/checkpoints.yml`
- Create: `.rdd/cache/.gitkeep`
- Create: `docs/framework/.gitkeep`
- Create: `docs/stages/.gitkeep`
- Create: `docs/handoff/.gitkeep`

**Step 1: Create .rdd directory structure**

```bash
mkdir -p .rdd/cache
mkdir -p docs/framework
mkdir -p docs/stages
mkdir -p docs/handoff
```

**Step 2: Create .rdd/config.yml**

```yaml
# RDD Configuration
# This is the main configuration file for RDD (Roadmap Driven Development)

version: "1.0.0"
project:
  name: ""
  description: ""

# Stage settings
stage:
  # Minimum test coverage requirement
  min_coverage: 20
  # Maximum consecutive failures before pause
  max_failures: 3
  # Tech debt threshold for blocking
  tech_debt_threshold: 3

# Gate settings
gates:
  design_required: true
  review_required: true
  e2e_required: true
  docs_required: true

# Hook settings
hooks:
  enabled: false
  config_file: ".rdd/hooks.yml"
  templates_file: ".rdd/templates.yml"

# Notification settings
notifications:
  quiet_hours:
    enabled: true
    start: "22:00"
    end: "08:00"
    timezone: "Asia/Shanghai"
    bypass_for_p0: true
```

**Step 3: Create .rdd/hooks.yml**

```yaml
# Hook Notification Configuration
# Configure notification channels and triggers

# Notification channels
channels:
  # Enterprise WeChat Robot
  wecom:
    enabled: false
    webhook_url: "${WECOM_WEBHOOK_URL}"

  # Email (SMTP)
  email:
    enabled: false
    smtp_host: "${SMTP_HOST}"
    smtp_port: 587
    smtp_user: "${SMTP_USER}"
    smtp_pass: "${SMTP_PASS}"
    from: "rdd-agent@example.com"
    to: []

  # iOS Bark
  bark:
    enabled: false
    server: "https://api.day.app"
    key: "${BARK_KEY}"
    sound: "alarm"

  # Telegram Bot
  telegram:
    enabled: false
    bot_token: "${TELEGRAM_BOT_TOKEN}"
    chat_id: "${TELEGRAM_CHAT_ID}"

  # Generic Webhook
  webhook:
    enabled: false
    url: "${CUSTOM_WEBHOOK_URL}"
    method: POST
    headers:
      Authorization: "Bearer ${WEBHOOK_TOKEN}"
      Content-Type: "application/json"

# Trigger rules
triggers:
  # P0: Roadmap changed - requires human approval
  roadmap_change:
    level: P0
    channels: [wecom, email]
    block: true
    template: roadmap_change

  # P0: Consecutive failures
  consecutive_failure:
    level: P0
    channels: [wecom, bark, telegram]
    block: true
    template: failure_alert
    condition:
      failure_count: 3

  # P0: Core hypothesis invalidated
  hypothesis_invalid:
    level: P0
    channels: [wecom, email, bark]
    block: true
    template: hypothesis_invalid

  # P1: Model disagreement
  model_disagreement:
    level: P1
    channels: [wecom, email]
    block: false
    template: model_disagreement

  # P1: Tech debt threshold exceeded
  tech_debt_threshold:
    level: P1
    channels: [wecom, email]
    block: true
    template: tech_debt_alert
    condition:
      debt_count: 3

  # P2: Stage completed
  stage_complete:
    level: P2
    channels: [wecom]
    block: false
    template: stage_complete

  # P3: Daily report
  daily_report:
    level: P3
    channels: [email]
    block: false
    schedule: "0 18 * * *"
    template: daily_report

  # P3: Weekly report
  weekly_report:
    level: P3
    channels: [email]
    block: false
    schedule: "0 18 * * 5"
    template: weekly_report

# Retry settings
retry:
  max_attempts: 3
  backoff: exponential
  initial_delay: 1s
  max_delay: 30s
```

**Step 4: Create .rdd/templates.yml**

```yaml
# Notification Templates
# Templates for different notification scenarios

templates:
  # Roadmap change notification
  roadmap_change:
    title: "🛤️ Roadmap 变更 - 需要审核"
    body: |
      **项目**: {{project_name}}
      **变更类型**: {{change_type}}
      **变更内容**: {{change_description}}
      **当前 Stage**: Stage {{current_stage}}

      **请访问审核**: {{review_url}}

      ---
      此消息由 RDD Agent 自动发送
    block_message: "⏳ Roadmap 变更需要人工审核，Agent 已暂停"

  # Failure alert notification
  failure_alert:
    title: "🔴 连续失败告警"
    body: |
      **项目**: {{project_name}}
      **当前 Stage**: Stage {{current_stage}}
      **失败次数**: {{failure_count}} 次
      **最后失败原因**: {{last_failure_reason}}

      **失败日志**:
      ```
      {{failure_log}}
      ```

      **诊断报告**: {{diagnosis_url}}

      ---
      请尽快处理，Agent 已暂停等待人工介入
    block_message: "⏳ 连续失败 {{failure_count}} 次，Agent 已暂停"

  # Hypothesis invalidated notification
  hypothesis_invalid:
    title: "⚠️ 核心假设证伪"
    body: |
      **项目**: {{project_name}}
      **Stage**: Stage {{current_stage}}
      **假设来源**: {{hypothesis_source}}
      **原始假设**: {{original_hypothesis}}
      **实际观察**: {{actual_observation}}
      **影响范围**: {{impact_scope}}

      **决策需求**:
      - 是否需要调整 Roadmap？
      - 是否需要重新规划当前 Stage？

      **ADR 记录**: {{adr_url}}

      ---
      核心假设被证伪，需要人工决策下一步方向
    block_message: "⏳ 核心假设证伪，Agent 已暂停等待决策"

  # Model disagreement notification
  model_disagreement:
    title: "🤔 多模型分歧"
    body: |
      **项目**: {{project_name}}
      **Stage**: Stage {{current_stage}}
      **分歧类型**: {{disagreement_type}}

      **模型意见**:
      {{#each model_opinions}}
      - **{{model_name}}**: {{opinion}}
      {{/each}}

      **分歧点**: {{disagreement_point}}
      **建议操作**: {{suggested_action}}

      **Review 详情**: {{review_url}}

      ---
      多个模型意见分歧，建议人工审核
    block_message: "ℹ️ 多模型分歧，建议人工审核（不阻塞）"

  # Tech debt threshold notification
  tech_debt_alert:
    title: "📊 技术债超阈值"
    body: |
      **项目**: {{project_name}}
      **当前技术债**: {{debt_count}} 条
      **阈值**: {{threshold}}

      **架构级降级功能债务**:
      {{#each architecture_debts}}
      - {{title}} (优先级: {{priority}})
      {{/each}}

      **建议**: 安排专项迭代偿还技术债

      **技术债台账**: {{debt_url}}

      ---
      技术债超过阈值，建议暂停新 Stage
    block_message: "⏳ 技术债超阈值，Agent 已暂停等待处理"

  # Stage complete notification
  stage_complete:
    title: "✅ Stage 完成"
    body: |
      **项目**: {{project_name}}
      **完成 Stage**: Stage {{completed_stage}}
      **耗时**: {{duration}}

      **交付物**:
      {{#each deliverables}}
      - {{this}}
      {{/each}}

      **下一 Stage**: Stage {{next_stage}}

      **验收报告**: {{verification_url}}

      ---
      Stage {{completed_stage}} 已完成验收
    block_message: "✅ Stage {{completed_stage}} 完成"

  # Daily report notification
  daily_report:
    title: "📊 RDD 每日报告 - {{date}}"
    body: |
      **项目**: {{project_name}}
      **报告日期**: {{date}}

      ## 进度概览
      - 当前 Stage: Stage {{current_stage}}
      - 整体进度: {{progress}}% ({{completed_stages}}/{{total_stages}})
      - 今日完成: {{today_completed}}

      ## 今日活动
      {{#each today_activities}}
      - {{time}}: {{description}}
      {{/each}}

      ## 技术债状态
      - 总计: {{total_debts}} 条
      - 本周新增: {{weekly_new_debts}} 条
      - 本周偿还: {{weekly_resolved_debts}} 条

      ## 下一步
      {{next_steps}}

      ---
      由 RDD Agent 自动生成
    block_message: null

  # Weekly report notification
  weekly_report:
    title: "📈 RDD 周报 - {{week_range}}"
    body: |
      **项目**: {{project_name}}
      **报告周期**: {{week_range}}

      ## 本周概览
      - 完成 Stage 数: {{weekly_stages}}
      - 代码变更: +{{lines_added}} / -{{lines_removed}}
      - 测试覆盖率: {{coverage}}%

      ## Stage 进展
      {{#each stage_progress}}
      - Stage {{number}}: {{status}} ({{duration}})
      {{/each}}

      ## 技术债趋势
      - 期初: {{start_debts}} 条
      - 期末: {{end_debts}} 条
      - 新增: {{new_debts}} 条
      - 偿还: {{resolved_debts}} 条

      ## 决策记录
      {{#each decisions}}
      - ADR-{{number}}: {{title}}
      {{/each}}

      ## 风险与阻塞
      {{#each risks}}
      - {{description}} (影响: {{impact}})
      {{/each}}

      ## 下周计划
      {{next_week_plan}}

      ---
      由 RDD Agent 自动生成
    block_message: null
```

**Step 5: Create .rdd/checkpoints.yml**

```yaml
# Human Checkpoint Configuration
# Define when human intervention is required

checkpoints:
  # Stage completion review
  stage_complete_review:
    enabled: true
    level: P2
    block: false
    channels: [wecom]

  # ADR review
  adr_review:
    enabled: true
    level: P2
    block: false
    channels: [wecom]

  # New tech debt notification
  new_debt:
    enabled: true
    level: P2
    block: false
    channels: [wecom]

  # Daily progress sync
  daily_sync:
    enabled: true
    level: P3
    block: false
    channels: [email]
    schedule: "0 18 * * *"
```

**Step 6: Create placeholder files**

```bash
touch .rdd/cache/.gitkeep
touch docs/framework/.gitkeep
touch docs/stages/.gitkeep
touch docs/handoff/.gitkeep
```

**Step 7: Commit**

```bash
git add .rdd/ docs/
git commit -m "feat: create RDD directory structure and configuration files"
```

---

### Task 2: Create Core Specification Documents

**Files:**
- Create: `docs/framework/project-governance-spec.md`
- Create: `docs/framework/agentic-code-execution-spec.md`
- Create: `docs/framework/standards-authoring-spec.md`

**Step 1: Create project-governance-spec.md**

Create file `docs/framework/project-governance-spec.md` with content defining project-level governance rules including goals, acceptance criteria, anti-corruption mechanisms, quality gates, and documentation standards. Include sections for:
- 适用条件
- Must/Should/May 规则
- Good/Bad Case 示例
- 边界声明
- 冲突优先级
- 生命周期

**Step 2: Create agentic-code-execution-spec.md**

Create file `docs/framework/agentic-code-execution-spec.md` with content defining how agents should execute tasks including task startup behavior, tool usage standards, automation and recovery patterns, and failure handling procedures.

**Step 3: Create standards-authoring-spec.md**

Create file `docs/framework/standards-authoring-spec.md` with content defining how to write standards including required sections, formatting rules, review process, and maintenance guidelines.

**Step 4: Commit**

```bash
git add docs/framework/
git commit -m "feat: add core specification documents"
```

---

### Task 3: Create Core Documentation Templates

**Files:**
- Create: `docs/01-charter.md`
- Create: `docs/02-engineering-principles.md`
- Create: `docs/03-stage-based-development.md`
- Create: `docs/08-autonomous-decisions.md`
- Create: `docs/10-review-practices.md`
- Create: `docs/11-next-steps.md`
- Create: `docs/12-technical-debt.md`

**Step 1: Create 01-charter.md**

Create project charter template with sections for: project vision, goals, non-goals, success criteria, and boundaries.

**Step 2: Create 02-engineering-principles.md**

Create engineering principles document with core principles for RDD development.

**Step 3: Create 03-stage-based-development.md**

Create SBD specification document explaining stage model, completion criteria, testing strategy, and stage sizing rules.

**Step 4: Create 08-autonomous-decisions.md**

Create ADR (Autonomous Decision Record) template and index.

**Step 5: Create 10-review-practices.md**

Create review practices document with multi-model review methodology.

**Step 6: Create 11-next-steps.md**

Create next steps tracking document template.

**Step 7: Create 12-technical-debt.md**

Create technical debt tracking document template.

**Step 8: Commit**

```bash
git add docs/
git commit -m "feat: add core documentation templates"
```

---

### Task 4: Create Stage Document Templates

**Files:**
- Create: `docs/stages/stage-roadmap.md`
- Create: `docs/stages/stage-template.md`

**Step 1: Create stage-roadmap.md**

Create roadmap template with stage table, status tracking, and change log.

**Step 2: Create stage-template.md**

Create stage design document template with all required sections.

**Step 3: Commit**

```bash
git add docs/stages/
git commit -m "feat: add stage document templates"
```

---

### Task 5: Create Agent Entry Points

**Files:**
- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `CHANGELOG.md`

**Step 1: Create AGENTS.md**

Create agent entry point document with mandatory reading order, document update obligations, stage promotion rules, and review rules.

**Step 2: Create CLAUDE.md**

Create Claude Code specific entry point with tool execution rules and quick start commands.

**Step 3: Create CHANGELOG.md**

Create changelog following Keep a Changelog format.

**Step 4: Commit**

```bash
git add AGENTS.md CLAUDE.md CHANGELOG.md
git commit -m "feat: add agent entry points"
```

---

### Task 6: Create Taskfile Template

**Files:**
- Create: `Taskfile.yml`

**Step 1: Create Taskfile.yml**

Create task runner configuration with common RDD tasks:
- bootstrap
- doctor
- stage:verify
- stage:gate
- handoff:pack
- check

**Step 2: Commit**

```bash
git add Taskfile.yml
git commit -m "feat: add Taskfile template"
```

---

## Phase 2: Claude Code Skills (P0)

### Task 7: Create Skills Directory Structure

**Files:**
- Create: `.claude/skills/rdd-core.md`
- Create: `.claude/skills/rdd-templates.md`

**Step 1: Create skills directory**

```bash
mkdir -p .claude/skills
```

**Step 2: Create rdd-core.md skill**

Create the core RDD skill with:
- Overview and principles
- When to use
- Core workflow
- Anti-patterns
- Checklist

**Step 3: Create rdd-templates.md skill**

Create the templates skill with all document templates:
- Stage template
- ADR template
- Tech debt template
- Handoff template
- Review log template

**Step 4: Commit**

```bash
git add .claude/skills/
git commit -m "feat: add RDD core skills"
```

---

### Task 8: Create rdd-init Skill

**Files:**
- Create: `.claude/skills/rdd-init.md`

**Step 1: Create rdd-init skill**

Create skill for initializing new RDD projects:
- Trigger conditions
- Initialization steps
- Directory creation
- Configuration setup
- Validation checklist

**Step 2: Commit**

```bash
git add .claude/skills/rdd-init.md
git commit -m "feat: add rdd-init skill"
```

---

### Task 9: Create rdd-migrate Skill

**Files:**
- Create: `.claude/skills/rdd-migrate.md`

**Step 1: Create rdd-migrate skill**

Create skill for migrating existing projects:
- Analysis steps
- Migration checklist
- Document transformation
- Validation

**Step 2: Commit**

```bash
git add .claude/skills/rdd-migrate.md
git commit -m "feat: add rdd-migrate skill"
```

---

### Task 10: Create rdd-roadmap Skill

**Files:**
- Create: `.claude/skills/rdd-roadmap.md`

**Step 1: Create rdd-roadmap skill**

Create skill for roadmap management:
- Creating roadmap
- Adding stages
- Reordering stages
- Progress tracking

**Step 2: Commit**

```bash
git add .claude/skills/rdd-roadmap.md
git commit -m "feat: add rdd-roadmap skill"
```

---

### Task 11: Create rdd-stage-auto Skill

**Files:**
- Create: `.claude/skills/rdd-stage-auto.md`

**Step 1: Create rdd-stage-auto skill**

Create skill for automatic stage execution:
- Gate checking
- Design document generation
- Review triggering
- Implementation guidance
- Completion verification

**Step 2: Commit**

```bash
git add .claude/skills/rdd-stage-auto.md
git commit -m "feat: add rdd-stage-auto skill"
```

---

### Task 12: Create rdd-knowledge Skill

**Files:**
- Create: `.claude/skills/rdd-knowledge.md`

**Step 1: Create rdd-knowledge skill**

Create skill for knowledge management:
- ADR management
- Tech debt management
- Handoff generation
- Context persistence

**Step 2: Commit**

```bash
git add .claude/skills/rdd-knowledge.md
git commit -m "feat: add rdd-knowledge skill"
```

---

### Task 13: Create rdd-loop Skill

**Files:**
- Create: `.claude/skills/rdd-loop.md`

**Step 1: Create rdd-loop skill**

Create skill for automatic loop execution:
- State monitoring
- Stage progression
- Exception handling
- Human checkpoint handling

**Step 2: Commit**

```bash
git add .claude/skills/rdd-loop.md
git commit -m "feat: add rdd-loop skill"
```

---

## Phase 3: Claude Code Commands (P0/P1)

### Task 14: Create Commands Directory Structure

**Files:**
- Create: `.claude/commands/rdd.md`
- Create: `.claude/commands/rdd-init.md`
- Create: `.claude/commands/rdd-migrate.md`
- Create: `.claude/commands/rdd-roadmap.md`
- Create: `.claude/commands/rdd-stage.md`
- Create: `.claude/commands/rdd-review.md`
- Create: `.claude/commands/rdd-debt.md`
- Create: `.claude/commands/rdd-adr.md`
- Create: `.claude/commands/rdd-handoff.md`
- Create: `.claude/commands/rdd-diagnose.md`
- Create: `.claude/commands/rdd-loop.md`
- Create: `.claude/commands/rdd-hooks.md`

**Step 1: Create commands directory**

```bash
mkdir -p .claude/commands
```

**Step 2: Create each command file**

For each command, create a markdown file with:
- Command description
- Arguments
- Options
- Examples
- Implementation guidance

**Step 3: Commit**

```bash
git add .claude/commands/
git commit -m "feat: add RDD commands"
```

---

## Phase 4: Hook Notification System (P0-P1)

### Task 15: Create Hook Notification Scripts

**Files:**
- Create: `.rdd/scripts/notify.sh`
- Create: `.rdd/scripts/wecom.sh`
- Create: `.rdd/scripts/email.sh`
- Create: `.rdd/scripts/bark.sh`
- Create: `.rdd/scripts/telegram.sh`
- Create: `.rdd/scripts/webhook.sh`

**Step 1: Create scripts directory**

```bash
mkdir -p .rdd/scripts
chmod +x .rdd/scripts/*.sh
```

**Step 2: Create notify.sh main script**

Create main notification orchestration script that:
- Reads hooks.yml configuration
- Selects appropriate channels based on trigger level
- Renders templates with variables
- Calls channel-specific scripts
- Handles retry logic

**Step 3: Create wecom.sh**

Create Enterprise WeChat notification script.

**Step 4: Create email.sh**

Create email notification script using sendmail or SMTP.

**Step 5: Create bark.sh**

Create iOS Bark notification script.

**Step 6: Create telegram.sh**

Create Telegram Bot notification script.

**Step 7: Create webhook.sh**

Create generic webhook notification script.

**Step 8: Commit**

```bash
git add .rdd/scripts/
git commit -m "feat: add hook notification scripts"
```

---

### Task 16: Create Hook Integration Points

**Files:**
- Create: `.rdd/hooks/pre-stage.sh`
- Create: `.rdd/hooks/post-stage.sh`
- Create: `.rdd/hooks/on-failure.sh`
- Create: `.rdd/hooks/on-roadmap-change.sh`

**Step 1: Create hook scripts**

Create hook scripts that integrate with RDD workflow:
- pre-stage.sh: Called before stage execution
- post-stage.sh: Called after stage completion
- on-failure.sh: Called on consecutive failures
- on-roadmap-change.sh: Called on roadmap modifications

**Step 2: Commit**

```bash
git add .rdd/hooks/
git commit -m "feat: add hook integration points"
```

---

## Phase 5: P1 Skills

### Task 17: Create rdd-review-auto Skill

**Files:**
- Create: `.claude/skills/rdd-review-auto.md`

**Step 1: Create rdd-review-auto skill**

Create skill for automated review with:
- Multi-model review triggering
- AI filtering of findings
- Rule-based filtering
- Verification methods

**Step 2: Commit**

```bash
git add .claude/skills/rdd-review-auto.md
git commit -m "feat: add rdd-review-auto skill"
```

---

### Task 18: Create rdd-recovery Skill

**Files:**
- Create: `.claude/skills/rdd-recovery.md`

**Step 1: Create rdd-recovery skill**

Create skill for failure recovery with:
- Failure analysis
- Automatic fix attempts
- Diagnostic report generation
- Human escalation

**Step 2: Commit**

```bash
git add .claude/skills/rdd-recovery.md
git commit -m "feat: add rdd-recovery skill"
```

---

### Task 19: Create rdd-diagnosis Skill

**Files:**
- Create: `.claude/skills/rdd-diagnosis.md`

**Step 1: Create rdd-diagnosis skill**

Create skill for RDD problem diagnosis with:
- Common issue patterns
- Diagnostic checklist
- Solution suggestions
- Fix recommendations

**Step 2: Commit**

```bash
git add .claude/skills/rdd-diagnosis.md
git commit -m "feat: add rdd-diagnosis skill"
```

---

### Task 20: Create rdd-fresh-check Skill

**Files:**
- Create: `.claude/skills/rdd-fresh-check.md`

**Step 1: Create rdd-fresh-check skill**

Create skill for fresh agent verification with:
- Empty context agent launch
- Documentation completeness check
- Self-bootstrap verification
- Report generation

**Step 2: Commit**

```bash
git add .claude/skills/rdd-fresh-check.md
git commit -m "feat: add rdd-fresh-check skill"
```

---

## Phase 6: Documentation and Testing

### Task 21: Create README

**Files:**
- Create: `README.md`

**Step 1: Create comprehensive README**

Create README with:
- Project introduction
- Quick start guide
- Installation instructions
- Configuration guide
- Usage examples
- Contributing guidelines

**Step 2: Commit**

```bash
git add README.md
git commit -m "feat: add comprehensive README"
```

---

### Task 22: Create Test Project

**Files:**
- Create: `tests/test-project/.rdd/config.yml`
- Create: `tests/test-project/docs/stages/stage-0.md`

**Step 1: Create test project structure**

Create minimal test project to validate:
- Init command
- Stage creation
- Gate checking
- Notification triggering

**Step 2: Commit**

```bash
git add tests/
git commit -m "feat: add test project"
```

---

### Task 23: Validation and Testing

**Step 1: Test rdd-init**

Validate that `rdd init` creates correct structure.

**Step 2: Test rdd-migrate**

Validate migration detection and transformation.

**Step 3: Test hook notifications**

Validate each notification channel works.

**Step 4: Test fresh-check**

Validate fresh agent can bootstrap.

**Step 5: Final commit**

```bash
git add .
git commit -m "feat: complete RDD framework implementation"
```

---

## Summary

| Phase | Tasks | Priority |
|-------|-------|----------|
| Phase 1 | Tasks 1-6: Core Framework | P0 |
| Phase 2 | Tasks 7-13: Claude Code Skills (P0) | P0 |
| Phase 3 | Tasks 14: Claude Code Commands | P0/P1 |
| Phase 4 | Tasks 15-16: Hook Notification System | P0/P1 |
| Phase 5 | Tasks 17-20: P1 Skills | P1 |
| Phase 6 | Tasks 21-23: Documentation and Testing | P1 |

Total: 23 tasks across 6 phases.
