# RDD (Roadmap Driven Development) 需求文档

> **核心理念**：人类铺设轨道（Roadmap），Agent 沿轨道自动前进

---

## 一、背景与目标

### 1.1 背景

受 Gary 的 Stage Based Development 范式启发，结合实践经验，提炼出一套完整的开发范式，目标是将人工干预降到最低，实现接近全自动的 Agent 驱动开发。

### 1.2 目标

构建 RDD (Roadmap Driven Development) 开发范式，包括：
1. 关键理念文档
2. 最佳实践指导手册
3. 可在 Claude Code 直接使用的 SKILLs 和 Commands
4. Hook 通知机制（企业微信、邮件、Bark、Telegram、Webhook）
5. 智能诊断与自动修复能力

### 1.3 功能要求

| 编号 | 功能 | 优先级 |
|------|------|--------|
| F1 | 帮助存量项目快速切换到 RDD 开发范式 | P0 |
| F2 | 快速初始化新项目，按照 RDD 开发范式进行开发 | P0 |
| F3 | 智能诊断项目中的 RDD 问题，并给出解决方案 | P1 |
| F4 | 推动项目批量进行 Stage 开发，无限降低人工干预 | P0 |
| F5 | 主动探索可能对生产更加有用的建议 | P2 |
| F6 | 实际测试 RDD 开发范式中的 SKILLs 和 Commands | P1 |

---

## 二、核心理念

### 2.1 RDD 核心原则

```
┌─────────────────────────────────────────────────────────────────┐
│                    RDD 核心原则                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Roadmap 驱动                                                │
│     - 人类铺设轨道，定义 Stage 路线                              │
│     - Agent 沿轨道自动前进                                      │
│     - Roadmap 变更必须人工审核                                  │
│                                                                 │
│  2. Stage 最小交付单元                                          │
│     - 每个 Stage 都可验收、可回滚、可 handoff                   │
│     - 控制 scope，接受阶段性妥协                                │
│     - 天然支持中断恢复与多 Agent 协作                           │
│                                                                 │
│  3. 防腐机制优先                                                │
│     - 禁止行为清单明确                                          │
│     - 四重门禁强制执行                                          │
│     - 文档更新义务同步完成                                      │
│                                                                 │
│  4. 显式知识管理                                                │
│     - 技术债必须可见，不以隐性知识管理                          │
│     - ADR 必须记录"对后续影响"                                  │
│     - 新 Agent 可凭文档自举                                     │
│                                                                 │
│  5. 多模型交叉验证                                              │
│     - 主开发模型 + 独立评审模型 + 规则检查                      │
│     - 约 50% findings 是误报，每条独立核查                      │
│     - 核查优先级：权威来源 > 代码验证 > 追问模型                │
│                                                                 │
│  6. Hook 通知机制                                               │
│     - 需要人工介入时自动通知                                    │
│     - 支持多渠道：企微、邮件、Bark、Telegram、Webhook           │
│     - 分级通知：P0 紧急 / P1 重要 / P2 通知 / P3 报告           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 核心公式

```
RDD = Roadmap（人类主导）
    + Stage（最小交付单元）
    + Gate（四重门禁）
    + Knowledge（显式知识管理）
    + Hook（人工介入通知）
