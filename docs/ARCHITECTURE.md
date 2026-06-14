# STRAYLIGHT Frontend Architecture — design doc (v0, to haggle)

Status: **draft for argument.** This is the shared map of what we're building
across the repos, the layering, the typeclass-axis app model, and the open
questions. Decisions marked **[D]**; open questions marked **[?]**. Nothing here
is sacred — the point is to argue it into shape before we overbuild.

---

## 0. Thesis

We are building, bottom to top:

1. a **polyglot build/package tool** (`straylight-prelude`) on modern build
   theory — content-addressed, hermetic actions, REAPI remote execution — that
   knows *both* source packages and compiled artifacts. **Nix is contained**
   behind it (a source-grader/toolchain-provider getting unrolled into REAPI),
   not the orchestrator.
2. a **frontend framework** (`hydrogen`) in PureScript/Halogen with a clean
   **plugin/integration frame** at the library level.
3. an **accessible component substrate** (`purescript-radix`) — Radix-UI
   behaviors specified in Lean and code-generated to PureScript.
4. a **design system** (`ORBITAL`, today in `halogen-orbital` as HTML/CSS/JS)
   ported onto radix + hydrogen as real Halogen components.
5. **apps** (straylight-web, reinit-dx, + four to come) — each one a choice of
   *instances* for a small set of axes, plus components.

The unifying idea: **an application is a product of typeclass instances** —
`Auth × Surface × Deploy (× Test?)` — over a body of components. Swap an
instance, not the app.

---

## 1. The layers

```
  apps         straylight-web · reinit-dx · <four apps> · looking-local
                 │  choose instances: Auth × Surface × Deploy (× Test)
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

| Repo | Role | Layer | Canonical | State / debt |
|---|---|---|---|---|
| `straylight-prelude` | polyglot build/pkg tool (Dhall→Starlark→buck2) | build | sensenet-ai | live; npm placement-tree, `npm_build`, deploy axis, artifacts all landed |
| `purescript-radix` | Lean behavior-algebra → accessible PS components | components | sensenet-ai | **[?] split**: real work is on the straylight-software remote (`ea2b5cf`); sensenet-ai is behind — reconcile |
| `hydrogen` | the framework + frame + integrations + ui + test | framework | sensenet-ai | becoming a **monorepo**; Frame/Surface/integrations landed; Playwright on a branch |
| `halogen-orbital` | ORBITAL design system (HTML/CSS/JS + a PWA ref) | design | straylight-software | needs porting → Halogen; holds `looking-local/` (multi-screen PWA), `orbital.css/js`, component galleries |
| `straylight-web` | medium-complexity reactive site (the testbed) | app | sensenet-ai | on the axes now; reflow + Supabase placeholder; "can afford to fuck up" |
| `reinit-dx` (+ `-website`) | reference app; **breaks overfit** to straylight-web | app | sensenet-ai | buck2 PS project + Next wrap; the second testbed |
| (`looking-local`, in halogen-orbital) | full HTML PWA reference (≈14 screens) | design/app | — | the concrete "14-screen PWA" shape lives here as HTML |

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
  `--external`). This is what lets *any* node toolchain's deps live in the graph.
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

| Axis | Interface | Lives | Instances | Status |
|---|---|---|---|---|
| **Auth** | `AuthProvider` (PS) | runtime | Supabase, Clerk | ✅ `Session`, `guardRoute`, provider-agnostic |
| **Surface** | `SurfaceContext = Host × SurfaceClass` (PS) | runtime | Browser/PWA/Native × Compact/Cozy/Roomy | ✅ live reflow; `reactive`/`bySurface`/`byHost` |
| **Deploy** | `DeployTarget {name,pack,push}` (build) | build | Vercel | ✅ pluggable; provider-suffixed runnable |
| **Test** | `?` | build+runtime | Playwright | **[?]** see §7 — axis or just a capability |

Operational triad (real today): **build** (`nix build`), **preview**
(`nix run .#dev`), **deploy** (the runnable). Each is an instance/verb; the app
logic never names a concrete provider.

