# 发布指导 (Release Guide)

> RDD Framework 版本发布流程和用户更新方式。

---

## 版本号规则

遵循语义化版本 (SemVer): `MAJOR.MINOR.PATCH`

| 段 | 含义 | 示例 |
|----|------|------|
| MAJOR | 不兼容的 API 变更 | v2.0.0 |
| MINOR | 向后兼容的功能新增 | v1.2.0 |
| PATCH | 向后兼容的问题修复 | v1.2.1 |

版本信息存储在两处，需保持同步：

| 文件 | 用途 |
|------|------|
| `.rdd/VERSION` | 运行时版本检测 |
| `git tag vX.Y.Z` | GitHub Releases 触发 |

---

## 发布前检查清单

发布前必须全部通过：

- [ ] `task test:bdd` — BDD 测试 31/31 通过
- [ ] `task test:e2e` — E2E 测试 42/42 通过
- [ ] `task fmt:check` — 代码格式检查通过
- [ ] `task lint:check` — Lint 检查无 error（warning 可忽略）
- [ ] `task bootstrap:deps` — 依赖工具安装检查通过
- [ ] `task fresh-check` — 新 Agent 可接手检查通过
- [ ] `CHANGELOG.md` — 更新日志已补充
- [ ] `docs/11-next-steps.md` — 当前状态已更新
- [ ] `docs/stages/stage-roadmap.md` — Roadmap 状态已更新
- [ ] `.rdd/VERSION` — 版本号已更新

---

## 发布步骤

### 1. 确认所有检查通过

```bash
task test:bdd && task test:e2e && task fmt:check && task lint:check && task fresh-check
```

### 2. 更新版本号

```bash
# 编辑 .rdd/VERSION，修改 VERSION= 行
vim .rdd/VERSION

# 或使用 version.sh（如已实现）
bash .rdd/scripts/version.sh bump --type minor
```

### 3. 更新 CHANGELOG

在 `CHANGELOG.md` 顶部添加新版本条目：

```markdown
## [v1.2.0] — Stage 22 Complete (2026-07-10)

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Decisions
- ADR-22A: ...（6 个 ADR）

### Tests
- E2E: 42/42, BDD: 31/31, Unit: 828/848
```

### 4. 提交并打 Tag

```bash
git add .rdd/VERSION CHANGELOG.md
git commit -m "chore(release): bump version to vX.Y.Z

Release summary line.
Key changes listed.

Tests: E2E M/M, BDD N/N
Breaking: none"

git tag -a vX.Y.Z -m "vX.Y.Z: one-line summary

New:
- feature a
- feature b

Fixes:
- fix a

Tests: E2E M/M, BDD N/N
Breaking: none"
```

### 5. Push 代码和 Tag

```bash
git push origin main
git push origin vX.Y.Z
```

GitHub Release 会自动基于 tag 创建，安装脚本从 `https://github.com/kofj/rdd/archive/refs/tags/vX.Y.Z.tar.gz` 下载。

---

## 用户安装与更新

### 新用户安装

```bash
# 安装最新稳定版（默认）
curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh

# 安装指定版本
curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh -s -- --version v1.2.0
```

### 已安装用户更新

```bash
# 方式 1: 升级到最新版
curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh -s -- --upgrade

# 方式 2: 指定版本覆盖安装
curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh -s -- --version v1.2.0
```

### 查看当前版本

```bash
cat ~/.rdd-framework/.rdd/VERSION
# 或
rdd version
```

---

## 版本发布记录

| 版本 | 日期 | 主要内容 | Tag |
|------|------|----------|-----|
| v1.2.0 | 2026-07-10 | Stage 22: 多阶段自主迭代 | `v1.2.0` |
| v1.1.0 | 2026-03-13 | Stage 19-21: 命令提示/帮助/TDD | — |
| v1.0.0 | 2026-03-09 | Stage 0-18: 核心框架全流程打通 | `v1.0` |

---

## 紧急修复发布 (Hotfix)

当需要紧急修复时：

1. 从 `main` 分支创建 `hotfix/xxx` 分支
2. 修复并测试
3. 按正常流程提交、打 tag（PATCH 版本号 +1）
4. Push 并通知用户更新

---

## 回滚

如果发布有严重问题：

```bash
# 1. 删除有问题的 tag
git tag -d v1.2.0
git push origin :refs/tags/v1.2.0

# 2. 回滚 VERSION 文件到上一个版本
vim .rdd/VERSION  # VERSION=1.1.0

# 3. 提交回滚
git add .rdd/VERSION
git commit -m "revert: roll back to v1.1.0 due to [reason]"
git push origin main

# 4. 用户可以使用升级命令安装上一个稳定版
```

---

## 相关文件

| 文件 | 用途 |
|------|------|
| `scripts/install/install.sh` | 安装/升级脚本 |
| `scripts/install/upgrade.sh` | 独立升级脚本 |
| `.rdd/VERSION` | 运行时版本文件 |
| `CHANGELOG.md` | 变更日志 |
| `docs/11-next-steps.md` | 当前项目状态 |
