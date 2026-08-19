# ORBITAL // FORGE

The source and publishing browser for Orbital projects. This first slice ports
the canonical Forge golden to a real PureScript/Halogen application built on
native `Hydrogen.Orbital` shell, navigation, and code-viewer primitives.

```console
npm ci
npm run check
```

`nix run` performs the same checked build. `nix run .#deploy` produces the
Vercel Build Output API tree and deploys it with the pinned CLI.

The project stays in the web monorepo for now, but has an independent Spago
manifest, lockfile, Nix entrypoint, asset boundary, and Vercel output so it can
move to its own repository without changing its build contract.
