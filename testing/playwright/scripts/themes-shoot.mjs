// themes-shoot.mjs <dist> <url> <out> — fullPage screenshot at a fixed viewport.
// Ephemeral port (listen 0) so parallel worktree agents never collide.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";
const [DIR, URL, OUT] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 820, height: 640 }, deviceScaleFactor: 2 });
await pg.goto(`http://127.0.0.1:${PORT}${URL}`);
await pg.waitForTimeout(450);
await pg.screenshot({ path: OUT, fullPage: true });
await b.close(); srv.close();
console.log(OUT);
