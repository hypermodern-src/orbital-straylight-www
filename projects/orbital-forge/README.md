# ORBITAL // FORGE

The source and publishing browser for Orbital projects. It is a real
PureScript/Halogen application built on native `Hydrogen.Orbital` shell,
navigation, repository, and syntax-highlighted code-viewer primitives.

Repository metadata, directory and blob views, branches, tags, commits, issues,
pull requests, releases, clone URLs, and source files come from the public
`straylight` organization on `git.s4.gl`. The complete read surface includes a
recursive go-to-file palette, language-byte breakdowns, path history, immutable
permalinks, commit verification and stats, changed-file navigation, native
highlighted unified diffs, and patch downloads. SVGs, raster images, Markdown,
PDFs, audio, and video render as first-class assets; text-capable formats retain
a Preview/Source switch. Repository READMEs are parsed and rendered locally.

The browser talks to the stable `/api/forge/v1` contract. A native Haskell
WAI/Warp service currently implements that contract with a constrained Forgejo
adapter: only `GET`, `HEAD`, and preflight requests are accepted, the
`straylight` organization is allowlisted, large responses stream through, and
an optional server-side Forgejo token never enters the browser. The provider is
a record boundary, so a native repository store can replace Forgejo without
changing the UI.

```console
npm ci
npm run check
nix build .#backend
nix run .#backend
```

The backend listens on `127.0.0.1:8080`, serves `dist/` when it is present, and
reads `PORT`, `HOST`, `FORGEJO_BASE_URL`, `FORGEJO_ORGANIZATION`,
`FORGEJO_TOKEN`, `FORGE_CORS_ORIGINS`, and `FORGE_PUBLIC_DIR`. Its health check
is `/healthz`. The production static build receives its API base through the
`orbital-forge-api` meta value; set `ORBITAL_FORGE_API_BASE` during
`build:vercel` to replace the deployed backend without rebuilding PureScript.

The deployed application is public static material, but the Haskell service and
its Forgejo upstream remain available only over the S4 tailnet.
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
