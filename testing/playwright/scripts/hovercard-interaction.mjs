// hovercard-interaction.mjs <dist> — drive Hydrogen.Themes.HoverCard. Asserts the
// HOVER-INTENT + STAYS-OPEN-OVER-CARD behaviour that distinguishes it from Popover:
//   * hover the trigger → after openDelay the card opens (no click).
//   * move the pointer FROM the trigger INTO the card → it must STAY open (the
//     mouseleave on the trigger that lands inside the card does not close it).
//   * leave BOTH → after closeDelay the card closes.
//   * anchored below the trigger (sideOffset 8, align start), portaled, NON-modal.
//   * Escape closes.
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

const card = pg.locator(".rt-HoverCardContent");
const trigger = pg.locator(".rt-HoverCardTrigger");
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

// Move the OS-level pointer to the centre of a Playwright locator.
const hoverCenter = async (loc) => {
  const bb = await loc.boundingBox();
  if (!bb) fail("element has no bounding box to hover");
  await pg.mouse.move(bb.x + bb.width / 2, bb.y + bb.height / 2);
};

try {
  if (!(await trigger.count())) fail("trigger missing");
  if (await card.isVisible()) fail("card visible before hover");
  console.log("✓ at rest: trigger present, card hidden");

  // hover the trigger → opens after openDelay (~200ms). No click.
  await hoverCenter(trigger);
  await card.waitFor({ state: "visible", timeout: 2000 });
  if ((await card.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if ((await card.getAttribute("data-side")) !== "bottom") fail("data-side not 'bottom'");
  if ((await bodyOverflow()) === "hidden") fail("hover card wrongly scroll-locked the body (it is non-modal)");
  console.log("✓ hover opens: data-state=open, data-side=bottom, NOT scroll-locked");

  await pg.waitForTimeout(120);
  // portaled + anchored below the trigger (top ≈ trigger.bottom + 8, left ≈ trigger.left).
  const tb = await trigger.boundingBox();
  const cb = await card.boundingBox();
  const portaled = await pg.evaluate(() => {
    const c = document.querySelector(".rt-HoverCardContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!c && !!root && root.parentElement === document.body && root.contains(c);
  });
  if (!portaled) fail("card not body-mounted in the portal root");
  if (!(cb.y > tb.y + tb.height - 1)) fail(`card not below trigger (card.y=${cb.y}, trigger.bottom=${tb.y + tb.height})`);
  if (Math.abs(cb.y - (tb.y + tb.height + 8)) > 3) fail(`sideOffset wrong (card.y=${cb.y}, expected≈${tb.y + tb.height + 8})`);
  if (Math.abs(cb.x - tb.x) > 3) fail(`not align=start (card.x=${cb.x}, trigger.x=${tb.x})`);
  console.log("✓ portal + anchored: body-mounted, below trigger at sideOffset 8, align start");

  // DISTINGUISHING: move the pointer FROM the trigger INTO the card. This fires a
  // mouseleave on the trigger AND a mouseenter on the card. The card MUST stay open.
  await hoverCenter(card);
  // wait well past closeDelay (150ms) to prove the leave-trigger close was cancelled.
  await pg.waitForTimeout(400);
  if (!(await card.isVisible())) fail("moving from trigger into the card closed it (hover-intent broken)");
  if ((await card.getAttribute("data-state")) !== "open") fail("card data-state flipped closed while hovered");
  console.log("✓ STAYS OPEN: pointer moved trigger→card keeps it open");

  // also prove hovering deep inside the card keeps it open.
  await card.hover();
  await pg.waitForTimeout(250);
  if (!(await card.isVisible())) fail("hovering inside the card closed it");
  console.log("✓ hovering inside the card holds it open");

  // leave BOTH → closes after closeDelay.
  await pg.mouse.move(700, 580);
  await card.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ leaving both closes after closeDelay");

  // reopen via hover → Escape closes.
  await hoverCenter(trigger);
  await card.waitFor({ state: "visible", timeout: 2000 });
  await pg.keyboard.press("Escape");
  await card.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ Escape closes");

  console.log("\nℵ hovercard-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ hovercard-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
