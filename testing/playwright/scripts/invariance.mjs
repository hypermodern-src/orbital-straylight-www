// invariance.mjs — the BEHAVIORAL-INVARIANCE gate (STR-383).
//
// The machine-proof of "drop shadcn/daisy/orbital on as easy as blinking": the
// SAME primitive rendered under N different presets must produce BYTE-IDENTICAL
// behavioral DOM — `role` / every `data-*` / every `aria-*` / `tabindex` / form
// semantics (type, disabled, hidden, value, name, …) and the tag tree — while ONLY
// `class` and inline `style` differ. If behavior is invariant across presets, then
// behavior lives in the primitive and the skin is pure decoration; swapping presets
// provably cannot touch behavior. If a preset ever injects a wrapper, a role, or a
// data-attr, this gate goes red.
//
//   node invariance.mjs <dist> <story-id>   # diff every [data-preset] subtree on the page
//   node invariance.mjs --selftest          # prove the gate passes/bites (no gallery/buck2)
//
// The page is expected to render the same component once per preset, each wrapped in a
// node carrying `data-preset="<name>"`. The gate extracts each subtree's behavioral DOM
// and asserts they are all equal to the first.
import { chromium } from "@playwright/test";
import { serve, settle } from "./themes-states.mjs";

// In CI the version-matched nix browser set (PLAYWRIGHT_BROWSERS_PATH, set by run.sh) is
// used. CHROMIUM_BIN overrides executablePath for environments where that set isn't
// materialized (e.g. a sandbox with a system chromium on PATH).
const launchOpts = process.env.CHROMIUM_BIN ? { executablePath: process.env.CHROMIUM_BIN } : {};
const launch = () => chromium.launch(launchOpts);

// The behavioral-DOM extractor, run IN-PAGE. Serializes an element subtree to a string
// that includes everything behavioral and NOTHING presentational. `class` and `style`
// are dropped (the preset's whole job); `id` is normalized to <idN> in first-seen order
// so generated ids (which differ per instance) don't create false divergence, while the
// REFERENCES between them (aria-controls/labelledby/activedescendant/for/…) are preserved
// structurally. The `data-preset` marker on the root itself is excluded.
function EXTRACTOR(root) {
  const SKIP = new Set(["SCRIPT", "STYLE", "LINK", "NOSCRIPT"]);
  const idMap = new Map(); let idN = 0;
  const normId = (v) => v.replace(/[A-Za-z0-9:_-]*radix[A-Za-z0-9:_-]*|:[a-z0-9]+:|«[a-z0-9]+»/gi, (m) => {
    if (!idMap.has(m)) idMap.set(m, "<id" + (idN++) + ">"); return idMap.get(m);
  });
  const DROP = new Set(["class", "style"]);
  const fmt = (el, depth, isRoot) => {
    if (el.nodeType === 3) { const t = el.textContent.trim(); return t ? "  ".repeat(depth) + "#" + t : ""; }
    if (el.nodeType !== 1 || SKIP.has(el.tagName)) return "";
    const attrs = [];
    for (const a of el.attributes) {
      if (DROP.has(a.name)) continue;
      if (isRoot && a.name === "data-preset") continue;
      let v = a.value;
      if (a.name === "id" || /^(aria-(controls|labelledby|describedby|activedescendant|owns))$|^for$|^list$|^form$/.test(a.name)) v = normId(v);
      attrs.push(a.name + '="' + v + '"');
    }
    attrs.sort();
    const open = "  ".repeat(depth) + "<" + el.tagName.toLowerCase() + (attrs.length ? " " + attrs.join(" ") : "") + ">";
    const kids = [];
    for (const c of el.childNodes) { const s = fmt(c, depth + 1, false); if (s) kids.push(s); }
    return [open, ...kids].join("\n");
  };
  return fmt(root, 0, true);
}

async function extractByPreset(scope) {
  const handles = await scope.$$("[data-preset]");
  const out = [];
  for (const h of handles) {
    const preset = await h.evaluate((e) => e.getAttribute("data-preset"));
    const dom = await h.evaluate(EXTRACTOR);
    out.push({ preset, dom });
  }
  return out;
}

// A page may carry several `[data-invariance="<component>"]` groups, each with its own
// `[data-preset]` variants — so many components prove in one page/build. Returns
// [{ group, variants }]. With no groups, the whole page is one group (named `fallback`).
async function extractGroups(pg, fallback) {
  const groups = await pg.$$("[data-invariance]");
  if (groups.length === 0) return [{ group: fallback, variants: await extractByPreset(pg) }];
  const out = [];
  for (const g of groups) {
    const name = await g.evaluate((e) => e.getAttribute("data-invariance"));
    out.push({ group: name, variants: await extractByPreset(g) });
  }
  return out;
}

// Returns true iff every group is preset-invariant.
function gateGroups(groupResults) {
  let allOk = true;
  for (const { group, variants } of groupResults)
    if (!reportAndExit(variants, group)) allOk = false;
  return allOk;
}

function reportAndExit(variants, label) {
  if (variants.length < 2) {
    console.error(`✘ invariance[${label}]: need ≥2 [data-preset] variants, found ${variants.length}`);
    process.exit(2);
  }
  const base = variants[0];
  const diffs = variants.slice(1).filter((v) => v.dom !== base.dom);
  console.log(`ℵ invariance[${label}]: ${variants.length} presets — ${variants.map((v) => v.preset).join(" · ")}`);
  if (diffs.length === 0) {
    console.log(`  ✔ behavioral DOM byte-identical across all presets (only class/style differ).`);
    return true;
  }
  console.error(`  ✘ behavioral divergence under preset(s): ${diffs.map((d) => d.preset).join(", ")} (vs ${base.preset})`);
  for (const d of diffs) {
    const a = base.dom.split("\n"), b = d.dom.split("\n");
    for (let i = 0; i < Math.max(a.length, b.length); i++)
      if (a[i] !== b[i]) { console.error(`    ${base.preset}: ${a[i] ?? "∅"}`); console.error(`    ${d.preset}: ${b[i] ?? "∅"}`); break; }
  }
  return false;
}

