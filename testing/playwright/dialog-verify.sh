#!/usr/bin/env bash
# dialog-verify.sh — build the Dialog demo app and drive its open/close behaviour
# (open, Escape, backdrop, self-target guard, button-close, scroll-lock). Exit 0 =
# all interactions pass. The behavioural gate for the Bucket B reference.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.dialog-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/dialog:app --out "$DIST" >/tmp/dialog-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/dialog-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/dialog-interaction.mjs "$DIST"
