-- | Hydrogen.Radix.ContextMenu — a right-click-triggered menu (radix `ContextMenu`).
-- |
-- | This is `DropdownMenu` with ONE behavioral difference: it opens on a
-- | `contextmenu` (right-click) event over a trigger AREA (a `div`) instead of a
-- | left-click on a button. Everything downstream is IDENTICAL: Popper
-- | positioning, a `role=menu` RovingFocus menu with `role=menuitem` buttons,
-- | Escape/pointer-outside dismissal, reposition on scroll/resize, focus-first
-- | on open, restore-focus to the trigger on close, and `ItemSelected` + close.
-- |
-- | v1 POSITIONING SIMPLIFICATION (point-anchor is a follow-up):
-- |   radix anchors the content to the EXACT mouse coordinates of the right-click
-- |   (a zero-size virtual anchor at `{ x, y }`). We instead anchor the content to
-- |   the trigger ELEMENT — we reuse `DropdownMenu`'s `Popper.position`
-- |   trigger→content with `side` (default Bottom) / `align` (default Start). True
-- |   point-anchored positioning needs a point-anchor variant of `Float.Popper`
-- |   (position relative to a virtual `{ x, y }` rect rather than a DOM element);
-- |   that is deferred.
-- |
-- | v1 (by feel), inherited from `DropdownMenu`: non-modal, no Presence, no portal,
-- | single instance (fixed ids), no typeahead, no submenus. Those are noted
-- | follow-ups.
module Hydrogen.Radix.ContextMenu
  ( component
  , MenuItem
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (length, mapWithIndex)
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Style (ClassNames, Side(..), Align(..), Orientation(..), cn, classes, dataState, dataAttr, sideName, alignName, role, aria)
import Web.DOM.Node (Node)
import Web.Event.Event (Event, EventType(..), preventDefault)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type MenuItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { trigger :: ClassNames
  , content :: ClassNames
  , item :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-context-menu-trigger"
  , content: cn "rdx-context-menu-content"
  , item: cn "rdx-context-menu-item"
  }

type Input =
  { items :: Array MenuItem
  , open :: Maybe Boolean
  , defaultOpen :: Boolean
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  }

defaultInput :: Input
defaultInput =
  { items: []
  , open: Nothing
  , defaultOpen: false
  , side: Bottom
  , align: Start
  , offset: 4.0
  , padding: 8.0
  , idPrefix: "rdx-context-menu"
  , style: defaultStyle
  , trigger: []
  }

data Output
  = OpenChanged Boolean
  | ItemSelected String

data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , items :: Array MenuItem
  , focused :: Int               -- roving tab stop among items
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , placedSide :: Side
  , placedAlign :: Align
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , subs :: Array H.SubscriptionId
  , contentNode :: Maybe Node
  }

data Action
  = Receive Input
  | Opened Event
  | EscapePressed
  | PointerDown Event
  | MenuKeyDown KE.KeyboardEvent
  | ItemClicked String
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-context-menu-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-context-menu-content"

itemRef :: String -> Int -> H.RefLabel
itemRef pfx i = H.RefLabel (pfx <> "-item-" <> show i)

component :: forall m. MonadEffect m => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        }
    }

initialState :: Input -> State
initialState input =
  { ctrl: controllable input.open input.defaultOpen
  , items: input.items
  , focused: 0
  , side: input.side
  , align: input.align
  , offset: input.offset
  , padding: input.padding
  , placedSide: input.side
  , placedAlign: input.align
  , idPrefix: input.idPrefix
  , style: input.style
  , trigger: input.trigger
  , subs: []
  , contentNode: Nothing
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div_
      [ HH.div
          [ HP.ref triggerRef
          , classes st.style.trigger
          , dataState (if open then "open" else "closed")
          , HE.handler (EventType "contextmenu") Opened
          ]
          (map HH.fromPlainHTML st.trigger)
      , if open then
          HH.div
            [ HP.ref contentRef
            , role "menu"
            , classes st.style.content
            , dataState "open"
            , dataAttr "side" (sideName st.placedSide)
            , dataAttr "align" (alignName st.placedAlign)
            , HP.tabIndex (-1)
            , HP.style "position:fixed;left:0;top:0;"
            , HE.onKeyDown MenuKeyDown
            ]
            (mapWithIndex (renderItem st) st.items)
        else HH.text ""
      ]

renderItem :: forall m. State -> Int -> MenuItem -> H.ComponentHTML Action () m
renderItem st idx item =
  HH.button
    ( [ HP.type_ HP.ButtonButton
      , HP.ref (itemRef st.idPrefix idx)
      , role "menuitem"
      , classes st.style.item
      , HP.tabIndex (tabIndexFor st.focused idx)
      , HP.disabled item.disabled
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> (if item.disabled then [ dataAttr "disabled" "" ] else [])
    )
    (map HH.fromPlainHTML item.label)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , items = input.items
      , side = input.side
      , align = input.align
      , offset = input.offset
      , padding = input.padding
      , idPrefix = input.idPrefix
      , style = input.style
      , trigger = input.trigger
      }
  Opened e -> do
    -- suppress the native browser context menu, then open ours
    liftEffect (preventDefault e)
    st <- H.get
    when (not (current st.ctrl)) openMenu
  EscapePressed -> closeMenu
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside closeMenu
  MenuKeyDown ke -> do
    st <- H.get
    let
      cfg = { orientation: Vertical, dir: LTR, loop: true }
      pos = { count: length st.items, current: st.focused }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> do
        H.modify_ _ { focused = idx }
        focusItem st.idPrefix idx
  ItemClicked value -> do
    H.raise (ItemSelected value)
    closeMenu
  Reposition -> reposition

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    H.modify_ _ { ctrl = (change true st.ctrl).next, focused = 0 }
    H.raise (OpenChanged true)
    reposition
    focusItem st.idPrefix 0
    mcNode <- map HTMLElement.toNode <$> H.getHTMLElementRef contentRef
    doc <- liftEffect (HTML.window >>= Window.document)
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    ptrSub <- H.subscribe (Dismiss.pointerDown docTarget PointerDown)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    H.modify_ _ { contentNode = mcNode, subs = [ escSub, ptrSub, scrollSub, resizeSub ] }

closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    -- restore focus to the trigger
    mtrig <- H.getHTMLElementRef triggerRef
    for_ mtrig (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, subs = [], contentNode = Nothing }
    H.raise (OpenChanged false)

focusItem :: forall m. MonadEffect m => String -> Int -> H.HalogenM State Action () Output m Unit
focusItem pfx idx = do
  mel <- H.getHTMLElementRef (itemRef pfx idx)
  for_ mel (liftEffect <<< HTMLElement.focus)

reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  manchor <- H.getHTMLElementRef triggerRef
  mfloat <- H.getHTMLElementRef contentRef
  case manchor, mfloat of
    Just anchor, Just floating -> do
      placed <- liftEffect (Popper.position
        { anchor, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
    _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openMenu else closeMenu
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
