#!/usr/bin/env bash
set -euo pipefail
umask 077
launcher="$(readlink -f -- "${BASH_SOURCE[0]}")"
root="$(cd -- "$(dirname -- "$launcher")/.." && pwd)"
for variable in GOG_GOOGLE_API_BASE_URL GOG_DISCOVERY_BASE_URL GOG_PHOTOS_BASE_URL GOG_PHOTOS_PICKER_BASE_URL; do
  if [[ -n "${!variable:-}" ]]; then
    printf 'Refusing endpoint override %s in the controlled Drive launcher.\n' "$variable" >&2
    exit 2
  fi
done
if [[ ${GOG_KEYRING_PASSWORD+x} && -z "$GOG_KEYRING_PASSWORD" ]]; then
  printf 'Refusing an explicitly empty keyring password.\n' >&2
  exit 2
fi
export GOG_HOME="${GOG_HOME:-$HOME/.local/share/arboreal-drive-cli}"
exec "$root/vendor/gog" "$@"
