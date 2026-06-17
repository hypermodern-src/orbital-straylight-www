// themes-closing-dom.mjs <dist> <id> — the CLOSING-state DOM oracle (STR-335).
//
// Radix `Presence` keeps a closing overlay MOUNTED with data-state="closed" until its
// CSS exit animation ends, THEN unmounts — so the exit animation plays. This driver
// captures that transient closing DOM deterministically and prints it NORMALIZED, so the
// Halogen port (which must mirror the lifecycle) can be diffed against real radix-themes.
//
// DETERMINISM (proven self-stable in themes-closing-capture.sh, same as the open oracle):
//   1. Open the overlay (the shared STATES[id].open driver), let it settle.
//   2. Inject `* { animation-duration: 100s !important; transition-duration: 100s !important }`
//      so the exit animation lingers indefinitely — the closing node never unmounts within
//      the capture window (no race against animationend).
//   3. Press Escape (DismissableLayer close) and poll until a `data-state="closed"` node is
//      present, then snapshot. With the animation pinned to 100s, the closing DOM is stable.
//
// Normalization is IDENTICAL to themes-open-dom.mjs (ids→<idN>, px→<px>, display:contents
// wrapper stripped) — structure stays exact. The oracle is "our closing Dialog's DOM ==
// radix's closing Dialog's DOM", never a self-written expectation.
import { chromium } from "@playwright/test";
import { serve, STATES, settle } from "./themes-states.mjs";

const [DIR, ID] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);

const spec = STATES[ID];
if (!spec || !spec.open) { console.error(`no open driver for id '${ID}'`); closeSrv(); process.exit(2); }

// Pin every animation/transition open-ended so the closing node lingers for the snapshot.
const SLOWDOWN = `* { animation-duration: 100s !important; animation-delay: 0s !important;
  transition-duration: 100s !important; transition-delay: 0s !important; }`;

const snapshotDOM = (pg) => pg.evaluate(() => {
  const SKIP = new Set(["SCRIPT", "STYLE", "LINK", "NOSCRIPT"]);
  const fmt = (el, d = 0) => {
    const pad = "  ".repeat(d);
    if (el.nodeType === 3) { const t = el.textContent.trim(); return t ? pad + "#" + t : ""; }
    if (el.nodeType !== 1 || SKIP.has(el.tagName)) return "";
    const onlyStyle = el.attributes.length === 1 && el.attributes[0].name === "style";
    if (el.tagName === "DIV" && onlyStyle && /display:\s*contents/.test(el.getAttribute("style") || "")) {
      return [...el.childNodes].map((k) => fmt(k, d)).filter(Boolean).join("\n");
    }
    const cls = (el.getAttribute("class") || "").split(/\s+/).filter(Boolean).sort().join(" ");
    const extra = [...el.attributes].filter((a) => a.name !== "class").map((a) => `${a.name}=${a.value}`).sort().join(" ");
    const head = `${pad}<${el.tagName.toLowerCase()}${cls ? ' class="' + cls + '"' : ""}${extra ? " " + extra : ""}>`;
    const kids = [...el.childNodes].map((k) => fmt(k, d + 1)).filter(Boolean);
    return [head, ...kids].join("\n");
  };
  return fmt(document.body);
});

const normalize = (raw) => {
  const idMap = new Map();
  const canonId = (m) => { if (!idMap.has(m)) idMap.set(m, `<id${idMap.size}>`); return idMap.get(m); };
  return raw
    .replace(/radix-:r[0-9a-z]+:|(?<![\w:]):r[0-9a-z]+:(?![\w])|radix-[0-9]+/gi, canonId)
    .replace(/-?\d+(?:\.\d+)?px/g, "<px>");
};

const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
await pg.goto(`http://127.0.0.1:${PORT}/?c=${ID}&s=open`);
await pg.waitForTimeout(250);

try {
  await spec.open(pg);
  await settle(pg);
  await pg.addStyleTag({ content: SLOWDOWN });
  await pg.waitForTimeout(50);
  await pg.keyboard.press("Escape");
  // The closing node must still be mounted with data-state="closed" (Presence lifecycle).
  await pg.waitForFunction(() => !!document.querySelector('[data-state="closed"]'), { timeout: 3000 });
  await pg.waitForTimeout(150);

  const closed = await pg.evaluate(() => !!document.querySelector('[role="dialog"][data-state="closed"], [role="alertdialog"][data-state="closed"], .rt-PopperContent[data-state="closed"]'));
  if (!closed) throw new Error("no closing overlay node mounted (data-state=closed) — Presence not keeping it alive");

  console.log(normalize(await snapshotDOM(pg)));
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error(`✗ ${ID}:closing — ${e.message}`);
  await b.close(); closeSrv();
  process.exit(1);
}
