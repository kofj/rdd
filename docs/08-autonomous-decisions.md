# 自主决策记录 (Autonomous Decisions Record)

> 本文档记录 RDD 项目中的架构决策和技术选择，确保决策过程可追溯、可理解。

---

## ADR 格式说明 (ADR Format Description)

### 什么是 ADR

ADR (Architecture Decision Record) 是记录架构决策的轻量级文档格式。每个决策记录包含：

- 决策的背景和上下文
- 做出的决策内容
- 做出该决策的原因
- 该决策对后续 Stage 的影响

### ADR 格式模板

```markdown
### 决策 N：[决策标题]

**背景**：是什么让这个决策浮现出来

**决策内容**：选择了什么路径

**原因**：为什么这样选择

**对后续 Stage 的影响**：（不能留空）
```

### 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| 决策编号 | 是 | 格式：决策 1、决策 2 等 |
| 决策标题 | 是 | 简洁概括决策内容 |
| 背景 | 是 | 描述触发这个决策的上下文 |
| 决策内容 | 是 | 明确描述做出的决策 |
| 原因 | 是 | 解释为什么做出这个决策 |
| 对后续 Stage 的影响 | 是 | 必须填写，描述对后续工作的影响 |

### 何时记录 ADR

以下情况需要记录 ADR：

1. **架构决策**：影响系统架构的重大决策
2. **技术选型**：选择技术栈、框架、库等
3. **设计权衡**：在多个方案间做出权衡
4. **假设变更**：核心假设被验证或证伪
5. **非目标声明**：明确不做某些事情
6. **技术债决策**：接受技术债的决策

### ADR 编写规范

```
DO:
- 每个决策独立记录
- 背景描述清晰，让新人能理解
- 决策内容明确，不含糊
- 原因充分，有理有据
- 影响具体，指向明确的 Stage

DON'T:
- "对后续 Stage 影响"留空
- 记录琐碎的日常决策
- 决策内容模棱两可
- 不记录原因或影响
```

---

## ADR 索引 (ADR Index)

<!-- 在此处添加新的 ADR 索引 -->

| 编号 | 标题 | 日期 | 相关 Stage | 状态 |
|------|------|------|------------|------|
| 决策 1 | Hook 脚本使用 source 引入共享函数 | 2026-03-07 | Stage 1 | 生效 |
| 决策 2 | Hook 触发通过 rdd-hooks skill 统一管理 | 2026-03-07 | Stage 1 | 生效 |
| 决策 3 | 使用相对路径和 PROJECT_ROOT 环境变量 | 2026-03-07 | Stage 1 | 生效 |
| 决策 4 | 凭证使用 ${VAR} 环境变量引用 | 2026-03-07 | Stage 1 | 生效 |
| 决策 5 | 选择 bats-core 作为 Shell 测试框架 | 2026-03-07 | Stage 2 | 生效 |
| 决策 6 | 测试分层策略：单元/BDD/E2E 三层测试 | 2026-03-07 | Stage 2 | 生效 |
| 决策 7 | 错误分类体系：可恢复/不可恢复两大类 | 2026-03-07 | Stage 4 | 生效 |
| 决策 8 | 重试策略：指数退避 + 抖动 | 2026-03-07 | Stage 4 | 生效 |
| 决策 9 | 降级策略：五级降级 (Level 0-4) | 2026-03-07 | Stage 4 | 生效 |
| 决策 10 | 日志格式：结构化 JSON 日志 | 2026-03-07 | Stage 4 | 生效 |
| 决策 11 | 指标格式：Prometheus 文本格式 | 2026-03-07 | Stage 4 | 生效 |
| 决策 12 | 熔断器：基于失败计数的熔断模式 | 2026-03-07 | Stage 4 | 生效 |
| 决策 13 | RBAC 权限模型：三角色设计 (admin/developer/viewer) | 2026-03-07 | Stage 6 | 生效 |
| 决策 14 | 审计日志采用文件存储 + JSON 格式方案 | 2026-03-07 | Stage 6 | 生效 |
| 决策 15 | 敏感数据处理：环境变量 + 可选 Vault 集成 | 2026-03-07 | Stage 6 | 生效 |
| 决策 16 | Shell 脚本安全加固：输入验证 + 注入防护 | 2026-03-07 | Stage 6 | 生效 |
| 决策 17 | 性能基准测试：自定义 bash 脚本方案 | 2026-03-07 | Stage 5 | 生效 |
| 决策 18 | 版本管理：语义化版本 + 兼容性矩阵 | 2026-03-07 | Stage 5 | 生效 |
| 决策 19 | 迁移策略：备份 + 原子迁移 + 回滚支持 | 2026-03-07 | Stage 5 | 生效 |
| 决策 20 | 兼容性检查：YAML schema 验证 + 破坏性变更检测 | 2026-03-07 | Stage 5 | 生效 |
| 决策 21 | 安装方式：curl \| sh 一键安装优先 | 2026-03-09 | Stage 8 | 生效 |
| 决策 22 | Skills 分发：复制到 ~/.claude/skills/ | 2026-03-09 | Stage 8 | 生效 |
| 决策 23 | 发布渠道：GitHub Release + npm | 2026-03-09 | Stage 9 | 生效 |
| 决策 24 | 命令命名：rdd (简短命令友好) | 2026-03-09 | Stage 8 | 生效 |

