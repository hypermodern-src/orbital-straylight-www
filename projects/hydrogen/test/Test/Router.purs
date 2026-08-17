-- | Coverage for the pure surface of Hydrogen.Runtime.Router. (The IsRoute/
-- | RouteMetadata classes and the history/DOM effects need a route type + a
-- | browser; `normalizeTrailingSlash` is the pure, total core.)
module Test.Router (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Runtime.Router (normalizeTrailingSlash)
import Hydrogen.Test.Assert (assertEqual, section)

suite :: Effect Unit
suite = do
  section "Router — normalizeTrailingSlash" do
    assertEqual "root stays root" "/" (normalizeTrailingSlash "/")
    assertEqual "strips a trailing slash" "/foo" (normalizeTrailingSlash "/foo/")
    assertEqual "leaves a clean path" "/foo" (normalizeTrailingSlash "/foo")
    assertEqual "nested trailing slash" "/foo/bar" (normalizeTrailingSlash "/foo/bar/")
    assertEqual "empty stays empty" "" (normalizeTrailingSlash "")
    assertEqual "idempotent" "/a/b" (normalizeTrailingSlash (normalizeTrailingSlash "/a/b/"))
