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
  , ensureContainer
  , adopt
  , setBodyOverflow
  , focus
  , isSelfTarget
  , afterFrame
  , anchorRect
  , containsTarget
  ) where

import Prelude

import Effect (Effect)
import Web.DOM (Element)
import Web.Event.Event (Event)

-- | A viewport rect (getBoundingClientRect) — the input to floating placement.
type Rect =
  { top :: Number, left :: Number, bottom :: Number, right :: Number, width :: Number, height :: Number }

foreign import _ensureContainer :: String -> Effect Element
foreign import _adopt :: Element -> Element -> Effect Unit
foreign import _setBodyOverflow :: String -> Effect String
foreign import _focus :: Element -> Effect Unit
foreign import _isSelfTarget :: Event -> Effect Boolean
foreign import _afterFrame :: Effect Unit -> Effect Unit
foreign import _anchorRect :: Element -> Effect Rect
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

-- | Does `node` contain the event's target? (inside/outside click test).
containsTarget :: Element -> Event -> Effect Boolean
containsTarget = _containsTarget
