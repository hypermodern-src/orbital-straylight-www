#!/usr/bin/env bash
# tooltip-verify.sh — build the Tooltip demo + drive its interaction gate. Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.tooltip-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/tooltip:app --out "$DIST" >/tmp/tooltip-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/tooltip-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/tooltip-interaction.mjs "$DIST"
