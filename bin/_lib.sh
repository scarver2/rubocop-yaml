#!/usr/bin/env bash
# bin/_lib.sh

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BIN_DIR/.." && pwd)"
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

cd "$ROOT_DIR"

run_bundle() {
  if [[ -x "$MISE_BIN" ]]; then
    PATH="$(dirname "$MISE_BIN"):$PATH" "$MISE_BIN" exec -- bundle exec "$@"
  else
    bundle exec "$@"
  fi
}
