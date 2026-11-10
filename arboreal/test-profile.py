#!/usr/bin/env python3
"""Check command policy without accessing real credentials or account data."""
import pathlib
import subprocess
import tempfile
binary = str(pathlib.Path(__file__).resolve().parents[1] / 'bin/gog-drive')
allowed = [ ['calendar', 'list'], ['gmail', 'search', 'test'], ['drive', 'ls'],
            ['docs', 'info', 'test-document'], ['sheets', 'metadata', 'test-sheet'], ['contacts', 'list'] ]
blocked = [['update', 'status'], ['auth', 'tokens', 'export', 'test@example.invalid'], ['tasks', 'lists']]
with tempfile.TemporaryDirectory() as root:
    env = {'PATH': '/usr/bin:/bin', 'HOME': root, 'GOG_HOME': root + '/gog'}
    for args in allowed:
        result = subprocess.run([binary, '--account', 'test@example.invalid', '--no-input', *args], env=env, capture_output=True, text=True)
        assert result.returncode == 10 and 'OAuth client credentials missing' in result.stderr, (args, result.returncode, result.stderr)
        print('Allowed, stopped before OAuth:', ' '.join(args))
    for args in blocked:
        result = subprocess.run([binary, '--no-input', *args], env=env, capture_output=True, text=True)
        assert result.returncode == 2 and 'baked safety profile' in result.stderr, (args, result.returncode, result.stderr)
        print('Blocked:', ' '.join(args))
