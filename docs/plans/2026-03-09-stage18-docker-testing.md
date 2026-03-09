# Stage 18: Docker 测试环境 - 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建 Docker 测试环境，用于完整安装流程测试和 CI/CD 集成

**Architecture:** 基于 Debian/Ubuntu 构建测试镜像，包含 curl、git、bash 等必要工具，支持运行完整安装脚本和测试

**Tech Stack:** Docker, Bats, ShellCheck

---

## 前置条件

- 在 worktree `/data/works/play/sbd-stage18/` 中执行
- 分支: `stage-18-docker-testing`

---

### Task 1: 创建 Docker 目录结构

**Files:**
- Create: `docker/Dockerfile.test`
- Create: `docker/entrypoint.sh`
- Create: `docker/run-tests.sh`

**Step 1: 创建目录**

```bash
mkdir -p docker
```

**Step 2: 提交目录**

```bash
git add docker/
git commit -m "chore: create docker directory structure"
```

---

### Task 2: 创建测试 Dockerfile

**Files:**
- Create: `docker/Dockerfile.test`

**Step 1: 编写 Dockerfile**

```dockerfile
# RDD Framework Test Environment
#
# 用于测试安装脚本和完整工作流
#
# 构建命令:
#   docker build -f docker/Dockerfile.test -t rdd-test .
#
# 运行命令:
#   docker run --rm -v $(pwd):/workspace rdd-test

FROM debian:bookworm-slim

LABEL maintainer="RDD Framework"
LABEL description="RDD Framework Test Environment"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PROJECT_ROOT=/workspace
ENV RDD_FRAMEWORK_HOME=/workspace
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 安装基础依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    curl \
    wget \
    git \
    bash \
    bc \
    ca-certificates \
    # 测试框架
    bats \
    # 代码检查
    shellcheck \
    # 清理缓存
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 安装 go-task (用于运行 Taskfile)
RUN curl -sL https://taskfile.dev/install.sh | sh -s -- -d -b /usr/local/bin

# 创建工作目录
WORKDIR /workspace

# 设置入口脚本
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 默认运行所有测试
ENTRYPOINT ["/entrypoint.sh"]
CMD ["test"]
```

**Step 2: 提交**

```bash
git add docker/Dockerfile.test
git commit -m "feat(docker): add test environment Dockerfile"
```

---

### Task 3: 创建入口脚本

**Files:**
- Create: `docker/entrypoint.sh`

**Step 1: 编写 entrypoint.sh**

