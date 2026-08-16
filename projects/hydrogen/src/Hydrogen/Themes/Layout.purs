-- | Hydrogen.Themes.Layout — Box / Flex, the composition substrate.
-- |
-- | These are the Radix Themes layout primitives: thin elements driven entirely by
-- | the shared prop engine (margin/padding, gap, direction, align, justify, …).
-- | `rt-Box` / `rt-Flex` carry the base layout CSS (`.rt-Flex { display: flex }`);
-- | every other token comes from the caller's props.
module Hydrogen.Themes.Layout
  ( box
  , flex
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

-- | A block container. `box [ P "6" ] [ … ]`.
box :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
box = el "div" [ "rt-Box" ]

-- | A flex container. Pass `Direction`, `Gap`, `Align`, `Justify`, `Wrap` as props;
-- | `rt-Flex` provides `display: flex` and the row default.
flex :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
flex = el "div" [ "rt-Flex" ]
