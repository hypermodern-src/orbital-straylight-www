# Straylight web

The working monorepo for Straylight's Hydrogen-based web stack.

The repository is deliberately shallow: every project remains an independent
build root under `projects/`, and root-level files only inventory and orchestrate
those projects. Projects must not import source directly from sibling projects.
Shared code crosses a project boundary through an explicit package or build-cell
dependency.

## Projects

| Project | Role | Production surface |
| --- | --- | --- |
| `hydrogen` | PureScript/Halogen framework, Radix port, Storybook, and gallery | `orbital-showroom` |
| `straylight-web` | Straylight product and company web application | `straylight-web` |
| `reinit-dx` | Reference Hydrogen SSG application | `reinit-dx` after cutover |
| `hypermodern-consulting` | Hydrogen SSG consultancy site | `hypermodern-website` |
| `orbital-web-jw` | Orbital product marketing Hydrogen SSG | `orbital-web-jw` |
| `web-middleware` | Language-neutral HTTP policy contract with a Haskell/WAI adapter | — |
| `cms` | PostgreSQL publishing core and delivery API for articles and papers | — |

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
./scripts/check cms
```

Run every check:

```console
./scripts/check
```

See [`docs/BOUNDARIES.md`](docs/BOUNDARIES.md) before introducing a shared
dependency, and [`docs/VERCEL.md`](docs/VERCEL.md) before relinking a Vercel
project.