**[D]** Auth and Surface are runtime PS typeclasses; Deploy is a build-level
instance. They live at different levels but share the concept "pluggable instance
per axis." We do **not** force Deploy into PS just for uniformity.

---

## 5. `hydrogen` as a monorepo — the library-level plugin/integration story

This is the part that needs to get clean. hydrogen becomes a monorepo of buck2
library cells, each a `purescript_library`, composed via `hydrogen//:defs.bzl`
macros and the transitive `PursLibInfo` provider (a lib's npm closure rides up to
consumers automatically).

Proposed package layout **[?]**:

```
hydrogen/
  defs.bzl                 # hydrogen_app, hydrogen_integration (the frame macros)
  src/Hydrogen/            # core: Router, Frame (Auth/Surface), Query, RemoteData, HTML/Renderer
  integrations/
    supabase/  clerk/      # AuthProvider instances (npm-SDK closures)
    next/                  # build-contributor integration (npm_build + content hook)  [?]
  ui/                      # the component library (radix-backed, ORBITAL-styled)  [?]
  test/                    # Playwright FFI (incubate here, split out later)         [?]
```

The frame contract an integration implements:

- **`AuthProvider`** — reactive auth (`subscribeAuth` + `signOut`), feeding the
  framework-maintained `Session`. (Clerk, Supabase.) ✅
- **`FrameworkContext`** — what the framework *gives* a plugin (navigate, current
  path, config). `RouterContext` is the concrete instance. ✅
- **build-contributor** — an integration that runs an external build (Next via
  `npm_build`) and contributes artifacts. **[?]** define the contract.
- **content-source** — an integration that contributes routes/pages from data
  (a CMS, MDX). **[?]** this is where "we keep the plugin frame even though we
  have our own CMS" lands — the CMS is a content-source instance.

**[D]** `hydrogen_app(integrations=[...])` is the public surface; an integration
is `hydrogen_integration(...)` (a `purescript_library` + its closure). **[?]** The
open design is the *typeclass set* for non-auth hooks (content-source,
build-contributor, data) and whether they're one `Integration` class with
capabilities or several small classes (like Auth vs FrameworkContext are
separate). Lean toward **several small classes** — that's been the right cut so
far.

---

## 6. Components & design system — `radix` + `ORBITAL` → `hydrogen`

The pipeline that turns ORBITAL into real components:

1. **`purescript-radix`** is the *behavior* substrate: 7 behaviors (Disclosure,
   FocusTrap, ScrollLock, AriaHider, Dismissable, Selection, Navigation) specified
   in Lean, composed to 48 Radix-UI components, code-generated to accessible
   PureScript (Dialog/Tabs/… built). Style-agnostic (presets:
   `--semantic/--tailwind/--shadcn/--daisy`).
2. **`ORBITAL`** (in `halogen-orbital`) is the *look*: today `orbital.css` +
   `orbital.js` + `orbital-{theme,mobile,pwa,site}.js` + HTML component galleries
   + the `looking-local/` PWA. It is the visual language (successor to/rename of
   ONO-SENDAI/MAAS) — **[?]** confirm the relationship to the 8 existing themes.
3. **hydrogen `ui/`** is the join: radix behaviors + ORBITAL tokens →
   **Halogen components written as `SurfaceView`s** (reactive where they reflow,
   surface-specific where they must), themeable via tokens.

**[D]** Components are `SurfaceView`s (`SurfaceContext -> HTML`); the
reactive/surface-specific distinction is first-class (proven on the Header). The
design system fills these; the framework threads one live `SurfaceContext`.

**[?]** Big open question: the **porting path** for ORBITAL. Options: (a) extract
ORBITAL into design *tokens* (CSS variables) consumed by hydrogen components +
hand-port the component set onto radix; (b) treat `orbital.css` as the token
source and only port *structure* to Halogen; (c) code-gen components from the
HTML galleries. Lean (a). And: does ORBITAL **replace** the ONO-SENDAI themes or
**subsume** them as one theme among many?

---

