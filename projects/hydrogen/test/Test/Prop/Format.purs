-- | Property-based coverage for Hydrogen.Data.Format — the pure formatting and
-- | calculation functions, quantified over their arithmetic invariants (sign
-- | symmetry, space-stripping equivalence, division-by-zero safety, bounded
-- | rates, the duration sentinel, the ms/s relation, and the parseBytes stub).
module Test.Prop.Format (suite) where

import Prelude

import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), Replacement(..), replaceAll) as S
import Effect (Effect)
import Hydrogen.Data.Format (formatBytes, formatBytesCompact, formatDuration, formatDurationMs, parseBytes, percentage, rate, ratio)
import Hydrogen.Test.Prop (prop)
import Test.QuickCheck ((<?>), (===))
import Test.QuickCheck.Gen (Gen, choose, chooseInt)

-- A strictly-positive, finite byte count (no NaN/Infinity, no zero).
genPosBytes :: Gen Number
genPosBytes = choose 1.0 1.0e12

-- Any finite byte count (covers zero and the negative branch).
genAnyBytes :: Gen Number
genAnyBytes = choose (-1.0e12) 1.0e12

stripSpaces :: String -> String
stripSpaces = S.replaceAll (S.Pattern " ") (S.Replacement "")

suite :: Effect Unit
suite = do
  -- Sign symmetry: negating the input only prepends a minus sign.
  prop "formatBytes negation: formatBytes (-b) = \"-\" <> formatBytes b (b > 0)" $
    genPosBytes <#> \b -> formatBytes (-b) === "-" <> formatBytes b

  -- The compact form is exactly the spaced form with its separators removed
  -- (show of a Number never contains a space, so the only spaces are unit gaps).
  prop "formatBytesCompact mirrors formatBytes without spaces" $
    genAnyBytes <#> \b -> stripSpaces (formatBytes b) === formatBytesCompact b

  -- Division-by-zero safety: percentage against a zero limit is 0.
  prop "percentage _ 0.0 = 0 (division-by-zero safe)" $
    \(c :: Int) -> percentage (toNumber c) 0.0 === 0

  -- Division-by-zero safety: rate against a zero total is 0.0.
  prop "rate _ 0 = 0.0 (division-by-zero safe)" $
    \(s :: Int) -> rate s 0 === 0.0

  -- Division-by-zero safety: ratio against a zero denominator is 0.0.
  prop "ratio _ 0.0 = 0.0 (division-by-zero safe)" $
    \(n :: Int) -> ratio (toNumber n) 0.0 === 0.0

  -- A rate of success/total with 0 <= s <= t (t > 0) is a probability in [0,1].
  prop "rate s t in [0.0, 1.0] when 0 <= s <= t" $
    chooseInt 1 1000000 >>= \t ->
      chooseInt 0 t <#> \s ->
        let r = rate s t
        in (r >= 0.0 && r <= 1.0)
             <?> ("rate " <> show s <> " " <> show t <> " = " <> show r <> " out of [0,1]")

  -- The "-" sentinel is returned exactly for non-positive durations.
  prop "formatDuration n = \"-\" iff n <= 0" $
    \(n :: Int) -> (formatDuration n == "-") === (n <= 0)

  -- Milliseconds reduce to seconds: ms = n*1000 formats like n seconds.
  prop "formatDurationMs (n*1000) = formatDuration n" $
    chooseInt 0 1000000 <#> \n -> formatDurationMs (n * 1000) === formatDuration n

  -- parseBytes is a stub: it never parses anything (always Nothing).
  prop "parseBytes is a stub: always Nothing" $
    \(s :: String) -> parseBytes s === Nothing
