-- | A minimal, dependency-free test harness — just `Effect` + a module-global
-- | tally. Assertions never throw mid-run (so one failure doesn't hide the rest);
-- | they record into a shared counter and `runSuite` reports the summary and exits
-- | non-zero if anything failed. That non-zero exit is exactly what `spago test`
-- | reads as a failing test. No spec/aff dependency: every import here is already
-- | in the registry closure, so the test graph needs no closure expansion.
module Hydrogen.Test.Assert
  ( assert
  , assertEqual
  , assertFalse
  , section
  , runSuite
  ) where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)

-- Module-global tallies (CAFs — evaluated once, shared across every assertion in
-- a run). The same `unsafePerformEffect (Ref.new …)` pattern the behavior layer
-- uses for its scroll-lock counter; safe here because a test binary is a single
-- linear run.
tally :: Ref.Ref { total :: Int, failed :: Int }
tally = unsafePerformEffect (Ref.new { total: 0, failed: 0 })

-- | Assert a boolean. Records pass/fail; prints a tick or a cross. Never throws.
assert :: String -> Boolean -> Effect Unit
assert msg cond = do
  _ <- Ref.modify (\t -> t { total = t.total + 1, failed = t.failed + if cond then 0 else 1 }) tally
  log (if cond then "    ✓ " <> msg else "    ✗ " <> msg)

-- | Assert two values equal, showing both on mismatch.
assertEqual :: forall a. Eq a => Show a => String -> a -> a -> Effect Unit
assertEqual msg expected actual =
  if expected == actual then assert msg true
  else do
    assert msg false
    log ("        expected: " <> show expected)
    log ("        actual:   " <> show actual)

-- | Assert a boolean is false.
assertFalse :: String -> Boolean -> Effect Unit
assertFalse msg cond = assert msg (not cond)

-- | A named group of assertions (purely for readable output).
section :: String -> Effect Unit -> Effect Unit
section name body = do
  log ("  • " <> name)
  body

-- | Run a suite, print the tally, and FAIL (non-zero exit) if any assertion did.
-- | This is the `main` a `purescript_test` target runs.
runSuite :: String -> Effect Unit -> Effect Unit
runSuite name body = do
  log ("◇ " <> name)
  body
  t <- Ref.read tally
  log ("\n" <> show (t.total - t.failed) <> "/" <> show t.total <> " assertions passed")
  when (t.failed > 0) (throw (show t.failed <> " assertion(s) failed in " <> name))
