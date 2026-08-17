# tests/playwright — pixel-perfect gallery tests

The Node/bun toolchain lives **here only**, isolated at the browser-test edge. The
application and component code remain native PureScript. Browser-test dependencies
are nixified with **bun2nix v2**.

## What it does

Pixel-diffs the **Hydrogen.Radix Halogen gallery** (`npm run bundle:gallery`) against
the **golden set** — radix-ui's own Storybook render of each story. radix-ui is MIT
((c) WorkOS); goldens are captured from their Storybook, not redistributed source.

## Layout

```
tests/playwright/
  package.json            bun deps (@playwright/test); bun2nix v2 → bun.nix
  playwright.config.ts    system Chromium (no browser download), 900×600 @1x,
                          snapshots ← ./golden/, exact match
  tests/gallery.spec.ts   one diff per story → golden/<id>.png
  scripts/capture-goldens.mjs   (re)capture goldens from radix's Storybook
  golden/                 committed golden PNGs (the reference)
  .gallery-dist/          built gallery (gitignored)
```

## Run it

```sh
tests/playwright/run.sh                 # build gallery + compare vs golden
tests/playwright/run.sh --update-snapshots   # (re)seed snapshots
```

`run.sh` is the entry point: it rebuilds the gallery with the pinned Spago CLI, wires
the **version-matched** Chromium from nix `playwright-driver.browsers` (so the
`@playwright/test` version and the browser revision can never drift — a mismatch is
what made the naive `executablePath` approach hang), provides bun/node/python from
nix, and runs the diff. Deterministic, ~0.4s/story, `maxDiffPixelRatio: 0`.

**Keep the versions matched.** `@playwright/test` in `package.json` MUST equal
`nix eval --raw nixpkgs#playwright-driver.version`. When bumping either, bump both,
then `bun install && nix run github:nix-community/bun2nix/2.1.0 -- -l bun.lock -o bun.nix`.

## Goldens

The committed `golden/<id>.png` is the reference. For **true equivalence** to radix
(the checkpoint), capture from radix's own Storybook (heavy; only when the story set
changes — the one step that touches radix's pnpm/React toolchain, kept here at the
edge):

```sh
( cd ~/src/vendor/primitives && pnpm install && pnpm run storybook:build )
bun run goldens          # scripts/capture-goldens.mjs, same matched Chromium
```

Until that runs, `golden/` holds the gallery's own seeded render (regression guard).
