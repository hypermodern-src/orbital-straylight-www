# ORBITAL // FORGE

The source and publishing browser for Orbital projects. This first slice ports
the canonical Forge golden to a real PureScript/Halogen application built on
native `Hydrogen.Orbital` shell, navigation, and code-viewer primitives.

Repository metadata, clone URLs, trees, and source files come from the public
`straylight` organization on `git.s4.gl`. The browser calls Forgejo directly
over the tailnet using public, read-only GETs. Forgejo's reverse proxy allows
only the Orbital Forge origins and local development; no Forgejo credential is
shipped to the client and cross-origin credentials are not enabled.

```console
npm ci
npm run check
```

The deployed application is public static material, but live repository data is
available only to a browser connected to the S4 tailnet.
Chrome 142 and newer also asks for Local Network Access on first connection;
grant that site permission to let the static app reach `git.s4.gl`.

`nix run` performs the same checked build. `nix run .#deploy` produces the
Vercel Build Output API tree and deploys it with the pinned CLI.

The project stays in the web monorepo for now, but has an independent Spago
manifest, lockfile, Nix entrypoint, asset boundary, and Vercel output so it can
move to its own repository without changing its build contract.
