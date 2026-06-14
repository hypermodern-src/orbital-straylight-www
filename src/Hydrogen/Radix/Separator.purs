-- | Hydrogen.Radix.Separator — a visual/semantic divider (radix `Separator`).
-- | Stateless. Decorative separators are hidden from the a11y tree (`role=none`);
-- | semantic ones get `role=separator` and `aria-orientation` (only when vertical,
-- | matching radix — horizontal is the separator default).
module Hydrogen.Radix.Separator
  ( separator
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), classes, dataOrientation, orientationName, role, aria)

separator
  :: forall w i
   . { orientation :: Orientation, decorative :: Boolean, class_ :: ClassNames }
  -> HH.HTML w i
separator o =
  HH.div
    ( [ classes o.class_, dataOrientation o.orientation ]
        <> semantics
    )
    []
  where
  semantics =
    if o.decorative then [ role "none" ]
    else case o.orientation of
      Vertical -> [ role "separator", aria "orientation" (orientationName Vertical) ]
      Horizontal -> [ role "separator" ]
