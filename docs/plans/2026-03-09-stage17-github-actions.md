# Stage 17: GitHub Actions CI/CD - 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建 GitHub Actions 工作流，实现推送标签时自动创建 GitHub Release

**Architecture:** 使用 `softprops/action-gh-release` action，在推送 `v*.*.*` 标签时自动创建 Release 并生成 Release Notes

**Tech Stack:** GitHub Actions, softprops/action-gh-release@v2

---

## 前置条件

- 在 worktree `/data/works/play/sbd-stage17/` 中执行
- 分支: `stage-17-github-actions`

---

### Task 1: 创建 GitHub Actions 目录结构

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `.github/workflows/ci.yml` (可选：CI 测试工作流)

**Step 1: 创建目录**

```bash
mkdir -p .github/workflows
```

**Step 2: 提交目录**

```bash
git add .github/
git commit -m "chore: create GitHub Actions directory structure"
```

---

### Task 2: 创建 Release 工作流

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: 编写 release.yml**

```yaml
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
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Version: $VERSION"

      - name: Extract release notes
        id: notes
        run: |
          # 从 CHANGELOG.md 提取当前版本的 release notes
          VERSION=${{ steps.version.outputs.version }}

          # 移除 'v' 前缀
          VERSION_NUM="${VERSION#v}"

          # 提取版本说明（到下一个版本标题之前）
          sed -n "/^## \[$VERSION_NUM\]/,/^## \[/p" CHANGELOG.md | head -n -1 > RELEASE_NOTES.md

          # 如果没有找到，使用通用说明
          if [ ! -s RELEASE_NOTES.md ]; then
            echo "Release $VERSION" > RELEASE_NOTES.md
          fi

          cat RELEASE_NOTES.md

      - name: Create tarball
        run: |
          VERSION=${{ steps.version.outputs.version }}
          tar --exclude='.git' --exclude='node_modules' --exclude='.rdd/cache' \
              -czvf rdd-framework-${VERSION}.tar.gz .

          # 生成校验和
          sha256sum rdd-framework-${VERSION}.tar.gz > rdd-framework-${VERSION}.tar.gz.sha256

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          body_path: RELEASE_NOTES.md
          generate_release_notes: true
          draft: false
          prerelease: ${{ contains(steps.version.outputs.version, '-') }}
          files: |
            rdd-framework-*.tar.gz
            rdd-framework-*.tar.gz.sha256
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Summary
        run: |
          echo "### Release Created! :rocket:" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Version:** ${{ steps.version.outputs.version }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Release URL:** ${{ github.server_url }}/${{ github.repository }}/releases/tag/${{ steps.version.outputs.version }}" >> $GITHUB_STEP_SUMMARY
```

**Step 2: 验证 YAML 语法**

```bash
# 安装 yamllint 或使用 python
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))"
```

Expected: No errors

**Step 3: 提交**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): add GitHub Actions release workflow"
```

---

### Task 3: 创建 CI 工作流（可选但推荐）

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1: 编写 ci.yml**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check shell scripts
        run: |
          find . -name "*.sh" -exec bash -n {} \;

      - name: Check YAML files
        run: |
          python3 -c "import yaml; [yaml.safe_load(open(f)) for f in $(find . -name '*.yml' -o -name '*.yaml')]"

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Setup Bats
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          sudo ./install.sh /usr/local

      - name: Install Task
        run: |
          sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

      - name: Run tests
        run: |
          export PROJECT_ROOT=$(pwd)
          export RDD_FRAMEWORK_HOME=$(pwd)
          task test || bats tests/

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-results/
          retention-days: 7

  install-test:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Test install script syntax
        run: |
          bash -n scripts/install/install.sh

      - name: Test install in clean environment
        run: |
          # 创建隔离环境
          docker run --rm -v $(pwd):/workspace -w /workspace ubuntu:22.04 \
            bash -c "apt-get update && apt-get install -y curl git bash && \
                     ./scripts/install/install.sh --prefix /tmp/rdd-test --no-path"
```

**Step 2: 提交**

```bash
git add .github/workflows/ci.yml
git commit -m "feat(ci): add CI workflow for linting and testing"
```

