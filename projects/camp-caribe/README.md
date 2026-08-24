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

Instrument Serif and DM Sans are self-hosted under the SIL Open Font License;
license texts live with the font files. The visual system pairs Caribbean
modernist color and cinematic documentary imagery with an editorial serif and
precise field-note typography.
