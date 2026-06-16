// themes-open-dom.mjs <dist> <id> <state> — the open-state DOM oracle (STR-331).
//
// Drives an interactive Radix Themes component (?c=<id>) into a named <state>
// (open / item-highlighted / option-selected / …) and prints the NORMALIZED DOM of
// the whole document — trigger AND portaled content — so it can be diffed against
// the Halogen port driven through the SAME state script. The external oracle: "our
// open Dialog's DOM == radix's open Dialog's DOM", not a self-written expectation.
//
// Normalization cancels the only two sources of run-to-run noise (proven by the
// self-stability check in themes-open-capture.sh — same upstream twice ⇒ identical):
//   1. radix `useId` ids (`radix-:r3:`, `:r3:`) → stable `<idN>` in first-seen order,
//      applied to id AND every reference (aria-controls/labelledby/…activedescendant).
//   2. layout-derived pixels (Popper `transform: translate(x,y)`, `--radix-*` width/
//      height vars, scroll-lock padding compensation) → `<px>`.
// Everything structural — tag tree, class SET (order-insensitive), data-*/aria-*/role,
// data-side/data-align — stays exact. Positioning is verified structurally (side/align),
// never by exact pixels (that was the magic-number trap the hand-roll fell into).
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";

const [DIR, ID, STATE = "open"] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;

// ── the per-component state scripts ─────────────────────────────────────────────
// Each puts the component into <state>; the snapshot is taken after settle().
const root = (pg) => pg.locator("#root");
const triggerButton = (pg) => root(pg).getByRole("button").first();
const settle = (pg) => pg.waitForTimeout(300); // let Popper position + presence flush

const openMenu = async (pg, click) => { await click(); await pg.locator('[role="menu"]').first().waitFor(); };

const STATES = {
  dialog: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.getByRole("dialog").waitFor(); },
  },
  alertdialog: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.getByRole("alertdialog").waitFor(); },
  },
  popover: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.locator(".rt-PopoverContent").waitFor(); },
  },
  tooltip: {
    open: async (pg) => { await triggerButton(pg).hover(); await pg.getByRole("tooltip").waitFor(); },
  },
  hovercard: {
    open: async (pg) => { await root(pg).getByRole("link").first().hover(); await pg.locator(".rt-HoverCardContent").waitFor(); },
  },
  dropdownmenu: {
    // freshly open: roving focus on the menu, no item highlighted yet.
    open: async (pg) => openMenu(pg, () => triggerButton(pg).click()),
    // ArrowDown twice ⇒ second item (Duplicate) highlighted (data-highlighted).
    item2: async (pg) => {
      await openMenu(pg, () => triggerButton(pg).click());
      await pg.keyboard.press("ArrowDown");
      await pg.keyboard.press("ArrowDown");
    },
  },
  contextmenu: {
    open: async (pg) => openMenu(pg, () => pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" })),
  },
  select: {
    // open: the listbox shows; the current value (apple) is the highlighted item.
    open: async (pg) => { await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); },
  },
};

const spec = STATES[ID];
if (!spec) { console.error(`no state script for id '${ID}'`); srv.close(); process.exit(2); }
const step = spec[STATE];
if (!step) { console.error(`id '${ID}' has no state '${STATE}' (have: ${Object.keys(spec).join(", ")})`); process.exit(2); }

const b = await chromium.launch();
// Fixed, roomy viewport so the default `open` state never flips near an edge
// (collision-flip is its own state to add later). deviceScaleFactor irrelevant for DOM.
const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
await pg.goto(`http://127.0.0.1:${PORT}/?c=${ID}`);
await pg.waitForTimeout(250);

try {
  await step(pg);
  await settle(pg);

  // Snapshot the whole document body — trigger (in #root) + every portaled layer.
  const raw = await pg.evaluate(() => {
    const SKIP = new Set(["SCRIPT", "STYLE", "LINK", "NOSCRIPT"]);
    const fmt = (el, d = 0) => {
      const pad = "  ".repeat(d);
      if (el.nodeType === 3) { const t = el.textContent.trim(); return t ? pad + "#" + t : ""; }
      if (el.nodeType !== 1 || SKIP.has(el.tagName)) return "";
      const cls = (el.getAttribute("class") || "").split(/\s+/).filter(Boolean).sort().join(" ");
      const extra = [...el.attributes].filter((a) => a.name !== "class").map((a) => `${a.name}=${a.value}`).sort().join(" ");
      const head = `${pad}<${el.tagName.toLowerCase()}${cls ? ' class="' + cls + '"' : ""}${extra ? " " + extra : ""}>`;
      const kids = [...el.childNodes].map((k) => fmt(k, d + 1)).filter(Boolean);
      return [head, ...kids].join("\n");
    };
    return fmt(document.body);
  });

  // ── normalize ────────────────────────────────────────────────────────────────
  const idMap = new Map();
  const canonId = (m) => { if (!idMap.has(m)) idMap.set(m, `<id${idMap.size}>`); return idMap.get(m); };
  const normalized = raw
    // radix/React generated ids in any form: `radix-:r3:`, `radix-:r3H1:`, bare `:r3:`.
    .replace(/radix-:r[0-9a-z]+:|(?<![\w:]):r[0-9a-z]+:(?![\w])|radix-[0-9]+/gi, canonId)
    // layout-derived pixels (Popper transforms, --radix-* size vars, scroll-lock pad).
    .replace(/-?\d+(?:\.\d+)?px/g, "<px>");

  console.log(normalized);
  await b.close(); srv.close();
  process.exit(0);
} catch (e) {
  console.error(`✗ ${ID}:${STATE} — ${e.message}`);
  await b.close(); srv.close();
  process.exit(1);
}
