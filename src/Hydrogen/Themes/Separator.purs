-- | Hydrogen.Themes.Separator — the Radix Themes Separator.
-- |
-- | Mirrors `separator.tsx` + `separator.props.tsx`: a `<span>` carrying the
-- | base class `rt-Separator` plus the `rt-r-orientation-*` / `rt-r-size-*`
-- | tokens from its propDefs (defaults: orientation=horizontal, size=1,
-- | color=gray, decorative=true). `color` renders as `data-accent-color` (so the
-- | default emits `data-accent-color="gray"`); `decorative` defaults to true,
-- | which upstream maps to `role={undefined}` (no `role` attribute at all).
-- |
-- | The engine has no special case for the `orientation` axis, so its class
-- | token (`rt-r-orientation-<value>`) is emitted directly via `Class`.
module Hydrogen.Themes.Separator
  ( separator
  ) where

import Prelude

import Data.Array (any)
import Data.String (Pattern(..), stripPrefix) as Str
import Data.Maybe (isJust)
import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `separator [ Size "4" ] `. Caller props override the defaults: the engine's
-- | single-value styling axes (Size, Color) are last-wins, but `orientation` is a
-- | raw `Class` token (the engine has no orientation axis), so we mirror upstream's
-- | single `rt-r-orientation-*` class by OMITTING the horizontal default when the
-- | caller supplies their own `Class "rt-r-orientation-…"` (otherwise Halogen would
-- | emit BOTH classes, unlike React, which only ever renders the resolved one).
separator :: forall w i. Array Prop -> HH.HTML w i
separator props =
  el "span" [ "rt-Separator" ]
    (orientationDefault <> [ Size "1", Color "gray" ] <> props)
    []
  where
  orientationDefault =
    if any callerOrientation props then []
    else [ Class "rt-r-orientation-horizontal" ]
  callerOrientation = case _ of
    Class c -> isJust (Str.stripPrefix (Str.Pattern "rt-r-orientation-") c)
    _ -> false
