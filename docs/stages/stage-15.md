# Stage 15: 代码提交与发布准备

## Status
- [x] Planning
- [ ] In Progress
- [ ] Complete

## Goals
将代码提交到 GitHub，为 v1.0.0 发布做准备。

## Non-Goals
- npm 发布 (Stage 17)
- 文档站点部署 (Stage 18)

## Core Hypotheses
- H1: 所有 E2E 测试已通过
- H2: 代码质量达到发布标准
- H3: 文档已更新到最新状态

## Acceptance Criteria

### 代码提交 (15.1)
- [ ] 检查所有文件状态
- [ ] 暂存所有更改
- [ ] 创建提交信息
- [ ] 提交更改

### Git Remote 配置 (15.2)
- [ ] 配置 GitHub remote
- [ ] 验证 remote 可访问
- [ ] 验证推送权限

### Tag 创建 (15.3)
- [ ] 创建 v1.0.0 tag
- [ ] 验证 tag 正确
- [ ] 推送 tag

### 发布前检查 (15.4)
- [ ] 所有测试通过
- [ ] CHANGELOG.md 更新
- [ ] 版本号正确
- [ ] README.md 更新

## Rollback Plan
- Git 提交可 revert
- Tag 可删除重建
- 发布前可取消

## Known Limitations
- 需要 GitHub 仓库权限
- 需要 main 分支写权限

## Impact on Subsequent Stages
- Stage 16 依赖代码已推送
- Stage 17 依赖 GitHub Release

---

## Implementation Notes

### 提交检查清单

```bash
# 1. 检查状态
git status

# 2. 检查测试
task test

# 3. 检查文档
task doctor

# 4. 暂存更改
git add .

# 5. 创建提交
git commit -m "feat: Complete Stage 11-14, E2E testing ready

- Add E2E testing framework (Stage 11)
- Add installation flow tests (Stage 12)
- Add Claude Code integration tests (Stage 13)
- Add full workflow tests (Stage 14)
- Update documentation

Tests: 867/867 passing
"

# 6. 创建 tag
git tag -a v1.0.0 -m "RDD Framework v1.0.0

Features:
- Stage-based development with 5-layer gates
- 13 Claude Code skills
- 6 CLI commands
- Multi-channel notifications
- 867 tests with 100% pass rate

Installation:
- curl | sh
- npm install -g @kofj/rdd
- Homebrew
"

# 7. 推送
git push origin main --tags
```

### 发布前检查

```bash
#!/bin/bash
# scripts/release/pre-release-check.sh

echo "=== RDD Framework v1.0.0 Pre-Release Check ==="

echo "1. Checking tests..."
task test || exit 1

echo "2. Checking doctor..."
task doctor || exit 1

echo "3. Checking version..."
grep -q '"version": "1.0.0"' package.json || exit 1
grep -q 'version-1.0.0' README.md || exit 1

echo "4. Checking CHANGELOG..."
grep -q "## \[1.0.0\]" CHANGELOG.md || exit 1

echo "5. Checking documentation..."
[ -f docs/stages/stage-11.md ] || exit 1
[ -f docs/stages/stage-12.md ] || exit 1
[ -f docs/stages/stage-13.md ] || exit 1
[ -f docs/stages/stage-14.md ] || exit 1

echo "All checks passed!"
```

---

## Verification

### Gate 1: Design Document Check
- [x] Design document complete
- [x] Goals clearly defined
- [x] Acceptance criteria testable

### Gate 2: Design Review Check
- [ ] 代码审查完成
- [ ] 无敏感信息

### Gate 3: Implementation Check
- [ ] 所有测试通过
- [ ] 提交完成
- [ ] Tag 创建

### Gate 4: Code Review Check
- [ ] 提交信息规范
- [ ] 无遗漏文件

### Gate 5: Completion Gate Check
- [ ] 代码已推送
- [ ] Stage 16 可开始