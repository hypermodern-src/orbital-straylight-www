-- | Hydrogen.Radix.DropdownMenu — a button-triggered menu (radix `DropdownMenu`).
-- |
-- | THE TEMPLATE for a Float + RovingFocus combination (ContextMenu, Menubar,
-- | Select all follow it). It is `Popover` (trigger + Popper-positioned content +
-- | Escape/pointer-outside dismissal + reposition + portal-to-body) PLUS a roving
-- | menu:
-- |   * items are DATA (`items :: Array MenuItem`);
-- |   * `role=menu` content with `role=menuitem` buttons, a roving tab stop, and
-- |     ArrowDown/Up navigation via `RovingFocus.navigate` (Vertical) → focus the
-- |     item ref;
-- |   * open focuses the first item; selecting an item raises `ItemSelected` and
-- |     closes.
-- |
-- | Portal-to-body follows the Popover template: the content is ALWAYS mounted
-- | (hidden with display:none when closed) so Halogen only patches — never removes —
-- | the node, which makes adopting it into `body` safe. On open we schedule
-- | `AfterOpen` via a one-shot rAF; it repositions then `finalize`s (adopt into body +
-- | focus the first item on the following frame). Reposition (scroll/resize) re-asserts
-- | the portal without re-focusing, because the placement modify re-parents the content
-- | out of body.
-- |
-- | v1 (by feel): non-modal, no Presence, single instance (fixed ids), no typeahead,
-- | no submenus. Those are noted follow-ups.
module Hydrogen.Radix.DropdownMenu
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
import Data.Tuple (Tuple(..))
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
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Envelope as Envelope
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
-- | separators. Roving focus + ArrowDown/Up navigate the items only; separators are
-- | skipped (they carry no ref and no role=menuitem).
data MenuEntry
  = MenuItemEntry MenuItem
  | MenuSeparator

-- | Smart constructor for a plain item (no shortcut/accent, enabled).
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
  , scrollRoot :: ClassNames     -- rt-ScrollAreaRoot
  , scrollViewport :: ClassNames -- rt-ScrollAreaViewport
  , menuViewport :: ClassNames   -- rt-BaseMenuViewport (the items wrapper)
  , focusRing :: ClassNames      -- rt-ScrollAreaViewportFocusRing
  , item :: ClassNames
  , shortcut :: ClassNames    -- the right-aligned shortcut span
  , separator :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-dropdown-trigger"
  , content: cn "rdx-dropdown-content"
  , scrollRoot: cn "rdx-dropdown-scroll-root"
  , scrollViewport: cn "rdx-dropdown-scroll-viewport"
  , menuViewport: cn "rdx-dropdown-viewport"
  , focusRing: cn "rdx-dropdown-focus-ring"
  , item: cn "rdx-dropdown-item"
  , shortcut: cn "rdx-dropdown-shortcut"
  , separator: cn "rdx-dropdown-separator"
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
  , contentStyle :: String     -- the content's CONSTANT style (outline + menu vars + pointer-events)
  , triggerAttrs :: Array (Tuple String String)  -- data-* on the trigger (e.g. accent-color)
  , portalAttrs :: Array (Tuple String String)   -- data-* on the content (theme re-application)
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
  , idPrefix: "rdx-dropdown"
  , style: defaultStyle
  , trigger: []
  , contentStyle: ""
  , triggerAttrs: []
  , portalAttrs: []
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
  , contentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentNode :: Maybe Node
  , triggerId :: String   -- generated on Initialize; the content's aria-labelledby source
  , contentId :: String   -- generated on Initialize; the trigger's aria-controls target + content id
  , openFocus :: Maybe Int  -- post-open focus target: Nothing = the content (click-open), Just i = item i (keyboard-open)
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | TriggerKeyDown KE.KeyboardEvent
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | EscapePressed
  | PointerDown Event
  | MenuKeyDown KE.KeyboardEvent
  | ItemClicked String
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-dropdown-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-dropdown-content"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-dropdown-wrapper"

