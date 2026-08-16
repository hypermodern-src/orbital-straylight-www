# Orbital web

The marketing site for Orbital CACHE, BUILD, pricing, verification, and the
early-access waitlist.

## Stack

- PureScript and Halogen for typed page structure
- Hydrogen for routing and static HTML generation
- Buck2 for the build graph
- Nix for pinned tools, framework source, checks, and deployment packaging
- The vendored `halogen-orbital` design system

There is no npm dependency graph. Small browser scripts remain assets for the
vendored design-system runtime, tab and clipboard behavior, and the existing
Supabase waitlist integration.

## Check and build

From this directory:

```console
nix flake check --accept-flake-config
nix develop --accept-flake-config -c buck2 build //:site --show-output
```

The Buck2 target emits a complete static site with seven routes. Page markup
lives under `src/Orbital/Pages`, route metadata under `src/Orbital/Route.purs`,
and page-specific styles under `styles/pages`.

## Preview

Build the site, find the output path printed by Buck2, and serve that directory:

```console
nix develop --accept-flake-config -c buck2 build //:site --show-output
python3 -m http.server 4173 --directory <output-path-from-the-last-line>
```

## Deploy

The flake packages the site as Vercel Build Output API v3 and exposes a prebuilt
deploy app. Deployment is intentionally separate from the build gate:

```console
vercel link
nix run .#deploy-orbital-web-jw-site-vercel --accept-flake-config
```

Do not link or promote production until the legacy Vercel project owner and
project name have been recovered. See `docs/launch-blockers.md` for the product
and content decisions that must be resolved before launch.
