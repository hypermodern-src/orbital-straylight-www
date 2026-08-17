-- | The QuickCheck bridge into the Hydrogen.Test.Assert tally. `prop` runs a
-- | property DETERMINISTICALLY (a fixed seed, 100 cases) so the suite is
-- | reproducible in CI, records ONE tally entry (pass iff every case passed), and
-- | on failure surfaces the first counterexample QuickCheck shrank to.
module Hydrogen.Test.Prop (prop) where

import Prelude

import Data.List as L
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Hydrogen.Test.Assert (assert)
import Random.LCG (mkSeed)
import Test.QuickCheck (class Testable, Result(..), quickCheckPure)

prop :: forall p. Testable p => String -> p -> Effect Unit
prop name p =
  case L.head (L.mapMaybe failMsg (quickCheckPure (mkSeed 271828) 100 p)) of
    Nothing -> assert (name <> " (100 cases)") true
    Just msg -> do
      assert name false
      log ("        ✗ counterexample: " <> msg)
  where
  failMsg = case _ of
    Success -> Nothing
    Failed m -> Just m
