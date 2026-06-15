-- | Hydrogen.Themes.AspectRatio — AspectRatio.
-- |
-- | Upstream: radix-ui/themes src/components/aspect-ratio.tsx, which simply
-- | re-exports the Radix primitive `AspectRatio.Root`
-- | (radix-ui/primitives packages/react/aspect-ratio/src/aspect-ratio.tsx).
-- |
-- | The primitive renders NO `rt-*` classes — it is pure inline-style geometry:
-- |
-- |   <div                       -- wrapper, the padding-bottom ratio box
-- |     style="position: relative; width: 100%; padding-bottom: {100/ratio}%"
-- |     data-radix-aspect-ratio-wrapper="">
-- |     <div                     -- inner, absolutely filling the wrapper
-- |       {...props}
-- |       style="...callerStyle; position: absolute; top: 0; right: 0;
-- |              bottom: 0; left: 0">
-- |       {children}
-- |     </div>
-- |   </div>
-- |
-- | `ratio` defaults to `1 / 1` upstream; here it is a required leading argument.
-- | The wrapper's `padding-bottom` is `(100 / ratio)%`. The inner div receives the
-- | caller's `Prop`s (so `Box`-style classes / accent color compose) plus the fixed
-- | inset style; per the engine's last-wins fold, the inset entries override any
-- | caller-supplied position/top/right/bottom/left.
module Hydrogen.Themes.AspectRatio
  ( aspectRatio
  ) where

import Prelude

import Data.Number.Format (toString)
import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `aspectRatio ratio props children` — wrap `children` in a box that holds the
-- | given width:height `ratio`. e.g. `aspectRatio (16.0 / 9.0) [] [ … ]`.
aspectRatio :: forall w i. Number -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
aspectRatio ratio props children =
  el "div"
    []
    [ StyleProp "position" "relative"
    , StyleProp "width" "100%"
    , StyleProp "padding-bottom" (toString (100.0 / ratio) <> "%")
    , DataAttr "radix-aspect-ratio-wrapper" ""
    ]
    [ el "div"
        []
        ( props <>
            [ StyleProp "position" "absolute"
            , StyleProp "top" "0"
            , StyleProp "right" "0"
            , StyleProp "bottom" "0"
            , StyleProp "left" "0"
            ]
        )
        children
    ]
