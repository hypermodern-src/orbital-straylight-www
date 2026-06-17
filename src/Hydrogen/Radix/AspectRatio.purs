-- | Hydrogen.Radix.AspectRatio — constrain content to a width/height ratio
-- | (radix `AspectRatio`). Stateless; uses the padding-bottom ratio technique.
-- | `ratio` is width÷height (e.g. 16/9 ≈ 1.78).
-- |
-- | Upstream (aspect-ratio.tsx) renders TWO divs:
-- |   * wrapper: `position:relative; width:100%; padding-bottom:{100/ratio}%`,
-- |     carrying the public marker attr `data-radix-aspect-ratio-wrapper=""`;
-- |   * inner: the caller's `style` FIRST, then `position:absolute; top/right/
-- |     bottom/left:0` (the browser's cssText collapses the four insets into the
-- |     `inset:0px` shorthand) — so the inset overrides any caller-supplied
-- |     position. The caller's class / id / data-* / aria-* land on the INNER div.
-- |
-- | `ratio` defaults to `1.0` (1/1) when omitted. The padding-bottom percentage is
-- | formatted with `Data.Number.Format.toString` so `100.0`→"100" (not "100.0"),
-- | matching React's number serialization node-for-node.
module Hydrogen.Radix.AspectRatio
  ( aspectRatio
  , aspectRatio_
  , Input
  , defaultInput
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv)
import Data.Number.Format (toString)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

-- | The inner-div prop surface. `ratio` is width÷height; `class_` / `style` / `attrs`
-- | all land on the INNER (absolutely-positioned) div, mirroring upstream's `{...props}`
-- | spread. `style` is the caller's inline style, merged BEFORE the inset overrides.
type Input i =
  { ratio :: Number
  , class_ :: ClassNames
  , style :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

-- | `defaultInput` — ratio 1/1, no class/style/extra attrs (matches upstream's `ratio = 1/1`).
defaultInput :: forall i. Input i
defaultInput = { ratio: 1.0, class_: mempty, style: "", attrs: [] }

aspectRatio
  :: forall w i
   . Input i
  -> Array HH.PlainHTML
  -> HH.HTML w i
aspectRatio o children =
  HH.div
    [ HP.attr (HH.AttrName "data-radix-aspect-ratio-wrapper") ""
    , HP.style ("position: relative; width: 100%; padding-bottom: " <> toString (100.0 / o.ratio) <> "%;")
    ]
    [ HH.div
        ( [ classes o.class_
          , HP.style (o.style <> "position: absolute; inset: 0px;")
          ] <> o.attrs
        )
        (map HH.fromPlainHTML children)
    ]

-- | `aspectRatio_ ratio children` — the common case: just a ratio, default class/style.
aspectRatio_ :: forall w i. Number -> Array HH.PlainHTML -> HH.HTML w i
aspectRatio_ ratio = aspectRatio (defaultInput { ratio = ratio })
