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
import { readFile, writeFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { derive } from "./derive.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const LOCK = join(HERE, "gaps.lock");
const UPDATE = process.argv.includes("--update");

const req = JSON.parse(await readFile(join(HERE, "required.json"), "utf8"));
const { cells, unbound, gatedCount } = await derive();

// ---- enumerated per-component cell files (STR-381 template, e.g. cells/Dialog.json).
// Where present, they REPLACE the scalar core_gaps_open with itemized cells: each
// status=gated cell must exist on disk (else a binding violation), each status=open
// core cell is named debt. Components migrate scalar→enumerated one at a time.
const enumerated = {}; // Component -> { coreOpen, namedOpen, gatedClaims:[ids] }
try {
  for (const f of await readdir(join(HERE, "cells"))) {
    if (!f.endsWith(".json")) continue;
    const cf = JSON.parse(await readFile(join(HERE, "cells", f), "utf8"));
    const comp = cf.component;
    let coreOpen = 0, namedOpen = 0; const gatedClaims = [];
    for (const c of cf.cells) {
      if (c.status === "gated") gatedClaims.push(c.id);
      else if (c.status === "open") { namedOpen++; if (c.importance === "core") coreOpen++; }
    }
    enumerated[comp] = { coreOpen, namedOpen, gatedClaims };
  }
} catch { /* no cells/ dir yet */ }

// ---- drift guard (STR-381 DoD): the ledger and DEPTH-AUDIT.md must stay mutually
// pinned. Parse the audit's `### <Name> — <N> gaps (<C> core)` headers and assert each
// component's enumerated open-core count equals the audit's C. Either both move or neither.
const auditCore = {};
{
  const audit = await readFile(join(HERE, "..", "..", "src", "Hydrogen", "Radix", "DEPTH-AUDIT.md"), "utf8");
  for (const m of audit.matchAll(/^### (\w+) — \d+ gaps \((\d+) core\)/gm)) auditCore[m[1]] = +m[2];
}
const driftErrors = [];
for (const [comp, e] of Object.entries(enumerated)) {
  if (comp in auditCore && auditCore[comp] !== e.coreOpen)
    driftErrors.push(`${comp}: ledger open-core ${e.coreOpen} ≠ DEPTH-AUDIT ${auditCore[comp]}`);
}

// A gated CLAIM in an enumerated file with no committed golden = binding violation.
const gatedOnDisk = new Set(cells.keys());
for (const [comp, e] of Object.entries(enumerated))
  for (const id of e.gatedClaims)
    if (!gatedOnDisk.has(id)) unbound.push(`${comp}:${id} (enumerated gated, no golden)`);

// ---- behavioral surface: numerator = gated cells; open debt = open core gaps.
// Enumerated components contribute their itemized core-open count; the rest the scalar.
const openCore = Object.entries(req.components).reduce(
  (n, [comp, c]) => n + (enumerated[comp] ? enumerated[comp].coreOpen : (c.core_gaps_open ?? 0)), 0);
const namedOpenCells = Object.values(enumerated).reduce((n, e) => n + e.namedOpen, 0);
const requiredBehavioral = gatedCount + openCore; // cells we hold + core cells we still owe
const covBehavioral = gatedCount / requiredBehavioral;

// ---- preset matrix: today only the native preset per component is gated
const presetsRequired = req.presets.required.length; // unstyled, themes, shadcn, daisy
const presetsGated = 1; // native only; rises as STR-383 lands non-native presets + goldens
const covPreset = presetsGated / presetsRequired;
const invarianceSubjects = (req.presets.invariance_subjects ?? []).length; // STR-383: proven preset-invariant

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
    enumerated_components: Object.keys(enumerated).length,
    named_open_cells: namedOpenCells,
    invariance_subjects: invarianceSubjects,
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
console.log(`  preset-invariance proven: ${t.invariance_subjects}/32 components (behavioral DOM identical across all presets)`);
console.log(`  enumerated: ${t.enumerated_components}/32 components itemized · ${t.named_open_cells} named open cells (STR-381 template)`);
console.log(`  binding violations (drivers with no committed golden): ${t.binding_violations}`);
if (current.unmapped_idgroups.length)
  console.log(`  ⚠ unmapped golden id-groups (add to required.json id_groups): ${current.unmapped_idgroups.join(", ")}`);

// Drift guard fails hard regardless of --update: the ledger may never disagree with the audit.
if (driftErrors.length) {
  console.error(`\n✘ LEDGER ↔ DEPTH-AUDIT DRIFT — these must move together:`);
  for (const d of driftErrors) console.error(`    · ${d}`);
  console.error(`  Update both the cell file and the DEPTH-AUDIT header in the same commit.`);
  process.exit(3);
}

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
if ((C.enumerated_components ?? 0) < (L.enumerated_components ?? 0)) regressions.push(`enumerated_components fell ${L.enumerated_components} → ${C.enumerated_components} (a cell file was lost)`);
if ((C.invariance_subjects ?? 0) < (L.invariance_subjects ?? 0)) regressions.push(`invariance_subjects fell ${L.invariance_subjects} → ${C.invariance_subjects} (a preset-invariance proof was dropped)`);

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
