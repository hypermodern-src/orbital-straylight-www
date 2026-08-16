-- | Hydrogen.Themes.Kbd — the Radix Themes Kbd.
-- |
-- | Mirrors `kbd.tsx`: a `<kbd>` carrying `rt-reset rt-Kbd` plus the
-- | `rt-variant-*` / `rt-r-size-*` tokens from `kbd.props.tsx`. The only
-- | default is `variant=classic` (size is responsive with no default, so no
-- | size class is emitted unless the caller supplies one). Written defaults
-- | first so the caller's props win under the engine's last-wins axes.
module Hydrogen.Themes.Kbd
  ( kbd
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `kbd [] [ HH.text "Shift + Tab" ]` → `<kbd class="rt-reset rt-Kbd rt-variant-classic">…`.
kbd :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
kbd props = el "kbd" [ "rt-reset", "rt-Kbd" ] ([ Variant "classic" ] <> props)
