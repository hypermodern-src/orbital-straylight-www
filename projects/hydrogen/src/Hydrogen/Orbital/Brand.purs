-- | Native Halogen renderers for ORBITAL's mark and product lockup.
-- |
-- | The aperiodic monotile path is the source artwork from the design bundle.
-- | It is rendered in the SVG namespace, stays `currentColor` by default, and
-- | is the only brand mark exposed by this module.
module Hydrogen.Orbital.Brand
  ( MarkSize(..)
  , MarkVariant(..)
  , MonotileInput
  , defaultMonotile
  , monotile
  , BrandSize(..)
  , BrandmarkInput
  , defaultBrandmark
  , brandmark
  , WatermarkInput
  , defaultWatermark
  , watermarkField
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

svgNamespace :: HH.Namespace
svgNamespace = HH.Namespace "http://www.w3.org/2000/svg"

markPath :: String
markPath = "m 18,18 v 20 l -17.32,10 10,17.32 h 40 l 10,-17.32 17.32,10 17.32,-10 -10,-17.32 h -20 v -20 L 48,.68 l -10,17.32 z"

data MarkSize = MicroMark | SmallMark | MediumMark | LargeMark | MarkPixels Int

derive instance eqMarkSize :: Eq MarkSize

markWidth :: MarkSize -> Int
markWidth MicroMark = 20
markWidth SmallMark = 28
markWidth MediumMark = 48
markWidth LargeMark = 96
markWidth (MarkPixels px) = max 1 px

data MarkVariant = SolidMark | StrokeMark | FilledMark

derive instance eqMarkVariant :: Eq MarkVariant

type MonotileInput r i =
  { size :: MarkSize
  , variant :: MarkVariant
  , color :: String
  , glow :: Boolean
  , class_ :: String
  , extraStyle :: String
  , attrs :: Array (HH.IProp r i)
  }

defaultMonotile :: forall r i. MonotileInput r i
defaultMonotile =
  { size: SmallMark
  , variant: SolidMark
  , color: "currentColor"
  , glow: false
  , class_: ""
  , extraStyle: ""
  , attrs: []
  }

monotile :: forall r w i. MonotileInput r i -> HH.HTML w i
monotile o =
  HH.elementNS svgNamespace (HH.ElemName "svg")
    ( [ HP.attr (HH.AttrName "viewBox") "0 0 96 66"
      , HP.attr (HH.AttrName "width") (show width)
      , HP.attr (HH.AttrName "height") (show height)
      , HP.attr (HH.AttrName "aria-hidden") "true"
      -- SVG exposes `className` as a read-only SVGAnimatedString. These must be
      -- attributes, not the HTML class/style properties Halogen normally uses.
      , HP.attr (HH.AttrName "class") (classNames [ "orbital-monotile", o.class_ ])
      , HP.attr (HH.AttrName "style") (markStyle o)
      ] <> o.attrs
    )
    [ HH.elementNS svgNamespace (HH.ElemName "path")
        [ HP.attr (HH.AttrName "d") markPath ]
        []
    ]
  where
  width = markWidth o.size
  height = toNumber width * 66.0 / 96.0

markStyle :: forall r i. MonotileInput r i -> String
markStyle o =
  "display: block; fill: " <> fill <> "; stroke: " <> stroke
    <> "; stroke-width: 4; filter: " <> glow <> "; " <> o.extraStyle
  where
  fill = case o.variant of
    SolidMark -> o.color
    StrokeMark -> "none"
    FilledMark -> "hsla(var(--hue),58%,38%,.12)"
  stroke = case o.variant of
    SolidMark -> "none"
    StrokeMark -> o.color
    FilledMark -> o.color
  glow = if o.glow then "drop-shadow(0 0 8px hsla(var(--hue),58%,52%,.55))" else "none"

data BrandSize = SmallBrand | MediumBrand | LargeBrand

derive instance eqBrandSize :: Eq BrandSize

type BrandmarkInput r i =
  { name :: String
  , product :: Maybe String
  , size :: BrandSize
  , href :: Maybe String
  , class_ :: String
  , attrs :: Array (HH.IProp (class :: String, style :: String | r) i)
  }

defaultBrandmark :: forall r i. BrandmarkInput r i
defaultBrandmark =
  { name: "Orbital"
  , product: Nothing
  , size: MediumBrand
  , href: Nothing
  , class_: ""
  , attrs: []
  }

brandmark :: forall r w i. BrandmarkInput r i -> HH.HTML w i
brandmark o =
  HH.element (HH.ElemName tag)
    ( [ HP.class_ (HH.ClassName (classNames [ "brand", o.class_ ]))
      , HP.style wrapperStyle
      ] <> hrefAttr <> o.attrs
    )
    [ monotile
        ( defaultMonotile
            { size = MarkPixels dimensions.mark
            , extraStyle = "opacity: .6;"
            }
        )
    , label
    ]
  where
  tag = case o.href of
    Just _ -> "a"
    Nothing -> "span"
  hrefAttr = case o.href of
    Just href -> [ HP.attr (HH.AttrName "href") href ]
    Nothing -> []
  dimensions = case o.size of
    SmallBrand -> { mark: 11, text: ".7rem" }
    MediumBrand -> { mark: 13, text: ".82rem" }
    LargeBrand -> { mark: 20, text: "1.15rem" }
  wrapperStyle =
    "display: inline-flex; align-items: center; gap: .7rem; font-weight: 600; font-size: "
      <> dimensions.text
      <> "; letter-spacing: .22em; text-transform: uppercase; color: var(--ink);"
  label = case o.product of
    Nothing -> HH.span_ [ HH.text o.name ]
    Just product ->
      HH.span_
        [ HH.span [ HP.style "color: var(--ink-m); font-weight: 500;" ] [ HH.text o.name ]
        , HH.span [ HP.style "color: var(--accent); margin: 0 .25rem;" ] [ HH.text "//" ]
        , HH.text product
        ]

type WatermarkInput i =
  { tile :: Int
  , opacity :: Number
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultWatermark :: forall i. WatermarkInput i
defaultWatermark = { tile: 52, opacity: 0.13, class_: "", attrs: [] }

watermarkField :: forall w i. WatermarkInput i -> Array (HH.HTML w i) -> HH.HTML w i
watermarkField o children =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "wm-field", o.class_ ])) ] <> o.attrs )
    [ HH.div
        [ HP.class_ (HH.ClassName "wm-tile")
        , HP.style ("background-size: " <> show (max 1 o.tile) <> "px; opacity: " <> show o.opacity <> ";")
        ]
        []
    , HH.div [ HP.class_ (HH.ClassName "wm-cap") ] children
    ]
