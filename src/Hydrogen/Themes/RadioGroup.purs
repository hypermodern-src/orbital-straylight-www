-- | Hydrogen.Themes.RadioGroup — the styled Radix Themes radio group.
-- |
-- | `radio-group.tsx` is two parts:
-- |
-- |   * `RadioGroup.Root` wraps the unstyled RadioGroupPrimitive.Root (a
-- |     `<div role="radiogroup">`) with the single base class `rt-RadioGroupRoot`.
-- |     size/variant/color/highContrast are NOT classes on the root — they flow
-- |     through context to each item — so the root carries only `rt-RadioGroupRoot`
-- |     (+ any margin props). At-rest the primitive div also emits `aria-required`
-- |     and `dir="ltr"` (RovingFocusGroup's tabIndex/outline are interactivity-only
-- |     and contribute no pixels, so omitted — same policy as Checkbox).
-- |
-- |   * `RadioGroup.Item` (no children) renders the solo radio: the
-- |     RadioGroupPrimitive.Item `<button role="radio">` with
-- |     `rt-reset rt-BaseRadioRoot` + size/variant (defaults 2/surface, per
-- |     base-radio.props.ts). The selected dot is a CSS `::after` pseudo-element
-- |     (base-radio.css), NOT an indicator element — themes passes no children to
-- |     the primitive, so a checked item is simply `data-state="checked"` on an
-- |     empty button. The hidden form bubble-input is absolutely-positioned +
-- |     opacity:0, so it is omitted (no pixels). This is the AT-REST render.
module Hydrogen.Themes.RadioGroup
  ( radioGroup
  , radioItem
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | RadioGroup.Root — `<div role="radiogroup">` holding the items. size/variant
-- | live on the items (via context upstream), so the root takes only layout props.
radioGroup :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
radioGroup props children =
  el "div" [ "rt-RadioGroupRoot" ]
    ( [ RawAttr "role" "radiogroup"
      , RawAttr "aria-required" "false"
      , RawAttr "dir" "ltr"
      ] <> props
    )
    children

-- | RadioGroup.Item — the solo radio `<button role="radio">` in the given checked
-- | state. `value` is the radio's form value. Defaults size 2 / variant surface.
radioItem :: forall w i. Boolean -> String -> Array Prop -> HH.HTML w i
radioItem checked value props =
  el "button" [ "rt-reset", "rt-BaseRadioRoot" ]
    ( [ Size "2"
      , Variant "surface"
      , RawAttr "type" "button"
      , RawAttr "role" "radio"
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (if checked then "checked" else "unchecked")
      , RawAttr "value" value
      ] <> props
    )
    []
