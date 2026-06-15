-- | Hydrogen.Themes.Blockquote — Blockquote.
-- |
-- | Upstream (radix-ui/themes `components/blockquote.tsx`) renders a `<Text asChild>`
-- | whose single child is a `<blockquote>`; `Text`'s `Slot.Root` merges its `rt-Text`
-- | class onto that element and Blockquote appends `rt-Blockquote`. So the DOM is one
-- | `<blockquote class="rt-Text rt-Blockquote …">` — which is exactly what
-- | `el "blockquote" [ "rt-Text", "rt-Blockquote" ]` emits. No size default upstream
-- | (size is inherited from `--font-size` of the Text scale when unset).
module Hydrogen.Themes.Blockquote
  ( blockquote
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

blockquote :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
blockquote = el "blockquote" [ "rt-Text", "rt-Blockquote" ]
