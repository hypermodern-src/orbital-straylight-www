-- | Hydrogen.Themes.Portal — the overlay-layer primitives Bucket B (Dialog,
-- | AlertDialog, Popover, HoverCard, Tooltip, DropdownMenu, …) builds on.
-- |
-- | Radix's overlay components render into a body-level container so their
-- | `position: fixed` escapes any ancestor stacking / `overflow` / `transform`
-- | containing block. `ensureContainer` lazily creates one shared `.radix-themes`
-- | div on `document.body`; `adopt` moves a node into it. `setBodyOverflow` is the
-- | scroll-lock (returns the previous value to restore on close); `focus` moves
-- | focus to the opened layer (a11y + so Escape is caught); `isSelfTarget` is the
-- | click-outside test (the event landed on the backdrop, not its content).
module Hydrogen.Themes.Portal
  ( Rect
  , Size
  , Anchored
  , Placement
  , ensureContainer
  , adopt
  , setBodyOverflow
  , focus
  , isSelfTarget
  , afterFrame
  , anchorRect
  , viewportSize
  , solveAnchored
  , containsTarget
  ) where

import Prelude

import Effect (Effect)
import Web.DOM (Element)
import Web.Event.Event (Event)

-- | A viewport rect (getBoundingClientRect) — the input to floating placement.
type Rect =
  { top :: Number, left :: Number, bottom :: Number, right :: Number, width :: Number, height :: Number }

-- | A width/height pair (the viewport, or a measured panel).
type Size = { width :: Number, height :: Number }

-- | A floating-placement request: the preferred side, the cross-axis alignment
-- | (`"start"`/`"center"`/`"end"`), the main-axis gap, and the viewport-edge padding.
type Anchored = { preferTop :: Boolean, align :: String, offset :: Number, pad :: Number }

-- | A solved placement: viewport coords for a `position: fixed` panel + the chosen side.
type Placement = { top :: Number, left :: Number, side :: String }

foreign import _ensureContainer :: String -> Effect Element
foreign import _adopt :: Element -> Element -> Effect Unit
foreign import _setBodyOverflow :: String -> Effect String
foreign import _focus :: Element -> Effect Unit
foreign import _isSelfTarget :: Event -> Effect Boolean
foreign import _afterFrame :: Effect Unit -> Effect Unit
foreign import _anchorRect :: Element -> Effect Rect
foreign import _viewportSize :: Effect Size
foreign import _containsTarget :: Element -> Event -> Effect Boolean

-- | Get (creating once) the shared body-level container with the given id.
ensureContainer :: String -> Effect Element
ensureContainer = _ensureContainer

-- | Move a node into a container (no-op if already there).
adopt :: Element -> Element -> Effect Unit
adopt = _adopt

-- | Set `document.body`'s `overflow`, returning the previous value.
setBodyOverflow :: String -> Effect String
setBodyOverflow = _setBodyOverflow

-- | Focus an element (silently no-ops if it isn't focusable).
focus :: Element -> Effect Unit
focus = _focus

-- | Did the event land on its `currentTarget` itself (the backdrop), not a child?
isSelfTarget :: Event -> Effect Boolean
isSelfTarget = _isSelfTarget

-- | Run an effect after the next frame paints (after Halogen has patched the DOM).
afterFrame :: Effect Unit -> Effect Unit
afterFrame = _afterFrame

-- | The anchor's viewport rect — position a `fixed` panel directly from it.
anchorRect :: Element -> Effect Rect
anchorRect = _anchorRect

-- | The visual viewport size.
viewportSize :: Effect Size
viewportSize = _viewportSize

-- | Collision-aware placement: given the anchor rect, the (measured) panel size,
-- | and the viewport, choose a side (flipping to the opposite when the preferred
-- | side would overflow) and a left that's shifted to stay within the viewport.
-- | Pure — measure with `anchorRect` (anchor) + `anchorRect` on the panel ref
-- | (a `visibility:hidden` panel still has a real size) + `viewportSize`.
solveAnchored :: Anchored -> Rect -> Size -> Size -> Placement
solveAnchored cfg anchor panel vp =
  let
    belowTop = anchor.bottom + cfg.offset
    aboveTop = anchor.top - cfg.offset - panel.height
    fitsBelow = belowTop + panel.height <= vp.height - cfg.pad
    fitsAbove = aboveTop >= cfg.pad
    -- prefer-top: top unless it doesn't fit. prefer-bottom: bottom if it fits, else
    -- flip up only when above actually fits, else fall back to bottom.
    placeBottom =
      if cfg.preferTop then not fitsAbove
      else fitsBelow || not fitsAbove
    side = if placeBottom then "bottom" else "top"
    top = if placeBottom then belowTop else aboveTop
    rawLeft = case cfg.align of
      "center" -> anchor.left + (anchor.width - panel.width) / 2.0
      "end" -> anchor.right - panel.width
      _ -> anchor.left
    hiLeft = max cfg.pad (vp.width - panel.width - cfg.pad)
    left = max cfg.pad (min hiLeft rawLeft)
  in
    { top, left, side }

-- | Does `node` contain the event's target? (inside/outside click test).
containsTarget :: Element -> Event -> Effect Boolean
containsTarget = _containsTarget
