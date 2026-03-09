# Agent 入口文件

> 这是 AI Agent 的主要入口文件。

## 项目概述

这是一个简单的 RDD Framework 项目示例。

## 快速开始

1. 阅读 `docs/stages/stage-1.md` 了解当前 Stage 目标
2. 检查 `docs/11-next-steps.md` 了解下一步行动
3. 运行 `task doctor` 验证项目状态

## 核心规则

### 必须遵守

1. **Stage 驱动开发**：所有工作必须围绕 Stage 目标展开
2. **Gate 检查**：Stage 完成前必须通过所有 Gate
3. **文档同步**：代码变更必须同步更新文档
4. **测试验证**：所有代码必须有测试覆盖

### 禁止行为

1. **跳过 Gate**：不通过 Gate 不能标记 Stage 完成
2. **扩大范围**：不能擅自添加非目标功能
3. **隐藏技术债**：所有妥协必须记录在技术债台账

## 文件导航

| 文件 | 用途 |
|------|------|
| AGENTS.md | Agent 入口（本文件） |
| CLAUDE.md | Claude Code 入口 |
| docs/11-next-steps.md | 下一步计划 |
| docs/stages/stage-1.md | 当前 Stage 文档 |
| docs/08-autonomous-decisions.md | 决策记录 |
| docs/12-technical-debt.md | 技术债台账 |

## 命令参考

```bash
# 项目检查
task doctor          # 健康检查
task status          # 状态概览
task test            # 运行测试

# Stage 管理
task gate-check      # Gate 检查
task stage:verify    # 验证 Stage 完成

# RDD 功能
task rdd:health      # RDD 健康检查
task rdd:backup      # 创建备份
task checkpoint:save # 保存检查点
```
