-- | QuickCheck generators for hydrogen's own types. Explicit `Gen`s (used with
-- | `forAll`) rather than `Arbitrary` instances — no orphans, and the generator is
-- | visible at each property's use site.
module Hydrogen.Test.Gen
  ( genSide
  , genAlign
  , genHue
  , genCoord
  , genDim
  , genSize
  , genRect
  , genRemoteData
  ) where

import Prelude

import Data.Array.NonEmpty (cons', fromArray) as NEA
import Data.Maybe (maybe)
import Hydrogen.Data.RemoteData (RemoteData(..))
import Hydrogen.Radix.Foundation.Color (Hue(..), allHues)
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..))
import Test.QuickCheck.Gen (Gen, choose, elements, oneOf)

genSide :: Gen Side
genSide = elements (NEA.cons' Top [ Right, Bottom, Left ])

genAlign :: Gen Align
genAlign = elements (NEA.cons' Start [ Center, End ])

genHue :: Gen Hue
genHue = maybe (pure Gray) elements (NEA.fromArray allHues)

-- A coordinate that can be negative (anchors live anywhere in the viewport).
genCoord :: Gen Number
genCoord = choose (-500.0) 500.0

-- A positive dimension (widths/heights are > 0).
genDim :: Gen Number
genDim = choose 1.0 300.0

genSize :: Gen { width :: Number, height :: Number }
genSize = { width: _, height: _ } <$> genDim <*> genDim

genRect :: Gen { x :: Number, y :: Number, width :: Number, height :: Number }
genRect = { x: _, y: _, width: _, height: _ } <$> genCoord <*> genCoord <*> genDim <*> genDim

-- Generate any RemoteData state from element generators for the error/value.
genRemoteData :: forall e a. Gen e -> Gen a -> Gen (RemoteData e a)
genRemoteData ge ga =
  oneOf (NEA.cons' (pure NotAsked) [ pure Loading, Failure <$> ge, Success <$> ga ])
