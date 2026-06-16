// popover-portal.mjs <dist> — verify Hydrogen.Radix.Popover (the floating-overlay
// template, STR-335) in a real browser via the gallery's ?story=popover: the content
// is portaled to a DIRECT child of <body>, Popper positions it (data-side stamped +
// off-origin coords), focus moves into it, and Escape / outside-click dismiss it and
// restore focus to the trigger.
import { serve } from "./themes-states.mjs";
import { chromium } from "@playwright/test";

const [DIR] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1000, height: 700 } });
const content = pg.locator(".popover-content");
const trigger = pg.locator("button", { hasText: "Open" });
const fail = (m) => { throw new Error(m); };

try {
  await pg.goto(`http://127.0.0.1:${PORT}/?story=popover`);
  await pg.waitForTimeout(250);
  await trigger.click();
  await content.waitFor();
  await pg.waitForTimeout(200); // AfterOpen → reposition → finalize (portal + focus)

  // 1. portal-to-body: the content node itself is a direct child of <body>.
  const portal = await pg.evaluate(() => {
    const c = document.querySelector(".popover-content");
    return { found: !!c, parentIsBody: !!c && c.parentElement === document.body, parentTag: c && c.parentElement && c.parentElement.tagName };
  });
  if (!portal.found) fail("no .popover-content after open");
  if (!portal.parentIsBody) fail(`content not portaled to body (parent = ${portal.parentTag})`);
  console.log("✓ portal-to-body: popover content is a direct child of <body>");

  // 2. Popper positioned it: data-side stamped + content moved off the (0,0) origin.
  const pos = await pg.evaluate(() => {
    const c = document.querySelector(".popover-content");
    const r = c.getBoundingClientRect();
    return { side: c.getAttribute("data-side"), align: c.getAttribute("data-align"), x: r.x, y: r.y };
  });
  if (!pos.side || !pos.align) fail(`data-side/align not stamped (side=${pos.side}, align=${pos.align})`);
  if (pos.x <= 0 && pos.y <= 0) fail(`content not positioned by Popper (still at origin x=${pos.x}, y=${pos.y})`);
  console.log(`✓ positioned: data-side=${pos.side} data-align=${pos.align}, at (${pos.x.toFixed(0)}, ${pos.y.toFixed(0)})`);

  // 3. focus moved into the content on open.
  const focusedIn = await pg.evaluate(() => { const c = document.querySelector(".popover-content"); return !!c && !!document.activeElement && c.contains(document.activeElement); });
  if (!focusedIn) fail("focus did not move into the popover on open");
  console.log("✓ focus-on-open: focus moved into the popover");

  // 4. Escape closes (hidden) + restores focus to the trigger.
  await pg.keyboard.press("Escape");
  await pg.waitForTimeout(150);
  if (await content.isVisible().catch(() => false)) fail("Escape did not close the popover");
  const onTrigger = await pg.evaluate(() => document.activeElement && document.activeElement.textContent.trim() === "Open");
  if (!onTrigger) fail("focus did not return to the trigger after Escape");
  console.log("✓ Escape closes + restores focus to the trigger");

  // 5. outside-click dismiss: reopen, click the page body away from the content.
  await trigger.click();
  await content.waitFor();
  await pg.waitForTimeout(150);
  await pg.mouse.click(600, 450);
  await pg.waitForTimeout(150);
  if (await content.isVisible().catch(() => false)) fail("outside click did not close the popover");
  console.log("✓ outside-click dismiss");

  console.log("\nℵ popover-portal: ALL PASS");
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error("\nℵ popover-portal: FAILED — " + e.message);
  await b.close(); closeSrv();
  process.exit(1);
}
