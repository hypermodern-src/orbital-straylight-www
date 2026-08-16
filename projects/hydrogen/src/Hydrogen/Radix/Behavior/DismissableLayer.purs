-- | Hydrogen.Radix.Behavior.DismissableLayer — dismiss-on-escape and
-- | dismiss-on-outside-pointer (radix `DismissableLayer`), as Halogen
-- | subscription emitters a component subscribes from its eval.
-- |
-- | When a layer (Dialog/Popover/Menu) opens, the component does
-- |   `H.subscribe (escape docTarget HandleEscape)` and
-- |   `H.subscribe (pointerDown docTarget HandlePointerDown)`,
-- | keeping the SubscriptionIds to unsubscribe on close. In the pointer handler it
-- | calls `isOutside contentNode event` to decide whether to dismiss.
-- |
-- | Fully typed: escape/pointerdown are Halogen event emitters; containment is
-- | `Web.DOM.Node.contains` over the target recovered with `Node.fromEventTarget`.
-- | No foreign code.
-- |
-- | NOTE (deferred edge): radix maintains a layer stack so only the top layer
-- | dismisses, and can disable outside pointer-events entirely. We defer the stack
-- | (single active layer is the common case); nest-aware dismissal lands when the
-- | menu family needs it.
module Hydrogen.Radix.Behavior.DismissableLayer
  ( escape
  , pointerDown
  , isOutside
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Halogen.Query.Event (eventListener)
import Halogen.Subscription (Emitter)
import Web.DOM.Node (Node, contains, fromEventTarget)
import Web.Event.Event (Event, EventType(..))
import Web.Event.Event as Event
import Web.Event.EventTarget (EventTarget)
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET

-- | Emit `onEscape` whenever Escape is pressed on `target` (usually the document).
escape :: forall a. EventTarget -> a -> Emitter a
escape target onEscape =
  eventListener KET.keydown target \e ->
    KE.fromEvent e >>= \ke ->
      if KE.key ke == "Escape" then Just onEscape else Nothing

-- | Emit `f event` on every `pointerdown` on `target`. The component decides in
-- | its handler whether the pointer landed outside its content (`isOutside`).
pointerDown :: forall a. EventTarget -> (Event -> a) -> Emitter a
pointerDown target f =
  eventListener (EventType "pointerdown") target (Just <<< f)

-- | Whether the event's target lies OUTSIDE the given content node. A target that
-- | is not a DOM node (none recovered) counts as outside — matching radix, where a
-- | pointer landing on non-content dismisses the layer.
isOutside :: Node -> Event -> Effect Boolean
isOutside content e =
  case Event.target e >>= fromEventTarget of
    Nothing -> pure true
    Just node -> not <$> contains content node
