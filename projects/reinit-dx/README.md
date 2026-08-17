# REINIT // DX

**Your AI broke it. We fix it.**

Landing page for vibe-coded app cleanup service. Three tiers:

- **FIX** ($149) — Debug in your existing stack
- **REINIT** ($1,490) — Rewrite critical paths in PureScript
- **VERIFY** ($14,900) — Formal verification via Lean4

## Stack

Built on the real stack to dogfood the tools:

- **PureScript** + **Halogen** — Type-safe UI
- **Hydrogen** — SSG, routing, HTML rendering
- **Tailwind** — Styling (CDN)
- **Spago** — PureScript build and dependency graph

## Development

```bash
# Install the pinned Spago and esbuild CLIs
npm ci

# Typecheck, prerender, and bundle into dist/
npm run check

# Dev server
npx serve dist -l 3333

# Expose via Tailscale
sudo tailscale funnel 3333
```

## SSG (Static Site Generation)

Pre-renders the landing page to static HTML for faster FCP and SEO:

`npm run build` performs the complete SSG and client build. `nix run .#build`
delegates to the same command inside the pinned Node/PureScript toolchain.

The SSG process:

1. Compiles PureScript
2. Bundles `Reinit.SSG` module for Node
3. Renders `staticPage` to HTML string (~49kb)
4. Injects into `public/index.html`
5. Bundles main app for client hydration

### How SSG Works with Halogen

Most page sections are static HTML — they don't use Halogen actions. These use polymorphic types:

```purescript
nav :: forall w i. HH.HTML w i  -- Works for both SSG and Halogen
```

Interactive sections (`hero`, `submit`) have event handlers, so SSG.purs provides static versions without them. Halogen hydrates on page load to restore interactivity.

## Structure

```
src/
  Main.purs           # Entry point
  Reinit/
    Page.purs         # Landing page component (~1300 lines)
    SSG.purs          # Static rendering for SSG
public/
  index.html          # HTML shell + CSS + diagnostic demo JS
  reinit.js           # Bundled PureScript app
script/
tooling/
  build-site.mjs       # Spago SSG and client bundler
```

## Features

- Live diagnostic demo (paste repo URL → animated terminal scan)
- 27 sections: hero, diagnostic, social proof, services, pricing, FAQ, deep dive, etc.
- God-mode CSS animations: scanlines, shimmer, glow, vortex, glitch
- Mobile responsive
- SEO meta tags (OG, Twitter, JSON-LD structured data)
- Shiki syntax highlighting for code blocks

## Color Palette

```
#5DCAA5  — Accent (success, CTA)
#E24B4A  — Critical (errors)
#EF9F27  — Warning
#0a0a0a  — Background
```

## Live

https://ultraviolence.osiris-walleye.ts.net
