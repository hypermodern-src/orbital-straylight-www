# Straylight web

The working monorepo for Straylight's Hydrogen-based web stack.

The repository is deliberately shallow: every project remains an independent
build root under `projects/`, and root-level files only inventory and orchestrate
those projects. Shared code crosses a project boundary through an explicit
package dependency.

## PureScript build standard

Spago is the sole PureScript dependency graph throughout this repository. Each
PureScript project owns a checked-in `spago.yaml` and `spago.lock`, pins its local
Spago CLI, and treats warnings as errors. Nix may provide Node, `purs`, and a
hermetic dependency closure, but always delegates compilation and bundling to
Spago.

Applications currently resolve Hydrogen through an explicit local Spago package
path. That is the planned repository-split seam: extraction replaces the path
with a pinned forge source without changing application imports or introducing a
second build definition.

## Projects

| Project | Role | Production surface |
| --- | --- | --- |
| `hydrogen` | PureScript/Halogen framework, Radix port, Storybook, and gallery | `orbital-showroom` |
| `straylight-web` | Straylight product and company web application | `straylight-web` |
| `reinit-dx` | Reference Hydrogen SSG application | `reinit-dx` after cutover |
| `hypermodern-consulting` | Hydrogen SSG consultancy site | `hypermodern-website` |
| `orbital-web-jw` | Orbital product marketing Hydrogen SSG | `orbital-web-jw` |
| `web-middleware` | Language-neutral HTTP policy contract with a Haskell/WAI adapter | — |
| `orbital-cms` | PostgreSQL publishing core and delivery API for articles and papers | — |
| `orbital-forge` | PureScript forge UI with a replaceable Haskell backend | `orbital-forge` |
| `ponce-speedway` | Bilingual zero-dependency PONCE International Speedway SSG | `ponce-speedway` |
| `camp-caribe` | Bilingual Hydrogen SSG for the Camp Caribe private coastal campus | preview pending |

The old `reinit-dx-website` Next.js wrapper remains outside the monorepo while
it serves production. It is deployment history, not the canonical application.

## Working here

Run one project's native check:

```console
./scripts/check hydrogen
./scripts/check reinit-dx
./scripts/check hypermodern-consulting
./scripts/check straylight-web
./scripts/check orbital-web-jw
./scripts/check web-middleware
./scripts/check orbital-cms
./scripts/check orbital-forge
./scripts/check ponce-speedway
./scripts/check camp-caribe
```

Run every check:

```console
./scripts/check
```

See [`docs/BOUNDARIES.md`](docs/BOUNDARIES.md) before introducing a shared
dependency, and [`docs/VERCEL.md`](docs/VERCEL.md) before relinking a Vercel
project.
