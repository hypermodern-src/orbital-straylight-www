# Storybook build boundary

The Storybook has two explicit dependency graphs:

- `spago.yaml` owns PureScript sources and the local Hydrogen dependency.
- `package.json` owns Storybook, Vite, and other JavaScript tooling.

`build-bundle.sh` invokes the root repository's pinned Spago binary, so the
Storybook cannot silently select a different compiler frontend. It writes the
Halogen bundle and stylesheet to `dist/`; Storybook exposes that directory through
`staticDirs` and writes the final static site to `storybook-static/`.

Nix may supply Node and `purs`, but it intentionally does not reconstruct either
dependency graph. Reproducibility comes from the checked-in Spago and JavaScript
lockfiles.
