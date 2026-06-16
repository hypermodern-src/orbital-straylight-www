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
  , positionWrapper
  , positionWrapperAt
  , positionAt
  , positionArrow
  , positionItemAligned
  ) where

import Prelude

import Data.Int (toNumber)
import Effect (Effect)
import Hydrogen.Radix.Foundation.Dom (setInlineStyle)
import Hydrogen.Radix.Float.Compute (Coords, Placement, Positioned, Rect, computePosition)
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..))
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

-- | The popper transform-origin string, in the form radix/floating-ui emits: the cross
-- | axis is `0%`/`100%` for start/end alignment and a px for center; the main axis a px.
transformOriginFor :: Placement -> String
transformOriginFor { side, align } =
  let
    cross = case align of
      Start -> "0%"
      Center -> "0px"
      End -> "100%"
  in
    -- the cross axis is X for a vertical side (top/bottom), Y for a horizontal side
    -- (left/right); the main axis is a px (0px here, the oracle normalizes it).
    case side of
      Top -> cross <> " 0px"
      Bottom -> cross <> " 0px"
      Left -> "0px " <> cross
      Right -> "0px " <> cross

-- | Position a radix-style POPPER WRAPPER (the `data-radix-popper-content-wrapper` div that
-- | the content sits inside). Mirrors floating-ui's output: `position:fixed; left/top:0;
-- | transform:translate(x,y)` plus the `--radix-popper-*` custom properties the content's
-- | own vars alias. The properties are written in upstream's declaration order so the
-- | serialized style attribute matches byte-for-byte (modulo the px the oracle normalizes).
positionWrapper
  :: { anchor :: HTMLElement
     , wrapper :: HTMLElement
     , floating :: HTMLElement
     , side :: Side
     , align :: Align
     , offset :: Number
     , padding :: Number
     }
  -> Effect Positioned
positionWrapper p = do
  anchor <- measureRect p.anchor
  positionWrapperWith { anchor, wrapper: p.wrapper, floating: p.floating, side: p.side, align: p.align, offset: p.offset, padding: p.padding }

-- | As `positionWrapper`, but against a VIRTUAL zero-size anchor at a point (the cursor) —
-- | radix's point-anchored ContextMenu, with the popper-wrapper structure.
positionWrapperAt
  :: { point :: Coords
     , wrapper :: HTMLElement
     , floating :: HTMLElement
     , side :: Side
     , align :: Align
     , offset :: Number
     , padding :: Number
     }
  -> Effect Positioned
positionWrapperAt p =
  positionWrapperWith
    { anchor: { x: p.point.x, y: p.point.y, width: 0.0, height: 0.0 }
    , wrapper: p.wrapper, floating: p.floating, side: p.side, align: p.align, offset: p.offset, padding: p.padding
    }

positionWrapperWith
  :: { anchor :: Rect
     , wrapper :: HTMLElement
     , floating :: HTMLElement
     , side :: Side
     , align :: Align
     , offset :: Number
     , padding :: Number
     }
  -> Effect Positioned
positionWrapperWith p = do
  fl <- measureRect p.floating
  boundary <- viewportRect
  let
    solved = computePosition
      { anchor: p.anchor
      , floating: { width: fl.width, height: fl.height }
      , placement: { side: p.side, align: p.align }
      , offset: p.offset
      , boundary
      , padding: p.padding
      }
    availW = boundary.width - 2.0 * p.padding
    availH = boundary.height - 2.0 * p.padding
    px n = show n <> "px"
    set = setInlineStyle p.wrapper
  set "position" "fixed"
  set "left" "0px"
  set "top" "0px"
  set "transform" ("translate(" <> px solved.x <> ", " <> px solved.y <> ")")
  set "min-width" "max-content"
  set "z-index" "auto"
  set "--radix-popper-available-width" (px availW)
  set "--radix-popper-available-height" (px availH)
  set "--radix-popper-anchor-width" (px p.anchor.width)
  set "--radix-popper-anchor-height" (px p.anchor.height)
  set "--radix-popper-transform-origin" (transformOriginFor solved.placement)
  pure solved

-- | Position the floating element against a VIRTUAL zero-size anchor at a point (the
-- | cursor) instead of a DOM element — radix's point-anchored ContextMenu. Same solve,
-- | with a `{x, y, 0, 0}` anchor rect.
positionAt
  :: { point :: Coords
     , floating :: HTMLElement
     , side :: Side
     , align :: Align
     , offset :: Number
     , padding :: Number
     }
  -> Effect Positioned
positionAt p = do
  fl <- measureRect p.floating
  boundary <- viewportRect
  let
    anchor = { x: p.point.x, y: p.point.y, width: 0.0, height: 0.0 }
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

-- | Position an arrow element inside the floating content: centered on the anchor along
-- | the cross axis (clamped `padding` inside the content), pinned to the content edge
-- | facing the anchor, and rotated so the (down-pointing) arrow svg points AT the anchor.
-- | `side` is the RESOLVED placement (post-flip). Mutates the arrow's left/top/transform
-- | out-of-band (the arrow's rendered style must stay constant, like the content's).
positionArrow
  :: { anchor :: HTMLElement
     , floating :: HTMLElement
     , arrow :: HTMLElement
     , side :: Side
     , padding :: Number
     }
  -> Effect Unit
positionArrow p = do
  a <- measureRect p.anchor
  fl <- measureRect p.floating
  ar <- measureRect p.arrow
  let
    clamp lo hi v = max lo (min hi v)
    crossX = clamp p.padding (fl.width - ar.width - p.padding) (a.x + a.width / 2.0 - fl.x - ar.width / 2.0)
    crossY = clamp p.padding (fl.height - ar.height - p.padding) (a.y + a.height / 2.0 - fl.y - ar.height / 2.0)
    setL v = setInlineStyle p.arrow "left" (show v <> "px")
    setT v = setInlineStyle p.arrow "top" (show v <> "px")
    setR d = setInlineStyle p.arrow "transform" ("rotate(" <> show d <> "deg)")
    -- declaration order matches upstream's serialized form: position, transform, left, top,
    -- transform-origin (position already sits first from the element's rendered style).
    place deg lv tv origin = setInlineStyle p.arrow "position" "absolute"
      *> setR deg *> setL lv *> setT tv
      *> setInlineStyle p.arrow "transform-origin" origin
  case p.side of
    Bottom -> place 180.0 crossX (negate ar.height) "center 0px"
    Top -> place 0.0 crossX fl.height "center 0px"
    Right -> place 90.0 (negate ar.width) crossY "0px center"
    Left -> place 270.0 fl.width crossY "0px center"

-- | Radix Select's default "item-aligned" positioning: place the listbox so the SELECTED
-- | item sits over the trigger (its center aligned with the trigger's center) and the left
-- | edges line up — then clamp into the viewport (inset by `padding`). Unlike popper mode
-- | (content below/above the trigger), the content OVERLAYS the trigger.
positionItemAligned
  :: { trigger :: HTMLElement
     , content :: HTMLElement
     , selectedItem :: HTMLElement
     , padding :: Number
     }
  -> Effect Unit
positionItemAligned p = do
  t <- measureRect p.trigger
  c <- measureRect p.content
  it <- measureRect p.selectedItem
  vp <- viewportRect
  let
    -- the selected item's offset within the content (content is at its current top)
    selOffset = it.y - c.y
    -- align the selected item's CENTER with the trigger's center
    rawTop = (t.y + t.height / 2.0) - (selOffset + it.height / 2.0)
    clamp lo hi v = max lo (min (max lo hi) v)
    top = clamp (vp.y + p.padding) (vp.y + vp.height - c.height - p.padding) rawTop
    left = clamp (vp.x + p.padding) (vp.x + vp.width - c.width - p.padding) t.x
  applyPosition p.content { x: left, y: top }
