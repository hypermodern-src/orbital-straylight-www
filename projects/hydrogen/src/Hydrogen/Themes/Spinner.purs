-- | Hydrogen.Themes.Spinner — the Radix Themes Spinner.
-- |
-- | Mirrors `spinner.tsx` + `spinner.props.tsx`: a `<span class="rt-Spinner">`
-- | carrying the `rt-r-size-*` token from its propDefs (default `size=2`), holding
-- | exactly EIGHT `<span class="rt-SpinnerLeaf" />` leaves (the rotating bars; see
-- | spinner.css `:nth-child(1..8)`). `loading` defaults to true and, with no
-- | children, upstream returns just this bare spinner — which is the only shape the
-- | golden exercises. `color`/`radius` would render as `data-*`; absent, inherited.
-- | NOTE: the Spinner animates (infinite CSS rotation); the golden harness
-- | screenshots with animations frozen (Playwright animations:"disabled" resets
-- | infinite animations to their initial frame), so it is sha-deterministic.
module Hydrogen.Themes.Spinner
  ( spinner
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `spinner [ Size "3" ] [ ]`. Caller props override the `size=2` default because
-- | the engine's single-value axes are last-wins. Renders the eight leaf bars.
spinner :: forall w i. Array Prop -> HH.HTML w i
spinner props =
  el "span" [ "rt-Spinner" ] ([ Size "2" ] <> props)
    (replicate8 (el "span" [ "rt-SpinnerLeaf" ] [] []))
  where
  replicate8 :: HH.HTML w i -> Array (HH.HTML w i)
  replicate8 leaf = [ leaf, leaf, leaf, leaf, leaf, leaf, leaf, leaf ]
