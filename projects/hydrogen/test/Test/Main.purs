-- | The hydrogen test entrypoint — runs every suite under one tally. `spago test`
-- | compiles this with the library and locked dependency closure, then runs it
-- | under Node; a non-zero exit (any failed assertion) fails the test.
-- |
-- | Coverage is the PURE logic of the framework — the parts unit tests can pin
-- | precisely. The Halogen *components* (the 23 Radix primitives) are covered by
-- | the pixel-perfect Playwright gallery, not here.
module Test.Main where

import Prelude

import Effect (Effect)
import Hydrogen.Test.Assert (runSuite)
import Test.Color as Color
import Test.Compute as Compute
import Test.Format as Format
import Test.RemoteData as RemoteData
import Test.Prop.Compute as PropCompute
import Test.Prop.Format as PropFormat
import Test.Prop.RemoteData as PropRemoteData
import Test.Prop.Router as PropRouter
import Test.Prop.Style as PropStyle
import Test.Router as Router
import Test.Style as Style
import Test.Typeahead as Typeahead

main :: Effect Unit
main = runSuite "hydrogen" do
  RemoteData.suite
  Format.suite
  Compute.suite
  Style.suite
  Router.suite
  Color.suite
  Typeahead.suite
  PropRemoteData.suite
  PropFormat.suite
  PropCompute.suite
  PropStyle.suite
  PropRouter.suite
