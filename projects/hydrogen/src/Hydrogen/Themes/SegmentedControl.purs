-- | Hydrogen.Themes.SegmentedControl — the styled Radix Themes SegmentedControl.
-- |
-- | Mirrors `segmented-control.tsx` (+ `.props.tsx`, `.css`). It is built on the
-- | unstyled `ToggleGroup` primitive (`type="single"`), so the at-rest DOM is:
-- |
-- |   * Root → `<div class="rt-SegmentedControlRoot" role="group" dir="ltr"
-- |     data-radius?>`. Defaults: variant `surface` (→ `rt-variant-surface`) and
-- |     size `2` (className `rt-r-size` → `rt-r-size-2`). `radius` realizes to
-- |     `data-radius`; `data-disabled` is only present when disabled (omitted here).
-- |     After its item children the root carries a trailing
-- |     `<div class="rt-SegmentedControlIndicator" />` — that empty div is the
-- |     sliding selection background and is pixel-load-bearing (the CSS shows it via
-- |     `[data-state='on'] ~ .rt-SegmentedControlIndicator`), so we emit it inside
-- |     `segmentedControl` itself, after the caller's children.
-- |   * Item → `<button class="rt-reset rt-SegmentedControlItem" type="button"
-- |     role="radio" aria-checked data-state="on|off" value tabindex>`. The
-- |     `data-state` (`on` for the selected item, `off` otherwise) drives the active
-- |     label fade and the indicator position, so it is load-bearing. Each item holds
-- |     a leading `<span class="rt-SegmentedControlItemSeparator" />` then a
-- |     `<span class="rt-SegmentedControlItemLabel">` wrapping the active label span
-- |     (`rt-SegmentedControlItemLabelActive`) and the `aria-hidden` inactive label
-- |     span (`rt-SegmentedControlItemLabelInactive`), each holding the same children.
-- |
-- | This is the AT-REST render used for the pixel goldens: roving focus, controlled
-- | value state, and live toggling are a later layer over the ported primitive; only
-- | the rendered DOM + classes are reproduced here.
module Hydrogen.Themes.SegmentedControl
  ( segmentedControl
  , segmentedItem
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), attrs)

-- | `segmentedControl [] [ segmentedItem true … , … ]` →
-- | `<div class="rt-SegmentedControlRoot rt-variant-surface rt-r-size-2" …>`.
-- | Variant default `surface`, size default `2` (both last-wins over caller props).
-- | The trailing indicator div is appended after the caller's item children.
segmentedControl :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
segmentedControl props children =
  HH.div
    ( attrs [ "rt-SegmentedControlRoot" ]
        ( [ Variant "surface"
          , Size "2"
          , RawAttr "role" "group"
          , RawAttr "dir" "ltr"
          ] <> props
        )
    )
    (children <> [ HH.div [ HP.class_ (HH.ClassName "rt-SegmentedControlIndicator") ] [] ])

-- | `segmentedItem active [] [ HH.text "Inbox" ]`. `active` selects
-- | `data-state=on|off` (and the matching `aria-checked` / `tabindex`), which drives
-- | the active label crossfade and the indicator slide.
segmentedItem :: forall w i. Boolean -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
segmentedItem active props children =
  HH.button
    ( attrs [ "rt-reset", "rt-SegmentedControlItem" ]
        ( [ RawAttr "type" "button"
          , RawAttr "role" "radio"
          , RawAttr "aria-checked" (if active then "true" else "false")
          , DataAttr "state" (if active then "on" else "off")
          , RawAttr "tabindex" (if active then "0" else "-1")
          ] <> props
        )
    )
    [ HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemSeparator") ] []
    , HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabel") ]
        [ HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabelActive") ] children
        , HH.span
            [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabelInactive")
            , HP.attr (HH.AttrName "aria-hidden") "true"
            ]
            children
        ]
    ]
