# testing/surface — the parity ledger + ratchet (STR-381 / STR-385)

The machine that makes TOTAL-PARITY progress **monotone, measurable, recorded, and
hard-gated**. It replaces hand-edited prose counts and unbacked Linear checkboxes with
one number the build derives from the committed goldens and refuses to let regress.

## Files

| File | Role |
|---|---|
| `required.json` | The **denominator** (hand-declared): per-component `face` (themed/bare) + `core_gaps_open` (the open core debt, from `DEPTH-AUDIT.md`) + `id_groups` (golden-id → component map) + the preset matrix `{unstyled, themes, shadcn, daisy}` (orbital last) + the pinned upstream (`primitives@45f8b34`, `themes@3`). |
| `derive.mjs` | The **numerator** (from reality): scans `testing/golden/themes/golden-{dom,aria}/*.txt` → the set of **gated cells** (a cell pinned byte-identical to upstream by ≥1 committed golden). Also reports **binding violations** — any `themes-states.mjs` driver state with no committed golden (a self-gate, the STR-330 anti-pattern). Never hand-edited. |
| `check.mjs` | The **ratchet**: ties numerator↔denominator↔baseline and enforces monotonicity. |
| `gaps.lock` | The committed **baseline**. `git log -p gaps.lock` IS the burndown. |

## Use

```bash
node testing/surface/check.mjs            # verify vs gaps.lock — nonzero exit on regression
node testing/surface/check.mjs --update   # deliberate re-baseline (record progress / move the pin)
node testing/surface/derive.mjs           # inspect the raw numerator + binding report
```

`testing/playwright/run.sh` runs `check.mjs` as a hard step before the pixel/DOM suite,
so the ratchet is part of the gate, not an optional report.

## The invariant

`check.mjs` **fails the build** if, vs `gaps.lock`: gated cells fell · open core debt rose ·
binding violations rose · presets-gated fell. The only way to move a number the wrong way
is `--update` **in the same commit** — visible in review. Progress can only ratchet toward
the zero-compromise end state (STR-330): `open == 0`, full surface gated, every preset
behaviorally invariant.

## Baseline (2026-06-19)

195 gated cells / 305 required = **63.9% behavioral**; preset matrix **1/4 (25%)**, native
only; **0 binding violations**; open core debt **110**. All **32/32** components are itemized
in `cells/` — **758 total rows** (195 gated + 563 open: 110 core / 230 common / 223 edge),
each open cell a named, trackable parity item. As STR-382 expands the dual-render surface and
STR-383 lands non-native presets (each adding committed goldens), `derive.mjs` picks them up
automatically and coverage rises — recorded in `gaps.lock`.

## Four enforced invariants

`check.mjs` fails the build on any of:
1. **Ratchet** — gated cells fell · open core debt rose · binding violations rose · presets-gated fell · enumerated components fell (vs `gaps.lock`).
2. **Binding** — a `themes-states.mjs` driver state, or an enumerated `status:gated` cell, with no committed golden (the self-gate anti-pattern). Exit 1.
3. **Drift guard** — any component's enumerated open-core count ≠ its `DEPTH-AUDIT.md` `(C core)` header. The ledger and the audit are mutually pinned; neither drifts silently. Exit 3.
4. **Mapping** — a committed golden whose id-group isn't mapped to a component in `required.json` (warns).

## What's still coarse (honest notes, tightened by STR-381 proper)

- The denominator's behavioral debt is `core_gaps_open` summed from `DEPTH-AUDIT.md`
  headers (110), not yet one row per individual missing cell. When STR-381 enumerates the
  full upstream prop×state surface, `required.json` gains explicit per-cell `missing` ids
  and the denominator sharpens.
- `presets_gated` is a single scalar (native preset only). When STR-383 lands the preset
  layer + per-preset goldens, this becomes a per-cell×preset tally and the behavioral-
  invariance check (DOM-identical-across-presets) joins the gate.
