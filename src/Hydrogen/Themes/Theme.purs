-- | Hydrogen.Themes.Theme — the `<Theme>` root wrapper.
-- |
-- | Radix Themes resolves every design token (accent scale, gray scale, radius,
-- | scaling, panel background) from data-attributes on a single `.radix-themes`
-- | root; descendant `rt-*` components read those CSS variables. This reproduces
-- | that root with the same config our golden app mounts under — accent indigo,
-- | gray slate, radius medium, light appearance — plus the bundled Inter face via
-- | `--default-font-family` (headless Chromium has no system sans, so this keeps
-- | the render deterministic and matching the golden).
module Hydrogen.Themes.Theme
  ( theme
  ) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

theme :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
theme children =
  HH.element (HH.ElemName "div")
    [ HP.class_ (HH.ClassName "radix-themes light")
    , HP.attr (HH.AttrName "data-is-root-theme") "true"
    , HP.attr (HH.AttrName "data-accent-color") "indigo"
    , HP.attr (HH.AttrName "data-gray-color") "slate"
    , HP.attr (HH.AttrName "data-has-background") "true"
    , HP.attr (HH.AttrName "data-panel-background") "translucent"
    , HP.attr (HH.AttrName "data-radius") "medium"
    , HP.attr (HH.AttrName "data-scaling") "100%"
    , HP.style "--default-font-family: 'Inter Variable', sans-serif"
    ]
    children