---

## ADR 记录

---

### 决策 1：Hook 脚本使用 source 引入共享函数

**背景**：Hook 脚本需要调用 notify.sh 中定义的 log_info、log_warn、log_error、send_notification 等函数。当前 Hook 脚本直接调用这些函数但没有 source notify.sh，导致 "command not found" 错误。

**决策内容**：所有 Hook 脚本在开头统一使用 `source "${SCRIPTS_DIR}/notify.sh"` 引入共享函数，并确保 SCRIPTS_DIR 正确设置。

**原因**：
1. 保持代码 DRY（Don't Repeat Yourself）
2. 便于维护，函数修改只需改一处
3. 符合 Shell 脚本最佳实践
4. 便于单元测试

**对后续 Stage 的影响**：
- Stage 2 测试可以直接测试 notify.sh 函数，无需复制代码
- 未来新增 Hook 只需 source 即可使用所有函数
- Stage 3 可依赖稳定的 Hook 机制实现恢复通知

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. 每个脚本内定义函数 - 代码重复，维护困难
2. 使用符号链接 - 不适用于函数，仅适用于文件

---

### 决策 21：安装方式采用 curl | sh 一键安装优先

**背景**：用户需要能够轻松安装 RDD Framework，当前没有安装方法。需要选择一种最方便用户的安装方式。

**决策内容**：
1. 首选安装方式：`curl -fsSL https://.../install.sh | sh`
2. 支持平台：macOS, Linux (x86_64, ARM64)
3. 安装目录：`~/.rdd-framework/`
4. 自动配置 PATH 和 Skills

**原因**：
1. 最简单的安装方式，无依赖
2. 不需要预先安装 Node.js 或其他运行时
3. 符合主流 CLI 工具安装习惯（如 Homebrew, nvm, rustup）
4. 脚本可检查依赖并给出友好提示

**对后续 Stage 的影响**：
- Stage 8 只需编写安装脚本，无需额外基础设施
- Stage 9 可扩展 npm 包作为备选安装方式
- 用户可在 5 分钟内完成安装和首次使用

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. 仅 npm 包 - 需要 Node.js 环境，限制用户群
2. 仅 Homebrew - 仅限 macOS 用户
3. 手动下载 - 用户体验差，易出错

---

### 决策 22：Skills 通过复制方式分发到 ~/.claude/skills/

**背景**：Claude Code 需要能够识别和使用 RDD skills。需要确定如何将 skills 安装到用户系统。

**决策内容**：
1. 安装时复制 skills 到 `~/.claude/skills/`
2. 复制 commands 到 `~/.claude/commands/`
3. 保留原始文件不变，独立副本
4. 提供 `rdd upgrade` 命令更新 skills

**原因**：
1. 最可靠的分发方式，无符号链接跨平台问题
2. 用户可以自定义 skills 而不影响全局
3. Claude Code 能够正确识别和加载
4. 卸载时直接删除目录即可

**对后续 Stage 的影响**：
- Stage 8 安装脚本需实现复制逻辑
- 用户可在项目内 `.claude/skills/` 覆盖全局 skills
- 支持多版本共存（未来）

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. 符号链接 - Windows 兼容性问题
2. 运行时动态加载 - 需要修改 Claude Code
3. 项目内 skills - 每个项目需要单独配置

---

### 决策 23：发布渠道采用 GitHub Release + npm

**背景**：需要选择发布渠道让用户获取框架。

**决策内容**：
1. 主要渠道：GitHub Release（安装脚本下载源）
2. 次要渠道：npm 全局包（覆盖 Node.js 用户）
3. 版本管理：语义化版本，GitHub Releases 管理

**原因**：
1. GitHub Release 免费、可靠、无需额外配置
2. npm 覆盖 Node.js 开发者群体
3. 不依赖付费服务
4. 版本发布流程简单

**对后续 Stage 的影响**：
- Stage 8 使用 GitHub Release 作为下载源
- Stage 9 实现 npm 包发布
- CI/CD 自动化发布流程

**Date**: 2026-03-09

**Related Stage**: Stage 9

**Alternatives Considered**:
1. 仅 GitHub Release - 覆盖面有限
2. 仅 npm - 需要 Node.js 环境
3. Homebrew + npm + GitHub - 维护成本高

---

### 决策 24：命令命名采用 rdd（简短命令友好）

**背景**：用户需要在命令行使用 RDD 命令，需要确定命令名称。

**决策内容**：
1. 主命令：`rdd`（简短，易记）
2. 子命令：`rdd init`, `rdd migrate`, `rdd stage`, `rdd knowledge`
3. Claude Code skills：保持 `/rdd-*` 格式（由 Claude Code 规范决定）

**原因**：
1. 简短命令减少输入，提高效率
2. 与其他 CLI 工具命名习惯一致
3. 子命令结构清晰
4. 易于记忆和使用

**对后续 Stage 的影响**：
- Stage 8 安装脚本创建 `rdd` 命令
- 文档使用 `rdd` 命令示例
- Skills 保持 `/rdd-init` 格式

**Date**: 2026-03-09

**Related Stage**: Stage 8

