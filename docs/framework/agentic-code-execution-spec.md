# Agent 代码执行规范 (Agentic Code Execution Specification)

> **定义"怎么做"** - Agent 如何执行任务的规范

---

## 适用条件

本规范适用于以下场景：

1. **Agent 执行开发任务时**：包括编码、测试、Review 等活动
2. **Stage 推进过程**：从设计到完成的全流程
3. **需要通过门禁检查的任务**
4. **涉及多模型协作的场景**

### 强制适用

- 所有 Agent 执行的代码变更
- 所有 Stage 的推进过程
- 所有 Review 活动

### 可选适用

- 纯文档更新（可简化）
- 配置变更（可简化）

---

## 任务启动行为

### 启动前检查

Agent 在开始任务前必须执行以下检查：

```
启动检查清单
├── [ ] 检查 Roadmap 状态
│   └── 确认当前 Stage 与 Roadmap 一致
├── [ ] 加载上下文
│   ├── 读取历史 ADR
│   ├── 读取技术债台账
│   └── 读取当前 Stage 文档
├── [ ] 验证前置条件
│   ├── 前序 Stage 是否完成
│   └── 入场条件是否满足
└── [ ] 确认工作目录
    └── 确保在正确的分支/目录工作
```

### 状态加载

Agent 必须加载以下状态：

| 状态文件 | 路径 | 用途 |
|----------|------|------|
| 当前上下文 | `.rdd/cache/context.json` | 当前 Stage 状态 |
| 状态快照 | `.rdd/cache/state.json` | 历史状态快照 |
| Roadmap | `docs/stages/stage-roadmap.md` | 整体规划 |
| 当前 Stage | `docs/stages/stage-N.md` | 当前任务详情 |
| ADR 日志 | `docs/08-autonomous-decisions.md` | 历史决策 |
| 技术债台账 | `docs/12-technical-debt.md` | 已知问题 |

### 任务确认

启动任务时，Agent 应输出：

```
=== 任务启动确认 ===
Stage: [Stage 名称]
目标: [当前 Stage 目标]
前置条件: [已验证的前置条件]
阻塞项: [已知的阻塞项，如无则为空]
开始时间: [时间戳]
```

---

## 工具调用规范

### 文件操作

#### 读取文件

```
优先使用 Read 工具读取文件
- 明确指定绝对路径
- 对于大文件，使用 offset 和 limit 参数分段读取
- 读取后保存关键内容到上下文
```

#### 编辑文件

```
优先使用 Edit 工具编辑文件
- 编辑前必须先读取文件
- 确保 old_string 唯一匹配
- 一次只做一个逻辑变更
```

#### 创建文件

```
使用 Write 工具创建新文件
- 确认父目录存在
- 文件创建后验证内容
- 新文件应立即提交到版本控制
```

### Bash 命令

#### 命令执行原则

1. **明确目的**：每个命令应有清晰的描述
2. **避免 Shell 状态依赖**：使用绝对路径，不依赖 `cd` 后的状态
3. **合理超时**：长命令设置适当 timeout
4. **错误处理**：检查命令返回值

#### 命令分类

| 类型 | 示例 | 注意事项 |
|------|------|----------|
| 查询命令 | `ls`, `find`, `grep` | 可并行执行 |
| 文件操作 | `mkdir`, `cp`, `mv` | 确认目标存在 |
| 代码执行 | `go run`, `npm test` | 设置超时 |
| Git 操作 | `git status`, `git diff` | 检查状态 |

#### Git 提交规范

```
提交前检查：
1. 运行 git status 查看变更
2. 运行 git diff 确认变更内容
3. 确保不提交敏感文件
4. 编写清晰的提交信息

提交格式：
<type>(<scope>): <subject>

<body>

<footer>
```

### LSP 工具使用

```
用于代码智能：
- goToDefinition: 跳转到定义
- findReferences: 查找引用
- hover: 获取类型信息
- documentSymbol: 获取文档符号

使用时机：
- 理解代码结构时
- 查找依赖关系时
- 重命名变量时
```

---

## Stage 推进流程

### 流程概览

