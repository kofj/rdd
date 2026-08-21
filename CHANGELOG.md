# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD workflow for automated releases
- Release helper script `scripts/release/create-release.sh`
- Docker test environment for isolated testing
- `docker/run-tests.sh` script for local and CI testing
- Docker test job in CI workflow

### Changed
- Releases are now automatically created when version tags are pushed
- ASCII Banner now correctly displays "RDD" instead of "RER"
- go-task installation now uses official taskfile.dev script with fallback
- RDD skills now support both slash (`/rdd-init`) and natural-language triggers
- Reference-only skills (`rdd-core`, `rdd-state`, `rdd-templates`, `rdd-hooks`) use
  `disable-model-invocation: true` to avoid spurious auto-triggering

### Fixed
- **Skills were never recognized by Claude Code**: skill files were installed as flat
  `~/.claude/skills/rdd-*.md` without YAML frontmatter, but Claude Code requires the
  directory format `<name>/SKILL.md` with a `description` field. All 17 skills are now
  converted to the correct format, so they load and can be triggered by natural language.
- All distributors (`postinstall.js`, `install.sh`, `upgrade.sh`, `uninstall.sh`) now
  deploy/remove skills in directory format and clean up legacy flat files on upgrade.

### Removed
- Duplicate `.claude/commands/rdd-*.md` slash commands — superseded by same-named skills
  (skills take precedence and already provide slash triggering).

## [1.0.0] - 2026-03-09

### Added

#### Installation & Distribution
- **One-line install**: `curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh`
- **npm package**: `npm install -g @kofj/rdd`
- **Homebrew formula**: `brew tap kofj/rdd && brew install rdd`
- **CLI command**: `rdd init`, `rdd migrate`, `rdd stage`, `rdd knowledge`
- **Upgrade/Uninstall**: `rdd upgrade`, `rdd uninstall`
- **Example projects**: simple-project, multi-stage-project

#### Core Framework
- **Stage-Based Development**: Implemented 5-layer gate check workflow
- **Hook System**: 8 hook types for proactive notifications
  - stage-complete, roadmap-change, consecutive-failure
  - hypothesis-invalid, model-disagreement, tech-debt-threshold
  - daily-report, weekly-report
- **Notification System**: Multi-channel support
  - WeChat (WeCom) webhook
  - Email (SMTP)
  - iOS Bark
  - Telegram
  - Generic webhook
- **Testing**: 867 test cases with 100% pass rate

#### Scripts and Tools (16 Core Scripts)
- notify.sh: Notification dispatcher
- checkpoint.sh: State persistence
- handoff.sh: Context transfer
- backup.sh / restore.sh: Data backup/restore
- health.sh: Health checks
- benchmark.sh: Performance benchmarking
- version.sh: Semantic versioning
- compat.sh: Compatibility checking
- migrate.sh: Version migration
- metrics.sh: Monitoring metrics
- audit.sh: Audit logging
- retry.sh: Retry logic
- circuit_breaker.sh: Circuit breaker pattern
- security-check.sh: Security validation
- install.sh, uninstall.sh, upgrade.sh: Installation scripts

#### Claude Code Integration
- **13 Skills**: Complete RDD workflow skills
  - rdd-init, rdd-migrate, rdd-roadmap, rdd-stage-auto
  - rdd-knowledge, rdd-loop, rdd-review-auto, rdd-recovery
  - rdd-diagnosis, rdd-fresh-check, rdd-hooks
  - rdd-core, rdd-templates
- **6 Commands**: Quick command access
  - /rdd-init, /rdd-migrate, /rdd-roadmap
  - /rdd-stage-auto, /rdd-knowledge, /rdd-loop

#### Security Features
- **Permission Model**: RBAC with admin/developer/viewer roles
- **Audit Logging**: Comprehensive operation tracking
- **Credential Security**: Environment variable support with ${VAR} syntax
- **Security Checks**: Automated security validation

#### Documentation
- **User Guide**: Quick start, installation, usage
- **Operations Manual**: Deployment, monitoring, troubleshooting
- **API Reference**: Skills and commands documentation
- **Example Projects**: Simple and multi-stage templates
- **CI/CD Templates**: GitHub Actions, GitLab CI

### Technical Debt Resolution
- ✅ TD-01: Hook 脚本未正确 source notify.sh
- ✅ TD-02: 无 Hook 触发机制
- ✅ TD-03: 脚本可能无执行权限
- ✅ TD-04: 路径硬编码
- ✅ TD-05: 单元测试覆盖率为 0%
- ✅ TD-06: 无 E2E 测试
- ✅ TD-07: 无 BDD 测试
- ✅ TD-08: 无自动上下文恢复
- ✅ TD-09: 凭证明文存储
- ✅ TD-10: 无状态持久化
- ✅ TD-11: Taskfile YAML 解析问题

