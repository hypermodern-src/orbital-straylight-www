// Visual-regression gate for the Storybook: screenshot every story (animations
// frozen → deterministic) and sha-compare to a committed baseline. This is what
// @storybook/test-runner does under the hood, but over our nix-pinned Chromium and
// fully under our control (no jest/test-runner dependency surface).
//
//   node visual.mjs <storybook-static> <baseline-dir> [--update]
//
// --update (re)writes the baselines; otherwise a mismatch exits non-zero and the
// offending story ids are printed. Run via visual-test.sh, which builds first.
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, extname } from "node:path";
import { createHash } from "node:crypto";
import { chromium } from "@playwright/test";

const STATIC = process.argv[2];
const BASE = process.argv[3];
const UPDATE = process.argv.includes("--update");
const MIME = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".css": "text/css", ".json": "application/json", ".woff2": "font/woff2", ".png": "image/png", ".svg": "image/svg+xml", ".map": "application/json" };

const srv = createServer(async (q, s) => {
  let p = decodeURIComponent(q.url.split("?")[0]); if (p === "/") p = "/index.html";
  try { const b = await readFile(join(STATIC, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;

const sha = (b) => createHash("sha256").update(b).digest("hex");
const index = JSON.parse(await readFile(join(STATIC, "index.json"), "utf8"));
const stories = Object.values(index.entries).filter((e) => e.type === "story");
stories.sort((a, b) => a.id.localeCompare(b.id));

await mkdir(BASE, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 600, height: 400 }, deviceScaleFactor: 2 });

let pass = 0, wrote = 0; const fail = [];
for (const s of stories) {
  await page.goto(`http://127.0.0.1:${PORT}/iframe.html?id=${s.id}&viewMode=story`);
  await page.waitForTimeout(450);
  const buf = await page.screenshot({ fullPage: true, animations: "disabled" });
  const bpath = join(BASE, s.id + ".png");
  if (UPDATE || !existsSync(bpath)) { await writeFile(bpath, buf); wrote++; continue; }
  if (sha(buf) === sha(await readFile(bpath))) pass++; else fail.push(s.id);
}
await browser.close();
srv.close();

if (wrote) console.log(`ℵ wrote ${wrote} baselines → ${BASE}`);
if (!UPDATE) {
  console.log(`ℵ visual: ${pass}/${stories.length} match` + (fail.length ? `, ${fail.length} CHANGED` : ""));
  if (fail.length) { console.log("CHANGED: " + fail.join(", ")); process.exitCode = 1; }
}
