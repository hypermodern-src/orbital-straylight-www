module Ponce.Track (trackMap) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldMap)
import Data.Int (floor, toNumber)
import Data.Maybe (fromMaybe)
import Data.Number (sqrt)
import Data.Number.Format (fixed, toStringWith)
import Data.String (joinWith)
import Data.Tuple (Tuple(..), uncurry)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

type Point =
  { x :: Number
  , y :: Number
  }

rawPoints :: Array (Tuple Number Number)
rawPoints =
  [ Tuple 1030.0 905.0, Tuple 1300.0 905.0, Tuple 1560.0 905.0
  , Tuple 1820.0 900.0, Tuple 1885.0 893.0, Tuple 1908.0 860.0
  , Tuple 1885.0 828.0, Tuple 1820.0 822.0, Tuple 1500.0 800.0
  , Tuple 1150.0 763.0, Tuple 1010.0 690.0, Tuple 962.0 580.0
  , Tuple 985.0 480.0, Tuple 940.0 465.0, Tuple 885.0 430.0
  , Tuple 830.0 485.0, Tuple 760.0 565.0, Tuple 700.0 650.0
  , Tuple 672.0 700.0, Tuple 618.0 745.0, Tuple 645.0 668.0
  , Tuple 720.0 530.0, Tuple 800.0 380.0, Tuple 848.0 285.0
  , Tuple 845.0 225.0, Tuple 700.0 190.0, Tuple 450.0 132.0
  , Tuple 270.0 90.0, Tuple 235.0 130.0, Tuple 235.0 320.0
  , Tuple 222.0 520.0, Tuple 200.0 700.0, Tuple 150.0 880.0
  , Tuple 110.0 955.0, Tuple 70.0 995.0, Tuple 88.0 1022.0
  , Tuple 160.0 1010.0, Tuple 300.0 970.0, Tuple 480.0 938.0
  , Tuple 595.0 930.0, Tuple 645.0 952.0, Tuple 700.0 985.0
  , Tuple 758.0 933.0
  ]

mapScale :: Number
mapScale = 2.9 / 1939.0

controlPoints :: Array Point
controlPoints = map scale rawPoints
  where
  scale (Tuple x y) =
    { x: x * mapScale - 1.45
    , y: y * mapScale - (1080.0 * mapScale) / 2.0
    }

origin :: Point
origin = { x: 0.0, y: 0.0 }

pointAt :: Int -> Point
pointAt index =
  let
    count = Array.length controlPoints
    wrapped = mod (index + count) count
  in
    fromMaybe origin (Array.index controlPoints wrapped)

catmull :: Point -> Point -> Point -> Point -> Number -> Point
catmull p0 p1 p2 p3 t =
  let
    t2 = t * t
    t3 = t2 * t
    coordinate a0 a1 a2 a3 =
      0.5 *
        ( 2.0 * a1
            + (a2 - a0) * t
            + (2.0 * a0 - 5.0 * a1 + 4.0 * a2 - a3) * t2
            + (3.0 * a1 - a0 - 3.0 * a2 + a3) * t3
        )
  in
    { x: coordinate p0.x p1.x p2.x p3.x
    , y: coordinate p0.y p1.y p2.y p3.y
    }

samplePath :: Number -> Point
samplePath t =
  let
    count = Array.length controlPoints
    normalized = if t >= 1.0 then 0.0 else if t < 0.0 then t + 1.0 else t
    position = normalized * toNumber count
    index = floor position
    offset = position - toNumber index
  in
    catmull
      (pointAt (index - 1))
      (pointAt index)
      (pointAt (index + 1))
      (pointAt (index + 2))
      offset

pixel :: Point -> Point
pixel point =
  { x: ((point.x + 1.45) / 2.9) * (640.0 - 92.0) + 46.0
  , y: ((point.y + 0.81) / 1.62) * (420.0 - 92.0) + 46.0
  }

decimal :: Number -> String
decimal = toStringWith (fixed 1)

trackPath :: String
trackPath =
  joinWith "" (map command (Array.range 0 192)) <> "Z"
  where
  command index =
    let
      point = pixel (samplePath (toNumber index / 192.0))
      prefix = if index == 0 then "M" else "L"
    in
      prefix <> decimal point.x <> " " <> decimal point.y

turnControlIndices :: Array Int
turnControlIndices = [ 5, 10, 12, 14, 19, 24, 27, 31, 34, 39, 41 ]

svgElement :: forall r w i. String -> Array (HH.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
svgElement name = HH.element (HH.ElemName name)

attribute :: forall r i. String -> String -> HH.IProp r i
attribute name = HP.attr (HH.AttrName name)

turnMarker :: forall w i. Int -> Int -> Array (HH.HTML w i)
turnMarker number controlIndex =
  let
    point = pixel (pointAt controlIndex)
    center = pixel origin
    dx = point.x - center.x
    dy = point.y - center.y
    distance = sqrt (dx * dx + dy * dy)
    safeDistance = if distance == 0.0 then 1.0 else distance
    labelX = point.x + (dx / safeDistance) * 20.0
    labelY = point.y + (dy / safeDistance) * 20.0 + 4.0
  in
    [ svgElement "circle"
        [ attribute "cx" (decimal point.x)
        , attribute "cy" (decimal point.y)
        , attribute "r" "4"
        , attribute "class" "turn-dot"
        ]
        []
    , svgElement "text"
        [ attribute "x" (decimal labelX)
        , attribute "y" (decimal labelY)
        , attribute "class" "turn-label"
        ]
        [ HH.text (show (number + 1)) ]
    ]

trackMap :: forall w i. String -> HH.HTML w i
trackMap language =
  let
    start = pixel (samplePath 0.0)
    startFinish = if language == "en" then "START / FINISH" else "META"
    label = if language == "en" then "Circuit map" else "Mapa del circuito"
    caption =
      if language == "en" then
        "1.54 mi (2.47 km) · 11 turns · run clockwise along the southern coast"
      else
        "1.54 mi (2.47 km) · 11 curvas · en sentido horario por la costa sur"
    markers = foldMap (uncurry turnMarker) (Array.mapWithIndex Tuple turnControlIndices)
  in
    svgElement "figure" [ attribute "class" "trackmap" ]
      [ svgElement "svg"
          [ attribute "viewBox" "0 0 640 420"
          , attribute "role" "img"
          , attribute "aria-label" label
          ]
          ( [ svgElement "path"
                [ attribute "d" trackPath
                , attribute "class" "track-outline"
                ]
                []
            , svgElement "path"
                [ attribute "d" trackPath
                , attribute "class" "track-line"
                ]
                []
            ]
              <> markers
              <> [ svgElement "rect"
                    [ attribute "x" (decimal (start.x - 5.0))
                    , attribute "y" (decimal (start.y - 10.0))
                    , attribute "width" "10"
                    , attribute "height" "20"
                    , attribute "class" "startfinish"
                    ]
                    []
                , svgElement "text"
                    [ attribute "x" (decimal (start.x + 14.0))
                    , attribute "y" (decimal (start.y + 4.0))
                    , attribute "class" "sf-label"
                    ]
                    [ HH.text startFinish ]
                ]
          )
      , svgElement "figcaption" [] [ HH.text caption ]
      ]
