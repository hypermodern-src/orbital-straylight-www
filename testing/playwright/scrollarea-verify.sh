#!/usr/bin/env bash
# scrollarea-verify.sh — build the ScrollArea demo + drive its scroll-tracking gate
# (proportional thumb, tracks viewport scroll top→bottom→top). Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.scrollarea-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/scrollarea:app --out "$DIST" >/tmp/scrollarea-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/scrollarea-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/scrollarea-interaction.mjs "$DIST"
