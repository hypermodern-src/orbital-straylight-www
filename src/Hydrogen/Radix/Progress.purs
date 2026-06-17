-- | Hydrogen.Radix.Progress — a progress bar (radix `Progress`). Stateless.
-- | `value = Nothing` is indeterminate; otherwise `data-state` is "loading" until
-- | `value >= max`, then "complete". The root carries the progressbar ARIA; the
-- | indicator mirrors `data-state`/`data-value` for CSS to animate the fill.
module Hydrogen.Radix.Progress
  ( progress
  , progressState
  , fmtNum
  , valueLabel
  , validMax
  , validValue
  ) where

import Prelude

import Data.Int (round, toNumber) as Int
import Data.Maybe (Maybe(..), maybe)
import Data.Number.Format (toString) as Num
import DOM.HTML.Indexed (HTMLdiv)
import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (ClassNames, classes, dataState, dataAttr, role, aria)

-- | `isValidMaxNumber`: a valid max is a positive number (upstream rejects ≤0/NaN and
-- | falls back to DEFAULT_MAX=100, logging getInvalidMaxError). `validMax` resolves the
-- | effective max: the supplied value if positive, else 100.
validMax :: Number -> Number
validMax max = if max > 0.0 then max else 100.0

-- | `isValidValueNumber`: a valid value is a number with `0 <= value <= max`. An
-- | out-of-range value is coerced to indeterminate (Nothing) upstream (clamp-to-null +
-- | getInvalidValueError). `validValue` resolves the effective value against the
-- | (already-validated) max: it passes a Just through only when in range, else Nothing.
validValue :: Maybe Number -> Number -> Maybe Number
validValue mv mx = case mv of
  Nothing -> Nothing
  Just v -> if v >= 0.0 && v <= mx then Just v else Nothing

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
    -- upstream validates max (≤0/NaN → DEFAULT_MAX 100) and value (out of [0,max] →
    -- indeterminate) BEFORE deriving state/attrs, so an invalid value/max never reaches
    -- aria-valuenow/data-value/data-state. The valid inputs flow through unchanged.
    mx = validMax o.max
    val = validValue o.value mx
    st = progressState val mx
  in
    HH.div
      ( [ classes o.class_
        , role "progressbar"
        , aria "valuemin" "0"
        , aria "valuemax" (fmtNum mx)
        , dataState st
        , dataAttr "max" (fmtNum mx)
        ]
          <> o.rootAttrs
          <> maybe []
              ( \v ->
                  [ aria "valuenow" (fmtNum v)
                  , aria "valuetext" (valueLabel v mx)
                  , dataAttr "value" (fmtNum v)
                  ]
              )
              val
      )
      [ HH.div
          ( [ classes o.indicator, dataState st, dataAttr "max" (fmtNum mx) ]
              <> maybe [] (\v -> [ dataAttr "value" (fmtNum v) ]) val
          )
          []
      ]