### Performance
- Hook trigger latency: < 100ms
- Notification send latency: < 500ms
- Memory footprint: ~4MB (idle)
- Test execution: 867 tests in ~60s

### Compatibility
- **Operating Systems**: macOS, Linux (x86_64, ARM64)
- **Shell**: Bash 4.0+
- **Task Runner**: go-task 3.0+
- **Claude Code**: Latest version

---

## [0.1.0] - 2026-03-06

### Added
- Initial RDD Framework implementation
- Stage-based development workflow
- Hook notification system
- Checkpoint and handoff system
- Multi-channel notification support
- Error handling and retry logic
- Performance benchmarking
- Security checks and audit logging

### Stage Progress

#### Stage 0: Framework Foundation ✅ (2026-03-06)
- Directory structure and configuration
- Documentation templates
- Agent entry points (AGENTS.md, CLAUDE.md)
- Basic scripts (notify.sh)

#### Stage 1: Critical Fixes ✅ (2026-03-07)
- Hook script fixes
- Path configuration
- Credential security

#### Stage 2: Testing Infrastructure ✅ (2026-03-07)
- bats-core framework integration
- Unit tests (500+ tests)
- BDD tests (10+ tests)
- Hook tests (19+ tests)
- E2E tests (21 tests)

#### Stage 3: Context Recovery ✅ (2026-03-08)
- Checkpoint system
- Handoff generation
- Recovery protocol

#### Stage 4: Error Handling ✅ (2026-03-08)
- Error classification
- Retry mechanism
- Circuit breaker pattern
- Structured logging

#### Stage 5: Performance ✅ (2026-03-08)
- Performance benchmarks
- Version management
- Migration scripts
- Compatibility checking

#### Stage 6: Security ✅ (2026-03-08)
- Permission model (RBAC)
- Audit logging
- Credential encryption support
- Security validation

#### Stage 7: Documentation ✅ (2026-03-08)
- User guide
- Operations manual
- CI/CD templates
- Example projects

#### Stage 8: User Installation ✅ (2026-03-09)
- One-line install script
- Skills global installation
- Project initialization command
- README installation guide

#### Stage 9: Package Manager Support ✅ (2026-03-09)
- npm package
- Homebrew formula
- Project migration command

#### Stage 10: Developer Experience ✅ (2026-03-09)
- Interactive initialization wizard
- Online documentation site
- Version release workflow

---

## Version History Summary

| Version | Date | Test Coverage | Installation Methods |
|---------|------|---------------|---------------------|
| 0.1.0 | 2026-03-06 | 0% | Manual |
| 1.0.0 | 2026-03-09 | 100% (867/867) | curl, npm, Homebrew |

---

> **Note**: This changelog follows the RDD principle of explicit knowledge management. All changes are documented with clear references to the source Stage.

## [v1.2.0] — Stage 22 Complete (2026-07-10)

### Added
- `auto-detect.sh` — Scan roadmap for incomplete stages, topological sort by dependencies
- `loop-persist.sh` — Fine-grained atomic persistence at every key action (gate/ADR/debt/heartbeat)
- `task-registry.sh` — gotask convergence, orphan script detection
- `worktree-pool.sh` — Git worktree pool for isolated parallel stage execution
- `subagent-scheduler.sh` — Parallel/sequential stage orchestration
- `progress-dashboard.sh` — Multi-stage progress visualization

### Changed
- **Hardened Gate 3**: Replaced echo-only checks with real test/lint/format execution (`task test:unit`, `task lint:check`, `task fmt:check`)
- **gotask convergence**: All scripts now registered as `task` entries (11 new tasks)
- **ADR persistence**: Decisions written immediately, not deferred to Gate 5
- **Tech debt persistence**: Debt entries written on discovery
- **Bats test runner**: Migrated from embedded submodule to system `bats` (Homebrew)

### Decisions
- ADR-22A: Auto-detect incomplete stages (not manual `--from`/`--to`)
- ADR-22B: Remove `start` subcommand
- ADR-22C: Remove `--goal` NL parsing (v1)
- ADR-22D: Fine-grained atomic persistence at every key action
- ADR-22E: Gate 3 real execution only (non-zero exit blocks)
- ADR-22F: gotask convergence (no orphan commands)

### Technical Debt
- None introduced in Stage 22

### Tests
- E2E: 42/42 passed (100%)
- Format: `shfmt` clean
- Dependencies: `shellcheck`, `shfmt`, `yq` required (see `task bootstrap:deps`)
