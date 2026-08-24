# PONCE International Speedway

Clean rebuild of [poncespeedway.com](https://www.poncespeedway.com/) — the
Squarespace original served a 471 KB homepage; this Hydrogen rebuild serves
small, fully prerendered HTML pages with no client framework payload.

Bilingual (EN/ES). Seven pages: home, circuit, events, karting, auto suites,
sponsors, fan club.

## Provenance

The original JavaScript generator was recovered from Vercel deployment
`dpl_B7YErLVKzY1pLMLSY2LNmY5LGukV` on 2026-08-23. Its deployment metadata
identified local commit `89aaf530472702cfe1437d300efea2fd29ec59b0`
(`Track geometry: digitize the official circuit map`); that commit was no
longer present in any local checkout. A clean build of the recovered source
matched every production deployment file by content hash before the site was
ported to Hydrogen and PureScript.

## Development

```bash
# Install the pinned Spago toolchain
npm ci

# Build static site
npm run build

# Serve locally
npm run serve
```

## Images

`static/images/*.jpg` are currently the originals pulled from the old site's
CDN. To regenerate them with fal.ai (flux-pro v1.1, ~6 images):

```bash
rm static/images/*.jpg
FAL_KEY=... node scripts/generate-images.js static/images
```

The key lives in `~/.config/agenix/netrc` under `machine api.fal.ai`.

## Structure

```
ponce-speedway/
├── content/site.json      # typed bilingual editorial content
├── src/Ponce/             # Hydrogen components, track geometry, and SSG
├── tooling/build-site.mjs # Spago build and static-asset assembly
├── package.json           # independent build and deployment entry points
├── scripts/
│   └── generate-images.js # fal.ai image generation
├── static/
│   ├── style.css
│   └── images/
└── dist/                  # generated site
```
