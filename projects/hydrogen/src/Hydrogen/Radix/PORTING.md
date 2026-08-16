# Hydrogen.Radix — porting guide

Hand-port of `radix-ui/primitives` → native PureScript/Halogen. **No external-JS
FFI in this tree** (positioning math is ported native; platform access goes
through `purescript-web-*` with thin DOM shims only where unavoidable). Reference
sources are read-only at `~/src/vendor/{primitives,colors,icons,themes}` — never
npm deps.

> **Status (2026-06-19).** All **32** user-facing primitives are ported and compile
> (this guide predates several — the substrate, Float engine, and the 32 are all in
> tree now). Breadth is complete; the target is **TOTAL PARITY** (STR-330): the
> *entire* upstream radix surface tied out DOM-identical under Playwright, every
> primitive skinnable by any preset, the Storybook the single source. Remaining work
> is measured in `DEPTH-AUDIT.md` (585 behavioral gaps — a lower bound) and
> `ARIA-AUDIT.md` (58 ARIA divergences). The backbone is the five keystones:
> **STR-381** surface manifest (the completeness denominator) · **STR-382** dual-render
> tie-out (port vs real upstream) · **STR-383** the preset layer + behavioral-invariance
> gate (Unstyled/Themes/shadcn/daisyUI, ORBITAL last) · **STR-384** Storybook = single
> source · **STR-385** the ratchet (monotone, hard-gated, recorded; the zero-compromise
> predicate as CI). See `CLAUDE.md`. **The rule: close a gap = add the oracle state
> that exercises it; the golden adjudicates. Never blind-fix from prose. Presets only
> supply classes — behavior lives in the primitive, and the invariance gate proves it.**

`buck = namespace = disk`, 1:1: everything here is `Hydrogen.Radix.*` at
`hydrogen/src/Hydrogen/Radix/`, covered by `hydrogen//:lib`.

## Layout

```
Radix/
  Color.purs              radix `colors` ported (data + CSS-var emitter). The tokens.
  Style.purs              the styling contract: ClassNames + axes + data-* helpers.
  Behavior/               positioning-independent substrate (port these FIRST):
    ControllableState     controlled/uncontrolled value pattern  [DONE — template]
    Direction             ltr/rtl                                [DONE]
    Presence  DismissableLayer  FocusScope  RovingFocus  Collection  Portal  Announce
  Float/                  the NATIVE floating-ui port (positioning engine):
    Compute  Popper
  <Component>.purs        one module per primitive, FLAT (radix-ui style).
                          Toggle, VisuallyHidden = DONE templates.
```

## The two idioms (already exemplified)

**Stateless primitive** → a plain render function, no component/Slot. Takes
`Array HH.PlainHTML` children + extra `ClassNames`. See `VisuallyHidden.purs`.
Good for: Separator, Label, AspectRatio, Avatar, Progress, AccessibleIcon.

**Stateful primitive** → a Halogen component. See `Toggle.purs` (the canonical
template). Rules:

- `Input` carries controllable props (`value :: Maybe a` controlled + `defaultValue`
  uncontrolled), config, `style :: Style`, and static `children :: Array HH.PlainHTML`.
- State holds a `Behavior.ControllableState.Controllable a`; `current` is what you
  render; `change` advances it + yields the value to `H.raise`. Refresh the
  controlled slot from input in the `Receive` action (`receive = Just <<< Receive`).
- Emit radix's **stable behavioral attributes** — `data-state`, `data-orientation`,
  `data-disabled`, ARIA — via `Style` helpers, ALONGSIDE per-part classes from the
  component's `Style` record. These attrs are non-negotiable; presets' CSS targets them.
- `Query` for external control (Set/Get). `Output` fires on every user-requested
  change (including controlled mode).

## Styling contract (`Style.purs`)

- A component defines its OWN `type Style = { <part> :: ClassNames, … }` and a
  `defaultStyle` of **semantic** class names (`cn "rdx-dialog-content"`).
- A _preset_ (semantic / tailwind / shadcn / daisy / **orbital**) is a set of
  `Style` values — lands later in `Hydrogen.Radix.Preset.*`. The component never
  hardcodes a look.
- Cross-cutting axes live in `Style`: `Variant`, `Size`, `Radius`, `Side`, `Align`,
  `Orientation`, `Accent` (= `Color.Hue`). Use the `*Name` realizations + the
  `data*` emitters. Multi-part components style each part from its own `Style` field
  (no style context passed between parts — matches radix themes).

## Per-component checklist

1. Read `~/src/vendor/primitives/packages/react/<name>/src/*.tsx` + the radix.com
   docs (anatomy / keyboard map / data-attrs) as the spec.
2. Identify parts (Root/Trigger/Content/…) → the `Style` record.
3. Identify state → `Controllable`; identify behaviors it composes (Presence,
   DismissableLayer, FocusScope, RovingFocus, Popper) → import from `Behavior/`/`Float/`.
