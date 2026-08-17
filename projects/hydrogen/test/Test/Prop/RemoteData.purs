-- | Property-based coverage for Hydrogen.Data.RemoteData — the instance laws over
-- | arbitrary states (the example suite pins specific cases; this quantifies).
-- |
-- | Idiom: a property over a custom generator is `gen <#> \x -> <Result>` (a
-- | `Gen Result`, which is Testable); a property over an Arbitrary type is just a
-- | function `\x -> <Result>`. `prop` runs it deterministically and tallies it.
module Test.Prop.RemoteData (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Data.RemoteData (RemoteData)
import Hydrogen.Test.Gen (genRemoteData)
import Hydrogen.Test.Prop (prop)
import Test.QuickCheck ((===))
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Gen (Gen)

genRD :: Gen (RemoteData String Int)
genRD = genRemoteData arbitrary arbitrary

suite :: Effect Unit
suite = do
  prop "functor identity: map id = id" $
    genRD <#> \rd -> map identity rd === rd
  prop "functor composition: map (f<<<g) = map f <<< map g" $
    genRD <#> \rd -> map ((_ + 1) <<< (_ * 2)) rd === map (_ + 1) (map (_ * 2) rd)
  prop "monad left identity: pure a >>= f = f a" $
    \(n :: Int) -> (pure n >>= k) === k n
  prop "monad right identity: m >>= pure = m" $
    genRD <#> \rd -> (rd >>= pure) === rd

k :: Int -> RemoteData String Int
k x = pure (x + 1)
