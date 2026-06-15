-- | Hydrogen.Themes.DataList — DataList.Root / Item / Label / Value.
-- |
-- | Upstream: radix-ui/themes src/components/data-list.tsx (+ .props.tsx, .css).
-- | Root is a `<dl>` rendered through `<Text asChild>`, so the bare `rt-Text`
-- | class (Text carries no class-bearing defaults) merges onto the dl alongside
-- | `rt-DataListRoot`. Root defaults: size `2` (className `rt-r-size`) and
-- | orientation `horizontal` (className `rt-r-orientation`, not an engine axis,
-- | so emitted via `Class`). Item is a `<div class="rt-DataListItem">`, Label a
-- | `<dt class="rt-DataListLabel">` (color → data-accent-color), Value a
-- | `<dd class="rt-DataListValue">`.
module Hydrogen.Themes.DataList
  ( dataListRoot
  , dataListItem
  , dataListLabel
  , dataListValue
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

dataListRoot :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
dataListRoot props =
  el "dl" [ "rt-Text", "rt-DataListRoot" ]
    ([ Size "2", Class "rt-r-orientation-horizontal" ] <> props)

dataListItem :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
dataListItem = el "div" [ "rt-DataListItem" ]

dataListLabel :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
dataListLabel = el "dt" [ "rt-DataListLabel" ]

dataListValue :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
dataListValue = el "dd" [ "rt-DataListValue" ]
