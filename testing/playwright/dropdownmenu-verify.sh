#!/usr/bin/env bash
# dropdownmenu-verify.sh — build the DropdownMenu demo + drive its interaction gate. Exit 0 = pass.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
DIST="$HERE/.dropdownmenu-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/dropdownmenu:app --out "$DIST" >/tmp/dropdownmenu-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/dropdownmenu-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE" && nix develop "$HY" -c node scripts/dropdownmenu-interaction.mjs "$DIST"
