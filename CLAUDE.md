# orbital-site

Marketing site for the Orbital product launches: **CACHE** (verified binary storage, target August 2026), **BUILD** (typed build system, target September 2026), plus the shared pricing page and the verification path. The **Orbital Confirm** runner follows later in 2026; leave room for it.

Read `02-Sales-Page-Handoff.md` before any copy or design work; its decisions and style rules are binding.

## Stack

Static HTML pages on the ORBITAL design system, vendored in `halogen-orbital/` (`orbital.css` + `orbital.js` + `orbital-theme.js`) from https://github.com/sensenet-ai/halogen-orbital. Do not fork the tokens; page-specific styles go in a `<style>` block on the page, following the idiom in that repo's `orbital-website/Orbital.html`.

- Tokens: one hue (`--hue:211`), one accent, Cormorant Garamond display / IBM Plex Mono UI, frosted glass over grain.
- Page skeleton: Google Fonts link, `orbital.css`, `body class="grain" data-ambient`, `.bar` nav, `.wrap` main, `.foot`, then `orbital.js` and `orbital-theme.js` (injects the light/dark toggle).
- Marketing layer: `.phero` split hero, `.clone` copy-paste config panel, `.sh` numbered section headers, `.feat`/`.glass` cards, `.statband`, `.ctaband`, `.term` terminal block.
- Motion: `data-reveal`, `data-reveal-stagger`, `data-split="char"`. Never gate content visibility on JS alone.

## Binding rules (from the handoff, do not relitigate)

1. Separate page per product, one shared pricing page, one subscription. Tiers gate account-level things (throughput, retention, SLAs), never which products you may use. Seats free. No SSO tax: SSO and audit logs free at every tier.
2. Two visitor paths: developers (self-serve, speed, docs) and compliance or safety-critical buyers (verification path, founder contact).
3. All pricing numbers are placeholders until the team unblocks them. On-prem and air-gapped claims are pending; do not state them. Never publish an unmeasured number: every quantitative claim is labeled measured, target, or estimate, with its basis.
4. Style: no em-dashes anywhere. Lay-readable copy, no unexplained jargon. Bold Orbital product names on first use. Never mention WARRANT or crypto positioning. Never use the names Straylight, sensenet, or weyl in site copy.

`TODO(team)` comments in the HTML mark every placeholder that needs a real value, link, or confirmation before launch.

## Run locally

Any static server, e.g. `python3 -m http.server 4173`, then open `http://localhost:4173/`.