```

### 2.3 人机分工

| 领域 | 人类职责 | Agent 职责 |
|------|---------|-----------|
| Roadmap | 定义愿景、规划路线、调整优先级 | 提取目标、执行 Stage |
| Stage 边界 | 审核关键 Stage、处理异常 | 生成设计文档、实现验证 |
| Review | 核查低置信度 findings | AI 初筛、规则过滤 |
| 技术债 | 判断优先级 | 自动发现、台账管理 |
| 文档 | 审核关键决策 | 自动生成、同步更新 |

---

## 三、整体架构

### 3.1 架构图

```
RDD Framework
│
├── 🎯 Roadmap 层（人类主导）
│   ├── 项目愿景与边界定义
│   ├── Stage 路线规划（增/删/重排）
│   ├── 优先级调整
│   └── 关键决策审核
│
├── 📜 规范层
│   ├── 项目规范层（定义"要做到什么"）
│   ├── 执行规范层（定义"怎么做"）
│   └── Agent 入口层（轻量引用，不重复正文）
│
├── 🔄 自动循环层
│   ├── 状态监控器
│   ├── Stage 推进器
│   ├── 异常处理器
│   └── 知识管理器
│
├── 🛡️ 防腐机制层
│   ├── 禁止行为清单（9 条）
│   ├── 四重门禁
│   ├── 文档更新义务（6 份）
│   └── 验证机制
│
├── 📋 技能层
│   ├── rdd-init
│   ├── rdd-migrate
│   ├── rdd-roadmap
│   ├── rdd-stage-auto
│   ├── rdd-review-auto
│   ├── rdd-recovery
│   ├── rdd-knowledge
│   ├── rdd-diagnosis
│   └── rdd-fresh-check
│
├── 🔔 Hook 通知层
│   ├── 触发层（何时通知）
│   ├── 分级层（P0-P3）
│   ├── 渠道层（企微/邮件/Bark/Telegram/Webhook）
│   └── 模板层（通知内容）
│
└── 🛑 人工检查点
    ├── Roadmap 变更（强制暂停）
    ├── 连续失败 3 次
    ├── 核心假设证伪
    ├── 多模型分歧严重
    └── 技术债超阈值
```

### 3.2 Stage 推进流程

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
│   ├── 单元测试（覆盖率 ≥ 20%）
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
│   ├── ✅ ADR 已记录（"对后续 Stage 影响"不可留空）
│   └── ✅ fresh-agent-check 通过
│
└── 文档更新义务（同步完成，禁止"文档待补"）
    ├── stage-N.md（实现差异）
    ├── stage-N-review-log.md（审阅记录，含采纳/不采纳理由）
    ├── autonomous-decisions.md（ADR）
    ├── technical-debt.md（技术债）
    ├── next-steps.md（进度）
    └── CHANGELOG.md（变更）
```

---

## 四、防腐机制

### 4.1 禁止行为清单（9 条）

```
禁止行为清单
│
├── ❌ 无设计文档开始实现
│   └── 必须先完成设计文档，再开始编码
│
├── ❌ Scope 悄悄扩大
│   └── 发现不对立即停下，先更新文档
│
├── ❌ "文档待补"状态声称完成
│   └── 文档必须同步完成，不允许后续补
│
├── ❌ 多个 Stage 核心未知数放同一 Stage
│   └── 每个 Stage 只验证一小组清晰假设
│
├── ❌ 依赖"口口相传"来运行测试
│   └── 测试必须可通过 Task 入口复现
│
├── ❌ 编写隐藏平台假设的脚本
│   └── 环境假设必须显式文档化
│
├── ❌ 在理解运行时约束之前引入宽泛接口
│   └── 先验证约束，再设计接口
│
├── ❌ 过早把昂贵检查塞进默认编辑循环
│   └── 昂贵检查应该显式触发，不是默认行为
│
└── ❌ 将技术债当作隐性知识管理
    └── 所有已知缺口必须在台账中显式记录
```

### 4.2 四重门禁

| 门禁 | 检查项 | 阻塞行为 |
|------|--------|---------|
| Gate 1 | 设计文档是否完成、目标是否清晰、非目标是否显式声明、验收标准是否可测试、回滚方案是否存在 | 禁止实现 |
| Gate 2 | 多模型 Review 是否触发、AI 初筛是否完成、高置信度 findings 是否修复 | 禁止编码 |
| Gate 3 | E2E 是否通过、覆盖率是否达标、干净环境验证是否通过 | 禁止提交 |
| Gate 4 | 所有阻塞性 findings 是否修复、所有验收标准是否达成 | 禁止完成 |
| Gate 5 | 6 份文档是否更新、fresh-agent-check 是否通过 | 禁止进入下一 Stage |

### 4.3 文档更新义务

Stage 完成时必须同步更新的文档：

