// alertdialog-interaction.mjs <dist> — drive Hydrogen.Themes.AlertDialog. Like the
// Dialog gate, but asserts the forced-decision behaviour: a backdrop click does NOT
// close it (only the action buttons / Escape do).
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

const ad = pg.locator('[role="alertdialog"]');
const trigger = pg.getByRole("button", { name: "Revoke access" }).first();
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  if (!(await trigger.count())) fail("trigger missing");
  if (await ad.isVisible()) fail("alertdialog visible before open");
  console.log("✓ at rest: trigger present, alertdialog hidden");

  await trigger.click();
  await ad.waitFor({ state: "visible", timeout: 2000 });
  if ((await ad.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if ((await bodyOverflow()) !== "hidden") fail("scroll not locked on open");
  console.log("✓ open: role=alertdialog, data-state=open, scroll locked");

  await pg.waitForTimeout(120);
  const portaled = await pg.evaluate(() => {
    const ov = document.querySelector(".rt-AlertDialogOverlay");
    const root = document.getElementById("hydrogen-portal-root");
    return !!ov && !!root && root.parentElement === document.body && root.contains(ov);
  });
  if (!portaled) fail("overlay not body-mounted in the portal root");
  console.log("✓ portal: overlay body-mounted");

  // THE distinguishing behaviour: a backdrop click must NOT close an alert dialog.
  await pg.locator(".rt-AlertDialogScrollPadding").click({ position: { x: 6, y: 6 } });
  await pg.waitForTimeout(150);
  if (!(await ad.isVisible())) fail("backdrop click closed the alert dialog (must be a forced decision)");
  console.log("✓ backdrop click does NOT close (forced decision)");

  // Escape closes + restores scroll.
  await pg.keyboard.press("Escape");
  await ad.waitFor({ state: "hidden", timeout: 2000 });
  if ((await bodyOverflow()) === "hidden") fail("scroll still locked after Escape");
  console.log("✓ Escape closes + restores scroll");

  // an action button (Cancel) closes.
  await trigger.click();
  await ad.waitFor({ state: "visible", timeout: 2000 });
  await pg.getByRole("button", { name: "Cancel" }).click();
  await ad.waitFor({ state: "hidden", timeout: 2000 });
  console.log("✓ Cancel closes");

  console.log("\nℵ alertdialog-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ alertdialog-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
