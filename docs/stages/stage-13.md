# Stage 13: Claude Code 集成测试

## Status
- [x] Planning
- [ ] In Progress
- [ ] Complete

## Goals
验证 Claude Code 可识别并使用 RDD Skills，确保第三方模型 API 连接正常。

## Non-Goals
- 完整工作流测试 (Stage 14)
- 性能测试
- 多模型对比测试

## Core Hypotheses
- H1: Claude Code 可识别 ~/.claude/skills/ 下的 Skills
- H2: Claude Code 可识别 ~/.claude/commands/ 下的 Commands
- H3: 第三方模型 API 连接正常
- H4: Skills 自动补全功能正常

## Acceptance Criteria

### Skills 识别测试 (13.1)
- [ ] Claude Code 启动正常
- [ ] /rdd-init 被识别
- [ ] /rdd-migrate 被识别
- [ ] /rdd-stage-auto 被识别
- [ ] /rdd-knowledge 被识别
- [ ] /rdd-loop 被识别
- [ ] 所有 6 个 Commands 可见

### Skills 内容测试 (13.2)
- [ ] rdd-core.md 内容正确
- [ ] rdd-init.md 内容正确
- [ ] rdd-stage-auto.md 内容正确
- [ ] Skills 描述准确
- [ ] Skills 触发词正确

### API 连接测试 (13.3)
- [ ] API 端点可达
- [ ] 认证成功
- [ ] 模型响应正常
- [ ] 错误处理正确

### 自动补全测试 (13.4)
- [ ] 输入 /rdd 显示所有 RDD 命令
- [ ] 命令描述正确显示
- [ ] Tab 补全正常

### 错误处理测试 (13.5)
- [ ] 无效 API Token 错误提示
- [ ] 网络错误处理
- [ ] 模型不可用处理

## Rollback Plan
- 移除测试配置
- 恢复默认配置
- 清理测试环境

## Known Limitations
- Docker 容器内无交互式界面
- 部分交互功能需模拟测试
- API 调用可能产生费用

## Impact on Subsequent Stages
- Stage 14 需要正常工作的 Claude Code 环境

---

## Implementation Notes

### 测试策略

由于 Claude Code 是交互式 CLI，测试策略如下：

1. **配置文件验证**: 检查 settings.json 格式正确
2. **Skills 文件验证**: 检查所有 Skills 文件存在且格式正确
3. **API 连接验证**: 使用 curl 测试 API 端点
4. **功能模拟**: 使用 bats 模拟交互测试

### API 连接测试

```bash
# tests/e2e/claude-integration.bats

@test "INT-01: Skills 文件存在" {
    local skills=(
        "rdd-core"
        "rdd-init"
        "rdd-migrate"
        "rdd-roadmap"
        "rdd-stage-auto"
        "rdd-knowledge"
        "rdd-loop"
        "rdd-review-auto"
        "rdd-recovery"
        "rdd-diagnosis"
        "rdd-fresh-check"
        "rdd-hooks"
        "rdd-templates"
    )

    for skill in "${skills[@]}"; do
        [ -f ~/.claude/skills/${skill}.md ]
    done
}

@test "INT-02: Commands 文件存在" {
    local commands=(
        "rdd-init"
        "rdd-migrate"
        "rdd-roadmap"
        "rdd-stage-auto"
        "rdd-knowledge"
        "rdd-loop"
    )

    for cmd in "${commands[@]}"; do
        [ -f ~/.claude/commands/${cmd}.md ]
    done
}

@test "INT-03: API 端点可达" {
    # 使用环境变量中的配置
    local api_url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"

    # 测试 API 端点可达性 (不发送实际请求)
    run curl -s -o /dev/null -w "%{http_code}" "${api_url}/v1/models"
    # 可能返回 401 (未认证) 或 200，都表示端点可达
    [[ "$output" =~ ^(200|401|403)$ ]]
}

@test "INT-04: Skills 格式正确" {
    # 检查 Skills 文件包含必要的 markdown 格式
    for skill in ~/.claude/skills/rdd-*.md; do
        # 检查文件非空
        [ -s "$skill" ]
        # 检查包含 name 字段
        grep -q "^name:" "$skill" || grep -q "^# " "$skill"
    done
}
```

### 配置验证

```bash
@test "INT-05: settings.json 格式正确" {
    [ -f ~/.claude/settings.json ]

    # 验证 JSON 格式
    run jq '.' ~/.claude/settings.json
    [ "$status" -eq 0 ]

    # 验证必要字段存在
    run jq -e '.model' ~/.claude/settings.json
    [ "$status" -eq 0 ]
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
- [ ] 所有集成测试通过
- [ ] API 连接验证成功
- [ ] Skills/Commands 验证成功

### Gate 4: Code Review Check
- [ ] 无敏感信息泄露
- [ ] 测试代码质量

### Gate 5: Completion Gate Check
- [ ] Claude Code 集成验证完成
- [ ] Stage 14 可开始