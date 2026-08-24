# PONCE International Speedway

Clean rebuild of [poncespeedway.com](https://www.poncespeedway.com/) — the
Squarespace original served a 471 KB homepage; this one serves ~4 KB of HTML
per page from a zero-dependency static build.

Bilingual (EN/ES). Seven pages: home, circuit, events, karting, auto suites,
sponsors, fan club.

## Provenance

The canonical source was recovered from Vercel deployment
`dpl_B7YErLVKzY1pLMLSY2LNmY5LGukV` on 2026-08-23. Its deployment metadata
identified local commit `89aaf530472702cfe1437d300efea2fd29ec59b0`
(`Track geometry: digitize the official circuit map`); that commit was no
longer present in any local checkout. A clean build of the recovered source
matches every production deployment file by content hash.

## Development

```bash
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
├── build.js               # SSG — all content lives here, EN/ES side by side
├── package.json           # independent build and deployment entry points
├── scripts/
│   └── generate-images.js # fal.ai image generation
├── static/
│   ├── style.css
│   └── images/
└── dist/                  # generated site
```
