// themes-a11y.mjs <dist> <capture|verify> [<id> …] — the a11y oracle (STR-333).
//
// Two checks per interactive component, in its `rest` and canonical-`shown` states (open for
// overlays, checked/on/pressed/selected/active/… for the non-overlay interactive set), driven
// by the shared themes-states.mjs, identical to the DOM oracle:
//   1. ARIA accessibility-tree snapshot (Playwright built-in) diffed against the committed
//      upstream baseline golden-aria/<id>.<state>.txt — so roles / accessible names /
//      states / relationships match real radix-themes exactly.
//   2. axe-core (vendored, injected at runtime — no npm dep). Real radix-themes is NOT
//      axe-clean on every demo (underline-less Link → link-in-text-block; the portal
//      focus-guard → aria-hidden-focus; red-variant contrast) — those are upstream's own
//      characteristics, so imposing "zero violations" would be a self-invented bar. Instead
//      we capture upstream's violation FINGERPRINT and require the port introduce NO NEW
//      violation (port rules ⊆ upstream rules). Axe complements the DOM oracle by judging
//      COMPUTED styles (contrast) the structural snapshot tokenizes away.
//
//   capture : write the upstream ARIA baselines + axe fingerprints (always succeeds).
//   verify  : port ARIA == baseline, and port adds no axe rule beyond the fingerprint.
import { chromium } from "@playwright/test";
import { serve, STATES, settle } from "./themes-states.mjs";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const [DIR, MODE = "verify", ...ONLY] = process.argv.slice(2);
const HERE = dirname(fileURLToPath(import.meta.url));
const BASE = join(HERE, "..", "..", "golden", "themes", "golden-aria");
const AXE = join(HERE, "..", "vendor", "axe.min.js");

// Rules that fire on a bare single-component demo page, not on the component — disabled.
// (Document/landmark/page-structure scaffolding; the component's own a11y stays asserted.)
const OFF = ["region", "landmark-one-main", "page-has-heading-one", "bypass", "document-title", "html-has-lang", "html-lang-valid", "meta-viewport", "landmark-unique"];
const axeOpts = { runOnly: { type: "tag", values: ["wcag2a", "wcag2aa"] }, rules: Object.fromEntries(OFF.map((r) => [r, { enabled: false }])) };

// rest = closed/at-rest (trigger only); `shown` = the canonical post-interaction state.
// Overlays expose "open"; the non-overlay interactive components expose their own single
// shown state (checked/on/pressed/selected/active/tab2) — pick the one non-rest key.
const shown = (id) => Object.keys(STATES[id]).includes("open") ? "open" : Object.keys(STATES[id]).filter((s) => s !== "rest")[0];
// Per-component EXTRA a11y states beyond rest+shown — for cells that require axe across more
// states (e.g. otp.axe-states: empty/typed/password/disabled, not just rest+filled).
const EXTRA_STATES = { otp: ["empty", "typed", "password", "disabled"], passwordtoggle: ["visible"] };
const MATRIX = [
  ...Object.keys(STATES).flatMap((id) => [{ id, state: "rest" }, { id, state: shown(id) }]),
  ...Object.entries(EXTRA_STATES).flatMap(([id, sts]) => sts.map((state) => ({ id, state }))),
];

const { port: PORT, close: closeSrv } = await serve(DIR);
// CHROMIUM_BIN overrides executablePath where the nix browser set isn't materialized
// (sandbox with a system chromium); no-op in CI (version-matched nix browsers).
const b = await chromium.launch(process.env.CHROMIUM_BIN ? { executablePath: process.env.CHROMIUM_BIN } : {});
let pass = 0, fail = 0;

for (const { id, state } of MATRIX) {
  if (ONLY.length && !ONLY.includes(id)) continue;
  const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
  const tag = `${id}:${state}`;
  try {
    // Always select the golden's `interactive` story (?c=<id>&s=<state>) — the SAME single
    // drivable instance the port (themes-interactive) renders — for BOTH the rest snapshot
    // (un-driven) and the shown state (driven), exactly as the DOM oracle does. The plain
    // ?c=<id> at-rest pixel page is a DIFFERENT, seeded story (named/pre-checked, no panels),
    // so snapshotting it for `rest` would compare two different stories; &s= keeps golden and
    // port symmetric. For ids with no interactive variant (the 8 overlays) &s= falls back to
    // the single page, so their baselines are unaffected.
    await pg.goto(`http://127.0.0.1:${PORT}/?c=${id}&s=${state}`); await pg.waitForTimeout(250);
    if (state !== "rest") { await STATES[id][state](pg); await settle(pg); }

    // 1. axe-core → the violated-rule fingerprint (impact moderate+; minor = noise).
    await pg.addScriptTag({ path: AXE });
    const res = await pg.evaluate((opts) => window.axe.run(document, opts), axeOpts);
    const rules = [...new Set(res.violations
      .filter((v) => ["moderate", "serious", "critical"].includes(v.impact))
      .map((v) => v.id))].sort();

    // 2. ARIA accessibility-tree snapshot
    const aria = (await pg.locator("body").ariaSnapshot()).trimEnd() + "\n";
    const ariaFile = join(BASE, `${id}.${state}.txt`);
    const axeFile = join(BASE, `${id}.${state}.axe.txt`);

    if (MODE === "capture") {
      await mkdir(BASE, { recursive: true });
      await writeFile(ariaFile, aria);
      await writeFile(axeFile, rules.length ? rules.join("\n") + "\n" : "");
      console.log(`  ✓ ${tag} — ARIA captured (${aria.split("\n").length} lines), axe fingerprint [${rules.join(", ") || "clean"}]`);
    } else {
      let want;
      try { want = await readFile(ariaFile, "utf8"); } catch { throw new Error(`no ARIA baseline (${ariaFile}); run capture`); }
      if (want !== aria) {
        const wl = want.split("\n"), gl = aria.split("\n");
        const firstDiff = wl.findIndex((l, i) => l !== gl[i]);
        throw new Error(`ARIA tree differs at line ${firstDiff + 1}:\n      - ${wl[firstDiff] ?? "(eof)"}\n      + ${gl[firstDiff] ?? "(eof)"}`);
      }
      const baseRules = (await readFile(axeFile, "utf8").catch(() => "")).split("\n").map((s) => s.trim()).filter(Boolean);
      const introduced = rules.filter((r) => !baseRules.includes(r));
      if (introduced.length) throw new Error(`new axe violation(s) not in upstream: ${introduced.join(", ")}`);
      console.log(`  ✓ ${tag} — ARIA matches upstream, no new axe violations`);
    }
    pass++;
  } catch (e) {
    console.log(`  ✗ ${tag}\n      ${e.message}`); fail++;
  } finally { await pg.close(); }
}

await b.close(); closeSrv();
console.log(`\nℵ a11y (${MODE}): ${pass} pass, ${fail} fail`);
process.exit(fail ? 1 : 0);
