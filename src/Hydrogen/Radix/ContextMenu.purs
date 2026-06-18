-- | Hydrogen.Radix.ContextMenu — a right-click-triggered menu (radix `ContextMenu`).
-- |
-- | This is `DropdownMenu` with TWO differences: it opens on a `contextmenu`
-- | (right-click) event over a trigger AREA (a `div`) instead of a left-click on a
-- | button, and it is POINT-ANCHORED — the menu opens at the exact cursor
-- | coordinates (a zero-size virtual anchor at `{ x, y }`) rather than relative to
-- | the trigger element. The trigger carries NO id / aria-controls / aria-expanded /
-- | aria-haspopup (it is not a labelling button), and the content carries NO id /
-- | aria-labelledby. Everything else is IDENTICAL: a floating popper-WRAPPER + a
-- | MODAL envelope (scroll-lock + focus guards + aria-hide siblings), a `role=menu`
-- | RovingFocus menu (the rt-ScrollArea item nesting), Escape/pointer-outside
-- | dismissal, reposition on scroll/resize, restore-focus to the trigger on close,
-- | and `ItemSelected` + close.
-- |
-- | PORTAL-TO-BODY (STR-335 floating template, mirrors DropdownMenu): the content is
-- | ALWAYS mounted (the wrapper hidden with display:none when closed) so Halogen
-- | never removes the node — only patches it — which makes adopting it into `body`
-- | safe. On open we capture the restore target, schedule `AfterOpen` via a one-shot
-- | microtask, then reposition + `finalize` (adopt the wrapper into body, layer the
-- | modal envelope, and focus the menu content). Reposition (scroll/resize) re-places
-- | only when the placement changed.
-- |
-- | v1 (by feel), inherited from `DropdownMenu`: no Presence, no typeahead, no
-- | submenus. Those are noted follow-ups.
module Hydrogen.Radix.ContextMenu
  ( component
  , MenuItem
  , CheckItem
  , RadioGroupData
  , RadioOption
  , MenuEntry(..)
  , CheckState(..)
  , menuItem
  , menuSeparator
  , menuCheckbox
  , menuRadioGroup
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
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), maybe)
import Data.String (Pattern(..), stripSuffix)
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
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
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
import Web.UIEvent.MouseEvent as ME

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

-- | Tri-state check status for a CheckboxItem (mirrors DropdownMenu.CheckState).
data CheckState = Checked | Unchecked | Indeterminate

derive instance eqCheckState :: Eq CheckState

type CheckItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , check :: CheckState
  , disabled :: Boolean
  }

type RadioOption =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type RadioGroupData =
  { value :: String
  , options :: Array RadioOption
  }

-- | A menu is a list of ENTRIES: focusable items interleaved with non-focusable
-- | separators (roving focus navigates the items only). CheckboxItem / RadioItem are
-- | focusable items (role=menuitemcheckbox / menuitemradio).
data MenuEntry
  = MenuItemEntry MenuItem
  | MenuSeparator
  | MenuCheckboxEntry CheckItem
  | MenuRadioGroupEntry RadioGroupData

menuItem :: String -> Array HH.PlainHTML -> MenuEntry
menuItem value label = MenuItemEntry { value, label, shortcut: [], accent: "", disabled: false }

menuSeparator :: MenuEntry
menuSeparator = MenuSeparator

menuCheckbox :: String -> Array HH.PlainHTML -> CheckState -> MenuEntry
menuCheckbox value label check = MenuCheckboxEntry { value, label, shortcut: [], check, disabled: false }

menuRadioGroup :: String -> Array RadioOption -> MenuEntry
menuRadioGroup value options = MenuRadioGroupEntry { value, options }

-- | The number of focusable (non-separator) items — the roving-focus modulus.
-- | The roving order counts only ENABLED items (upstream menu.tsx:540
-- | `getItems().filter(!disabled)`, :720 `focusable={!disabled}`). A disabled item
-- | renders but is excluded from the roving order entirely, so arrows skip OVER it.
itemCount :: Array MenuEntry -> Int
itemCount = foldl (\n e -> n + entryFocusables e) 0

entryFocusables :: MenuEntry -> Int
entryFocusables = case _ of
  MenuItemEntry item -> if item.disabled then 0 else 1
  MenuCheckboxEntry item -> if item.disabled then 0 else 1
  MenuRadioGroupEntry grp -> Array.length (Array.filter (not <<< _.disabled) grp.options)
  MenuSeparator -> 0

