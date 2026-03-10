# RDD Framework v1.0 User Readiness Roadmap

> Goal: Enable users to install with one click and use RDD Framework in Claude Code

---

## Current Status Assessment

### ✅ Completed

| Component | Status | Description |
|-----------|--------|-------------|
| Framework Core Code | ✅ | 16 scripts + 8 Hooks |
| Skills Definition | ✅ | 13 skills defined |
| Commands Definition | ✅ | 6 commands defined |
| Documentation System | ✅ | User guide + Operations manual |
| Test Coverage | ✅ | 867 tests 100% passing |
| CI/CD Templates | ✅ | GitHub Actions + GitLab CI |
| Example Projects | ✅ | simple-project + multi-stage |

### ❌ User Readiness Gaps

| Gap | Impact | Priority |
|-----|--------|----------|
| **No installation method** | Users cannot get the framework | P0 |
| **Skills not available** | Claude Code cannot invoke skills | P0 |
| **No init command** | Users cannot quickly start new projects | P1 |
| **No installation guide in docs** | README lacks installation steps | P1 |
| **No version release** | No release package/version tag | P1 |
| **No npm/homebrew** | Non-standard installation channels | P2 |

---

## Roadmap

### Stage 8: User Installation Experience (v1.0.1)

**Goal**: Enable users to install and use RDD Framework

**Estimated Duration**: 2-3 days

**Acceptance Criteria**:
- [ ] One-click installation script available
- [ ] `rdd init` command available in any project
- [ ] Skills work in Claude Code
- [ ] README includes complete installation guide
- [ ] GitHub Release published

---

#### Task Breakdown

##### 8.1 Installation Script (P0)

**Goal**: Provide `curl | sh` one-click installation

**Deliverables**:
```
scripts/install.sh          # One-click installation script
scripts/uninstall.sh        # Uninstall script
scripts/upgrade.sh          # Upgrade script
```

**Installation Flow**:
```bash
# User executes
curl -fsSL https://raw.githubusercontent.com/xxx/rdd-framework/main/scripts/install.sh | sh

# Script executes:
# 1. Detect system environment
# 2. Check dependencies (bash, task, git)
# 3. Create ~/.rdd-framework directory
# 4. Download framework files
# 5. Configure PATH
# 6. Install skills to ~/.claude/skills/
# 7. Verify installation
```

**Acceptance**:
- [ ] macOS installation successful
- [ ] Linux installation successful
- [ ] After installation `rdd --version` available
- [ ] After installation `task --list` shows RDD tasks

##### 8.2 Global Skills Installation (P0)

**Goal**: Skills available in all projects

**Claude Code Skills Mechanism**:
- Claude Code reads `~/.claude/skills/*.md` as global skills
- Reads `.claude/skills/*.md` as project skills
- Same for Commands

**Deliverables**:
```
~/.claude/skills/
├── rdd-init.md
├── rdd-migrate.md
├── rdd-roadmap.md
├── rdd-stage-auto.md
├── rdd-knowledge.md
├── rdd-loop.md
├── rdd-review-auto.md
├── rdd-recovery.md
├── rdd-diagnosis.md
├── rdd-fresh-check.md
├── rdd-hooks.md
├── rdd-core.md
└── rdd-templates.md

~/.claude/commands/
├── rdd-init.md
├── rdd-migrate.md
├── rdd-roadmap.md
├── rdd-stage-auto.md
├── rdd-knowledge.md
└── rdd-loop.md
```

**Acceptance**:
- [ ] `/rdd-init` available in any project
- [ ] `/rdd-stage-auto` available in RDD projects
- [ ] Skills descriptions displayed correctly in Claude Code

##### 8.3 Project Initialization Command (P1)

**Goal**: `rdd init` creates new RDD project

**Command Design**:
```bash
# Initialize in current directory
rdd init

# Create named project
rdd init my-project

# Create from template
rdd init --template multi-stage
```

**Initialization Content**:
```
my-project/
├── .rdd/
│   ├── config.yml
│   ├── hooks.yml
│   ├── templates.yml
│   ├── cache/
│   ├── scripts/ -> ~/.rdd-framework/scripts (symlink)
│   └── hooks/ -> ~/.rdd-framework/hooks (symlink)
├── docs/
│   ├── stages/
│   ├── 01-charter.md
│   ├── 02-engineering-principles.md
│   ├── ...
├── tests/
│   ├── unit/
│   ├── bdd/
│   └── e2e/
├── .claude/
│   └── skills/ (optional project-specific skills)
├── AGENTS.md
├── CLAUDE.md
├── Taskfile.yml -> ~/.rdd-framework/Taskfile.yml (symlink)
└── CHANGELOG.md
```

