# CLAUDE.md — Hydrogen

Hydrogen is a native PureScript/Halogen framework and component system. Spago is
the sole PureScript build graph. Nix supplies tools and thin command wrappers; it
must not duplicate package or module metadata.

## Start here

The repo contains two related layers:

1. The framework: `Hydrogen.Query`, `Hydrogen.Router`, `Hydrogen.Data.*`,
   `Hydrogen.Runtime.*`, and `Hydrogen.UI.*`.
2. The component system: a native Halogen port of Radix Primitives under
   `src/Hydrogen/Radix/`, plus the styled `Hydrogen.Themes.*` layer.

Before changing `Hydrogen.Radix.*` or `Hydrogen.Themes.*`, read
`src/Hydrogen/Radix/PORTING.md`. There is no Radix npm runtime dependency and no
React bridge. DOM FFI is permitted only at explicit platform boundaries.

## Build contract

Node 22.5 or newer is required. Use the pinned local Spago and esbuild versions:

```sh
npm ci
npm run build                 # spago build --strict
npm test                      # spago test --strict
npm run check                 # build + test
```

Browser fixtures are also Spago packages:

```sh
npm run bundle:gallery
npm run bundle:themes-port
npm run bundle:themes-interactive
```

The Nix interface delegates to those commands:

```sh
nix develop
nix run .#build
nix run .#test
nix run .#check
```

PureScript dependencies belong in `spago.yaml`; JavaScript build tools belong in
`package.json`. Do not add a parallel module graph or package manifest. Zero
compiler warnings is the bar.

## Verification

The component port is judged against the real upstream React render, not
self-written expectations. The Playwright harness covers normalized DOM, ARIA,
keyboard behavior, state transitions, and pixels:

```sh
testing/playwright/run.sh
testing/playwright/run.sh --update-snapshots  # intentional re-baseline only
node testing/surface/check.mjs
node testing/surface/check.mjs --update       # intentional ratchet update only
```

The rule for closing a parity gap is to add the oracle state that exercises it,
then let the upstream golden adjudicate. The remaining work is recorded in
`src/Hydrogen/Radix/DEPTH-AUDIT.md` and `ARIA-AUDIT.md`.

## Layout

```text
src/Hydrogen/                  framework and public umbrella modules
src/Hydrogen/Radix/            native primitives
  Behavior/                    shared interaction substrate
  Float/                       native positioning engine
  Foundation/                  DOM, styling, color, portal, envelope
src/Hydrogen/Themes/           styled wrappers and tokens
test/                          Spago unit tests and support modules
examples/                      gallery Spago package
examples/themes-port/          static themes parity package
examples/themes-interactive/   interactive themes parity package
storybook/                     Storybook Spago package and JS shell
testing/playwright/            external behavioral and visual gates
```

## Component conventions

- Stateless primitives are plain render functions; stateful primitives are
  Halogen components over `Behavior.ControllableState.Controllable`.
- Stable `data-*`, ARIA, role, tabindex, and focus behavior are part of the public
  contract. Presets supply appearance only.
- Keep positioning and other finite-domain logic pure and total. Browser reads
  and writes stay at narrow DOM boundaries.
- Preserve existing goldens unless the task explicitly changes the intended
  rendering or behavior.
