-- | Hydrogen.Radix.Label — a form label (radix `Label`). Stateless render fn.
-- | `for` associates it with a control by id.
module Hydrogen.Radix.Label
  ( label
  , label_
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

label :: forall w i. { for :: String, class_ :: ClassNames } -> Array HH.PlainHTML -> HH.HTML w i
label opts children =
  HH.label [ HP.for opts.for, classes opts.class_ ] (map HH.fromPlainHTML children)

label_ :: forall w i. Array HH.PlainHTML -> HH.HTML w i
label_ children = HH.label_ (map HH.fromPlainHTML children)
