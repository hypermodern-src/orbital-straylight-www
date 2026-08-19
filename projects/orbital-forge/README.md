# ORBITAL // FORGE

The source and publishing browser for Orbital projects. It is a real
PureScript/Halogen application built on native `Hydrogen.Orbital` shell,
navigation, repository, and syntax-highlighted code-viewer primitives.

Repository metadata, directory and blob views, branches, tags, commits, issues,
pull requests, releases, clone URLs, and source files come from the public
`straylight` organization on `git.s4.gl`. Repository READMEs are parsed and
rendered locally. The browser calls Forgejo directly over the tailnet using
public, read-only GETs. Forgejo's reverse proxy allows only the Orbital Forge
origins and local development; no Forgejo credential is shipped to the client
and cross-origin credentials are not enabled.

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

## Product gate

The acceptance target is **Forgejo parity**, not GitHub parity. The public
read-only repository surface is the first milestone; Orbital Forge does not
graduate from preview until the [Forgejo parity gate](FORGEJO-PARITY.md) is
closed. GitHub-only product features do not enter that gate.