**Acceptance**:
- [ ] `rdd init` creates complete directory structure
- [ ] `task doctor` passes
- [ ] Claude Code can read CLAUDE.md

##### 8.4 README Installation Guide (P1)

**Goal**: Users can install following documentation

**New Content**:
```markdown
## Installation

### Quick Start

\`\`\`bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/xxx/rdd-framework/main/scripts/install.sh | sh

# Verify installation
rdd --version

# Initialize a new project
rdd init my-project
cd my-project

# Start using with Claude Code
# Just open Claude Code in the project directory
\`\`\`

### Requirements

- Bash 4.0+
- Task (go-task) 3.0+
- Git 2.0+
- Claude Code (optional, for AI-assisted development)

### Manual Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/xxx/rdd-framework.git
cd rdd-framework

# Install globally
./scripts/install.sh

# Or use locally
export RDD_FRAMEWORK_HOME=$(pwd)
\`\`\`

### Using with Claude Code

After installation, RDD skills are automatically available in Claude Code:

- `/rdd-init` - Initialize a new RDD project
- `/rdd-migrate` - Migrate existing project
- `/rdd-stage-auto` - Execute stage with gates
- `/rdd-knowledge` - Manage ADRs and tech debt
- `/rdd-loop` - Control autonomous execution
```

**Acceptance**:
- [ ] README includes installation steps
- [ ] README includes quick start
- [ ] README includes Claude Code usage instructions

##### 8.5 GitHub Release (P1)

**Goal**: Officially release v1.0.0

**Release Content**:
- Git tag v1.0.0
- GitHub Release notes
- Release assets (tar.gz, zip)
- CHANGELOG update

**Acceptance**:
- [ ] v1.0.0 tag created
- [ ] GitHub Release published
- [ ] Download links working
- [ ] Install script points to stable version

---

### Stage 9: Package Manager Support (v1.1.0)

**Goal**: Provide standard package manager installation methods

**Estimated Duration**: 3-5 days

**Acceptance Criteria**:
- [ ] npm package published (@kofj/rdd)
- [ ] Homebrew formula submitted
- [ ] AUR package (Arch Linux)

---

#### Task Breakdown

##### 9.1 npm Package (P1)

**Goal**: `npm install -g @kofj/rdd`

**package.json Design**:
```json
{
  "name": "@kofj/rdd",
  "version": "1.0.0",
  "description": "Roadmap Driven Development Framework for AI Agents",
  "bin": {
    "rdd": "./bin/rdd"
  },
  "files": [
    "bin/",
    "scripts/",
    ".claude/",
    ".rdd/",
    "Taskfile.yml",
    "docs/"
  ],
  "scripts": {
    "postinstall": "node scripts/postinstall.js"
  },
  "keywords": ["ai", "agent", "development", "roadmap", "claude"],
  "license": "MIT"
}
```

**Acceptance**:
- [ ] `npm install -g @kofj/rdd` successful
- [ ] `rdd --version` shows version
- [ ] Skills correctly installed to ~/.claude/

##### 9.2 Homebrew Formula (P2)

**Goal**: `brew install rdd-framework`

**Formula Design**:
```ruby
class RddFramework < Formula
  desc "Roadmap Driven Development Framework for AI Agents"
  homepage "https://github.com/xxx/rdd-framework"
  url "https://github.com/xxx/rdd-framework/archive/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "go-task" => :recommended

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/rdd"

    # Install Claude Code skills
    (ENV["HOME"]+"/.claude/skills").mkpath
    (libexec/".claude/skills").children.each do |skill|
      ln_s skill, ENV["HOME"]+"/.claude/skills"/skill.basename
    end
  end
end
```

**Acceptance**:
- [ ] `brew install xxx/rdd/rdd-framework` successful
- [ ] Homebrew tap created

##### 9.3 Project Migration Command (P2)

**Goal**: `rdd migrate` converts existing project to RDD project

**Command Design**:
```bash
# Detect existing project type and migrate
rdd migrate

# Specify project type
rdd migrate --type node
rdd migrate --type python
rdd migrate --type go
```

**Acceptance**:
- [ ] Detect project type
- [ ] Create RDD directory structure
- [ ] Preserve existing code
- [ ] Generate initial Roadmap

---

### Stage 10: Developer Experience Optimization (v1.2.0)

**Goal**: Improve developer experience

**Estimated Duration**: 2-3 days

**Acceptance Criteria**:
- [ ] Interactive initialization wizard
- [ ] VS Code extension basic features
- [ ] Online documentation site

