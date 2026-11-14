#!/usr/bin/env python3
"""Real filesystem lifecycle and CLI tests; never touches the actual user home."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
# Bats/framework suites export project paths. Child fixtures must not inherit them.
CHILD_ENV = {k: v for k, v in os.environ.items() if not k.startswith('RDD_') and k not in {
    'PROJECT_ROOT', 'CACHE_DIR', 'CONFIG_FILE', 'TEMPLATES_FILE', 'HOOKS_FILE',
    'VERSION_FILE', 'DRY_RUN', 'SCRIPTS_DIR'}}


def run_process(*args, **kwargs):
    kwargs.setdefault('env', CHILD_ENV)
    return subprocess.run(*args, **kwargs)

spec = importlib.util.spec_from_file_location('rdd_manage', ROOT / 'scripts/install/manage.py')
manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manager)


class AgentsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='rdd agents ')
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / 'user'
        self.prefix = self.root / 'runtime'
        self.home.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def call(self, action='install', *extra):
        with contextlib.redirect_stdout(io.StringIO()):
            manager.main([action, '--prefix', str(self.prefix), '--user-home', str(self.home), *extra])

    def cli(self, *args, cwd=None, success=True):
        result = run_process([str(self.prefix / 'bin/rdd'), *args], cwd=cwd, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_codex_only_and_idempotent_upgrade(self):
        self.call('install', '--agent', 'codex')
        self.assertFalse((self.home / '.claude').exists())
        skill = self.home / '.agents/skills/rdd-core'
        self.assertEqual(manager.digest(skill), manager.digest(ROOT / '.claude/skills/rdd-core'))
        self.call()
        manifest = json.loads((self.prefix / manager.MANIFEST).read_text())
        self.assertEqual(manifest['targets'], ['codex'])
        self.cli('--version')

    def test_both_identical_and_sibling_references_resolve(self):
        self.call()
        sources = sorted((ROOT / '.claude/skills').glob('rdd-*'))
        for source in sources:
            for host in manager.TARGETS.values():
                target = self.home / host / source.name
                self.assertEqual(manager.digest(source), manager.digest(target))
                import re
                for ref in re.findall(r'\.\./rdd-[\w/-]+\.md', (target / 'SKILL.md').read_text()):
                    self.assertTrue((target / ref).is_file(), ref)

    def test_invalid_target_no_mutation(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('install', '--agent', 'unknown')
        self.assertFalse(self.prefix.exists())

    def test_conflict_preflight_and_explicit_backup(self):
        skill = self.home / '.agents/skills/rdd-core'
        skill.mkdir(parents=True)
        (skill / 'custom').write_text('keep me')
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.assertFalse(self.prefix.exists())
        self.assertFalse((self.home / '.claude').exists())
        self.call('install', '--replace-skills')
        self.assertEqual(next((self.home / '.rdd-backups').rglob('rdd-core.rdd-backup-*')).joinpath('custom').read_text(), 'keep me')
        discovered = sorted(p.parent.name for p in skill.parent.glob('*/SKILL.md'))
        canonical = sorted(p.parent.name for p in (ROOT / '.claude/skills').glob('*/SKILL.md'))
        self.assertEqual(discovered, canonical)

    def test_modified_owned_skill_preserved_on_uninstall(self):
        self.call()
        skill = self.home / '.agents/skills/rdd-core'
        (skill / 'custom').write_text('keep me')
        self.call('uninstall')
        self.assertEqual((skill / 'custom').read_text(), 'keep me')
        self.assertFalse((self.home / '.claude/skills/rdd-core').exists())

    def test_unrelated_files_survive_upgrade_and_uninstall(self):
        self.call()
        (self.prefix / 'personal.txt').write_text('user')
        (self.prefix / 'docs/personal.md').write_text('user')
        skill = self.home / '.agents/skills/other-skill'
        skill.mkdir(); (skill / 'SKILL.md').write_text('unrelated')
        self.call()
        self.call('uninstall')
        self.assertEqual((self.prefix / 'personal.txt').read_text(), 'user')
        self.assertEqual((self.prefix / 'docs/personal.md').read_text(), 'user')
        self.assertTrue((skill / 'SKILL.md').exists())

    def test_modified_runtime_blocks_upgrade(self):
        self.call()
        (self.prefix / 'README.md').write_text('modified')
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.assertEqual((self.prefix / 'README.md').read_text(), 'modified')

    def test_symlink_collision_never_followed(self):
        external = self.root / 'external'; external.mkdir()
        (external / 'important').write_text('keep')
        skill = self.home / '.agents/skills/rdd-core'
        skill.parent.mkdir(parents=True); skill.symlink_to(external)
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.call('install', '--replace-skills')
        self.assertEqual((external / 'important').read_text(), 'keep')
        self.assertFalse(skill.is_symlink())

    def test_parent_symlink_refused(self):
        external = self.root / 'external'; external.mkdir()
        (self.home / '.agents').symlink_to(external)
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.assertEqual(list(external.iterdir()), [])

    def test_add_target_preserves_previous(self):
        self.call('install', '--agent', 'claude')
        self.call('install', '--agent', 'codex')
        self.assertEqual(json.loads((self.prefix / manager.MANIFEST).read_text())['targets'], ['claude', 'codex'])

    def test_dry_run_does_not_write(self):
        self.call('install', '--dry-run')
        self.assertFalse(self.prefix.exists())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_runtime_commit_failure_restores_skills(self):
        self.call()
        before = manager.digest(self.home / '.agents/skills')
        original = Path.rename
        def failing_rename(path, target):
            if '.rdd-incoming-' in path.name and target == self.prefix:
                raise OSError('injected commit failure')
            return original(path, target)
        with patch.object(Path, 'rename', failing_rename), contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('install', '--version', '9.9.9')
        self.assertEqual(manager.digest(self.home / '.agents/skills'), before)
        self.cli('--version')

    def test_new_project_and_migration_preserve_files(self):
        self.call()
        project = self.root / 'my project'
        self.cli('init', str(project))
        self.assertTrue((project / '.rdd/scripts/loop-persist.sh').is_file())
        self.assertNotIn('Stage 23', (project / 'docs/stages/stage-roadmap.md').read_text())
        self.assertIn('AGENTS.md', (project / 'CLAUDE.md').read_text())
        self.cli('doctor', cwd=project)
        result = run_process(['task', 'test:unit'], cwd=project, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Configure test:unit', result.stderr + result.stdout)
        (project / 'AGENTS.md').write_text('user guidance')
        (project / 'Taskfile.yml').write_text("version: '3'\ntasks:\n  test:\n    cmds: ['true']\n")
        self.cli('migrate', cwd=project)
        self.assertEqual((project / 'AGENTS.md').read_text(), 'user guidance')
        self.assertTrue((project / 'Taskfile.rdd.yml').is_file())
        self.assertIn("['true']", (project / 'Taskfile.yml').read_text())

    def test_shell_install_upgrade_uninstall(self):
        command = ['bash', str(ROOT / 'scripts/install/install.sh'), '--source', str(ROOT), '--prefix', str(self.prefix), '--user-home', str(self.home), '--no-path']
        for extra in (['--agent', 'codex'], ['--upgrade']):
            result = run_process(command + extra, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.cli('--help')
        self.cli('uninstall', '--user-home', str(self.home))
        self.assertFalse(self.prefix.exists())

    def test_unowned_prefix_refused_and_backed_up(self):
        self.prefix.mkdir(); (self.prefix / 'legacy').write_text('old')
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.call('install', '--replace-skills')
        backup = next(self.root.glob('runtime.rdd-backup-*'))
        self.assertEqual((backup / 'legacy').read_text(), 'old')

    def test_unsafe_prefix_and_manifest_refused(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('install', '--prefix', str(ROOT))
        self.call()
        file = self.prefix / manager.MANIFEST
        data = json.loads(file.read_text()); data['files']['../escape'] = 'bad'; file.write_text(json.dumps(data))
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('uninstall')

    def test_dry_uninstall_and_migrate_do_not_write(self):
        self.call()
        before = manager.digest(self.prefix)
        self.call('uninstall', '--dry-run')
        self.assertEqual(manager.digest(self.prefix), before)
        project = self.root / 'preview'
        self.call('migrate', '--project', str(project), '--dry-run')
        self.assertFalse(project.exists())

    def test_upgrade_retires_owned_skills_and_preserves_new_collisions(self):
        self.call()
        source = self.root / 'new-source'
        shutil.copytree(ROOT, source, symlinks=True, ignore=shutil.ignore_patterns('.git', '.worktrees', 'cache', '__pycache__', 'node_modules'))
        shutil.rmtree(source / '.claude/skills/rdd-help')
        (self.prefix / 'docs/new-user-file.md').write_text('user')
        (source / 'docs/new-user-file.md').write_text('upstream')
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('install', '--source', str(source))
        self.assertEqual((self.prefix / 'docs/new-user-file.md').read_text(), 'user')
        (source / 'docs/new-user-file.md').unlink()
        self.call('install', '--source', str(source))
        self.assertFalse((self.home / '.agents/skills/rdd-help').exists())
        self.assertFalse((self.prefix / '.claude/skills/rdd-help/SKILL.md').exists())
        self.call('uninstall')
        self.assertEqual((self.prefix / 'docs/new-user-file.md').read_text(), 'user')

    def test_npm_pack_and_symlink_entry(self):
        result = run_process(['npm', 'pack', '--ignore-scripts', '--json', '--pack-destination', str(self.root)], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        archive = self.root / json.loads(result.stdout)[0]['filename']
        run_process(['tar', '-xzf', str(archive), '-C', str(self.root)], check=True)
        entry = self.root / 'rdd-npm'; entry.symlink_to(self.root / 'package/bin/rdd')
        result = run_process([str(entry), 'install', '--agent', 'codex', '--prefix', str(self.prefix), '--user-home', str(self.home)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.cli('--version')

    def test_scheduler_requests_retain_dirty_worktree_and_state(self):
        project = self.root / 'repo'
        self.call('init', '--project', str(project))
        def run(*command, success=True):
            result = run_process(command, cwd=project, capture_output=True, text=True)
            if success:
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            return result
        run('git', 'init', '-q')
        run('git', 'add', '.')
        run('git', '-c', 'user.name=RDD Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture')
        result = run('bash', '.rdd/scripts/subagent-scheduler.sh', 'sequential', '23', '24')
        state = json.loads((project / '.rdd/worktrees/pool.json').read_text())
        self.assertEqual(list(state['active']), ['23'])
        worktree = Path(state['active']['23'])
        self.assertTrue((worktree / '.rdd/trigger-stage-23').is_file())
        result = run('bash', '.rdd/scripts/worktree-pool.sh', 'release', '23', success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(worktree.exists())
        run('bash', '.rdd/scripts/loop-persist.sh', 'init', '1')
        run('bash', '.rdd/scripts/loop-persist.sh', 'stage-start', '23', 'fixture')
        self.assertIn('23', run('bash', '.rdd/scripts/loop-persist.sh', 'show').stdout)

    def test_installed_reconfigure_is_idempotent_and_home_cannot_change(self):
        self.call('install', '--agent', 'codex')
        skill = self.home / '.agents/skills/rdd-core/SKILL.md'
        inode = skill.stat().st_ino
        self.cli('install', '--agent', 'codex')
        self.assertEqual(skill.stat().st_ino, inode)
        self.cli('install', '--agent', 'claude')
        self.assertTrue((self.home / '.claude/skills/rdd-core/SKILL.md').exists())
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call('install', '--user-home', str(self.root / 'another-user'))

    def test_interactive_and_chinese_init(self):
        self.call()
        project = self.root / 'chinese'
        self.cli('init', '--lang', 'zh', str(project))
        self.assertIn('项目章程', (project / 'docs/01-charter.md').read_text())
        result = run_process([str(self.prefix / 'bin/rdd'), 'init', '--interactive'], cwd=self.root,
            input=str(self.root / 'interactive') + '\nen\n', capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_temporary_bootstrap_uninstall_and_version_identity(self):
        command = ['bash', str(ROOT / 'scripts/install/install.sh'), '--source', str(ROOT), '--prefix', str(self.prefix), '--user-home', str(self.home), '--version', 'v9.8.7']
        run_process(command, check=True, stdout=subprocess.DEVNULL)
        self.assertIn('v9.8.7', self.cli('--version').stdout)
        self.cli('install', '--agent', 'claude')
        self.assertIn('v9.8.7', self.cli('--version').stdout)
        bootstrap = self.root / 'downloaded-installer.sh'
        shutil.copy2(ROOT / 'scripts/install/install.sh', bootstrap)
        result = run_process(['bash', str(bootstrap), '--uninstall', '--prefix', str(self.prefix), '--dry-run'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.prefix.exists())
        run_process(['bash', str(bootstrap), '--uninstall', '--prefix', str(self.prefix)], check=True, stdout=subprocess.DEVNULL)
        self.assertFalse(self.prefix.exists())

    def test_backup_client_symlink_is_rejected_before_mutation(self):
        external = self.root / 'external-backup'; external.mkdir()
        token = manager.hashlib.sha256(str(self.prefix).encode()).hexdigest()[:12]
        backup = self.home / '.rdd-backups' / token
        backup.mkdir(parents=True)
        (backup / 'codex').symlink_to(external)
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.call()
        self.assertFalse(self.prefix.exists())
        self.assertEqual(list(external.iterdir()), [])

    def test_knowledge_cli_forwards_arguments_to_shared_tasks(self):
        self.call()
        project = self.root / 'knowledge-project'
        self.cli('init', str(project))
        self.cli('knowledge', 'adr', '23A', 'Shared runtime', 'Parity request', 'One implementation',
                 'Prevent drift', 'Both hosts share tasks', '23', cwd=project)
        self.assertIn('Both hosts share tasks', (project / 'docs/08-autonomous-decisions.md').read_text())
        self.cli('knowledge', 'debt', '99', 'Deferred item', 'Local', '23', 'Known limitation',
                 'README.md', '1', 'Later', cwd=project)
        self.assertIn('Known limitation', (project / 'docs/12-technical-debt.md').read_text())
        self.cli('stage', 'status', cwd=project)


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(AgentsTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
