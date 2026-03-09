# Multi-Stage Project Example

这是一个多 Stage 的 RDD Framework 项目示例，展示复杂项目的组织方式。

## 项目结构

```
multi-stage-project/
├── .rdd/
│   ├── config/
│   │   └── config.yml       # 项目配置
│   ├── hooks/
│   │   ├── stage-complete.sh
│   │   ├── roadmap-change.sh
│   │   └── consecutive-failure.sh
│   ├── cache/
│   │   ├── checkpoints.json
│   │   └── handoff.md
│   └── scripts/
│       └── custom-utils.sh
├── docs/
│   ├── stages/
│   │   ├── stage-roadmap.md
│   │   ├── stage-1.md
│   │   ├── stage-2.md
│   │   └── stage-3.md
│   ├── 01-charter.md
│   ├── 02-engineering-principles.md
│   ├── 08-autonomous-decisions.md
│   ├── 11-next-steps.md
│   └── 12-technical-debt.md
├── tests/
│   ├── unit/
│   ├── bdd/
│   └── e2e/
├── AGENTS.md
├── CLAUDE.md
└── Taskfile.yml
```

## Stage 规划

### Stage 1: 基础架构

**目标**：建立项目基础架构

**验收标准**：
- [ ] 目录结构创建
- [ ] 配置系统实现
- [ ] 基础 Hook 配置
- [ ] 单元测试框架

**预计时间**：1-2 天

### Stage 2: 核心功能

**目标**：实现核心业务功能

**验收标准**：
- [ ] 核心功能实现
- [ ] API 接口完成
- [ ] 集成测试通过
- [ ] 文档更新

**预计时间**：3-5 天

**依赖**：Stage 1 完成

### Stage 3: 优化与发布

**目标**：性能优化和发布准备

**验收标准**：
- [ ] 性能达标
- [ ] 文档完整
- [ ] CI/CD 配置
- [ ] 发布就绪

**预计时间**：2-3 天

**依赖**：Stage 2 完成

## 多 Stage 工作流

### Stage 转换

```
Stage N 完成
    ↓
Gate 5 检查
    ↓
更新文档
    ↓
触发 Hook
    ↓
Stage N+1 开始
```

### Gate 检查流程

每个 Stage 必须通过 5 个 Gate：

| Gate | 检查内容 |
|------|----------|
| Gate 1 | 设计文档完整性 |
| Gate 2 | 设计评审通过 |
| Gate 3 | 实现和测试完成 |
| Gate 4 | 代码评审通过 |
| Gate 5 | 完成度验证 |

### 检查点系统

在关键节点保存检查点：

```bash
# 保存检查点
task checkpoint:save

# 查看检查点
task checkpoint:show

# 恢复检查点
task recovery:load
```

### Handoff 流程

Agent 切换时的上下文传递：

```bash
# 生成 Handoff 文档
task handoff:generate

# 验证 Handoff 文档
task handoff:validate

# 查看最新 Handoff
cat docs/handoff/handoff-latest.md
```

## 高级配置

### 多 Hook 配置

```yaml
# .rdd/config/config.yml
hooks:
  enabled: true
  channels:
    # 企业微信
    - type: wecom
      webhook: ${WECOM_WEBHOOK_URL}
      events: [stage_complete, roadmap_change]

    # 邮件通知
    - type: email
      smtp_host: ${SMTP_HOST}
      smtp_port: ${SMTP_PORT}
      events: [consecutive_failure]

    # Slack
    - type: slack
      webhook: ${SLACK_WEBHOOK_URL}
      events: [stage_complete]
```

### 自定义脚本

```bash
#!/usr/bin/env bash
# .rdd/scripts/custom-utils.sh

# 自定义通知函数
custom_notify() {
    local title="$1"
    local message="$2"

    # 发送到自定义渠道
    curl -X POST "${CUSTOM_WEBHOOK_URL}" \
        -H "Content-Type: application/json" \
        -d "{\"title\": \"${title}\", \"message\": \"${message}\"}"
}

# 自定义验证函数
validate_environment() {
    # 检查必要的环境变量
    local required_vars=(
        "PROJECT_NAME"
        "ENVIRONMENT"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "ERROR: ${var} is not set"
            return 1
        fi
    done

    return 0
}
```

### 技术债管理

在 `docs/12-technical-debt.md` 记录技术债：

```markdown
### TD-01: 需要重构登录模块

- **优先级**：降级功能 / 模块级
- **来源**：Stage 2 审阅（Stage 2）
- **原始描述**："登录模块代码复杂度高"
- **建议落地 Stage**：Stage 3
- **当前状态**：[ ] 待处理
```

### ADR 记录

在 `docs/08-autonomous-decisions.md` 记录决策：

```markdown
### 决策 1：选择 PostgreSQL 作为主数据库

**背景**：需要选择持久化存储方案

**决策内容**：使用 PostgreSQL 作为主数据库

**原因**：
- 成熟稳定
- 社区活跃
- 支持 JSON 类型

**对后续 Stage 的影响**：
- Stage 2 需要设计 Schema
- Stage 3 需要优化查询
```

## 测试策略

### 测试层次

```
E2E 测试 (端到端)
    ↓
BDD 测试 (行为驱动)
    ↓
单元测试 (函数级)
```

### 测试命令

```bash
# 运行所有测试
task test

# 运行单元测试
task test:unit

# 运行 BDD 测试
task test:bdd

# 运行 E2E 测试
task test:e2e

# 生成覆盖率报告
task test:coverage
```

## 最佳实践

### 1. Stage 粒度控制

- 每个 Stage 聚焦单一目标
- 预计时间 1-5 天
- 可验证的验收标准

### 2. 文档同步

- 代码变更同步更新文档
- ADR 记录重要决策
- 技术债及时记录

### 3. Gate 验证

- 不跳过任何 Gate
- Gate 失败立即修复
- 保留验证记录

### 4. Hook 利用

- Stage 完成自动通知
- Roadmap 变更触发告警
- 连续失败人工介入

## 常见问题

### Q: Stage 如何划分？

A: 按照功能独立性和验收标准划分。每个 Stage 应该：
- 有明确的目标
- 可独立测试
- 有清晰的边界

### Q: Gate 检查失败怎么办？

A: 按以下步骤处理：
1. 查看 Gate 失败原因
2. 修复问题
3. 重新运行 Gate
4. 记录处理过程

### Q: 如何处理技术债？

A:
1. 记录在技术债台账
2. 评估优先级
3. 安排在后续 Stage
4. 定期回顾

## 下一步

- 阅读 [Stage 工作流详解](../../docs/03-stage-based-development.md)
- 了解 [Hook 系统](../../docs/user-guide/advanced-usage.md)
- 查看 [故障排查指南](../../docs/operations/troubleshooting.md)
