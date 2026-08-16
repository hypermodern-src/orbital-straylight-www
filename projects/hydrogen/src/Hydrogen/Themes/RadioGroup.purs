-- | Hydrogen.Themes.RadioGroup — the styled Radix Themes radio group.
-- |
-- | `radio-group.tsx` is two parts:
-- |
-- |   * `RadioGroup.Root` wraps the unstyled RadioGroupPrimitive.Root (a
-- |     `<div role="radiogroup">`) with the single base class `rt-RadioGroupRoot`.
-- |     size/variant/color/highContrast are NOT classes on the root — they flow
-- |     through context to each item — so the root carries only `rt-RadioGroupRoot`
-- |     (+ any margin props). The primitive div also emits `aria-required`, `dir`,
-- |     and — because RovingFocusGroup.Root is asChild-merged onto it — a roving
-- |     `tabindex="0"` (an item is focusable, not tabbing out) and
-- |     `style="outline: none;"`. The full-subtree DOM oracle captures these, so they
-- |     are load-bearing and emitted here.
-- |
-- |   * `RadioGroup.Item` (no children) renders the solo radio: the
-- |     RadioGroupPrimitive.Item `<button role="radio">` with
-- |     `rt-reset rt-BaseRadioRoot` + size/variant (defaults 2/surface, per
-- |     base-radio.props.ts). The selected dot is a CSS `::after` pseudo-element
-- |     (base-radio.css), NOT an indicator element — themes passes no children to
-- |     the primitive, so a checked item is simply `data-state="checked"` on an
-- |     empty button. RovingFocusGroup.Item + Collection.ItemSlot stamp each button
-- |     with `data-radix-collection-item=""` and a roving `tabindex` (0 for the
-- |     current tab stop / checked item, -1 otherwise). The hidden form bubble-input
-- |     is omitted (isFormControl is false without a `<form>` ancestor).
-- |
-- | These `radioGroup`/`radioItem` helpers render a single static (at-rest) snapshot —
-- | the themes-port / storybook at-rest galleries. The INTERACTIVE gallery now drives
-- | the radio group through the real `Hydrogen.Radix.RadioGroup` primitive (roving
-- | keyboard + selection-follows-focus), styled to the same chrome via its Style slots.
module Hydrogen.Themes.RadioGroup
  ( radioGroup
  , radioItem
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | RadioGroup.Root — `<div role="radiogroup">` holding the items. size/variant
-- | live on the items (via context upstream), so the root takes only layout props.
-- | Carries the RovingFocusGroup roving `tabindex="0"` + `style="outline: none;"`.
radioGroup :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
radioGroup props children =
  el "div" [ "rt-RadioGroupRoot" ]
    ( [ RawAttr "role" "radiogroup"
      , RawAttr "aria-required" "false"
      , RawAttr "dir" "ltr"
      , RawAttr "tabindex" "0"
      , RawAttr "style" "outline: none;"
      ] <> props
    )
    children

-- | RadioGroup.Item — the solo radio `<button role="radio">` in the given checked
-- | state. `value` is the radio's form value. Defaults size 2 / variant surface.
-- | Carries `data-radix-collection-item=""` and the roving `tabindex` (0 when
-- | checked / the current tab stop, -1 otherwise).
radioItem :: forall w i. Boolean -> String -> Array Prop -> HH.HTML w i
radioItem checked value props =
  el "button" [ "rt-reset", "rt-BaseRadioRoot" ] (radioItemProps checked value <> props) []

-- | The styling props common to every radio item button (everything except event
-- | handlers, which `Prop` cannot carry — the stateful `component` appends those).
radioItemProps :: Boolean -> String -> Array Prop
radioItemProps checked value =
  [ Size "2"
  , Variant "surface"
  , RawAttr "type" "button"
  , RawAttr "role" "radio"
  , RawAttr "aria-checked" (if checked then "true" else "false")
  , DataAttr "state" (if checked then "checked" else "unchecked")
  , DataAttr "radix-collection-item" ""
  , RawAttr "tabindex" (if checked then "0" else "-1")
  , RawAttr "value" value
  ]
