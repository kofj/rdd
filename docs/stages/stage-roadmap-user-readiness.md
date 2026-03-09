# RDD Framework v1.0 用户可用性 Roadmap

> 目标：让用户能够一键安装并在 Claude Code 中使用 RDD Framework

---

## 当前状态评估

### ✅ 已完成

| 组件 | 状态 | 说明 |
|------|------|------|
| 框架核心代码 | ✅ | 16 脚本 + 8 Hooks |
| Skills 定义 | ✅ | 13 个 skills 已定义 |
| Commands 定义 | ✅ | 6 个 commands 已定义 |
| 文档体系 | ✅ | 用户指南 + 运维手册 |
| 测试覆盖 | ✅ | 867 测试 100% 通过 |
| CI/CD 模板 | ✅ | GitHub Actions + GitLab CI |
| 示例项目 | ✅ | simple-project + multi-stage |

### ❌ 用户可用性缺口

| 缺口 | 影响 | 优先级 |
|------|------|--------|
| **无安装方法** | 用户无法获取框架 | P0 |
| **Skills 不可用** | Claude Code 无法调用 skills | P0 |
| **无初始化命令** | 用户无法快速开始新项目 | P1 |
| **文档无安装指引** | README 缺少安装步骤 | P1 |
| **无版本发布** | 无发布包/版本标签 | P1 |
| **无 npm/homebrew** | 非标准安装渠道 | P2 |

---

## Roadmap

### Stage 8: 用户安装体验 (v1.0.1)

**目标**: 让用户能够安装和使用 RDD Framework

**预计工期**: 2-3 天

**验收标准**:
- [ ] 一键安装脚本可用
- [ ] `rdd init` 命令在任意项目可用
- [ ] Skills 在 Claude Code 中生效
- [ ] README 包含完整安装指引
- [ ] GitHub Release 发布

---

#### 任务分解

##### 8.1 安装脚本 (P0)

**目标**: 提供 `curl | sh` 一键安装

**交付物**:
```
scripts/install.sh          # 一键安装脚本
scripts/uninstall.sh        # 卸载脚本
scripts/upgrade.sh          # 升级脚本
```

**安装流程**:
```bash
# 用户执行
curl -fsSL https://raw.githubusercontent.com/xxx/rdd-framework/main/scripts/install.sh | sh

# 脚本执行:
# 1. 检测系统环境
# 2. 检查依赖 (bash, task, git)
# 3. 创建 ~/.rdd-framework 目录
# 4. 下载框架文件
# 5. 配置 PATH
# 6. 安装 skills 到 ~/.claude/skills/
# 7. 验证安装
```

**验收**:
- [ ] macOS 安装成功
- [ ] Linux 安装成功
- [ ] 安装后 `rdd --version` 可用
- [ ] 安装后 `task --list` 显示 RDD 任务

##### 8.2 全局 Skills 安装 (P0)

**目标**: Skills 在所有项目中可用

**Claude Code Skills 机制**:
- Claude Code 读取 `~/.claude/skills/*.md` 作为全局 skills
- 读取 `.claude/skills/*.md` 作为项目 skills
- Commands 同理

**交付物**:
```
~/.claude/skills/
├── rdd-init.md
├── rdd-migrate.md
├── rdd-roadmap.md
├── rdd-stage-auto.md
├── rdd-knowledge.md
├── rdd-loop.md
├── rdd-review-auto.md
├── rdd-recovery.md
├── rdd-diagnosis.md
├── rdd-fresh-check.md
├── rdd-hooks.md
├── rdd-core.md
└── rdd-templates.md

~/.claude/commands/
├── rdd-init.md
├── rdd-migrate.md
├── rdd-roadmap.md
├── rdd-stage-auto.md
├── rdd-knowledge.md
└── rdd-loop.md
```

**验收**:
- [ ] `/rdd-init` 在任意项目可用
- [ ] `/rdd-stage-auto` 在 RDD 项目可用
- [ ] Skills 说明在 Claude Code 中正确显示

##### 8.3 项目初始化命令 (P1)

**目标**: `rdd init` 创建新 RDD 项目

**命令设计**:
```bash
# 在当前目录初始化
rdd init

# 创建新项目
rdd init my-project

# 从模板创建
rdd init --template multi-stage
```

**初始化内容**:
```
my-project/
├── .rdd/
│   ├── config.yml
│   ├── hooks.yml
│   ├── templates.yml
│   ├── cache/
│   ├── scripts/ -> ~/.rdd-framework/scripts (symlink)
│   └── hooks/ -> ~/.rdd-framework/hooks (symlink)
├── docs/
│   ├── stages/
│   ├── 01-charter.md
│   ├── 02-engineering-principles.md
│   ├── ...
├── tests/
│   ├── unit/
│   ├── bdd/
│   └── e2e/
├── .claude/
│   └── skills/ (可选项目特定 skills)
├── AGENTS.md
├── CLAUDE.md
├── Taskfile.yml -> ~/.rdd-framework/Taskfile.yml (symlink)
└── CHANGELOG.md
```

