# Hydrogen Storybook

Production Storybook 8 (`@storybook/html-vite`) over the **`Hydrogen.Themes`**
components — the Halogen port of Radix Themes, each story pixel-equivalent to the
upstream goldens.

## Architecture

One FFI seam, everything else is the existing Halogen library:

- **`src/Storybook/Mount.{purs,js}`** — a `purs_browser_bundle` (built by buck2 via
  `//storybook:bundle`) whose `main` publishes `window.hydrogenStorybook.mount(id,
  args, el)`. `render` maps each story's live control `args` to the component's
  `Array Prop` (arg-driven singles) or renders a representative demo (composites).
  The FFI module lives in a `purescript_library` because an app's own `srcs` are
  passed verbatim to `purs compile` (which would try to parse the `.js`).
- **`.storybook/preview.ts`** — a decorator wraps every story in the `.radix-themes`
  root (accent indigo / gray slate / radius medium, bundled Inter) and loads the
  Radix stylesheet (`themes.css`), so a story renders exactly like the golden.
- **`stories/*.stories.ts`** — one per component. Arg-driven ones expose controls
  (variant / size / color / checked / value / …); adding a story is `args` + a
  `Mount.render` case.

## Run it

```sh
bun install
bun run bundle        # buck2 build //storybook:bundle → dist/hydrogen-stories.js
bun run storybook     # dev server on :6006
# or
bun run build         # bundle + static storybook-static/
```

## Visual-regression gate

`visual-test.sh` screenshots every story with animations frozen and sha-compares to
the committed baselines in `__visual__/` — the same discipline as the component
golden gate, applied to Storybook.

```sh
./visual-test.sh            # verify (non-zero exit on any visual change)
./visual-test.sh --update   # refresh baselines after an intentional change, then commit
```

Build outputs (`dist/`, `storybook-static/`, `node_modules/`) are gitignored; the
`__visual__/` baselines are committed.

## Containment note

Standalone bun/Vite today (matching the golden-factory + Playwright harnesses, which
all consume buck2 outputs). Wrapping the Storybook build itself as a buck2 action
(bun2nix node_modules + an `npm_build`-style rule) is a cross-cutting follow-up
shared with those harnesses, not Storybook-specific.
