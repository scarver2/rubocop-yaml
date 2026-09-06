#!/usr/bin/env bash
# bin/_lib.sh

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BIN_DIR/.." && pwd)"
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

cd "$ROOT_DIR"

if [[ ! -x "$MISE_BIN" ]]; then
  echo "mise was not found at $MISE_BIN; set MISE_BIN to its executable path." >&2
  exit 127
fi

run_bundle() {
  PATH="$(dirname "$MISE_BIN"):$PATH" "$MISE_BIN" exec -- bundle exec "$@"
}

