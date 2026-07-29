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

## Pre-launch waitlist (live)

Until GA the primary CTA sitewide is "Get early access": a two-field form (email + optional "what do you build with") on index, cache, and build pages, posting to Supabase project `orbital-site` (`lhmodcikykyoxpaojeyn`, org jwpr). `waitlist.js` holds the project URL and publishable key (public by design). The `waitlist_signups` table has RLS enabled with no policies and all direct grants revoked; the browser can only call three RPCs: `join_waitlist` (insert, returns position + referral code), `waitlist_count`, and `referral_count`. Emails are not readable with the shipped key; exports for the mail tool need the service-role key. Supabase security advisors flag the anon-executable SECURITY DEFINER functions; that is the intended access path.

`thanks.html` is the confirmation page: queue position, referral link (`?r=CODE`, attributed via localStorage), reward progress, pre-written share text, one-tap share links (X, Hacker News, LinkedIn). Signups also store first-touch UTM params and external referrer (`signup_source` column) for per-channel conversion analysis, and `join_waitlist` rejects common disposable-email domains. Reward copy is placeholder-labeled until pricing resolves. Live signup counters render only at 25+ signups (threshold in `waitlist.js`); counts are always real, never seeded. Email drafts live in `docs/email-sequence.md`. At launch: swap forms back to "Start free" signup CTAs and update the origin in thanks.html referral links to the production domain.

## Run locally

Any static server against the repo root, e.g. `python3 -m http.server 4173`, then open `http://localhost:4173/`. No build needed for development.

## Deploy

Vercel runs `npm run build` (see `build.mjs`): it copies the site into `dist/` and minifies CSS/JS there with esbuild. Source files, including the vendored `halogen-orbital/` design system, stay byte-identical to upstream in git; never commit minified copies or edit the vendored files. Deploy with `npx vercel@latest deploy --prod --yes --scope mclbbk-1351s-projects`.
