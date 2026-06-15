-- | Hydrogen.Themes.VisuallyHidden — VisuallyHidden.
-- |
-- | Upstream: radix-ui/themes src/components/visually-hidden.tsx, which is a thin
-- | re-export of the radix primitive `VisuallyHidden.Root`
-- | (radix-ui/primitives packages/react/visually-hidden/src/visually-hidden.tsx).
-- |
-- | The primitive renders a bare `<span>` (NO `rt-*` class) whose entire effect is
-- | the frozen `VISUALLY_HIDDEN_STYLES` inline style — the Bootstrap sr-only recipe:
-- |
-- |   position: absolute; border: 0; width: 1px; height: 1px; padding: 0;
-- |   margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0);
-- |   white-space: nowrap; word-wrap: normal;
-- |
-- | (React renders the unitless numeric `width:1 / height:1 / margin:-1` as `1px /
-- | 1px / -1px`; `border:0 / padding:0` stay unitless.) We reproduce that style
-- | exactly via `StyleProp`. There are NO default styling props and no base class.
-- | The element renders nothing visible — it is screen-reader-only content.
module Hydrogen.Themes.VisuallyHidden
  ( visuallyHidden
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

visuallyHidden :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
visuallyHidden props =
  el "span" []
    ( [ StyleProp "position" "absolute"
      , StyleProp "border" "0"
      , StyleProp "width" "1px"
      , StyleProp "height" "1px"
      , StyleProp "padding" "0"
      , StyleProp "margin" "-1px"
      , StyleProp "overflow" "hidden"
      , StyleProp "clip" "rect(0, 0, 0, 0)"
      , StyleProp "white-space" "nowrap"
      , StyleProp "word-wrap" "normal"
      ] <> props
    )
