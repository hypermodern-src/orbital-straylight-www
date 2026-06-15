-- | Hydrogen.Themes.Checkbox — the styled Radix Themes checkbox.
-- |
-- | `checkbox.tsx` wraps the unstyled Checkbox primitive with
-- | `rt-reset rt-BaseCheckboxRoot rt-CheckboxRoot` (size/variant defaults 2/surface)
-- | and, when checked, renders an indicator span holding the `ThickCheckIcon` SVG.
-- | This is the AT-REST render used for the pixel goldens — a static `<button
-- | role=checkbox>` in the given checked state (the hidden form bubble-input is
-- | omitted: it is absolutely-positioned + visually hidden, so it contributes no
-- | pixels). Live toggling is a later layer over the ported primitive.
module Hydrogen.Themes.Checkbox
  ( checkbox
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Core (Namespace(..))
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), el)

checkbox :: forall w i. Boolean -> Boolean -> Array Prop -> HH.HTML w i
checkbox checked isDisabled props =
  el "button" [ "rt-reset", "rt-BaseCheckboxRoot", "rt-CheckboxRoot" ]
    ( [ Size "2"
      , Variant "surface"
      , RawAttr "type" "button"
      , RawAttr "role" "checkbox"
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (if checked then "checked" else "unchecked")
      , RawAttr "value" "on"
      ] <> disabledAttrs <> props
    )
    (if checked then [ indicator ] else [])
  where
  -- both the Root and (when shown) the Indicator carry data-disabled when disabled.
  disabledAttrs = if isDisabled then [ RawAttr "disabled" "disabled", DataAttr "disabled" "true" ] else []

  svgNS = Namespace "http://www.w3.org/2000/svg"

  -- The Indicator renders the icon via Slot, merging its classes onto the <svg>
  -- itself — so the indicator IS the svg (no wrapper span), carrying the rt-*
  -- indicator classes, data-state, and pointer-events:none.
  indicator =
    -- NB: SVGElement.className is a read-only SVGAnimatedString, so the class must
    -- be set via setAttribute (HP.attr "class"), not HP.class_ (which assigns the
    -- DOM property and throws on SVG).
    HH.elementNS svgNS (HH.ElemName "svg")
      ( [ HP.attr (HH.AttrName "class") "rt-BaseCheckboxIndicator rt-CheckboxIndicator"
      , HP.attr (HH.AttrName "data-state") "checked"
      , HP.attr (HH.AttrName "width") "9"
      , HP.attr (HH.AttrName "height") "9"
      , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
      , HP.attr (HH.AttrName "fill") "currentcolor"
      , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
      , HP.style "pointer-events: none;"
      ] <> (if isDisabled then [ HP.attr (HH.AttrName "data-disabled") "true" ] else []) )
      [ HH.elementNS svgNS (HH.ElemName "path")
          [ HP.attr (HH.AttrName "fill-rule") "evenodd"
          , HP.attr (HH.AttrName "clip-rule") "evenodd"
          , HP.attr (HH.AttrName "d")
              "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
          ]
          []
      ]
