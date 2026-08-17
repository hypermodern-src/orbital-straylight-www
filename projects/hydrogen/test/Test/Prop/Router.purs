-- | Property-based coverage for `Hydrogen.Runtime.Router.normalizeTrailingSlash`
-- | — the only pure, testable surface of the router (the rest is FFI / typeclass).
-- | All comparisons are String/Int/Boolean projections (Show + Eq), so `(===)` is
-- | well-typed; the trailing-character check uses the same `Data.String.CodeUnits`
-- | API the implementation does, so the tests track the real semantics.
module Test.Prop.Router (suite) where

import Prelude

import Data.String.CodeUnits as SCU
import Effect (Effect)
import Hydrogen.Runtime.Router (normalizeTrailingSlash)
import Hydrogen.Test.Prop (prop)
import Test.QuickCheck ((<?>), (===))

-- | Does this path end in a slash? (the predicate the implementation branches on)
endsInSlash :: String -> Boolean
endsInSlash s = SCU.takeRight 1 s == "/"

suite :: Effect Unit
suite = do
  -- The root path is a fixed point: it keeps its single slash, never stripped to "".
  prop "root '/' is a fixed point" $
    \(_ :: Int) -> normalizeTrailingSlash "/" === "/"

  -- Idempotence: normalizing an already-normalized path is a no-op.
  prop "idempotent: normalize (normalize s) = normalize s" $
    \(s :: String) ->
      normalizeTrailingSlash (normalizeTrailingSlash s) === normalizeTrailingSlash s

  -- Output shape: the result is either the root "/" or it does not end in a slash.
  prop "result is '/' or does not end in a slash" $
    \(s :: String) ->
      let r = normalizeTrailingSlash s
      in (r == "/" || not (endsInSlash r))
           <?> ("normalized to a non-root path ending in '/': " <> show r)

  -- A path that does not end in a slash is returned unchanged (forced by appending
  -- a non-slash char).
  prop "path without trailing slash maps to itself" $
    \(s :: String) ->
      let p = s <> "x"
      in normalizeTrailingSlash p === p

  -- A non-root path with exactly one trailing slash has precisely that slash
  -- removed (the "/" prefix + "x" guarantee a non-empty, non-root base).
  prop "single trailing slash on a non-root path is stripped" $
    \(s :: String) ->
      let base = "/" <> s <> "x"
      in normalizeTrailingSlash (base <> "/") === base

  -- normalize removes AT MOST one character: |out| is |in| or one less.
  prop "result length is input length or one less" $
    \(s :: String) ->
      let
        inLen = SCU.length s
        outLen = SCU.length (normalizeTrailingSlash s)
        delta = inLen - outLen
      in (delta == 0 || delta == 1)
           <?> ("length delta was " <> show delta <> " for input " <> show s)

  -- Only ONE trailing slash is removed, not a run: a non-root path ending in "//"
  -- still ends in "/" after normalization.
  prop "only one trailing slash is removed (double-slash still ends in '/')" $
    \(s :: String) ->
      let doubled = "/" <> s <> "x" <> "//"
      in endsInSlash (normalizeTrailingSlash doubled)
           <?> ("'//' was over-stripped for input " <> show doubled)
