#!/usr/bin/env python3
"""Shared, standard-library-only RDD installation lifecycle (Python >= 3.8)."""
import argparse
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = 'install-manifest.json'
TARGETS = {'claude': '.claude/skills', 'codex': '.agents/skills'}
ASSETS = ('bin', 'scripts', '.rdd', '.claude/skills', 'templates', 'docs', 'Taskfile.yml', 'AGENTS.md', 'CLAUDE.md', 'package.json', 'README.md', 'LICENSE')


def digest(path):
    if path.is_symlink():
        return 'symlink:' + os.readlink(path)
    if path.is_file():
        return hashlib.sha256(path.read_bytes()).hexdigest()
    if not path.exists():
        return None
    h = hashlib.sha256()
    for file in sorted(path.rglob('*')):
        if file.is_file() or file.is_symlink():
            h.update(str(file.relative_to(path)).encode())
            h.update(digest(file).encode())
    return h.hexdigest()


def read_manifest(prefix):
    file = prefix / MANIFEST
    if not file.exists():
        return {'targets': [], 'skills': {}, 'files': {}}
    data = json.loads(file.read_text())
    if data.get('owner') != 'rdd' or data.get('schema') != 1:
        raise ValueError('Unsupported installation manifest')
    for name in data['files']:
        if Path(name).is_absolute() or '..' in Path(name).parts:
            raise ValueError('Unsafe manifest path')
    for target, skills in data['skills'].items():
        if target not in TARGETS or any('/' in n or not n.startswith('rdd-') for n in skills):
            raise ValueError('Unsafe skill manifest')
    return data


def copy_tree(src, dst):
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True, symlinks=True,
                        ignore=shutil.ignore_patterns('__pycache__', 'cache', 'logs', '.keys', '.DS_Store'))
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def source_inventory(source):
    inventory = {}
    ignored = {'__pycache__', 'cache', 'logs', '.keys', '.DS_Store'}
    for name in ASSETS:
        base = source / name
        for file in ([base] if base.is_file() else base.rglob('*') if base.exists() else []):
            relative = file.relative_to(source)
            if ignored.intersection(relative.parts):
                continue
            if file.is_symlink():
                raise ValueError('Source assets must be real files: ' + str(file))
            if file.is_file():
                inventory[str(relative)] = file
    return inventory


