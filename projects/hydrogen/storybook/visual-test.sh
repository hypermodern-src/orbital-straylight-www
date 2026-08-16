#!/usr/bin/env bash
# Production visual-regression gate: (re)build the Halogen bundle + Storybook, then
# screenshot every story and sha-compare to the committed baselines (__visual__/).
#   visual-test.sh            verify (non-zero exit on any visual change)
#   visual-test.sh --update   refresh the baselines (commit the result)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
bash "$HERE/build-bundle.sh" >/dev/null
( cd "$HERE" && nix shell nixpkgs#bun -c bunx storybook build >/dev/null 2>&1 )
# Use the SAME nix-pinned Chromium as the main gate. The floating `nixpkgs#playwright-
# driver.browsers` drifts off the @playwright/test npm pin → "Executable doesn't exist".
source "$HY/testing/playwright/pinned-browsers.sh"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
# run from testing/playwright so the bare @playwright/test import resolves
( cd "$HY/testing/playwright" && nix develop "$HY" -c node scripts/storybook-visual.mjs \
    "$HERE/storybook-static" "$HERE/__visual__" "$@" )