async function selftest() {
  const b = await launch();
  const pg = await b.newPage();
  let ok = true;

  // Case 1 — same behavior, different skins → MUST PASS.
  await pg.setContent(`
    <div data-preset="unstyled"><button type="button" role="switch" aria-checked="false" data-state="off" class="">x</button></div>
    <div data-preset="themes"><button type="button" role="switch" aria-checked="false" data-state="off" class="rt-Switch" style="color:red">x</button></div>
    <div data-preset="shadcn"><button type="button" role="switch" aria-checked="false" data-state="off" class="peer inline-flex">x</button></div>
  `);
  const pass = reportAndExit(await extractByPreset(pg), "selftest-identical");
  if (!pass) { console.error("  ✘✘ SELFTEST FAILED: identical-behavior case should PASS"); ok = false; }

  // Case 2 — a preset injects a behavioral difference (data-state) → MUST BITE.
  await pg.setContent(`
    <div data-preset="good"><button type="button" role="switch" aria-checked="false" data-state="off">x</button></div>
    <div data-preset="bad"><button type="button" role="switch" aria-checked="true" data-state="on">x</button></div>
  `);
  const bit = !reportAndExit(await extractByPreset(pg), "selftest-divergent");
  if (!bit) { console.error("  ✘✘ SELFTEST FAILED: divergent-behavior case should BITE"); ok = false; }
  else console.log("  ✔ gate correctly bit the injected behavioral divergence.");

  // Case 3 — id normalization: same structure, different generated ids → MUST PASS.
  await pg.setContent(`
    <div data-preset="a"><label for="radix-:r1:">L</label><input id="radix-:r1:" aria-describedby="radix-:r2:"><span id="radix-:r2:">d</span></div>
    <div data-preset="b"><label for="radix-:r9:" class="x">L</label><input id="radix-:r9:" aria-describedby="radix-:rA:" class="y"><span id="radix-:rA:" class="z">d</span></div>
  `);
  const idPass = reportAndExit(await extractByPreset(pg), "selftest-idnorm");
  if (!idPass) { console.error("  ✘✘ SELFTEST FAILED: id-normalization case should PASS"); ok = false; }

  await b.close();
  console.log(ok ? "\n✔ invariance gate self-test PASSED (passes on skin-only diffs, bites on behavioral diffs)." : "\n✘ invariance gate self-test FAILED.");
  process.exit(ok ? 0 : 1);
}

// OVERLAY mode: prove an overlay's OPEN-state behavioral DOM is preset-invariant.
// Each preset is a SEPARATE page (`<baseId>-<preset>`), so the body-portaled content is
// unambiguous — no pairing. Opens via a generic gesture on the trigger, waits for the
// overlay's role, snapshots the whole <body>, diffs across presets. Self-contained (no
// #root / STATES coupling — the gallery mounts to body).
//   node invariance.mjs <dist> --overlay <baseId> <preset1,..> <waitRole> [click|rightclick|hover]
async function overlay(DIR, baseId, presetCsv, waitRole, gesture = "click") {
  const presets = presetCsv.split(",");
  const { port, close } = await serve(DIR);
  const b = await launch();
  const variants = [];
  for (const p of presets) {
    const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
    await pg.goto(`http://127.0.0.1:${port}/?story=${encodeURIComponent(`${baseId}-${p}`)}`);
    await pg.waitForTimeout(250);
    try {
      const trig = pg.getByRole("button").first();
      if (gesture === "rightclick") await trig.click({ button: "right" });
      else if (gesture === "hover") await trig.hover();
      else await trig.click();
      await pg.locator(`[role="${waitRole}"]`).first().waitFor({ timeout: 8000 });
      await settle(pg);
    } catch (e) {
      console.error(`✘ ${baseId}-${p}: open (${gesture} → role=${waitRole}) failed — ${e.message.split("\n")[0]}`);
      await b.close(); close(); process.exit(1);
    }
    const dom = await (await pg.$("body")).evaluate(EXTRACTOR);
    variants.push({ preset: p, dom });
    await pg.close();
  }
  await b.close(); close();
  const ok = reportAndExit(variants, `${baseId} (open)`);
  process.exit(ok ? 0 : 1);
}

// ── main ──────────────────────────────────────────────────────────────────────
if (process.argv.includes("--selftest")) {
  await selftest();
} else if (process.argv.includes("--overlay")) {
  const i = process.argv.indexOf("--overlay");
  const DIR = process.argv[2];
  const [baseId, presetCsv, waitRole, gesture] = process.argv.slice(i + 1);
  if (!DIR || !baseId || !presetCsv || !waitRole) {
    console.error("usage: invariance.mjs <dist> --overlay <baseId> <preset1,...> <waitRole> [click|rightclick|hover]"); process.exit(2);
  }
  await overlay(DIR, baseId, presetCsv, waitRole, gesture);
} else {
  const [DIR, STORY] = process.argv.slice(2);
  if (!DIR || !STORY) { console.error("usage: invariance.mjs <dist> <story-id>  |  invariance.mjs --selftest"); process.exit(2); }
  const { port, close } = await serve(DIR);
  const b = await launch();
  const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
  await pg.goto(`http://127.0.0.1:${port}/?story=${encodeURIComponent(STORY)}`);
  await pg.waitForTimeout(300);
  const ok = gateGroups(await extractGroups(pg, STORY));
  await b.close(); close();
  process.exit(ok ? 0 : 1);
}
