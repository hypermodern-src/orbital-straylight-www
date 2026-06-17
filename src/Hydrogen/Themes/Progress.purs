-- | Hydrogen.Themes.Progress — `progress.tsx` over the radix `Progress` primitive.
-- |
-- | A `<div class="rt-ProgressRoot">` (defaults `size=2`, `variant=surface` from
-- | `progress.props.tsx`) wrapping a single `<div class="rt-ProgressIndicator">`.
-- | The Themes wrapper sets the inline custom property `--progress-value` on the
-- | root (only `--progress-value`, since the golden passes `value` but no `max`,
-- | so `--progress-max`/`--progress-duration` are omitted and fall back to the CSS
-- | defaults), and the indicator's `transform: scaleX(value/max)` is driven by it.
-- |
-- | The role/aria + data-state/data-value/data-max anatomy is supplied by
-- | `Hydrogen.Radix.Progress.progress` — Themes is a STYLED WRAPPER over the
-- | primitive (mirroring upstream `Progress` → `ProgressPrimitive.Root/Indicator`),
-- | NOT a parallel re-implementation, so the two can never drift.
module Hydrogen.Themes.Progress
  ( progress
  ) where

import Prelude

import Data.Int (toNumber)
import Data.Tuple (Tuple(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Progress as Progress
import Hydrogen.Themes.Prop (Prop(..), resolve)

-- | `progress 25 []` → a surface/size-2 progress bar at 25% (value < max ⇒
-- | `data-state="loading"`). Caller props (e.g. `Variant "soft"`, `Color "cyan"`)
-- | override the defaults — last wins. The role/aria/data anatomy (the
-- | integer-formatted `aria-valuenow="25"` + `aria-valuetext="25%"`, data-state/
-- | value/max) is the `Hydrogen.Radix.Progress` primitive's. Default max of 100.
progress :: forall w i. Int -> Array Prop -> HH.HTML w i
progress value props =
  let
    -- the themed class/style/data the wrapper stamps on the Root: rt-ProgressRoot +
    -- the size/variant axes + caller overrides + the --progress-value custom prop.
    r = resolve [ "rt-ProgressRoot" ]
      ( [ Size "2", Variant "surface", StyleProp "--progress-value" (show value) ] <> props )
  in
    Progress.progress
      { value: pure (toNumber value)
      , max: 100.0
      , class_: cn r.class_
      , indicator: cn "rt-ProgressIndicator"
      , rootAttrs:
          (if r.style == "" then [] else [ HP.style r.style ])
            <> map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v) r.dataAttrs
            <> map (\(Tuple k v) -> HP.attr (HH.AttrName k) v) r.rawAttrs
      }