## 7. Testing — Playwright

A clean, comprehensive Playwright FFI exists on hydrogen branches
(`b7r6/integrate-nix-flake-check-0x01`, `dev`):
`launch`/`newPage`/`goto`/`getByRole`/`click`/`fill`/`screenshot`/… It should
**incubate in hydrogen** (a `test/` library), split out later.

**[?]** Is testing an **axis** (a `TestDriver`/`Harness` typeclass instance,
parallel to Deploy) or just a capability? Argument for axis: a hydrogen app could
declare its test harness as an instance (Playwright now, others later), and the
build wires `build/preview/deploy/**test**` as a fourth verb. Argument against:
testing is orthogonal to the running app — it drives it from outside, so it's a
*tool over* an app, not an instance *of* it. **Lean: a capability/tool first
(the FFI + a `hydrogen_test` rule), promote to an axis only if a second harness
appears.**

---

## 8. The apps

- **straylight-web** — the medium-complexity reactive site; the primary testbed,
  "can afford to fuck up." Currently the 88-screen product sprawl; the real PWA
  shape is ~14 screens (cf. `looking-local`).
- **reinit-dx** — the reference app; deliberately a *second* testbed to **break
  the overfit** to straylight-web. Anything that only works for straylight-web
  isn't part of the frame.
- **`looking-local`** (HTML, in halogen-orbital) — a full multi-screen PWA
  reference (cities/explore/gallery/journal/… + `sw.js` + manifest). The concrete
  "14-screen PWA" target, in HTML, ready to port.
- **the four apps** — **[?]** named later ("when we're dialed on what we've
  already bitten off"). Not designed here.

**[D]** Sequence the dial-in on straylight-web **and** reinit-dx together so the
frame doesn't overfit one app.

---

## 9. Sequencing

Where we are and the path:

1. **Axes + reflow** — Auth, Surface(+Host), Deploy all pluggable + demonstrated
   on straylight-web. ✅ (we are here)
2. **Break overfit** — bring reinit-dx onto the same axes; fix whatever only
   worked for straylight-web.
3. **PWA shell + real Auth** — PWA manifest + service worker (cf. looking-local's
   `sw.js`); make the Supabase Auth instance live (real project + minimal
   schema/RLS). *(User flagged Supabase as a later graduation — main →
   product-pages → then real.)*
4. **ORBITAL → components** — extract tokens, port the component set onto radix
   as `SurfaceView`s; this is the big one.
5. **Clean starter template** — crystallize the minimal `hydrogen_app` seed (all
   axes + build/preview/deploy/test) once the above is dialed.
6. **The four apps** — built on the clean base.

Testing (Playwright) and the nix→REAPI containment proceed in parallel as they're
ready.

---

## 10. Open questions to haggle

1. **[?]** Test: axis or capability? (§7 — lean capability-first.)
2. **[?]** hydrogen monorepo package layout (§5) — `integrations/ ui/ test/`
   boundaries; one `Integration` class vs several small hook classes.
3. **[?]** ORBITAL porting path (§6) — tokens-first? does it replace or subsume
   the ONO-SENDAI/MAAS themes?
4. **[?]** radix ↔ orbital ↔ hydrogen boundary — does the styled component set
   live in hydrogen `ui/`, in radix (as a style preset), or in `halogen-orbital`
   reborn as a PS lib? (Lean: behaviors in radix, styled components in hydrogen,
   ORBITAL as the token/theme source.)
5. **[?]** Next: a removable build-contributor integration, or are we leaning
   harder into the PS-native CMS so Next exits sooner?
6. **[?]** Canonical-remote reconciliation — push the real `purescript-radix` and
   `halogen-orbital` histories to sensenet-ai before building on them.
7. **[?]** The four apps — when we name them, do they share one schema/backend or
   diverge? (Affects whether Auth/data is one instance or per-app.)
8. **[?]** Surface: is `Native` real on the roadmap (a real native host), or
   aspirational? Affects how hard we lean on `byHost`.

---

*Generated as a starting point for argument. Edit aggressively.*