4. Emit every `data-*`/ARIA attribute radix emits (grep the TS for `data-` and
   `aria-`). These are the contract.
5. `defaultStyle` = semantic names. `defaultInput`. `Slot`/`Query`/`Output`.
6. Typecheck: `cd hydrogen && nix develop --command bash -c 'spago build 2>&1 | tail'`.
   Zero errors; keep warnings at zero.

## Float/ — the native floating-ui port (design note)

floating-ui's `computePosition` runs a runtime middleware list where a middleware
can request `reset`, restarting the pipeline (capped by `resetCount <= 50`, a gas
counter). **We do NOT replicate that loop.** That architecture exists only because
their middleware are runtime-decoupled for third-party extensibility. We have a
FIXED, finite set, so positioning is a **closed-form pure function** — no reentry,
no fuel.

The placement space is a **finite lattice**: `side ∈ {top,right,bottom,left} ×
align ∈ {start,center,end}` = 12 placements. So:

- **`flip`** = a closed-form selection: `find fits (primary : fallbacks)` over a
  fixed finite list, each candidate's fit evaluated once (memoized over the
  lattice). Not iterate-to-fixpoint.
- **`shift`** = clamp coords into the boundary rect — pure arithmetic.
- **`offset`** / **`arrow`** = pure arithmetic.

So `computePosition` ≈
`offset ∘ arrow ∘ shift ∘ (coordsFromPlacement (flip primary fallbacks rects))` —
a straight composition of pure functions over precomputed rects; no monad, no
`Writer`, no gas. Platform (`getBoundingClientRect`, viewport) via thin DOM shims;
all geometry is pure PureScript.

**Totality (the thesis):** termination is STRUCTURAL — `List/fold` over a finite
enumerated type (the lattice), not `Natural/fold` over fuel. There is no totality
witness to carry because there is no unbounded iteration. This is the strongest
form of "liftable into the Dhall / System Fω model the real build tool targets": a
total closed-form function over a finite domain. (Earlier note proposed a
gas-bounded `foldM` — wrong; the finite memoized lattice makes fuel unnecessary.)

Middleware to port first: `offset`, `flip`, `shift`, `arrow` (covers
Popover/Tooltip/Menu/Select).

## Status (port progress)

**Substrate (7) — done:** ControllableState · Direction · FocusScope · DismissableLayer ·
ScrollLock · RovingFocus · Presence. (Collection intentionally skipped — a
React-ism for enumerating arbitrary children; our data-driven primitives take
items as `Input` arrays and index them with `RovingFocus.navigate`.)

**Float (native positioning) — done:** `Float.Compute` (closed-form, finite
lattice) · `Float.Popper` (DOM wiring).

**Primitives (23) — done, all typecheck via `//check:hydrogen_check`:**
- stateless: VisuallyHidden · Label · Separator · AspectRatio · AccessibleIcon · Progress
- stateful: Toggle · Checkbox · Switch · Avatar
- disclosure: Dialog · AlertDialog · Collapsible
- roving: Tabs · RadioGroup · ToggleGroup · Accordion
- floating: Popover · Tooltip · HoverCard · DropdownMenu · ContextMenu · Select

Templates that pin each idiom: `Toggle` (stateful) · `VisuallyHidden` (stateless) ·
`Dialog` (composed/focus/dismiss) · `Tabs` (RovingFocus-consumer) · `Popover`
(Float-consumer) · `DropdownMenu` (Float + roving menu).

**Deferred (long tail):** Slider (pointer-drag — new idiom) · Menubar (menu
composition) · Toolbar (arbitrary-children roving) · NavigationMenu (complex) ·
Toast (queue + portal + swipe + timing) · Form (validation) ·
OneTimePasswordField · PasswordToggleField.

**Cross-cutting v1 simplifications to revisit:** ~~single-instance fixed ids~~ RESOLVED
(STR-334): `Behavior.Id.useId` mints a per-mount `radix-<n>` id on `Initialize`; the
overlays (Dialog/AlertDialog/Tooltip/HoverCard/Collapsible) and the roving controls
(Tabs/RadioGroup/Accordion, via a `uid`-suffixed `base`) no longer collide across
instances · ref-timing on open (validate focus under `hydrogen_test`) ·
ContextMenu element-anchored (not point-anchored) positioning · exit animations
only where Presence is wired (Collapsible) · the `Hydrogen.Radix.Preset.*` modules
(orbital/daisy/shadcn `Style` records) aren't written yet — components ship
`defaultStyle` (semantic names) only.

## Sequence

Behaviors first (they're shared substrate), then `Float/` (native positioning),
then the primitives fan out (one subagent each) against the stable behavior layer.
Within primitives: trivial/presentational → disclosure family (Dialog/Popover/…) →
roving/menu family → form controls → complex (Select/Tabs/Toast).
