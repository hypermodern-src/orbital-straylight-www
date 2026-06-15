#!/usr/bin/env bash
# contextmenu-verify.sh — build the ContextMenu demo + drive its interaction gate. Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.contextmenu-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/contextmenu:app --out "$DIST" >/tmp/contextmenu-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/contextmenu-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/contextmenu-interaction.mjs "$DIST"
