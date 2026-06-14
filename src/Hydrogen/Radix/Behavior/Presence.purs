-- | Hydrogen.Radix.Behavior.Presence — keep a node mounted through its exit
-- | animation (radix `Presence`).
-- |
-- | A pure three-state machine plus an `animationend` subscription. A component
-- | renders while `isRendered`, stamps `data-state` (open/closed) so CSS can run
-- | enter/exit animations, and only drops the node once the exit animation
-- | finishes (or immediately, if there is none):
-- |
-- |   present True  → Open
-- |   present False → Closing       (still rendered, data-state="closed")
-- |   finishExit    : Closing → Closed   (now unrendered)
-- |
-- | When it enters `Closing`, the component asks `hasAnimation` whether an exit
-- | animation is actually running: if not, it `finishExit`s immediately;
-- | otherwise it subscribes `animationEnd` and `finishExit`s when that fires.
-- |
-- | NOTE (deferred edge): radix re-reads the computed `animationName` across
-- | frames to catch animations that change mid-exit. We take the simpler
-- | snapshot — adequate for the standard enter/exit keyframe pattern.
module Hydrogen.Radix.Behavior.Presence
  ( Presence(..)
  , present
  , finishExit
  , isRendered
  , dataStateOf
  , hasAnimation
  , animationEnd
  ) where

import Prelude

import Effect (Effect)
import Halogen.Query.Event (eventListener)
import Halogen.Subscription (Emitter)
import Hydrogen.Radix.Dom (computedStyle)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget (EventTarget)
import Web.HTML.HTMLElement (HTMLElement)

data Presence = Open | Closing | Closed

derive instance eqPresence :: Eq Presence

instance showPresence :: Show Presence where
  show = case _ of
    Open -> "Open"
    Closing -> "Closing"
    Closed -> "Closed"

-- | Apply a present flag. Becoming present always re-opens; becoming absent
-- | starts the exit (only from `Open`) — `Closing`/`Closed` are left for
-- | `finishExit`.
present :: Boolean -> Presence -> Presence
present true _ = Open
present false Open = Closing
present false p = p

-- | The exit animation finished: drop the node.
finishExit :: Presence -> Presence
finishExit Closing = Closed
finishExit p = p

-- | Whether the node should be in the DOM.
isRendered :: Presence -> Boolean
isRendered Closed = false
isRendered _ = true

-- | The `data-state` value CSS targets for enter/exit.
dataStateOf :: Presence -> String
dataStateOf Open = "open"
dataStateOf _ = "closed"

-- | Whether the element currently has a CSS animation, by inspecting the
-- | resolved `animation-name` (no running animation reads as `"none"`).
hasAnimation :: HTMLElement -> Effect Boolean
hasAnimation el = do
  name <- computedStyle el "animation-name"
  pure (name /= "none" && name /= "")

-- | Emit `onEnd` when an `animationend` fires on `target` (the exiting node).
animationEnd :: forall a. EventTarget -> a -> Emitter a
animationEnd target onEnd =
  eventListener (EventType "animationend") target (\_ -> pure onEnd)
