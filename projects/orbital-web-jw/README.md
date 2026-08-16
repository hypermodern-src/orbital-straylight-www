# Orbital web

The marketing site for Orbital CACHE, BUILD, INFER, pricing, verification, and
the early-access waitlist.

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

The Buck2 target emits a complete static site with eight routes. Page markup
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

The app is linked locally to `b7r6s-projects/orbital-web-jw`; `.vercel/` and its
OIDC credentials remain untracked. The current Vercel alias is
`https://orbital-web-jw.vercel.app`. The legacy GitHub auto-deploy remains in an
unavailable team and is not modified by this deployment path.

Do not attach a custom domain until the intended production origin and the
items in `docs/launch-blockers.md` have been resolved.
