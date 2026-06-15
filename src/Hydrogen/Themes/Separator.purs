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

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `separator [ Size "4" ] `. Caller props override the defaults because the
-- | engine's single-value axes are last-wins; the leading `Class` orientation
-- | token is the horizontal default and is replaced when the caller passes their
-- | own `Class "rt-r-orientation-vertical"`.
separator :: forall w i. Array Prop -> HH.HTML w i
separator props =
  el "span" [ "rt-Separator" ]
    ([ Class "rt-r-orientation-horizontal", Size "1", Color "gray" ] <> props)
    []
