-- | The inline SVGs: the Hypermodern monogram and the theme-toggle glyphs.
module Site.Svg
  ( monogram
  , sun
  , moon
  ) where

import Halogen.HTML as HH
import Halogen.HTML.Core (AttrName(..), Namespace(..))

svgNS :: Namespace
svgNS = Namespace "http://www.w3.org/2000/svg"

svg :: forall w i. Array (HH.IProp () i) -> Array (HH.HTML w i) -> HH.HTML w i
svg = HH.elementNS svgNS (HH.ElemName "svg")

path :: forall w i. Array (HH.IProp () i) -> HH.HTML w i
path attrs = HH.elementNS svgNS (HH.ElemName "path") attrs []

circle :: forall w i. Array (HH.IProp () i) -> HH.HTML w i
circle attrs = HH.elementNS svgNS (HH.ElemName "circle") attrs []

attr :: forall i. String -> String -> HH.IProp () i
attr n = HH.attr (AttrName n)

-- | The mark, parameterized by fill (currentColor / ink / accent).
monogram :: forall w i. String -> HH.HTML w i
monogram fill =
  svg [ attr "viewBox" "0 0 96 66", attr "fill" fill ]
    [ path [ attr "d" "m 18,18 v 20 l -17.32,10 10,17.32 h 40 l 10,-17.32 17.32,10 17.32,-10 -10,-17.32 h -20 v -20 L 48,.68 l -10,17.32 z" ] ]

sun :: forall w i. HH.HTML w i
sun =
  svg [ attr "viewBox" "0 0 16 16", attr "fill" "none", attr "stroke" "currentColor", attr "stroke-width" "1.3" ]
    [ circle [ attr "cx" "8", attr "cy" "8", attr "r" "3.4" ]
    , path [ attr "d" "M8 1v2M8 13v2M1 8h2M13 8h2M3.2 3.2l1.4 1.4M11.4 11.4l1.4 1.4M12.8 3.2l-1.4 1.4M4.6 11.4l-1.4 1.4" ]
    ]

moon :: forall w i. HH.HTML w i
moon =
  svg [ attr "viewBox" "0 0 16 16", attr "fill" "none", attr "stroke" "currentColor", attr "stroke-width" "1.3" ]
    [ path [ attr "d" "M13.5 9.2A5.3 5.3 0 1 1 6.8 2.5a4.2 4.2 0 0 0 6.7 6.7z" ] ]
