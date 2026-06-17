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
import Data.Array (dropEnd, length, takeEnd)
import Data.Number.Format (precision, toStringWith)
import Data.String (Pattern(..), contains) as Str
import Data.String.CodeUnits (fromCharArray, toCharArray)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

-- | Serialize the padding-bottom percentage the way the BROWSER'S CSSOM does: a CSS
-- | `<percentage>` is rounded to at most 6 significant figures, with trailing zeros (and a
-- | bare trailing dot) dropped. React sets `paddingBottom` via the style PROPERTY, so the
-- | committed golden carries the browser-rounded form (e.g. 100/(21/9) → "42.8571", not the
-- | full-precision "42.857142857142854"). `precision 6` is JS `toPrecision(6)`; we then trim.
cssPercent :: Number -> String
cssPercent n =
  let s = toStringWith (precision 6) n
  in if Str.contains (Str.Pattern ".") s then fromCharArray (trimDot (dropZeros (toCharArray s))) else s
  where
  -- drop trailing '0's, then a single trailing '.' if it became bare (e.g. "200." → "200").
  dropZeros cs = if length cs > 0 && takeEnd 1 cs == [ '0' ] then dropZeros (dropEnd 1 cs) else cs
  trimDot cs = if takeEnd 1 cs == [ '.' ] then dropEnd 1 cs else cs

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
    , HP.style ("position: relative; width: 100%; padding-bottom: " <> cssPercent (100.0 / o.ratio) <> "%;")
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