def remove(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def validate_destination(path):
    # A linked parent could redirect writes outside the selected user/prefix.
    for parent in (path, *path.parents):
        if parent.is_symlink():
            raise ValueError('Refusing symlink destination: ' + str(parent))


def install(args):
    source = Path(args.source or ROOT).resolve()
    prefix = Path(args.prefix).expanduser().absolute()
    if prefix.is_symlink():
        raise ValueError('Installation prefix must not be a symlink')
    prefix = prefix.parent.resolve() / prefix.name
    home = Path(args.user_home or read_manifest(prefix).get('user_home', str(Path.home()))).expanduser().resolve()
    validate_destination(prefix)
    if (prefix == source and not (prefix / MANIFEST).is_file()) or source in prefix.parents or prefix in source.parents:
        raise ValueError('Installation prefix and source must be separate trees')
    if prefix == home or prefix == Path('/') or prefix in home.parents:
        raise ValueError('Unsafe installation prefix')
    skills = sorted((source / '.claude/skills').glob('rdd-*/SKILL.md'))
    if not skills or not (source / 'scripts/install/manage.py').is_file():
        raise ValueError('Source does not contain the dual-agent RDD runtime')
    if (prefix / '.git').exists():
        raise ValueError('Refusing to install over a Git working tree')
    old = read_manifest(prefix)
    if old.get('user_home') and str(home) != old['user_home']:
        raise ValueError('User home differs from installation manifest; use a separate prefix')
    inventory = source_inventory(source)
    if source == prefix:
        inventory = {name: file for name, file in inventory.items() if name in old['files']}
    for name, src in inventory.items():
        dst = prefix / name
        if dst.exists() and name not in old['files'] and digest(dst) != digest(src) and not args.replace_skills:
            raise ValueError('Unowned runtime collision: ' + name)
    if prefix.exists() and any(prefix.iterdir()) and not (prefix / MANIFEST).exists():
        if not args.replace_skills:
            raise ValueError('Legacy/unowned prefix: use --replace-skills to back it up before migration')
    selected = list(TARGETS) if args.agent == 'both' else [args.agent] if args.agent else old['targets'] or list(TARGETS)
    targets = sorted(set(old['targets'] + selected))
    backup_root = home / '.rdd-backups' / hashlib.sha256(str(prefix).encode()).hexdigest()[:12]
    validate_destination(backup_root)
    destinations = []
    for target in targets:
        validate_destination(backup_root / target)
        root = home / TARGETS[target]
        validate_destination(root)
        for skill in skills:
            dst = root / skill.parent.name
            expected = old['skills'].get(target, {}).get(skill.parent.name)
            current = digest(dst)
            conflict = current is not None and (dst.is_symlink() or current != expected)
            if conflict and not args.replace_skills:
                raise ValueError('Preserving unowned/modified skill: %s; use --replace-skills for a backup' % dst)
            destinations.append((skill.parent, dst, conflict))
    retired_skills = []
    source_names = {s.parent.name for s in skills}
    for target, owned in old['skills'].items():
        for name, expected in owned.items():
            if name not in source_names:
                retired_skills.append((target, name, expected))
    for name, expected in old['files'].items():
        if name not in inventory and name != 'VERSION':
            continue
        current = digest(prefix / name)
        if current is not None and current != expected and not args.replace_skills:
            raise ValueError('Modified runtime file: %s; use --replace-skills for a backup' % name)
    if args.dry_run:
        print('Would install %s into %s (%d skills)' % (','.join(targets), prefix, len(skills)))
        return
    prefix.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix='.rdd-stage-', dir=prefix.parent))
    swaps = []
    try:
        runtime = staging / 'runtime'
        runtime.mkdir()
        # Preserve unrelated files in an existing prefix, including old backups.
        if prefix.exists():
            shutil.copytree(prefix, runtime, dirs_exist_ok=True, symlinks=True)
        for name, src in inventory.items():
            dst = runtime / name
            validate_destination(dst)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        retained_files = {}
        for name, expected in old['files'].items():
            if name not in inventory and name != 'VERSION':
                dst = runtime / name
                validate_destination(dst)
                if digest(dst) == expected:
                    remove(dst)
                elif dst.exists():
                    retained_files[name] = expected
                    print('Preserved modified retired runtime asset: ' + name)
        selected_version = args.version or (old.get('version') if source == prefix else None) or json.loads((source / 'package.json').read_text())['version']
        (runtime / 'VERSION').write_text(selected_version)
        files = {name: digest(runtime / name) for name in inventory}
        files['VERSION'] = digest(runtime / 'VERSION')
        files.update(retained_files)
        manifest = {'schema': 1, 'owner': 'rdd', 'version': (runtime / 'VERSION').read_text(),
                    'targets': targets, 'user_home': str(home), 'skills': {}, 'files': files}
        for index, (src, dst, conflict) in enumerate(destinations):
            staged = staging / ('skill-%d' % index)
            copy_tree(src, staged)
            target = next(t for t in targets if dst.parent == home / TARGETS[t])
            manifest['skills'].setdefault(target, {})[src.name] = digest(staged)
            swaps.append((staged, dst, conflict))
        for target, name, expected in retired_skills:
            dst = home / TARGETS[target] / name
            if digest(dst) == expected and not dst.is_symlink():
                swaps.append((None, dst, False))
            elif dst.exists() or dst.is_symlink():
                manifest['skills'].setdefault(target, {})[name] = expected
                print('Preserved modified retired skill: ' + str(dst))
        (runtime / MANIFEST).write_text(json.dumps(manifest, indent=2) + '\n')
        swaps.append((runtime, prefix, bool(args.replace_skills)))
        committed = []
        try:
            for staged, dst, keep_backup in swaps:
                if staged is not None and not dst.is_symlink() and digest(staged) == digest(dst):
                    continue
                dst.parent.mkdir(parents=True, exist_ok=True)
                backup = dst.with_name(dst.name + '.rdd-backup-' + uuid.uuid4().hex[:10])
                for target in targets:
                    if dst.parent == home / TARGETS[target]:
                        backup = backup_root / target / backup.name
                        backup.parent.mkdir(parents=True, exist_ok=True)
                        break
                had_original = dst.exists() or dst.is_symlink()
                if had_original:
                    dst.rename(backup)
                committed.append((dst, backup, had_original, keep_backup))
                if staged is None:
                    continue
                # Move across filesystems safely via a temporary sibling.
                incoming = dst.with_name('.rdd-incoming-' + uuid.uuid4().hex[:10])
                try:
                    shutil.copytree(staged, incoming, symlinks=True)
                    incoming.rename(dst)
                finally:
                    remove(incoming)
        except BaseException:
            for dst, backup, had_original, _ in reversed(committed):
                remove(dst)
                if had_original:
                    backup.rename(dst)
            raise
        for _, backup, had_original, keep_backup in committed:
            if had_original:
                if keep_backup:
                    print('Backup preserved: ' + str(backup))
                else:
                    remove(backup)
    finally:
        remove(staging)
    print('Installed RDD for %s: %s' % (', '.join(targets), prefix))
    print('CLI: %s/bin/rdd' % prefix)
    print('Claude Code: /rdd-help    Codex CLI/IDE: $rdd-help')
    print('Add %s/bin to PATH if needed. Existing client settings were preserved.' % prefix)


