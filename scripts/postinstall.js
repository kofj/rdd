#!/usr/bin/env node
/**
 * RDD Framework Post-Install Script
 * Runs after npm install to set up skills and commands
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const HOME = os.homedir();
const CLAUDE_DIR = path.join(HOME, '.claude');
const SKILLS_DIR = path.join(CLAUDE_DIR, 'skills');
const COMMANDS_DIR = path.join(CLAUDE_DIR, 'commands');

// Skills to install
const SKILLS = [
    'rdd-init',
    'rdd-migrate',
    'rdd-roadmap',
    'rdd-stage-auto',
    'rdd-knowledge',
    'rdd-loop',
    'rdd-review-auto',
    'rdd-recovery',
    'rdd-diagnosis',
    'rdd-fresh-check',
    'rdd-hooks',
    'rdd-core',
    'rdd-templates'
];

// Commands to install
const COMMANDS = [
    'rdd-init',
    'rdd-migrate',
    'rdd-roadmap',
    'rdd-stage-auto',
    'rdd-knowledge',
    'rdd-loop'
];

function ensureDir(dir) {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        console.log(`Created directory: ${dir}`);
    }
}

function copyFile(src, dest) {
    try {
        fs.copyFileSync(src, dest);
        console.log(`Installed: ${path.basename(dest)}`);
    } catch (err) {
        console.warn(`Warning: Could not copy ${path.basename(src)}: ${err.message}`);
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

    for (const skill of SKILLS) {
        const src = path.join(sourceSkillsDir, `${skill}.md`);
        const dest = path.join(SKILLS_DIR, `${skill}.md`);

        if (fs.existsSync(src)) {
            copyFile(src, dest);
        } else {
            console.warn(`Warning: Skill not found: ${skill}.md`);
        }
    }
}

function installCommands() {
    const packageDir = path.resolve(__dirname, '..');
    const sourceCommandsDir = path.join(packageDir, '.claude', 'commands');

    if (!fs.existsSync(sourceCommandsDir)) {
        console.warn('Warning: Commands source directory not found');
        return;
    }

    ensureDir(COMMANDS_DIR);

    for (const command of COMMANDS) {
        const src = path.join(sourceCommandsDir, `${command}.md`);
        const dest = path.join(COMMANDS_DIR, `${command}.md`);

        if (fs.existsSync(src)) {
            copyFile(src, dest);
        } else {
            console.warn(`Warning: Command not found: ${command}.md`);
        }
    }
}

function main() {
    console.log('\n📝 RDD Framework Post-Install\n');
    console.log('Installing RDD skills and commands for Claude Code...\n');

    installSkills();
    installCommands();

    console.log('\n✅ RDD Framework installed successfully!\n');
    console.log('Next steps:');
    console.log('  1. Run "rdd --version" to verify installation');
    console.log('  2. Run "rdd init my-project" to create a new project');
    console.log('  3. Open Claude Code in your project directory');
    console.log('  4. Use /rdd-init or other RDD skills\n');
}

main();
