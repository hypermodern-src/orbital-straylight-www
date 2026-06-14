-- | Hydrogen.Radix.Behavior.FocusScope — focus trapping and restoration
-- | (radix `FocusScope`), as Effect helpers a component drives from its eval.
-- |
-- | A stateful primitive (Dialog, Popover, …) calls `captureFocus` when it opens
-- | (focusing the first tabbable element and returning a `Restore` action), wires
-- | `tabLoop` into the content's `onKeyDown` to keep Tab inside, and runs the
-- | `Restore` when it closes. All of it is pure PureScript over the typed web
-- | bindings — querying, focusing, narrowing `Node → HTMLElement`, reference
-- | identity (`unsafeRefEq`) — with the single foreign touch being the computed
-- | visibility read, through `Hydrogen.Radix.Dom`.
-- |
-- | NOTE (deferred edges): radix also keeps a global stack of nested scopes (an
-- | inner scope pauses an outer one) and a MutationObserver that re-focuses when
-- | the focused node is removed. We defer both — a single active scope is the
-- | common case. Tabbable discovery is a querySelector approximation filtered by
-- | computed visibility (radix uses a TreeWalker; same intent).
module Hydrogen.Radix.Behavior.FocusScope
  ( Restore
  , tabbables
  , captureFocus
  , tabLoop
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Hydrogen.Radix.Dom (computedStyle)
import Unsafe.Reference (unsafeRefEq)
import Web.DOM.NodeList as NodeList
import Web.DOM.ParentNode (QuerySelector(..), querySelectorAll) as PN
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- | An action that restores focus to wherever it was before the scope captured it.
type Restore = Effect Unit

tabbableSelector :: String
tabbableSelector =
  "a[href], button:not([disabled]), input:not([disabled]):not([type=hidden]), "
    <> "select:not([disabled]), textarea:not([disabled]), "
    <> "[tabindex]:not([tabindex=\"-1\"]):not([disabled])"

-- | Visible, in the computed-style sense: neither `visibility:hidden` nor
-- | `display:none`. The one query the type-checked bindings can't answer.
visible :: HTMLElement.HTMLElement -> Effect Boolean
visible el = do
  vis <- computedStyle el "visibility"
  disp <- computedStyle el "display"
  pure (vis /= "hidden" && disp /= "none")

-- | Visible, tabbable elements inside a container, in document order.
tabbables :: HTMLElement.HTMLElement -> Effect (Array HTMLElement.HTMLElement)
tabbables container = do
  nl <- PN.querySelectorAll (PN.QuerySelector tabbableSelector) (HTMLElement.toParentNode container)
  nodes <- NodeList.toArray nl
  Array.filterA visible (Array.mapMaybe HTMLElement.fromNode nodes)

-- | Focus the first tabbable element (or the container itself), recording the
-- | previously-focused element. Returns an action that restores it.
captureFocus :: HTMLElement.HTMLElement -> Effect Restore
captureFocus container = do
  doc <- HTML.window >>= Window.document
  prev <- HTMLDocument.activeElement doc
  ts <- tabbables container
  case Array.head ts of
    Just el -> HTMLElement.focus el
    Nothing -> HTMLElement.focus container
  pure (maybe (pure unit) HTMLElement.focus prev)

-- | Keep Tab inside the container: at the last element a forward Tab wraps to the
-- | first (and vice-versa) when `loop` is set. Returns `true` when it moved focus,
-- | i.e. the caller should `preventDefault`.
tabLoop :: Boolean -> HTMLElement.HTMLElement -> KE.KeyboardEvent -> Effect Boolean
tabLoop loop container ke =
  if KE.key ke /= "Tab" then pure false
  else do
    ts <- tabbables container
    case Array.head ts, Array.last ts of
      Just first, Just last -> do
        doc <- HTML.window >>= Window.document
        active <- HTMLDocument.activeElement doc
        let atLast = maybe false (\a -> unsafeRefEq a last) active
        let atFirst = maybe false (\a -> unsafeRefEq a first) active
        if not (KE.shiftKey ke) && atLast then do
          when loop (HTMLElement.focus first)
          pure loop
        else if KE.shiftKey ke && atFirst then do
          when loop (HTMLElement.focus last)
          pure loop
        else pure false
      _, _ -> pure false