def uninstall(args):
    prefix = Path(args.prefix).expanduser().absolute()
    if prefix.is_symlink():
        raise ValueError('Installation prefix must not be a symlink')
    prefix = prefix.parent.resolve() / prefix.name
    validate_destination(prefix)
    if not (prefix / MANIFEST).is_file():
        raise ValueError('No owned installation manifest; refusing to remove ' + str(prefix))
    manifest = read_manifest(prefix)
    home = Path(args.user_home or read_manifest(prefix).get('user_home', str(Path.home()))).expanduser().resolve()
    if str(home) != manifest['user_home']:
        raise ValueError('User home differs from installation manifest')
    retained = []
    for target, skills in manifest['skills'].items():
        validate_destination(home / TARGETS[target])
        for name, expected in skills.items():
            dst = home / TARGETS[target] / name
            if digest(dst) == expected and not dst.is_symlink():
                remove(dst)
            elif dst.exists() or dst.is_symlink():
                retained.append(str(dst))
    for name, expected in manifest['files'].items():
        file = prefix / name
        # Never traverse a parent replaced with a symlink since installation.
        if any(p.is_symlink() for p in file.parents):
            retained.append(str(file)); continue
        if digest(file) == expected:
            remove(file)
        elif file.exists() or file.is_symlink():
            retained.append(str(file))
    (prefix / MANIFEST).unlink()
    for directory in sorted(prefix.rglob('*'), key=lambda p: len(p.parts), reverse=True):
        if directory.is_dir() and not directory.is_symlink():
            try:
                directory.rmdir()
            except OSError:
                pass
    try:
        prefix.rmdir()
    except OSError:
        pass
    print('Removed owned, unchanged RDD assets.')
    for file in retained:
        print('Preserved modified asset: ' + file)


def provision(args):
    """Merge fresh generated project assets without overwriting existing user files."""
    project = Path(args.project).absolute()
    if project.is_symlink():
        raise ValueError('Project directory must not be a symlink')
    project = project.parent.resolve() / project.name
    project.mkdir(parents=True, exist_ok=True)
    validate_destination(project)
    runtime = ROOT
    for folder in ('tests/unit', 'tests/bdd', 'tests/e2e', 'docs/handoff', '.rdd/cache'):
        directory = project / folder
        validate_destination(directory)
        directory.mkdir(parents=True, exist_ok=True)
    def write(name, content):
        dst = project / name
        validate_destination(dst)
        if not dst.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            if args.lang == 'zh':
                translations = {
                    'docs/01-charter.md': '# 项目章程\n\n请与用户定义项目愿景、目标、非目标与可验证验收标准。\n',
                    'docs/11-next-steps.md': '# 下一步计划\n\n当前阶段：规划。先定义项目章程并批准路线图，再开始实现。Gate 3 前必须配置真实测试。\n',
                }
                content = translations.get(name, content)
            dst.write_text(content)
    for folder in ('scripts', 'hooks'):
        for src in (runtime / '.rdd' / folder).rglob('*'):
            if src.is_file():
                dst = project / '.rdd' / src.relative_to(runtime / '.rdd')
                validate_destination(dst)
                if not dst.exists():
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dst)
    for src in (runtime / '.rdd').glob('*.yml'):
        if src.name != 'config.yml':
            write('.rdd/' + src.name, src.read_text())
    write('.rdd/config.yml', 'version: "1.0.0"\nproject:\n  name: ' + json.dumps(project.name) + '\nhooks:\n  enabled: false\nstage:\n  min_coverage: 20\n')
    write('AGENTS.md', (runtime / 'AGENTS.md').read_text())
    write('CLAUDE.md', '# Claude Code entry point\n\nRead AGENTS.md for shared RDD rules.\nUse /rdd-help; Codex uses $rdd-help.\n')
    for name in ('02-engineering-principles.md', '03-stage-based-development.md', '10-review-practices.md'):
        write('docs/' + name, (runtime / 'docs' / name).read_text())
    write('docs/01-charter.md', '# Project Charter\n\nDefine the project vision, goals, non-goals and testable success criteria with the user.\n')
    write('docs/11-next-steps.md', '# Next Steps\n\nCurrent stage: planning. Define the charter and approve a roadmap before implementation. Configure real test tasks before Gate 3.\n')
    write('docs/stages/stage-roadmap.md', '# Stage Roadmap\n\nNo stages approved yet.\n\n| Stage | Status | Goal | Dependencies |\n|-------|--------|------|--------------|\n')
    write('docs/08-autonomous-decisions.md', '# Autonomous Decisions\n\nNo decisions recorded yet.\n')
    write('docs/12-technical-debt.md', '# Technical Debt Ledger\n\nNo debts recorded yet.\n')
    write('CHANGELOG.md', '# Changelog\n\n## Unreleased\n\n- Initialized RDD project.\n')
    # Full runtime task namespace, with project-specific tests deliberately unconfigured.
    import re
    taskfile = (runtime / 'Taskfile.yml').read_text()
    for name in ('test:unit', 'test:e2e', 'test:bdd', 'test:coverage'):
        block = "  %s:\n    desc: Configure project %s\n    cmds:\n      - 'echo \"Configure %s for this project before Gate 3\" >&2; exit 1'\n\n" % (name, name, name)
        taskfile, count = re.subn(r'^  ' + re.escape(name) + r':\n.*?(?=^  [\w][^\n]*:\n|\Z)', lambda m: block, taskfile, flags=re.M | re.S)
        if count != 1:
            raise ValueError('Missing project test template: ' + name)
    for name in ('test:agents', 'test:agents:coverage', 'install:agents', 'test:clean', 'test:clients', 'test:linux'):
        taskfile = re.sub(r'^  ' + re.escape(name) + r':\n.*?(?=^  [\w][^\n]*:\n|\Z)', '', taskfile, flags=re.M | re.S)
    taskfile = taskfile.replace('bash scripts/', 'bash .rdd/scripts/')
    taskname = 'Taskfile.rdd.yml' if (project / 'Taskfile.yml').exists() else 'Taskfile.yml'
    write(taskname, taskfile)
    if taskname == 'Taskfile.rdd.yml':
        print('Preserved Taskfile.yml; use task -t Taskfile.rdd.yml, then integrate RDD tasks with your existing test tasks.')
    if args.lang == 'zh':
        print('RDD 项目已就绪；请填写项目章程和路线图，并配置真实测试任务。')
    print('RDD project ready: ' + str(project))


