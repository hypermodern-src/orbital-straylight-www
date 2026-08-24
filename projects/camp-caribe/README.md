# Camp Caribe

Bilingual Camp Caribe venue site built as a static Hydrogen application with
PureScript and Spago. The current production site remains untouched until this
build is reviewed and explicitly promoted.

## Development

```bash
npm ci
npm run build
npm run serve
```

`npm run build:vercel` emits Vercel Build Output API v3 under
`.vercel/output/`. `nix run` executes the same strict Spago check through the
pinned Nix toolchain.

The default build is the Tidal events concept. Three additional art directions
use the same typed content and component tree:

```bash
CAMP_CONCEPT=salt npm run build:vercel
CAMP_CONCEPT=heritage npm run build:vercel
CAMP_CONCEPT=black-sand npm run build:vercel
```

Each concept is delivered as a separate immutable Vercel preview. Concept CSS
is layered after the shared responsive and accessible component system.

## Structure

```text
camp-caribe/
├── content/site.json      # typed English and Spanish editorial content
├── src/Camp/              # Hydrogen components and static renderer
├── static/                # styles, interaction, fonts, imagery, and footage
├── tooling/build-site.mjs # strict Spago build and asset assembly
├── spago.yaml             # local Hydrogen dependency and PureScript graph
└── flake.nix              # reproducible project entry points
```

## Asset provenance

The logo, four video clips, and all documentary stills were recovered from the
public `campcaribe.com` site on 2026-08-23. The six generic stock images formerly
used for audience categories were deliberately excluded because they did not
document the property.

`static/images/hero-aerial.webp` is a non-destructive, AI-assisted restoration
derived from the recovered aerial photograph. The edit was constrained to
clarity, dynamic range, exposure, and tonal balance while preserving the actual
campus geometry and contents. `static/images/aerial-overview.jpg` retains the
unaltered source image alongside it. Documentary stills are delivered as AVIF;
the recovered JPEG originals remain preserved in the V1 repository history.
The events home page uses the real black-sand shoreline as its hero, with a
smaller responsive AVIF derivative for mobile delivery.

Instrument Serif and DM Sans are self-hosted under the SIL Open Font License;
license texts live with the font files. The civilian events direction pairs a
classic deep-teal and sun-washed-sand palette with soft architectural arches,
editorial serif typography, and an honest water-first sequence of the property.
The more operational Caribbean-modernist V2 remains frozen at
`camp-caribe-v2.vercel.app` while this concept is reviewed independently.
