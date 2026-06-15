// contextmenu-interaction.mjs <dist> — drive Hydrogen.Themes.ContextMenu. Asserts the
// DISTINGUISHING right-click behaviour: a LEFT click does NOT open; a contextmenu
// (right-click) opens the menu AT THE CURSOR; the native browser menu is prevented;
// portaled + non-modal (no scroll-lock); closes on outside-click, on Escape, and on
// selecting an item; keyboard ArrowDown highlights a row.
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
await pg.waitForTimeout(300);

const region = pg.locator(".rt-ContextMenuTriggerRegion");
const panel = pg.locator(".rt-ContextMenuContent");
const items = pg.locator(".rt-ContextMenuItem");
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  if (!(await region.count())) fail("trigger region missing");
  if (await panel.isVisible()) fail("menu visible before open");
  console.log("✓ at rest: region present, menu hidden");

  const rb = await region.boundingBox();

  // A LEFT click must NOT open the menu (the distinguishing negative).
  await pg.mouse.click(rb.x + rb.width / 2, rb.y + rb.height / 2);
  await pg.waitForTimeout(150);
  if (await panel.isVisible()) fail("left click wrongly opened the context menu");
  console.log("✓ left click does NOT open");

  // Prove the native browser context menu is prevented (defaultPrevented on the event).
  const prevented = await pg.evaluate(() => new Promise((res) => {
    const el = document.querySelector(".rt-ContextMenuTriggerRegion");
    const r = el.getBoundingClientRect();
    el.addEventListener("contextmenu", (e) => res(e.defaultPrevented), { once: true });
    el.dispatchEvent(new MouseEvent("contextmenu", {
      bubbles: true, cancelable: true,
      clientX: r.left + 40, clientY: r.top + 30,
    }));
  }));
  if (!prevented) fail("native contextmenu default was NOT prevented");
  console.log("✓ native browser context menu prevented (defaultPrevented)");
  // that synthetic event also OPENED the menu (at its coords) — close it so the
  // position test below measures the REAL right-click, not the stale dispatch.
  await pg.keyboard.press("Escape");
  await panel.waitFor({ state: "hidden", timeout: 2000 });

  // A real RIGHT click opens the menu AT THE CURSOR.
  const cx = rb.x + 60, cy = rb.y + 50;
  await pg.mouse.click(cx, cy, { button: "right" });
  await panel.waitFor({ state: "visible", timeout: 2000 });
  if ((await panel.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  // NON-modal: the page must NOT be scroll-locked.
  if ((await bodyOverflow()) === "hidden") fail("context menu wrongly scroll-locked the body (it is non-modal)");
  console.log("✓ right click opens: data-state=open, NOT scroll-locked");

  if ((await items.count()) < 1) fail("menu has no items");

  // Portaled to the body container, positioned AT the cursor (top/left ≈ clientY/clientX).
  // (the body-mount is re-asserted on requestAnimationFrame after Halogen's render.)
  await pg.waitForTimeout(120);
  const pb = await panel.boundingBox();
  const portaled = await pg.evaluate(() => {
    const p = document.querySelector(".rt-ContextMenuContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!p && !!root && root.parentElement === document.body && root.contains(p);
  });
  if (!portaled) fail("menu not body-mounted in the portal root");
  if (Math.abs(pb.x - cx) > 4) fail(`menu not at cursor X (panel.x=${pb.x}, cursor.x=${cx})`);
  if (Math.abs(pb.y - cy) > 4) fail(`menu not at cursor Y (panel.y=${pb.y}, cursor.y=${cy})`);
  console.log("✓ portal + positioned at the cursor (clientX/clientY)");

  // Keyboard: ArrowDown highlights the first row.
  await pg.keyboard.press("ArrowDown");
  await pg.waitForTimeout(60);
  const hl = await pg.locator(".rt-ContextMenuItem[data-highlighted]").count();
  if (hl !== 1) fail(`ArrowDown did not highlight exactly one row (got ${hl})`);
  console.log("✓ ArrowDown highlights a row (data-highlighted)");

  // Escape closes.
  await pg.keyboard.press("Escape");
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ Escape closes");

  // Reopen → outside click closes.
  await pg.mouse.click(cx, cy, { button: "right" });
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await pg.mouse.click(750, 600);
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ outside click closes");

  // Reopen → selecting an item closes.
  await pg.mouse.click(cx, cy, { button: "right" });
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await items.first().click();
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ selecting an item closes");

  console.log("\nℵ contextmenu-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ contextmenu-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
