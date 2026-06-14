-- | Hydrogen.Radix.VisuallyHidden — content available to screen readers but
-- | visually hidden (radix `VisuallyHidden`). A stateless presentational
-- | primitive: a `<span>` carrying the canonical clip style.
-- |
-- | Idiom note: stateless primitives are plain render functions (no Halogen
-- | component / no Slot); they take their children as `Array HH.PlainHTML` and
-- | optional extra class names. Stateful primitives (see `Toggle`) are full
-- | components.
module Hydrogen.Radix.VisuallyHidden
  ( visuallyHidden
  , visuallyHidden_
  , inlineStyle
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

-- | The canonical visually-hidden inline style (matches radix exactly).
inlineStyle :: String
inlineStyle =
  "position:absolute;border:0;width:1px;height:1px;padding:0;margin:-1px;"
    <> "overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;word-wrap:normal;"

-- | A visually-hidden span with extra classes and static children.
visuallyHidden :: forall w i. ClassNames -> Array HH.PlainHTML -> HH.HTML w i
visuallyHidden extra children =
  HH.span
    [ HP.style inlineStyle, classes extra ]
    (map HH.fromPlainHTML children)

-- | A visually-hidden span with just children.
visuallyHidden_ :: forall w i. Array HH.PlainHTML -> HH.HTML w i
visuallyHidden_ = visuallyHidden mempty

