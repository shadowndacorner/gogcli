# Bounded security review — 2026-11-10

## Conclusion

Suitable as a reproducible review baseline; not a guarantee against data leakage. No live Google account was authenticated. This review did not inspect every command, all dependency implementations, the compiler source, or observe live OAuth/API traffic. A frozen dependency set can freeze vulnerabilities too; update it only through reviewed changes.

## Observations

- Source is MIT-licensed. The pinned commit and compiler are recorded in README.md. Original dependency archives were obtained through proxy.golang.org with Go's checksum database enabled; `go mod verify` passed. Vendoring then froze the build inputs. The final build performs no dependency resolution over the network.
- `internal/googleauth/oauth_flow.go` uses Google's OAuth endpoint, random state checks, and PKCE verifier exchange. `oauth_network.go` defaults the callback listener to 127.0.0.1 on an ephemeral port. Explicit listener/redirect overrides exist; keep the loopback defaults for personal login.
- `internal/googleapi/client_auth.go` refreshes tokens through Google's OAuth endpoint. `internal/secrets/store.go` uses account/client-specific keyring records and verifies writes by reading them back. `vendor/github.com/99designs/keyring/file.go` encrypts file entries using JOSE password-based encryption and writes mode 0600. An explicitly empty keyring password is accepted by `internal/secrets/backend.go`; do not use one. The OS account and keyring remain part of the trust boundary.
- A source search for telemetry vendors/exporter initialization did not identify a default application telemetry uploader in internal/ or cmd/. OpenTelemetry instrumentation exists in dependencies; this is not proof of zero network disclosure. Normal Drive operations necessarily send requests to Google.
- `internal/googleapi/transport_base_url.go` permits an environment-selected API relay. It omits credentials for that relay and rejects cross-origin redirects, but request paths and upload bodies still go there. A controlled deployment must reject unintended endpoint overrides. Standard HTTP proxy environment settings and local trust roots also affect network routing.
- Verbose transport logging includes errors; auth flows print authorization URLs. File contents and account metadata are intentionally returned by CLI commands. Keep logs/transcripts private; never print exported tokens or OAuth callback URLs. This review does not establish complete error-log redaction.
- The upstream `update status` command contacts GitHub for release information; it does not install a replacement. The baked Drive profile denies it, generic API commands, MCP, and unrelated service commands. These restrictions do not remove all linked code or stop an operator replacing the binary.

## Known-vulnerability check

Pinned govulncheck v1.9.0 scanned the resulting binary and Go 1.27.3 standard library. It reported zero affected symbols and zero affected imported packages. It also reported two module-level advisories whose affected packages are not imported:

- GO-2026-6911: MCP client Location-header SSRF/credential disclosure in github.com/mark3labs/mcp-go v1.5.0; no fixed version listed by the scan.
- GO-2026-5932: unsafe/unmaintained OpenPGP package in golang.org/x/crypto v0.58.0.

See VULNERABILITY-SCAN.txt for the exact result. A symbol-based binary scan is not a complete call-graph or behavioral proof, and it only covers advisories known to that database at scan time. Do not describe this dependency graph as advisory-free.

## Remaining assurance work

For stronger assurance, review all reachable Drive/auth code and their dependencies, test real OAuth only with a disposable account, and capture destination metadata without recording credentials or file contents. Apply an independently enforced network policy if the threat model requires Google-only egress. Keep least-privilege OAuth scopes and explicit account selection. No claim of complete security clearance is made by this fork.

## Validation and deployment guard

The focused upstream OAuth/state/token/keyring/redirect/credential/read-only/baked-policy tests passed in all five selected packages (googleauth, secrets, googleapi, config, cmd). The first sandboxed attempt could not bind localhost; the successful rerun used permission to run synthetic local servers. Full upstream CI was not run. SECURITY-TESTS.txt contains the successful package results.

The deployment launcher rejects nonempty API/discovery endpoint override environment variables and explicitly empty file-keyring passwords. These guards were smoke-tested. They are convenience controls, not a firewall: direct execution of the binary, process environment/trust-root changes, and code replacement remain possible for the same OS user.

## Six-service policy correction

The owner authorized Gmail, Calendar, Drive, Docs, Sheets, and Contacts. The baked policy now permits those six services; dependencies are unchanged. The previous bounded Drive/auth review does not constitute a full audit of the newly enabled service handlers. Policy regression checks cover entry into all six services using an empty temporary credential store, plus rejection of update-status, token export, and Tasks. No real credentials or account data were accessed.
