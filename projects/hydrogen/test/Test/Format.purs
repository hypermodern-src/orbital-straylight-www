-- | Coverage for Hydrogen.Data.Format — the pure display formatters. The expected
-- | outputs are exactly the module's own doc-comment examples, so this suite also
-- | guards those docs.
module Test.Format (suite) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Hydrogen.Data.Format (formatBytes, formatBytesCompact, formatCount, formatDuration, formatDurationCompact, formatDurationMs, formatNum, formatNumCompact, formatPercent, gb, mb, parseBytes, percentage, rate, ratio)
import Hydrogen.Test.Assert (assertEqual, section)

suite :: Effect Unit
suite = do
  section "Format — bytes" do
    assertEqual "1 KB" "1.0 KB" (formatBytes 1024.0)
    assertEqual "2.5 GB" "2.5 GB" (formatBytes (2.5 * gb))
    assertEqual "zero bytes" "0 B" (formatBytes 0.0)
    assertEqual "raw bytes floor" "512 B" (formatBytes 512.0)
    assertEqual "negative" "-1.0 KB" (formatBytes (-1024.0))
    assertEqual "MB boundary" "1.0 MB" (formatBytes mb)
    assertEqual "compact GB" "1.5GB" (formatBytesCompact (1.5 * gb))
    assertEqual "compact bytes" "0B" (formatBytesCompact 0.0)

  section "Format — numbers" do
    assertEqual "one decimal" "3.1" (formatNum 3.14159)
    assertEqual "whole keeps .0" "10.0" (formatNum 10.0)
    assertEqual "compact thousand" "1.5k" (formatNumCompact 1500.0)
    assertEqual "compact million" "2.5M" (formatNumCompact 2500000.0)
    assertEqual "compact small" "500" (formatNumCompact 500.0)
    assertEqual "percent" "87.4%" (formatPercent 0.874)
    assertEqual "percent full" "100.0%" (formatPercent 1.0)
    assertEqual "count compact" "45.2k" (formatCount 45230)
    assertEqual "count small" "500" (formatCount 500)

  section "Format — durations" do
    assertEqual "zero is dash" "-" (formatDuration 0)
    assertEqual "seconds" "45s" (formatDuration 45)
    assertEqual "minutes+seconds" "2m 5s" (formatDuration 125)
    assertEqual "hours+min+sec" "1h 1m 1s" (formatDuration 3661)
    assertEqual "compact minutes" "2m" (formatDurationCompact 125)
    assertEqual "compact hours" "1h" (formatDurationCompact 3661)
    assertEqual "ms to seconds" "45s" (formatDurationMs 45000)
    assertEqual "ms to m+s" "2m 5s" (formatDurationMs 125000)

  section "Format — calculations (division-by-zero safe)" do
    assertEqual "percentage" 75 (percentage 750.0 1000.0)
    assertEqual "percentage zero limit" 0 (percentage 5.0 0.0)
    assertEqual "rate half" 0.5 (rate 1 2)
    assertEqual "rate three-quarters" 0.75 (rate 3 4)
    assertEqual "rate zero total" 0.0 (rate 0 0)
    assertEqual "ratio" 0.75 (ratio 3.0 4.0)
    assertEqual "ratio quarter" 0.25 (ratio 1.0 4.0)
    assertEqual "ratio zero denom" 0.0 (ratio 1.0 0.0)

  section "Format — parseBytes (currently a stub: always Nothing)" do
    assertEqual "stub returns Nothing" (Nothing :: Maybe Number) (parseBytes "1.0 KB")
    assertEqual "invalid is Nothing" (Nothing :: Maybe Number) (parseBytes "nonsense")
