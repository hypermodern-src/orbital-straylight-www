-- | Hydrogen.Themes.Slider — the styled Radix Themes slider.
-- |
-- | `slider.tsx` wraps the unstyled `Slider` primitive (radix-ui) with
-- | `rt-SliderRoot` (size/variant defaults 2/surface), a `rt-SliderTrack`
-- | holding a `rt-SliderRange`, and one `rt-SliderThumb` per value. This is the
-- | AT-REST render used for the pixel goldens: a static horizontal slider at a
-- | fixed value, reproducing the inline geometry the primitive computes —
-- |
-- |   * Root   <span> — `dir="ltr"`, `data-orientation="horizontal"`, and the
-- |     `--radix-slider-thumb-transform: translateX(-50%)` custom property.
-- |   * Range  <span> — `left: 0%; right: {100 - percent}%`.
-- |   * Thumb wrapper <span> — `transform: var(--radix-slider-thumb-transform);
-- |     position: absolute; left: calc({percent}% + 0px)` (the in-bounds offset
-- |     is 0 until the thumb is measured, i.e. at first paint).
-- |   * Thumb  <span class="rt-SliderThumb"> — role/aria-value*/tabindex=0.
-- |
-- | Single-value form only (the golden renders `defaultValue={[40]}`): with one
-- | value the primitive emits no `aria-label`. min/max default to 0/100.
module Hydrogen.Themes.Slider
  ( slider
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | A horizontal slider rendered at rest at a single percentage `value`
-- | (0–100). `slider 40 []` reproduces `<Slider defaultValue={[40]} />`.
slider :: forall w i. Int -> Array Prop -> HH.HTML w i
slider value props =
  el "span" [ "rt-SliderRoot" ]
    ( [ Size "2"
      , Variant "surface"
      , RawAttr "dir" "ltr"
      , DataAttr "orientation" "horizontal"
      , StyleProp "--radix-slider-thumb-transform" "translateX(-50%)"
      ] <> props
    )
    [ el "span" [ "rt-SliderTrack" ]
        [ DataAttr "orientation" "horizontal" ]
        [ el "span" [ "rt-SliderRange" ]
            [ DataAttr "orientation" "horizontal"
            , StyleProp "left" "0%"
            , StyleProp "right" (show (100 - value) <> "%")
            ]
            []
        ]
    , el "span" []
        [ StyleProp "transform" "var(--radix-slider-thumb-transform)"
        , StyleProp "position" "absolute"
        , StyleProp "left" ("calc(" <> show value <> "% + 1.2px)")
        ]
        [ el "span" [ "rt-SliderThumb" ]
            [ RawAttr "role" "slider"
            , RawAttr "aria-valuemin" "0"
            , RawAttr "aria-valuenow" (show value)
            , RawAttr "aria-valuemax" "100"
            , RawAttr "aria-orientation" "horizontal"
            , DataAttr "orientation" "horizontal"
            , RawAttr "tabindex" "0"
            ]
            []
        ]
    ]
