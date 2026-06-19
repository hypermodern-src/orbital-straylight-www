# STRAYLIGHT Frontend Architecture — design doc (v0, to haggle)

Status: **draft for argument.** This is the shared map of what we're building
across the repos, the layering, the typeclass-axis app model, and the open
questions. Decisions marked **[D]**; open questions marked **[?]**. Nothing here
is sacred — the point is to argue it into shape before we overbuild.

---

## Round update — 2026-06-13: the component library is a radix-ui port, in hydrogen

**[D] Stop the infinite regress.** `purescript-radix` (Lean behavior-algebra →
components) and `verified-purescript` (proof-carrying extraction) are **filed as
research oddities** — interesting, real, but *not load-bearing*. We chased the
"run out the verified generator to 48 themeable components" bet to its source and
it doesn't hold: the behavior-algebra compiler was archived in the radix
reconciliation (`archive/behavior-algebra-compiler`), only ever had real specs for
~3 components with stubbed composition proofs; and `verified-purescript` is a
pure-algebraic-law prover (`rfl`-grade) that structurally cannot reach interactive
UI behavior (you can't prove "Escape closes the dialog" by reflexivity). Reviving
it is a months-long bet on the least-leveraged 40%. We pass.

**[D] The component library is a hand-written PureScript/Halogen port of
`radix-ui/primitives`, living *inside* hydrogen.** We vendor radix-ui as a
**read-only reference** (`~/src/vendor/primitives`, the React monorepo — 59
packages, ~23.6k LOC TS) and port behavior primitive-by-primitive into our own PS
modules. **We never import a radix npm package** — no marriage to the monolith.
Brute-forced with subagents (one component per agent) over a shared set of ported
behaviors. The two good things radix-pure already produced (Dialog, Tabs + the
FocusScope/AriaHider/Id FFI) are the seed.

**[D] Get the flake-juggling down.** Filing radix + verified-purescript as
oddities removes two flakes/cells from the active set. The components do **not**
get their own repo/flake — they live in the `hydrogen//` cell. Active flake set is
now: `straylight-prelude` · `hydrogen` (framework **+ component library**) ·
`halogen-orbital` (ORBITAL look, → presets) · the apps. (`purescript-radix`,
`verified-purescript` parked.)

**[D] The styling amenity is the preset/token contract, not codegen.** A component
is written once; a **preset** (`StyleConfig`: which classes land on
root/trigger/overlay/content/item/…) themes it. `semantic | tailwind | shadcn |
daisy | **orbital**`. ORBITAL and the *new* designs become presets — that is the
"styling amenities for days," and it needs none of the Lean machinery. The preset
record threads as component input. See §5 tree + §6.

**[D] Ground-up, artisanal — no FFI in the core.** Port fresh from radix-ui
source; do **not** borrow radix-pure's modules (parked, potentially hinky). The
component library is **100% PureScript, zero external-JS dependency** — positioning
math (floating-ui) is **ported native**, not FFI'd to `@floating-ui/dom`. Platform
access (focus, `getComputedStyle`, `getBoundingClientRect`) goes through
`purescript-web-*`, with thin DOM shims only where those bindings don't reach —
never a dependency on a JS library. **This is precedent-setting**: FFI to external
JS is allowed only at the *integration/test* edges (Playwright, maybe
Supabase/Clerk), never in the radix core. The bar: reproduce *any* radix-based
outcome — shadcn, daisy, **ORBITAL // DESIGN** — as a preset over one native engine.

**[D] Also taking from the radix-ui org (we're here once):** `colors` (30 hues ×
12 steps × light/dark/alpha/P3 — the accessible token foundation) →
`Hydrogen.Radix.Color`; `icons` (332 SVGs) → a vendored asset set; `themes` →
**reference only** (study its variant/size/color/radius prop API to inform
`Style.purs`; we replace its look with ORBITAL+presets). Skip website /
design-system / auth / radix-legacy as code. **Port reference** stays the read-only
`~/src/vendor/{primitives,colors,icons,themes}` clones — never npm deps.

**[D] buck = namespace = disk, 1:1.** The component library is just
`hydrogen/src/Hydrogen/Radix/`, already covered by the existing `hydrogen//:lib`
glob (`src/**`). No `ui/` dir, no separate `//ui:lib` (that was a confusing
mismatch). Disk `src/Hydrogen/Radix/` ↔ module `Hydrogen.Radix.*` ↔ cell
`hydrogen//`. We split into disk-matching sub-targets (a BUCK *inside*
`src/Hydrogen/Radix/`) only if compile cost later demands it.

---

## 0. Thesis

We are building, bottom to top:

1. a **polyglot build/package tool** (`straylight-prelude`) on modern build
   theory — content-addressed, hermetic actions, REAPI remote execution — that
   knows _both_ source packages and compiled artifacts. **Nix is contained**
   behind it (a source-grader/toolchain-provider getting unrolled into REAPI),
   not the orchestrator.
2. a **frontend framework** (`hydrogen`) in PureScript/Halogen with a clean
   **plugin/integration frame** at the library level.
3. an **accessible component substrate** (`purescript-radix`) — Radix-UI
   behaviors specified in Lean and code-generated to PureScript.
4. a **design system** (`ORBITAL`, today in `halogen-orbital` as HTML/CSS/JS)
   ported onto radix + hydrogen as real Halogen components.
5. **apps** (straylight-web, reinit-dx, + a first batch of three websites and one
   app) — each one a choice of _instances_ for a small set of axes, plus
   components; mutually independent except for sharing libraries.

The unifying idea: **an application is a product of typeclass instances** —
`Auth × Surface × Deploy (× Test?)` — over a body of components. Swap an
instance, not the app.

---

## 1. The layers

```
  apps         straylight-web · reinit-dx · <3 sites + 1 app> · looking-local
                 │  choose instances: Auth × Surface × Deploy (+ hydrogen_test)
  design        ORBITAL  (halogen-orbital: HTML/CSS/JS  →  Halogen components)
  framework     hydrogen  (monorepo: core · frame/axes · integrations · ui · test)
  components     purescript-radix  (Lean behavior-algebra → accessible PS prims)
  build/pkg     straylight-prelude  (polyglot, content-addressed, REAPI; nix contained)
```

Each layer depends only downward. The prelude **takes no position** on any layer
above it — it ships language/build/package primitives; hydrogen composes them
into the frame. That agnosticism is load-bearing: it's what lets a second
"hydrogen-like" framework exist on the same foundation.

---

## 2. Repository map

| Repo                                  | Role                                                | Layer      | Canonical           | State / debt                                                                                                 |
| ------------------------------------- | --------------------------------------------------- | ---------- | ------------------- | ------------------------------------------------------------------------------------------------------------ |
| `straylight-prelude`                  | polyglot build/pkg tool (Dhall→Starlark→buck2)      | build      | sensenet-ai         | live; npm placement-tree, `npm_build`, deploy axis, artifacts all landed                                     |
| `hydrogen`                            | framework + frame + integrations + **component library** + test | framework + components | sensenet-ai | the **monorepo**; Frame/Surface/integrations landed; component library = radix-ui port (§5/§6) lands here    |
| `~/src/vendor/primitives`             | **radix-ui/primitives — read-only port reference**  | (vendor)   | upstream            | 59 pkgs / ~23.6k LOC TS; the source we hand-port from. **Not a dependency**; never imported as npm           |
| `purescript-radix`                    | ~~Lean behavior-algebra → components~~              | (parked)   | sensenet-ai         | **filed as research oddity.** Seeded Dialog/Tabs + FocusScope/AriaHider/Id FFI; generator archived           |
| `verified-purescript`                 | ~~proof-carrying PS extraction~~                    | (parked)   | sensenet-ai         | **filed as research oddity.** Real `rfl`-grade pure-law prover; can't reach interactive UI behavior          |
| `halogen-orbital`                     | ORBITAL design system (HTML/CSS/JS + a PWA ref)     | design     | straylight-software | needs porting → Halogen; holds `looking-local/` (multi-screen PWA), `orbital.css/js`, component galleries    |
| `straylight-web`                      | medium-complexity reactive site (the testbed)       | app        | sensenet-ai         | on the axes now; reflow + Supabase placeholder; "can afford to fuck up"                                      |
| `reinit-dx` (+ `-website`)            | reference app; **breaks overfit** to straylight-web | app        | sensenet-ai         | buck2 PS project + Next wrap; the second testbed                                                             |
| (`looking-local`, in halogen-orbital) | full HTML PWA reference (≈14 screens)               | design/app | —                   | the concrete "14-screen PWA" shape lives here as HTML                                                        |

**[D]** Canonical org is `sensenet-ai`; `straylight-software` is legacy. **[?]**
purescript-radix and halogen-orbital still have their real history on the legacy
remote — reconcile to sensenet-ai before building on them.

---

## 3. Build/package foundation — `straylight-prelude`

Framework-agnostic. What it provides that the frontend uses:

- **PureScript**: `purescript_library` / `purescript_app` / `purs_site` (SSG) /
  `purs_browser_bundle` (embeddable bundle) / `purs_compile`. Registry closure
  resolved offline (no spago).
- **npm as a resolved placement tree** (the real ontology): `bun.lock` keys
  encode bun's solved hoist-then-nest; `npm-resolve-lock.py` images it; the IR
  materializes the real nested `node_modules` (proven on Clerk's 562-placement /
  depth-5 closure); peers/host-provided = `External` (sidecar → esbuild
  `--external`). This is what lets _any_ node toolchain's deps live in the graph.
- **`npm_build`**: generic node build (node + closure + `cmd` → artifact). Proven
  running `next build` as a hermetic buck2 action — the nix-containment beachhead.
- **`artifacts`**: materialize a buck2 target's output as a store path (the seam
  a foreign build, e.g. Next, consumes).
