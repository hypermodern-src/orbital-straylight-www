// Capture the GOLDEN set: radix-ui's own Storybook render of each story, the
// pixel reference the Halogen gallery is diffed against (radix-ui/primitives is
// MIT, (c) WorkOS). Run once when the story set changes; goldens are committed.
//
// Flow (heavy — the only step that touches radix's React/pnpm toolchain, kept
// here at the test edge, never in the buck2 core):
//   1. Build radix's storybook to static HTML in the vendor clone:
//        ( cd ~/src/vendor/primitives && pnpm install && pnpm run storybook:build )
//      → ~/src/vendor/primitives/apps/storybook/storybook-static
//   2. Serve it, navigate the per-story iframe, screenshot the story canvas into
//      ./golden/<id>.png at the SAME viewport/DPR/Chromium as playwright.config.ts
//      so the comparison is apples-to-apples (font rendering included).
//
// Story id ↔ golden name map (extend as the gallery grows). Storybook iframe URL:
//   <static>/iframe.html?id=components-<kebab>--<story>&viewMode=story
import { chromium } from "@playwright/test";

const STATIC =
  process.env.RADIX_STORYBOOK_STATIC ??
  `${process.env.HOME}/src/vendor/primitives/apps/storybook/storybook-static`;
const PORT = 6199;

// golden id → storybook story id
const STORIES = [
  { id: "checkbox", story: "components-checkbox--styled" },
  // … one per reproduced story
];

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";

const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".png": "image/png", ".svg": "image/svg+xml", ".woff2": "font/woff2", ".woff": "font/woff", ".ttf": "font/ttf" };

const server = createServer(async (req, res) => {
  try {
    let p = decodeURIComponent(req.url.split("?")[0]);
    if (p === "/") p = "/index.html";
    const buf = await readFile(join(STATIC, p));
    res.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream");
    res.end(buf);
  } catch {
    res.statusCode = 404;
    res.end("not found");
  }
});

await new Promise((r) => server.listen(PORT, "127.0.0.1", r));
const browser = await chromium.launch({
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});
const page = await browser.newPage({ viewport: { width: 900, height: 600 }, deviceScaleFactor: 1 });
for (const s of STORIES) {
  await page.goto(`http://127.0.0.1:${PORT}/iframe.html?id=${s.story}&viewMode=story`);
  await page.waitForLoadState("networkidle");
  await page.screenshot({ path: `./golden/${s.id}.png`, fullPage: true });
  console.log(`golden: ${s.id} <- ${s.story}`);
}
await browser.close();
server.close();
