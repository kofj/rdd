#!/usr/bin/env python3
"""Re-run the real Task test entry in a disposable source copy, without notifications."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import sys

root = Path(__file__).resolve().parents[1]
log = root / '.rdd/cache/clean-test.log'
log.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='rdd-clean-test-') as temporary:
    source = Path(temporary).resolve() / 'source'
    shutil.copytree(root, source, symlinks=True, ignore=shutil.ignore_patterns(
        '.git', '.worktrees', 'worktrees', 'cache', 'logs', '__pycache__', 'node_modules'))
    # Real tests may run hook scripts; no configured channel is allowed to send.
    hooks = source / '.rdd/hooks.yml'
    hooks.write_text(hooks.read_text().replace('enabled: true', 'enabled: false'))
    env = {k: v for k, v in os.environ.items() if not k.startswith('RDD_') and k not in {
        'PROJECT_ROOT', 'CACHE_DIR', 'CONFIG_FILE', 'HOOKS_FILE', 'TEMPLATES_FILE', 'VERSION_FILE'}}
    env.update(PROJECT_ROOT=str(source), DRY_RUN='true')
    print('Clean verification log: ' + str(log), flush=True)
    with log.open('w') as output:
        result = subprocess.run(['task', 'test'], cwd=source, env=env, stdout=output, stderr=subprocess.STDOUT)
    text = log.read_text()
    failed = [line for line in text.splitlines() if line.startswith('not ok')]
    passed = sum(line.startswith('ok ') for line in text.splitlines())
    print('Clean Task test: %d passed; %d failed; exit %d' % (passed, len(failed), result.returncode))
    for line in failed:
        print(line)
    sys.exit(result.returncode)