-- | The enabled MenuItem at roving index `n` (the keyboard-selection target). Mirrors
-- | the same enabled-only ordering `renderEntries` assigns refs/tabindex over.
enabledValueAt :: Int -> Array MenuEntry -> Maybe String
enabledValueAt n entries = Array.index (Array.concatMap enabledValues entries) n
  where
  enabledValues = case _ of
    MenuItemEntry item | not item.disabled -> [ item.value ]
    MenuCheckboxEntry item | not item.disabled -> [ item.value ]
    MenuRadioGroupEntry grp -> map _.value (Array.filter (not <<< _.disabled) grp.options)
    _ -> []

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
  , checkboxItem :: ClassNames
  , radioGroup :: ClassNames
  , radioItem :: ClassNames
  , indicator :: ClassNames
  , checkIndicator :: Array HH.PlainHTML
  , radioIndicator :: Array HH.PlainHTML
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-context-menu-trigger"
  , content: cn "rdx-context-menu-content"
  , scrollRoot: cn "rdx-context-menu-scroll-root"
  , scrollViewport: cn "rdx-context-menu-scroll-viewport"
  , menuViewport: cn "rdx-context-menu-viewport"
  , focusRing: cn "rdx-context-menu-focus-ring"
  , item: cn "rdx-context-menu-item"
  , shortcut: cn "rdx-context-menu-shortcut"
  , separator: cn "rdx-context-menu-separator"
  , checkboxItem: cn "rdx-context-menu-checkbox-item"
  , radioGroup: cn "rdx-context-menu-radio-group"
  , radioItem: cn "rdx-context-menu-radio-item"
  , indicator: cn "rdx-context-menu-indicator"
  , checkIndicator: []
  , radioIndicator: []
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
  , triggerStyle :: String     -- inline style on the trigger AREA (its size/border)
  , contentStyle :: String     -- the content's CONSTANT style (outline + menu vars + pointer-events)
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
  , idPrefix: "rdx-context-menu"
  , style: defaultStyle
  , trigger: []
  , triggerStyle: ""
  , contentStyle: ""
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
  , presence :: Presence  -- Open / Closing (mounted, exiting) / Closed (unmounted)
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
  , triggerStyle :: String
  , contentStyle :: String
  , portalAttrs :: Array (Tuple String String)
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot microtask subscription for AfterOpen / AfterClose
  , animSub :: Maybe H.SubscriptionId  -- content `animationend` subscription during exit
  , contentNode :: Maybe Node
  , point :: { x :: Number, y :: Number }  -- the right-click cursor point (virtual anchor)
  }

data Action
  = Receive Input
  | Opened Event
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | AfterClose          -- after the closing render flushed: re-adopt + arm exit animation
  | AnimDone            -- the content exit animation finished: finishExit + tear down envelope
  | EscapePressed
  | PointerDown Event
  | MenuKeyDown KE.KeyboardEvent
  | ItemClicked String
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-context-menu-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-context-menu-content"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-context-menu-wrapper"

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
        }
    }

