// No-cache static server for the gallery dist. python http.server sends a
// Last-Modified from the file mtime can make a browser revalidate and serve a
// stale style.css from a prior run. This server sends `Cache-Control: no-store` and no
// Last-Modified, so every load is fresh. Bulletproof.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";

const DIR = process.argv[2] ?? ".gallery-dist";
const PORT = Number(process.argv[3] ?? 3940);
const MIME = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
};

createServer(async (req, res) => {
  let p = decodeURIComponent(req.url.split("?")[0]);
  if (p === "/") p = "/index.html";
  try {
    const buf = await readFile(join(DIR, p));
    res.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream");
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    res.end(buf);
  } catch {
    res.statusCode = 404;
    res.end("not found");
  }
}).listen(PORT, "127.0.0.1", () => console.log(`serve ${DIR} :${PORT}`));
