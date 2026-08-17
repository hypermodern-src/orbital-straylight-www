-- | Coverage for Hydrogen.Radix.Foundation.Color — the hue vocabulary. (The full
-- | scales are large data tables; here we pin the hue set + its name mapping.)
module Test.Color (suite) where

import Prelude

import Data.Array (length, nub)
import Effect (Effect)
import Hydrogen.Radix.Foundation.Color (Hue(..), allHues, hueName)
import Hydrogen.Test.Assert (assertEqual, section)

suite :: Effect Unit
suite = do
  section "Color — hueName" do
    assertEqual "gray" "gray" (hueName Gray)
    assertEqual "red" "red" (hueName Red)
    assertEqual "blue" "blue" (hueName Blue)
    assertEqual "green" "green" (hueName Green)
    assertEqual "iris" "iris" (hueName Iris)
    assertEqual "orange" "orange" (hueName Orange)

  section "Color — allHues" do
    assertEqual "the radix palette has 31 hues" 31 (length allHues)
    assertEqual "every hue name is distinct" 31 (length (nub (map hueName allHues)))