```
Stage 推进流程
│
├── [GATE 0] Stage 启动检查
│   ├── 检查前置条件是否满足
│   ├── 检查 Roadmap 是否有变更
│   └── 加载上下文（历史 ADR、技术债）
│
├── [GATE 1] 设计文档前置检查
│   ├── 禁止：无设计文档开始实现
│   ├── 禁止：scope 悄悄扩大
│   └── 生成 Stage 设计文档（基于模板）
│
├── [GATE 2] 方案 Review（写代码前）
│   ├── 触发多模型 Review
│   ├── 应用 Prompt 设计原则（同事模式）
│   ├── AI 初筛 findings（预期过滤 50%）
│   ├── 规则过滤（记忆偏差、逻辑谬误模式）
│   ├── 核查方法：权威来源 > 代码验证 > 追问模型
│   └── 低置信度 findings → 人工审核
│
├── [GATE 3] 实现与测试
│   ├── 实现
│   ├── 单元测试（覆盖率 >= 20%）
│   ├── E2E 测试（至少 2 条高信号路径）
│   ├── 真实环境验证（非 mock）
│   └── 干净环境二级验证（本地 + 干净环境）
│
├── [GATE 4] 代码 Review（E2E 通过后）
│   ├── 触发多模型 Review
│   ├── 三角校验：主开发模型 + 独立评审模型 + 规则检查
│   ├── AI 初筛 + 规则过滤
│   └── 核查每条 finding（不依赖"多模型共识"）
│
├── [GATE 5] 完成门禁检查
│   ├── ✅ 主要假设被验证或证伪
│   ├── ✅ 测试可通过 Task 入口复现
│   ├── ✅ 无未文档化的手工步骤
│   ├── ✅ 实现与设计一致（差异已记录）
│   ├── ✅ 新能力有 CLI 子命令
│   ├── ✅ 技术债台账已更新
│   ├── ✅ ADR 已记录
│   └── ✅ fresh-agent-check 通过
│
└── 文档更新义务（同步完成，禁止"文档待补"）
    ├── stage-N.md（实现差异）
    ├── stage-N-review-log.md（审阅记录）
    ├── autonomous-decisions.md（ADR）
    ├── technical-debt.md（技术债）
    ├── next-steps.md（进度）
    └── CHANGELOG.md（变更）
```

### Stage 状态流转

```
规划中 → 进行中 → Review中 → 验证中 → 完成
    ↑          ↓
    └── 失败 ←┘
```

| 状态 | 描述 | 允许的操作 |
|------|------|------------|
| 规划中 | Stage 正在设计 | 编辑设计文档 |
| 进行中 | Stage 正在实现 | 编码、测试 |
| Review中 | Stage 正在 Review | 修复 findings |
| 验证中 | Stage 正在验证 | 运行测试、fresh-check |
| 完成 | Stage 已完成 | 进入下一 Stage |
| 失败 | Stage 执行失败 | 诊断、恢复或人工介入 |

---

## 四重门禁

### Gate 0：Stage 启动检查

**触发时机**：Stage 开始时

**检查项**：
```yaml
Gate 0 检查:
  roadmap_status:
    - 当前 Stage 与 Roadmap 一致
    - Roadmap 无未审核的变更
  prerequisites:
    - 前序 Stage 已完成
    - 入场条件已满足
  context:
    - ADR 日志已加载
    - 技术债台账已加载
    - 当前 Stage 文档已加载
```

**失败处理**：
- Roadmap 不一致 → 暂停，请求人工审核
- 前置条件不满足 → 等待或调整 Roadmap
- 上下文加载失败 → 恢复或重建

### Gate 1：设计文档前置检查

**触发时机**：开始实现前

**检查项**：
```yaml
Gate 1 检查:
  design_document:
    - 设计文档存在
    - 目标清晰
    - 非目标显式声明
    - 验收标准可测试
    - 回滚方案存在
  scope:
    - 无未记录的 scope 变化
    - 核心假设数量合理（<= 3）
```

**失败处理**：
- 设计文档不存在 → 生成设计文档
- 验收标准不可测试 → 重新定义
- Scope 已变化 → 更新文档并审核

### Gate 2：方案 Review（写代码前）

**触发时机**：设计方案完成后、编码前

**检查项**：
```yaml
Gate 2 检查:
  review_process:
    - 多模型 Review 已触发
    - AI 初筛已完成
    - 规则过滤已完成
  findings:
    - 高置信度 findings 已修复
    - 低置信度 findings 已人工审核
```