itemRef :: String -> Int -> H.RefLabel
itemRef pfx i = H.RefLabel (pfx <> "-item-" <> show i)

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

component :: forall m. MonadEffect m => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        , initialize = Just Initialize
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
  , contentStyle: input.contentStyle
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , contentNode: Nothing
  , triggerId: ""
  , contentId: ""
  , openFocus: Nothing
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , HP.id st.triggerId
            , classes st.style.trigger
            , aria "expanded" (if open then "true" else "false")
            , aria "haspopup" "menu"
            , dataState (if open then "open" else "closed")
            , dataAttr "radix-popper-side" (sideName st.placedSide)
            , dataAttr "radix-popper-align" (alignName st.placedAlign)
            , HE.onClick \_ -> TriggerClicked
            , HE.onKeyDown TriggerKeyDown
            ]
              <> (if open then [ aria "controls" st.contentId ] else [])
              <> portalData st.triggerAttrs
          )
          (map HH.fromPlainHTML st.trigger)
      -- the popper WRAPPER (portal root) — position:fixed up front (shrink-to-fit measure);
      -- the rest of its style is FFI (positionWrapper).
      , HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          , dir "ltr"
          , HP.style (if open then "position: fixed;" else "display:none;")
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , HP.id st.contentId
                , role "menu"
                , classes st.style.content
                , aria "labelledby" st.triggerId
                , aria "orientation" "vertical"
                , dataState (if open then "open" else "closed")
                , dataAttr "side" (sideName st.placedSide)
                , dataAttr "align" (alignName st.placedAlign)
                , dataAttr "orientation" "vertical"
                , dataAttr "radix-menu-content" ""
                , dir "ltr"
                , HP.tabIndex (-1)
                , HP.style st.contentStyle
                , HE.onKeyDown MenuKeyDown
                ] <> portalData st.portalAttrs
              )
              -- the rt-ScrollArea nesting upstream wraps menu items in:
              -- scrollRoot > [ scrollViewport > table-div > menuViewport > items, focusRing ]
              [ HH.div
                  [ classes st.style.scrollRoot
                  , dir "ltr"
                  , HP.style "position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;"
                  ]
                  [ HH.div
                      [ classes st.style.scrollViewport
                      , dataAttr "radix-scroll-area-viewport" ""
                      , HP.style "overflow: scroll;"
                      ]
                      [ HH.div [ HP.style "min-width: 100%; display: table;" ]
                          [ HH.div [ classes st.style.menuViewport ] (renderEntries st) ]
                      ]
                  , HH.div [ classes st.style.focusRing ] []
                  ]
              ]
          ]
      ]

dir :: forall r i. String -> HP.IProp r i
dir = HP.attr (HH.AttrName "dir")

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

-- | A menu item is a DIV (radix uses generic elements, not buttons) with role=menuitem,
-- | a roving tab stop, optional per-item accent, and an optional right-aligned shortcut.
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
        <> (if st.focused == idx then [ dataAttr "highlighted" "" ] else [])
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
  Initialize -> do
    tid <- useId
    cid <- useId
    H.modify_ _ { triggerId = tid, contentId = cid }
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
      , contentStyle = input.contentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closeMenu else openMenu
  -- APG menu-button: on a CLOSED menu, ArrowDown opens + highlights the FIRST item,
  -- ArrowUp opens + highlights the LAST. (When open, the content owns key handling.)
  TriggerKeyDown ke -> do
    st <- H.get
    when (not (current st.ctrl)) case KE.key ke of
      "ArrowDown" -> liftEffect (preventDefault (KE.toEvent ke)) *> openMenuAt 0
      "ArrowUp" -> liftEffect (preventDefault (KE.toEvent ke)) *> openMenuAt (itemCount st.entries - 1)
      _ -> pure unit
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
        -- the focused-state re-render re-parents the wrapper out of body; on the next frame
        -- re-adopt it (before the trailing guard, preserving order) then focus the item.
        mwrap <- H.getHTMLElementRef wrapperRef
        mitem <- H.getHTMLElementRef (itemRef st.idPrefix idx)
        liftEffect $ Dom.queueMicrotask do
          for_ mwrap Envelope.reAdoptBeforeTrail
          for_ mitem HTMLElement.focus
  ItemClicked value -> do
    H.raise (ItemSelected value)
    closeMenu
  -- scroll/resize: just re-place. NOT re-adopt — the wrapper stays in body across renders
  -- (Halogen patches it in place), and re-adopting would move it past the trailing focus
  -- guard AND blur the focused content. (This bit the menu because lockScroll fires resize.)
  Reposition -> reposition

