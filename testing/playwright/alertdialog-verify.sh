#!/usr/bin/env bash
# alertdialog-verify.sh — build the AlertDialog demo and drive its behaviour
# (open, NO backdrop-close, Escape, button-close, scroll-lock, portal). Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.alertdialog-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/alertdialog:app --out "$DIST" >/tmp/alertdialog-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/alertdialog-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/alertdialog-interaction.mjs "$DIST"
