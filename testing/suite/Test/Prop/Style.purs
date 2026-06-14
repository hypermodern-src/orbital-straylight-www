-- | Property-based coverage for Hydrogen.Radix.Foundation.Style — the `cn`
-- | normalizer and the `ClassNames` monoid (the example suite pins specific
-- | strings; this quantifies the invariants over arbitrary input). `ClassNames`
-- | has Eq and Show, so it may appear in `===`.
module Test.Prop.Style (suite) where

import Prelude

import Data.Array (all)
import Data.String (joinWith) as Str
import Effect (Effect)
import Hydrogen.Radix.Foundation.Style (cn, unClassNames)
import Hydrogen.Test.Prop (prop)
import Test.QuickCheck ((<?>), (===))

suite :: Effect Unit
suite = do
  -- cn drops every empty token: a normalized class list has no "" members.
  prop "cn yields no empty tokens" $
    \(s :: String) ->
      all (_ /= "") (unClassNames (cn s))
        <?> ("cn produced an empty token for input " <> show s)

  -- Re-joining the normalized tokens with a single space and re-normalizing is a
  -- fixpoint: cn has fully canonicalized the string in one pass.
  prop "cn is idempotent under space-rejoin" $
    \(s :: String) ->
      cn (Str.joinWith " " (unClassNames (cn s))) === cn s

  -- Monoid left identity over the ClassNames monoid.
  prop "ClassNames monoid: mempty <> x = x" $
    \(s :: String) ->
      let x = cn s in (mempty <> x) === x

  -- Monoid right identity.
  prop "ClassNames monoid: x <> mempty = x" $
    \(s :: String) ->
      let x = cn s in (x <> mempty) === x

  -- Monoid associativity over three normalized lists.
  prop "ClassNames monoid: associativity" $
    \(a :: String) (b :: String) (c :: String) ->
      let
        x = cn a
        y = cn b
        z = cn c
      in
        ((x <> y) <> z) === (x <> (y <> z))

  -- unClassNames is a monoid homomorphism into (Array String, <>): the structural
  -- concat of ClassNames projects to array concatenation.
  prop "unClassNames is a homomorphism: unClassNames (x <> y) = unClassNames x <> unClassNames y" $
    \(a :: String) (b :: String) ->
      unClassNames (cn a <> cn b) === (unClassNames (cn a) <> unClassNames (cn b))

  -- Normalizing the space-join of two token lists equals their structural concat:
  -- ties cn (the re-parse) back to <> (the structural concat).
  prop "cn (join (tokens a <> tokens b)) = cn a <> cn b" $
    \(a :: String) (b :: String) ->
      cn (Str.joinWith " " (unClassNames (cn a) <> unClassNames (cn b)))
        === (cn a <> cn b)
