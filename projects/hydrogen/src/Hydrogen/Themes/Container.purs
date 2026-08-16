-- | Hydrogen.Themes.Container — Container.
-- |
-- | Upstream: radix-ui/themes src/components/container.tsx (+ .props.tsx,
-- | container.css). Renders two nested divs:
-- |
-- |   <div class="rt-Container rt-r-size-4">
-- |     <div class="rt-ContainerInner">{children}</div>
-- |   </div>
-- |
-- | The OUTER div is `rt-Container` and carries the size axis (className
-- | `rt-r-size`); size defaults to `4` (max-width 1136px). The size, display
-- | (`rt-r-display`) and align (`rt-r-ai`) axes — plus any margin props — apply
-- | to the outer div. The INNER div is always exactly `rt-ContainerInner`
-- | (it carries the width/min/max-width + height inline styles upstream; those
-- | are not modeled here, so it stays bare). Children go inside the inner div.
module Hydrogen.Themes.Container
  ( container
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), attrs)

container :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
container props children =
  HH.div
    (attrs [ "rt-Container" ] ([ Size "4" ] <> props))
    [ HH.div [ HH.attr (HH.AttrName "class") "rt-ContainerInner" ] children ]
