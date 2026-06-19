// check.mjs — THE RATCHET (STR-385). Ties the derived numerator (derive.mjs, from the
// committed goldens) to the declared denominator (required.json) and to the committed
// baseline (gaps.lock), and enforces MONOTONICITY: gated may only rise, open debt + binding
// violations may only fall. Any regression fails the gate; the only way to move a number the
// wrong way is to lower the lock IN THE SAME COMMIT (visible in review).
//
//   node check.mjs            # verify against gaps.lock; nonzero exit on regression
//   node check.mjs --update   # rewrite gaps.lock to current (the deliberate re-baseline)
//
// This is the recorded, measurable, hard-gated burndown. `git log -p gaps.lock` IS the
// monotone progress history — no prose, no hand-edited counts.
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { derive } from "./derive.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const LOCK = join(HERE, "gaps.lock");
const UPDATE = process.argv.includes("--update");

const req = JSON.parse(await readFile(join(HERE, "required.json"), "utf8"));
const { cells, unbound, gatedCount } = await derive();

// ---- behavioral surface: numerator = gated cells; open debt = open core gaps (DEPTH-AUDIT)
const openCore = Object.values(req.components).reduce((n, c) => n + (c.core_gaps_open ?? 0), 0);
const requiredBehavioral = gatedCount + openCore; // cells we hold + core cells we still owe
const covBehavioral = gatedCount / requiredBehavioral;

// ---- preset matrix: today only the native preset per component is gated
const presetsRequired = req.presets.required.length; // unstyled, themes, shadcn, daisy
const presetsGated = 1; // native only; rises as STR-383 lands non-native presets + goldens
const covPreset = presetsGated / presetsRequired;

// ---- per-component gated cell tally (group golden ids back to components)
const idgroupToComp = {};
for (const [comp, c] of Object.entries(req.components))
  for (const g of c.id_groups) idgroupToComp[g] = comp;
const perComponent = {};
for (const comp of Object.keys(req.components)) perComponent[comp] = { gated: 0, core_open: req.components[comp].core_gaps_open };
const unmapped = new Set();
for (const cell of cells.values()) {
  const comp = idgroupToComp[cell.idgroup];
  if (comp) perComponent[comp].gated++;
  else unmapped.add(cell.idgroup);
}

const current = {
  schema: 1,
  upstream: req.upstream,
  totals: {
    gated_cells: gatedCount,
    open_core_gaps: openCore,
    required_behavioral: requiredBehavioral,
    coverage_behavioral_pct: +(covBehavioral * 100).toFixed(1),
    presets_gated: presetsGated,
    presets_required: presetsRequired,
    coverage_preset_pct: +(covPreset * 100).toFixed(1),
    binding_violations: unbound.length,
  },
  per_component: Object.fromEntries(
    Object.entries(perComponent).sort((a, b) => b[1].core_open - a[1].core_open)
  ),
  binding_violations: unbound.sort(),
  unmapped_idgroups: [...unmapped].sort(),
};

// ---- the burndown line
const t = current.totals;
console.log(`ℵ surface ledger — upstream primitives@${req.upstream.primitives_sha} themes@${req.upstream.radix_themes}`);
console.log(`  behavioral: ${t.gated_cells} gated / ${t.required_behavioral} required  (${t.coverage_behavioral_pct}%)  · open core debt: ${t.open_core_gaps}`);
console.log(`  preset matrix: ${t.presets_gated}/${t.presets_required} presets  (${t.coverage_preset_pct}%)  [unstyled·themes·shadcn·daisy; orbital last]`);
console.log(`  binding violations (drivers with no committed golden): ${t.binding_violations}`);
if (current.unmapped_idgroups.length)
  console.log(`  ⚠ unmapped golden id-groups (add to required.json id_groups): ${current.unmapped_idgroups.join(", ")}`);

if (UPDATE) {
  await writeFile(LOCK, JSON.stringify(current, null, 2) + "\n");
  console.log(`\n✔ gaps.lock re-baselined to current.`);
  process.exit(0);
}

// ---- the ratchet: compare to the committed baseline
let lock;
try { lock = JSON.parse(await readFile(LOCK, "utf8")); }
catch { console.error(`\n✘ no gaps.lock — run \`node check.mjs --update\` to establish the baseline.`); process.exit(2); }

const regressions = [];
const L = lock.totals, C = current.totals;
if (C.gated_cells < L.gated_cells) regressions.push(`gated_cells fell ${L.gated_cells} → ${C.gated_cells} (a golden was lost)`);
if (C.open_core_gaps > L.open_core_gaps) regressions.push(`open_core_gaps rose ${L.open_core_gaps} → ${C.open_core_gaps} (debt added)`);
if (C.binding_violations > L.binding_violations) regressions.push(`binding_violations rose ${L.binding_violations} → ${C.binding_violations} (a driver lost its golden)`);
if (C.presets_gated < L.presets_gated) regressions.push(`presets_gated fell ${L.presets_gated} → ${C.presets_gated}`);

if (regressions.length) {
  console.error(`\n✘ RATCHET REGRESSION — progress is monotone; these moved the wrong way:`);
  for (const r of regressions) console.error(`    · ${r}`);
  console.error(`  If intentional (a deliberate re-baseline), run \`node check.mjs --update\` in this commit.`);
  process.exit(1);
}

const advanced = C.gated_cells > L.gated_cells || C.open_core_gaps < L.open_core_gaps || C.binding_violations < L.binding_violations;
console.log(advanced
  ? `\n✔ ratchet held + ADVANCED. Re-baseline with \`node check.mjs --update\` to record the progress.`
  : `\n✔ ratchet held (no change vs gaps.lock).`);
process.exit(0);
