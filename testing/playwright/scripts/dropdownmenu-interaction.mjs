// dropdownmenu-interaction.mjs <dist> — drive Hydrogen.Themes.DropdownMenu. Asserts
// the click-triggered anchored menu + its DISTINGUISHING behaviour: a roving keyboard
// highlight. ArrowDown moves data-highlighted onto the first item, then the next;
// ArrowUp moves it back; click/Escape/outside-click all close. Anchored below the
// trigger (align start, sideOffset 4), portaled to the body.
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

const panel = pg.locator(".rt-DropdownMenuContent");
const items = pg.locator(".rt-DropdownMenuItem");
const trigger = pg.getByRole("button", { name: "Options" });
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
// index of the menuitem carrying data-highlighted (-1 if none).
const highlightedIndex = () => pg.evaluate(() => {
  const els = Array.from(document.querySelectorAll(".rt-DropdownMenuItem"));
  return els.findIndex((e) => e.hasAttribute("data-highlighted"));
});

try {
  if (!(await trigger.count())) fail("trigger missing");
  if (await panel.isVisible()) fail("menu visible before open");
  console.log("✓ at rest: trigger present, menu hidden");

  // click opens.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  if ((await panel.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if ((await panel.getAttribute("role")) !== "menu") fail("content role not 'menu'");
  if ((await items.count()) !== 4) fail(`expected 4 menuitems, got ${await items.count()}`);
  if ((await items.first().getAttribute("role")) !== "menuitem") fail("item role not 'menuitem'");
  console.log("✓ open: role=menu, 4 menuitems, role=menuitem");

  await pg.waitForTimeout(120);
  // portaled + anchored below the trigger (top ≈ trigger.bottom + 4, left ≈ trigger.left).
  const tb = await trigger.boundingBox();
  const pb = await panel.boundingBox();
  const portaled = await pg.evaluate(() => {
    const p = document.querySelector(".rt-DropdownMenuContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!p && !!root && root.parentElement === document.body && root.contains(p);
  });
  if (!portaled) fail("menu not body-mounted in the portal root");
  if (!(pb.y > tb.y + tb.height - 1)) fail(`menu not below trigger (panel.y=${pb.y}, trigger.bottom=${tb.y + tb.height})`);
  if (Math.abs(pb.y - (tb.y + tb.height + 4)) > 3) fail(`sideOffset wrong (panel.y=${pb.y}, expected≈${tb.y + tb.height + 4})`);
  if (Math.abs(pb.x - tb.x) > 3) fail(`not align=start (panel.x=${pb.x}, trigger.x=${tb.x})`);
  console.log("✓ portal + anchored: body-mounted, below trigger at sideOffset 4, align start");

  // DISTINGUISHING: nothing highlighted on open; ArrowDown highlights the first item.
  if ((await highlightedIndex()) !== -1) fail("an item was highlighted before any ArrowDown");
  await pg.keyboard.press("ArrowDown");
  await pg.waitForTimeout(60);
  if ((await highlightedIndex()) !== 0) fail(`ArrowDown did not highlight item 0 (got ${await highlightedIndex()})`);
  // ...next ArrowDown moves the highlight to the second item.
  await pg.keyboard.press("ArrowDown");
  await pg.waitForTimeout(60);
  if ((await highlightedIndex()) !== 1) fail(`second ArrowDown did not highlight item 1 (got ${await highlightedIndex()})`);
  // ArrowUp moves it back.
  await pg.keyboard.press("ArrowUp");
  await pg.waitForTimeout(60);
  if ((await highlightedIndex()) !== 0) fail(`ArrowUp did not move highlight back to item 0 (got ${await highlightedIndex()})`);
  console.log("✓ roving highlight: ArrowDown 0→1, ArrowUp →0 (data-highlighted moves)");

  // ArrowUp from item 0 wraps to the last item.
  await pg.keyboard.press("ArrowUp");
  await pg.waitForTimeout(60);
  if ((await highlightedIndex()) !== 3) fail(`ArrowUp from 0 did not wrap to last item (got ${await highlightedIndex()})`);
  console.log("✓ wraparound: ArrowUp from first → last");

  // click on an item closes.
  await items.nth(3).click();
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ click item closes");

  // reopen → outside click closes.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
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

  console.log("\nℵ dropdownmenu-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ dropdownmenu-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
