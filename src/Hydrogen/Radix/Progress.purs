-- | Hydrogen.Radix.Progress — a progress bar (radix `Progress`). Stateless.
-- | `value = Nothing` is indeterminate; otherwise `data-state` is "loading" until
-- | `value >= max`, then "complete". The root carries the progressbar ARIA; the
-- | indicator mirrors `data-state`/`data-value` for CSS to animate the fill.
module Hydrogen.Radix.Progress
  ( progress
  , progressState
  , fmtNum
  , valueLabel
  ) where

import Prelude

import Data.Int (round, toNumber) as Int
import Data.Maybe (Maybe(..), maybe)
import Data.Number.Format (toString) as Num
import DOM.HTML.Indexed (HTMLdiv)
import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (ClassNames, classes, dataState, dataAttr, role, aria)

-- | `getProgressState`: indeterminate when `value` is absent; `complete` when
-- | `value === max` (upstream uses STRICT equality, not `>=`); else `loading`.
progressState :: Maybe Number -> Number -> String
progressState mv max = case mv of
  Nothing -> "indeterminate"
  Just v -> if v == max then "complete" else "loading"

-- | Stringify a Number the way React's `${n}` does: a whole value (25.0) renders
-- | as the integer "25", a fractional value (25.5) keeps its decimals — so
-- | `aria-valuenow`/`data-value`/`data-max` never carry a PureScript-only ".0".
fmtNum :: Number -> String
fmtNum n =
  let r = Int.round n
  in if Int.toNumber r == n then show r else Num.toString n

-- | `defaultGetValueLabel`: `Math.round((value / max) * 100)%`.
valueLabel :: Number -> Number -> String
valueLabel v max = show (Int.round (v / max * 100.0)) <> "%"

-- | The root carries the progressbar ARIA; the indicator mirrors
-- | `data-state`/`data-value`/`data-max` for CSS to animate the fill. `rootAttrs`
-- | is an escape hatch for the preset-level extras a themed wrapper stamps onto the
-- | Root (the resolved `rt-ProgressRoot …` class, the inline `--progress-value`
-- | style, `data-accent-color`/`data-radius`).
progress
  :: forall w i
   . { value :: Maybe Number
     , max :: Number
     , class_ :: ClassNames
     , indicator :: ClassNames
     , rootAttrs :: Array (HH.IProp HTMLdiv i)
     }
  -> HH.HTML w i
progress o =
  let
    st = progressState o.value o.max
  in
    HH.div
      ( [ classes o.class_
        , role "progressbar"
        , aria "valuemin" "0"
        , aria "valuemax" (fmtNum o.max)
        , dataState st
        , dataAttr "max" (fmtNum o.max)
        ]
          <> o.rootAttrs
          <> maybe []
              ( \v ->
                  [ aria "valuenow" (fmtNum v)
                  , aria "valuetext" (valueLabel v o.max)
                  , dataAttr "value" (fmtNum v)
                  ]
              )
              o.value
      )
      [ HH.div
          ( [ classes o.indicator, dataState st, dataAttr "max" (fmtNum o.max) ]
              <> maybe [] (\v -> [ dataAttr "value" (fmtNum v) ]) o.value
          )
          []
      ]