**Alternatives Considered**:
1. `rdd-framework` - 过长，输入不便
2. `rdd-cli` - 不必要的后缀
3. `@kofj/rdd` - npm scope 命名，不适合 CLI

---

### 决策 2：Hook 触发通过 rdd-hooks skill 统一管理

**背景**：当前 Hooks 脚本存在但没有任何机制触发它们。需要在合适的时机调用这些脚本。

**决策内容**：创建 rdd-hooks skill 定义触发规则，各 skill 在适当时机通过环境变量传递参数并调用 Hook 脚本。

**原因**：
1. 集中管理所有 Hook 触发逻辑
2. 便于测试和调试
3. 遵循 RDD 单一职责原则
4. 各 skill 无需了解 Hook 实现细节

**对后续 Stage 的影响**：
- Stage 2 可以测试 Hook 触发流程
- Stage 3 可依赖此机制发送恢复通知
- Stage 4 可扩展更多 Hook 类型

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. 在每个 skill 中直接调用 - 分散，难维护
2. 创建独立 Hook 服务 - 过度设计，增加复杂度

---

### 决策 3：使用相对路径和 PROJECT_ROOT 环境变量

**背景**：当前代码中硬编码了 `/data/works/play/sbd/` 路径，导致框架无法在其他项目中使用。

**决策内容**：
1. 所有路径使用相对路径（相对于脚本所在目录）
2. 支持 PROJECT_ROOT 环境变量覆盖项目根目录
3. 在 skills 中使用 `.` 或 `${PROJECT_ROOT:-.}` 形式

**原因**：
1. 使框架可移植到任意项目
2. 保持向后兼容（默认当前目录）
3. 符合 12-Factor App 原则
4. 简化部署流程

**对后续 Stage 的影响**：
- Stage 2 测试可在临时目录运行
- Stage 4 多项目支持变得简单
- rdd-init 可直接在新项目创建结构

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. 绝对路径配置文件 - 需要每个项目单独配置
2. 自动检测项目根 - 不可靠，可能误判

---

### 决策 4：凭证使用 ${VAR} 环境变量引用

**背景**：当前 hooks.yml 中 Webhook URL、Bot Token 等敏感信息需要明文存储，存在安全风险。

**决策内容**：支持 `${VAR}` 和 `$VAR` 形式的环境变量引用，配置文件中只存储变量名而非实际值。

**原因**：
1. 符合安全最佳实践
2. 便于 CI/CD 集成
3. 支持不同环境不同配置
4. 避免敏感信息泄露到版本控制

**对后续 Stage 的影响**：
- Stage 2 测试可使用 mock 环境变量
- Stage 4 CI/CD 集成可直接使用 CI 环境变量
- 可安全提交配置文件示例

**Date**: 2026-03-07

**Related Stage**: Stage 1

**Alternatives Considered**:
1. 加密存储 - 增加复杂度，需要密钥管理
2. 单独 secrets 文件 - 增加配置复杂度
3. 仅环境变量 - 不便于本地开发

---

### 决策 5：选择 bats-core 作为 Shell 测试框架

**背景**：Stage 2 需要建立测试体系，为 notify.sh 和 Hook 脚本提供单元测试和 BDD 测试能力。当前没有任何测试框架。

**决策内容**：选择 bats-core 作为 Shell 脚本测试框架，用于单元测试和 BDD 测试。

**原因**：
1. 原生 BDD 风格语法（@test "description"），符合 Stage 2 的 BDD 测试需求
2. TAP (Test Anything Protocol) 输出，易于 CI 集成
3. 活跃的社区和丰富的文档
4. 支持环境变量 mock 和函数覆盖
5. 可扩展通过 bats-support、bats-assert 等库

**对后续 Stage 的影响**：
- Stage 2：建立完整的单元测试和 BDD 测试体系
- Stage 3：可测试上下文恢复逻辑
- Stage 4：CI/CD 可直接使用 bats 输出

**Date**: 2026-03-07

**Related Stage**: Stage 2

**Alternatives Considered**:
1. shunit2 - xUnit 风格，不适合 BDD 场景
2. shellcheck - 静态分析，非测试框架
3. 自定义测试脚本 - 重复造轮子，功能有限

---

### 决策 6：测试分层策略：单元/BDD/E2E 三层测试

**背景**：需要为 RDD 框架建立完整测试体系，确保各层级测试覆盖不同的验证需求。

**决策内容**：采用三层测试策略：

1. **单元测试层 (tests/unit/)**：测试单个函数和脚本逻辑
   - notify.sh 各函数测试
   - Hook 脚本测试
   - 工具函数测试
   - 目标覆盖率 >= 80%

2. **BDD 测试层 (tests/bdd/)**：测试用户行为场景
   - Given/When/Then 格式
   - 验证 Hook 触发流程
   - 验证通知发送流程
   - 验证错误处理

3. **E2E 测试层 (tests/e2e/)**：端到端集成测试
   - 完整工作流测试
   - 真实环境验证
   - Agent 行为模拟

**原因**：
1. 分层测试隔离关注点
2. 单元测试快速反馈，BDD 验证行为，E2E 验证集成
3. 符合测试金字塔原则
4. 便于定位问题层级

**对后续 Stage 的影响**：
- Stage 2：实现三层测试框架和基础测试用例
- Stage 3：可添加上下文恢复的 E2E 测试
- Stage 4：CI/CD 可分层运行测试

