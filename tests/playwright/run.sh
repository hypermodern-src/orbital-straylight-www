#!/usr/bin/env bash
# Bulletproof, reproducible Playwright runner.
#  * Chromium comes from nix `playwright-driver.browsers` — version-matched to the
#    @playwright/test in package.json (no system binary, no download, no drift).
#  * deps (bun, node, python3) come from nix; nothing assumed on PATH.
#  * the gallery is rebuilt from buck2 each run so the diff is never stale.
# Usage: tests/playwright/run.sh [playwright args]   (e.g. --update-snapshots)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HYDROGEN="$(cd "$HERE/../.." && pwd)"

echo "ℵ building //examples:gallery → .gallery-dist"
# wipe first: `buck2 build --out` over an EXISTING directory does not cleanly
# replace it (stale files survive and get served → the diff silently passes).
rm -rf "$HERE/.gallery-dist"
( cd "$HYDROGEN" && nix develop -c buck2 build //examples:gallery \
    --out tests/playwright/.gallery-dist >/dev/null )

# version-matched browser set (must match @playwright/test in package.json)
PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_BROWSERS_PATH
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1

# free the port hard: any orphaned http.server (e.g. from a killed run) would,
# with reuseExistingServer:false, collide; with :true it would silently serve a
# stale dist. Kill any server on it before Playwright starts its own.
pkill -f "serve.mjs .gallery-dist 3940" 2>/dev/null || true
pkill -f "http.server 3940" 2>/dev/null || true
sleep 0.5

cd "$HERE"
exec nix shell nixpkgs#bun nixpkgs#python3 --command bun run test "$@"
