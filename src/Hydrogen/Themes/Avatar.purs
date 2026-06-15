-- | Hydrogen.Themes.Avatar — the Radix Themes Avatar.
-- |
-- | Mirrors `avatar.tsx` (+ `avatar.props.tsx`, `avatar.css`): the Root primitive
-- | renders `<span class="rt-reset rt-AvatarRoot …">` carrying the `rt-r-size-*`
-- | and `rt-variant-*` tokens from its propDefs (defaults: `size=3`, `variant=soft`),
-- | plus `data-accent-color` / `data-radius` for `color` / `radius`.
-- |
-- | With no image `src` the Radix `Avatar.Image` reports loading status `error`
-- | immediately, so the AT-REST DOM is the *error* branch: a single
-- | `<span class="rt-AvatarFallback rt-one-letter | rt-two-letters">` holding the
-- | fallback text. We reproduce that resting tree (length 1 → `rt-one-letter`,
-- | length 2 → `rt-two-letters`, matching the upstream classnames() conditions).
module Hydrogen.Themes.Avatar
  ( avatar
  ) where

import Prelude

import Data.String (length)
import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `avatar "A" [ Color "indigo" ]`. The first String is the fallback text; caller
-- | props override the `size=3` / `variant=soft` defaults (engine axes are last-wins).
avatar :: forall w i. String -> Array Prop -> HH.HTML w i
avatar fallback props =
  el "span" [ "rt-reset", "rt-AvatarRoot" ] ([ Size "3", Variant "soft" ] <> props)
    [ el "span" ([ "rt-AvatarFallback" ] <> letterClass) [] [ HH.text fallback ] ]
  where
  letterClass = case length fallback of
    1 -> [ "rt-one-letter" ]
    2 -> [ "rt-two-letters" ]
    _ -> []
