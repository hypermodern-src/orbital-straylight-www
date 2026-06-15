// dialog-interaction.mjs <dist> — drive the Hydrogen.Themes.Dialog and assert its
// open/close behaviour. Exit 0 = all interactions pass. The behavioural gate for
// the Bucket B (overlay/portal) reference, the counterpart to the pixel gate that
// covers the at-rest components.
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

const dialog = pg.locator('[role="dialog"]');
const trigger = pg.getByRole("button", { name: "Edit profile" });
const fail = (m) => { console.error("✗ " + m); throw new Error(m); };
const bodyOverflow = () => pg.evaluate(() => document.body.style.overflow);

try {
  // 1. at rest: trigger present, no dialog, body scrollable.
  if (!(await trigger.count())) fail("trigger button missing");
  if (await dialog.count()) fail("dialog present before open");
  if ((await bodyOverflow()) === "hidden") fail("body scroll locked before open");
  console.log("✓ at rest: trigger present, no dialog, scroll unlocked");

  // 2. click trigger → dialog opens (role=dialog, data-state=open, title), scroll locked.
  await trigger.click();
  await dialog.waitFor({ state: "visible", timeout: 2000 });
  if ((await dialog.getAttribute("data-state")) !== "open") fail("data-state not 'open'");
  if (!(await pg.locator(".rt-DialogContent h1", { hasText: "Edit profile" }).count())) fail("title missing");
  if ((await bodyOverflow()) !== "hidden") fail("body scroll not locked on open");
  console.log("✓ open: dialog visible, data-state=open, title rendered, scroll locked");

  // 3. Escape closes (document-level keydown listener), scroll restored.
  await pg.keyboard.press("Escape");
  await dialog.waitFor({ state: "detached", timeout: 2000 });
  if ((await bodyOverflow()) === "hidden") fail("body scroll still locked after Escape");
  console.log("✓ Escape closes + restores scroll");

  // 4. reopen → backdrop (padding corner, away from content) closes.
  await trigger.click();
  await dialog.waitFor({ state: "visible", timeout: 2000 });
  await pg.locator(".rt-DialogScrollPadding").click({ position: { x: 6, y: 6 } });
  await dialog.waitFor({ state: "detached", timeout: 2000 });
  console.log("✓ backdrop click closes");

  // 5. reopen → a content click does NOT close (self-target guard).
  await trigger.click();
  await dialog.waitFor({ state: "visible", timeout: 2000 });
  await pg.locator(".rt-DialogContent h1").click();
  await pg.waitForTimeout(150);
  if (!(await dialog.count())) fail("content click closed the dialog (self-target guard broken)");
  console.log("✓ content click keeps dialog open");

  // 6. Save button closes.
  await pg.getByRole("button", { name: "Save" }).click();
  await dialog.waitFor({ state: "detached", timeout: 2000 });
  console.log("✓ Save closes");

  console.log("\nℵ dialog-interaction: ALL PASS");
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error("\nℵ dialog-interaction: FAILED — " + e.message);
  await b.close(); srv.close();
  process.exit(1);
}