**Date**: 2026-03-07

**Related Stage**: Stage 2

**Alternatives Considered**:
1. 仅单元测试 - 无法验证行为和集成
2. 仅 E2E 测试 - 反馈慢，调试困难
3. 无分层 - 测试混乱，职责不清

---

### 决策 7：错误分类体系采用可恢复/不可恢复两大类

**背景**：Stage 4 需要建立完善的错误处理机制，需要对错误进行分类以决定处理策略。

**决策内容**：采用两级错误分类体系：
1. **可恢复错误 (Recoverable)**：可通过重试、降级或熔断自动处理
   - 临时性错误：网络超时、服务不可用、限流
   - 可降级错误：通知渠道失败、模板渲染失败
   - 需熔断错误：持续失败的通知渠道

2. **不可恢复错误 (Non-Recoverable)**：需要人工干预
   - 配置错误：格式错误、缺失必需配置
   - 逻辑错误：无效触发类型、模板语法错误
   - 环境错误：缺失工具、权限不足
   - 系统错误：内存不足、磁盘满

**原因**：
1. 简化错误处理逻辑，二分法清晰易理解
2. 可恢复错误可自动处理，减少人工干预
3. 不可恢复错误明确需要人工介入
4. 符合业界最佳实践

**对后续 Stage 的影响**：
- Stage 5 可基于错误分类进行性能分析
- Stage 6 审计日志可记录错误分类
- 所有后续 Stage 都需要使用统一的错误分类

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. 三级分类（可恢复/部分可恢复/不可恢复）- 过于复杂
2. 多标签分类 - 不便于决策
3. 无分类 - 混乱，难以处理

---

### 决策 8：重试策略采用指数退避 + 抖动

**背景**：通知发送等操作可能因临时故障失败，需要自动重试机制。

**决策内容**：采用指数退避（Exponential Backoff）加抖动（Jitter）的重试策略：
- 初始延迟：1秒
- 最大延迟：30秒
- 退避倍数：2
- 抖动范围：±50% 随机化
- 最大重试次数：3次

**原因**：
1. 指数退避避免立即重试导致的资源浪费
2. 抖动防止多个客户端同时重试（惊群效应）
3. 最大延迟限制避免过长等待
4. 最大重试次数限制避免无限重试
5. 符合 AWS/Google Cloud 的最佳实践

**对后续 Stage 的影响**：
- Stage 5 性能测试需要考虑重试对延迟的影响
- 所有网络操作都应使用统一的重试策略
- Stage 7 文档需要说明重试行为

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. 固定间隔重试 - 可能导致惊群效应
2. 线性退避 - 恢复不够快或等待过长
3. 无重试 - 可靠性差

---

### 决策 9：降级策略采用五级降级 (Level 0-4)

**背景**：当系统部分功能不可用时，需要优雅降级以保持核心功能可用。

**决策内容**：采用五级降级策略：
- **Level 0 (Full)**：全部功能可用，所有通知渠道正常
- **Level 1 (Reduced)**：主要渠道正常，备用渠道待命
- **Level 2 (Essential)**：仅关键通知 (P0/P1)，减少重试
- **Level 3 (Minimal)**：仅 P0 通知，无重试，静态内容
- **Level 4 (Safe Mode)**：无外部调用，仅本地日志

**原因**：
1. 渐进式降级避免突然失效
2. 分级明确，便于监控和告警
3. Level 4 安全模式确保最小可用性
4. 可基于失败率自动调整降级级别
5. 便于运维人员快速理解系统状态

**对后续 Stage 的影响**：
- Stage 5 性能测试需要验证各级降级行为
- Stage 6 权限系统可与降级级别联动
- Stage 7 运维手册需要说明各级降级的处理方法

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. 二级降级（正常/降级）- 粒度太粗
2. 无限级别 - 过于复杂
3. 无降级机制 - 可靠性差

---

### 决策 10：日志格式采用结构化 JSON 日志

**背景**：需要可观测性支持故障排查和性能分析。

**决策内容**：采用结构化 JSON 日志格式：
- 必需字段：timestamp, level, message
- 上下文字段：component, trace_id, span_id
- 错误字段：error_code, error_category
- 性能字段：duration_ms
- RDD 字段：rdd_stage, rdd_project

**原因**：
1. JSON 格式机器可读，便于日志聚合
2. 结构化字段便于搜索和过滤
3. trace_id 支持追踪单个请求
4. 与 ELK、Loki 等主流日志系统兼容
5. 便于后期分析和监控

**对后续 Stage 的影响**：
- Stage 5 可利用 duration_ms 进行性能分析
- Stage 6 审计日志可复用相同格式
- Stage 7 运维手册需要说明日志格式

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. 纯文本日志 - 不便于解析和搜索
2. CSV 格式 - 字段扩展不便
3. 二进制格式 - 不便于调试

---

### 决策 11：指标格式采用 Prometheus 文本格式

**背景**：需要暴露系统指标以支持监控和告警。

**决策内容**：采用 Prometheus 文本格式暴露指标：
- Counter 类型：rdd_notifications_total, rdd_errors_total
- Gauge 类型：rdd_circuit_breaker_state, rdd_degradation_level
- Histogram 类型：rdd_notification_duration_seconds
- 输出文件：${RDD_DIR}/cache/metrics.prom

