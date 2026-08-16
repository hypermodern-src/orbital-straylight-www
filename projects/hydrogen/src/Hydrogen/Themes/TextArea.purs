-- | Hydrogen.Themes.TextArea — `text-area.tsx`: a `<div class="rt-TextAreaRoot">`
-- | (carrying the size/variant — defaults 2/surface) wrapping the actual
-- | `<textarea class="rt-reset rt-TextAreaInput">`. Mirrors TextField's
-- | wrapper-div + inner-element shape; this is the bare text area.
module Hydrogen.Themes.TextArea
  ( textArea
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), attrs)

-- | `textArea "Reply to comment…" [ Size "3" ]`.
textArea :: forall w i. String -> Array Prop -> HH.HTML w i
textArea placeholder props =
  HH.div
    (attrs [ "rt-TextAreaRoot" ] ([ Size "2", Variant "surface" ] <> props))
    [ HH.textarea
        [ HP.class_ (HH.ClassName "rt-reset rt-TextAreaInput")
        , HP.placeholder placeholder
        ]
    ]
