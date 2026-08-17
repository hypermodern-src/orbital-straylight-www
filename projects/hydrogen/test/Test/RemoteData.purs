-- | Coverage for Hydrogen.Data.RemoteData — the async-lifecycle ADT and its
-- | (documented) instance semantics: first-failure Apply, short-circuit Bind,
-- | NotAsked-identity Alt, most-progressed Semigroup, plus every combinator.
module Test.RemoteData (suite) where

import Prelude

import Control.Alt ((<|>))
import Data.Either (Either(..))
import Data.Foldable (foldr, foldMap)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Hydrogen.Data.RemoteData (RemoteData(..), fold, fromEither, fromMaybe, isFailure, isLoading, isNotAsked, isSuccess, map2, map3, mapError, sequence, toEither, toMaybe, withDefault)
import Hydrogen.Test.Assert (assert, assertEqual, section)

-- Concrete instantiations keep the assertions annotation-free.
na :: RemoteData String Int
na = NotAsked

ld :: RemoteData String Int
ld = Loading

fl :: RemoteData String Int
fl = Failure "boom"

su :: RemoteData String Int
su = Success 7

suite :: Effect Unit
suite = do
  section "RemoteData — Functor" do
    assertEqual "map over Success" (Success 8) (map (_ + 1) su)
    assertEqual "map preserves NotAsked" na (map (_ + 1) na)
    assertEqual "map preserves Loading" ld (map (_ + 1) ld)
    assertEqual "map preserves Failure" fl (map (_ + 1) fl)
    assertEqual "functor identity" su (map identity su)

  section "RemoteData — Apply (first-failure: Failure > Loading > NotAsked > Success)" do
    assertEqual "Success <*> Success" (Success 8) (map2 (+) su (Success 1))
    assertEqual "Failure short-circuits left" fl (map2 (+) fl su)
    assertEqual "Failure short-circuits right" fl (map2 (+) su fl)
    assertEqual "Loading beats Success" ld (map2 (+) ld su)
    assertEqual "Failure beats Loading" fl (map2 (+) fl ld)
    assertEqual "NotAsked beats Success" na (map2 (+) na su)
    assertEqual "Loading beats NotAsked" ld (map2 (+) ld na)
    assertEqual "map3 all Success" (Success 12) (map3 (\a b c -> a + b + c) su (Success 2) (Success 3))
    assertEqual "map3 one Failure" fl (map3 (\a b c -> a + b + c) su fl (Success 3))

  section "RemoteData — Bind (short-circuits on non-Success)" do
    assertEqual "Success >>= f" (Success 14) (su >>= \x -> Success (x * 2))
    assertEqual "NotAsked >>= f" na (na >>= \x -> Success (x * 2))
    assertEqual "Loading >>= f" ld (ld >>= \x -> Success (x * 2))
    assertEqual "Failure >>= f" fl (fl >>= \x -> Success (x * 2))
    assertEqual "monad left identity" (Success 8 :: RemoteData String Int) (pure 7 >>= \x -> Success (x + 1))
    assertEqual "monad right identity" su (su >>= pure)

  section "RemoteData — Semigroup (most-progressed; Success appends payloads)" do
    let
      sa = Success [ 1 ] :: RemoteData String (Array Int)
      sb = Success [ 2 ] :: RemoteData String (Array Int)
      la = Loading :: RemoteData String (Array Int)
      fa = Failure "boom" :: RemoteData String (Array Int)
      nb = NotAsked :: RemoteData String (Array Int)
    assertEqual "Success <> Success appends" (Success [ 1, 2 ]) (sa <> sb)
    assertEqual "Success beats Loading" sa (sa <> la)
    assertEqual "Success beats Failure" sa (fa <> sa)
    assertEqual "Failure beats Loading" fa (la <> fa)
    assertEqual "Loading beats NotAsked" la (nb <> la)
    assertEqual "NotAsked is identity (left)" sa (nb <> sa)
    assertEqual "NotAsked <> NotAsked" nb (nb <> nb)

  section "RemoteData — Alt (NotAsked identity, Success wins)" do
    assertEqual "NotAsked <|> x = x" su (na <|> su)
    assertEqual "x <|> NotAsked = x" fl (fl <|> na)
    assertEqual "Success absorbs on left" su (su <|> fl)
    assertEqual "Success wins on right" su (fl <|> su)
    assertEqual "Failure > Loading" fl (fl <|> ld)

  section "RemoteData — Foldable" do
    assertEqual "foldr only Success" 8 (foldr (+) 1 su)
    assertEqual "foldr ignores Failure" 1 (foldr (+) 1 fl)
    assertEqual "foldMap Success" [ 7 ] (foldMap (\x -> [ x ]) su)
    assertEqual "foldMap NotAsked is mempty" ([] :: Array Int) (foldMap (\x -> [ x ]) na)

  section "RemoteData — construction / elimination" do
    assertEqual "fromEither Right" su (fromEither (Right 7))
    assertEqual "fromEither Left" fl (fromEither (Left "boom"))
    assertEqual "fromMaybe Just" su (fromMaybe "boom" (Just 7))
    assertEqual "fromMaybe Nothing" fl (fromMaybe "boom" Nothing)
    assertEqual "toEither Success" (Right 7) (toEither "pending" su)
    assertEqual "toEither Failure" (Left "boom") (toEither "pending" fl)
    assertEqual "toEither NotAsked uses pending" (Left "pending") (toEither "pending" na)
    assertEqual "toEither Loading uses pending" (Left "pending") (toEither "pending" ld)
    assertEqual "toMaybe Success" (Just 7) (toMaybe su)
    assertEqual "toMaybe Failure" (Nothing :: Maybe Int) (toMaybe fl)
    assertEqual "withDefault Success" 7 (withDefault 0 su)
    assertEqual "withDefault non-Success" 0 (withDefault 0 fl)
    let h = { notAsked: "na", loading: "ld", failure: \e -> "fail:" <> e, success: \a -> "ok:" <> show a }
    assertEqual "fold success" "ok:7" (fold h su)
    assertEqual "fold failure" "fail:boom" (fold h fl)
    assertEqual "fold notAsked" "na" (fold h na)

  section "RemoteData — predicates / mapError / sequence" do
    assert "isNotAsked" (isNotAsked na)
    assert "isLoading" (isLoading ld)
    assert "isFailure" (isFailure fl)
    assert "isSuccess" (isSuccess su)
    assert "isSuccess false on Failure" (not (isSuccess fl))
    assertEqual "mapError transforms Failure" (Failure 4 :: RemoteData Int Int) (mapError (\_ -> 4) fl)
    assertEqual "mapError preserves Success" (Success 7 :: RemoteData Int Int) (mapError (\_ -> 4) su)
    assertEqual "sequence all Success" (Success [ 1, 2, 3 ] :: RemoteData String (Array Int)) (sequence [ Success 1, Success 2, Success 3 ])
    assertEqual "sequence with a Failure" (Failure "boom") (sequence [ Success 1, fl, Success 3 ])
