# Phase 3: 发布与运维 - 设计文档

> 创建日期: 2026-03-09
> 状态: 设计中

---

## 背景

Phase 1-2 已完成核心开发和 E2E 测试，发现以下问题需要解决：

1. **ASCII Banner Bug**: 安装脚本显示 "RER" 而非 "RDD"
2. **go-task 安装**: 当前从 GitHub Releases 直接下载，建议改用官方脚本
3. **GitHub Release 自动化**: 需要自动发布 Release
4. **Docker 测试环境**: 需要完整安装测试容器化

---

## 设计目标

### Stage 16: 安装脚本修复
- 修复 ASCII Banner 显示 "RDD"
- go-task 安装改用官方脚本 `https://taskfile.dev/install.sh`
- 验证安装流程在干净环境可用

### Stage 17: GitHub Actions CI/CD
- 推送标签自动创建 GitHub Release
- 自动生成 Release Notes
- 上传构建产物（源码包、校验和）

### Stage 18: Docker 测试环境
- 基于 Claude Code devcontainer 构建测试镜像
- 完整安装流程测试
- 可用于 CI/CD 和本地测试

---

## 技术方案

### Stage 16: 安装脚本修复

#### Banner 修复
```
修复前 (显示 RER):
   ██████╗ ███████╗██████╗  ██████╗
   ██╔══██╗██╔════╝██╔══██╗██╔═══██╗
   ██████╔╝█████╗  ██████╔╝██║   ██║
   ██╔══██╗██╔══╝  ██╔══██╗██║   ██║
   ██║  ██║███████╗██║  ██║╚██████╔╝
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝

修复后 (显示 RDD):
   ██████╗ ███████╗██████╗  ██████╗
   ██╔══██╗██╔════╝██╔══██╗██╔═══██╗
   ██████╔╝█████╗  ██████╔╝██║   ██║
   ██╔══██╗██╔══╝  ██╔══██╗██║   ██║
   ██║  ██║███████╗██║  ██║╚██████╔╝
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝
```

#### go-task 安装改造
```bash
# 旧方案: 直接下载二进制
task_url="https://github.com/go-task/task/releases/download/..."

# 新方案: 使用官方安装脚本
install_task() {
    if command -v task &> /dev/null; then
        log_info "task already installed: $(task --version)"
        return 0
    fi

    log_step "Installing go-task..."

    local task_install_dir="${INSTALL_PREFIX}/bin"
    mkdir -p "${task_install_dir}"

    # 使用官方安装脚本
    curl -sL https://taskfile.dev/install.sh | sh -s -- -d -b "${task_install_dir}"

    if [[ -f "${task_install_dir}/task" ]]; then
        chmod +x "${task_install_dir}/task"
        log_info "go-task installed to ${task_install_dir}/task"
    else
        log_error "Failed to install go-task"
        return 1
    fi
}
```

### Stage 17: GitHub Actions CI/CD

#### 工作流文件
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate Release Notes
        id: notes
        run: |
          # 从 CHANGELOG.md 提取当前版本说明
          ...

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          body_path: RELEASE_NOTES.md
          generate_release_notes: true
          files: |
            dist/*
```

### Stage 18: Docker 测试环境

#### Dockerfile
```dockerfile
FROM node:20-bookworm

# 安装测试依赖
RUN apt-get update && apt-get install -y \
    curl git bash bc \
    && rm -rf /var/lib/apt/lists/*

# 安装 Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# 设置测试工作目录
WORKDIR /workspace

# 测试入口
COPY tests/docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

---

## 并行执行策略

### Git Worktree 布局
```
/data/works/play/sbd/           # main (主分支)
/data/works/play/sbd-stage16/   # stage-16-fix-install-script
/data/works/play/sbd-stage17/   # stage-17-github-actions
/data/works/play/sbd-stage18/   # stage-18-docker-testing
```

### Subagent 分工
| Agent | Stage | 任务 |
|-------|-------|------|
| Agent-1 | Stage 16 | 修复 Banner + go-task 安装脚本 |
| Agent-2 | Stage 17 | 创建 GitHub Actions 工作流 |
| Agent-3 | Stage 18 | 创建 Docker 测试环境 |

### 质量门禁
每个 Stage 完成后：
1. 单元测试通过
2. E2E 测试通过（如适用）
3. 代码审查
4. 合并到 main

### ADR 决策流程
遇到问题时：
1. 记录问题和可选方案
2. 选择方案并记录理由
3. 更新 `docs/08-autonomous-decisions.md`
4. 继续执行

---

## 验收标准

### Stage 16
- [ ] ASCII Banner 正确显示 "RDD"
- [ ] go-task 使用官方脚本安装
- [ ] 干净环境安装测试通过
- [ ] 现有单元测试通过
- [ ] E2E 安装测试通过

### Stage 17
- [ ] 推送标签触发 Release 工作流
- [ ] Release Notes 自动生成
- [ ] GitHub Release 创建成功

### Stage 18
- [ ] Docker 镜像构建成功
- [ ] 容器内安装测试通过
- [ ] CI 集成测试可运行

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| taskfile.dev 安装脚本不可用 | 安装失败 | 保留直接下载作为 fallback |
| GitHub Actions 权限问题 | Release 创建失败 | 使用 GITHUB_TOKEN，测试权限配置 |
| Docker 镜像体积过大 | CI 慢 | 使用多阶段构建，精简依赖 |

---

## 修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-09 | 初始设计文档 |
