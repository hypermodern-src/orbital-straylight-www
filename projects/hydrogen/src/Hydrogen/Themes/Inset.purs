-- | Hydrogen.Themes.Inset — Inset.
-- |
-- | Upstream: radix-ui/themes src/components/inset.tsx (+ .props.tsx, .css). A
-- | `<div class="rt-Inset ...">` that bleeds its content to the edges of a
-- | padded parent (typically a Card) by cancelling the parent's padding via
-- | negative margins. Defaults: side `all` (className `rt-r-side` → `rt-r-side-all`)
-- | and clip `border-box` (className `rt-r-clip` → `rt-r-clip-border-box`).
-- | Both `side` and `clip` are engine axes; the leading last-wins entries
-- | reproduce upstream's `default:` fields. Side/clip/padding may be overridden
-- | by the caller (e.g. `Side "top"`, `Pb "current"` for the image-card look).
module Hydrogen.Themes.Inset
  ( inset
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

inset :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
inset props =
  el "div" [ "rt-Inset" ]
    ([ Side "all", Clip "border-box" ] <> props)
