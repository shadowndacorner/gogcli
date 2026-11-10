#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GO_ROOT:?Set GO_ROOT to the verified Go 1.27.3 installation}"
export PATH="$GO_ROOT/bin:$PATH" GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off GOWORK=off CGO_ENABLED=0 GOOS=linux GOARCH=amd64
export GOENV=off GOFLAGS='-mod=vendor -p=2' GOMAXPROCS=2
unset GOEXPERIMENT
[[ "$(go env GOVERSION)" == go1.27.3 ]] || { echo 'Expected Go 1.27.3' >&2; exit 1; }
sha256sum --check --quiet arboreal/vendor.sha256
mkdir -p bin
# Generated policy is included only in this restricted build.
generated=internal/cmd/safety_profile_baked_gen.go
[[ ! -e "$generated" ]] || { echo "Refusing to overwrite $generated" >&2; exit 1; }
trap 'rm -f "$generated"' EXIT
go run ./cmd/bake-safety-profile arboreal/drive.yaml "$generated"
go build -trimpath -buildvcs=false -tags safety_profile \
  -ldflags='-buildid= -X github.com/openclaw/gogcli/internal/cmd.version=v0.48.0-arboreal-personal-google -X github.com/openclaw/gogcli/internal/cmd.commit=f939ed37151af5b789ac08b98339fe8ddf880b09' \
  -o bin/gog-drive ./cmd/gog
sha256sum bin/gog-drive
