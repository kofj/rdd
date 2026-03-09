class RddFramework < Formula
  desc "Roadmap Driven Development Framework for AI Agents"
  homepage "https://github.com/kofj/rdd"
  url "https://github.com/kofj/rdd/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "TBD"  # Will be updated during release
  license "MIT"
  head "https://github.com/kofj/rdd.git", branch: "main"

  depends_on "go-task" => :recommended
  depends_on "bash" => :recommended

  def install
    # Install to libexec
    libexec.install Dir["*"]

    # Create bin directory and symlink rdd command
    bin.mkdir
    bin.install_symlink libexec/"bin/rdd"

    # Install scripts
    (libexec/"scripts").install Dir["scripts/*.sh"]

    # Install Claude Code skills
    ohai "Installing Claude Code skills..."
    skills_dir = Pathname.new(ENV["HOME"]) / ".claude" / "skills"
    skills_dir.mkpath

    if (libexec/".claude/skills").exist?
      (libexec/".claude/skills").children.each do |skill|
        ln_sf skill, skills_dir/skill.basename
      end
    end

    # Install Claude Code commands
    ohai "Installing Claude Code commands..."
    commands_dir = Pathpath.new(ENV["HOME"]) / ".claude" / "commands"
    commands_dir.mkpath

    if (libexec/".claude/commands").exist?
      (libexec/".claude/commands").children.each do |command|
        ln_sf command, commands_dir/command.basename
      end
    end

    # Set environment variable
    ohai "Setting RDD_FRAMEWORK_HOME environment variable..."
    ENV["RDD_FRAMEWORK_HOME"] = libexec
  end

  def caveats
    <<~EOS
      RDD Framework has been installed!

      To complete the setup, add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):

        export RDD_FRAMEWORK_HOME="#{libexec}"

      Then restart your shell or run:
        source ~/.bashrc  # or ~/.zshrc

      Quick Start:
        rdd init my-project    # Create a new project
        cd my-project
        task doctor            # Verify setup

      Use with Claude Code:
        Open Claude Code in your project directory.
        RDD skills are automatically available.

      Documentation:
        https://github.com/kofj/rdd

    EOS
  end

  test do
    assert_match "RDD Framework", shell_output("#{bin}/rdd --version")
    assert_match "Usage", shell_output("#{bin}/rdd --help")
  end
end
