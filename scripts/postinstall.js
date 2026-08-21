#!/usr/bin/env node
/**
 * RDD Framework Post-Install Script
 * Runs after npm install to set up skills for Claude Code.
 *
 * Skills use the Claude Code directory format: ~/.claude/skills/<name>/SKILL.md
 * A compliant skill supports both slash (/rdd-init) and natural-language triggers,
 * so no separate slash commands are installed.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const HOME = os.homedir();
const CLAUDE_DIR = path.join(HOME, '.claude');
const SKILLS_DIR = path.join(CLAUDE_DIR, 'skills');
const COMMANDS_DIR = path.join(CLAUDE_DIR, 'commands');

function ensureDir(dir) {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        console.log(`Created directory: ${dir}`);
    }
}

function copyDir(src, dest) {
    ensureDir(dest);
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);
        if (entry.isDirectory()) {
            copyDir(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

// Remove legacy flat skill files (~/.claude/skills/rdd-*.md) and legacy slash
// commands (~/.claude/commands/rdd-*.md) left behind by older versions.
function cleanupLegacy() {
    for (const [dir, label] of [[SKILLS_DIR, 'skill'], [COMMANDS_DIR, 'command']]) {
        if (!fs.existsSync(dir)) continue;
        for (const name of fs.readdirSync(dir)) {
            if (/^rdd-.*\.md$/.test(name)) {
                fs.rmSync(path.join(dir, name), { force: true });
                console.log(`Removed legacy ${label}: ${name}`);
            }
        }
    }
}

function installSkills() {
    const packageDir = path.resolve(__dirname, '..');
    const sourceSkillsDir = path.join(packageDir, '.claude', 'skills');

    if (!fs.existsSync(sourceSkillsDir)) {
        console.warn('Warning: Skills source directory not found');
        return;
    }

    ensureDir(SKILLS_DIR);

    for (const entry of fs.readdirSync(sourceSkillsDir, { withFileTypes: true })) {
        if (!entry.isDirectory() || !entry.name.startsWith('rdd-')) continue;
        const src = path.join(sourceSkillsDir, entry.name);
        const dest = path.join(SKILLS_DIR, entry.name);
        copyDir(src, dest);
        console.log(`Installed skill: ${entry.name}`);
    }
}

function main() {
    console.log('\n📝 RDD Framework Post-Install\n');
    console.log('Installing RDD skills for Claude Code...\n');

    cleanupLegacy();
    installSkills();

    console.log('\n✅ RDD Framework installed successfully!\n');
    console.log('Next steps:');
    console.log('  1. Run "rdd --version" to verify installation');
    console.log('  2. Run "rdd init my-project" to create a new project');
    console.log('  3. Open Claude Code in your project directory');
    console.log('  4. Use /rdd-init or ask in natural language\n');
}

main();
