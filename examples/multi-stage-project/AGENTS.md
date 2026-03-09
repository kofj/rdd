# Agent 入口文件

> 这是多 Stage 项目的 AI Agent 主要入口文件。

## 项目概述

这是一个多 Stage 的 RDD Framework 项目示例，展示复杂项目的组织和工作方式。

## 当前状态

| 项目 | 状态 |
|------|------|
| 当前 Stage | Stage 1: 基础架构 |
| 进度 | ⏳ 待开始 |
| 下一步 | 查看 `docs/stages/stage-1.md` |

## 快速开始

### 1. 了解项目
```bash
# 查看项目状态
task status

# 查看健康检查
task doctor

# 查看 Roadmap
cat docs/stages/stage-roadmap.md
```

### 2. 开始 Stage 1
```bash
# 阅读 Stage 1 文档
cat docs/stages/stage-1.md

# 运行 Gate 1 检查
task gate-1
```

### 3. 提交完成
```bash
# 保存检查点
task checkpoint:save

# 验证 Stage
task stage:verify

# 生成 Handoff
task handoff:generate
```

## 核心规则

### RDD 开发规则

1. **Stage 驱动**：所有工作围绕当前 Stage 目标
2. **Gate 验证**：Stage 完成前必须通过所有 Gate
3. **文档同步**：代码变更同步更新文档
4. **技术债可见**：所有妥协记录在技术债台账
5. **决策可追溯**：重要决策记录在 ADR

### 禁止行为

1. **跳过 Gate**：不通过 Gate 不能标记 Stage 完成
2. **扩大范围**：不能擅自添加非目标功能
3. **隐藏问题**：所有问题必须记录
4. **忽略技术债**：技术债必须记录在台账

## 多 Stage 工作流

### Stage 生命周期

```
规划 → 设计 → 实现 → 测试 → Gate检查 → 完成
```

### Gate 检查点

| Gate | 检查内容 | 通过条件 |
|------|----------|----------|
| Gate 1 | 设计文档 | 文档完整、目标明确 |
| Gate 2 | 设计评审 | 评审通过、问题解决 |
| Gate 3 | 实现测试 | 测试通过、覆盖达标 |
| Gate 4 | 代码评审 | 评审通过、规范达标 |
| Gate 5 | 完成验证 | 所有标准满足 |

### 检查点机制

关键节点保存状态：

```bash
# 保存检查点
task checkpoint:save

# 查看当前检查点
task checkpoint:show

# 恢复检查点
task recovery:load
```

### Handoff 机制

Agent 切换时传递上下文：

```bash
# 生成 Handoff
task handoff:generate

# 验证 Handoff
task handoff:validate

# 查看 Handoff
cat docs/handoff/handoff-latest.md
```

## 文件导航

### 核心文档

| 文件 | 用途 | 优先级 |
|------|------|--------|
| docs/11-next-steps.md | 下一步行动 | 高 |
| docs/stages/stage-N.md | 当前 Stage 文档 | 高 |
| docs/stages/stage-roadmap.md | 整体规划 | 高 |
| docs/08-autonomous-decisions.md | 决策记录 | 中 |
| docs/12-technical-debt.md | 技术债台账 | 中 |

### 配置文件

| 文件 | 用途 |
|------|------|
| .rdd/config/config.yml | 项目配置 |
| .rdd/hooks/*.sh | Hook 脚本 |
| Taskfile.yml | Task 定义 |

### 缓存文件

| 文件 | 用途 |
|------|------|
| .rdd/cache/checkpoints.json | 检查点数据 |
| .rdd/cache/handoff.md | Handoff 文档 |

## 命令参考

### 项目管理

```bash
task doctor          # 项目健康检查
task status          # 项目状态概览
task roadmap         # 显示 Roadmap
task version         # 显示版本
```

### Stage 管理

```bash
task gate-check      # 运行所有 Gate
task gate-1          # Gate 1: 设计文档
task gate-2          # Gate 2: 设计评审
task gate-3          # Gate 3: 实现测试
task gate-4          # Gate 4: 代码评审
task gate-5          # Gate 5: 完成验证
task stage:verify    # 验证 Stage 完成
```

### 测试

```bash
task test            # 运行所有测试
task test:unit       # 运行单元测试
task test:bdd        # 运行 BDD 测试
task test:e2e        # 运行 E2E 测试
task test:coverage   # 生成覆盖率报告
```

### RDD 功能

```bash
task rdd:health      # RDD 健康检查
task rdd:backup      # 创建备份
task rdd:restore     # 恢复备份
task rdd:audit       # 查看审计日志
```

### 检查点和恢复

```bash
task checkpoint:save   # 保存检查点
task checkpoint:show   # 显示检查点
task recovery:check    # 检查是否需要恢复
task recovery:load     # 加载恢复点
task handoff:generate  # 生成 Handoff
task handoff:validate  # 验证 Handoff
```

## 问题排查

### Gate 检查失败

1. 查看失败原因
2. 修复问题
3. 重新运行 Gate
4. 记录处理过程

### 测试失败

1. 查看错误日志
2. 定位问题代码
3. 修复并验证
4. 更新相关测试

### Hook 触发失败

1. 检查配置文件
2. 验证环境变量
3. 查看 Hook 脚本日志
4. 手动触发测试

## 最佳实践

### 每个 Stage 开始时

1. 阅读 Stage 文档
2. 检查依赖 Stage 状态
3. 保存初始检查点
4. 确认验收标准

### Stage 执行中

1. 定期保存检查点
2. 及时记录决策
3. 更新技术债台账
4. 保持文档同步

### Stage 完成时

1. 运行所有 Gate
2. 更新 Roadmap
3. 生成 Handoff
4. 触发 Stage 完成 Hook

---

> **提示**：遇到问题时，查看 `docs/operations/troubleshooting.md` 获取帮助。
