# Stage 8: 用户安装体验

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
让用户能够一键安装 RDD Framework 并在 Claude Code 中使用，实现完整的用户可用性。

## Non-Goals
- npm 包发布（Stage 9）
- Homebrew 支持（Stage 9）
- VS Code 扩展（Stage 10）
- 交互式向导（Stage 10）

## Core Hypotheses
- H1: 用户可以通过 curl | sh 在 5 分钟内完成安装
- H2: Skills 安装后 Claude Code 可以自动识别
- H3: `rdd init` 可以创建完整的项目结构
- H4: 用户无需阅读长文档即可开始使用

## Acceptance Criteria

### 安装脚本 (8.1) ✅
- [x] install.sh 支持 macOS 和 Linux
- [x] 检测依赖 (bash, task, git)
- [x] 创建 ~/.rdd-framework 目录
- [x] 下载框架文件
- [x] 配置 PATH
- [x] 安装 skills 到 ~/.claude/skills/
- [x] 验证安装成功
- [x] uninstall.sh 可完全卸载
- [x] upgrade.sh 可升级版本

### Skills 全局安装 (8.2) ✅
- [x] 13 个 skills 复制到 ~/.claude/skills/
- [x] 6 个 commands 复制到 ~/.claude/commands/
- [x] Claude Code 可识别 skills
- [x] /rdd-init 在任意项目可用
- [x] /rdd-stage-auto 在 RDD 项目可用

### 项目初始化命令 (8.3) ✅
- [x] `rdd init` 在当前目录创建项目
- [x] `rdd init <name>` 创建命名项目
- [x] 创建完整目录结构
- [x] 创建配置文件
- [x] 创建文档模板
- [x] 创建 Taskfile.yml
- [x] 符号链接到全局脚本
- [x] `task doctor` 通过

### README 更新 (8.4) ✅
- [x] 安装步骤完整
- [x] 快速开始指南
- [x] Claude Code 使用说明
- [x] 命令参考
- [x] 故障排查

### GitHub Release (8.5) ✅
- [x] v1.0.0 tag 创建
- [x] Release notes 编写
- [x] 发布资产打包 (tar.gz, zip)
- [x] 安装脚本指向稳定版本

## Rollback Plan
- 安装脚本支持 --uninstall 参数
- 版本回退：`rdd upgrade --version <version>`
- 项目独立，不影响已有项目

## Known Limitations
- Windows 原生不支持，需使用 WSL
- 需要网络连接下载文件
- 首次安装需要手动配置通知渠道

## Impact on Subsequent Stages
- Stage 9 基于安装脚本构建 npm 包
- Stage 10 可扩展交互式向导
- 为后续版本提供分发基础

---

## Implementation Notes

### 安装脚本架构

```
scripts/
├── install.sh          # 主安装脚本
├── uninstall.sh        # 卸载脚本
├── upgrade.sh          # 升级脚本
├── common.sh           # 共享函数
└── templates/
    └── Taskfile.yml    # 项目 Taskfile 模板
```

### 安装流程

```
1. 环境检查
   ├── 检测操作系统
   ├── 检测依赖 (bash, task, git)
   └── 提示缺少依赖

2. 准备安装
   ├── 创建 ~/.rdd-framework
   ├── 创建 ~/.claude/skills
   └── 创建 ~/.claude/commands

3. 下载文件
   ├── 下载核心脚本
   ├── 下载 skills
   ├── 下载 commands
   └── 下载文档模板

4. 配置环境
   ├── 添加到 PATH
   ├── 配置 RDD_FRAMEWORK_HOME
   └── 验证安装

5. 完成
   ├── 显示成功信息
   └── 显示下一步指引
```

### rdd 命令架构

```
~/.rdd-framework/
├── bin/
│   └── rdd            # 主命令入口
├── lib/
│   ├── init.sh        # init 子命令
│   ├── migrate.sh     # migrate 子命令
│   ├── stage.sh       # stage 子命令
│   ├── knowledge.sh   # knowledge 子命令
│   └── common.sh      # 共享函数
├── scripts/           # 从项目复制
├── hooks/             # 从项目复制
├── templates/         # 项目模板
│   ├── docs/
│   ├── .rdd/
│   └── Taskfile.yml
└── VERSION
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
- [x] Install script tested on macOS
- [x] Install script tested on Linux
- [x] Skills loading verified
- [x] `rdd init` creates valid project
- [x] `task doctor` passes

### Gate 4: Code Review Check
- [x] Triangulation complete
- [x] All blocking findings resolved
- [x] All acceptance criteria met

### Gate 5: Completion Gate Check
- [x] Main hypotheses verified
- [x] Tests reproducible
- [x] Documentation complete
- [x] fresh-agent-check passed
- [x] CHANGELOG updated
