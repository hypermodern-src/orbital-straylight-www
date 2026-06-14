-- | Hydrogen.Radix.Float.Popper — the DOM wiring around the pure `Compute` core.
-- |
-- | A floating primitive (Popover/Tooltip/Menu/Select) calls `position` on open,
-- | and again on scroll/resize (subscribing via `windowTarget`), passing the
-- | anchor and floating elements; Popper measures them, runs
-- | `Compute.computePosition`, and pins the floating element. It returns the
-- | `Positioned` so the caller can echo `data-side`/`data-align`.
-- |
-- | Almost all of this is typed web bindings — `getBoundingClientRect` (measure),
-- | `innerWidth`/`innerHeight` (viewport), `toEventTarget` (the window) — so the
-- | only foreign touch is writing the solved `left`/`top`, through the one blessed
-- | style writer in `Hydrogen.Radix.Foundation.Dom`.
-- |
-- | NOTE: positioning mutates the floating element's `left`/`top` out-of-band, so
-- | the component must keep its rendered inline `style` constant (e.g. just
-- | `position:fixed`) — Halogen's vdom only re-patches a prop when its value
-- | changes, so a constant style string won't clobber the applied coords.
module Hydrogen.Radix.Float.Popper
  ( measureRect
  , viewportRect
  , applyPosition
  , windowTarget
  , position
  ) where

import Prelude

import Data.Int (toNumber)
import Effect (Effect)
import Hydrogen.Radix.Foundation.Dom (setInlineStyle)
import Hydrogen.Radix.Float.Compute (Coords, Positioned, Rect, computePosition)
import Hydrogen.Radix.Foundation.Style (Align, Side)
import Web.DOM.Element as Element
import Web.Event.EventTarget (EventTarget)
import Web.HTML as HTML
import Web.HTML.HTMLElement (HTMLElement)
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

-- | The element's viewport rect, via the typed `getBoundingClientRect`.
measureRect :: HTMLElement -> Effect Rect
measureRect el = do
  r <- Element.getBoundingClientRect (HTMLElement.toElement el)
  pure { x: r.x, y: r.y, width: r.width, height: r.height }

-- | The viewport as a boundary rect (`{0, 0, innerWidth, innerHeight}`).
viewportRect :: Effect Rect
viewportRect = do
  win <- HTML.window
  w <- Window.innerWidth win
  h <- Window.innerHeight win
  pure { x: 0.0, y: 0.0, width: toNumber w, height: toNumber h }

-- | Pin the floating element via `position:fixed; left; top` (the one inline-style
-- | writer the port uses).
applyPosition :: HTMLElement -> Coords -> Effect Unit
applyPosition el c = do
  setInlineStyle el "position" "fixed"
  setInlineStyle el "left" (show c.x <> "px")
  setInlineStyle el "top" (show c.y <> "px")

-- | The window as an event target (for scroll/resize reposition subscriptions).
windowTarget :: Effect EventTarget
windowTarget = Window.toEventTarget <$> HTML.window

-- | Measure anchor + floating against the viewport, solve, apply. Returns the
-- | placement actually used so the caller can echo `data-side`/`data-align`.
position
  :: { anchor :: HTMLElement
     , floating :: HTMLElement
     , side :: Side
     , align :: Align
     , offset :: Number
     , padding :: Number
     }
  -> Effect Positioned
position p = do
  anchor <- measureRect p.anchor
  fl <- measureRect p.floating
  boundary <- viewportRect
  let
    solved = computePosition
      { anchor
      , floating: { width: fl.width, height: fl.height }
      , placement: { side: p.side, align: p.align }
      , offset: p.offset
      , boundary
      , padding: p.padding
      }
  applyPosition p.floating { x: solved.x, y: solved.y }
  pure solved
