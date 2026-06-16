#!/usr/bin/env bash
# themes-a11y.sh [--capture|--golden] [<id> …] — the a11y oracle gate (STR-333).
#
#   --capture : build the golden, write upstream ARIA baselines + axe fingerprints to
#               testing/golden/themes/golden-aria/ (run when the component set changes).
#   --golden  : build the golden, verify it against its own committed baselines
#               (self-consistency + ARIA-snapshot stability — the non-circular check).
#   (default) : build //examples/themes-port:app and verify the port — ARIA tree ==
#               upstream and no axe violation beyond upstream's fingerprint. The gate.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"

MODE=verify; GOLDEN=0
case "${1:-}" in
  --capture) MODE=capture; GOLDEN=1; shift ;;
  --golden)  MODE=verify;  GOLDEN=1; shift ;;
esac

if [ "$GOLDEN" -eq 1 ]; then
  DIST="$HY/testing/golden/themes/dist"
  if [ ! -f "$DIST/app.js" ]; then
    echo "ℵ building golden dist (bun)"
    ( cd "$HY/testing/golden/themes" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )
  fi
else
  echo "ℵ building the Halogen port (//examples/themes-port:app)"
  DIST="$HERE/.themes-a11y-dist"; rm -rf "$DIST"
  ( cd "$HY" && nix develop -c buck2 build //examples/themes-port:app --out "$DIST" >/tmp/themes-a11y-build.log 2>&1 ) \
    || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/themes-a11y-build.log | grep -v Compiling | head; exit 1; }
fi

export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"
exec nix develop "$HY" -c node scripts/themes-a11y.mjs "$DIST" "$MODE" "$@"
