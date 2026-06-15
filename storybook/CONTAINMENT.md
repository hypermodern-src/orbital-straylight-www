# Storybook → buck2 containment (done)

`nix develop -c buck2 build //storybook:static` builds `storybook-static/`
**hermetically** — nix-provided node_modules, the buck2-built Halogen bundle, no
ambient `bun install`. The standalone `bun run storybook` (dev server, fast HMR)
remains for the dev inner loop.

## How it works

- **`bun.nix`** — the node_modules manifest (`bun2nix` over `bun.lock`, every dep
  sha512-pinned). Re-run `nix run github:nix-community/bun2nix/2.1.0 -- -l bun.lock
  -o bun.nix` after changing `package.json`.
- **`flake.nix`** — `toolchain.purescript.bun2nix.storybook = ./storybook` builds
  that into a node_modules derivation; its store path lands in `.buckconfig.local`
  as `[purescript] bun2nix_storybook`. (Flake src, so only git-tracked files go in.)
- **`storybook.bzl`** — the `storybook_static` rule: stages the sources + the
  `:bundle` FFI bundle + a writable copy of the node_modules, runs the Storybook
  CLI, captures the output. It reads the bun2nix store path via
  `read_root_config("purescript", "bun2nix_storybook")`.
- **`//storybook:static`** (in `BUCK`) wires it: srcs, `bun2nix = "storybook"`, and
  the `cmd` that stages `dist/` (bundle + stylesheet for `staticDirs`) and runs
  `node node_modules/storybook/bin/index.cjs build`.

## The one wrinkle (solved)

bun2nix's default is bun's **isolated** layout: top-level `node_modules` only
symlinks the *direct* deps; the flat, node-resolvable tree (where transitive deps
like `@storybook/core` live) is `.bun/node_modules`. Plain `node` (the Storybook
CLI) can't resolve from the isolated top level. The rule's build script therefore
stages `<store>/.bun/node_modules` as `node_modules` when present — that flat tree
resolves cleanly.

## TODO (prelude upstream)

`storybook.bzl` is a thin local rule — `npm_build` with node_modules from a bun2nix
store path instead of the http_archive placement list. Upstream it as
`npm_build(npm_packages = "bun2nix#<name>")` so the documented bun2nix fragment
works for npm_build too (it currently only feeds esbuild's NODE_PATH), and the
`.bun/node_modules` handling lives in the prelude. Same shape applies to containing
the golden factory + Playwright harness.
