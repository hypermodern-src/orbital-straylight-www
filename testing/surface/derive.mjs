// derive.mjs — the NUMERATOR, read from reality. Scans the committed goldens and the
// shared state-driver table, emits the set of GATED cells (a cell that is byte-pinned
// against upstream by at least one committed golden) + the binding report. Never
// hand-edited: the ledger cannot claim a cell is gated that the filesystem doesn't back.
//
// A "cell" here is a golden id `<idgroup>.<state>` (e.g. dialog.open). Its oracle artifacts
// are golden-dom/<cell>.txt (DOM-identical-to-upstream) and/or golden-aria/<cell>.txt
// (ARIA-tree-identical). A cell is GATED iff at least one exists.
//
// Binding (the anti-circularity check): every state in themes-states.mjs STATES must have
// a committed golden — a driver that runs but pins nothing is a self-gate, the exact
// failure STR-330 corrected. derive() returns those as `unbound_drivers`.
import { readdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const GOLDEN = join(HERE, "..", "golden", "themes");

const isNoise = (f) => /^(readme|license|copyright)/i.test(f);

async function listCells(sub, dropAxe) {
  let files;
  try { files = await readdir(join(GOLDEN, sub)); } catch { return new Map(); }
  const m = new Map(); // cell -> filename
  for (const f of files) {
    if (!f.endsWith(".txt") || isNoise(f)) continue;
    if (dropAxe && f.endsWith(".axe.txt")) continue;
    m.set(f.replace(/\.txt$/, ""), join(sub, f));
  }
  return m;
}

// Parse the STATES table: which states each id-group is driven into. We read the source
// rather than import it (importing boots a server). Top-level keys are `  <id>: {` and
// each state is `    <state>: ` one indent deeper, before the next id block.
async function parseStates() {
  const src = await readFile(join(HERE, "..", "playwright", "scripts", "themes-states.mjs"), "utf8");
  const start = src.indexOf("export const STATES");
  const body = src.slice(start);
  const out = new Map(); // id -> Set(state)
  let cur = null;
  for (const line of body.split("\n")) {
    const idm = line.match(/^  ([a-z0-9-]+): \{/);
    if (idm) { cur = idm[1]; out.set(cur, new Set()); continue; }
    if (cur) {
      const sm = line.match(/^    ([a-zA-Z0-9-]+): (?:async )?\(/);
      if (sm) out.get(cur).add(sm[1]);
      if (/^  \},?$/.test(line)) cur = null;
    }
  }
  return out;
}

export async function derive() {
  const dom = await listCells("golden-dom", false);
  const aria = await listCells("golden-aria", true);
  const states = await parseStates();

  // Union of cells that have any committed golden.
  const cells = new Map(); // cell -> { dom, aria, idgroup, state }
  for (const [cell, file] of dom) upsert(cells, cell, "dom", file);
  for (const [cell, file] of aria) upsert(cells, cell, "aria", file);

  // Binding: every driver state must be pinned by a golden.
  const gatedCells = new Set(cells.keys());
  const unbound = [];
  for (const [id, sts] of states) {
    for (const st of sts) {
      if (!gatedCells.has(`${id}.${st}`)) unbound.push(`${id}.${st}`);
    }
  }

  return { cells, unbound, gatedCount: cells.size };
}

function upsert(map, cell, kind, file) {
  const dot = cell.indexOf(".");
  const idgroup = dot < 0 ? cell : cell.slice(0, dot);
  const state = dot < 0 ? "" : cell.slice(dot + 1);
  const e = map.get(cell) ?? { dom: null, aria: null, idgroup, state };
  e[kind] = file;
  map.set(cell, e);
}

// CLI: `node derive.mjs` prints the derived numerator as JSON.
if (process.argv[1] && process.argv[1].endsWith("derive.mjs")) {
  const d = await derive();
  console.log(JSON.stringify({
    gated: d.gatedCount,
    unbound_drivers: d.unbound,
    cells: [...d.cells.keys()].sort(),
  }, null, 2));
}
