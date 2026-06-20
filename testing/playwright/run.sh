#!/usr/bin/env bash
# Bulletproof, reproducible Playwright runner.
#  * Chromium comes from nix `playwright-driver.browsers` — version-matched to the
#    @playwright/test in package.json (no system binary, no download, no drift).
#  * deps (bun, node, python3) come from nix; nothing assumed on PATH.
#  * the gallery is rebuilt from buck2 each run so the diff is never stale.
# Usage: testing/playwright/run.sh [playwright args]   (e.g. --update-snapshots)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HYDROGEN="$(cd "$HERE/../.." && pwd)"

echo "ℵ building //examples:gallery → .gallery-dist"
# wipe first: `buck2 build --out` over an EXISTING directory does not cleanly
# replace it (stale files survive and get served → the diff silently passes).
rm -rf "$HERE/.gallery-dist"
# Absolute --out so the harness directory can move without breaking the path.
( cd "$HYDROGEN" && nix develop -c buck2 build //examples:gallery \
    --out "$HERE/.gallery-dist" >/dev/null )

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
# Materialize the harness node_modules (gitignored; wiped by `git clean -x`). The
# nix-provided Chromium is used (PLAYWRIGHT_BROWSERS_PATH), so skip Playwright's
# own browser download during install.
if [ ! -d node_modules ]; then
  echo "ℵ installing harness deps (bun, frozen lockfile)"
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 nix shell nixpkgs#bun --command bun install --frozen-lockfile
fi
# The surface ratchet (STR-385): the gate that closes behind us. Fails if the gated-cell
# count regressed, open core debt rose, or a state-driver lost its committed golden. Runs
# BEFORE the pixel/DOM suite so a lost golden is caught fast and unambiguously.
echo "ℵ surface ratchet"
nix shell nixpkgs#nodejs --command node "$HYDROGEN/testing/surface/check.mjs"

# Behavioral-invariance gate (STR-383): the SAME primitive under every preset must have
# byte-identical behavioral DOM (only class/style differ) — the "drop any skin on" proof.
# One line per invariance subject story; the gate exits nonzero on any divergence.
echo "ℵ behavioral-invariance gate"
for s in toggle-presets presets inv-a inv-b inv-c inv-d inv-e; do
  nix shell nixpkgs#bun --command bun "$HERE/scripts/invariance.mjs" "$HERE/.gallery-dist" "$s"
done

exec nix shell nixpkgs#bun nixpkgs#python3 --command bun run test "$@"
