-- | Hydrogen.Themes.Code — the Radix Themes Code.
-- |
-- | Mirrors `code.tsx`: a `<code>` carrying `rt-reset rt-Code` plus the
-- | `rt-variant-*` / `rt-r-size-*` tokens from `code.props.tsx` (default:
-- | `variant=soft`; `size` is responsive with no default, so it is omitted
-- | unless the caller sets it). `color` renders as the `data-accent-color`
-- | attribute; the `asChild`/Slot polymorphism and the ghost-color resolution
-- | are deferred (not needed by the demo). Inline element.
module Hydrogen.Themes.Code
  ( code
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `code [ Variant "solid" ] [ HH.text "npm start" ]`. Caller props override
-- | the `variant=soft` default because the engine's single-value axes are
-- | last-wins.
code :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
code props = el "code" [ "rt-reset", "rt-Code" ] ([ Variant "soft" ] <> props)