**原因**：
1. Prometheus 是云原生监控的事实标准
2. 文本格式简单，无依赖
3. 支持 Counter/Gauge/Histogram 三种类型
4. 与 Grafana 等可视化工具兼容
5. 可被 Prometheus 直接抓取

**对后续 Stage 的影响**：
- Stage 5 性能测试可利用 Histogram 数据
- Stage 7 可提供 Grafana Dashboard 模板
- 未来可添加 HTTP endpoint 支持实时抓取

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. StatsD 格式 - 需要 statsd exporter
2. OpenTelemetry - 过于复杂
3. 自定义格式 - 兼容性差

---

### 决策 12：熔断器采用基于失败计数的熔断模式

**背景**：当某个通知渠道持续失败时，需要快速失败避免资源浪费。

**决策内容**：采用基于失败计数的熔断器模式：
- **CLOSED**：正常状态，请求通过
- **OPEN**：熔断状态，请求直接失败
- **HALF_OPEN**：半开状态，允许测试请求

参数配置：
- 失败阈值：5次连续失败后打开
- 成功阈值：3次连续成功后关闭
- 超时时间：60秒后尝试半开
- 状态存储：JSON 文件

**原因**：
1. 熔断器防止级联故障
2. 三态模型简单可靠
3. 基于计数而非时间窗口，实现简单
4. JSON 文件存储无需外部依赖
5. 可独立于其他功能使用

**对后续 Stage 的影响**：
- Stage 5 可基于熔断器状态进行性能分析
- Stage 7 运维手册需要说明熔断器状态
- 后续可扩展为分布式熔断器

**Date**: 2026-03-07

**Related Stage**: Stage 4

**Alternatives Considered**:
1. 无熔断器 - 故障会持续影响系统
2. 时间窗口熔断 - 实现复杂，需要滑动窗口
3. 令牌桶 - 适合限流，不适合熔断

---

### 决策 5：使用 Rust 作为主要开发语言

**背景**：项目需要高性能、内存安全的后端服务，团队有 Rust 开发经验。

**决策内容**：选择 Rust 作为主要开发语言，配合 Tokio 异步运行时。

**原因**：
1. Rust 提供内存安全保证，减少运行时错误
2. Tokio 生态成熟，适合构建高性能网络服务
3. 团队有 Rust 开发经验，学习成本低
4. 静态类型系统有利于大型项目的维护

**对后续 Stage 的影响**：
- Stage 2：需要引入 Tokio 和相关异步库
- Stage 3：需要设计异步 API 接口
- Stage 4：需要考虑 Rust 的部署和分发方案

---

### 决策 2：使用 etcd 作为分布式配置存储

**背景**：项目需要分布式配置管理，支持多节点部署。

**决策内容**：选择 etcd 作为分布式配置存储，配合 etcd-client 库。

**原因**：
1. etcd 提供 CP 特性，适合配置管理场景
2. 支持 Watch 机制，实时感知配置变更
3. 提供 Lease 机制，支持分布式锁
4. 与 Kubernetes 生态兼容

**对后续 Stage 的影响**：
- Stage 5：需要实现 etcd 连接池管理
- Stage 6：需要设计配置变更的通知机制
- Stage 7：需要实现分布式锁保证一致性

---

### 示例 ADR (Example ADR)

以下是一个完整的 ADR 示例：

### 决策 3：采用分层架构设计

**背景**：项目初期需要确定整体架构风格，以支持后续的功能扩展和维护。

**决策内容**：采用分层架构，分为以下层次：

```
┌─────────────────────────────────────┐
│           API Layer                 │  ← 对外接口
├─────────────────────────────────────┤
│         Service Layer               │  ← 业务逻辑
├─────────────────────────────────────┤
│         Repository Layer            │  ← 数据访问
├─────────────────────────────────────┤
│         Infrastructure Layer        │  ← 基础设施
└─────────────────────────────────────┘
```

**原因**：
1. 分层架构职责清晰，便于团队协作
2. 每层可独立测试，提高代码质量
3. 便于后续替换底层实现（如数据库）
4. 符合团队熟悉的架构风格

**对后续 Stage 的影响**：
- Stage 1：定义各层接口和依赖关系
- Stage 2：实现 Infrastructure Layer（日志、配置）
- Stage 3：实现 Repository Layer（数据访问）
- Stage 4：实现 Service Layer（核心业务）
- Stage 5：实现 API Layer（对外接口）
- 后续 Stage：每层可独立演进，但需注意接口兼容

**技术债记录**：
- TD-02：初期可能存在跨层调用，需要在后续 Stage 中重构
- 建议 Stage 6 专门处理代码规范化

---

### 决策 13：RBAC 权限模型：三角色设计 (admin/developer/viewer)

**背景**：RDD Framework 需要权限控制系统来管理不同用户对框架操作的访问权限，确保安全性和合规性。

**决策内容**：采用基于角色的访问控制 (RBAC) 模型，定义三个角色：

1. **Admin (管理员)**：
   - 完全控制权限
   - 用户和角色管理
   - 配置修改
   - 审计日志访问

2. **Developer (开发者)**：
   - 执行 Stage 和测试
   - 编辑设计文档
   - 管理技术债
   - 执行 Hooks

