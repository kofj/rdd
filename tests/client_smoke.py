#!/usr/bin/env python3
"""Opt-in real-client smoke. Uses existing authentication; writes only temp fixtures/cache logs."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import json

root = Path(__file__).resolve().parents[1]
logs = root / '.rdd/cache/client-smoke'
logs.mkdir(parents=True, exist_ok=True)
env = {k: v for k, v in os.environ.items() if not k.startswith('RDD_') and k not in {'PROJECT_ROOT', 'CONFIG_FILE', 'CACHE_DIR'}}
versions = {client: subprocess.check_output([client, '--version'], text=True).strip() for client in ('claude', 'codex')}
with tempfile.TemporaryDirectory(prefix='rdd-client-smoke-') as temporary:
    base = Path(temporary).resolve()
    prefix, home, project = base / 'runtime', base / 'user', base / 'project'
    subprocess.run(['python3', str(root / 'scripts/install/manage.py'), 'install', '--source', str(root), '--prefix', str(prefix), '--user-home', str(home)], env=env, check=True, stdout=subprocess.DEVNULL)
    subprocess.run([str(prefix / 'bin/rdd'), 'init', str(project)], env=env, check=True, stdout=subprocess.DEVNULL)
    for host in ('.claude', '.agents'):
        shutil.copytree(home / host / 'skills', project / host / 'skills')
    (project / 'AGENTS.md').write_text('Isolated RDD smoke fixture. Read the requested skill. Only work here; no notifications, source edits, commits or stage completion.\n')
    (project / 'docs/11-next-steps.md').write_text('# Next Steps\n\nStage: 23. Gate: 3. Tests unconfigured; Gate 3 pending.\n')
    common = ('Read the installed shared runtime contract. Report the pending stage/gate and actual skill path. '
              'Run task test:unit once; report the nonzero exit as blocking Gate 3. Do not edit source, mark completion, or notify anyone. ')
    commands = [
        ('claude', ['claude', '-p', '--tools', 'Read,Bash', '--allowedTools', 'Read,Bash(task *)', '--no-session-persistence', '--output-format', 'json',
                    'Use /rdd-help. Run task checkpoint:save -- 23 fixture 10 and task checkpoint:show to save/read state. ' + common]),
        ('codex', ['codex', 'exec', '--ephemeral', '--sandbox', 'workspace-write', '--skip-git-repo-check', '--json',
                   'Use $rdd-help. Run task checkpoint:show to read the checkpoint left by Claude Code; do not save or change it. ' + common]),
    ]
    previous = None
    for client, command in commands:
        with (logs / (client + '.log')).open('w') as output:
            result = subprocess.run(command, cwd=project, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=180)
        if result.returncode:
            raise SystemExit('%s smoke failed (%d); see %s' % (client, result.returncode, logs))
        checkpoint = project / '.rdd/cache/checkpoints.json'
        if not checkpoint.is_file():
            raise SystemExit(client + ' did not produce/read the required checkpoint')
        current = checkpoint.read_bytes()
        if str(json.loads(current)['project']['current_stage']) != '23':
            raise SystemExit('Checkpoint did not preserve explicit Stage 23 identity')
        if previous is not None and current != previous:
            raise SystemExit('Read-only Codex recovery changed the shared checkpoint')
        previous = current
        print(client + ': exited successfully; checkpoint ' + ('saved' if client == 'claude' else 'preserved'))
    (logs / 'checkpoint.json').write_bytes(previous)
    (logs / 'versions.json').write_text(json.dumps(versions, indent=2) + '\n')
print('Inspect actual skill/command reports in ' + str(logs))
