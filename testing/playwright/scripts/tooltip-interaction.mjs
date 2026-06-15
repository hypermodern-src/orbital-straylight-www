// tooltip-interaction.mjs <dist> — drive Hydrogen.Themes.Tooltip. Asserts the
// DISTINGUISHING hover behaviour: a CLICK does NOT open it; HOVER opens it after a
// delay; the tooltip text is present and portaled; mouse-leave closes it; the panel
// is placed ABOVE the trigger (side=bottom); Escape closes.
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

const panel = pg.locator(".rt-TooltipContent");
const text = pg.locator(".rt-TooltipText");
const trigger = pg.getByRole("button", { name: "Hover me" });
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  if (!(await trigger.count())) fail("trigger missing");
  if (await panel.isVisible()) fail("panel visible before hover");
  console.log("✓ at rest: trigger present, panel hidden");

  // DISTINGUISHING: there is NO click-to-open path — a click does not INSTANTLY open
  // the tooltip (only a sustained hover + delay does). Clicking necessarily hovers, so
  // we check it isn't open the instant the click lands, then leave before the delay.
  await trigger.click();
  if (await panel.isVisible()) fail("click instantly opened the tooltip (must be hover+delay driven, no onClick)");
  await pg.mouse.move(700, 550); // leave before the ~200ms delay → the open is cancelled
  await pg.waitForTimeout(300);
  if (await panel.isVisible()) fail("tooltip opened without a sustained hover");
  console.log("✓ no click-to-open path (needs a sustained hover)");

  // DISTINGUISHING: a fleeting hover (shorter than the open delay) must NOT open it.
  await trigger.hover();
  await pg.waitForTimeout(80);
  await pg.mouse.move(700, 550); // leave before the ~200ms delay elapses
  await pg.waitForTimeout(250);
  if (await panel.isVisible()) fail("fleeting hover opened the tooltip (hover-intent delay not honoured)");
  console.log("✓ fleeting hover does NOT open (hover-intent delay)");

  // HOVER and stay → opens after the delay. (Move the OS pointer to the trigger
  // centre explicitly — more reliable than .hover() right after a move-away.)
  const tb = await trigger.boundingBox();
  await pg.mouse.move(tb.x + tb.width / 2, tb.y + tb.height / 2);
  await panel.waitFor({ state: "visible", timeout: 3000 });
  if ((await panel.getAttribute("data-state")) !== "delayed-open") fail("data-state not 'delayed-open'");
  if ((await panel.getAttribute("data-side")) !== "bottom") fail("data-side not 'bottom'");
  if ((await panel.getAttribute("role")) !== "tooltip") fail("role not 'tooltip'");
  if ((await bodyOverflow()) === "hidden") fail("tooltip wrongly scroll-locked the body (it is non-modal)");
  if ((await text.count()) !== 1) fail("rt-TooltipText missing");
  const txt = (await text.innerText()).trim();
  if (!txt.length) fail("tooltip text is empty");
  console.log(`✓ hover opens: data-state=delayed-open, side=bottom, role=tooltip, text="${txt}"`);

  await pg.waitForTimeout(120);
  // portaled + placed BELOW the trigger (panel.top ≈ trigger.bottom + 4).
  const pb = await panel.boundingBox();
  const portaled = await pg.evaluate(() => {
    const p = document.querySelector(".rt-TooltipContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!p && !!root && root.parentElement === document.body && root.contains(p);
  });
  if (!portaled) fail("panel not body-mounted in the portal root");
  if (!(pb.y > tb.y + tb.height - 1)) fail(`panel not below trigger (panel.top=${pb.y}, trigger.bottom=${tb.y + tb.height})`);
  if (Math.abs(pb.y - (tb.y + tb.height + 4)) > 3) fail(`sideOffset wrong (panel.top=${pb.y}, expected≈${tb.y + tb.height + 4})`);
  if (Math.abs(pb.x - tb.x) > 3) fail(`not align=start (panel.x=${pb.x}, trigger.x=${tb.x})`);
  console.log("✓ portal + anchored: body-mounted, below trigger at sideOffset 4, align start");

  // mouse-leave closes.
  await pg.mouse.move(700, 550);
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ mouse-leave closes");

  // reopen via hover → Escape closes.
  await trigger.hover();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await pg.keyboard.press("Escape");
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ Escape closes");

  console.log("\nℵ tooltip-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ tooltip-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