**验收**:
- [ ] `rdd init` 创建完整目录结构
- [ ] `task doctor` 通过
- [ ] Claude Code 可读取 CLAUDE.md

##### 8.4 README 安装指引 (P1)

**目标**: 用户能按文档完成安装

**新增内容**:
```markdown
## Installation

### Quick Start

\`\`\`bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/xxx/rdd-framework/main/scripts/install.sh | sh

# Verify installation
rdd --version

# Initialize a new project
rdd init my-project
cd my-project

# Start using with Claude Code
# Just open Claude Code in the project directory
\`\`\`

### Requirements

- Bash 4.0+
- Task (go-task) 3.0+
- Git 2.0+
- Claude Code (optional, for AI-assisted development)

### Manual Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/xxx/rdd-framework.git
cd rdd-framework

# Install globally
./scripts/install.sh

# Or use locally
export RDD_FRAMEWORK_HOME=$(pwd)
\`\`\`

### Using with Claude Code

After installation, RDD skills are automatically available in Claude Code:

- `/rdd-init` - Initialize a new RDD project
- `/rdd-migrate` - Migrate existing project
- `/rdd-stage-auto` - Execute stage with gates
- `/rdd-knowledge` - Manage ADRs and tech debt
- `/rdd-loop` - Control autonomous execution
```

**验收**:
- [ ] README 包含安装步骤
- [ ] README 包含快速开始
- [ ] README 包含 Claude Code 使用说明

##### 8.5 GitHub Release (P1)

**目标**: 正式发布 v1.0.0

**发布内容**:
- Git tag v1.0.0
- GitHub Release 说明
- 发布资产 (tar.gz, zip)
- CHANGELOG 更新

**验收**:
- [ ] v1.0.0 tag 创建
- [ ] GitHub Release 发布
- [ ] 下载链接可用
- [ ] 安装脚本指向稳定版本

---

### Stage 9: 包管理器支持 (v1.1.0)

**目标**: 提供标准包管理器安装方式

**预计工期**: 3-5 天

**验收标准**:
- [ ] npm 包发布 (@kofj/rdd)
- [ ] Homebrew formula 提交
- [ ] AUR package (Arch Linux)

---

#### 任务分解

##### 9.1 npm 包 (P1)

**目标**: `npm install -g @kofj/rdd`

**package.json 设计**:
```json
{
  "name": "@kofj/rdd",
  "version": "1.0.0",
  "description": "Roadmap Driven Development Framework for AI Agents",
  "bin": {
    "rdd": "./bin/rdd"
  },
  "files": [
    "bin/",
    "scripts/",
    ".claude/",
    ".rdd/",
    "Taskfile.yml",
    "docs/"
  ],
  "scripts": {
    "postinstall": "node scripts/postinstall.js"
  },
  "keywords": ["ai", "agent", "development", "roadmap", "claude"],
  "license": "MIT"
}
```

**验收**:
- [ ] `npm install -g @kofj/rdd` 成功
- [ ] `rdd --version` 显示版本
- [ ] Skills 正确安装到 ~/.claude/

##### 9.2 Homebrew Formula (P2)

**目标**: `brew install rdd-framework`

**Formula 设计**:
```ruby
class RddFramework < Formula
  desc "Roadmap Driven Development Framework for AI Agents"
  homepage "https://github.com/xxx/rdd-framework"
  url "https://github.com/xxx/rdd-framework/archive/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "go-task" => :recommended

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/rdd"

    # Install Claude Code skills
    (ENV["HOME"]/".claude/skills").mkpath
    (libexec/".claude/skills").children.each do |skill|
      ln_s skill, ENV["HOME"]/".claude/skills"/skill.basename
    end
  end
end
```

**验收**:
- [ ] `brew install xxx/rdd/rdd-framework` 成功
- [ ] Homebrew tap 创建

##### 9.3 项目迁移命令 (P2)

**目标**: `rdd migrate` 将现有项目转为 RDD 项目

**命令设计**:
```bash
# 检测现有项目类型并迁移
rdd migrate

# 指定项目类型
rdd migrate --type node
rdd migrate --type python
rdd migrate --type go
```

**验收**:
- [ ] 检测项目类型
- [ ] 创建 RDD 目录结构
- [ ] 保留现有代码
- [ ] 生成初始 Roadmap

---

### Stage 10: 开发者体验优化 (v1.2.0)

**目标**: 提升开发者使用体验

**预计工期**: 2-3 天