| 文档 | 更新内容 | 时机 |
|------|----------|------|
| `docs/stages/stage-N.md` | 实现差异、验收标准变化 | Stage 完成时 |
| `docs/stages/stage-N-review-log.md` | findings、采纳/不采纳理由 | Review 完成时 |
| `docs/08-autonomous-decisions.md` | ADR、假设偏差 | 决策发生时 |
| `docs/12-technical-debt.md` | 新增/偿还技术债 | Stage 完成时 |
| `docs/11-next-steps.md` | 进度、下一步入场条件 | Stage 完成时 |
| `CHANGELOG.md` | 本 Stage 变更摘要 | Stage 完成时 |

**防止文档腐化的三规则**：
1. **即时更新**：发现设计偏差立即更新，不等 Stage 结束
2. **实质内容**：必须有具体内容，不能只写"待定"
3. **版本刷新**：所有"当前状态"字段同步刷新

### 4.4 技术债管理

**发现渠道（四渠道）**：
```
A. Stage 文档"非目标"和"已知限制"章节 → 主动记录
B. 审阅日志"推后/不接受"区 → 从 review-log 提取
C. ADR"对后续 Stage 的影响"字段 → 有行动含义的条目
D. 代码扫描（TODO/FIXME/HACK/XXX）→ 自动扫描
```

**优先级两轴**：
- 影响域：架构级 / 模块级 / 局部
- 阻塞性：阻塞 Stage / 降级功能 / 技术优化

**排序规则**：
1. 阻塞后续 Stage → 下个 Stage 前必须解决
2. 降级功能 + 架构级 → 专项迭代处理
3. 降级功能 + 模块级/局部 → 对应 Stage 顺带解决
4. 纯技术优化 → 待基准测试驱动

**阈值触发**：
- "降级功能 + 架构级"积压超过 3 条 → 安排专项迭代

---

## 五、Hook 通知系统

### 5.1 通知分级

| 级别 | 阻塞行为 | 默认渠道 | 示例 |
|------|---------|---------|------|
| 🔴 P0 | Agent 暂停，等待人工介入 | 全渠道 | 连续失败、假设证伪、Roadmap 变更 |
| 🟠 P1 | Agent 继续，建议尽快处理 | 主要渠道 | 模型分歧、技术债超阈值 |
| 🟢 P2 | 不阻塞，信息同步 | 即时渠道 | Stage 完成、新 ADR |
| 📊 P3 | 不阻塞，定期汇总 | 批量渠道 | 日报、周报 |

### 5.2 支持的通知渠道

| 渠道 | 配置方式 | 适用级别 |
|------|---------|---------|
| 企业微信机器人 | webhook_url | P0-P2 |
| 邮件 | SMTP 配置 | P0-P3 |
| iOS Bark | server + key | P0-P1 |
| Telegram Bot | bot_token + chat_id | P0-P2 |
| Webhook（通用） | url + method + headers | 全部 |

### 5.3 触发规则

```yaml
triggers:
  roadmap_change:        # Roadmap 变更
    level: P0
    channels: [wecom, email]
    block: true

  consecutive_failure:   # 连续失败 3 次
    level: P0
    channels: [wecom, bark, telegram]
    block: true
    condition:
      failure_count: 3

  hypothesis_invalid:    # 核心假设证伪
    level: P0
    channels: [wecom, email, bark]
    block: true

  model_disagreement:    # 多模型分歧
    level: P1
    channels: [wecom, email]
    block: false

  tech_debt_threshold:   # 技术债超阈值
    level: P1
    channels: [wecom, email]
    block: true
    condition:
      debt_count: 3

  stage_complete:        # Stage 完成
    level: P2
    channels: [wecom]
    block: false

  daily_report:          # 日报
    level: P3
    channels: [email]
    schedule: "0 18 * * *"

  weekly_report:         # 周报
    level: P3
    channels: [email]
    schedule: "0 18 * * 5"
```

---

## 六、技能与命令

### 6.1 技能清单

