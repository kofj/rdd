# Contributing to RDD Framework

感谢你对 RDD Framework 的关注！本文档将帮助你了解如何为项目做出贡献。

## 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)

## 行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们承诺：

- 使用包容和友好的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性化的语言或图像
- 挑衅、侮辱/贬损评论以及人身或政治攻击
- 公开或私下骚扰
- 未经明确许可，发布他人的私人信息
- 其他在专业环境中可能被合理认为不适当的行为

## 如何贡献

### 报告 Bug

如果你发现了 bug，请通过 [GitHub Issues](../../issues) 提交报告。

**Bug 报告应包含：**

1. **标题**：简洁明了的描述
2. **环境**：
   - 操作系统
   - Shell 版本 (bash --version)
   - Task 版本 (task --version)
3. **复现步骤**：详细的复现步骤
4. **预期行为**：你期望发生什么
5. **实际行为**：实际发生了什么
6. **日志**：相关的错误日志或输出

### 建议新功能

欢迎提出新功能建议！请通过 [GitHub Issues](../../issues) 提交。

**功能建议应包含：**

1. **用例**：描述这个功能解决什么问题
2. **建议方案**：你认为应该如何实现
3. **替代方案**：你考虑过的其他方案
4. **附加信息**：任何其他相关信息

### 提交代码

请遵循 [Pull Request 流程](#pull-request-流程)。

## 开发流程

### 1. Fork 和 Clone

```bash
# Fork 后 clone 你的仓库
git clone https://github.com/YOUR_USERNAME/rdd-framework.git
cd rdd-framework

# 添加上游仓库
git remote add upstream https://github.com/ORIGINAL_REPO/rdd-framework.git
```

### 2. 创建分支

```bash
# 从 master 创建功能分支
git checkout -b feature/your-feature-name

# 或从 master 创建修复分支
git checkout -b fix/your-fix-name
```

### 3. 开发和测试

```bash
# 运行测试
task test

# 运行健康检查
task doctor

# 运行特定测试
task test:unit
task test:bdd
task test:e2e
```

### 4. 提交更改

```bash
git add .
git commit -m "feat: 添加新功能描述"
```

### 5. 推送和创建 PR

```bash
git push origin feature/your-feature-name
```

然后在 GitHub 上创建 Pull Request。

## 代码规范

### Shell 脚本规范

```bash
#!/usr/bin/env bash
# 脚本描述
#
# 用法: script.sh [参数]
#
# 参数:
#   $1 - 第一个参数描述
#
# 环境变量:
#   VAR_NAME - 变量描述
#
# 返回值:
#   0 - 成功
#   1 - 失败

set -euo pipefail

# 常量
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# 日志函数
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# 主函数
main() {
    log_info "开始执行..."
    # 实现
}

main "$@"
```

### 命名规范

- **脚本文件**：小写，使用下划线分隔 (`my_script.sh`)
- **变量**：大写常量，小写局部变量
- **函数**：小写，使用下划线分隔 (`my_function()`)
- **环境变量**：大写，使用下划线 (`RDD_DIR`)

### 文档规范

- 使用 Markdown 格式
- 标题使用 ATX 风格 (`#`)
- 代码块指定语言
- 链接使用相对路径

## 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

### 格式

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### 类型 (type)

| 类型 | 描述 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响代码运行） |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `build` | 构建系统或依赖更新 |
| `ci` | CI 配置更新 |
| `chore` | 其他不修改 src 或 test 的更改 |

### 示例

```bash
# 新功能
git commit -m "feat(hooks): 添加新 hook 类型支持"

# Bug 修复
git commit -m "fix(notify): 修复环境变量展开问题"

# 文档更新
git commit -m "docs: 更新快速开始指南"

# 重大变更
git commit -m "feat(api)!: 修改 API 接口

BREAKING CHANGE: notify 函数签名已更改，需要更新调用代码"
```

## Pull Request 流程

### PR 检查清单

在提交 PR 前，请确保：

- [ ] 代码通过所有测试 (`task test`)
- [ ] 代码符合规范 (`task lint` 如果可用)
- [ ] 文档已更新
- [ ] CHANGELOG.md 已更新（如适用）
- [ ] 提交消息符合规范

### PR 标题格式

```
<type>(<scope>): <description>
```

例如：
- `feat(stage): 添加 Stage 8 支持`
- `fix(test): 修复测试用例失败问题`
- `docs: 添加 API 参考文档`

### PR 描述模板

```markdown
## 变更描述

简要描述这个 PR 的变更内容。

## 变更类型

- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 重构
- [ ] 其他

## 相关 Issue

Fixes #123

## 测试计划

- [ ] 单元测试通过
- [ ] E2E 测试通过
- [ ] 手动测试通过

## 截图（如适用）

## 附加信息

任何其他需要说明的信息。
```

### Review 流程

1. **自动检查**：CI 自动运行测试
2. **代码审查**：至少一位 maintainer 审查
3. **讨论**：讨论反馈和建议
4. **批准**：Maintainer 批准后合并
5. **合并**：Squash merge 到 master

## 获取帮助

- **GitHub Issues**：提交 bug 报告或功能建议
- **GitHub Discussions**：讨论问题和想法
- **Pull Request**：在 PR 中提问

## 许可证

通过贡献代码，你同意你的贡献将按照项目的许可证授权。

---

感谢你的贡献！