@contextlib.contextmanager
def lifecycle_lock(args):
    prefix = Path(args.prefix).expanduser().resolve()
    manifest = read_manifest(prefix)
    home = Path(args.user_home or manifest.get('user_home', str(Path.home()))).expanduser().resolve()
    handles = []
    try:
        for key in sorted({str(prefix), str(home)}):
            token = hashlib.sha256(key.encode()).hexdigest()
            lockpath = Path(tempfile.gettempdir()) / ('rdd-lifecycle-' + token + '.lock')
            fd = os.open(lockpath, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
            handle = os.fdopen(fd, 'w')
            handles.append(handle)
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise ValueError('Another RDD lifecycle operation is active for this prefix/home')
        yield
    finally:
        for handle in reversed(handles):
            handle.close()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['install', 'uninstall', 'init', 'migrate'])
    parser.add_argument('--source')
    parser.add_argument('--prefix', default=os.environ.get('RDD_FRAMEWORK_HOME', str(Path.home() / '.rdd-framework')))
    parser.add_argument('--user-home')
    parser.add_argument('--agent', choices=['claude', 'codex', 'both'])
    parser.add_argument('--version')
    parser.add_argument('--replace-skills', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--project', default='.')
    parser.add_argument('project_name', nargs='?')
    parser.add_argument('--interactive', '-i', action='store_true')
    parser.add_argument('--lang', '-l', choices=['en', 'zh'], default='en')
    parser.add_argument('--analyze', action='store_true')
    parser.add_argument('--plan', action='store_true')
    args = parser.parse_args(argv)
    if args.project_name:
        args.project = args.project_name
    if args.interactive and args.action in ('init', 'migrate') and not args.dry_run:
        args.project = input('Project directory [%s]: ' % args.project).strip() or args.project
        args.lang = input('Document language en/zh [%s]: ' % args.lang).strip() or args.lang
        if args.lang not in ('en', 'zh'):
            parser.error('Document language must be en or zh')
    try:
        if args.dry_run and args.action != 'install':
            print('Would perform %s; no files changed.' % args.action)
            return
        if args.action in ('install', 'uninstall'):
            with lifecycle_lock(args):
                if args.action == 'install':
                    install(args)
                else:
                    uninstall(args)
        else:
            if args.analyze or args.plan:
                print('Plan: add missing shared RDD assets; preserve existing files and Taskfile.')
            else:
                provision(args)
    except (ValueError, OSError, KeyError) as error:
        parser.exit(1, 'RDD: %s\n' % error)


if __name__ == '__main__':
    main()
