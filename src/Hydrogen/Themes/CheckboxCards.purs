-- | Hydrogen.Themes.CheckboxCards — the styled Radix Themes CheckboxCards.
-- |
-- | Mirrors `checkbox-cards.tsx`:
-- |
-- |   * `CheckboxCards.Root` is a `<Grid asChild>` wrapping the unstyled
-- |     CheckboxGroupPrimitive.Root, so the grid + group classes land on a single
-- |     `<div>`: `rt-Grid rt-CheckboxCardsRoot` + the root propDefs (size default 2 →
-- |     `rt-r-size-2`, variant default surface → `rt-variant-surface`) + the grid
-- |     defaults baked into `checkboxCardsRootPropDefs` (columns default
-- |     `repeat(auto-fit, minmax(200px, 1fr))` — an arbitrary value, so a bare
-- |     `rt-r-gtc` class plus `--grid-template-columns` custom property — and gap
-- |     default `4` → `rt-r-gap-4`). The primitive carries `dir="ltr"` at rest
-- |     (RovingFocusGroup's tabindex/roving is interactivity-only → omitted). No
-- |     `color` prop ⇒ no `data-accent-color`.
-- |
-- |   * `CheckboxCards.Item` is a `<label class="rt-BaseCard rt-CheckboxCardsItem">`
-- |     (note: NO `rt-reset` on the label) whose children render FIRST, followed by
-- |     the checkbox button. The button is the base-checkbox primitive with
-- |     `rt-reset rt-BaseCheckboxRoot rt-CheckboxCardCheckbox` + the size/variant
-- |     extracted from context (size 2, static variant surface) →
-- |     `rt-r-size-2 rt-variant-surface`. When checked it holds the
-- |     `rt-BaseCheckboxIndicator` ThickCheckIcon SVG and `data-state="checked"`;
-- |     unchecked is an empty button with `data-state="unchecked"`. The hidden form
-- |     bubble-input is absolutely-positioned + visually hidden (no pixels) → omitted.
-- |
-- | This is the AT-REST render used for the pixel goldens; live toggling is a later
-- | layer over the ported primitive.
module Hydrogen.Themes.CheckboxCards
  ( checkboxCards
  , checkboxCard
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Core (Namespace(..))
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), el)

-- | CheckboxCards.Root — the grid of cards. Defaults: size 2, variant surface,
-- | columns `repeat(auto-fit, minmax(200px, 1fr))`, gap 4 (all last-wins so the
-- | caller can override). Reproduces `<Grid asChild>` collapsing onto the group div.
checkboxCards :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
checkboxCards props =
  el "div" [ "rt-Grid", "rt-CheckboxCardsRoot" ]
    ( [ Size "2"
      , Variant "surface"
      -- columns default is an arbitrary value → bare rt-r-gtc class + custom prop.
      , Class "rt-r-gtc"
      , StyleProp "--grid-template-columns" "repeat(auto-fit, minmax(200px, 1fr))"
      , Gap "4"
      , RawAttr "dir" "ltr"
      ] <> props
    )

-- | CheckboxCards.Item — one card. `checked` selects the checkbox state. Children
-- | (e.g. a Text label) render before the absolutely-positioned checkbox button.
checkboxCard :: forall w i. Boolean -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
checkboxCard checked props children =
  el "label" [ "rt-BaseCard", "rt-CheckboxCardsItem" ] props
    ( children <> [ checkboxButton ] )
  where
  checkboxButton =
    el "button" [ "rt-reset", "rt-BaseCheckboxRoot", "rt-CheckboxCardCheckbox" ]
      [ Size "2"
      , Variant "surface"
      , RawAttr "type" "button"
      , RawAttr "role" "checkbox"
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (if checked then "checked" else "unchecked")
      , RawAttr "value" "on"
      ]
      (if checked then [ indicator ] else [])

  svgNS = Namespace "http://www.w3.org/2000/svg"

  -- The Indicator renders the ThickCheckIcon via Slot, merging the indicator class
  -- onto the <svg> itself (no wrapper). SVGElement.className is a read-only
  -- SVGAnimatedString, so the class is set via setAttribute (HP.attr "class"),
  -- not HP.class_ (which assigns the DOM property and throws on SVG).
  indicator =
    HH.elementNS svgNS (HH.ElemName "svg")
      [ HP.attr (HH.AttrName "class") "rt-BaseCheckboxIndicator"
      , HP.attr (HH.AttrName "data-state") "checked"
      , HP.attr (HH.AttrName "width") "9"
      , HP.attr (HH.AttrName "height") "9"
      , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
      , HP.attr (HH.AttrName "fill") "currentcolor"
      , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
      , HP.style "pointer-events: none;"
      ]
      [ HH.elementNS svgNS (HH.ElemName "path")
          [ HP.attr (HH.AttrName "fill-rule") "evenodd"
          , HP.attr (HH.AttrName "clip-rule") "evenodd"
          , HP.attr (HH.AttrName "d")
              "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
          ]
          []
      ]
