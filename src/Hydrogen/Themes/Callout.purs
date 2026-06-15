-- | Hydrogen.Themes.Callout — the Radix Themes Callout.
-- |
-- | Mirrors `callout.tsx` + `callout.props.tsx`:
-- |   * Callout.Root → a `<div class="rt-CalloutRoot">` carrying its propDefs
-- |     (defaults: `variant=soft`, `size=2`); `color` realizes to `data-accent-color`
-- |     and `highContrast` to `rt-high-contrast` — neither used by the golden.
-- |   * Callout.Text → a `<Text as="p">` (so `rt-Text`) carrying `rt-CalloutText`.
-- |     Upstream sizes it via `mapCalloutSizeToTextSize(rootSize)` read from the
-- |     Callout context: rootSize `3` → text `3`, everything else → text `2`. With
-- |     the Root default size `2` that resolves to `rt-r-size-2`, which we apply
-- |     directly here (the golden uses only the default-size Root>Text).
module Hydrogen.Themes.Callout
  ( calloutRoot
  , calloutText
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `calloutRoot [ Variant "surface" ] [ … ]`. Caller props override the defaults
-- | because the engine's single-value axes are last-wins.
calloutRoot :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
calloutRoot props = el "div" [ "rt-CalloutRoot" ] ([ Variant "soft", Size "2" ] <> props)

-- | The callout body text — a `<p class="rt-Text rt-CalloutText rt-r-size-2">`,
-- | the `rt-r-size-2` coming from the Root's default size mapped to a text size.
calloutText :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
calloutText props = el "p" [ "rt-Text", "rt-CalloutText" ] ([ Size "2" ] <> props)
