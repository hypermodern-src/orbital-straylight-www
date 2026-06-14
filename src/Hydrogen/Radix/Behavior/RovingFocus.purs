-- | Hydrogen.Radix.Behavior.RovingFocus — arrow-key navigation across a group of
-- | items with a single tab stop (radix `RovingFocusGroup`).
-- |
-- | The navigation is a **pure, closed-form function** over the finite space
-- | (key × current-index): no DOM, no state, no fuel — `navigate` maps a keydown
-- | to "focus item N" or "do nothing". The consuming component owns the item list
-- | and performs the focus (and renders the roving tabindex: 0 for the current
-- | item, -1 for the rest, via `tabIndexFor`). This keeps the hard part total and
-- | testable; only the focus call touches the DOM.
-- |
-- | Honors orientation (which arrows are live), `dir` (RTL flips horizontal
-- | arrows), and `loop` (wrap at the ends). Home/End jump to first/last.
module Hydrogen.Radix.Behavior.RovingFocus
  ( Intent(..)
  , Move(..)
  , focusIntent
  , move
  , navigate
  , tabIndexFor
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Foundation.Style (Orientation(..))

-- | Where the user wants focus to go.
data Intent = Prev | Next | First | Last

derive instance eqIntent :: Eq Intent

-- | The result of a keydown: focus the item at this index, or nothing happened.
data Move = MoveTo Int | Stay

derive instance eqMove :: Eq Move

-- | Map a key to a navigation intent, given orientation and direction. Arrows on
-- | the inactive axis (and unrelated keys) produce `Nothing`. RTL swaps the
-- | horizontal arrows. (radix `getFocusIntent`.)
focusIntent :: Orientation -> Dir -> String -> Maybe Intent
focusIntent orientation dir key =
  let
    k = case dir, key of
      RTL, "ArrowLeft" -> "ArrowRight"
      RTL, "ArrowRight" -> "ArrowLeft"
      _, _ -> key
  in
    case k of
      "Home" -> Just First
      "End" -> Just Last
      "ArrowUp" -> if orientation == Vertical then Just Prev else Nothing
      "ArrowDown" -> if orientation == Vertical then Just Next else Nothing
      "ArrowLeft" -> if orientation == Horizontal then Just Prev else Nothing
      "ArrowRight" -> if orientation == Horizontal then Just Next else Nothing
      _ -> Nothing

-- | Apply an intent to the current index over `count` items, wrapping when `loop`.
move :: Boolean -> Int -> Int -> Intent -> Int
move loop count current = case _ of
  First -> 0
  Last -> count - 1
  Prev ->
    let i = current - 1
    in if i < 0 then (if loop then count - 1 else 0) else i
  Next ->
    let i = current + 1
    in if i >= count then (if loop then 0 else count - 1) else i

-- | The whole closed-form step: keydown → focus move (or stay).
navigate
  :: { orientation :: Orientation, dir :: Dir, loop :: Boolean }
  -> { count :: Int, current :: Int }
  -> String
  -> Move
navigate cfg st key = case focusIntent cfg.orientation cfg.dir key of
  Nothing -> Stay
  Just intent -> MoveTo (move cfg.loop st.count st.current intent)

-- | The roving tabindex value for item `idx` given the current tab stop.
tabIndexFor :: Int -> Int -> Int
tabIndexFor current idx = if idx == current then 0 else -1
