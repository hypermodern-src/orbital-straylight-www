# CLAUDE.md — Hydrogen

PureScript/Halogen framework by Straylight Software, in the `sensenet-ai` monorepo.
Built with **buck2 + Nix** (`buck = namespace = disk`, 1:1). This file is the
operational map; the design narrative lives in `docs/ARCHITECTURE.md`.

## What this actually is (2026-06)

Two things share the repo, and the centre of gravity has moved:

1. **The original framework seed** — `Hydrogen.Query` (caching/SWR), `Hydrogen.Router`,
   `Hydrogen.API.Client`, `Hydrogen.SSG`, `Hydrogen.Data.RemoteData`, `Hydrogen.UI.*`.
   Still present, still compiled (the `README.md` Quick-Start is about this). Stable.
2. **The component library — a hand-written port of `radix-ui/primitives` →
   native PureScript/Halogen** (`src/Hydrogen/Radix/`). This is where the active work is.
   Per `docs/ARCHITECTURE.md`, the earlier `purescript-radix` / `verified-purescript`
   codegen bets were **parked**; the hand-port won. **No radix npm dep, no external-JS
   FFI** — even floating-ui positioning is ported native. radix-ui is vendored
   read-only at `~/src/vendor/{primitives,colors,icons,themes}` as the *reference spec*.

If a task touches `Hydrogen.Radix.*` or `Hydrogen.Themes.*`, read
`src/Hydrogen/Radix/PORTING.md` first — it is the contract.

## Build / test

```bash
# typecheck the whole framework (zero errors AND zero warnings is the bar)
nix develop -c buck2 build //src/Hydrogen/Radix:radix      # the port
nix develop -c buck2 build //:lib                           # everything

# the verification gate (the real proof — see below). Rebuilds the gallery from
# buck2 each run so the diff is never stale; nix-pinned Chromium, no drift.
testing/playwright/run.sh                 # run all gates (incl. the surface ratchet)
testing/playwright/run.sh --update-snapshots   # re-baseline (only when intended)

# the surface ratchet (STR-385) — monotone parity progress, derived from the goldens.
node testing/surface/check.mjs            # verify vs gaps.lock; nonzero exit on regression
node testing/surface/check.mjs --update   # deliberate re-baseline (record progress)

# unit suite (the math/foundation: Compute, Style, Color, Format, Router, RemoteData)
nix develop -c buck2 test //testing/suite:...   # (see testing/suite/BUCK)
```

`spago build` directly does **not** work — the build is buck2-driven (no `spago.dhall`).

## The end state — TOTAL PARITY (zero compromise)

Not a partial port, not a demo. The target (STR-330) is: **the entire upstream
radix-ui surface, tied out DOM-identical under Playwright, every primitive skinnable
by any preset, with the Storybook as the single source** (demo = golden source =
gallery). One story authored once fans out to: surface enumeration · dual render
(port + real upstream) · every preset · the Storybook.

This is enforced as an **executable CI predicate**, not a judgment call. DONE when
CI asserts ALL of:
- `cells_present == cells_required` — denominator derived from upstream (not taste); **no missing cells**
- every cell: port DOM `==` upstream DOM, byte-identical, on the **pinned** upstream sha, both faces (`Hydrogen.Radix.*` vs `@radix-ui/react-*`, `Hydrogen.Themes.*` vs `@radix-ui/themes`)
- every cell × preset {Unstyled, Themes, Shadcn, Daisy}: **behavioral DOM invariant** (role/data-\*/aria/tabindex/focus) + per-preset render matches that skin's ground truth — the machine-proof you can drop any skin on
- APG keyboard for every keyboard cell; Presence/exit + pointer-drag oracles for every animated/draggable cell
- `open == 0`, `skipped == 0`, `self-gated == 0` (waivers only on `edge`, with recorded reason+owner)
- the Storybook builds + renders the full matrix; ORBITAL preset last on the same green rails

Progress is **monotone** (the ratchet: counts only fall), **recorded** (`gaps.lock`
across `git log` IS the burndown), **hard-gated** (one buck2 target = the only merge path).

## The verification model — externally grounded, never circular

The port's whole credibility rests on being diffed against the **real upstream React
render**, never against self-written expectations. Current CI-gated oracle layers
(`testing/playwright/`, drivers in `scripts/themes-*.mjs`, baselines in
`testing/golden/themes/`) — being generalized to the full surface (STR-382):

| Oracle | Script | Proves | Baseline |
|---|---|---|---|
| **golden-dom** | `themes-{dom,open,closing}-dom.mjs` | DOM subtree byte-identical to upstream (ids→`<idN>`, px→`<px>` normalized) | `golden-dom/*.txt` |
| **golden-aria** | `themes-a11y.mjs` | ARIA accessibility tree + axe fingerprint vs upstream | `golden-aria/*.txt` |
| **themes-apg** | `themes-apg.mjs` | WAI-ARIA APG **keyboard** key→behavior conformance (spec-cited) | in-script assertions |

