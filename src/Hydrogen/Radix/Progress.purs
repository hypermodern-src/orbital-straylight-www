-- | Hydrogen.Radix.Progress — a progress bar (radix `Progress`). Stateless.
-- | `value = Nothing` is indeterminate; otherwise `data-state` is "loading" until
-- | `value >= max`, then "complete". The root carries the progressbar ARIA; the
-- | indicator mirrors `data-state`/`data-value` for CSS to animate the fill.
module Hydrogen.Radix.Progress
  ( progress
  , progressState
  ) where

import Prelude

import Data.Maybe (Maybe(..), maybe)
import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (ClassNames, classes, dataState, dataAttr, role, aria)

progressState :: Maybe Number -> Number -> String
progressState mv max = case mv of
  Nothing -> "indeterminate"
  Just v -> if v >= max then "complete" else "loading"

progress
  :: forall w i
   . { value :: Maybe Number, max :: Number, class_ :: ClassNames, indicator :: ClassNames }
  -> HH.HTML w i
progress o =
  let
    st = progressState o.value o.max
  in
    HH.div
      ( [ classes o.class_
        , role "progressbar"
        , aria "valuemin" "0"
        , aria "valuemax" (show o.max)
        , dataState st
        , dataAttr "max" (show o.max)
        ]
          <> maybe [] (\v -> [ aria "valuenow" (show v), dataAttr "value" (show v) ]) o.value
      )
      [ HH.div [ classes o.indicator, dataState st ] [] ]
