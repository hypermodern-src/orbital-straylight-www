-- | Hydrogen.Themes.Button — the Radix Themes Button.
-- |
-- | Mirrors `button.tsx` → `base-button.tsx`: a `<button>` carrying
-- | `rt-reset rt-BaseButton rt-Button` plus the `rt-variant-*` / `rt-r-size-*`
-- | tokens from its propDefs (defaults: `variant=solid`, `size=2`). `color` and
-- | `radius` render as `data-*` attributes; absent, the button inherits the
-- | enclosing `<Theme>`'s accent. The `asChild`/Slot polymorphism and the loading
-- | spinner are deferred (not needed by the variant/size matrix).
module Hydrogen.Themes.Button
  ( button
  , disabled
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `button [ Variant "soft", Size "3" ] [ HH.text "Save" ]`. Caller props override
-- | the defaults because the engine's single-value axes are last-wins.
button :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
button props = el "button" [ "rt-reset", "rt-BaseButton", "rt-Button" ] ([ Variant "solid", Size "2" ] <> props)

-- | The disabled-button props (the real `disabled` attribute plus radix's
-- | `data-disabled`, which its `[data-disabled]` rules also key on). Spread into a
-- | button's prop list: `button (disabled <> [ … ]) [ … ]`.
disabled :: Array Prop
disabled = [ RawAttr "disabled" "disabled", DataAttr "disabled" "true" ]