- **Deploy axis** (`DeployTarget {name, pack, push}`): pluggable provider, Vercel
  the first instance.
- **REAPI**: remote-execution config is plumbed (off). **[D]** Target end-state:
  buck2/REAPI is primary, nix is the contained source-grader/toolchain-provider.

**[?]** Cleanups owed: extract the npm closure/build machinery out of
`Render/PureScript.dhall` into `Render/Npm.dhall` (it's node-generic); give
`npm_build` its own node toolchain (it currently borrows purescript's).

---

## 4. The application model — the axes

A hydrogen app is configured by selecting an **instance per axis**, over a body
of components:

| Axis        | Interface                                   | Lives         | Instances                               | Status                                          |
| ----------- | ------------------------------------------- | ------------- | --------------------------------------- | ----------------------------------------------- |
| **Auth**    | `AuthProvider` (PS)                         | runtime       | Supabase, Clerk                         | ✅ `Session`, `guardRoute`, provider-agnostic   |
| **Surface** | `SurfaceContext = Host × SurfaceClass` (PS) | runtime       | Browser/PWA/Native × Compact/Cozy/Roomy | ✅ live reflow; `reactive`/`bySurface`/`byHost` |
| **Deploy**  | `DeployTarget {name,pack,push}` (build)     | build         | Vercel                                  | ✅ pluggable; provider-suffixed runnable        |
| **Test**    | `hydrogen_test` (capability, not axis yet)  | build         | Playwright                              | **[D]** a tool *over* an app (§7); promote to a `TestHarness` axis only if a 2nd harness appears |

Operational triad (real today): **build** (`nix build`), **preview**
(`nix run .#dev`), **deploy** (the runnable). Each is an instance/verb; the app
logic never names a concrete provider.

**[D]** Auth and Surface are runtime PS typeclasses; Deploy is a build-level
instance. They live at different levels but share the concept "pluggable instance
per axis." We do **not** force Deploy into PS just for uniformity.

---

## 5. `hydrogen` as a monorepo — the library-level plugin/integration story

**[D] Incubation principle.** Everything incubates in `hydrogen` under one clean
tree; we **split out opportunistically, on durable orthogonality** — a subtree
graduates to its own repo (radix → `purescript-radix`, design → `halogen-orbital`,
test → a playwright repo) only once its boundary has proven stable. Don't split
early; don't bolt unrelated things together. The monorepo is one buck2 cell
(`hydrogen//`) of `purescript_library` packages, composed via `hydrogen//:defs.bzl`
macros + the transitive `PursLibInfo` provider (a lib's npm closure rides up to
consumers automatically).

**[D] hydrogen's first-order ontology** — the concepts the frame is *about*:
the framework **core**; the **axes** (Auth, Surface, Deploy, Test); **Integration**
(a plugin instance); and — at minimum — **Design System**, **Component Library**,
and **Component**. The last three are first-order, not incidental: an app is
components drawn from a component library, styled by a design system.

**[D] Concrete tree** (updated 2026-06-13 — the component library is the radix-ui
port; everything lives in the one `hydrogen//` cell to keep flake-juggling down).
Flag anything that looks like trouble:

```
hydrogen/                       ONE buck2 cell (hydrogen//), ONE flake. No sub-flakes.
  defs.bzl                      frame macros: hydrogen_app · hydrogen_integration · hydrogen_test
  BUCK                          targets below — all in this cell
  flake.nix                     the single dev/build flake (framework + components)

  src/Hydrogen/                 //:lib — the framework CORE (unchanged)
    Router.purs                 routing + RouteMetadata
    Frame.purs                  axes: AuthProvider · FrameworkContext · Session · guardRoute
    Surface.purs                axis: Host × SurfaceClass · SurfaceView · reflow
    Query.purs  Data/RemoteData.purs  data/state
    HTML/Renderer.purs          Halogen → string (SSG/prerender)

    Radix/                      THE COMPONENT LIBRARY (radix-ui port), namespace
                                Hydrogen.Radix.*. Covered by //:lib's src/** glob —
                                disk = namespace = cell, 1:1. No separate target.
      Color.purs                radix `colors` ported: 30 hues × 12 steps × light/dark/
                                alpha/P3, + CSS-var emitter. The token foundation.
      Style.purs                THE STYLING AMENITY: StyleConfig + Preset
                                (Semantic|Tailwind|Shadcn|Daisy|Orbital), threaded as
                                component input. ORBITAL + new designs = presets.
      Behavior/                 the positioning-independent substrate (port FIRST —
                                ground-up, native PS, no external FFI):
        ControllableState · Presence · DismissableLayer · FocusScope · RovingFocus
        Collection · Portal · Direction · Id · VisuallyHidden · Announce
      Float/                    the NATIVE floating-ui port (positioning engine):
        Compute.purs (offset/flip/shift/arrow middleware) · Popper.purs
      <Component>.purs          one module per radix primitive, FLAT under Radix
                                (radix-ui style), subagent unit, ~31:
        Dialog · AlertDialog · Popover · Tooltip · HoverCard · Collapsible · Accordion
        DropdownMenu · ContextMenu · Menubar · NavigationMenu · Toolbar · Tabs · Select
        Checkbox · Switch · RadioGroup · Slider · Toggle · ToggleGroup · Toast · Form
        Label · Separator · AspectRatio · Avatar · Progress · …
        (presentational ORBITAL vocab — Card/Badge/Hero/Nav/Status — lands here too,
         same Style contract, once the look ports)

  integrations/                 plugin INSTANCES (each //integrations/<x>:lib)
    supabase/  clerk/           AuthProvider                 (FFI allowed — edge)
    next/                       build-contributor (npm_build)            [later]

  test/                         //test:lib + the hydrogen_test rule — Playwright FFI
    src/Hydrogen/Test/Playwright.purs                        (FFI allowed — edge)
```

**[D]** No `design/` / `components/` / `behaviors/` / `ui/` as separate buck cells
or directories — over-structured and name-mismatched. The library is plain
`src/Hydrogen/Radix/` under the single `hydrogen//:lib`, organized by namespace:
`Color` · `Style` · `Behavior/` (substrate) · `Float/` (native positioning) ·
flat `<Component>.purs`. ORBITAL is a **preset** in `Style.purs`, not a
design-system cell; `halogen-orbital` stays the *source of the look* we translate
into the orbital preset + the presentational primitives. **Port reference** is the
read-only `~/src/vendor/{primitives,colors,icons,themes}` — never npm deps.

The frame contract an integration implements (separate small classes, not one
god-`Integration` — that cut has been right so far):

- **`AuthProvider`** — reactive auth (`subscribeAuth` + `signOut`) → the
  framework-maintained `Session`. (Clerk, Supabase.) ✅
- **`FrameworkContext`** — what the framework *gives* a plugin (navigate, current
  path, config). `RouterContext` is the concrete instance. ✅
- **build-contributor** — runs an external build (Next via `npm_build`) and
  contributes artifacts. **[?]** define the contract.
- **content-source** — contributes routes/pages from data (a CMS, MDX). This is
  where "we keep the plugin frame even though we have our own CMS" lands — the CMS
  is a content-source instance. **[?]** define the contract.

**[D]** `hydrogen_app(integrations=[...])` is the public surface; an integration
is `hydrogen_integration(...)` (a `purescript_library` + its closure).

---

## 6. Components & design system — `radix` + `ORBITAL` → `hydrogen`

The pipeline that turns ORBITAL into real components:

1. **`purescript-radix`** is the _behavior_ substrate: 7 behaviors (Disclosure,
   FocusTrap, ScrollLock, AriaHider, Dismissable, Selection, Navigation) specified
   in Lean, composed to 48 Radix-UI components, code-generated to accessible
   PureScript (Dialog/Tabs/… built). Style-agnostic (presets:
   `--semantic/--tailwind/--shadcn/--daisy`).
2. **`ORBITAL`** (in `halogen-orbital`) is the _look_: today `orbital.css` +
   `orbital.js` + `orbital-{theme,mobile,pwa,site}.js` + HTML component galleries
   - the `looking-local/` PWA. It is the visual language (successor to/rename of
     ONO-SENDAI/MAAS) — **[?]** confirm the relationship to the 8 existing themes.
3. **hydrogen `components/`** (the Component Library, first-order — §5) is the
   join: `behaviors/` (radix) + `design/orbital` tokens → **Halogen Components
   written as `SurfaceView`s** (reactive where they reflow, surface-specific where
   they must), themeable via tokens.

**[D] Design System, Component Library, Component are first-order** in hydrogen's
ontology (§5) — not afterthoughts. **[D]** Components are `SurfaceView`s
(`SurfaceContext -> HTML`); the reactive/surface-specific distinction is
first-class (proven on the Header). The design system fills these; the framework
threads one live `SurfaceContext`. **[?]** We tried to keep the component set
**roughly radix-shaped** — the exact shape gets decided *on the spot* in the
porting, not pinned here.

**[?]** Big open question: the **porting path** for ORBITAL. Options: (a) extract
ORBITAL into design _tokens_ (CSS variables) consumed by hydrogen components +
hand-port the component set onto radix; (b) treat `orbital.css` as the token
source and only port _structure_ to Halogen; (c) code-gen components from the
HTML galleries. Lean (a). And: does ORBITAL **replace** the ONO-SENDAI themes or
**subsume** them as one theme among many?

---

## 7. Testing — Playwright

A clean, comprehensive Playwright FFI exists on hydrogen branches
(`b7r6/integrate-nix-flake-check-0x01`, `dev`):
`launch`/`newPage`/`goto`/`getByRole`/`click`/`fill`/`screenshot`/… It should
**incubate in hydrogen** (a `test/` library), split out later.

**[D] Capability, not (yet) an axis.** Start with the **`hydrogen_test`** primitive
— a buck2 rule that drives a built app from outside via the Playwright FFI (it's a
*tool over* an app, not an instance *of* it). Promote to a `TestHarness` axis only
if a second harness appears. The FFI incubates in `hydrogen//test:lib`.

---

## 8. The apps

- **straylight-web** — the medium-complexity reactive site; the primary testbed,
  "can afford to fuck up." Currently the 88-screen product sprawl; the real PWA
  shape is ~14 screens (cf. `looking-local`).
- **reinit-dx** — the reference app; deliberately a _second_ testbed to **break
  the overfit** to straylight-web. Anything that only works for straylight-web
  isn't part of the frame.
- **`looking-local`** (HTML, in halogen-orbital) — a full multi-screen PWA
  reference (cities/explore/gallery/journal/… + `sw.js` + manifest). The concrete
  "14-screen PWA" target, in HTML, ready to port.
- **the first batch — [D] three websites + one app** — mutually **unrelated
  except that they depend on similar libraries** (hydrogen, the component library,
  ORBITAL). Named later. Consequence: **Auth/data is per-app, not one shared
  instance** — each picks its own Auth/Surface/Deploy instances and its own
  schema. The frame must make "another independent app on the same libraries"
  cheap; it must *not* assume a shared backend.

**[D]** Sequence the dial-in on straylight-web **and** reinit-dx together so the
frame doesn't overfit one app.

---

## 9. Sequencing

Where we are and the path:

1. **Axes + reflow** — Auth, Surface(+Host), Deploy all pluggable + demonstrated
   on straylight-web. ✅ (we are here)
2. **Reconcile to sensenet-ai** — push real `purescript-radix` + `halogen-orbital`
   to sensenet-ai (everything goes to sensenet-ai for now).
3. **Break overfit** — bring reinit-dx onto the same axes; fix whatever only
   worked for straylight-web.
4. **PWA shell + real Auth** — PWA manifest + service worker (cf. looking-local's
   `sw.js`); make the Supabase Auth instance live (real project + minimal
   schema/RLS). _(Supabase is a later graduation — main → product-pages → real.)_
5. **`hydrogen_test`** — land the Playwright FFI on main + the `hydrogen_test`
   rule (so we can drive the apps under test as we build).
6. **ORBITAL → components** — stand up `design/` + `components/` + `behaviors/`;
   port the component set as `SurfaceView`s. The big one.
7. **Clean starter template** — crystallize the minimal `hydrogen_app` seed (all
   axes + build/preview/deploy/test) once the above is dialed.
8. **The first batch** — three websites + one app, on the clean base.

The nix→REAPI containment proceeds in parallel as it's ready.

---

## 10. Decisions & remaining open questions

Resolved this round **[D]**:

1. **Test** = the `hydrogen_test` primitive (a capability/tool over the app), not
   an axis yet (§7).
2. **Monorepo** = incubate everything in `hydrogen` under one clean tree, split on
   durable orthogonality; concrete tree in §5; **design system / component library
   / component are first-order ontology**; several small hook classes, not one.
3. **Apps** = three websites + one app in the first batch, **independent except
   shared libraries** → Auth/data is per-app, no shared backend assumed (§8).
4. **Canonical** = everything goes to sensenet-ai for now (push radix +
   halogen-orbital).
5. **`Native`** = leave shape in the ontology (the `Host` axis keeps it) but **do
   not over-pivot** — native apps are probably written in native languages; we
   don't build toward a native host now.

Still open **[?]** (decide on the spot, when the code forces it):

6. **ORBITAL porting path** (§6) — tokens-first; replace vs subsume the
   ONO-SENDAI/MAAS themes. (Kept "roughly radix-shaped"; the exact shape gets
   decided in the porting.)
7. **`behaviors/` vs separate `purescript-radix`** and **`design/` vs reborn
   `halogen-orbital`** boundaries — incubate now, split when orthogonality is
   durable.
8. **Next** — removable build-contributor integration, or lean into the PS-native
   CMS so Next exits sooner?

---

## Round update — 2026-06-19: the port is built; verification is the work now

**Where we actually are.** All **32** user-facing radix primitives are ported and
compile; the substrate (7 behaviors), the native closed-form `Float`/`Popper`
engine, and the Themes (`rt-*`) preset are in tree. **Breadth is done.** What is
*not* done is proving behavioral parity — and we now measure that distance instead
of asserting it:

- `src/Hydrogen/Radix/DEPTH-AUDIT.md` — **585 gaps / 32 components** (110 core /
  250 common / 225 edge; 288 missing-in-port / 199 in-port-but-unverified / 98 partial).
- `src/Hydrogen/Radix/ARIA-AUDIT.md` — **58 blocking ARIA divergences / 14 primitives**.
- **APG keyboard** conformance exists for only ~9 of 32 components.

**The discipline that makes this non-circular.** Three CI-gated oracles diff the
port against the *real upstream React render*: golden-dom (DOM-identical), golden-aria
(ARIA tree + axe), themes-apg (WAI-ARIA APG keyboard). The rule: **close a gap = add
the oracle state that exercises it; the golden adjudicates — never blind-fix from
prose.** The reverted hand-rolled Themes layer + its self-gating `*-interaction.mjs`
tests (STR-330's "wrong turn") are exactly the anti-pattern this replaces.

**Reified.** The audits are the source-of-truth backlog; Linear **STR-330** is the
projection — `Verify+close: <Component>` per primitive (STR-349…STR-380), the TIER-1
bug epic (STR-344), and oracle-infra issues (STR-345 APG expansion, STR-346
Presence/closing, STR-347 pointer-drag, STR-348 ARIA regression-gate). Operational
detail (build, test, oracle model, conventions) lives in `CLAUDE.md`.

---

_Generated as a starting point for argument. Edit aggressively._
