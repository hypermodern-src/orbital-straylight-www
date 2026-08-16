-- | Hydrogen.Themes.Section — Section.
-- |
-- | Upstream: radix-ui/themes src/components/section.tsx (+ .props.tsx). A
-- | `<section class="rt-Section ...">` driven by the shared prop engine plus the
-- | layout and margin props. Its one own styling axis is `size` (className
-- | `rt-r-size`, default `3` → `rt-r-size-3`), which controls vertical padding
-- | (size 1=24px, 2=40px, 3=64px, 4=80px). `display` (none/initial) is also a
-- | propDef but has no default. The `asChild`/Slot polymorphism is deferred.
module Hydrogen.Themes.Section
  ( section
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `section [ Size "4" ] [ … ]`. Caller props override the `Size "3"` default
-- | because the engine's single-value axes are last-wins.
section :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
section props = el "section" [ "rt-Section" ] ([ Size "3" ] <> props)