---

#### Task Breakdown

##### 10.1 Interactive Initialization Wizard (P2)

**Goal**: Guide users through project configuration

**Design**:
```bash
$ rdd init --interactive

? What is your project name? (my-project)
? What is your project description?
? Which notification channels do you want to enable?
  ◉ WeChat (WeCom)
  ◯ Email
  ◯ Telegram
  ◯ Slack
? Do you want to create initial stages? (Y/n)
? How many stages do you plan? (3-5)
? What is your development approach?
  ◉ Test-Driven Development
  ◯ Behavior-Driven Development
  ◯ Documentation-Driven Development

✅ Project initialized successfully!

Next steps:
1. cd my-project
2. Open Claude Code in this directory
3. Run /rdd-roadmap to plan your stages
```

##### 10.2 VS Code Extension (P3)

**Goal**: Provide RDD-related VS Code integration

**Features**:
- Stage document snippets
- Gate check shortcut commands
- Roadmap visualization
- ADR record shortcuts

##### 10.3 Online Documentation Site (P2)

**Goal**: Provide searchable online documentation

**Technology Choice**:
- VitePress or Docusaurus
- GitHub Pages deployment

**Content**:
- Quick start
- Concept guide
- API reference
- Best practices
- FAQ

---

## Timeline

```
Week 1 (2026-03-10 ~ 2026-03-16):
├── Stage 8.1: Installation script
├── Stage 8.2: Global Skills installation
└── Stage 8.3: Project initialization command

Week 2 (2026-03-17 ~ 2026-03-23):
├── Stage 8.4: README update
├── Stage 8.5: GitHub Release
└── v1.0.1 release

Week 3-4 (2026-03-24 ~ 2026-04-06):
├── Stage 9.1: npm package
├── Stage 9.2: Homebrew
└── v1.1.0 release

Week 5-6 (2026-04-07 ~ 2026-04-20):
├── Stage 10.1: Interactive wizard
├── Stage 10.3: Documentation site
└── v1.2.0 release
```

---

## Release Plan

### v1.0.1 (2026-03-17)

**Theme**: User Installation Experience

**Content**:
- One-click installation script
- Global Skills installation
- Project initialization command
- README installation guide
- GitHub Release

### v1.1.0 (2026-04-07)

**Theme**: Package Manager Support

**Content**:
- npm global package
- Homebrew formula
- Project migration command

### v1.2.0 (2026-04-21)

**Theme**: Developer Experience

**Content**:
- Interactive initialization wizard
- Online documentation site

---

## Resource Requirements

### Personnel

- Development: 1 person (main work)
- Documentation: 0.5 person (documentation optimization)
- Testing: 0.5 person (multi-environment testing)

### Infrastructure

- GitHub Repository (existing)
- npm Registry (free)
- Homebrew Tap (free)
- GitHub Pages (free)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Skills path issues | Medium | High | Test multiple environments, provide manual configuration method |
| Cross-platform compatibility | Medium | Medium | Support macOS/Linux, Windows WSL |
| npm publish permissions | Low | Medium | Request npm org permissions in advance |
| Homebrew review | Low | Low | Prepare detailed documentation, respond to review comments |

---

## Success Metrics

### After v1.0.1 Release

- Users can complete installation within 5 minutes
- `rdd init` success rate > 95%
- `/rdd-init` skill invocation success rate > 95%

### After v1.1.0 Release

- npm weekly downloads > 100
- Homebrew installation success rate > 90%
- GitHub Stars growth > 20%

### After v1.2.0 Release

- Documentation site daily visits > 50
- User feedback response time < 24h
- Community contributions > 5 PRs

---

## Items Awaiting Confirmation

Please review the following key decisions:

1. **Installation Method Priority**:
   - [ ] curl | sh first (recommended)
   - [ ] npm first
   - [ ] Homebrew first

2. **Skills Distribution Strategy**:
   - [ ] Copy to ~/.claude/skills/ during installation
   - [ ] Create symbolic links
   - [ ] Load dynamically at runtime

3. **Release Channels**:
   - [ ] GitHub Release only
   - [ ] GitHub + npm
   - [ ] GitHub + npm + Homebrew

4. **Version Number Strategy**:
   - [ ] Start from v1.0.1
   - [ ] Start from v1.1.0
   - [ ] Release v1.0.0 directly

5. **Project Naming**:
   - [ ] rdd-framework
   - [ ] rdd (short)
   - [ ] @kofj/rdd

---

> **Next Step**: Please confirm the above decisions, and I will begin implementing Stage 8.
