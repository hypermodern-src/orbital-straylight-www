-- | Hydrogen.Themes.Switch — the styled Radix Themes Switch.
-- |
-- | Mirrors `switch.tsx`: the unstyled Switch primitive's Root carries
-- | `rt-reset rt-SwitchRoot` (size/variant defaults 2/surface from
-- | `switch.props.tsx`), and holds a single `rt-SwitchThumb` span (plus
-- | `rt-high-contrast` on the thumb when highContrast is set). `color`/`radius`
-- | render as `data-accent-color`/`data-radius`; absent, the switch inherits the
-- | enclosing `<Theme>`'s accent.
-- |
-- | This is the AT-REST render for the pixel goldens — a static
-- | `<button role=switch>` in the given checked state, with the matching
-- | `data-state` on both Root and Thumb (the hidden form bubble-input is omitted:
-- | it is visually hidden and contributes no pixels). The `disabled` helper adds
-- | the real `disabled` attribute plus `data-disabled`, which the
-- | `[data-disabled]` CSS rules key on.
module Hydrogen.Themes.Switch
  ( switch
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `switch checked props`. Caller props override the defaults (size 2 / variant
-- | surface) because the engine's single-value axes are last-wins.
switch :: forall w i. Boolean -> Boolean -> Array Prop -> HH.HTML w i
switch checked isDisabled props =
  el "button" [ "rt-reset", "rt-SwitchRoot" ]
    ( [ Size "2"
      , Variant "surface"
      , RawAttr "type" "button"
      , RawAttr "role" "switch"
      , RawAttr "aria-checked" (if checked then "true" else "false")
      , DataAttr "state" (state checked)
      , RawAttr "value" "on"
      ] <> disabledAttrs <> props
    )
    [ thumb ]
  where
  -- both Root and Thumb carry data-disabled when disabled (the [data-disabled]
  -- CSS rules style the thumb too).
  disabledAttrs = if isDisabled then [ RawAttr "disabled" "disabled", DataAttr "disabled" "true" ] else []

  thumb =
    el "span" [ "rt-SwitchThumb" ]
      ([ DataAttr "state" (state checked) ] <> (if isDisabled then [ DataAttr "disabled" "true" ] else []))
      []

  state c = if c then "checked" else "unchecked"
