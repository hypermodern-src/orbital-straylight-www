-- | Hydrogen.Themes.Card — `rt-reset rt-BaseCard rt-Card` (size default 1,
-- | variant default surface). Mirrors card.tsx.
module Hydrogen.Themes.Card
  ( card
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

card :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
card props = el "div" [ "rt-reset", "rt-BaseCard", "rt-Card" ] ([ Size "1", Variant "surface" ] <> props)
