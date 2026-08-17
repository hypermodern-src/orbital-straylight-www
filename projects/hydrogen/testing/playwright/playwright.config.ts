import { defineConfig } from "@playwright/test";

// Pixel-perfect comparison of the Hydrogen.Radix Halogen gallery against the
// golden set (radix-ui Storybook render, captured by scripts/capture-goldens.mjs).
// Bulletproof/reproducible: Playwright uses ITS OWN version-matched Chromium from
// the nix `playwright-driver.browsers` set (PLAYWRIGHT_BROWSERS_PATH), NOT a system
// binary — so the @playwright/test version and the browser revision always agree.
// The same matched Chromium captures goldens AND runs the diff (run.sh wires it).

export default defineConfig({
  testDir: "./tests",
  // Goldens live here, named by the snapshot arg (e.g. checkbox.png).
  snapshotPathTemplate: "./golden/{arg}{ext}",
  forbidOnly: !!process.env.CI,
  fullyParallel: false,
  expect: {
    // threshold:0 = max per-pixel COLOR sensitivity. This is load-bearing: the
    // checkbox boxes are light gray (#efefef) on white, and pixelmatch's DEFAULT
    // threshold (0.2) treats that as "matching" — so box-size/fill changes slip
    // through silently. threshold:0 catches them. The cost is a higher but
    // DETERMINISTIC antialiasing floor: the correct gallery diffs against radix's
    // own Storybook render at ~121px of sub-pixel glyph-edge antialiasing
    // (cross-renderer: radix=React→iframe, us=Halogen→body; stable across runs,
    // NOT a layout difference). maxDiffPixels:200 absorbs that floor with headroom
    // while still failing on any real change (which moves 100s–1000s of pixels —
    // verified: a 1px box-size change fails). A rise toward 200 = investigate.
    toHaveScreenshot: { threshold: 0, maxDiffPixels: 200, animations: "disabled" },
  },
  use: {
    baseURL: "http://127.0.0.1:3940",
    launchOptions: {
      // nix sandbox-less env; PINNED version-matched Chromium from PLAYWRIGHT_BROWSERS_PATH
      // (run.sh sources pinned-browsers.sh so the revision matches @playwright/test).
      args: ["--no-sandbox", "--disable-dev-shm-usage"],
    },
    viewport: { width: 900, height: 600 },
    deviceScaleFactor: 1,
  },
  // Serve the pre-built Spago gallery dist in .gallery-dist.
  webServer: {
    // no-cache static server (see scripts/serve.mjs) keeps CSS deterministic.
    command: "bun scripts/serve.mjs .gallery-dist 3940",
    url: "http://127.0.0.1:3940",
    // NEVER reuse: an orphaned server (e.g. from a killed run) serving a stale
    // dist would silently pass every diff. Playwright always starts its own
    // against the freshly-rebuilt dist and tears it down. run.sh frees the port.
    reuseExistingServer: false,
    timeout: 30_000,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
