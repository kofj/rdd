# Stage 3: Context Recovery Enhancement

## Status
- [x] Planning
- [x] In Progress
- [ ] Complete

## Goals

实现 Compact 后的自动上下文恢复能力，确保 Agent 在长时间运行或会话重置后能够无缝恢复工作状态。

**一句话描述**: 设计并实现完整的上下文恢复系统，包括 Handoff 文档、Checkpoint 机制和 Compact 恢复协议。

**详细说明**:

本 Stage 的核心目标是解决 Claude Compact 操作导致的上下文丢失问题。当一个长时间运行的任务需要 Compact 时，Agent 需要能够：

1. **检测恢复需求**: 自动识别这是一个恢复场景而非新会话
2. **加载上下文**: 从 Handoff 文档和 Checkpoint 文件中恢复状态
3. **继续工作**: 从上次中断点继续执行，而非从头开始

这将使 RDD 框架真正具备 7x24 自动运行能力。

---

## Non-Goals

- 不涉及多项目并行支持（Stage 4）
- 不涉及 CI/CD 集成（Stage 4）
- 不涉及分布式状态存储（接受为长期限制）
- 不涉及跨 Agent 状态同步（接受为长期限制）

---

## Core Hypotheses

### H1: Agent 可以通过 CLAUDE.md 协议检测恢复场景

- **假设内容**: 在 CLAUDE.md 中定义会话启动协议，Agent 可以检测是否存在待恢复的 Handoff 文档或 Checkpoint
- **验证方式**: 通过 E2E 测试验证 Agent 在新会话中能正确识别恢复场景
- **风险**: 如果检测机制不可靠，需要引入显式标记文件

### H2: Handoff 文档包含足够的状态信息

- **假设内容**: 设计的 Handoff 文档格式能够捕获所有必要的工作状态，使 Agent 能够准确恢复
- **验证方式**: fresh-agent-check 测试验证新 Agent 可以无缝接手
- **风险**: 如果 Handoff 信息不足，可能需要增加更多字段

### H3: Checkpoint 可以准确保存执行进度

- **假设内容**: Checkpoint 文件可以准确记录 Gate 进度、阻塞项、决策历史等关键状态
- **验证方式**: 通过单元测试验证状态序列化和反序列化的准确性
- **风险**: 如果状态表示不完整，恢复后可能丢失关键信息

### H4: 自动触发机制可以及时保存状态

- **假设内容**: 在关键节点（Gate 完成、决策做出、定时触发）自动保存状态，不会丢失重要进展
- **验证方式**: 通过 E2E 测试验证各种触发场景
- **风险**: 如果触发时机不当，可能保存过多冗余数据或遗漏关键状态

---

## Acceptance Criteria

### Handoff System

- [x] Handoff 文档格式定义完成
- [x] 自动 Handoff 生成机制实现
  - [x] Gate 完成后自动生成
  - [x] 重要决策后自动更新
  - [x] 30分钟无进展触发更新
- [x] Handoff 文档验证脚本实现
- [x] fresh-agent-check 使用 Handoff 文档通过

### Checkpoint System

- [x] `.rdd/cache/checkpoints.json` 格式定义完成
- [x] Checkpoint 保存功能实现
  - [x] Gate 进度保存
  - [x] 阻塞项保存
  - [x] 决策历史保存
  - [x] 技术债状态保存
- [x] Checkpoint 恢复功能实现
- [x] Checkpoint 单元测试覆盖率 >= 80%

### Compact Recovery Protocol

- [x] CLAUDE.md 会话启动协议定义完成
- [x] 恢复场景检测机制实现
- [x] 自动加载 Handoff 和 Checkpoint 实现
- [x] 恢复确认流程实现

### Testing & Verification

- [x] 恢复流程 E2E 测试通过
- [x] fresh-agent-check 自动化测试通过
- [x] 单元测试覆盖率 >= 80%
- [x] 文档验证测试通过

---

## Rollback Plan

