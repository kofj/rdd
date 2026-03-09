# Stage 12: 安装流程 E2E 测试

## Status
- [x] Planning
- [ ] In Progress
- [ ] Complete

## Goals
验证完整安装流程在干净环境中可用，确保用户可以通过多种方式安装 RDD Framework。

## Non-Goals
- Claude Code 集成测试 (Stage 13)
- 完整工作流测试 (Stage 14)
- 性能测试

## Core Hypotheses
- H1: `curl | sh` 安装方式可在干净环境成功
- H2: Skills 和 Commands 正确安装到 ~/.claude/
- H3: `rdd init` 可创建完整项目结构
- H4: `rdd --version` 和 `task doctor` 正常工作

## Acceptance Criteria

### curl | sh 安装测试 (12.1)
- [ ] 从本地文件模拟 curl | sh 安装
- [ ] 检查 ~/.rdd-framework/ 目录创建
- [ ] 检查 PATH 配置正确
- [ ] 检查 rdd 命令可用
- [ ] 清理测试环境

### 手动安装测试 (12.2)
- [ ] 复制 skills 到 ~/.claude/skills/
- [ ] 复制 commands 到 ~/.claude/commands/
- [ ] 复制 scripts 到 ~/.rdd-framework/scripts/
- [ ] 检查文件权限正确
- [ ] 检查所有文件存在

### npm 安装测试 (12.3)
- [ ] 验证 package.json 正确
- [ ] 模拟 npm install -g 流程
- [ ] 检查 postinstall 脚本执行
- [ ] 检查 rdd 命令可用

### 命令功能测试 (12.4)
- [ ] `rdd --version` 显示版本
- [ ] `rdd --help` 显示帮助
- [ ] `rdd init <name>` 创建项目
- [ ] `rdd init` 在当前目录初始化
- [ ] `rdd doctor` 健康检查通过

### 项目结构验证 (12.5)
- [ ] 创建的项目包含 .rdd/ 目录
- [ ] 创建的项目包含 docs/ 目录
- [ ] 创建的项目包含 tests/ 目录
- [ ] 创建的项目包含 Taskfile.yml
- [ ] Taskfile 可执行

## Rollback Plan
- 每个测试独立运行
- 测试后清理环境
- Docker 容器可重建

## Known Limitations
- 测试不涉及真实网络下载
- npm publish 未执行，使用本地模拟

## Impact on Subsequent Stages
- Stage 13 需要安装成功的环境
- Stage 14 需要可用的项目

---

## Implementation Notes

### 测试用例设计

```bash
# tests/e2e/install-flow.bats

@test "INST-01: curl | sh 安装成功" {
    # 模拟 curl | sh 安装
    run bash scripts/install/install.sh --prefix /tmp/rdd-test
    [ "$status" -eq 0 ]
    [ -f "/tmp/rdd-test/bin/rdd" ]
}

@test "INST-02: 手动安装成功" {
    # 手动复制文件
    mkdir -p ~/.claude/{skills,commands}
    cp -r .claude/skills/* ~/.claude/skills/
    cp -r .claude/commands/* ~/.claude/commands/
    [ -f ~/.claude/skills/rdd-init.md ]
    [ -f ~/.claude/commands/rdd-init.md ]
}

@test "INST-03: rdd --version 正常" {
    run rdd --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.0.0" ]]
}

@test "INST-04: rdd init 创建项目" {
    run rdd init test-project
    [ "$status" -eq 0 ]
    [ -d "test-project/.rdd" ]
    [ -d "test-project/docs" ]
    [ -f "test-project/Taskfile.yml" ]
}

@test "INST-05: task doctor 通过" {
    cd test-project
    run task doctor
    [ "$status" -eq 0 ]
}
```

### 测试执行顺序

```
1. 环境准备
   └── docker build -t rdd-test tests/e2e/

2. 安装测试
   ├── INST-01: curl | sh
   ├── INST-02: 手动安装
   └── INST-03: npm 安装

3. 功能测试
   ├── INST-04: rdd --version
   ├── INST-05: rdd --help
   ├── INST-06: rdd init
   └── INST-07: task doctor

4. 清理
   └── docker rm / docker rmi
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
- [ ] 所有测试用例通过
- [ ] 测试覆盖率 >= 80%
- [ ] 无残留测试文件

### Gate 4: Code Review Check
- [ ] 测试代码质量
- [ ] 测试独立性
- [ ] 清理完整性

### Gate 5: Completion Gate Check
- [ ] 安装流程验证完成
- [ ] 文档更新
- [ ] Stage 13 可开始