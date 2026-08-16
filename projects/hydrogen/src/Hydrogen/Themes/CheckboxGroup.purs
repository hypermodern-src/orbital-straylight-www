-- | Hydrogen.Themes.CheckboxGroup — the styled Radix Themes CheckboxGroup.
-- |
-- | Mirrors `checkbox-group.tsx`:
-- |   * `CheckboxGroup.Root` → `<div role="group" class="rt-CheckboxGroupRoot
-- |     rt-r-size-2">`. The size default (2) comes from `_internal/base-checkbox.props.ts`
-- |     and is carried on the Root (the props are extracted with marginPropDefs and the
-- |     base checkbox propDefs; only size produces a token on the Root here).
-- |   * `CheckboxGroup.Item` → when given children, a `<Text as="label" size={size}>`
-- |     i.e. `<label class="rt-Text rt-r-size-2 rt-CheckboxGroupItem">` wrapping
-- |       - the checkbox button (the BaseCheckbox primitive: same `rt-reset
-- |         rt-BaseCheckboxRoot` button + `ThickCheckIcon` indicator SVG as Checkbox.purs,
-- |         but with `rt-CheckboxGroupItemCheckbox` instead of `rt-CheckboxRoot`), carrying
-- |         the size/variant defaults (2/surface) from context and the item's `value`.
-- |       - `<span class="rt-CheckboxGroupItemInner">{children}</span>`.
-- |
-- | With no `color` prop React emits `data-accent-color={undefined}` (no attribute) on
-- | the checkbox button, so we omit it too.
-- |
-- | This is the AT-REST render used for the pixel goldens: a static group of
-- | `<button role=checkbox>` items in the given checked state (the hidden form
-- | bubble-input is absolutely-positioned + visually hidden, contributing no pixels).
-- | Live toggling is a later layer over the ported primitive.
module Hydrogen.Themes.CheckboxGroup
  ( checkboxGroup
  , checkboxGroupItem
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Core (Namespace(..))
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `checkboxGroup [] [ checkboxGroupItem … ]` →
-- | `<div role="group" class="rt-CheckboxGroupRoot rt-r-size-2">`. Size default 2
-- | (last-wins over caller props).
checkboxGroup :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
checkboxGroup props =
  el "div" [ "rt-CheckboxGroupRoot" ]
    ( [ Size "2"
      , RawAttr "role" "group"
      ] <> props
    )

-- | `checkboxGroupItem checked value [] [ HH.text "One" ]`. `checked` selects the
-- | indicator + `data-state`/`aria-checked`; `value` is the item's form value (the
-- | required `value` prop on the underlying radio-group-style primitive).
checkboxGroupItem
  :: forall w i
   . Boolean
  -> String
  -> Array Prop
  -> Array (HH.HTML w i)
  -> HH.HTML w i
checkboxGroupItem checked value props children =
  -- <Text as="label" size={size} className="rt-CheckboxGroupItem">
  el "label" [ "rt-Text", "rt-CheckboxGroupItem" ]
    ( [ Size "2" ] <> props )
    [ itemCheckbox
    , HH.span
        [ HP.class_ (HH.ClassName "rt-CheckboxGroupItemInner") ]
        children
    ]
  where
  -- The BaseCheckbox primitive: same button/indicator as Checkbox.purs, but the
  -- group item class is `rt-CheckboxGroupItemCheckbox` (not `rt-CheckboxRoot`).
  itemCheckbox =
    el "button" [ "rt-reset", "rt-BaseCheckboxRoot", "rt-CheckboxGroupItemCheckbox" ]
      [ Size "2"
      , Variant "surface"
      , RawAttr "type" "button"
      , RawAttr "role" "checkbox"
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (if checked then "checked" else "unchecked")
      , RawAttr "value" value
      ]
      (if checked then [ indicator ] else [])

  svgNS = Namespace "http://www.w3.org/2000/svg"

  -- The Indicator renders the ThickCheckIcon via Slot, merging its classes onto the
  -- <svg> itself — the indicator IS the svg (no wrapper span).
  indicator =
    -- NB: SVGElement.className is a read-only SVGAnimatedString, so the class must
    -- be set via setAttribute (HP.attr "class"), not HP.class_.
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
