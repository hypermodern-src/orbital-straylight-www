-- | Hydrogen.Radix.Behavior.Typeahead — type-to-focus over a list of item labels
-- | (radix `useTypeahead` / menu.tsx `getNextMatch`).
-- |
-- | Like `RovingFocus`, the hard part is a **pure, closed-form function**: given the
-- | accumulated search buffer, the items' text values, and the current index, `nextMatch`
-- | returns the index to focus (or `Nothing`). The consuming component owns the buffer,
-- | the 1-second reset timer, the DOM text read, and the focus call — only those touch the
-- | world; the matching rule is total and testable.
-- |
-- | Faithful to radix `getNextMatch` (menu.tsx:411-434):
-- |   * a buffer of one repeated character ("aa", "aaa") normalizes to that single char and
-- |     CYCLES — it searches from after the current match, so repeats walk through the
-- |     items that share a first letter;
-- |   * a single character likewise excludes the current match (so the same key advances);
-- |   * a multi-character distinct buffer ("ad") keeps the current match in scope (you are
-- |     refining, not advancing), matching from the current index forward with wraparound;
-- |   * the search is case-insensitive prefix matching; a result equal to the current match
-- |     is treated as "no move" (`Nothing`).
module Hydrogen.Radix.Behavior.Typeahead
  ( nextMatch
  , isTypeaheadChar
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.CodeUnits as SCU

-- | Is `key` a character that should feed the typeahead buffer? A printable single
-- | character (length 1). Space only counts when a search is already in progress — at rest
-- | Space is an activation key (radix space-guard: menu.tsx onKeyDown). Modifier/navigation
-- | keys ("Shift", "ArrowDown", "Enter", …) are multi-character and excluded.
isTypeaheadChar :: String -> Boolean -> Boolean
isTypeaheadChar key searchActive =
  String.length key == 1 && (key /= " " || searchActive)

-- | All characters in the (non-empty) string are the same.
allSame :: String -> Boolean
allSame s = case SCU.uncons s of
  Nothing -> false
  Just { head } -> SCU.toCharArray s # Array.all (_ == head)

-- | The next index to focus given the search buffer, the item texts, and the current index
-- | (`-1` when nothing is focused). `Nothing` = no move.
nextMatch :: String -> Array String -> Int -> Maybe Int
nextMatch search texts current =
  let
    n = Array.length texts
  in
    if n == 0 || String.null search then Nothing
    else
      let
        repeated = String.length search > 1 && allSame search
        needle = String.toLower (if repeated then SCU.take 1 search else search)
        -- wrap the index space to start AT the current match (radix `wrapArray`).
        startIdx = max current 0
        wrapped = map (\i -> (startIdx + i) `mod` n) (Array.range 0 (n - 1))
        -- a single effective character excludes the current match, so the key advances.
        excludeCurrent = String.length needle == 1
        order = if excludeCurrent then Array.filter (_ /= current) wrapped else wrapped
        isMatch i = fromMaybe false do
          t <- Array.index texts i
          pure (isPrefix needle (String.toLower t))
      in
        case Array.find isMatch order of
          Just i | i /= current -> Just i
          _ -> Nothing

-- | Prefix test; both arguments already lowercased by the caller.
isPrefix :: String -> String -> Boolean
isPrefix needle hay = String.take (String.length needle) hay == needle
