-- | Coverage for Hydrogen.Radix.Behavior.Typeahead — the pure type-to-focus matcher
-- | (radix `getNextMatch`). The DOM read / focus / idle clock live in the components and
-- | are covered by the APG gate; this pins the matching rule precisely.
module Test.Typeahead (suite) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Hydrogen.Radix.Behavior.Typeahead (isTypeaheadChar, nextMatch)
import Hydrogen.Test.Assert (assertEqual, section)

-- The dropdown demo's items (textContent incl. the shortcut suffix, as radix captures it).
items :: Array String
items = [ "Edit⌘ E", "Duplicate⌘ D", "Archive⌘ N", "Delete⌘ ⌫" ]

suite :: Effect Unit
suite = do
  section "Typeahead — single character (excludes the current match → advances)" do
    assertEqual "d from Edit → Duplicate" (Just 1) (nextMatch "d" items 0)
    assertEqual "a from Edit → Archive" (Just 2) (nextMatch "a" items 0)
    assertEqual "case-insensitive (D == d)" (Just 1) (nextMatch "D" items 0)
    assertEqual "no item starts with z → no move" Nothing (nextMatch "z" items 0)
    assertEqual "wraps past the end (e from Delete → Edit)" (Just 0) (nextMatch "e" items 3)

  section "Typeahead — repeated character cycles among matches" do
    -- "dd" normalizes to "d" and still excludes the current → walks to the NEXT d-item.
    assertEqual "dd from Duplicate → Delete" (Just 3) (nextMatch "dd" items 1)
    assertEqual "dd from Delete wraps → Duplicate" (Just 1) (nextMatch "dd" items 3)

  section "Typeahead — multi-character distinct buffer refines (keeps current in scope)" do
    -- building a word ("du") matches from the current index INCLUSIVE — you are refining,
    -- not advancing — so a current Duplicate stays Duplicate, never jumps to Delete.
    assertEqual "du from Duplicate stays (current still matches → no move)" Nothing (nextMatch "du" items 1)
    assertEqual "del from Edit → Delete" (Just 3) (nextMatch "del" items 0)
    assertEqual "dup from Delete → Duplicate" (Just 1) (nextMatch "dup" items 3)

  section "Typeahead — edge cases" do
    assertEqual "empty buffer → no move" Nothing (nextMatch "" items 0)
    assertEqual "empty item list → no move" Nothing (nextMatch "a" [] 0)
    assertEqual "current = -1 (nothing focused), d → Duplicate" (Just 1) (nextMatch "d" items (-1))

  section "Typeahead — isTypeaheadChar (printable gate, space-guard)" do
    assertEqual "letter is a typeahead char" true (isTypeaheadChar "a" false)
    assertEqual "digit is a typeahead char" true (isTypeaheadChar "7" false)
    assertEqual "Enter is not (multi-char key)" false (isTypeaheadChar "Enter" false)
    assertEqual "ArrowDown is not" false (isTypeaheadChar "ArrowDown" false)
    assertEqual "Space at rest is not (activation key)" false (isTypeaheadChar " " false)
    assertEqual "Space while searching IS (space-guard)" true (isTypeaheadChar " " true)