3. **Viewer (观察者)**：
   - 只读访问
   - 查看文档和状态
   - 查看路线图和进度

**原因**：
1. 三角色设计覆盖 RDD 主要使用场景
2. 实现简单，配置文件即可管理
3. 易于理解和维护
4. 可扩展到更细粒度的 ACL

**对后续 Stage 的影响**：
- Stage 7：需要在文档中说明权限配置
- 生产部署：必须配置 RBAC 后才能部署
- 未来版本：可能需要扩展到更细粒度的权限控制

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. ACL (访问控制列表) - 太复杂，初期不需要
2. ABAC (基于属性的访问控制) - 实现复杂，过度设计
3. 无权限控制 - 不符合安全合规要求

---

### 决策 14：审计日志采用文件存储 + JSON 格式方案

**背景**：RDD Framework 需要审计日志来记录所有重要操作，满足安全审计和合规要求。

**决策内容**：
1. 采用文件存储审计日志，支持双格式：
   - 文本格式 (audit.log)：人类可读
   - JSON 格式 (audit.json)：机器可解析

2. 审计日志格式包含：
   - who: 操作者
   - when: 时间戳
   - what: 操作对象
   - where: 操作来源
   - result: 操作结果

3. 日志轮转策略：
   - 单文件最大 10MB
   - 保留最近 10 个日志文件
   - 自动压缩归档

**原因**：
1. 文件存储简单可靠，无需额外依赖
2. JSON 格式便于日志分析和集成
3. 双格式兼顾人类阅读和机器处理
4. 轮转策略防止磁盘空间耗尽

**对后续 Stage 的影响**：
- Stage 7：需要提供日志查询和导出工具
- 高频场景：可能需要数据库存储方案
- 日志分析：可集成 ELK 等日志平台

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. 数据库存储 - 增加依赖，初期不需要
2. 仅文本格式 - 不利于机器解析
3. 仅 JSON 格式 - 不便于人工查看
4. Syslog - 增加配置复杂度

---

### 决策 15：敏感数据处理：环境变量 + 可选 Vault 集成

**背景**：Stage 1 已实现环境变量引用，但需要更强的敏感数据保护机制，包括加密存储和可选的 Vault 集成。

**决策内容**：
1. 环境变量作为主要凭证存储方式（Stage 1 已实现）
2. 新增强敏感数据加密功能：
   - AES-256-CBC 加密
   - 自动密钥生成和管理
   - 加密/解密命令行工具

3. 可选 HashiCorp Vault 集成：
   - 支持 KV v2 secret engine
   - 支持 Transit 加密服务
   - 自动降级到环境变量

4. 数据脱敏策略：
   - 密码完全遮蔽
   - Token 显示首尾各 4 字符
   - URL 遮蔽凭证部分

**原因**：
1. 环境变量是云原生标准做法
2. Vault 是业界标准的密钥管理方案
3. 可选集成降低使用门槛
4. 分层安全策略满足不同安全需求

**对后续 Stage 的影响**：
- Stage 7：需要文档说明 Vault 配置方法
- 生产部署：建议启用 Vault 集成
- 安全审计：需验证敏感数据保护措施

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. 仅环境变量 - 安全性不足，不支持轮换
2. 强制 Vault - 增加部署复杂度
3. 自建密钥管理 - 重复造轮子，安全风险
4. 配置文件加密 - 不便于 CI/CD 集成

---

### 决策 16：Shell 脚本安全加固：输入验证 + 注入防护

**背景**：RDD Framework 的核心逻辑由 Shell 脚本实现，需要防止常见的 Shell 脚本安全漏洞，特别是命令注入和路径遍历。

**决策内容**：
1. 输入验证机制：
   - 字母数字验证 (alphanumeric)
   - 路径验证（防止路径遍历）
   - 命令验证（防止命令注入）
   - URL/Email 格式验证

2. 注入防护：
   - 危险字符过滤 (;、|、&、$()、`` 等)
   - YAML/JSON 转义
   - 安全文件操作

3. 安全配置检查：
   - 文件权限检查
   - 凭证暴露检查
   - RBAC 配置检查
   - 审计日志检查

**原因**：
1. Shell 脚本是安全薄弱环节
2. 输入验证是防止注入的第一道防线
3. 自动化检查确保安全配置一致性
4. 符合安全最佳实践

**对后续 Stage 的影响**：
- Stage 2：测试需覆盖安全验证场景
- Stage 7：需提供安全配置指南
- 所有脚本：需应用安全验证函数

**Date**: 2026-03-07

**Related Stage**: Stage 6

**Alternatives Considered**:
1. 重写为 Python/Rust - 工作量大，影响兼容性
2. 仅依赖外部安全扫描 - 不能预防运行时攻击
3. 沙箱执行 - 增加复杂度，限制功能

---

### 决策 17：性能基准测试采用自定义 bash 脚本方案

**背景**：Stage 5 需要建立性能基准测试体系，测量 Hook 触发延迟、通知发送延迟和内存占用，确保性能指标达标。

**决策内容**：采用自定义 bash 脚本 (benchmark.sh) 实现性能基准测试：
- 使用 bash 内置的 date +%s%N 获取纳秒级时间戳
- 通过 /proc/$PID/status 获取内存占用
- 支持多次迭代计算统计数据 (min/max/avg/median/p95/p99)
- 输出 JSON 格式报告便于 CI 集成

