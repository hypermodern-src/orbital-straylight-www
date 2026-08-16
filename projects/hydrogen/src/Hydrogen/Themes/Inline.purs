-- | Hydrogen.Themes.Inline — the Radix Themes Em and Strong inline elements.
-- |
-- | Mirrors `em.tsx` (`<em class="rt-Em">`) and `strong.tsx`
-- | (`<strong class="rt-Strong">`). Both wrap a `Slot.Root` that merges the
-- | single `rt-*` class onto the native tag, so the DOM is one element carrying
-- | that class — exactly what `el tag [ "rt-Em" | "rt-Strong" ]` emits. Their
-- | propDefs (asChild / truncate / textWrap) carry no defaults, so there are no
-- | default styling props to seed.
module Hydrogen.Themes.Inline
  ( em
  , strong
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

-- | `em [] [ HH.text "remarkably" ]` → `<em class="rt-Em">remarkably</em>`.
em :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
em = el "em" [ "rt-Em" ]

-- | `strong [] [ HH.text "quick" ]` → `<strong class="rt-Strong">quick</strong>`.
strong :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
strong = el "strong" [ "rt-Strong" ]