**失败处理**：
- 高置信度 findings 未修复 → 修复后继续
- Review 未触发 → 触发 Review 流程

### Gate 3：实现与测试

**触发时机**：编码完成后

**检查项**：
```yaml
Gate 3 检查:
  tests:
    - 单元测试覆盖率 >= 20%
    - E2E 测试通过
    - 至少 2 条高信号 E2E 路径
  verification:
    - 真实环境验证通过（非 mock）
    - 干净环境验证通过
```

**失败处理**：
- 测试未通过 → 修复并重试
- 覆盖率不足 → 补充测试
- 验证失败 → 诊断原因并修复

### Gate 4：代码 Review（E2E 通过后）

**触发时机**：测试通过后

**检查项**：
```yaml
Gate 4 检查:
  review_process:
    - 多模型 Review 已触发
    - 三角校验已完成
    - AI 初筛已完成
    - 规则过滤已完成
  findings:
    - 所有阻塞性 findings 已修复
    - 所有验收标准已达成
```

**失败处理**：
- 阻塞性 findings → 修复后重新 Review
- 验收标准未达成 → 补充实现

### Gate 5：完成门禁检查

**触发时机**：准备标记 Stage 完成时

**检查项**：
```yaml
Gate 5 检查:
  verification:
    - 主要假设被验证或证伪
    - 测试可通过 Task 入口复现
    - 无未文档化的手工步骤
    - 实现与设计一致
    - 新能力有 CLI 子命令
  documentation:
    - 技术债台账已更新
    - ADR 已记录
    - fresh-agent-check 通过
```

**失败处理**：
- 文档未更新 → 更新文档
- fresh-check 失败 → 修复问题后重试

---

## Review 规范

### Review 类型

| 类型 | 时机 | 目的 |
|------|------|------|
| 设计 Review | Gate 2 | 审核设计方案 |
| 代码 Review | Gate 4 | 审核实现代码 |
| 快速 Review | 小变更 | 快速确认 |

### 多模型 Review 流程

```
多模型 Review 流程
│
├── 1. 触发 Review
│   └── 主开发模型发起 Review 请求
│
├── 2. 独立评审
│   ├── 独立评审模型进行 Review
│   └── 规则检查器进行静态检查
│
├── 3. AI 初筛
│   ├── 过滤记忆偏差类 findings
│   ├── 过滤逻辑谬误类 findings
│   └── 预期过滤约 50% findings
│
├── 4. 核查 findings
│   ├── 优先级：权威来源 > 代码验证 > 追问模型
│   ├── 每条 finding 独立核查
│   └── 不依赖"多模型共识"
│
├── 5. 分类处理
│   ├── 高置信度 → 自动修复
│   ├── 低置信度 → 人工审核
│   └── 误报 → 标记并记录
│
└── 6. 生成报告
    ├── 记录所有 findings
    ├── 记录采纳/不采纳理由
    └── 更新 review-log.md
```

### Review 输出格式

```markdown
# Stage N Review Log

## Review 概要
- 日期: YYYY-MM-DD
- Review 类型: [设计/代码]
- 参与模型: [模型列表]

## Findings

### Finding 1: [标题]
- **严重程度**: [阻塞/警告/建议]
- **置信度**: [高/中/低]
- **描述**: [具体描述]
- **建议修复**: [修复建议]
- **处理结果**: [采纳/不采纳/误报]
- **处理理由**: [理由说明]

### Finding 2: ...

## 统计
- 总 findings: N
- 阻塞性: N
- 警告: N
- 建议: N
- 采纳率: N%
```

---

## 自动化与可恢复性

### 自动化检查点

| 检查点 | 触发条件 | 自动化程度 |
|--------|----------|------------|
| Gate 0 | Stage 启动 | 完全自动 |
| Gate 1 | 设计完成 | 完全自动 |
| Gate 2 | 方案完成 | 半自动（需人工审核低置信度） |
| Gate 3 | 实现完成 | 完全自动 |
| Gate 4 | 测试通过 | 半自动（需人工审核低置信度） |
| Gate 5 | 准备完成 | 完全自动 |

### 状态持久化