initialState :: Input -> State
initialState input =
  { ctrl: controllable input.open input.defaultOpen
  , presence: if startOpen then Open else Closed
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
  , triggerStyle: input.triggerStyle
  , contentStyle: input.contentStyle
  , portalAttrs: input.portalAttrs
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , animSub: Nothing
  , contentNode: Nothing
  , point: { x: 0.0, y: 0.0 }
  }
  where
  startOpen = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
    -- rendered while Open OR Closing (Presence keeps the closing menu mounted with
    -- data-state="closed" through its exit animation, then drops it at Closed).
    rendered = isRendered st.presence
    -- the open RemoveScroll wrapper re-enables pointers over the content (`pointer-events: auto`
    -- baked into contentStyle). On close that block is released immediately (Envelope.clearPointerEvents)
    -- while the node lingers for the exit animation, so the closing render must NOT carry it.
    contentStyle' = if open then st.contentStyle else stripPointerEventsAuto st.contentStyle
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      [ HH.div
          [ HP.ref triggerRef
          , classes st.style.trigger
          -- the trigger AREA is itself the styled box (radix's Trigger is asChild) — its
          -- size/border come from triggerStyle, so there is no extra wrapper element.
          , HP.style st.triggerStyle
          , dataState (if open then "open" else "closed")
          , HE.handler (EventType "contextmenu") Opened
          ]
          (map HH.fromPlainHTML st.trigger)
      -- the popper WRAPPER (portal root) — position:fixed up front (shrink-to-fit measure);
      -- the rest of its style is FFI (positionWrapperAt) and PERSISTS across the exit (the node
      -- is never unmounted while Closing, so the positioned left/top/transform linger). The
      -- wrapper is in the tree while `rendered` (Open OR Closing); hidden only when fully Closed.
      , HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          , dir "ltr"
          , HP.style (if rendered then "position: fixed;" else "display:none;")
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , role "menu"
                , classes st.style.content
                , aria "orientation" "vertical"
                , dataState (dataStateOf st.presence)
                , dataAttr "side" (sideName st.placedSide)
                , dataAttr "align" (alignName st.placedAlign)
                , dataAttr "orientation" "vertical"
                , dataAttr "radix-menu-content" ""
                , dir "ltr"
                , HP.tabIndex (-1)
                , HP.style contentStyle'
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

-- | Drop a trailing ` pointer-events: auto;` (the open RemoveScroll pointer re-enable) from
-- | the content's inline style for the CLOSING render. The DOM effect mirrors
-- | `Envelope.clearPointerEvents`; doing it in render too keeps the lingering closed node's
-- | inline style identical to upstream (no `pointer-events` declaration) across re-renders.
stripPointerEventsAuto :: String -> String
stripPointerEventsAuto s =
  case stripSuffix (Pattern " pointer-events: auto;") s of
    Just trimmed -> trimmed
    Nothing -> case stripSuffix (Pattern "pointer-events: auto;") s of
      Just trimmed -> trimmed
      Nothing -> s

-- | Render the entries, threading a running focusable-item index so separators are
-- | skipped in the roving order (only MenuItemEntry consumes an index / gets a ref).
renderEntries :: forall m. State -> Array (H.ComponentHTML Action () m)
renderEntries st = _.html (foldl step { idx: 0, html: [] } st.entries)
  where
  step acc = case _ of
    MenuSeparator -> acc { html = acc.html <> [ renderSep st ] }
    MenuItemEntry item
      | item.disabled -> acc { html = acc.html <> [ renderItem st Nothing item ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderItem st (Just acc.idx) item ]
          }
    MenuCheckboxEntry item
      | item.disabled -> acc { html = acc.html <> [ renderCheckbox st Nothing item ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderCheckbox st (Just acc.idx) item ]
          }
    MenuRadioGroupEntry grp ->
      let
        inner = foldl (radioStep grp.value) { idx: acc.idx, html: [] } grp.options
      in
        acc
          { idx = inner.idx
          , html = acc.html <> [ HH.div [ classes st.style.radioGroup, role "group" ] inner.html ]
          }
  radioStep selected innerAcc opt
    | opt.disabled = innerAcc { html = innerAcc.html <> [ renderRadio st selected Nothing opt ] }
    | otherwise = innerAcc
        { idx = innerAcc.idx + 1
        , html = innerAcc.html <> [ renderRadio st selected (Just innerAcc.idx) opt ]
        }

-- | A menu item is a DIV (radix uses generic elements) with role=menuitem, a roving tab
-- | stop, optional per-item accent, and an optional right-aligned shortcut.
-- | `mIdx = Nothing` ⇒ the item is DISABLED — out of the roving order: tabindex -1,
-- | never `data-highlighted`, click is a no-op (the handler guards on disabled).
renderItem :: forall m. State -> Maybe Int -> MenuItem -> H.ComponentHTML Action () m
renderItem st mIdx item =
  HH.div
    ( [ role "menuitem"
      , classes st.style.item
      , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
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

checkAria :: CheckState -> String
checkAria = case _ of
  Checked -> "true"
  Unchecked -> "false"
  Indeterminate -> "mixed"

checkData :: CheckState -> String
checkData = case _ of
  Checked -> "checked"
  Unchecked -> "unchecked"
  Indeterminate -> "indeterminate"

renderIndicator :: forall m. State -> Array HH.PlainHTML -> CheckState -> Array (H.ComponentHTML Action () m)
renderIndicator st icon cs
  | cs == Unchecked = []
  | otherwise =
      [ HH.span
          [ classes st.style.indicator, dataState (checkData cs) ]
          (map HH.fromPlainHTML icon)
      ]

renderCheckbox :: forall m. State -> Maybe Int -> CheckItem -> H.ComponentHTML Action () m
renderCheckbox st mIdx item =
  HH.div
    ( [ role "menuitemcheckbox"
      , classes st.style.checkboxItem
      , aria "checked" (checkAria item.check)
      , dataState (checkData item.check)
      , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> renderIndicator st st.style.checkIndicator item.check
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

renderRadio :: forall m. State -> String -> Maybe Int -> RadioOption -> H.ComponentHTML Action () m
renderRadio st selected mIdx opt =
  let
    cs = if selected == opt.value then Checked else Unchecked
  in
    HH.div
      ( [ role "menuitemradio"
        , classes st.style.radioItem
        , aria "checked" (checkAria cs)
        , dataState (checkData cs)
        , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
        , dataAttr "radix-collection-item" ""
        , dataAttr "orientation" "vertical"
        , HE.onClick \_ -> ItemClicked opt.value
        ]
          <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
          <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
          <> (if opt.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
      )
      ( map HH.fromPlainHTML opt.label
          <> renderIndicator st st.style.radioIndicator cs
          <> (if Array.null opt.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML opt.shortcut) ])
      )

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
      , triggerStyle = input.triggerStyle
      , contentStyle = input.contentStyle
      , portalAttrs = input.portalAttrs
      }
  Opened e -> do
    -- suppress the native browser context menu, capture the cursor point (the menu's
    -- virtual anchor — radix point-anchors the content at the click), then open ours.
    liftEffect (preventDefault e)
    for_ (ME.fromEvent e) \me ->
      H.modify_ _ { point = { x: toNumber (ME.clientX me), y: toNumber (ME.clientY me) } }
    st <- H.get
    when (not (current st.ctrl)) openMenu
  -- after the open render flushed (content ref live): measure+place, then portal the
  -- wrapper into body + layer the modal envelope + focus the content.
  AfterOpen -> do
    reposition
    finalize true
  -- runs on the frame after the CLOSING render flushed. The focused-state/close re-render
  -- re-parents the wrapper back under the component root, so re-adopt it into body (it lingers
  -- there with data-state="closed" through the exit animation). Then arm the exit on the content
  -- (the node carrying the PopperContent exit animation): finishClose when `animationend` fires,
  -- or immediately if there is no running animation (radix → immediate unmount). The modal
  -- envelope (scroll-lock marker, focus guards, hideOthers) stays up until AnimDone.
  AfterClose -> do
    mnode <- H.getHTMLElementRef contentRef
    armed <- case mnode of
      Nothing -> pure false
      Just node -> do
        animates <- liftEffect (hasAnimation node)
        if animates then do
          sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
          H.modify_ _ { animSub = Just sub }
          pure true
        else pure false
    if armed then do
      -- re-adopt the wrapper BEFORE the trailing focus guard (the guards persist through the
      -- exit), preserving body order [lead, #root, wrapper, trail].
      mwrap <- H.getHTMLElementRef wrapperRef
      for_ mwrap (liftEffect <<< Envelope.reAdoptBeforeTrail)
      -- release the pointer block the OPEN envelope set (body `pointer-events:none` lifts, the
      -- content's `pointer-events:auto` is cleared) while the closing node lingers; the
      -- `data-scroll-locked` marker + focus guards + hideOthers stay until unmount.
      liftEffect Envelope.releaseScrollPointer
      for_ mnode \node -> liftEffect (Envelope.clearPointerEvents (HTMLElement.toElement node))
    else finishClose
  AnimDone -> finishClose
  EscapePressed -> closeMenu
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside closeMenu
  MenuKeyDown ke -> do
    st <- H.get
    let
      key = KE.key ke
      cfg = { orientation: Vertical, dir: LTR, loop: true }
      pos = { count: itemCount st.entries, current: st.focused }
    -- Enter/Space SELECT the focused item (upstream menu.tsx:667-680 SELECTION_KEYS →
    -- currentTarget.click() + preventDefault). Keyboard activation of items, previously
    -- impossible (navigate returned Stay for these keys).
    if (key == "Enter" || key == " ")
      && st.focused >= 0 then do
      liftEffect (preventDefault (KE.toEvent ke))
      for_ (enabledValueAt st.focused st.entries) \v -> do
        H.raise (ItemSelected v)
        closeMenu
    else case navigate cfg pos key of
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
    st <- H.get
    -- a disabled item is non-interactive (upstream menu.tsx:639 handleSelect disabled
    -- guard) — clicking it neither selects nor closes the menu.
    let
      pick = case _ of
        MenuItemEntry it | it.value == value -> Just it.disabled
        MenuCheckboxEntry it | it.value == value -> Just it.disabled
        MenuRadioGroupEntry grp -> map _.disabled (Array.find (\o -> o.value == value) grp.options)
        _ -> Nothing
      mDisabled = Array.findMap pick st.entries
    when (maybe true not mDisabled) do
      H.raise (ItemSelected value)
      closeMenu
  -- scroll/resize: just re-place. NOT re-adopt — the wrapper stays in body across renders
  -- (Halogen patches it in place), and re-adopting would move it past the trailing focus
  -- guard AND blur the focused content. (This bit the menu because lockScroll fires resize.)
  Reposition -> reposition

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    -- re-opening cancels any in-flight exit (the wrapper is still mounted/Closing).
    for_ st.animSub H.unsubscribe
    -- open with NO item highlighted (focus goes to the menu content; the first ArrowDown
    -- highlights an item) — matches radix. focused = -1 means "no roving highlight".
    H.modify_ _ { ctrl = (change true st.ctrl).next, presence = Open, animSub = Nothing, focused = -1, restoreEl = mprev }
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

-- | Dispatch `AfterOpen` after the open render flushes.
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  -- a MICROTASK, not a frame: AfterOpen must focus the content before the open-state driver's
  -- first arrow key (which fires on the next macrotask). A rAF would be a frame too late.
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | Adopt the WRAPPER into body; on open layer the MODAL menu envelope (scroll-lock + focus
-- | guards + aria-hide siblings) and focus the menu content.
-- | SYNCHRONOUS (not an afterFrame): with the guarded reposition there's no pending re-render
-- | to re-parent the wrapper, so the content can be focused in this same frame — the
-- | open-state driver fires its arrow keys immediately, before a deferred focus would land.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  -- radix focuses the menu CONTENT on open (role=menu, tabindex=-1), not an item.
  mcontent <- if focusToo then H.getHTMLElementRef contentRef else pure Nothing
  case mbody, mwrap of
    Just body, Just wrap -> liftEffect do
      Portal.adopt body (HTMLElement.toElement wrap)
      when focusToo do
        Envelope.lockScroll
        Envelope.addFocusGuards
        Envelope.hideOthers wrap
        for_ mcontent HTMLElement.focus
    _, _ -> pure unit

-- | Begin the close: flip controllable + Presence to Closing (the wrapper/content stay MOUNTED
-- | with data-state="closed", still portaled in body, envelope still up), tear down the
-- | open-time document subscriptions, restore focus to the trigger, and schedule AfterClose to
-- | arm the exit animation on the next frame. The envelope teardown + unmount happen at AnimDone.
closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    -- restore focus to the trigger captured on open (the envelope teardown waits for AnimDone).
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, presence = present false st.presence, subs = [], postSub = Nothing, contentNode = Nothing }
    H.raise (OpenChanged false)
    psid <- scheduleAfterClose
    H.modify_ _ { postSub = Just psid }

-- | Dispatch `AfterClose` after the closing render flushes.
scheduleAfterClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterClose = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterClose <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | The exit animation finished (or there was none): tear down the modal envelope, restore
-- | focus already happened in closeMenu, drop the wrapper (Presence Closing → Closed unmounts
-- | it), and clear the exit subscriptions.
finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  liftEffect (Envelope.showOthers *> Envelope.removeFocusGuards *> Envelope.unlockScroll)
  H.modify_ _ { presence = finishExit st.presence, restoreEl = Nothing, animSub = Nothing, postSub = Nothing }

-- | Point-anchored: position the popper WRAPPER at the captured cursor point (a zero-size
-- | virtual anchor), NOT the trigger element — radix's ContextMenu places the menu where
-- | you clicked, not relative to the trigger area.
reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  mwrap <- H.getHTMLElementRef wrapperRef
  mfloat <- H.getHTMLElementRef contentRef
  case mwrap, mfloat of
    Just wrapper, Just floating -> do
      placed <- liftEffect (Popper.positionWrapperAt
        { point: st.point, wrapper, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      -- only modify (→ re-render, which re-parents the portaled wrapper) when the placement
      -- actually changed; a no-op reposition (e.g. the resize lockScroll fires) must not
      -- re-render, or the wrapper leaves body and we'd need to re-adopt.
      when (placed.placement.side /= st.placedSide || placed.placement.align /= st.placedAlign) $
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
