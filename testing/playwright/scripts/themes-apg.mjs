// themes-apg.mjs <dist> [<id> …] — WAI-ARIA APG keyboard-conformance gate (STR-332).
//
// Encodes the WAI-ARIA Authoring Practices key→behavior tables as executable checks
// and runs them against a dist. Validated against the REAL @radix-ui/themes golden
// (so the expectations are spec-grounded, not self-invented — the same non-circular
// discipline as the DOM oracle); then run unchanged against //examples/themes-port:app
// to prove the Hydrogen.Radix behavior layer (FocusScope / RovingFocus / DismissableLayer)
// matches the spec end-to-end. Each check cites the APG pattern it encodes.
//
// A check fails with the exact key + expected vs actual focus/selection/open-state.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";

const [DIR, ...ONLY] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;

// ── DOM probes (run in-page) ─────────────────────────────────────────────────
const activeWithin = (pg, sel) => pg.evaluate((s) => { const c = document.querySelector(s); return !!(c && document.activeElement && c.contains(document.activeElement)); }, sel);
const activeIs = (pg, sel) => pg.evaluate((s) => document.activeElement === document.querySelector(s), sel);
const highlightedText = (pg) => pg.evaluate(() => { const e = document.querySelector("[data-highlighted]"); return e ? (e.textContent || "").trim().slice(0, 40) : null; });
const visible = (pg, sel) => pg.locator(sel).first().isVisible().catch(() => false);
const ok = (cond, msg) => { if (!cond) throw new Error(msg); };
// menu/listbox item text carries the shortcut suffix ("Edit⌘ E") — match by label prefix.
// Poll: roving focus settles a frame or two after the keypress, so don't assert on a fixed delay.
const hlStarts = async (pg, label) => {
  let t = null;
  for (let i = 0; i < 20; i++) { t = await highlightedText(pg); if (t?.startsWith(label)) return; await pg.waitForTimeout(50); }
  ok(false, `expected "${label}…" highlighted (got ${t})`);
};

const triggerBtn = (pg) => pg.locator("#root").getByRole("button").first();
const selectValue = (pg) => pg.locator(".rt-SelectTrigger").textContent();

// ── the conformance checks, grouped by APG pattern ───────────────────────────
const CHECKS = [
  // Dialog (Modal) — https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
  { id: "dialog", apg: "dialog-modal", name: "open moves focus into the dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    ok(await activeWithin(pg, '[role="dialog"]'), "focus did not move into the dialog on open");
  }},
  { id: "dialog", apg: "dialog-modal", name: "Tab is trapped within the dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    for (let i = 0; i < 6; i++) await pg.keyboard.press("Tab");
    ok(await activeWithin(pg, '[role="dialog"]'), "Tab escaped the dialog (focus trap broken)");
  }},
  { id: "dialog", apg: "dialog-modal", name: "Escape closes and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(200);
    ok(!(await visible(pg, '[role="dialog"]')), "Escape did not close the dialog");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},

  // Menu Button + Menu — https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
  { id: "dropdownmenu", apg: "menu-button", name: "ArrowDown on the trigger opens and focuses the first item", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok(await activeWithin(pg, '[role="menu"]'), "menu did not receive focus");
    await hlStarts(pg, "Edit");
  }},
  // Keyboard-opened (ArrowDown opens + highlights first) — then rove from a known state.
  { id: "dropdownmenu", apg: "menu", name: "ArrowDown roves to the next item", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "Edit");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Duplicate");
  }},
  { id: "dropdownmenu", apg: "menu", name: "End highlights the last item, Home the first", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "Edit");
    await pg.keyboard.press("End"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("Home"); await hlStarts(pg, "Edit");
  }},
  { id: "dropdownmenu", apg: "menu", name: "Escape closes and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Escape did not close the menu");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},

  // Listbox (Select) — https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ (select-only)
  { id: "select", apg: "listbox", name: "open highlights the selected option", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "Apple");
  }},
  { id: "select", apg: "listbox", name: "ArrowDown roves to the next option", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Orange");
  }},
  { id: "select", apg: "listbox", name: "Enter selects the highlighted option and closes", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await pg.keyboard.press("Enter"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="listbox"]')), "Enter did not close the listbox");
    ok((await selectValue(pg))?.includes("Orange"), `trigger should now show Orange (got ${await selectValue(pg)})`);
  }},
  { id: "select", apg: "listbox", name: "Escape closes without changing the value", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="listbox"]')), "Escape did not close the listbox");
    ok((await selectValue(pg))?.includes("Apple"), `value should remain Apple (got ${await selectValue(pg)})`);
  }},

  // Tooltip — https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/
  { id: "tooltip", apg: "tooltip", name: "focus shows the tooltip", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    ok(await visible(pg, '[role="tooltip"], .rt-TooltipContent'), "tooltip did not show on focus");
  }},
  { id: "tooltip", apg: "tooltip", name: "Escape hides the tooltip", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="tooltip"]')), "Escape did not hide the tooltip");
  }},
];

const b = await chromium.launch();
let pass = 0, fail = 0; let lastApg = "";
for (const c of CHECKS) {
  if (ONLY.length && !ONLY.includes(c.id)) continue;
  const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
  try {
    await pg.goto(`http://127.0.0.1:${PORT}/?c=${c.id}`); await pg.waitForTimeout(250);
    if (c.apg !== lastApg) { console.log(`\n  ◆ ${c.id} — APG: ${c.apg}`); lastApg = c.apg; }
    await c.run(pg);
    console.log(`  ✓ ${c.name}`); pass++;
  } catch (e) {
    console.log(`  ✗ ${c.name}\n      ${e.message}`); fail++;
  } finally { await pg.close(); }
}
await b.close(); srv.close();
console.log(`\nℵ APG conformance: ${pass} pass, ${fail} fail`);
process.exit(fail ? 1 : 0);
