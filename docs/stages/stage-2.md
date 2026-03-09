# Stage 2: 测试体系建设

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

## Goals
建立完整的测试体系，确保框架可靠性。包括单元测试、BDD 测试、E2E 测试三层测试架构。

## Non-Goals
- 不涉及上下文恢复功能（Stage 3）
- 不涉及 CI/CD 生产环境集成（Stage 4）
- 不涉及 Mock Claude API 完整实现（仅基础 mock）

## Core Hypotheses
- H1: bats-core 可以满足 Shell 脚本单元测试需求
- H2: BDD 场景可以验证用户行为预期
- H3: E2E 测试可以模拟真实 Agent 工作流
- H4: 测试覆盖率可达 80%

## Acceptance Criteria
- [x] 单元测试框架集成 (bats-core)
- [x] notify.sh 单元测试覆盖率 >= 80% (34 tests)
- [ ] Hook 脚本单元测试覆盖率 >= 80%
- [x] BDD 场景定义完成 (Given/When/Then) - 10 tests
- [ ] Gate 检查自动化测试完成
- [x] E2E 测试项目模板创建 - 12 tests
- [ ] Mock Claude API 基础实现
- [x] `task test` 执行所有测试 - 81 tests passing
- [x] 测试覆盖率报告生成
- [ ] CI 流水线配置完成

## Rollback Plan
测试框架独立于核心功能，可单独删除 tests/ 目录回滚。

## Known Limitations
- Mock Claude API 仅基础实现，不模拟完整 Agent 行为
- 覆盖率工具 kcov 可能不在所有环境可用
- E2E 测试使用 DRY_RUN 模式避免实际网络调用

## Impact on Subsequent Stages
- Stage 3 可依赖测试保障实现上下文恢复
- Stage 4 可依赖 CI 流水线实现自动化部署

---

## Implementation Notes

### Technical Decisions Made
- 决策 5: 选择 bats-core 作为 Shell 测试框架 (ADR-005)
- 决策 6: 测试分层策略：单元/BDD/E2E 三层测试 (ADR-006)

### Architecture
```
tests/
├── unit/                    # Unit tests (bats-core)
│   ├── notify.bats          # notify.sh function tests
│   ├── hooks/               # Hook script tests
│   └── helpers/             # Test helpers
├── bdd/                     # BDD tests
│   ├── hook-notification.bats
│   ├── error-handling.bats
│   └── config-loading.bats
├── e2e/                     # E2E tests
│   ├── full-notification-flow.bats
│   └── mock-claude/
├── fixtures/                # Test fixtures
└── lib/                     # Test libraries
    ├── bats-core/
    ├── bats-support/
    └── bats-assert/
```

### Testing Strategy
| Component | Test Type | Priority |
|-----------|-----------|----------|
| log_* functions | Unit | High |
| expand_env_vars | Unit | High |
| send_* functions | Unit | High |
| is_quiet_hours | Unit | Medium |
| send_notification | Unit | High |
| Hook scripts | Unit | High |
| Hook trigger flow | BDD | High |
| Error handling | BDD | Medium |
| Full notification | E2E | Medium |

---

## Verification

### Gate 1: Design Document Check
- [x] Design document complete
- [x] Goals clearly defined
- [x] Non-goals explicitly stated
- [x] Acceptance criteria testable
- [x] Rollback plan exists

### Gate 2: Design Review Check
- [ ] Multi-model review triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [ ] Implementation complete
- [ ] Unit test coverage >= 80%
- [ ] E2E tests (2+ high-signal paths)
- [ ] Real environment verification
- [ ] Clean environment verification

### Gate 4: Code Review Check
- [ ] Triangulation complete
- [ ] All blocking findings resolved
- [ ] All acceptance criteria met

### Gate 5: Completion Gate Check
- [ ] Main hypotheses verified
- [ ] Tests reproducible via Task
- [ ] No undocumented manual steps
- [ ] Implementation matches design
- [ ] Tech debt ledger updated
- [ ] ADR recorded
- [ ] fresh-agent-check passed
