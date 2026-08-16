// themes-dom.mjs <dist> <url> [selector] — print the matched subtree (default body).
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";
const [DIR, URL, SEL] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;
const b = await chromium.launch();
const pg = await b.newPage();
await pg.goto(`http://127.0.0.1:${PORT}${URL}`); await pg.waitForTimeout(400);
const html = await pg.evaluate((sel) => {
  const root = (sel && document.querySelector(sel)) || document.querySelector("#root > *") || document.body;
  const fmt = (el, d = 0) => {
    const pad = "  ".repeat(d);
    if (el.nodeType === 3) { const t = el.textContent.trim(); return t ? pad + "#" + t : ""; }
    if (el.nodeType !== 1) return "";
    const cls = (el.getAttribute("class") || "").split(/\s+/).filter(Boolean).sort().join(" ");
    const extra = [...el.attributes].filter((a) => a.name !== "class").map((a) => `${a.name}=${a.value}`).sort().join(" ");
    const head = `${pad}<${el.tagName.toLowerCase()}${cls ? ' class="' + cls + '"' : ""}${extra ? " " + extra : ""}>`;
    const kids = [...el.childNodes].map((k) => fmt(k, d + 1)).filter(Boolean);
    return [head, ...kids].join("\n");
  };
  return fmt(root);
}, SEL);
console.log(html);
await b.close(); srv.close();
