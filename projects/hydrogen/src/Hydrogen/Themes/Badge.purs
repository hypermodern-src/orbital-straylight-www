-- | Hydrogen.Themes.Badge — Badge.
-- |
-- | Upstream: radix-ui/themes src/components/badge.tsx (+ .props.tsx). A
-- | `<span class="rt-reset rt-Badge ...">`. Defaults: size `1` (className
-- | `rt-r-size` → `rt-r-size-1`) and variant `soft` (→ `rt-variant-soft`).
-- | `color` realizes to `data-accent-color`, `radius` to `data-radius`.
module Hydrogen.Themes.Badge
  ( badge
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

badge :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
badge props =
  el "span" [ "rt-reset", "rt-Badge" ]
    ([ Size "1", Variant "soft" ] <> props)
