# ORBITAL design system

`Hydrogen.Orbital` is the native PureScript/Halogen expression of the ORBITAL
design guide. It is a preset alongside `Hydrogen.Themes`, not a modification of
the Radix compatibility port. Radix oracle work can therefore continue without
brand-specific classes leaking into its DOM.

## Load the system

Copy `assets/orbital/` into the application's public assets and link the native
entry point:

```html
<link rel="stylesheet" href="/orbital/hydrogen.css">
```

`hydrogen.css` imports the canonical design-system payload and adds only the
PureScript typography role classes, focus/disabled behaviour, and reduced-motion
rules. The canonical CSS, semantic aliases, font files, data styles, favicon,
and monotile artwork are carried byte-for-byte from `Orbital Design System.zip`.

The light surface is the default. Ono-sendai is a token swap on the document
root:

```html
<html lang="en" data-theme="onosendai">
```

Remove `data-theme` to return to light. Do not select the theme through a media
query and do not ship a second dark component tree. A consumer surface that
needs true black may additionally set `data-surface="black"` on the root.

## Foundations

`Hydrogen.Orbital.Foundation` closes the guide's vocabulary into ADTs:

- `Appearance`: light or Ono-sendai
- `Surface`: page or true black
- `Tone`: neutral, accent, success, warning, or error
- `ComponentSize`: small, medium, or large
- semantic color, font, space, and radius tokens
- `breakpointLap = 900`, the one adaptivity breakpoint

The token functions return CSS variable references, not copied values. This is
what keeps a component theme-neutral.

## Typography

IBM Plex Mono is the voice for titles, headings, numerals, labels, body, and UI.
Use `display`, `sectionTitle`, `cardTitle`, `eyebrow`, and `body` from
`Hydrogen.Orbital.Typography` instead of selecting a family locally.

Cormorant Garamond is limited to `prose` and `pullQuote`: essays, papers, archive
entries, quotations, and axioms. It is never used for titles, labels, numerals,
prices, controls, or the wordmark.

## Implemented component contracts

| Layer | Native modules and components |
| --- | --- |
| Foundation | typed appearance, surface, tone, size, color, type, space, radius, breakpoint |
| Brand | `monotile`, `brandmark`, `watermarkField` |
| Core | `button`, `linkButton`, `linkCTA`, `badge`, `tag`, `statusDot`, `separator`, `spinner`, `progress` |
| Type | `display`, `sectionTitle`, `cardTitle`, `eyebrow`, `body`, `prose`, `pullQuote` |
| Surfaces | `glassCard`, `sectionHead`, `statBand`, `metaList`, `terminal` |

Every renderer takes a typed visual input plus an `attrs` escape hatch for ids,
data attributes, ARIA, and Halogen event handlers. Interactive elements preserve
the native element: a button is a `<button type="button">`; an action with an
`href` is an anchor. Progress, spinners, status decoration, and separators ship
their baseline semantics rather than relying on appearance alone.

## Porting order

New families should be added from the bottom up:

1. Reuse a semantic token. Do not add a component-local color, family, curve,
   radius, shadow, or breakpoint.
2. Preserve the exact class and DOM contract from the design bundle.
3. Reuse a `Hydrogen.Radix` behavior primitive when the component is stateful.
   ORBITAL owns the preset; Radix owns focus, keyboard, presence, and overlay
   behavior.
4. Encode visual axes as closed types and leave DOM/event attributes open.
5. Add semantics and reduced-motion behavior before adding the reference story.
6. Verify light and Ono-sendai at both sides of the 900px breakpoint.

The next useful tranche is Forms and Navigation, built over the existing native
Checkbox, RadioGroup, Switch, Slider, Select, Tabs, ToggleGroup, and Toolbar
behaviors. Shells and overlays should follow after those foundations are proven.
