# Shared Playwright browser pin (sourced by run.sh + every themes-*.sh wrapper).
#
# The pixel/DOM goldens were captured with a SPECIFIC Chromium, and the diff must run
# on that same one — overlay popper positioning is sub-pixel-sensitive, so a different
# Chromium build shifts the 8 floating overlays (dialog/popover/tooltip/…) past the
# maxDiffPixels budget and reds the gate. Playwright also refuses to launch unless the
# browser revision matches the @playwright/test npm version.
#
# So the browser MUST match `@playwright/test` in package.json. We get it from nix,
# but PINNED — NOT the floating `nixpkgs#` registry, which drifts (it moved to
# playwright-driver 1.60.0 / chromium 1223 while package.json pins 1.59.1 / chromium
# 1217, breaking both the launch and the goldens). This rev is the nixpkgs commit whose
# playwright-driver.version == the package.json pin.
#
# TO BUMP PLAYWRIGHT: change @playwright/test in package.json AND this rev together —
# find the nixpkgs commit where `nix eval nixpkgs#playwright-driver.version` equals the
# new npm version (git log pkgs/development/web/playwright/driver.nix) — then re-capture
# the goldens with the new browser (run.sh --update-snapshots).
PINNED_NIXPKGS="github:NixOS/nixpkgs/7cc8a6b08a51"  # playwright-driver 1.59.1 → chromium 1217
PLAYWRIGHT_BROWSERS_PATH="$(nix build "${PINNED_NIXPKGS}#playwright-driver.browsers" --no-link --print-out-paths)"
export PLAYWRIGHT_BROWSERS_PATH