| 技能 | 功能 | 优先级 |
|------|------|--------|
| `rdd-init` | 项目初始化，创建目录结构和规范文档 | P0 |
| `rdd-migrate` | 存量项目迁移，诊断并转换结构 | P0 |
| `rdd-roadmap` | Roadmap 管理，创建/调整 Stage 路线 | P0 |
| `rdd-stage-auto` | Stage 自动执行，含四重门禁 | P0 |
| `rdd-review-auto` | Review 自动化，含 AI 初筛 | P1 |
| `rdd-recovery` | 失败自动恢复，含诊断报告 | P1 |
| `rdd-knowledge` | 知识管理（ADR/技术债/Handoff） | P0 |
| `rdd-diagnosis` | 问题诊断，给出解决方案 | P1 |
| `rdd-fresh-check` | 新 Agent 可接手验证 | P1 |
| `rdd-loop` | 自动循环，7x24 推进 | P0 |

### 6.2 命令清单

```bash
# 项目初始化
rdd init [--template <template>] [--enable-hooks]

# 存量项目迁移
rdd migrate [--analyze] [--plan]

# Roadmap 管理
rdd roadmap create
rdd roadmap show
rdd roadmap add-stage <name>
rdd roadmap remove-stage <id>
rdd roadmap reorder <ids...>
rdd roadmap progress

# Stage 管理
rdd stage new <name>
rdd stage show <id>
rdd stage verify <id>
rdd stage complete <id>
rdd stage handoff

# Review
rdd review start [--type design|code]
rdd review filter-findings
rdd review verify-finding <id>

# 知识管理
rdd adr list
rdd adr add
rdd adr show <id>
rdd debt list
rdd debt add
rdd debt resolve <id>
rdd handoff generate

# 诊断
rdd diagnose [--fix]

# 自动循环
rdd loop start [--dry-run]
rdd loop status
rdd loop pause
rdd loop resume
rdd loop stop

# Hooks
rdd hooks list
rdd hooks test <channel>
rdd notify --trigger <trigger>

# 验证
rdd fresh-check
rdd gate check [--stage <id>]
```

---

## 七、目录结构

```
project/
│
├── .rdd/                          # RDD 配置目录
│   ├── config.yml                 # 主配置
│   ├── hooks.yml                  # Hook 通知配置
│   ├── templates.yml              # 通知模板
│   ├── checkpoints.yml            # 检查点配置
│   └── cache/                     # 缓存目录
│       ├── context.json           # 当前上下文
│       └── state.json             # 状态快照
│
├── docs/
│   ├── framework/                 # 规范层
│   │   ├── project-governance-spec.md    # 项目规范
│   │   ├── agentic-code-execution-spec.md # 执行规范
│   │   └── standards-authoring-spec.md   # 规范编写规范
│   │
│   ├── stages/                    # Stage 文档
│   │   ├── stage-roadmap.md       # Roadmap
│   │   ├── stage-0.md             # Stage 设计
│   │   ├── stage-0-review-log.md  # Review 日志
│   │   └── stage-0-retrospective.md # 复盘（可选）
│   │
│   ├── handoff/                   # Handoff 文档
│   │   └── handoff-latest.md      # 最新 Handoff
│   │
│   ├── 01-charter.md              # 项目章程
│   ├── 02-engineering-principles.md # 工程原则
│   ├── 03-stage-based-development.md # SBD 规范
│   ├── 08-autonomous-decisions.md # ADR 日志
│   ├── 10-review-practices.md     # Review 方法论
│   ├── 11-next-steps.md           # 当前进度
│   └── 12-technical-debt.md       # 技术债台账
│
├── AGENTS.md                      # Agent 入口
├── CLAUDE.md                      # Claude Code 入口
├── CHANGELOG.md                   # 变更日志
├── Taskfile.yml                   # 统一任务入口
└── README.md                      # 项目说明
```

---

## 八、实施计划

### 8.1 阶段划分

