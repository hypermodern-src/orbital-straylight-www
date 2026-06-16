// overlay-portal.mjs <dist> <storyId> — portal/focus/dismiss check for the fanned-out
// overlays (STR-335), via the gallery's ?story=<id>. Modal overlays portal a WRAPPER
// (content.parent.parent === body) and focus-trap; floating/hover overlays portal the
// content itself (content.parent === body), position via Popper, and don't take focus.
import { serve } from "./themes-states.mjs";
import { chromium } from "@playwright/test";

const CFG = {
  "alert-dialog": { kind: "modal", open: "click", trigger: "Delete account", content: '[role="alertdialog"]', focus: true, restore: true },
  "tooltip": { kind: "hover", open: "hover", trigger: "Hover me", content: ".tooltip-content", focus: false },
  // hover-card's trigger is an inline <a> (radix HoverCard wraps a link), not a button.
  "hover-card": { kind: "hover", open: "hover", trigger: "Hover me", triggerTag: "a", content: ".hover-card-content", focus: false },
  // menus: content (role=menu/listbox) is itself the portaled node; focus moves to an item.
  "dropdown-menu": { kind: "menu", open: "click", trigger: "Open", content: '[role="menu"]', focus: true, restore: true },
  "context-menu": { kind: "menu", open: "rightclick", trigger: "Right-click here", content: '[role="menu"]', focus: true, restore: false },
  "select": { kind: "menu", open: "click", trigger: "Pick a fruit", content: '[role="listbox"]', focus: true, restore: true },
};

const [DIR, ID] = process.argv.slice(2);
const cfg = CFG[ID];
if (!cfg) { console.error(`no config for '${ID}'`); process.exit(2); }

const { port: PORT, close: closeSrv } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1000, height: 700 } });
const content = pg.locator(cfg.content);
// context-menu's trigger is a right-clickable region, not a button — locate by text.
// hover-card's trigger is an <a> (triggerTag); others default to a button.
const trigger = cfg.open === "rightclick" ? pg.getByText(cfg.trigger, { exact: false }) : pg.locator(cfg.triggerTag ?? "button", { hasText: cfg.trigger });
const fail = (m) => { throw new Error(m); };

try {
  await pg.goto(`http://127.0.0.1:${PORT}/?story=${ID}`);
  await pg.waitForTimeout(250);

  // open: click / right-click / hover. Hover dispatches mouseenter directly (a top-anchored
  // tooltip covers its own trigger at the viewport edge, defeating actionability-checked hover).
  if (cfg.open === "click") await trigger.click();
  else if (cfg.open === "rightclick") await trigger.click({ button: "right" });
  else await trigger.dispatchEvent("mouseenter");
  await content.waitFor();
  await pg.waitForTimeout(200);

  // 1. portal-to-body. Floating/menu: the content node itself is the body child. Modal:
  // the portaled node is an ancestor (the themed anatomy nests the content under
  // overlay > scroll > scrollPadding), so walk up to a direct body child.
  const portal = await pg.evaluate((sel) => {
    const c = document.querySelector(sel);
    if (!c) return { found: false };
    const contentToBody = c.parentElement === document.body;
    let n = c, ancestorToBody = false;
    while (n && n.parentElement) { if (n.parentElement === document.body) { ancestorToBody = true; break; } n = n.parentElement; }
    return { found: true, ancestorToBody, contentToBody };
  }, cfg.content);
  if (!portal.found) fail(`no ${cfg.content} after open`);
  const portaled = cfg.kind === "modal" ? portal.ancestorToBody : portal.contentToBody;
  if (!portaled) fail(`not portaled to body (kind=${cfg.kind}, ancestor→body=${portal.ancestorToBody}, content→body=${portal.contentToBody})`);
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

  // 5. restores focus to the trigger on close
  if (cfg.restore) {
    const onTrigger = await pg.evaluate((t) => !!document.activeElement && (document.activeElement.textContent || "").includes(t), cfg.trigger);
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
