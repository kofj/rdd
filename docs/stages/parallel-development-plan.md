# 并行开发策略规划

## Stage 依赖关系分析

```
Stage 0 ✅ ─┐
            ├─→ Stage 2 ─┬─→ Stage 3 ─┐
Stage 1 ✅ ─┘            │            │
                         ├─→ Stage 4 ─┼─→ Stage 5 ─┐
                         │            │            │
                         │            └─→ Stage 6 ─┼─→ Stage 7
                         │                         │
                         └─────────────────────────┘
```

## 并行开发波次

### Wave 1: Stage 2 (测试基础) - 必须**完成**
**时间**: Day 1-3
**阻塞**: Stage 3-7 都依赖测试框架
**交付**:
- bats-core 框架集成
- notify.sh 100% 测试覆盖
- Hook 脚本 100% 测试覆盖
- BDD/E2E 测试框架
- Docker + Kind 测试环境

### Wave 2: Stage 3 + Stage 4 (并行开发)
**时间**: Day 4-6 (与 Wave 1 部分重叠)
**并行任务**:
- **Stage 3 (Worktree A)**: 上下文恢复
  - 自动 Handoff 生成
  - 状态持久化
  - Compact 恢复协议

- **Stage 4 (Worktree B)**: 错误处理与可观测性
  - 错误分类体系
  - 重试机制
  - 降级策略
  - 监控指标

### Wave 3: Stage 5 + Stage 6 (并行开发)
**时间**: Day 7-9
**并行任务**:
- **Stage 5 (Worktree A)**: 性能与兼容性
  - 性能基准测试
  - 版本管理
  - 升级迁移

- **Stage 6 (Worktree B)**: 安全与权限
  - 权限模型
  - 审计日志
  - 凭证加密

### Wave 4: Stage 7 (最终整合)
**时间**: Day 10-12
**任务**: 文档与运维完善
- 用户文档
- 运维手册
- CI/CD 集成模板
- 示例项目

## Git Worktree 规划

```
main (baseline)
├── worktree-stage-2  → Stage 2 开发，完成后合并
├── worktree-stage-3  → Stage 3 并行开发
├── worktree-stage-4  → Stage 4 并行开发
├── worktree-stage-5  → Stage 5 并行开发
├── worktree-stage-6  → Stage 6 并行开发
└── worktree-stage-7  → Stage 7 最终整合
```

## 验收标准

### 每个 Stage 完成验收
1. **Gate 检查通过**: 5 个 Gate 全部通过
2. **测试覆盖达标**: >= 95%（预期 100%）
3. **Docker 环境测试**: 干净 Docker 容器内通过
4. **Kind 环境测试**: 干净 Kind 集群内通过
5. **文档更新**: ADR、技术债、Roadmap 同步更新

### 最终生产可用验收
1. 所有 Stage Gate 通过
2. E2E 测试在 Docker + Kind 双环境通过
3. 性能基准达标（Hook < 100ms，通知 < 500ms）
4. 错误恢复测试通过（模拟故障恢复）
5. 文档完整（用户文档 + 运维手册）

## ADR 记录要求

每个 Stage 必须记录以下决策：
1. 技术选型决策
2. 架构设计决策
3. 性能权衡决策
4. 安全权衡决策
5. 对后续 Stage 的影响

## 合并策略

### Stage 2 合并
- PR 创建后自测通过
- 无冲突直接合并到 main

### Stage 3-6 并行合并
- Wave 2 完成后同时创建 PR
- 合并顺序: Stage 3 → Stage 4 → main
- Wave 3 完成后同时创建 PR
- 合并顺序: Stage 5 → Stage 6 → main

### Stage 7 最终合并
- 所有前置 Stage 合并后
- Stage 7 合并到 main
- 创建 v1.0 release tag
