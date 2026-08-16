#!/usr/bin/env bash
# themes-apg.sh [--golden] [<id> …] — WAI-ARIA APG keyboard-conformance gate (STR-332).
#
#   --golden : run the conformance checks against the real @radix-ui/themes golden —
#              validates that the encoded key→behavior tables are spec-grounded (they
#              must pass on upstream, the non-circular check).
#   (default): build //examples/themes-interactive:app and run the SAME checks against it —
#              the gate proving the Hydrogen.Radix behavior layer matches the APG (the 8
#              overlays + the 6 stateful non-overlay patterns all render drivably there).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"

GOLDEN=0; if [ "${1:-}" = "--golden" ]; then GOLDEN=1; shift; fi

if [ "$GOLDEN" -eq 1 ]; then
  DIST="$HY/testing/golden/themes/dist"
  if [ ! -f "$DIST/app.js" ]; then
    echo "ℵ building golden dist (bun)"
    ( cd "$HY/testing/golden/themes" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )
  fi
else
  echo "ℵ building the Halogen port (//examples/themes-interactive:app)"
  DIST="$HERE/.themes-apg-dist"; rm -rf "$DIST"
  ( cd "$HY" && nix develop -c buck2 build //examples/themes-interactive:app --out "$DIST" >/tmp/themes-apg-build.log 2>&1 ) \
    || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/themes-apg-build.log | grep -v Compiling | head; exit 1; }
fi

source "$HERE/pinned-browsers.sh"  # pinned, version-matched browser set (see that file)
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"
exec nix develop "$HY" -c node scripts/themes-apg.mjs "$DIST" "$@"
