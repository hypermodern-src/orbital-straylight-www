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
import { chromium } from "@playwright/test";
import { serve, STATES, settle } from "./themes-states.mjs";

const [DIR, ID, STATE = "open"] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);

const spec = STATES[ID];
if (!spec) { console.error(`no state script for id '${ID}'`); closeSrv(); process.exit(2); }
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
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error(`✗ ${ID}:${STATE} — ${e.message}`);
  await b.close(); closeSrv();
  process.exit(1);
}
