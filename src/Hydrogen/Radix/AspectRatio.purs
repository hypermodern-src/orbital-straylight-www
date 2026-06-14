-- | Hydrogen.Radix.AspectRatio — constrain content to a width/height ratio
-- | (radix `AspectRatio`). Stateless; uses the padding-bottom ratio technique.
-- | `ratio` is width÷height (e.g. 16/9 ≈ 1.78).
module Hydrogen.Radix.AspectRatio
  ( aspectRatio
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

aspectRatio
  :: forall w i
   . { ratio :: Number, class_ :: ClassNames }
  -> Array HH.PlainHTML
  -> HH.HTML w i
aspectRatio o children =
  HH.div
    [ HP.style ("position:relative;width:100%;padding-bottom:" <> show (100.0 / o.ratio) <> "%;") ]
    [ HH.div
        [ classes o.class_
        , HP.style "position:absolute;top:0;right:0;bottom:0;left:0;"
        ]
        (map HH.fromPlainHTML children)
    ]
