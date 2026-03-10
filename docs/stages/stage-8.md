# Stage 8: User Installation Experience

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
Enable users to install RDD Framework with one click and use it in Claude Code, achieving complete user usability.

## Non-Goals
- npm package publishing (Stage 9)
- Homebrew support (Stage 9)
- VS Code extension (Stage 10)
- Interactive wizard (Stage 10)

## Core Hypotheses
- H1: Users can complete installation in 5 minutes via curl | sh
- H2: Claude Code can automatically recognize Skills after installation
- H3: `rdd init` can create complete project structure
- H4: Users can start using without reading long documentation

## Acceptance Criteria

### Installation Script (8.1) ✅
- [x] install.sh supports macOS and Linux
- [x] Detect dependencies (bash, task, git)
- [x] Create ~/.rdd-framework directory
- [x] Download framework files
- [x] Configure PATH
- [x] Install skills to ~/.claude/skills/
- [x] Verify installation successful
- [x] uninstall.sh can completely uninstall
- [x] upgrade.sh can upgrade version

### Global Skills Installation (8.2) ✅
- [x] 13 skills copied to ~/.claude/skills/
- [x] 6 commands copied to ~/.claude/commands/
- [x] Claude Code can recognize skills
- [x] /rdd-init available in any project
- [x] /rdd-stage-auto available in RDD projects

### Project Initialization Command (8.3) ✅
- [x] `rdd init` creates project in current directory
- [x] `rdd init <name>` creates named project
- [x] Creates complete directory structure
- [x] Creates configuration files
- [x] Creates document templates
- [x] Creates Taskfile.yml
- [x] Symlinks to global scripts
- [x] `task doctor` passes

### README Update (8.4) ✅
- [x] Complete installation steps
- [x] Quick start guide
- [x] Claude Code usage instructions
- [x] Command reference
- [x] Troubleshooting

### GitHub Release (8.5) ✅
- [x] v1.0.0 tag created
- [x] Release notes written
- [x] Release assets packaged (tar.gz, zip)
- [x] Install script points to stable version

## Rollback Plan
- Install script supports --uninstall parameter
- Version rollback: `rdd upgrade --version <version>`
- Projects are independent, doesn't affect existing projects

## Known Limitations
- Windows native not supported, requires WSL
- Requires network connection to download files
- First installation requires manual notification channel configuration

## Impact on Subsequent Stages
- Stage 9 builds on install script for npm package
- Stage 10 can extend interactive wizard
- Provides distribution foundation for future versions

---

## Implementation Notes

### Installation Script Architecture

```
scripts/
├── install.sh          # Main installation script
├── uninstall.sh        # Uninstall script
├── upgrade.sh          # Upgrade script
├── common.sh           # Shared functions
└── templates/
    └── Taskfile.yml    # Project Taskfile template
```

### Installation Flow

```
1. Environment Check
   ├── Detect operating system
   ├── Detect dependencies (bash, task, git)
   └── Prompt for missing dependencies

2. Prepare Installation
   ├── Create ~/.rdd-framework
   ├── Create ~/.claude/skills
   └── Create ~/.claude/commands

3. Download Files
   ├── Download core scripts
   ├── Download skills
   ├── Download commands
   └── Download document templates

4. Configure Environment
   ├── Add to PATH
   ├── Configure RDD_FRAMEWORK_HOME
   └── Verify installation

5. Complete
   ├── Show success message
   └── Show next steps
```

### rdd Command Architecture

```
~/.rdd-framework/
├── bin/
│   └── rdd            # Main command entry
├── lib/
│   ├── init.sh        # init subcommand
│   ├── migrate.sh     # migrate subcommand
│   ├── stage.sh       # stage subcommand
│   ├── knowledge.sh   # knowledge subcommand
│   └── common.sh      # Shared functions
├── scripts/           # Copied from project
├── hooks/             # Copied from project
├── templates/         # Project templates
│   ├── docs/
│   ├── .rdd/
│   └── Taskfile.yml
└── VERSION
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
- [x] Multi-model review triggered
- [x] AI pre-filtering completed
- [x] High-confidence findings resolved

### Gate 3: Implementation & Testing Check
- [x] Implementation complete
- [x] Install script tested on macOS
- [x] Install script tested on Linux
- [x] Skills loading verified
- [x] `rdd init` creates valid project
- [x] `task doctor` passes

### Gate 4: Code Review Check
- [x] Triangulation complete
- [x] All blocking findings resolved
- [x] All acceptance criteria met

### Gate 5: Completion Gate Check
- [x] Main hypotheses verified
- [x] Tests reproducible
- [x] Documentation complete
- [x] fresh-agent-check passed
- [x] CHANGELOG updated
