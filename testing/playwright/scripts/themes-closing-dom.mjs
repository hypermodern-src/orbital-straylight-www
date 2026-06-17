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
//   3. Run the per-id CLOSE action (CLOSE[id] in themes-states.mjs — Escape for the modal/
//      popper overlays, pointer-leave for tooltip/hovercard) and poll until the overlay
//      CONTENT node is mounted with `data-state="closed"`, then snapshot. With the animation
//      pinned to 100s, the closing DOM is stable. Close actions key off UPSTREAM selectors
//      only, so the same script runs against golden AND the Halogen port.
//
// Normalization is IDENTICAL to themes-open-dom.mjs (ids→<idN>, px→<px>, display:contents
// wrapper stripped) — structure stays exact. The oracle is "our closing Dialog's DOM ==
// radix's closing Dialog's DOM", never a self-written expectation.
import { chromium } from "@playwright/test";
import { serve, STATES, CLOSE, settle } from "./themes-states.mjs";

const [DIR, ID] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);

const spec = STATES[ID];
if (!spec || !spec.open) { console.error(`no open driver for id '${ID}'`); closeSrv(); process.exit(2); }
const closeAction = CLOSE[ID];
if (!closeAction) { console.error(`no CLOSE driver for id '${ID}'`); closeSrv(); process.exit(2); }

// The set of UPSTREAM selectors that identify a closing overlay CONTENT node — one per
// overlay anatomy (modal dialog/alertdialog, Popper popovers/menus/hovercard, Select listbox,
// Tooltip). The closing node must still be mounted with data-state="closed" (Presence keeps
// it alive while the exit animation plays). NOT keyed off any port-internal class.
const CLOSED_SEL = [
  '[role="dialog"][data-state="closed"]',
  '[role="alertdialog"][data-state="closed"]',
  '.rt-PopperContent[data-state="closed"]',
  '.rt-SelectContent[data-state="closed"]',
  '.rt-TooltipContent[data-state="closed"]',
  '.rt-HoverCardContent[data-state="closed"]',
  // Toast: the bare <li> lingers data-state="closed" (Presence) through the golden story's
  // exit keyframe — keyed off the upstream li, no port-internal class.
  'li[data-state="closed"][data-swipe-direction]',
  // Collapsible: the content div (it carries the aria-controls `id`; the trigger button does
  // not) lingers data-state="closed" + hidden through the golden story's injected exit keyframe.
  'div[id][data-state="closed"]',
].join(", ");

// Pin every animation/transition open-ended so the closing node lingers for the snapshot.
const SLOWDOWN = `* { animation-duration: 100s !important; animation-delay: 0s !important;
  transition-duration: 100s !important; transition-delay: 0s !important; }`;

const snapshotDOM = (pg) => pg.evaluate(() => {
  const SKIP = new Set(["SCRIPT", "STYLE", "LINK", "NOSCRIPT"]);
  const fmt = (el, d = 0) => {
    const pad = "  ".repeat(d);
    if (el.nodeType === 3) { const t = el.textContent.trim(); return t ? pad + "#" + t : ""; }
    if (el.nodeType !== 1 || SKIP.has(el.tagName)) return "";
    // Radix Toast SR-announce mirror (role=status, aria-live, timer-driven content/unmount) —
    // stripped symmetrically from golden AND port, same as in themes-open-dom.mjs.
    if (el.tagName === "SPAN" && el.getAttribute("role") === "status" && el.hasAttribute("aria-live")) return "";
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
  // Pin the exit animation to 100s BEFORE closing, so the closing node never unmounts within
  // the capture window (no race against animationend).
  await pg.addStyleTag({ content: SLOWDOWN });
  await pg.waitForTimeout(50);
  await closeAction(pg);
  // The closing CONTENT node must still be mounted with data-state="closed" (Presence
  // lifecycle) — poll on the overlay-content selector specifically, not any [data-state].
  await pg.waitForFunction((sel) => !!document.querySelector(sel), CLOSED_SEL, { timeout: 3000 });
  await pg.waitForTimeout(150);

  const closed = await pg.evaluate((sel) => !!document.querySelector(sel), CLOSED_SEL);
  if (!closed) throw new Error("no closing overlay node mounted (data-state=closed) — Presence not keeping it alive");

  console.log(normalize(await snapshotDOM(pg)));
  await b.close(); closeSrv();
  process.exit(0);
} catch (e) {
  console.error(`✗ ${ID}:closing — ${e.message}`);
  await b.close(); closeSrv();
  process.exit(1);
}
