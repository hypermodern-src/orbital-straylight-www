```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  // hypermodern // consulting
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

the ORBITAL deck mock (`original-mocks/hypermodern-website-final`),
fully reproduced on hydrogen. horizontal = sections, vertical = depth.

PureScript is built only through the pinned Spago CLI. Within this monorepo the
Hydrogen dependency resolves to `../hydrogen`; a future repository split only
needs to replace that one `extraPackages` path with a pinned source dependency.

- `purescript/src/Site/Content.purs` — the seven panels, class-for-class
- `purescript/src/Site/Deck.purs` — the state machine (page, overlay,
  onosendai theme, keyboard/wheel/touch paging, 900ms transition lock)
- `purescript/src/Site/Deck.js` — the scroll-linked painting, ported
  function-for-function from `orbital-site.js` (reveal, rails, count-ups)
- `styles/orbital-deck.css` — verbatim from halogen-orbital

#### // `method`

```
❯ bun install
❯ bun run build     # spago bundle + hydrogen ssg -> dist/
❯ bun run serve     # http://localhost:8739
```
