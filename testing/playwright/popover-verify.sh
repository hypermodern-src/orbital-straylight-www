#!/usr/bin/env bash
# popover-verify.sh — build the Popover demo and drive its behaviour (anchored
# below trigger, non-modal, outside/Escape close, inside-keeps-open, toggle). Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.popover-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/popover:app --out "$DIST" >/tmp/popover-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/popover-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/popover-interaction.mjs "$DIST"