**回滚策略**: 功能通过配置开关控制，可禁用自动恢复功能

**回滚步骤**:

1. 在 `config.yml` 中设置 `recovery.enabled: false`
2. 删除 `.rdd/cache/checkpoints.json` 文件
3. Handoff 文档保留作为手动参考
4. 框架退回到无自动恢复状态

**回滚条件**:

- 恢复机制导致状态混乱
- 性能问题影响正常工作
- Agent 无法正确处理恢复场景

---

## Known Limitations

- **本地存储**: Checkpoint 存储在本地文件系统，不支持分布式场景 - 计划在后续版本解决
- **单 Agent**: 不支持多 Agent 协作的上下文同步 - 接受为长期限制
- **手动触发**: 部分恢复场景需要手动确认 - 计划在 Stage 4 优化
- **历史版本**: 不支持 Checkpoint 历史版本管理 - 接受为当前限制

---

## Impact on Subsequent Stages

- **Stage 4**: CI/CD 集成可以利用 Checkpoint 机制保存构建状态，多项目支持可以复用 Handoff 格式
- **未来版本**: 分布式状态存储可以替换本地 Checkpoint，但接口保持不变

---

## Implementation Notes

### Architecture Overview

```
Context Recovery System Architecture
=====================================

┌─────────────────────────────────────────────────────────────────┐
│                        CLAUDE.md Entry Point                     │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   Session Startup Protocol                   ││
│  │  1. Read docs/11-next-steps.md                               ││
│  │  2. Check .rdd/cache/handoff.md existence                    ││
│  │  3. If handoff.md exists → Recovery Mode                     ││
│  │  4. Else → Normal Mode                                       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Recovery Mode                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  1. Load Handoff Document (.rdd/cache/handoff.md)           ││
│  │  2. Load Checkpoint (.rdd/cache/checkpoints.json)           ││
│  │  3. Verify State Consistency                                 ││
│  │  4. Resume from Last Known State                             ││
│  │  5. Confirm Recovery to User                                 ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Checkpoint System                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    checkpoints.json                           ││
│  │  {                                                            ││
│  │    "version": "1.0",                                          ││
│  │    "project": {...},                                          ││
│  │    "stage": {...},                                            ││
│  │    "gates": {...},                                            ││
│  │    "decisions": [...],                                        ││
│  │    "blockers": [...],                                         ││
│  │    "timestamp": "..."                                         ││
│  │  }                                                            ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  Trigger Points:                                                 │
│  - Gate completion                                               │
│  - Decision made (ADR)                                           │
│  - Blocker encountered                                           │
│  - Timer-based (every 30 minutes)                                │
│  - Manual trigger                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Handoff System                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      handoff.md                               ││
│  │  ## Current Progress                                          ││
│  │  ## Completed Evidence                                        ││
│  │  ## Blockers and Risks                                        ││
│  │  ## Next Single Action                                        ││
│  │  ## Degradation Strategy                                      ││
│  │  ## Recovery Instructions                                     ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Verification

### Gate 1: Design Document Check
- [x] Design document complete
- [x] Goals clearly defined
- [x] Non-goals explicitly stated
- [x] Acceptance criteria testable
- [x] Rollback plan exists

### Gate 2: Design Review Check
- [x] Multi-model review triggered
- [x] AI pre-filtering completed
- [x] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [x] Implementation complete
- [x] Unit test coverage >= 80% (34 unit tests + 35 handoff tests)
- [x] E2E tests (9 E2E tests)
- [x] Real environment verification (all tests pass)
- [x] Clean environment verification (tests use isolated temp directories)

### Gate 4: Code Review Check
- [x] Triangulation complete
- [x] All blocking findings resolved
- [x] All acceptance criteria met

### Gate 5: Completion Gate Check
- [x] Main hypotheses verified
- [x] Tests reproducible via Task
- [x] No undocumented manual steps
- [x] Implementation matches design
- [x] Tech debt ledger updated
- [x] ADR recorded
- [x] fresh-agent-check passed
