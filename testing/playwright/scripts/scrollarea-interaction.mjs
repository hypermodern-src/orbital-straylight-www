// scrollarea-interaction.mjs <dist> — drive Hydrogen.Themes.ScrollArea. Asserts the
// custom thumb tracks the viewport scroll: proportional size, starts at top, moves
// down as the viewport scrolls, reaches the bottom at max scroll.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";

const [DIR] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;

const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 820, height: 640 } });
await pg.goto(`http://127.0.0.1:${PORT}/`);
await pg.waitForTimeout(350);

const root = pg.locator(".rt-ScrollAreaRoot");
const viewport = pg.locator(".rt-ScrollAreaViewport");
const scrollbar = pg.locator(".rt-ScrollAreaScrollbar");
const thumb = pg.locator(".rt-ScrollAreaThumb");
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const setScroll = (v) => viewport.evaluate((el, val) => { el.scrollTop = val === "max" ? el.scrollHeight : val; el.dispatchEvent(new Event("scroll")); }, v);

try {
  // 1. structure present.
  for (const [loc, name] of [[root, "Root"], [viewport, "Viewport"], [scrollbar, "Scrollbar"], [thumb, "Thumb"]])
    if (!(await loc.count())) fail(`rt-ScrollArea${name} missing`);
  if ((await scrollbar.getAttribute("data-orientation")) !== "vertical") fail("scrollbar not data-orientation=vertical");
  console.log("✓ structure: Root > Viewport + Scrollbar(vertical) > Thumb");

  // 2. content overflows the viewport (so it's actually scrollable).
  const geom = await viewport.evaluate((el) => ({ sh: el.scrollHeight, ch: el.clientHeight }));
  if (!(geom.sh > geom.ch + 10)) fail(`content does not overflow (scrollHeight=${geom.sh}, clientHeight=${geom.ch})`);
  console.log(`✓ content overflows: scrollHeight=${geom.sh} > clientHeight=${geom.ch}`);

  // 3. thumb is proportionally sized (smaller than the track, non-zero).
  const tb = await scrollbar.boundingBox();
  const th0 = await thumb.boundingBox();
  if (!(th0.height > 4 && th0.height < tb.height - 4)) fail(`thumb not proportionally sized (thumb=${th0.height}, track=${tb.height})`);
  // and starts at the top of the track.
  if (Math.abs(th0.y - tb.y) > 6) fail(`thumb not at top at scrollTop=0 (thumb.y=${th0.y}, track.y=${tb.y})`);
  console.log(`✓ thumb proportional (${th0.height.toFixed(0)}px of ${tb.height.toFixed(0)}px track) and at top`);

  // 4. scrolling the viewport moves the thumb DOWN, proportionally.
  await setScroll(geom.sh - geom.ch); // scroll to the bottom
  await pg.waitForTimeout(120);
  const thMax = await thumb.boundingBox();
  if (!(thMax.y > th0.y + 10)) fail(`thumb did not move down on scroll (top: ${th0.y} -> ${thMax.y})`);
  // at max scroll the thumb bottom ≈ the track bottom.
  if (Math.abs((thMax.y + thMax.height) - (tb.y + tb.height)) > 8) fail(`thumb not at bottom at max scroll (thumb.bottom=${thMax.y + thMax.height}, track.bottom=${tb.y + tb.height})`);
  console.log(`✓ thumb tracks scroll: moved ${th0.y.toFixed(0)} -> ${thMax.y.toFixed(0)}, reaches the bottom`);

  // 5. scrolling back to the top returns the thumb to the top.
  await setScroll(0);
  await pg.waitForTimeout(120);
  const thBack = await thumb.boundingBox();
  if (Math.abs(thBack.y - tb.y) > 6) fail(`thumb did not return to top (thumb.y=${thBack.y}, track.y=${tb.y})`);
  console.log("✓ thumb returns to top on scroll-to-top");

  // 6. DRAGGING the thumb down scrolls the viewport.
  const td = await thumb.boundingBox();
  await pg.mouse.move(td.x + td.width / 2, td.y + td.height / 2);
  await pg.mouse.down();
  await pg.mouse.move(td.x + td.width / 2, td.y + td.height / 2 + 70, { steps: 6 });
  await pg.mouse.up();
  await pg.waitForTimeout(120);
  const scrolled = await viewport.evaluate((el) => el.scrollTop);
  if (!(scrolled > 20)) fail(`dragging the thumb did not scroll the viewport (scrollTop=${scrolled})`);
  const thDragged = await thumb.boundingBox();
  if (!(thDragged.y > td.y + 10)) fail(`thumb did not move down on drag (${td.y} -> ${thDragged.y})`);
  console.log(`✓ thumb drag scrolls the viewport (scrollTop=${scrolled.toFixed(0)}, thumb ${td.y.toFixed(0)} -> ${thDragged.y.toFixed(0)})`);

  console.log("\nℵ scrollarea-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ scrollarea-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
