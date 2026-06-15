-- | Hydrogen.Themes.IconButton — the Radix Themes IconButton.
-- |
-- | Mirrors `icon-button.tsx` → `_internal/base-button.tsx`: a `<button>` carrying
-- | `rt-reset rt-BaseButton rt-IconButton` plus the `rt-variant-*` / `rt-r-size-*`
-- | tokens from its propDefs (shared with Button via `baseButtonPropDefs`; defaults
-- | `variant=solid`, `size=2`). Like Button, `color`/`radius` render as `data-*`
-- | attributes and, absent, the button inherits the enclosing `<Theme>`'s accent.
-- | The single child is an icon (typically an SVG). The `asChild`/Slot polymorphism
-- | and loading spinner are deferred (not needed by the variant/size matrix).
module Hydrogen.Themes.IconButton
  ( iconButton
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `iconButton [ Variant "soft" ] [ icon ]`. Caller props override the defaults
-- | because the engine's single-value axes are last-wins.
iconButton :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
iconButton props = el "button" [ "rt-reset", "rt-BaseButton", "rt-IconButton" ] ([ Variant "solid", Size "2" ] <> props)
