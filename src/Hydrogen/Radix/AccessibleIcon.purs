-- | Hydrogen.Radix.AccessibleIcon — give a decorative icon an accessible name
-- | (radix `AccessibleIcon`). The icon is hidden from the a11y tree; a
-- | visually-hidden label carries the name. Stateless.
module Hydrogen.Radix.AccessibleIcon
  ( accessibleIcon
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (aria)
import Hydrogen.Radix.VisuallyHidden (visuallyHidden_)

accessibleIcon :: forall w i. { label :: String } -> Array HH.PlainHTML -> HH.HTML w i
accessibleIcon o icon =
  HH.span_
    [ HH.span [ aria "hidden" "true" ] (map HH.fromPlainHTML icon)
    , visuallyHidden_ [ HH.text o.label ]
    ]
