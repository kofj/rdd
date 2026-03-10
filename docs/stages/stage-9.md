# Stage 9: Package Manager Support

## Status
- [x] Planning
- [x] In Progress
- [x] Complete

**Completion Date**: 2026-03-09

## Goals
Provide standard package manager installation methods, allowing users to install RDD Framework via npm or Homebrew.

## Non-Goals
- Windows package managers (chocolatey, scoop)
- VS Code extension (Stage 10)
- Online documentation site (Stage 10)

## Core Hypotheses
- H1: npm installation can cover Node.js developer user base
- H2: Homebrew installation can cover macOS developer user base
- H3: Users can verify installation via standard commands

## Acceptance Criteria

### npm Package (9.1) ✅
- [x] package.json configured correctly
- [x] postinstall script executes correctly
- [x] `npm install -g @kofj/rdd` succeeds
- [x] `rdd --version` shows version
- [x] `rdd init` creates project successfully
- [x] Skills installed correctly to ~/.claude/

### Homebrew Formula (9.2) ✅
- [x] Formula file created
- [x] `brew tap` can add tap
- [x] `brew install` succeeds
- [x] Commands available after installation

### Project Migration Command (9.3) ✅
- [x] `rdd migrate` detects project type
- [x] Creates RDD directory structure
- [x] Preserves existing code
- [x] Generates initial Roadmap

## Rollback Plan
- npm package can retract version
- Homebrew tap can be deleted
- Projects are independent, doesn't affect existing projects

## Known Limitations
- npm requires Node.js 14+
- Homebrew only supports macOS/Linux
- Migration command only supports common project types

## Impact on Subsequent Stages
- Stage 10 can extend interactive wizard
- Provides multiple installation channel choices

---

## Implementation Notes

### npm Package Structure

```
rdd-framework/
├── package.json
├── bin/
│   └── rdd              # CLI entry
├── scripts/
│   ├── install.sh       # curl install script
│   ├── uninstall.sh
│   ├── upgrade.sh
│   └── postinstall.js   # npm postinstall
├── .claude/
│   ├── skills/          # Copy to ~/.claude/skills/
│   └── commands/        # Copy to ~/.claude/commands/
├── .rdd/
│   ├── scripts/         # Core scripts
│   └── hooks/           # Hook scripts
├── docs/
│   └── templates/       # Document templates
└── README.md
```

### Homebrew Formula

```ruby
class RddFramework < Formula
  desc "Roadmap Driven Development Framework for AI Agents"
  homepage "https://github.com/kofj/rdd"
  url "https://github.com/kofj/rdd/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"
  head "https://github.com/kofj/rdd.git", branch: "main"

  depends_on "go-task" => :recommended

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/rdd"

    # Install Claude Code skills
    (ENV["HOME"]+"/.claude/skills").mkpath
    (libexec/".claude/skills").children.each do |skill|
      ln_s skill, ENV["HOME"]+"/.claude/skills"/skill.basename
    end

    # Install Claude Code commands
    (ENV["HOME"]+"/.claude/commands").mkpath
    (libexec/".claude/commands").children.each do |command|
      ln_s command, ENV["HOME"]+"/.claude/commands"/command.basename
    end
  end

  test do
    assert_match "RDD Framework", shell_output("#{bin}/rdd --version")
  end
end
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
- [x] npm pack successful
- [x] npm install test passed
- [x] Homebrew formula test passed
- [x] rdd migrate test passed

### Gate 4: Code Review Check
- [x] Triangulation complete
- [x] All blocking findings resolved
- [x] All acceptance criteria met

### Gate 5: Completion Gate Check
- [x] Main hypotheses verified
- [x] Tests reproducible
- [x] Documentation complete
- [x] CHANGELOG updated