---

### Task 4: 创建标签触发测试脚本

**Files:**
- Create: `scripts/release/create-release.sh`

**Step 1: 编写创建发布脚本**

```bash
#!/usr/bin/env bash
#
# 创建 GitHub Release 的辅助脚本
#
# Usage:
#   ./scripts/release/create-release.sh v1.0.0
#

set -euo pipefail

VERSION="${1:-}"

if [[ -z "${VERSION}" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

# 验证版本格式
if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "Error: Invalid version format. Expected: v1.0.0 or v1.0.0-beta.1"
    exit 1
fi

# 检查 CHANGELOG.md 是否有对应版本
VERSION_NUM="${VERSION#v}"
if ! grep -q "## \[${VERSION_NUM}\]" CHANGELOG.md; then
    echo "Warning: Version ${VERSION_NUM} not found in CHANGELOG.md"
    echo "Please update CHANGELOG.md first."
    exit 1
fi

echo "Creating release ${VERSION}..."
echo ""

# 创建标签
git tag -a "${VERSION}" -m "Release ${VERSION}"

# 推送标签
echo "Pushing tag to origin..."
git push origin "${VERSION}"

echo ""
echo "Done! GitHub Actions will create the release automatically."
echo "Check: https://github.com/\$(git remote get-url origin | sed 's/.*github.com[/:]//' | sed 's/.git$//')/actions"
```

**Step 2: 设置执行权限**

```bash
chmod +x scripts/release/create-release.sh
```

**Step 3: 提交**

```bash
mkdir -p scripts/release
git add scripts/release/
git commit -m "feat: add release helper script"
```

---

### Task 5: 更新文档

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `docs/11-next-steps.md`
- Create: `docs/release-process.md`

**Step 1: 创建发布流程文档**

```markdown
# 发布流程

## 自动发布

推送符合语义版本格式的标签会自动触发 GitHub Actions 创建 Release：

\`\`\`bash
# 创建并推送标签
./scripts/release/create-release.sh v1.0.0

# 或手动操作
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
\`\`\`

## 版本命名规范

- 正式版本: `v1.0.0`, `v1.1.0`, `v2.0.0`
- 预发布版本: `v1.0.0-beta.1`, `v1.0.0-rc.1`

## 发布前检查清单

1. [ ] 更新 CHANGELOG.md
2. [ ] 运行所有测试通过
3. [ ] 更新版本号（如有必要）
4. [ ] 创建标签并推送

## GitHub Actions 工作流

| 工作流 | 触发条件 | 说明 |
|--------|----------|------|
| `release.yml` | 推送 `v*.*.*` 标签 | 创建 GitHub Release |
| `ci.yml` | push 到 main/develop | 运行测试 |
```

**Step 2: 更新 CHANGELOG.md**

```markdown
## [Unreleased]

### Added
- GitHub Actions CI/CD workflow for automated releases
- Release helper script `scripts/release/create-release.sh`

### Changed
- Releases are now automatically created when version tags are pushed
```

**Step 3: 提交**

```bash
git add CHANGELOG.md docs/
git commit -m "docs: add release process documentation"
```

---

### Task 6: 质量门禁检查

**Step 1: 验证工作流语法**

```bash
# 验证 YAML 语法
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
```

Expected: No errors

**Step 2: 验证脚本语法**

```bash
bash -n scripts/release/create-release.sh
```

Expected: No errors

**Step 3: 运行现有测试**

```bash
cd /data/works/play/sbd-stage17
task test
```

Expected: All tests pass

**Step 4: 推送分支**

```bash
git push origin stage-17-github-actions
```

---

## 完成标准

- [ ] GitHub Actions 工作流文件创建
- [ ] Release 工作流语法正确
- [ ] CI 工作流语法正确（可选）
- [ ] 发布脚本可用
- [ ] 文档已更新
- [ ] 分支已推送

---

## 注意事项

1. **首次使用需要在 GitHub 仓库推送后才能触发**
2. **确保仓库已配置 GitHub Actions 权限**
3. **测试时使用预发布版本标签（如 v1.0.0-beta.1）**

---

## 修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-09 | 初始计划 |
