#!/usr/bin/env bash
# hovercard-verify.sh — build the HoverCard demo + drive its interaction gate. Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.hovercard-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/hovercard:app --out "$DIST" >/tmp/hovercard-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/hovercard-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/hovercard-interaction.mjs "$DIST"
