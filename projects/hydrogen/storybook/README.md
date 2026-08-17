# Hydrogen Storybook

Storybook 8 (`@storybook/html-vite`) presents the `Hydrogen.Themes` component
surface. Halogen owns rendering; Storybook supplies navigation, controls, and the
visual-test shell.

## Architecture

- `src/Storybook/Mount.{purs,js}` builds with the local `spago.yaml` and publishes
  `window.hydrogenStorybook.mount(id, args, el)`.
- `.storybook/preview.ts` installs the theme root and loads the bundled stylesheet.
- `stories/*.stories.ts` maps Storybook controls to the Halogen mount function.
- `build-bundle.sh` uses the root's pinned Spago binary and writes `dist/`.

## Run it

Install the root PureScript tools and Storybook's JavaScript dependencies, then
run the desired surface:

```sh
(cd .. && npm ci)
npm install
npm run storybook             # development server on :6006
npm run build                 # static output in storybook-static/
```

## Visual-regression gate

`visual-test.sh` screenshots every story with animations frozen and compares it
to the committed baselines in `__visual__/`.

```sh
./visual-test.sh
./visual-test.sh --update     # intentional baseline refresh only
```

Build outputs (`dist/`, `storybook-static/`, `node_modules/`) are ignored; visual
baselines are committed.
