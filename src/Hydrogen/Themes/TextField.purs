-- | Hydrogen.Themes.TextField — `text-field.tsx`: a `<div class="rt-TextFieldRoot">`
-- | (carrying the size/variant — defaults 2/surface) wrapping the actual
-- | `<input class="rt-reset rt-TextFieldInput">`. The click-to-focus handler and
-- | the left/right slots are deferred; this is the bare text input.
module Hydrogen.Themes.TextField
  ( textField
  , textFieldValue
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), attrs)

-- | `textField "you@example.com" [ Size "3" ]`.
textField :: forall w i. String -> Array Prop -> HH.HTML w i
textField placeholder props =
  HH.div
    (attrs [ "rt-TextFieldRoot" ] ([ Size "2", Variant "surface" ] <> props))
    [ HH.input
        [ HP.class_ (HH.ClassName "rt-reset rt-TextFieldInput")
        , HP.spellcheck false
        , HP.placeholder placeholder
        ]
    ]

-- | As `textField`, but with an initial `value` (renders the input's value).
textFieldValue :: forall w i. String -> String -> Array Prop -> HH.HTML w i
textFieldValue placeholder value props =
  HH.div
    (attrs [ "rt-TextFieldRoot" ] ([ Size "2", Variant "surface" ] <> props))
    [ HH.input
        [ HP.class_ (HH.ClassName "rt-reset rt-TextFieldInput")
        , HP.spellcheck false
        , HP.placeholder placeholder
        -- the `value` ATTRIBUTE (radix's defaultValue), not HP.value (which sets the DOM
        -- property — invisible to an attribute snapshot).
        , HP.attr (HH.AttrName "value") value
        ]
    ]