-- | Click-open: focus the menu CONTENT with NO item highlighted (the first ArrowDown
-- | highlights an item) — matches radix.
openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = openMenuWith (-1) Nothing

-- | Keyboard-open (APG menu-button): open with item `idx` highlighted and focused.
openMenuAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
openMenuAt idx = openMenuWith idx (Just idx)

openMenuWith :: forall m. MonadEffect m => Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
openMenuWith focusedIdx openFocus = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, focused = focusedIdx, restoreEl = mprev, openFocus = openFocus }
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
  -- a MICROTASK, not a frame: AfterOpen must focus the content before the open-state driver's
  -- first arrow key (which fires on the next macrotask). A rAF would be a frame too late.
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | On the next frame (after the placement modify's render re-parents the content),
-- | adopt the content into body — and, on open, focus the first item AFTER the move so
-- | the appendChild doesn't blur it.
-- | Adopt the WRAPPER into body; on open layer the MODAL menu envelope (radix DropdownMenu
-- | is modal: scroll-lock + focus guards + aria-hide siblings) and focus the menu content.
-- | SYNCHRONOUS (not an afterFrame): with the guarded reposition there's no pending re-render
-- | to re-parent the wrapper, so the content can be focused in this same frame — the
-- | open-state driver fires its arrow keys immediately, before a deferred focus would land.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  -- click-open focuses the menu CONTENT (role=menu, tabindex=-1); keyboard-open (APG
  -- menu-button) focuses the highlighted ITEM instead (openFocus = Just idx).
  mfocus <- if focusToo
    then case st.openFocus of
      Just idx -> H.getHTMLElementRef (itemRef st.idPrefix idx)
      Nothing -> H.getHTMLElementRef contentRef
    else pure Nothing
  case mbody, mwrap of
    Just body, Just wrap -> liftEffect do
      Portal.adopt body (HTMLElement.toElement wrap)
      when focusToo do
        Envelope.lockScroll
        Envelope.addFocusGuards
        Envelope.hideOthers wrap
        for_ mfocus HTMLElement.focus
    _, _ -> pure unit

closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    -- tear down the modal envelope + restore focus to the trigger captured on open
    liftEffect (Envelope.showOthers *> Envelope.removeFocusGuards *> Envelope.unlockScroll)
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing, openFocus = Nothing }
    H.raise (OpenChanged false)

reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  manchor <- H.getHTMLElementRef triggerRef
  mwrap <- H.getHTMLElementRef wrapperRef
  mfloat <- H.getHTMLElementRef contentRef
  case manchor, mwrap, mfloat of
    Just anchor, Just wrapper, Just floating -> do
      placed <- liftEffect (Popper.positionWrapper
        { anchor, wrapper, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      -- only modify (→ re-render, which re-parents the portaled wrapper) when the placement
      -- actually changed; a no-op reposition (e.g. the resize lockScroll fires) must not
      -- re-render, or the wrapper leaves body and we'd need to re-adopt.
      when (placed.placement.side /= st.placedSide || placed.placement.align /= st.placedAlign) $
        H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
    _, _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openMenu else closeMenu
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))