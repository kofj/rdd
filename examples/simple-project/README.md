# Simple Project Example

这是一个简单的 RDD Framework 项目示例，展示最小配置和使用方式。

## 项目结构

```
simple-project/
├── .rdd/
│   ├── config/
│   │   └── config.yml       # 项目配置
│   ├── hooks/
│   │   └── stage-complete.sh # Stage 完成 Hook
│   ├── cache/               # 运行时缓存
│   └── scripts/             # 自定义脚本
├── docs/
│   └── stages/
│       └── stage-1.md       # Stage 文档
├── AGENTS.md                # Agent 入口
├── CLAUDE.md                # Claude Code 入口
└── Taskfile.yml             # Task 定义
```

## 快速开始

### 1. 初始化项目

```bash
# 复制示例到你的项目
cp -r examples/simple-project/* /path/to/your/project/

# 或使用 rdd-init skill
# 在 Claude Code 中: /rdd-init
```

### 2. 配置项目

编辑 `.rdd/config/config.yml`:

```yaml
project:
  name: my-project
  version: 1.0.0

hooks:
  enabled: true
  channels:
    - type: wecom
      webhook: ${WECOM_WEBHOOK_URL}
```

### 3. 定义 Stage

编辑 `docs/stages/stage-1.md`:

```markdown
# Stage 1: 项目初始化

## Goals
建立项目基础结构。

## Acceptance Criteria
- [ ] 目录结构创建完成
- [ ] 配置文件就位
- [ ] 测试通过
```

### 4. 运行

```bash
# 检查项目状态
task doctor

# 运行测试
task test

# 查看帮助
task --list
```

## 核心概念

### Hook 系统

Hook 在特定事件触发时执行：

```bash
# stage-complete.sh 在 Stage 完成时触发
#!/usr/bin/env bash
source "${SCRIPTS_DIR}/notify.sh"

send_notification "Stage completed" "success"
```

### 配置管理

使用环境变量保护敏感信息：

```yaml
# .rdd/config/config.yml
hooks:
  channels:
    - type: wecom
      webhook: ${WECOM_WEBHOOK_URL}  # 从环境变量读取
```

### Stage 工作流

```
1. 阅读 Stage 文档
   ↓
2. 实现需求
   ↓
3. 运行测试
   ↓
4. Gate 检查
   ↓
5. 触发 Hook
   ↓
6. 更新文档
```

## 常用命令

| 命令 | 描述 |
|------|------|
| `task doctor` | 项目健康检查 |
| `task test` | 运行所有测试 |
| `task status` | 查看项目状态 |
| `task rdd:health` | RDD 健康检查 |

## 下一步

- 查看 [多 Stage 项目示例](../multi-stage-project/)
- 阅读 [用户指南](../../docs/user-guide/quick-start.md)
- 了解 [Stage 工作流](../../docs/03-stage-based-development.md)
