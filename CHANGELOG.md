# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- RDD (Roadmap Driven Development) framework initial setup
- Core documentation structure with 7 key documents:
  - `docs/01-charter.md` - Project charter and vision
  - `docs/02-engineering-principles.md` - Engineering principles and quality standards
  - `docs/03-stage-based-development.md` - Stage-based development methodology
  - `docs/08-autonomous-decisions.md` - Architecture Decision Records (ADR)
  - `docs/10-review-practices.md` - Multi-model review methodology
  - `docs/11-next-steps.md` - Current progress and next steps
  - `docs/12-technical-debt.md` - Technical debt ledger
- Stage document templates:
  - `docs/stages/stage-roadmap.md` - Roadmap template
  - `docs/stages/stage-N.md` - Stage design document template
  - `docs/stages/stage-N-review-log.md` - Review log template
  - `docs/stages/stage-N-retrospective.md` - Retrospective template
- RDD configuration directory structure (`.rdd/`)
- Agent entry points:
  - `AGENTS.md` - Main entry point for AI agents
  - `CLAUDE.md` - Claude Code specific entry point
- RDD core concepts:
  - Roadmap-driven development methodology
  - Stage as minimal delivery unit
  - Four-layer gate checkpoint system
  - Explicit knowledge management
  - Multi-model review with false positive handling
  - Hook notification system design

### Changed

- N/A (initial release)

### Deprecated

- N/A (initial release)

### Removed

- N/A (initial release)

### Fixed

- N/A (initial release)

### Security

- N/A (initial release)

---

## [0.1.0] - 2026-03-06

### Added

- Initial RDD framework structure
- Documentation templates and guidelines
- Agent entry points for AI-driven development

---

## Changelog Guidelines

### Types of Changes

- **Added**: New features or capabilities
- **Changed**: Changes to existing functionality
- **Deprecated**: Features that will be removed in future releases
- **Removed**: Features that have been removed
- **Fixed**: Bug fixes and corrections
- **Security**: Security-related changes

### Entry Format

Each Stage completion should add an entry following this format:

```markdown
## [version] - YYYY-MM-DD

### Added
- Feature description (Stage N)

### Changed
- Change description (Stage N)

### Fixed
- Fix description (Stage N)
```

### Version Naming

- Major version (X.0.0): Breaking changes, major milestones
- Minor version (0.X.0): New features, Stage completions
- Patch version (0.0.X): Bug fixes, minor improvements

---

> **Note**: This changelog follows the RDD principle of explicit knowledge management. All changes should be documented with clear references to the source Stage.
