# Arboreal pinned personal Google build

Fork: https://github.com/shadowndacorner/gogcli

Base: upstream v0.48.0, commit `f939ed37151af5b789ac08b98339fe8ddf880b09`. The MIT license permits this fork; retain LICENSE and vendored dependency licenses.

This branch freezes the source and 2,177 vendored files. `go.mod` and `go.sum` retain the upstream dependency versions; `vendor.sha256` checks every vendored file. The compiler is Go 1.27.3, Linux amd64, pinned by archive SHA-256 in `toolchain.json`. No dependency upgrades are performed by the build.

## Rebuild

From the repository root, with Python 3.12+:

```sh
python3 arboreal/fetch-toolchain.py /absolute/new/path/go-toolchain
GO_ROOT=/absolute/new/path/go-toolchain/go ./arboreal/build.sh
```

The first command downloads the checksum-verified compiler. The second uses vendored dependencies with `GOPROXY=off`, `GOSUMDB=off`, `GOTOOLCHAIN=local`, and `GOWORK=off`. It does not run upstream Makefile targets or install scripts. This disables Go dependency fetching, not network access at the OS level. For stronger build isolation, run the second command in a network-disabled environment with the source, compiler, and writable build cache available.

Output: `bin/gog-drive`. Builds use CGO disabled, fixed platform, trimmed paths, no VCS stamping or build ID, and fixed version metadata. Two builds on the preparation host produced the same SHA-256:

`45fb623b6b84e14142cdc875d67247955f647dead5d91a0fa5327db282a3b0eb`

This demonstrates repeatability on one host, not independent reproducibility across toolchains or hosts. Verify the source commit and compiler too; a checksum manifest is not a signature and can be changed by a repository writer.

## Command policy

`drive.yaml` is compiled into the binary using upstream's safety-profile mechanism. It allows Gmail, Calendar, Drive, Docs, Sheets, Contacts, authentication, configuration, schema, and version commands. It denies token export. Unlisted service commands, generic API, MCP, and update-status commands are denied. It is not an OS sandbox, endpoint firewall, or removal of all unrelated code from the binary. OAuth scopes still control account permissions; preserve existing grants when reauthorizing. The owner has already authorized all six services. Multi-account aliases remain supported.

## Review status

Read SECURITY-REVIEW.md and VULNERABILITY-SCAN.txt before authenticating. This is a controlled build with a bounded review, **not certified clean software**. No Google credentials were supplied during preparation. Keep source, build inputs, and validation evidence together; review dependency and source diffs before updating the pin.

The agent-facing deployment instructions live at `/home/claire/src/arboreal/google-drive-cli/AGENTS.md` on the preparation host. That deployment uses this binary through its existing launcher. Never store credentials in the repository.
