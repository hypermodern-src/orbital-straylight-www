-- | Hydrogen.Themes.Progress — `progress.tsx` over the radix `Progress` primitive.
-- |
-- | A `<div class="rt-ProgressRoot">` (defaults `size=2`, `variant=surface` from
-- | `progress.props.tsx`) wrapping a single `<div class="rt-ProgressIndicator">`.
-- | The Themes wrapper sets the inline custom property `--progress-value` on the
-- | root (only `--progress-value`, since the golden passes `value` but no `max`,
-- | so `--progress-max`/`--progress-duration` are omitted and fall back to the CSS
-- | defaults), and the indicator's `transform: scaleX(value/max)` is driven by it.
-- |
-- | The radix primitive (react-progress) decorates BOTH the root and the indicator
-- | with `data-state` / `data-value` / `data-max`, and the root additionally with
-- | `role="progressbar"` + `aria-valuemin/max/now/text` (valuetext = round(value/max
-- | * 100)%). With a concrete `value` < `max`, the state is "loading". We reproduce
-- | that exact at-rest DOM.
module Hydrogen.Themes.Progress
  ( progress
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), attrs)

-- | `progress 25 []` → a surface/size-2 progress bar at 25% (value < max ⇒
-- | `data-state="loading"`). Caller props (e.g. `Variant "soft"`, `Color "cyan"`)
-- | override the defaults — last wins. Reproduces the at-rest DOM with the default
-- | max of 100.
progress :: forall w i. Int -> Array Prop -> HH.HTML w i
progress value props =
  HH.div
    ( attrs [ "rt-ProgressRoot" ]
        ( [ Size "2"
          , Variant "surface"
          , StyleProp "--progress-value" (show value)
          , RawAttr "role" "progressbar"
          , RawAttr "aria-valuemin" "0"
          , RawAttr "aria-valuemax" "100"
          , RawAttr "aria-valuenow" (show value)
          , RawAttr "aria-valuetext" (show valueLabel <> "%")
          , DataAttr "state" "loading"
          , DataAttr "value" (show value)
          , DataAttr "max" "100"
          ]
            <> props
        )
    )
    [ HH.div
        [ HP.class_ (HH.ClassName "rt-ProgressIndicator")
        , HP.attr (HH.AttrName "data-state") "loading"
        , HP.attr (HH.AttrName "data-value") (show value)
        , HP.attr (HH.AttrName "data-max") "100"
        ]
        []
    ]
  where
  -- defaultGetValueLabel: Math.round(value / max * 100)
  valueLabel :: Int
  valueLabel = (value * 100 + 50) `div` 100
