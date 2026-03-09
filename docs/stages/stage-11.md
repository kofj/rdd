# Stage 11: E2E 测试框架准备

## Status
- [x] Planning
- [ ] In Progress
- [ ] Complete

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

### Docker 测试镜像 (11.1)
- [ ] 创建 `tests/e2e/Dockerfile.claude`
- [ ] 基于 Ubuntu/Alpine 镜像
- [ ] 安装必要依赖 (bash, curl, git, node, task)
- [ ] 安装 Claude Code CLI
- [ ] 配置环境变量
- [ ] 镜像构建成功

### Claude Code 安装 (11.2)
- [ ] Claude Code CLI 可执行
- [ ] 版本验证通过
- [ ] 配置目录创建 (~/.claude/)
- [ ] settings.json 配置正确

### 第三方模型配置 (11.3)
- [ ] API 端点配置 (使用环境变量)
- [ ] 模型名称配置
- [ ] API 连接测试通过
- [ ] 不在文件中硬编码敏感信息

### 测试项目模板 (11.4)
- [ ] 创建最小化测试项目
- [ ] 包含基本 RDD 结构
- [ ] 可用于后续测试

### 测试脚本 (11.5)
- [ ] `tests/e2e/setup-test-env.sh` - 环境配置
- [ ] `tests/e2e/run-tests.sh` - 测试运行
- [ ] `tests/e2e/cleanup.sh` - 清理脚本

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
- [ ] Docker 镜像构建成功
- [ ] Claude Code 安装验证
- [ ] API 连接测试通过
- [ ] 测试项目创建成功

### Gate 4: Code Review Check
- [ ] 无敏感信息泄露
- [ ] Dockerfile 最佳实践
- [ ] 脚本可维护性

### Gate 5: Completion Gate Check
- [ ] 测试环境就绪
- [ ] 后续 Stage 可开始
- [ ] 文档更新完成
