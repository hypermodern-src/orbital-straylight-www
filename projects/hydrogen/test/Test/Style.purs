-- | Coverage for Hydrogen.Radix.Foundation.Style — the class-list monoid (`cn`)
-- | and the style-axis name realizations (the radix-themes prop vocabulary).
module Test.Style (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Radix.Foundation.Style (Align(..), Orientation(..), Radius(..), Side(..), Size(..), Variant(..), alignName, cn, orientationName, radiusName, sideName, sizeName, unClassNames, variantName)
import Hydrogen.Test.Assert (assertEqual, section)

suite :: Effect Unit
suite = do
  section "Style — cn (class-list builder)" do
    assertEqual "splits on spaces" [ "a", "b", "c" ] (unClassNames (cn "a b c"))
    assertEqual "single token" [ "single" ] (unClassNames (cn "single"))
    assertEqual "drops empties + trims runs" [ "a", "b" ] (unClassNames (cn "  a   b  "))
    assertEqual "empty string -> no tokens" ([] :: Array String) (unClassNames (cn ""))
    assertEqual "normalizing makes them equal" (cn "a b") (cn "a   b")

  section "Style — ClassNames is a Monoid" do
    assertEqual "append concatenates" [ "a", "b" ] (unClassNames (cn "a" <> cn "b"))
    assertEqual "mempty is identity (left)" (cn "x") (mempty <> cn "x")
    assertEqual "mempty is identity (right)" (cn "x") (cn "x" <> mempty)

  section "Style — axis names (radix-themes vocabulary)" do
    assertEqual "variant solid" "solid" (variantName Solid)
    assertEqual "variant ghost" "ghost" (variantName Ghost)
    assertEqual "variant classic" "classic" (variantName Classic)
    assertEqual "size 1" "1" (sizeName Size1)
    assertEqual "size 4" "4" (sizeName Size4)
    assertEqual "radius none" "none" (radiusName RadiusNone)
    assertEqual "radius full" "full" (radiusName RadiusFull)
    assertEqual "side top" "top" (sideName Top)
    assertEqual "side left" "left" (sideName Left)
    assertEqual "align start" "start" (alignName Start)
    assertEqual "align center" "center" (alignName Center)
    assertEqual "align end" "end" (alignName End)
    assertEqual "orientation horizontal" "horizontal" (orientationName Horizontal)
    assertEqual "orientation vertical" "vertical" (orientationName Vertical)