**The rule for closing any gap:** *add the oracle state that exercises it
(golden-first, self-stable); the gate adjudicates* — it either confirms the port
(coverage) or reveals a diff (fix). **Never blind-fix from prose; the golden is truth.**
Circular `*-interaction.mjs` self-gates are exactly the anti-pattern STR-330 corrected,
and the ratchet (STR-385) makes "self-gated" a build failure, not a style violation.

## Current status — looks-done, provably-not-yet-done

- **Breadth: complete.** All 32 user-facing radix primitives are ported and compile
  (AccessibleIcon → Tooltip). The build is green.
- **Depth: in verification, against the TOTAL-PARITY bar above.** The repo's audits
  measure the remaining distance (a *lower bound* — the manifest STR-381 will expand
  the denominator to the full prop×state×preset surface):
  - `src/Hydrogen/Radix/DEPTH-AUDIT.md` — **585 behavioral gaps across 32 components**
    (110 core / 250 common / 225 edge; 288 missing-in-port / 199 in-port-unverified / 98 partial).
  - `src/Hydrogen/Radix/ARIA-AUDIT.md` — **58 blocking ARIA divergences across 14 primitives**.
  - **APG keyboard** coverage exists for only ~9 of 32 components.
  - **Presets** (Unstyled/Themes/shadcn/daisy/ORBITAL): not yet built as a formal layer.
- This is **all tracked in Linear under STR-330** (see below). The audits are the
  source-of-truth backlog; the Linear issues are the work-tracking projection — until
  the manifest+ratchet (STR-381/385) make the manifest itself the single truth.

## Linear — STR-330 is the single source of truth

Team `// straylight //`. Parent epic **STR-330** ("Themes interactive layer — the REAL port").
Children:

- **Architecture/correction (done):** STR-331 oracle · STR-332 APG harness · STR-333 a11y ·
  STR-334 id-source · STR-337 ARIA audit · STR-338 overlay preset · STR-343 cleanup.
- **In-flight primitives:** STR-335 overlay substrate · STR-336 ContextMenu point-anchor ·
  STR-339 form controls · STR-340 ScrollArea · STR-341 Slider · STR-342 NavigationMenu/TabNav.
- **Keystones — the TOTAL-PARITY backbone (build in order 381 → 382/383 → 384 → 385):**
  - **STR-381** — Surface manifest (the upstream-derived completeness denominator).
  - **STR-382** — Dual-render tie-out harness (port vs real upstream, full surface, byte-identical).
  - **STR-383** — Preset layer + behavioral-invariance gate (Unstyled/Themes/shadcn/daisyUI; ORBITAL last).
  - **STR-384** — Storybook is the single source (one matrix → Storybook UI + Playwright gallery).
  - **STR-385** — The ratchet (monotone / hard-gated / recorded; the predicate as CI).
- **Oracle infra:** STR-345 APG expansion · STR-346 Presence/closing · STR-347 pointer-drag ·
  STR-348 ARIA regression-gate. **TIER-1 bugs:** STR-344 (14, fix first).
- **STR-349 … STR-380** — one `Verify+close: <Component>` issue per primitive (32).
  **Scope now expands:** each primitive's DoD is the full manifest surface green across
  both faces and all presets — not just its DEPTH-AUDIT core gaps. Blocked by the keystones.

The keystones come FIRST. Until the manifest + ratchet (STR-381/385) exist, "closed"
is not enforceable — the per-component issues are still prose that can drift. When you
verify a cell, the manifest/lock records it; do not hand-edit counts.

## Layout (`buck = namespace = disk`)

```
src/Hydrogen/                  Frame, Surface, umbrella (Hydrogen.purs), UI/, Data/, Runtime/
src/Hydrogen/Radix/            the 32 primitives, FLAT (radix-ui style)
  Behavior/                    substrate: ControllableState, Presence, DismissableLayer,
                               FocusScope, RovingFocus, Direction, ScrollLock, Id
  Float/                       native floating-ui port: Compute, Popper (closed-form, no reentry)
  Foundation/                  Color, Style, Portal, Dom, Envelope
  Themes/  (../Themes)         the radix-themes preset: rt-* classes over the primitives
testing/playwright/            the verification gate (run.sh + scripts/ + goldens)
testing/golden/themes/         upstream-render baselines (golden-dom, golden-aria)
testing/suite/                 PureScript unit tests
storybook/ examples/           story sources + golden/gallery apps
```

## Conventions

- **Two idioms** (`PORTING.md`): stateless primitive = plain render fn (`VisuallyHidden`);
  stateful = Halogen component over `Behavior.ControllableState.Controllable` (`Toggle` = template).
- Emit radix's **stable `data-*` / `aria-*` / `role`** attributes — they are the behavioral
  contract presets target. The *look* is never hardcoded; it comes from a swappable preset
  (`Style` record per part). Themes = the `rt-*` preset.
- Keep the 38 at-rest pixel-identical components + goldens untouched unless the task says so.
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
```