```
Agent 必须持久化以下状态：
├── .rdd/cache/context.json
│   ├── 当前 Stage ID
│   ├── 当前 Gate
│   ├── 上次检查点时间
│   └── 已完成步骤列表
└── .rdd/cache/state.json
    ├── 历史 Stage 状态
    ├── 技术债快照
    └── ADR 快照
```

### 中断恢复

```
恢复流程：
1. 读取 context.json 获取当前状态
2. 确认当前 Gate
3. 验证已完成的步骤
4. 从最后一个检查点继续
5. 如验证失败，回退到上一个稳定检查点
```

### Handoff 协议

当需要切换 Agent 时：

```markdown
## Handoff 文档格式

### 当前进度
- Stage: [Stage 名称]
- Gate: [当前 Gate]
- 进度: [百分比]

### 已完成证据
- [证据链接1]
- [证据链接2]

### 阻塞与风险
- [阻塞描述]

### 下一步唯一动作
- [具体动作]

### 降级策略
若 30 分钟无进展，触发 [降级策略]
```

---

## 失败处理流程

### 失败分类

| 级别 | 描述 | 处理方式 |
|------|------|----------|
| 可恢复 | 已知错误，有解决方案 | 自动修复 |
| 需诊断 | 未知错误，需诊断 | 触发诊断流程 |
| 需人工 | 超出 Agent 能力范围 | 暂停并通知 |
| 致命 | 系统级问题 | 紧急通知 |

### 失败处理流程

```
失败处理流程
│
├── 1. 检测失败
│   └── 记录错误信息
│
├── 2. 分类失败
│   ├── 可恢复 → 尝试自动修复
│   ├── 需诊断 → 触发诊断
│   ├── 需人工 → 暂停并通知
│   └── 致命 → 紧急通知
│
├── 3. 可恢复错误处理
│   ├── 查找解决方案
│   ├── 应用修复
│   └── 重试验证
│
├── 4. 需诊断错误处理
│   ├── 收集诊断信息
│   ├── 分析根本原因
│   ├── 生成诊断报告
│   └── 提出解决方案
│
├── 5. 连续失败处理
│   ├── 记录失败次数
│   ├── 3 次失败 → 触发 P0 通知
│   └── 等待人工介入
│
└── 6. 记录处理结果
    ├── 更新 context.json
    ├── 记录到 Stage 日志
    └── 更新技术债台账（如产生新债务）
```

### 重试策略

```yaml
retry_policy:
  max_retries: 3
  backoff:
    initial_delay: 10s
    max_delay: 300s
    multiplier: 2

  retryable_errors:
    - network_timeout
    - resource_temporarily_unavailable
    - rate_limit_exceeded

  non_retryable_errors:
    - permission_denied
    - resource_not_found
    - configuration_error
```

### 人工介入触发条件

```yaml
human_intervention_triggers:
  P0_immediate:
    - roadmap_change
    - consecutive_failure_3
    - hypothesis_invalidated
    - security_issue

  P1_urgent:
    - model_disagreement
    - tech_debt_threshold

  P2_normal:
    - review_conflict
    - scope_change_request
```

---

## Good/Bad Case 示例

### Good Case：正确的 Stage 启动流程

```
=== Stage 3 启动 ===

1. 检查 Roadmap 状态
   [OK] Roadmap 最新更新: 2026-03-05
   [OK] 当前 Stage 与 Roadmap 一致

2. 加载上下文
   [OK] 已加载 ADR 日志 (3 条记录)
   [OK] 已加载技术债台账 (2 条待处理)
   [OK] 已加载 Stage 3 设计文档

3. 验证前置条件
   [OK] Stage 2 已完成
   [OK] 入场条件满足: 数据库连接已配置

4. 开始执行
   当前 Gate: Gate 1 (设计文档前置检查)
```

### Bad Case：跳过前置检查

```
=== 错误示例 ===

Agent 直接开始编码，未执行前置检查：
- 未检查 Roadmap 是否有变更
- 未加载技术债台账
- 未验证前置条件

结果：
- 使用了已废弃的 API（Roadmap 已变更）
- 重复处理 Stage 2 已解决的技术债
- 缺少数据库连接配置导致测试失败
```

### Good Case：正确的 Gate 1 处理