**验收标准**:
- [ ] 交互式初始化向导
- [ ] VS Code 扩展基础功能
- [ ] 在线文档站点

---

#### 任务分解

##### 10.1 交互式初始化向导 (P2)

**目标**: 引导用户完成项目配置

**设计**:
```bash
$ rdd init --interactive

? What is your project name? (my-project)
? What is your project description?
? Which notification channels do you want to enable?
  ◉ WeChat (WeCom)
  ◯ Email
  ◯ Telegram
  ◯ Slack
? Do you want to create initial stages? (Y/n)
? How many stages do you plan? (3-5)
? What is your development approach?
  ◉ Test-Driven Development
  ◯ Behavior-Driven Development
  ◯ Documentation-Driven Development

✅ Project initialized successfully!

Next steps:
1. cd my-project
2. Open Claude Code in this directory
3. Run /rdd-roadmap to plan your stages
```

##### 10.2 VS Code 扩展 (P3)

**目标**: 提供 RDD 相关的 VS Code 集成

**功能**:
- Stage 文档 snippets
- Gate 检查快捷命令
- Roadmap 可视化
- ADR 记录快捷键

##### 10.3 在线文档站点 (P2)

**目标**: 提供可搜索的在线文档

**技术选择**:
- VitePress 或 Docusaurus
- GitHub Pages 部署

**内容**:
- 快速开始
- 概念指南
- API 参考
- 最佳实践
- FAQ

---

## 时间线

```
Week 1 (2026-03-10 ~ 2026-03-16):
├── Stage 8.1: 安装脚本
├── Stage 8.2: 全局 Skills 安装
└── Stage 8.3: 项目初始化命令

Week 2 (2026-03-17 ~ 2026-03-23):
├── Stage 8.4: README 更新
├── Stage 8.5: GitHub Release
└── v1.0.1 发布

Week 3-4 (2026-03-24 ~ 2026-04-06):
├── Stage 9.1: npm 包
├── Stage 9.2: Homebrew
└── v1.1.0 发布

Week 5-6 (2026-04-07 ~ 2026-04-20):
├── Stage 10.1: 交互式向导
├── Stage 10.3: 文档站点
└── v1.2.0 发布
```

---

## 发布计划

### v1.0.1 (2026-03-17)

**主题**: 用户安装体验

**内容**:
- 一键安装脚本
- 全局 Skills 安装
- 项目初始化命令
- README 安装指引
- GitHub Release

### v1.1.0 (2026-04-07)

**主题**: 包管理器支持

**内容**:
- npm 全局包
- Homebrew formula
- 项目迁移命令

### v1.2.0 (2026-04-21)

**主题**: 开发者体验

**内容**:
- 交互式初始化向导
- 在线文档站点

---

## 资源需求

### 人力

- 开发: 1 人 (主要工作)
- 文档: 0.5 人 (文档优化)
- 测试: 0.5 人 (多环境测试)

### 基础设施

- GitHub Repository (已有)
- npm Registry (免费)
- Homebrew Tap (免费)
- GitHub Pages (免费)

---

## 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Skills 路径问题 | 中 | 高 | 测试多种环境，提供手动配置方法 |
| 跨平台兼容性 | 中 | 中 | 支持 macOS/Linux，Windows WSL |
| npm 发布权限 | 低 | 中 | 提前申请 npm org 权限 |
| Homebrew 审核 | 低 | 低 | 准备详细文档，响应审核意见 |

---

## 成功指标

### v1.0.1 发布后

- 用户能在 5 分钟内完成安装
- `rdd init` 成功率 > 95%
- `/rdd-init` skill 调用成功率 > 95%

### v1.1.0 发布后

- npm 周下载量 > 100
- Homebrew 安装成功率 > 90%
- GitHub Stars 增长 > 20%

### v1.2.0 发布后

- 文档站点日访问 > 50
- 用户反馈响应时间 < 24h
- 社区贡献 > 5 PRs

---

## 待确认事项

请审核以下关键决策:

1. **安装方式优先级**:
   - [ ] curl | sh 优先 (推荐)
   - [ ] npm 优先
   - [ ] Homebrew 优先

2. **Skills 分发策略**:
   - [ ] 安装时复制到 ~/.claude/skills/
   - [ ] 创建符号链接
   - [ ] 运行时动态加载

3. **发布渠道**:
   - [ ] 仅 GitHub Release
   - [ ] GitHub + npm
   - [ ] GitHub + npm + Homebrew

4. **版本号策略**:
   - [ ] 从 v1.0.1 开始
   - [ ] 从 v1.1.0 开始
   - [ ] 直接发布 v1.0.0

5. **项目命名**:
   - [ ] rdd-framework
   - [ ] rdd (简短)
   - [ ] @kofj/rdd

---

> **下一步**: 请确认以上决策，我将开始实施 Stage 8。