```bash
#!/usr/bin/env bash
#
# Docker 测试入口脚本
#
# 支持的命令:
#   test    - 运行所有测试
#   install - 运行安装测试
#   e2e     - 运行 E2E 测试
#   shell   - 进入交互式 shell
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "\n${BLUE}==>${NC} ${BOLD}$*${NC}"
}

# 运行单元测试
run_unit_tests() {
    log_step "Running unit tests..."

    cd "${PROJECT_ROOT}"

    if command -v task &> /dev/null; then
        task test-unit
    elif [ -d "tests/unit" ]; then
        bats tests/unit/
    else
        log_info "No unit tests found, skipping..."
    fi
}

# 运行 E2E 测试
run_e2e_tests() {
    log_step "Running E2E tests..."

    cd "${PROJECT_ROOT}"
    export PROJECT_ROOT
    export RDD_FRAMEWORK_HOME

    if [ -d "tests/e2e" ]; then
        bats tests/e2e/
    else
        log_info "No E2E tests found, skipping..."
    fi
}

# 运行安装测试
run_install_test() {
    log_step "Testing installation in clean environment..."

    # 创建隔离的测试目录
    local test_dir="/tmp/rdd-test-$$"
    mkdir -p "${test_dir}"

    # 设置测试环境
    export INSTALL_PREFIX="${test_dir}/.rdd-framework"
    export HOME="${test_dir}"
    export PATH="${INSTALL_PREFIX}/bin:${PATH}"

    # 运行安装脚本
    cd "${PROJECT_ROOT}"

    if bash scripts/install/install.sh; then
        log_info "Installation test passed!"

        # 验证安装
        if [ -x "${INSTALL_PREFIX}/bin/rdd" ]; then
            log_info "rdd command installed successfully"
            "${INSTALL_PREFIX}/bin/rdd" --version || true
        fi

        if command -v task &> /dev/null || [ -x "${INSTALL_PREFIX}/bin/task" ]; then
            log_info "go-task installed successfully"
        fi

        return 0
    else
        log_error "Installation test failed!"
        return 1
    fi
}

# 运行所有测试
run_all_tests() {
    log_step "Running all tests..."

    local failed=0

    # 运行单元测试
    run_unit_tests || ((failed++))

    # 运行 E2E 测试
    run_e2e_tests || ((failed++))

    # 运行安装测试
    run_install_test || ((failed++))

    # 汇总结果
    echo ""
    log_step "Test Results"
    if [ ${failed} -eq 0 ]; then
        log_info "All tests passed!"
        return 0
    else
        log_error "${failed} test suite(s) failed"
        return 1
    fi
}

# 主函数
main() {
    local command="${1:-test}"

    case "${command}" in
        test|all)
            run_all_tests
            ;;
        unit)
            run_unit_tests
            ;;
        e2e)
            run_e2e_tests
            ;;
        install)
            run_install_test
            ;;
        shell)
            exec /bin/bash
            ;;
        *)
            echo "Usage: $0 {test|unit|e2e|install|shell}"
            echo ""
            echo "Commands:"
            echo "  test    - Run all tests (default)"
            echo "  unit    - Run unit tests only"
            echo "  e2e     - Run E2E tests only"
            echo "  install - Run installation test only"
            echo "  shell   - Start interactive shell"
            exit 1
            ;;
    esac
}

main "$@"
```

**Step 2: 设置执行权限**

```bash
chmod +x docker/entrypoint.sh
```

**Step 3: 提交**

```bash
git add docker/entrypoint.sh
git commit -m "feat(docker): add test entrypoint script"
```

---

### Task 4: 创建运行脚本

**Files:**
- Create: `docker/run-tests.sh`

**Step 1: 编写 run-tests.sh**

```bash
#!/usr/bin/env bash
#
# Docker 测试运行脚本
#
# 用于本地和 CI 环境运行 Docker 测试
#
# Usage:
#   ./docker/run-tests.sh           # 运行所有测试
#   ./docker/run-tests.sh unit      # 只运行单元测试
#   ./docker/run-tests.sh e2e       # 只运行 E2E 测试
#   ./docker/run-tests.sh install   # 只运行安装测试
#   ./docker/run-tests.sh shell     # 进入容器 shell
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 配置
IMAGE_NAME="${IMAGE_NAME:-rdd-test}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-rdd-test-$$}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_step() {
    echo -e "${BLUE}==>${NC} $*"
}

# 构建 Docker 镜像
build_image() {
    log_step "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."

    docker build \
        -f "${PROJECT_ROOT}/docker/Dockerfile.test" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${PROJECT_ROOT}"

    log_info "Image built successfully"
}

# 运行容器
run_container() {
    local command="${1:-test}"

    log_step "Running tests in container..."

    docker run --rm \
        --name "${CONTAINER_NAME}" \
        -v "${PROJECT_ROOT}:/workspace:ro" \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${command}"
}

# 主函数
main() {
    local command="${1:-test}"

    # 检查 Docker 是否可用
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed"
        exit 1
    fi

    # 构建镜像
    build_image

    # 运行测试
    case "${command}" in
        build)
            # 只构建镜像
            log_info "Image built: ${IMAGE_NAME}:${IMAGE_TAG}"
            ;;
        shell)
            # 进入容器 shell
            docker run --rm -it \
                --name "${CONTAINER_NAME}" \
                -v "${PROJECT_ROOT}:/workspace" \
                "${IMAGE_NAME}:${IMAGE_TAG}" \
                shell
            ;;
        *)
            run_container "${command}"
            ;;
    esac
}

main "$@"
```