```
=== Gate 1 检查 ===

检查设计文档:
[OK] docs/stages/stage-3.md 存在
[OK] 目标清晰: "实现用户认证功能"
[OK] 非目标显式声明: "不包含第三方登录"
[OK] 验收标准可测试:
    - 用户可以使用邮箱密码登录
    - 登录失败显示正确错误信息
[OK] 回滚方案: 回退到 stage-2-end 分支

检查 Scope:
[OK] 无未记录的 scope 变化
[OK] 核心假设数量: 2 (合理)

Gate 1 通过，进入 Gate 2
```

### Bad Case：设计文档不完整

```
=== Gate 1 检查 ===

检查设计文档:
[OK] docs/stages/stage-3.md 存在
[FAIL] 目标不清晰: "改进认证"
[FAIL] 非目标未声明
[FAIL] 验收标准不可测试: "用户感觉更好"
[FAIL] 回滚方案缺失

检查 Scope:
[FAIL] 发现 scope 变化: 新增了密码重置功能
[FAIL] 核心假设数量: 5 (过多)

Gate 1 失败，需要更新设计文档
```

### Good Case：正确的 Review 流程

```
=== Gate 2 Review ===

1. 触发多模型 Review
   [OK] 主开发模型: Claude
   [OK] 独立评审模型: GPT-4
   [OK] 规则检查器: linter

2. 收集 Findings
   - Finding 1: 缺少输入验证 (高置信度)
   - Finding 2: 可能的 SQL 注入 (高置信度)
   - Finding 3: 变量命名不规范 (低置信度)

3. AI 初筛
   [OK] 过滤记忆偏差: 0 条
   [OK] 过滤逻辑谬误: 0 条

4. 核查 Findings
   - Finding 1: [采纳] 代码验证确认
   - Finding 2: [采纳] 权威来源确认
   - Finding 3: [不采纳] 主观偏好

5. 修复高置信度 Findings
   [OK] 修复 Finding 1
   [OK] 修复 Finding 2

6. 更新 review-log.md
   [OK] 记录所有 findings
   [OK] 记录采纳/不采纳理由

Gate 2 通过，进入 Gate 3
```

### Bad Case：跳过 Review 流程

```
=== 错误示例 ===

Agent 跳过 Gate 2 直接开始编码：
- 未触发多模型 Review
- 未进行 AI 初筛
- 未核查 findings

结果：
- 代码中存在 SQL 注入漏洞
- 缺少输入验证导致生产环境崩溃
- Gate 4 发现问题，需要大量返工
```

### Good Case：正确的失败恢复

```
=== 失败恢复 ===

检测到失败:
- 错误: 测试环境连接超时
- 分类: 可恢复

处理步骤:
1. 记录错误信息
   [OK] 错误类型: network_timeout
   [OK] 错误时间: 2026-03-06 14:30:00

2. 查找解决方案
   [OK] 找到解决方案: 重试并检查网络配置

3. 应用修复
   [OK] 检查网络配置正常
   [OK] 重试测试 (第 1 次)
   [FAIL] 仍然超时

4. 指数退避重试
   [OK] 等待 20 秒
   [OK] 重试测试 (第 2 次)
   [OK] 测试通过

5. 记录处理结果
   [OK] 更新 context.json
   [OK] 记录到 Stage 日志

恢复成功，继续执行
```

### Bad Case：未记录失败处理

```
=== 错误示例 ===

Agent 遇到失败后直接重试：
- 未记录错误信息
- 未分析根本原因
- 未更新状态

结果：
- 同样的错误反复出现
- 无法追溯问题原因
- 其他 Agent 接手时无法恢复
```

---

## 边界声明

### 本规范覆盖范围

- Agent 执行任务的行为规范
- Stage 推进的具体流程
- 门禁检查的执行标准
- Review 活动的流程规范
- 失败处理和恢复流程

### 本规范不覆盖范围

- 项目治理规则（参考 project-governance-spec.md）
- 规范编写规范（参考 standards-authoring-spec.md）
- Hook 通知的配置（参考相关配置文档）
- 具体的编码规范（参考项目代码规范）

### 与其他规范的关系

- 本规范定义"怎么做"
- `project-governance-spec.md` 定义"要做到什么"
- `standards-authoring-spec.md` 定义"如何写规范"

---

*本规范是 RDD (Roadmap Driven Development) 框架的一部分*

*版本: 1.0.0*
*最后更新: 2026-03-06*
