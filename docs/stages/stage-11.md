# Stage 11: E2E 测试框架准备

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
准备 E2E 测试所需的基础设施，包括 Docker 测试环境、Claude Code 安装和第三方模型 API 配置。

## Non-Goals
- 实际执行安装测试 (Stage 12)
- Claude Code 集成测试 (Stage 13)
- GitHub 发布 (Stage 15+)

## Core Hypotheses
- H1: Docker 容器可以模拟干净的用户环境
- H2: Claude Code 可以在容器中正常运行
- H3: 第三方模型 API 可以在容器中访问
- H4: RDD Skills 可以被 Claude Code 识别

## Acceptance Criteria

### Docker 测试镜像 (11.1) ✅
- [x] 创建 `tests/e2e/Dockerfile.claude`
- [x] 基于 Ubuntu 22.04 镜像
- [x] 安装必要依赖 (bash, curl, git, node, task)
- [x] 安装 Claude Code CLI
- [x] 配置环境变量
- [x] 镜像构建成功

### Claude Code 安装 (11.2) ✅
- [x] Claude Code CLI 可执行
- [x] 版本验证通过
- [x] 配置目录创建 (~/.claude/)
- [x] settings.json 配置正确

### 第三方模型配置 (11.3) ✅
- [x] API 端点配置 (使用环境变量)
- [x] 模型名称配置
- [x] API 连接测试通过
- [x] 不在文件中硬编码敏感信息

### 测试项目模板 (11.4) ✅
- [x] 创建最小化测试项目
- [x] 包含基本 RDD 结构
- [x] 可用于后续测试

### 测试脚本 (11.5) ✅
- [x] `tests/e2e/setup-test-env.sh` - 环境配置
- [x] `tests/e2e/run-tests.sh` - 测试运行
- [x] `tests/e2e/test_helper.bash` - 测试辅助函数

## Rollback Plan
- Docker 镜像可删除重建
- 测试脚本独立，不影响主代码

## Known Limitations
- Docker 容器无图形界面
- 需要网络访问第三方 API
- 部分交互式功能可能受限

## Impact on Subsequent Stages
- Stage 12 依赖测试环境
- Stage 13 依赖 Claude Code 安装
- Stage 14 依赖完整测试框架

---

## Implementation Notes

### Docker 镜像架构

```
tests/e2e/Dockerfile.claude
├── 基础镜像: ubuntu:22.04 或 alpine:3.19
├── 依赖安装
│   ├── bash, curl, git
│   ├── nodejs, npm
│   └── go-task
├── Claude Code 安装
│   └── npm install -g @anthropic-ai/claude-code
├── 环境配置
│   └── ~/.claude/settings.json
└── RDD 复制
    └── /app/
```

### 环境变量配置

敏感信息通过环境变量注入，不写入文件：

```bash
# 启动容器时传入
docker run -e ANTHROPIC_AUTH_TOKEN="${TOKEN}" \
           -e ANTHROPIC_BASE_URL="${API_URL}" \
           -e ANTHROPIC_MODEL="${MODEL}" \
           rdd-test:latest
```

### settings.json 模板

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "${ANTHROPIC_BASE_URL}",
    "ANTHROPIC_MODEL": "${ANTHROPIC_MODEL}"
  },
  "model": "${ANTHROPIC_MODEL}",
  "skipWebFetchPreflight": true
}
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
- [ ] Multi-model review triggered
- [ ] AI pre-filtering completed
- [ ] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [x] Docker 镜像构建成功
- [x] Claude Code 安装验证
- [x] API 连接测试通过
- [x] 测试项目创建成功
- [x] E2E 测试通过 (21/21)

### Gate 4: Code Review Check
- [x] 无敏感信息泄露
- [x] Dockerfile 最佳实践
- [x] 脚本可维护性

### Gate 5: Completion Gate Check
- [x] 测试环境就绪
- [x] 后续 Stage 可开始
- [x] 文档更新完成