**原因**：
1. 无需额外依赖，bash 原生支持
2. 与 RDD 现有脚本风格一致
3. 轻量级，不增加部署复杂度
4. 可直接集成到 Taskfile
5. JSON 输出支持 CI/CD 管道

**对后续 Stage 的影响**：
- Stage 7：可在 CI 中自动运行性能回归测试
- 性能数据可用于生成性能报告
- 可与监控系统集成实现持续性能追踪

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. 使用 hyperfine - 需要安装外部工具
2. 使用 Python + timeit - 增加 Python 依赖
3. 使用 shell 内置 time - 精度不足

---

### 决策 18：版本管理采用语义化版本 + 兼容性矩阵

**背景**：RDD Framework 需要版本管理系统来跟踪发布版本、管理兼容性和支持升级迁移。

**决策内容**：采用语义化版本 (SemVer) 配合兼容性矩阵：
- 版本格式：MAJOR.MINOR.PATCH[-PRERELEASE]
- VERSION 文件存储当前版本和兼容范围
- 提供版本比较、兼容性检查、版本升级等工具函数
- 兼容性矩阵定义版本间的兼容关系

**原因**：
1. SemVer 是业界标准，开发者熟悉
2. 兼容性矩阵明确版本升级路径
3. VERSION 文件简单可靠，无外部依赖
4. 版本比较逻辑可完全在 bash 中实现
5. 支持预发布版本 (alpha/beta/rc)

**对后续 Stage 的影响**：
- Stage 7：CI/CD 可自动更新版本号
- 发布流程可自动化版本升级
- 用户可根据兼容性矩阵选择升级版本

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. Git tags 作为版本 - 需要 git 环境
2. 自动递增版本号 - 无法表达破坏性变更
3. 日期版本 (CalVer) - 不适合库/框架

---

### 决策 19：迁移策略采用备份 + 原子迁移 + 回滚支持

**背景**：用户升级 RDD 版本时需要安全可靠的迁移机制，确保数据不丢失且可回滚。

**决策内容**：采用三阶段迁移策略：
1. **预检阶段**：检查前置条件、磁盘空间、权限
2. **备份阶段**：创建完整备份，记录迁移元数据
3. **执行阶段**：原子更新，失败自动回滚

支持特性：
- 迁移前自动备份关键配置
- 迁移脚本按版本组织 (.rdd/migrations/)
- 迁移日志记录所有操作
- 支持一键回滚到上一个版本

**原因**：
1. 备份确保数据安全，可恢复
2. 原子迁移保证一致性
3. 回滚机制降低升级风险
4. 迁移日志便于审计和故障排查
5. 分阶段设计便于调试和扩展

**对后续 Stage 的影响**：
- Stage 7：可在 CI 中自动测试迁移流程
- 提供迁移文档和最佳实践指南
- 可扩展支持数据库迁移（如需要）

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. 仅提示用户手动备份 - 用户体验差
2. 无回滚支持的迁移 - 风险高
3. 外部迁移工具 - 增加依赖

---

### 决策 20：兼容性检查采用 YAML schema 验证 + 破坏性变更检测

**背景**：需要验证用户配置文件与当前版本 RDD 兼容，及时发现配置问题和潜在破坏性变更。

**决策内容**：实现多维度兼容性检查：
1. **Schema 验证**：检查必需字段、字段类型、有效值
2. **版本兼容性**：检查配置版本与框架版本兼容性
3. **破坏性变更检测**：识别版本间的破坏性变更
4. **废弃警告**：提示即将移除的功能
5. **自动修复**：对简单问题提供自动修复能力

**原因**：
1. Schema 验证提前发现配置错误
2. 破坏性变更检测帮助用户规划升级
3. 废弃警告给用户迁移时间
4. 自动修复减少用户手动操作
5. 综合检查提高系统稳定性

**对后续 Stage 的影响**：
- Stage 7：可集成到 CI 流程自动检查
- 配置验证可防止运行时错误
- 可扩展支持更多配置格式

**Date**: 2026-03-07

**Related Stage**: Stage 5

**Alternatives Considered**:
1. 仅版本号检查 - 无法发现配置问题
2. 外部 schema 验证工具 - 增加依赖
3. 无兼容性检查 - 用户体验差，易出错

---

### 决策 17：Handoff 文档使用 Markdown 格式存储在 .rdd/cache/handoff.md

**背景**：Stage 3 需要实现上下文恢复系统，需要确定 Handoff 文档的存储格式和位置。

**决策内容**：
1. **存储格式**：采用 Markdown 格式，便于 Agent 和人类阅读
2. **存储位置**：`.rdd/cache/handoff.md`，与 Checkpoint 文件同目录
3. **文档结构**：
   - Current Progress (当前进度)
   - Completed Evidence (已完成证据)
   - Blockers and Risks (阻塞和风险)
   - Next Single Action (下一步行动)
   - Degradation Strategy (降级策略)
   - Recovery Instructions (恢复指令)

**原因**：
1. Markdown 格式易于 Agent 解析和生成
2. 纯文本格式无需额外依赖
3. 与 CLAUDE.md 风格一致
4. 便于版本控制和差异比较
5. 存储在 cache 目录可被 gitignore

