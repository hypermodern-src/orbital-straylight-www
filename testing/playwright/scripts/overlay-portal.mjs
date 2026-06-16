// overlay-portal.mjs <dist> <storyId> — portal/focus/dismiss check for the fanned-out
// overlays (STR-335), via the gallery's ?story=<id>. Modal overlays portal a WRAPPER
// (content.parent.parent === body) and focus-trap; floating/hover overlays portal the
// content itself (content.parent === body), position via Popper, and don't take focus.
import { serve } from "./themes-states.mjs";
import { chromium } from "@playwright/test";

const CFG = {
  "alert-dialog": { kind: "modal", role: "alertdialog", trigger: "Delete account", content: '[role="alertdialog"]', focus: true },
  "tooltip": { kind: "hover", trigger: "Hover me", content: ".tooltip-content", focus: false },
  "hover-card": { kind: "hover", trigger: "Hover me", content: ".hover-card-content", focus: false },
};

const [DIR, ID] = process.argv.slice(2);
const cfg = CFG[ID];
if (!cfg) { console.error(`no config for '${ID}'`); process.exit(2); }

const { port: PORT, close: closeSrv } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1000, height: 700 } });
const content = pg.locator(cfg.content);
const trigger = pg.locator("button", { hasText: cfg.trigger });
const fail = (m) => { throw new Error(m); };

try {
  await pg.goto(`http://127.0.0.1:${PORT}/?story=${ID}`);
  await pg.waitForTimeout(250);

  // hover overlays: dispatch mouseenter directly (a top-anchored tooltip covers its own
  // trigger at the viewport edge, so Playwright's actionability-checked .hover never settles).
  if (cfg.kind === "modal") await trigger.click();
  else await trigger.dispatchEvent("mouseenter");
  await content.waitFor();
  await pg.waitForTimeout(200);

  // 1. portal-to-body
  const portal = await pg.evaluate((sel) => {
    const c = document.querySelector(sel);
    if (!c) return { found: false };
    // modal: content is inside a wrapper that is the portaled node; floating: content is.
    const wrapperToBody = c.parentElement && c.parentElement.parentElement === document.body;
    const contentToBody = c.parentElement === document.body;
    return { found: true, wrapperToBody, contentToBody };
  }, cfg.content);
  if (!portal.found) fail(`no ${cfg.content} after open`);
  const portaled = cfg.kind === "modal" ? portal.wrapperToBody : portal.contentToBody;
  if (!portaled) fail(`not portaled to body (kind=${cfg.kind}, wrapper→body=${portal.wrapperToBody}, content→body=${portal.contentToBody})`);
  console.log(`✓ portal-to-body (${cfg.kind})`);

  // 2. floating overlays are positioned by Popper (data-side stamped + off-origin)
  if (cfg.kind === "hover") {
    const pos = await pg.evaluate((sel) => { const c = document.querySelector(sel); const r = c.getBoundingClientRect(); return { side: c.getAttribute("data-side"), x: r.x, y: r.y }; }, cfg.content);
    if (!pos.side) fail("data-side not stamped");
    if (pos.x <= 0 && pos.y <= 0) fail(`not positioned (origin x=${pos.x} y=${pos.y})`);
    console.log(`✓ positioned: data-side=${pos.side} at (${pos.x.toFixed(0)}, ${pos.y.toFixed(0)})`);
  }

  // 3. modal overlays move focus into the content
  if (cfg.focus) {
    const inside = await pg.evaluate((sel) => { const c = document.querySelector(sel); return !!c && c.contains(document.activeElement); }, cfg.content);
    if (!inside) fail("focus did not move into the modal");
    console.log("✓ focus-on-open");
  }

  // 4. Escape dismisses
  await pg.keyboard.press("Escape");
  await pg.waitForTimeout(150);
  if (await content.isVisible().catch(() => false)) fail("Escape did not dismiss");
  console.log("✓ Escape dismiss");

  // 5. modal restores focus to the trigger
  if (cfg.focus) {
    const onTrigger = await pg.evaluate((t) => document.activeElement && document.activeElement.textContent.trim() === t, cfg.trigger);
    if (!onTrigger) fail("focus not restored to trigger");
    console.log("✓ focus restored to trigger");
  }

  console.log(`\nℵ overlay-portal ${ID}: ALL PASS`);
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error(`\nℵ overlay-portal ${ID}: FAILED — ${e.message}`);
  await b.close(); closeSrv();
  process.exit(1);
}
