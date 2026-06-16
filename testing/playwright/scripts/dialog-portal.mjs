// dialog-portal.mjs <dist> — verify Hydrogen.Radix.Dialog's portal-to-body + focus
// (STR-335) in a real browser. Drives the gallery's ?story=dialog and asserts the
// behaviors the typechecker can't: the open dialog is portaled to a DIRECT child of
// <body> (escaping its render parent), focus moves into it on open, and Escape closes
// it and restores focus to the trigger. This is the runtime gate for the portal
// substrate (the full upstream DOM match is the STR-338 Themes-preset oracle).
import { serve } from "./themes-states.mjs";
import { chromium } from "@playwright/test";

const [DIR] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1000, height: 700 } });
const fail = (m) => { throw new Error(m); };

try {
  await pg.goto(`http://127.0.0.1:${PORT}/?story=dialog`);
  await pg.waitForTimeout(250);

  const trigger = pg.locator("button", { hasText: "Open" });
  await trigger.click();
  await pg.getByRole("dialog").waitFor();
  await pg.waitForTimeout(150); // let the AfterOpen rAF (portal + focus) fire

  // 1. portal-to-body: the overlay wrapper (the dialog's parent) is a DIRECT child of
  //    <body> — i.e. it was lifted out of its Halogen render parent.
  const portal = await pg.evaluate(() => {
    const d = document.querySelector('[role="dialog"]');
    const wrap = d && d.parentElement;
    return { found: !!d, wrapParentIsBody: !!wrap && wrap.parentElement === document.body, wrapParentTag: wrap && wrap.parentElement && wrap.parentElement.tagName };
  });
  if (!portal.found) fail("no [role=dialog] after open");
  if (!portal.wrapParentIsBody) fail(`overlay not portaled to body (wrapper parent = ${portal.wrapParentTag})`);
  console.log("✓ portal-to-body: overlay wrapper is a direct child of <body>");

  // 2. focus moved into the dialog on open.
  const focusedIn = await pg.evaluate(() => { const d = document.querySelector('[role="dialog"]'); return !!d && !!document.activeElement && d.contains(document.activeElement); });
  if (!focusedIn) fail("focus did not move into the dialog on open");
  console.log("✓ focus-on-open: focus moved into the dialog");

  // 3. Escape closes (content hidden) and restores focus to the trigger.
  await pg.keyboard.press("Escape");
  await pg.waitForTimeout(150);
  const dialogHidden = !(await pg.getByRole("dialog").isVisible().catch(() => false));
  if (!dialogHidden) fail("Escape did not close the dialog");
  const onTrigger = await pg.evaluate(() => document.activeElement && document.activeElement.textContent.trim() === "Open");
  if (!onTrigger) fail("focus did not return to the trigger after Escape");
  console.log("✓ Escape closes + restores focus to the trigger");

  console.log("\nℵ dialog-portal: ALL PASS");
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error("\nℵ dialog-portal: FAILED — " + e.message);
  await b.close(); closeSrv();
  process.exit(1);
}
