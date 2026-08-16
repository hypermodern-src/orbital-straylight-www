-- | Hydrogen.Radix.Foundation.Portal — render an overlay into a body-level container.
-- |
-- | radix's overlay components (Dialog, Popover, Tooltip, …) render their content into
-- | a container appended to `document.body`, so the content's `position: fixed`/absolute
-- | escapes any ancestor stacking context / `overflow` / `transform` containing block.
-- | This is the unstyled mechanism; the Themes preset supplies the container's class and
-- | (separately) copies the theme tokens onto it.
-- |
-- | NO new FFI: per Foundation.Dom's one-`.js`-file rule, this is pure PureScript over
-- | the typed `Web.DOM` / `Web.HTML` bindings — get-or-create a div, move a node into it,
-- | run after the next frame.
-- |
-- | Halogen owns the overlay node and re-parents it under the component root on each
-- | patch, so a caller that wants the node to *stay* in `body` re-asserts `adopt` after
-- | the render that moved it (via `afterFrame`). Moving the node does not detach Halogen's
-- | event listeners or invalidate its `RefLabel` — both track the element by reference.
module Hydrogen.Radix.Foundation.Portal
  ( documentBody
  , ensureContainer
  , adopt
  , afterFrame
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Unsafe.Reference (unsafeRefEq)
import Web.DOM (Element)
import Web.DOM.Document (createElement)
import Web.DOM.Element as Element
import Web.DOM.Node (appendChild, parentNode)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window (document, requestAnimationFrame)

-- | `document.body` as an `Element` — the upstream portal target (radix appends overlay
-- | layers as DIRECT children of `body`, no wrapper, so `adopt`-ing here matches the
-- | open-state DOM oracle). The Themes preset puts the `.radix-themes` class + tokens on
-- | the overlay node itself, not on a container.
documentBody :: Effect (Maybe Element)
documentBody = do
  doc <- window >>= document
  map HTMLElement.toElement <$> HTMLDocument.body doc

-- | Get (creating once) the shared body-level container `<div id className>`. Idempotent:
-- | a second call with the same id returns the existing node.
ensureContainer :: String -> String -> Effect Element
ensureContainer id className = do
  doc <- window >>= document
  existing <- querySelector (QuerySelector ("#" <> id)) (HTMLDocument.toParentNode doc)
  case existing of
    Just el -> pure el
    Nothing -> do
      el <- createElement "div" (HTMLDocument.toDocument doc)
      Element.setId id el
      Element.setClassName className el
      HTMLDocument.body doc >>= case _ of
        Just body -> appendChild (Element.toNode el) (HTMLElement.toNode body)
        Nothing -> pure unit
      pure el

-- | Move `node` into `container` (portal in) — a no-op when it is already a direct child,
-- | so re-asserting it each frame doesn't churn the DOM.
adopt :: Element -> Element -> Effect Unit
adopt container node = do
  let n = Element.toNode node
  let c = Element.toNode container
  parentNode n >>= case _ of
    Just p | unsafeRefEq p c -> pure unit
    _ -> appendChild n c

-- | Run an effect after the next animation frame — a stable "Halogen has patched the DOM"
-- | hook (the node a just-dispatched open action renders exists by the time this fires).
afterFrame :: Effect Unit -> Effect Unit
afterFrame eff = window >>= \w -> void (requestAnimationFrame eff w)
