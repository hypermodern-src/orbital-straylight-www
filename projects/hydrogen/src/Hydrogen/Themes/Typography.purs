-- | Hydrogen.Themes.Typography — Text / Heading.
-- |
-- | Upstream renders both through a `Slot.Root` that merges the `rt-Text` /
-- | `rt-Heading` class onto the chosen element (`as`), so the DOM is a single
-- | tag carrying the class — which is exactly what `el tag [ "rt-Text" ]` emits.
-- | `text`/`heading` use the upstream default element (`span`/`h1`); the `*As`
-- | variants pick another (`label`, `div`, `p`, `h3`, …).
module Hydrogen.Themes.Typography
  ( text
  , textAs
  , heading
  , headingAs
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

text :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
text = el "span" [ "rt-Text" ]

textAs :: forall w i. String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
textAs tag = el tag [ "rt-Text" ]

heading :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
heading = el "h1" [ "rt-Heading" ]

headingAs :: forall w i. String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
headingAs tag = el tag [ "rt-Heading" ]
