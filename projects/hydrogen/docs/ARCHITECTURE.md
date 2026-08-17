# Hydrogen architecture

Hydrogen is the shared PureScript/Halogen web layer for Straylight applications.
It is deliberately split by language-level responsibility so the framework can
move into its own repository without changing module names or build semantics.

## Build boundary

Spago owns the complete PureScript dependency and module graph. The root package
builds the library and unit tests; each independently bundled browser surface has
a small local `spago.yaml` that depends on Hydrogen by path.

```text
spago.yaml
  ├─ src/**/*.purs
  └─ test/**/*.purs

examples/spago.yaml
  └─ hydrogen: { path: .. }

examples/themes-port/spago.yaml
  └─ hydrogen: { path: ../.. }

examples/themes-interactive/spago.yaml
  └─ hydrogen: { path: ../.. }

storybook/spago.yaml
  └─ hydrogen: { path: .. }
```

`package.json` pins Spago and esbuild and names the supported commands. Nix
provides Node and the PureScript compiler, then delegates to npm. There is no
second source of package, target, or module metadata.

## Module layers

Dependencies point downward:

```text
applications
  ├─ Hydrogen.Themes.*       styled component wrappers
  ├─ Hydrogen.Radix.*        behaviorally complete primitives
  └─ Hydrogen.UI.*           framework UI conveniences
         │
         ├─ Radix.Behavior.* interaction state and focus
         ├─ Radix.Float.*    pure positioning calculations
         ├─ Radix.Foundation.* DOM/style/platform boundaries
         └─ Data/Runtime     query, routing, SSG, transport
```

Application code may use the styled layer, the primitive layer, or both. A theme
must not own behavior: switching presets may change classes and CSS variables but
not normalized DOM, accessibility, keyboard behavior, or focus behavior.

## Rendering and platform seams

Most code is native PureScript. JavaScript FFI is limited to operations the
browser or Node runtime actually owns, such as DOM measurements, static-site file
output, and mounting Storybook fixtures. Computation remains in PureScript where
it can be tested without a browser.

The floating-position engine is an example of the intended shape: browser code
reads rectangles, a total PureScript function chooses and computes a placement,
and a narrow browser boundary applies the result.

## Verification model

The component system has multiple independent checks:

- strict Spago builds reject warnings and type errors;
- `spago test` covers pure framework and foundation behavior;
- the Playwright gallery compares normalized DOM and ARIA with upstream Radix;
- APG scenarios exercise keyboard and focus behavior;
- committed visual goldens catch styled rendering regressions;
- the surface ratchet prevents verified coverage from decreasing.

The external upstream render is the oracle. Tests written solely against the port
are useful unit tests, but they are not evidence of parity.

## Repository split readiness

Hydrogen currently appears both as a standalone repository and as a vendored
project in the web monorepo. Consumers depend on its public modules through a
Spago package path. A future repository split therefore changes the
`extraPackages.hydrogen` location from `path` to `git`; it does not require a new
build graph or application rewrite.

Keep these boundaries intact:

- Hydrogen owns framework and reusable component modules.
- Each application owns its routes, content, SSG entry point, and deployment.
- Browser fixture packages own only fixture-specific sources and assets.
- JavaScript tooling never becomes the authoritative PureScript dependency graph.
