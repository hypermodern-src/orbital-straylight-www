// select-interaction.mjs <dist> — drive Hydrogen.Themes.Select. Asserts the
// DISTINGUISHING selection behaviour: the trigger shows the selected label;
// opening shows the options with the selected one aria-selected + indicated;
// choosing a DIFFERENT option updates the trigger text and closes; plus the
// shared floating contract (portaled, anchored below trigger, arrow-nav + Enter
// selects, Escape closes, outside-click closes).
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

const panel = pg.locator(".rt-SelectContent");
const trigger = pg.getByRole("combobox");
const innerText = () => pg.locator(".rt-SelectTriggerInner").innerText();
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  if (!(await trigger.count())) fail("trigger (role=combobox) missing");
  if (await panel.isVisible()) fail("listbox visible before open");
  // DISTINGUISHING: trigger shows the initially-selected label.
  const t0 = (await innerText()).trim();
  if (t0 !== "Apple") fail(`trigger should show selected label 'Apple', got '${t0}'`);
  if ((await trigger.getAttribute("aria-expanded")) !== "false") fail("aria-expanded not false at rest");
  console.log("✓ at rest: trigger shows 'Apple', listbox hidden, aria-expanded=false");

  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  if ((await panel.getAttribute("role")) !== "listbox") fail("panel role not 'listbox'");
  if ((await panel.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if ((await panel.getAttribute("data-side")) !== "bottom") fail("data-side not 'bottom'");
  if ((await trigger.getAttribute("aria-expanded")) !== "true") fail("aria-expanded not true when open");
  // anchored listbox is NON-modal: must NOT scroll-lock the body.
  if ((await bodyOverflow()) === "hidden") fail("select wrongly scroll-locked the body (it is non-modal)");
  console.log("✓ open: role=listbox, data-state=open, aria-expanded=true, not scroll-locked");

  // options present, the selected one is aria-selected and has an indicator.
  const options = pg.locator(".rt-SelectItem");
  if ((await options.count()) !== 4) fail(`expected 4 options, got ${await options.count()}`);
  const apple = pg.locator('.rt-SelectItem[data-value="apple"]');
  if ((await apple.getAttribute("aria-selected")) !== "true") fail("'apple' option not aria-selected");
  if ((await apple.locator(".rt-SelectItemIndicator").count()) !== 1) fail("selected option missing indicator");
  const orange = pg.locator('.rt-SelectItem[data-value="orange"]');
  if ((await orange.getAttribute("aria-selected")) !== "false") fail("'orange' wrongly aria-selected");
  if ((await orange.locator(".rt-SelectItemIndicator").count()) !== 0) fail("unselected option has indicator");
  console.log("✓ options: 4 rendered, selected 'apple' marked aria-selected + indicator, others not");

  await pg.waitForTimeout(120);
  // portaled + anchored below the trigger (top ≈ trigger.bottom + 4, left ≈ trigger.left).
  const tb = await trigger.boundingBox();
  const pb = await panel.boundingBox();
  const portaled = await pg.evaluate(() => {
    const p = document.querySelector(".rt-SelectContent");
    const root = document.getElementById("hydrogen-portal-root");
    return !!p && !!root && root.parentElement === document.body && root.contains(p);
  });
  if (!portaled) fail("listbox not body-mounted in the portal root");
  if (!(pb.y > tb.y + tb.height - 1)) fail(`listbox not below trigger (panel.y=${pb.y}, trigger.bottom=${tb.y + tb.height})`);
  if (Math.abs(pb.x - tb.x) > 3) fail(`not align=start (panel.x=${pb.x}, trigger.x=${tb.x})`);
  console.log("✓ portal + anchored: body-mounted, below trigger, align start");

  // DISTINGUISHING: choosing a DIFFERENT option updates the trigger text + closes.
  await orange.click();
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  const t1 = (await innerText()).trim();
  if (t1 !== "Orange") fail(`trigger text did not update after selecting Orange (got '${t1}')`);
  if ((await trigger.getAttribute("aria-expanded")) !== "false") fail("aria-expanded not false after select");
  console.log("✓ select-by-click: trigger text → 'Orange', listbox closed");

  // reopen → the newly-selected option is the marked one.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  if ((await orange.getAttribute("aria-selected")) !== "true") fail("'orange' not aria-selected after reopen");
  if ((await apple.getAttribute("aria-selected")) !== "false") fail("'apple' still aria-selected after reopen");
  console.log("✓ reopen: selection persisted (Orange marked, Apple not)");

  // ArrowDown from Orange (idx 1) → Grape (idx 2), Enter selects → trigger 'Grape'.
  await pg.keyboard.press("ArrowDown");
  await pg.waitForTimeout(60);
  const hl = await pg.locator('.rt-SelectItem[data-highlighted="true"]').getAttribute("data-value");
  if (hl !== "grape") fail(`ArrowDown should highlight 'grape', highlighted='${hl}'`);
  await pg.keyboard.press("Enter");
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  const t2 = (await innerText()).trim();
  if (t2 !== "Grape") fail(`Enter did not select highlighted 'Grape' (trigger='${t2}')`);
  console.log("✓ keyboard: ArrowDown highlights next, Enter selects → 'Grape', closes");

  // reopen → Escape closes, selection unchanged.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await pg.keyboard.press("Escape");
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  if ((await innerText()).trim() !== "Grape") fail("Escape changed the selection (should be unchanged)");
  console.log("✓ Escape closes without changing selection");

  // reopen → outside click closes.
  await trigger.click();
  await panel.waitFor({ state: "visible", timeout: 2000 });
  await pg.mouse.click(700, 560);
  await panel.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ outside click closes");

  console.log("\nℵ select-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ select-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