**Step 2: 设置执行权限**

```bash
chmod +x docker/run-tests.sh
```

**Step 3: 提交**

```bash
git add docker/run-tests.sh
git commit -m "feat(docker): add test runner script"
```

---

### Task 5: 更新 CI 集成

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: 添加 Docker 测试 Job**

在 `.github/workflows/ci.yml` 中添加：

```yaml
  docker-test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: |
          docker build -f docker/Dockerfile.test -t rdd-test .

      - name: Run tests in Docker
        run: |
          docker run --rm -v $(pwd):/workspace rdd-test test

      - name: Run installation test
        run: |
          docker run --rm -v $(pwd):/workspace rdd-test install
```

**Step 2: 提交**

```bash
git add .github/workflows/ci.yml
git commit -m "feat(ci): add Docker test job"
```

---

### Task 6: 更新文档

**Files:**
- Modify: `CHANGELOG.md`
- Create: `docs/docker-testing.md`

**Step 1: 创建 Docker 测试文档**

```markdown
# Docker 测试环境

## 快速开始

### 构建镜像

\`\`\`bash
./docker/run-tests.sh build
\`\`\`

### 运行测试

\`\`\`bash
# 运行所有测试
./docker/run-tests.sh

# 只运行单元测试
./docker/run-tests.sh unit

# 只运行 E2E 测试
./docker/run-tests.sh e2e

# 只运行安装测试
./docker/run-tests.sh install

# 进入容器 shell
./docker/run-tests.sh shell
\`\`\`

## 测试命令

| 命令 | 说明 |
|------|------|
| `test` / `all` | 运行所有测试 |
| `unit` | 只运行单元测试 |
| `e2e` | 只运行 E2E 测试 |
| `install` | 只运行安装测试 |
| `shell` | 进入交互式 shell |

## CI 集成

Docker 测试已集成到 GitHub Actions CI 工作流中，每次 PR 和 push 都会自动运行。

## 本地调试

\`\`\`bash
# 构建并进入 shell
./docker/run-tests.sh shell

# 在容器内手动测试
cd /workspace
bash scripts/install/install.sh
\`\`\`
```

**Step 2: 更新 CHANGELOG.md**

```markdown
## [Unreleased]

### Added
- Docker test environment for isolated testing
- `docker/run-tests.sh` script for local and CI testing
- Docker test job in CI workflow
```

**Step 3: 提交**

```bash
git add CHANGELOG.md docs/
git commit -m "docs: add Docker testing documentation"
```

---

### Task 7: 质量门禁检查

**Step 1: 验证 Dockerfile 语法**

```bash
# 如果有 dockerfilelint
dockerfilelint docker/Dockerfile.test

# 或使用 hadolint
docker run --rm -i hadolint/hadolint < docker/Dockerfile.test
```

Expected: No errors (or only warnings)

**Step 2: 构建镜像测试**

```bash
docker build -f docker/Dockerfile.test -t rdd-test .
```

Expected: Build succeeds

**Step 3: 运行测试**

```bash
docker run --rm -v $(pwd):/workspace rdd-test test
```

Expected: Tests pass (或预期的测试结果)

**Step 4: 推送分支**

```bash
git push origin stage-18-docker-testing
```

---

## 完成标准

- [ ] Dockerfile 构建成功
- [ ] 入口脚本可用
- [ ] 运行脚本可用
- [ ] CI 集成完成
- [ ] 文档已更新
- [ ] 本地 Docker 测试通过
- [ ] 分支已推送

---

## 注意事项

1. **Docker 镜像约 300MB**，首次构建需要时间
2. **CI 中使用 Docker** 会增加运行时间
3. **挂载为只读** (`:ro`) 避免污染源码

---

## 修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-09 | 初始计划 |
