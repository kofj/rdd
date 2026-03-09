# Stage 9: 包管理器支持

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
提供标准包管理器安装方式，让用户可以通过 npm 或 Homebrew 安装 RDD Framework。

## Non-Goals
- Windows 包管理器 (chocolatey, scoop)
- VS Code 扩展 (Stage 10)
- 在线文档站点 (Stage 10)

## Core Hypotheses
- H1: npm 安装可覆盖 Node.js 开发者用户群
- H2: Homebrew 安装可覆盖 macOS 开发者用户群
- H3: 用户可以通过标准命令验证安装

## Acceptance Criteria

### npm 包 (9.1) ✅
- [x] package.json 配置正确
- [x] postinstall 脚本正确执行
- [x] `npm install -g @kofj/rdd` 成功
- [x] `rdd --version` 显示版本
- [x] `rdd init` 创建项目成功
- [x] Skills 正确安装到 ~/.claude/

### Homebrew Formula (9.2) ✅
- [x] Formula 文件创建
- [x] `brew tap` 可添加 tap
- [x] `brew install` 成功
- [x] 安装后命令可用

### 项目迁移命令 (9.3) ✅
- [x] `rdd migrate` 检测项目类型
- [x] 创建 RDD 目录结构
- [x] 保留现有代码
- [x] 生成初始 Roadmap

## Rollback Plan
- npm 包可撤回版本
- Homebrew tap 可删除
- 项目独立，不影响已有项目

## Known Limitations
- npm 需要 Node.js 14+
- Homebrew 仅支持 macOS/Linux
- 迁移命令仅支持常见项目类型

## Impact on Subsequent Stages
- Stage 10 可扩展交互式向导
- 提供多渠道安装选择

---

## Implementation Notes

### npm 包结构

```
rdd-framework/
├── package.json
├── bin/
│   └── rdd              # CLI 入口
├── scripts/
│   ├── install.sh       # curl 安装脚本
│   ├── uninstall.sh
│   ├── upgrade.sh
│   └── postinstall.js   # npm postinstall
├── .claude/
│   ├── skills/          # 复制到 ~/.claude/skills/
│   └── commands/        # 复制到 ~/.claude/commands/
├── .rdd/
│   ├── scripts/         # 核心脚本
│   └── hooks/           # Hook 脚本
├── docs/
│   └── templates/       # 文档模板
└── README.md
```

### Homebrew Formula

```ruby
class RddFramework < Formula
  desc "Roadmap Driven Development Framework for AI Agents"
  homepage "https://github.com/kofj/rdd"
  url "https://github.com/kofj/rdd/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"
  head "https://github.com/kofj/rdd.git", branch: "main"

  depends_on "go-task" => :recommended

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/rdd"

    # Install Claude Code skills
    (ENV["HOME"]+"/.claude/skills").mkpath
    (libexec/".claude/skills").children.each do |skill|
      ln_s skill, ENV["HOME"]+"/.claude/skills"/skill.basename
    end

    # Install Claude Code commands
    (ENV["HOME"]+"/.claude/commands").mkpath
    (libexec/".claude/commands").children.each do |command|
      ln_s command, ENV["HOME"]+"/.claude/commands"/command.basename
    end
  end

  test do
    assert_match "RDD Framework", shell_output("#{bin}/rdd --version")
  end
end
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
- [x] npm pack 成功
- [x] npm install 测试通过
- [x] Homebrew formula 测试通过
- [x] rdd migrate 测试通过

### Gate 4: Code Review Check
- [x] Triangulation complete
- [x] All blocking findings resolved
- [x] All acceptance criteria met

### Gate 5: Completion Gate Check
- [x] Main hypotheses verified
- [x] Tests reproducible
- [x] Documentation complete
- [x] CHANGELOG updated
