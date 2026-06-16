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
-- | PORTAL-TO-BODY (STR-335 floating template, mirrors Popover): the content is
-- | ALWAYS mounted (hidden with display:none when closed) so Halogen never removes
-- | the node — only patches it — which makes adopting it into `body` safe. On open
-- | we capture the restore target, schedule `AfterOpen` on the next frame, then on
-- | the frame after the placement modify we `Portal.adopt` the content into body
-- | and focus the first item. Reposition (scroll/resize) re-asserts the portal
-- | (the placement modify re-parents the content out of body).
-- |
-- | v1 (by feel), inherited from `DropdownMenu`: non-modal, no Presence,
-- | single instance (fixed ids), no typeahead, no submenus. Those are noted
-- | follow-ups.
module Hydrogen.Radix.ContextMenu
  ( component
  , MenuItem
  , MenuEntry(..)
  , menuItem
  , menuSeparator
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl, for_, traverse_)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), Orientation(..), cn, classes, dataState, dataAttr, sideName, alignName, role, aria)
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
  , shortcut :: Array HH.PlainHTML  -- right-aligned shortcut hint (empty = none)
  , accent :: String                -- per-item data-accent-color (e.g. "red"); "" = none
  , disabled :: Boolean
  }

-- | A menu is a list of ENTRIES: focusable items interleaved with non-focusable
-- | separators (roving focus navigates the items only).
data MenuEntry
  = MenuItemEntry MenuItem
  | MenuSeparator

menuItem :: String -> Array HH.PlainHTML -> MenuEntry
menuItem value label = MenuItemEntry { value, label, shortcut: [], accent: "", disabled: false }

menuSeparator :: MenuEntry
menuSeparator = MenuSeparator

-- | The number of focusable (non-separator) items — the roving-focus modulus.
itemCount :: Array MenuEntry -> Int
itemCount = Array.length <<< Array.filter case _ of
  MenuItemEntry _ -> true
  MenuSeparator -> false

type Style =
  { trigger :: ClassNames
  , content :: ClassNames
  , viewport :: ClassNames
  , item :: ClassNames
  , shortcut :: ClassNames
  , separator :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-context-menu-trigger"
  , content: cn "rdx-context-menu-content"
  , viewport: cn "rdx-context-menu-viewport"
  , item: cn "rdx-context-menu-item"
  , shortcut: cn "rdx-context-menu-shortcut"
  , separator: cn "rdx-context-menu-separator"
  }

type Input =
  { entries :: Array MenuEntry
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
  { entries: []
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
  , entries :: Array MenuEntry
  , focused :: Int               -- roving tab stop among focusable items
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , placedSide :: Side
  , placedAlign :: Align
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentNode :: Maybe Node
  }

data Action
  = Receive Input
  | Opened Event
  | AfterOpen           -- after the open render flushed: position + portal + focus
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
  , entries: input.entries
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
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
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
      -- content is ALWAYS mounted (hidden when closed) so Halogen never removes the
      -- node — only patches it — which makes adopting it into body safe. The open-state
      -- style string is CONSTANT, so Halogen won't rewrite it on re-render and clobber
      -- the left/top Popper applies via FFI; closing adds display:none.
      , HH.div
          [ HP.ref contentRef
          , role "menu"
          , classes st.style.content
          , dataState (if open then "open" else "closed")
          , dataAttr "side" (sideName st.placedSide)
          , dataAttr "align" (alignName st.placedAlign)
          , HP.tabIndex (-1)
          , HP.style (if open then "position:fixed;left:0;top:0;" else "position:fixed;left:0;top:0;display:none;")
          , HE.onKeyDown MenuKeyDown
          ]
          [ HH.div [ classes st.style.viewport ] (renderEntries st) ]
      ]

-- | Render the entries, threading a running focusable-item index so separators are
-- | skipped in the roving order (only MenuItemEntry consumes an index / gets a ref).
renderEntries :: forall m. State -> Array (H.ComponentHTML Action () m)
renderEntries st = _.html (foldl step { idx: 0, html: [] } st.entries)
  where
  step acc = case _ of
    MenuSeparator -> acc { html = acc.html <> [ renderSep st ] }
    MenuItemEntry item -> acc
      { idx = acc.idx + 1
      , html = acc.html <> [ renderItem st acc.idx item ]
      }

-- | A menu item is a DIV (radix uses generic elements) with role=menuitem, a roving tab
-- | stop, optional per-item accent, and an optional right-aligned shortcut.
renderItem :: forall m. State -> Int -> MenuItem -> H.ComponentHTML Action () m
renderItem st idx item =
  HH.div
    ( [ HP.ref (itemRef st.idPrefix idx)
      , role "menuitem"
      , classes st.style.item
      , HP.tabIndex (tabIndexFor st.focused idx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> (if item.accent == "" then [] else [ dataAttr "accent-color" item.accent ])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

renderSep :: forall m. State -> H.ComponentHTML Action () m
renderSep st =
  HH.div
    [ classes st.style.separator
    , role "separator"
    , aria "orientation" "horizontal"
    ]
    []

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , entries = input.entries
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
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body + focus
  -- the first item.
  AfterOpen -> do
    reposition
    finalize true
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
      pos = { count: itemCount st.entries, current: st.focused }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> do
        H.modify_ _ { focused = idx }
        focusItem st.idPrefix idx
  ItemClicked value -> do
    H.raise (ItemSelected value)
    closeMenu
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame). No re-focus.
  Reposition -> do
    reposition
    finalize false

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, focused = 0, restoreEl = mprev }
    H.raise (OpenChanged true)
    mcNode <- map HTMLElement.toNode <$> H.getHTMLElementRef contentRef
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    ptrSub <- H.subscribe (Dismiss.pointerDown docTarget PointerDown)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    psid <- scheduleAfterOpen
    H.modify_ _
      { contentNode = mcNode
      , subs = [ escSub, ptrSub, scrollSub, resizeSub ]
      , postSub = Just psid
      }

-- | Dispatch `AfterOpen` on the next animation frame (after the open render flushes).
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | On the next frame (after the placement modify's render re-parents the content),
-- | adopt the content into body — and, on open, focus the first item AFTER the move so
-- | the appendChild doesn't blur it.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mc <- H.getHTMLElementRef contentRef
  -- resolve the item element in HalogenM, then focus it INSIDE the afterFrame after the
  -- adopt move (so appendChild doesn't blur it). Mirrors DropdownMenu/Select.
  mitem <- if focusToo then H.getHTMLElementRef (itemRef st.idPrefix st.focused) else pure Nothing
  case mbody, mc of
    Just body, Just content ->
      liftEffect $ Portal.afterFrame do
        Portal.adopt body (HTMLElement.toElement content)
        for_ mitem HTMLElement.focus
    _, _ -> pure unit

closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    -- restore focus to the trigger
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing }
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