**对后续 Stage 的影响**：
- Stage 4 CI/CD 可直接读取 Handoff 状态
- 未来可扩展支持多项目 Handoff
- 可集成到通知系统

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. JSON 格式 - 不便于人类阅读
2. YAML 格式 - 需要 YAML 解析器
3. 存储在 docs 目录 - 会污染版本历史

---

### 决策 18：Checkpoint 使用 JSON 格式存储在 .rdd/cache/checkpoints.json

**背景**：Stage 3 需要保存执行状态以便恢复，需要确定 Checkpoint 的存储格式和结构。

**决策内容**：
1. **存储格式**：JSON 格式，便于程序解析
2. **存储位置**：`.rdd/cache/checkpoints.json`
3. **数据结构**：
   - version: 格式版本
   - project: 项目信息
   - stage: 当前 Stage 信息
   - gates: Gate 完成状态
   - decisions: 决策历史
   - blockers: 阻塞项
   - tech_debt: 技术债状态
   - next_steps: 下一步
   - timestamp: 时间戳
   - recovery_count: 恢复次数

**原因**：
1. JSON 是 Shell 脚本可解析的标准格式
2. 结构化数据便于程序处理
3. 支持增量更新
4. 可扩展添加新字段
5. 与 Handoff 文档互补

**对后续 Stage 的影响**：
- Stage 4 可基于 Checkpoint 实现断点续传
- Stage 5 可基于 Checkpoint 生成进度报告
- 未来可支持分布式 Checkpoint 同步

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. SQLite 数据库 - 增加依赖
2. 纯文本格式 - 不便于结构化查询
3. 多文件存储 - 增加管理复杂度

---

### 决策 19：恢复协议在 CLAUDE.md 中定义会话启动协议

**背景**：Stage 3 需要实现 Compact 后的自动恢复，需要确定恢复协议的定义位置和触发机制。

**决策内容**：
1. **协议位置**：在 CLAUDE.md 中定义 Compact Recovery Protocol 章节
2. **检测机制**：通过检查 `.rdd/cache/handoff.md` 是否存在判断是否需要恢复
3. **恢复步骤**：
   - 读取 Handoff 文档
   - 加载 Checkpoint 状态
   - 验证环境一致性
   - 从上次中断点继续
   - 确认恢复完成

**原因**：
1. CLAUDE.md 是 Agent 的入口文档
2. 会话启动时必然读取 CLAUDE.md
3. 检测机制简单可靠
4. 不需要修改 Agent 核心逻辑
5. 文档化便于理解和维护

**对后续 Stage 的影响**：
- 所有 Agent 都能自动支持恢复
- 可扩展支持更多恢复场景
- 未来可集成到 Agent 训练

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. 独立恢复脚本 - Agent 需要主动调用
2. 环境变量标记 - 可能被覆盖
3. Git hook 触发 - 与版本控制耦合

---

### 决策 20：Handoff 自动触发采用三种触发机制

**背景**：Stage 3 需要确定何时自动生成 Handoff 文档，以确保上下文不会丢失。

**决策内容**：实现三种自动触发机制：
1. **Gate 完成触发**：任何 Gate 完成后自动生成 Handoff
2. **决策触发**：重要决策（ADR）记录后更新 Handoff
3. **定时触发**：30 分钟无 Checkpoint 更新时自动生成

**原因**：
1. Gate 完成是重要里程碑，应该记录
2. 决策影响后续工作，需要记录上下文
3. 定时触发防止长时间运行任务丢失进度
4. 三种触发机制互补，覆盖不同场景
5. 可通过任务命令手动触发

**对后续 Stage 的影响**：
- Stage 4 可扩展更多触发条件
- 未来可支持自定义触发规则
- 可集成到 CI/CD 流水线

**Date**: 2026-03-08

**Related Stage**: Stage 3

**Alternatives Considered**:
1. 仅手动触发 - 容易遗忘
2. 仅定时触发 - 可能错过重要节点
3. 所有操作后触发 - 过于频繁，影响性能

---

## ADR 废弃记录

当决策不再适用时，在此记录废弃原因：

### [决策编号] 废弃记录

**废弃日期**：[日期]

**废弃原因**：[说明为什么废弃这个决策]

**替代方案**：[新的决策或方案]

**影响评估**：[废弃后对现有代码的影响]

---

## 修订记录

| 版本 | 日期 | 修订内容 | 修订人 |
|------|------|----------|--------|
| v1.0 | [日期] | 初始版本 | [姓名] |

---

> **重要**：所有架构决策必须在此记录。"对后续 Stage 的影响"字段不能留空，这是 ADR 的核心价值所在。

### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-07
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-07
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-07
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-07
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-08
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-09
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-09
**Related Stage**: Stage unknown
### Decision: Hypothesis Invalidated (Stage unknown)

**Background**: During Stage unknown, testing revealed that a core hypothesis was invalid.

**Hypothesis**: Unknown

**Invalidation Reason**: Unknown

**Evidence**: No evidence provided

**Impact on Subsequent Stages**:
- This stage may need to be redesigned
- Dependent stages may need to be reevaluated
- Roadmap may need adjustment

**Date**: 2026-03-09
**Related Stage**: Stage unknown

