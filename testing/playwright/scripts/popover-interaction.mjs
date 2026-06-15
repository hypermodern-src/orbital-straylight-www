// popover-interaction.mjs <dist> — drive Hydrogen.Themes.Popover. Asserts the
// anchored/non-modal behaviour: panel positioned below the trigger, NO scroll-lock,
// closes on outside-click + Escape, stays open on an inside click, toggles.
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

const panel = pg.locator(".rt-PopoverContent");
const trigger = pg.getByRole("button", { name: "Comments" });
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  if (!(await trigger.count())) fail("trigger missing");
  if (await panel.isVisible()) fail("panel visible before open");
  console.log("✓ at rest: trigger present, panel hidden");

  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  if ((await panel.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if ((await panel.getAttribute("data-side")) !== "bottom") fail("data-side not 'bottom'");
  // NON-modal: the page must NOT be scroll-locked.
  if ((await bodyOverflow()) === "hidden") fail("popover wrongly scroll-locked the body (it is non-modal)");
  console.log("✓ open: data-state=open, data-side=bottom, NOT scroll-locked");

  await pg.waitForTimeout(120);
  // portaled + anchored below the trigger (top ≈ trigger.bottom + 8, left ≈ trigger.left).
  const tb = await trigger.boundingBox();
  const pb = await panel.boundingBox();
  const portaled = await pg.evaluate(() => {
    const p = document.querySelector(".rt-PopoverContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!p && !!root && root.parentElement === document.body && root.contains(p);
  });
  if (!portaled) fail("panel not body-mounted in the portal root");
  if (!(pb.y > tb.y + tb.height - 1)) fail(`panel not below trigger (panel.y=${pb.y}, trigger.bottom=${tb.y + tb.height})`);
  if (Math.abs(pb.y - (tb.y + tb.height + 8)) > 3) fail(`sideOffset wrong (panel.y=${pb.y}, expected≈${tb.y + tb.height + 8})`);
  if (Math.abs(pb.x - tb.x) > 3) fail(`not align=start (panel.x=${pb.x}, trigger.x=${tb.x})`);
  console.log("✓ portal + anchored: body-mounted, below trigger at sideOffset 8, align start");

  // inside click keeps it open.
  await panel.click({ position: { x: 5, y: 5 } });
  await pg.waitForTimeout(120);
  if (!(await panel.isVisible())) fail("inside click closed the popover");
  console.log("✓ inside click keeps open");

  // outside click closes.
  await pg.mouse.click(600, 500);
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ outside click closes");

  // reopen → Escape closes.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await pg.keyboard.press("Escape");
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ Escape closes");

  // trigger toggles closed.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await trigger.click();
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ trigger toggles closed");

  console.log("\nℵ popover-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ popover-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
