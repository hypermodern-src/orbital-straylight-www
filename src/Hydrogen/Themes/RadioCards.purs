-- | Hydrogen.Themes.RadioCards — the styled Radix Themes RadioCards.
-- |
-- | Mirrors `radio-cards.tsx` (+ `radio-cards.props.tsx`, `radio-cards.css`):
-- |
-- |   * `RadioCards.Root` is `<Grid asChild>` wrapping `RadioGroupPrimitive.Root`,
-- |     so the rendered `<div role="radiogroup">` carries BOTH `rt-Grid` (from Grid)
-- |     and `rt-RadioCardsRoot`. Own propDefs: size default `2` (className
-- |     `rt-r-size` → `rt-r-size-2`), variant default `surface` (→ `rt-variant-surface`),
-- |     plus two grid defaults — `gap` default `4` (→ `rt-r-gap-4`) and `columns`
-- |     default `repeat(auto-fit, minmax(160px, 1fr))`. `columns` is an arbitrary
-- |     (non-enum) string, so `extractProps` emits the class `rt-r-gtc` AND the inline
-- |     custom property `--grid-template-columns: repeat(auto-fit, minmax(160px, 1fr))`
-- |     (parseGridValue passes the string through unchanged). The unstyled primitive's
-- |     `role="radiogroup"`, `aria-required="false"` and `dir="ltr"` ride along.
-- |     With no `color` prop the React render emits `data-accent-color={undefined}`
-- |     (no attribute), so we omit it too.
-- |
-- |   * `RadioCards.Item` is `RadioGroupPrimitive.Item` (`asChild={false}`) → a
-- |     `<button type="button" role="radio" class="rt-reset rt-BaseCard rt-RadioCardsItem">`.
-- |     `aria-checked` / `data-state` are `true`/`checked` for the selected card and
-- |     `false`/`unchecked` otherwise — `[data-state='checked']` drives the
-- |     accent-indicator outline, so it is pixel-load-bearing. `value` is the radio's
-- |     form value. The roving-focus group gives the checked item `tabindex="0"` and
-- |     the rest `tabindex="-1"`. (The hidden bubble `<input type="radio">` is
-- |     `opacity:0` / absolutely positioned and contributes no pixels, so it is
-- |     omitted from this at-rest render.)
-- |
-- | This is the AT-REST render used for the pixel goldens: the roving-focus group
-- | (live focus handlers) and value-change wiring are a later layer over the ported
-- | primitive; only the rendered DOM + classes are reproduced here.
module Hydrogen.Themes.RadioCards
  ( radioCards
  , radioCard
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `radioCards [] [ radioCard true "a" [] [ … ], … ]`
-- | → `<div role="radiogroup" class="rt-Grid rt-RadioCardsRoot rt-r-size-2
-- |    rt-variant-surface rt-r-gtc rt-r-gap-4" style="--grid-template-columns: …">`.
-- | Size default `2`, variant default `surface`, gap default `4`, columns default
-- | `repeat(auto-fit, minmax(160px, 1fr))` (all last-wins over caller props).
radioCards :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
radioCards props =
  el "div" [ "rt-Grid", "rt-RadioCardsRoot" ]
    ( [ Size "2"
      , Variant "surface"
      , Gap "4"
      , Class "rt-r-gtc"
      , StyleProp "--grid-template-columns" "repeat(auto-fit, minmax(160px, 1fr))"
      , RawAttr "role" "radiogroup"
      , RawAttr "aria-required" "false"
      , RawAttr "dir" "ltr"
      ] <> props
    )

-- | `radioCard checked value [] [ HH.text "…" ]`. `checked` selects
-- | `aria-checked` / `data-state` (and the roving tabindex); `value` is the radio's
-- | form value.
radioCard :: forall w i. Boolean -> String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
radioCard checked value props =
  el "button" [ "rt-reset", "rt-BaseCard", "rt-RadioCardsItem" ]
    ( [ RawAttr "type" "button"
      , RawAttr "role" "radio"
      , RawAttr "value" value
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (if checked then "checked" else "unchecked")
      , RawAttr "tabindex" (if checked then "0" else "-1")
      ] <> props
    )
