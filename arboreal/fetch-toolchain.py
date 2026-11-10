#!/usr/bin/env python3
"""Download the exact compiler archive pinned beside this script."""
import hashlib
import json
import pathlib
import sys
import tarfile
import tempfile
import urllib.request

lock = json.loads(pathlib.Path(__file__).with_name('toolchain.json').read_text())
destination = pathlib.Path(sys.argv[1]).resolve()
if destination.exists():
    raise SystemExit('Destination must not exist; refusing to overwrite a toolchain')
with tempfile.TemporaryDirectory() as temp:
    archive = pathlib.Path(temp) / lock['filename']
    with urllib.request.urlopen('https://go.dev/dl/' + lock['filename'], timeout=120) as response:
        with archive.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
    with archive.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest()
    if digest != lock['sha256']:
        raise SystemExit('Toolchain checksum mismatch')
    destination.mkdir(parents=True)
    with tarfile.open(archive) as tar:
        tar.extractall(destination, filter='data')
print(destination / 'go')