| 阶段 | 目标 | 产出 | 时间 |
|------|------|------|------|
| 阶段一 | 核心框架 | 目录结构、规范模板、基础技能 | 1 周 |
| 阶段二 | 自动化能力 | Stage 推进器、Review 自动化、知识管理 | 1 周 |
| 阶段三 | Hook 通知 | 多渠道通知、分级触发、模板系统 | 1 周 |
| 阶段四 | 自动循环 | 状态监控、异常恢复、7x24 推进 | 1 周 |
| 阶段五 | 测试验证 | 在实际项目中测试、修复问题 | 1 周 |

### 8.2 优先级排序

```
P0（必须实现）:
├── rdd-init（项目初始化）
├── rdd-migrate（存量迁移）
├── rdd-roadmap（Roadmap 管理）
├── rdd-stage-auto（Stage 自动执行）
├── rdd-knowledge（知识管理）
├── rdd-loop（自动循环）
└── Hook 通知系统（P0 级别）

P1（重要实现）:
├── rdd-review-auto（Review 自动化）
├── rdd-recovery（失败恢复）
├── rdd-diagnosis（问题诊断）
├── rdd-fresh-check（新 Agent 验证）
└── Hook 通知系统（P1-P2 级别）

P2（锦上添花）:
├── rdd 管理后台（可视化界面）
├── rdd metrics（指标统计）
└── Hook 通知系统（P3 级别）
```

---

## 九、验收标准

### 9.1 功能验收

| 编号 | 验收标准 | 验证方式 |
|------|---------|---------|
| F1 | 存量项目可通过 `rdd migrate` 完成迁移 | 在 示例项目测试 |
| F2 | 新项目可通过 `rdd init` 完成初始化 | 创建测试项目验证 |
| F3 | `rdd diagnose` 能诊断出常见问题 | 注入问题测试 |
| F4 | `rdd loop` 能自动推进 Stage | 在测试项目运行 |
| F5 | Hook 通知能正确触发和发送 | 触发各场景测试 |
| F6 | 所有技能和命令能正常工作 | 端到端测试 |

### 9.2 质量验收

| 编号 | 验收标准 |
|------|---------|
| Q1 | 所有规范文档符合规范编写规范 |
| Q2 | 所有技能通过 fresh-agent-check |
| Q3 | 所有命令有完整的帮助文档 |
| Q4 | Hook 配置文件有完整示例 |
| Q5 | 目录结构符合 RDD 规范 |

---

## 十、附录

### 10.1 ADR 格式

```markdown
### 决策 N：[标题]

**背景**：是什么让这个决策浮现出来

**决策内容**：选择了什么路径

**原因**：为什么这样选择

**对后续 Stage 的影响**：（不能留空）
```

### 10.2 技术债台账格式

```markdown
### TD-NN：简短标题
- **优先级**：[阻塞/降级功能/技术优化] / [架构级/模块级/局部]
- **来源**：[原型期主动妥协 / 审阅推后 / 自主决策妥协]（Stage 编号）
- **原始描述**：（引用原始文档表述）
- **来源文件**：（文件路径和行号）
- **建议落地 Stage**：（Stage N 或"专项"或"按需"）
```

### 10.3 Handoff 格式

```markdown
## 当前进度
- 阶段：
- 进度百分比：

## 已完成证据
- [链接1]
- [链接2]

## 阻塞与风险
- [阻塞点描述]

## 下一步唯一动作
- [具体动作描述]

## 降级策略
若 30 分钟无进展，触发 [降级策略描述]
```

### 10.4 Stage 设计文档格式

```markdown
# Stage N：[标题]

## 状态
[ ] 规划中 / [ ] 进行中 / [ ] 完成

## 目标
本阶段只解决什么

## 非目标
本阶段明确不做什么

## 核心假设
- 假设 A：[描述]
- 假设 B：[描述]

## 验收标准
- [ ] 验收标准 A
- [ ] 验收标准 B

## 回滚方案
失败时退回到哪个版本

## 已知限制
- [限制 A]
- [限制 B]

## 对后续 Stage 的影响
- [影响 A]
- [影响 B]
```

