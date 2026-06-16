-- | Hydrogen.Radix.Select — a button-triggered listbox with a selected value
-- | (radix `Select`).
-- |
-- | Select IS `DropdownMenu`: a button trigger + a Popper-positioned floating
-- | content + Escape/pointer-outside dismissal + reposition + RovingFocus over the
-- | items + focus-first-on-open + restore-focus-to-trigger-on-close. It adds
-- | **listbox semantics** and a **selected value**:
-- |   * content is `role=listbox`, items are `role=option`;
-- |   * a SECOND controllable (`sel :: Controllable String`) carries the chosen
-- |     value alongside `ctrl :: Controllable Boolean` (open). Both are refreshed
-- |     from input on `Receive` (`sync input.open st.ctrl`, `sync input.value st.sel`);
-- |   * opening focuses the SELECTED item (its index, else 0) rather than always 0;
-- |   * arrow keys navigate + move focus only (do NOT select); selection happens on
-- |     Enter/click — choosing sets `sel`, raises `ValueChanged`, and closes
-- |     (restoring focus to the trigger).
-- |
-- | v1 (by feel): non-modal, no Presence, single instance (fixed ids),
-- | no typeahead. The trigger renders `input.trigger` (Array PlainHTML) as-is
-- | followed by the current selected value as text — a deliberate simplification
-- | (radix resolves the selected item's `label`; here it is the raw value string,
-- | or nothing when unselected). Those are noted follow-ups.
-- |
-- | Portal-to-body (STR-335 floating template, mirrors Hydrogen.Radix.Popover):
-- | the listbox content is ALWAYS mounted (hidden with display:none when closed) so
-- | Halogen only patches — never removes — the node, which makes adopting it into
-- | `document.body` safe. On open we schedule `AfterOpen` on the next frame (one-shot
-- | rAF), which repositions then `finalize`s: on the following frame it adopts the
-- | content into body AND focuses the selected item (the appendChild blurs it, so the
-- | focus must happen AFTER the move). scroll/resize `Reposition` re-asserts the
-- | portal too (the placement modify re-parents the content out of body), without
-- | re-focusing. The restore target (trigger) is captured BEFORE opening so no
-- | post-open `modify` un-portals the content.
module Hydrogen.Radix.Select
  ( component
  , SelectItem
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (find, findIndex, length, mapWithIndex, null)
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..), fromMaybe)
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
import Web.Event.Event (Event, EventType(..))
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type SelectItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { trigger :: ClassNames
  , value :: ClassNames      -- the trigger's inner value slot (rt-SelectTriggerInner)
  , content :: ClassNames
  , viewport :: ClassNames    -- the inner scroll/items wrapper (rt-SelectViewport)
  , group :: ClassNames       -- the option group (role=group)
  , label :: ClassNames       -- the group label
  , item :: ClassNames
  , indicator :: ClassNames   -- the selected-item check slot (rt-SelectItemIndicator)
  , itemText :: ClassNames    -- the per-option text span
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-select-trigger"
  , value: cn "rdx-select-value"
  , content: cn "rdx-select-content"
  , viewport: cn "rdx-select-viewport"
  , group: cn "rdx-select-group"
  , label: cn "rdx-select-label"
  , item: cn "rdx-select-item"
  , indicator: cn "rdx-select-indicator"
  , itemText: cn "rdx-select-item-text"
  }

type Input =
  { items :: Array SelectItem
  , open :: Maybe Boolean
  , defaultOpen :: Boolean
  , value :: Maybe String
  , defaultValue :: String
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML       -- rendered AFTER the value slot (e.g. the chevron)
  , groupLabel :: Array HH.PlainHTML    -- optional label heading the option group
  , checkIcon :: Array HH.PlainHTML     -- placed in the indicator slot of the selected item
  }

defaultInput :: Input
defaultInput =
  { items: []
  , open: Nothing
  , defaultOpen: false
  , value: Nothing
  , defaultValue: ""
  , side: Bottom
  , align: Start
  , offset: 4.0
  , padding: 8.0
  , idPrefix: "rdx-select"
  , style: defaultStyle
  , trigger: []
  , groupLabel: []
  , checkIcon: []
  }

data Output
  = OpenChanged Boolean
  | ValueChanged String

data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)
  | SetValue String a
  | GetValue (String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean   -- open
  , sel :: Controllable String     -- selected value
  , items :: Array SelectItem
  , focused :: Int                  -- roving tab stop among items
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , placedSide :: Side
  , placedAlign :: Align
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , groupLabel :: Array HH.PlainHTML
  , checkIcon :: Array HH.PlainHTML
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentNode :: Maybe Node
  }

data Action
  = Receive Input
  | TriggerClicked
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | EscapePressed
  | PointerDown Event
  | ListKeyDown KE.KeyboardEvent
  | ItemChosen String
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-select-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-select-content"

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
  , sel: controllable input.value input.defaultValue
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
  , groupLabel: input.groupLabel
  , checkIcon: input.checkIcon
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , contentNode: Nothing
  }

-- | The index of the currently selected item, or 0 when nothing matches.
selectedIndex :: State -> Int
selectedIndex st =
  fromMaybe 0 (findIndex (\item -> item.value == current st.sel) st.items)

-- | The selected item's LABEL (what radix shows in the trigger), not the raw value;
-- | empty when nothing is selected (the preset's placeholder, if any, would show).
selectedLabel :: forall m. State -> Array (H.ComponentHTML Action () m)
selectedLabel st = case find (\item -> item.value == current st.sel) st.items of
  Just item -> map HH.fromPlainHTML item.label
  Nothing -> []

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
    selected = current st.sel
  in
    HH.div_
      [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , classes st.style.trigger
            , role "combobox"
            , aria "autocomplete" "none"
            , aria "expanded" (if open then "true" else "false")
            , dataState (if open then "open" else "closed")
            , HE.onClick \_ -> TriggerClicked
            ]
              <> (if selected == "" then [ dataAttr "placeholder" "" ] else [])
          )
          -- the value slot (rt-SelectTriggerInner) wraps the selected value; the trigger
          -- PlainHTML (e.g. the chevron) renders after it.
          ( [ HH.span [ classes st.style.value ]
                [ HH.span [ HP.style "pointer-events:none" ] (selectedLabel st) ]
            ] <> map HH.fromPlainHTML st.trigger
          )
      -- content is ALWAYS mounted (hidden when closed) so Halogen never removes the
      -- node — only patches it — which makes adopting it into body safe. The open-state
      -- style string is CONSTANT, so Halogen won't rewrite it on re-render and clobber
      -- the left/top Popper applies via FFI; closing adds display:none.
      , HH.div
          [ HP.ref contentRef
          , role "listbox"
          , classes st.style.content
          , dataState (if open then "open" else "closed")
          , dataAttr "side" (sideName st.placedSide)
          , dataAttr "align" (alignName st.placedAlign)
          , HP.tabIndex (-1)
          , HP.style (if open then "position:fixed;left:0;top:0;" else "position:fixed;left:0;top:0;display:none;")
          , HE.onKeyDown ListKeyDown
          ]
          [ HH.div [ classes st.style.viewport ]
              [ HH.div [ classes st.style.group, role "group" ]
                  ( (if null st.groupLabel then [] else [ HH.div [ classes st.style.label ] (map HH.fromPlainHTML st.groupLabel) ])
                      <> mapWithIndex (renderItem st) st.items
                  )
              ]
          ]
      ]

-- | A select option is a DIV (role=option) carrying data-value/aria-selected/data-state,
-- | a check indicator when selected, and a text span. data-highlighted marks the roving
-- | focus (matches radix's highlighted styling).
renderItem :: forall m. State -> Int -> SelectItem -> H.ComponentHTML Action () m
renderItem st idx item =
  let
    isSelected = item.value == current st.sel
  in
    HH.div
      ( [ HP.ref (itemRef st.idPrefix idx)
        , role "option"
        , classes st.style.item
        , dataAttr "value" item.value
        , dataAttr "radix-collection-item" ""
        , aria "selected" (if isSelected then "true" else "false")
        , dataState (if isSelected then "checked" else "unchecked")
        , HP.tabIndex (tabIndexFor st.focused idx)
        , HE.onClick \_ -> ItemChosen item.value
        ]
          <> (if st.focused == idx then [ dataAttr "highlighted" "true" ] else [])
          <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
      )
      ( (if isSelected then [ HH.span [ classes st.style.indicator, aria "hidden" "true" ] (map HH.fromPlainHTML st.checkIcon) ] else [])
          <> [ HH.span [ classes st.style.itemText ] (map HH.fromPlainHTML item.label) ]
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , sel = sync input.value st.sel
      , items = input.items
      , side = input.side
      , align = input.align
      , offset = input.offset
      , padding = input.padding
      , idPrefix = input.idPrefix
      , style = input.style
      , trigger = input.trigger
      , groupLabel = input.groupLabel
      , checkIcon = input.checkIcon
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closeMenu else openMenu
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body + focus
  -- the selected item.
  AfterOpen -> do
    reposition
    st <- H.get
    finalize (Just st.focused)
  EscapePressed -> closeMenu
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside closeMenu
  ListKeyDown ke -> do
    st <- H.get
    let
      cfg = { orientation: Vertical, dir: LTR, loop: true }
      pos = { count: length st.items, current: st.focused }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> do
        H.modify_ _ { focused = idx }
        focusItem st.idPrefix idx
  ItemChosen value -> do
    st <- H.get
    let res = change value st.sel
    H.modify_ _ { sel = res.next }
    H.raise (ValueChanged res.emit)
    closeMenu
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame). No re-focus.
  Reposition -> do
    reposition
    finalize Nothing

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    let start = selectedIndex st
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, focused = start, restoreEl = mprev }
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
-- | adopt the content into body — and, when given a focus index, focus that item AFTER
-- | the move so the appendChild doesn't blur it.
finalize :: forall m. MonadEffect m => Maybe Int -> H.HalogenM State Action () Output m Unit
finalize mFocus = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mc <- H.getHTMLElementRef contentRef
  -- resolve the item element in HalogenM (refs aren't queryable from the afterFrame
  -- Effect), then focus it INSIDE the afterFrame after the adopt move (so appendChild
  -- doesn't blur it). Mirrors DropdownMenu.
  mitem <- case mFocus of
    Just idx -> H.getHTMLElementRef (itemRef st.idPrefix idx)
    Nothing -> pure Nothing
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
    -- restore focus to the trigger captured at open time
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing }
    H.raise (OpenChanged false)

focusItem :: forall m. MonadEffect m => String -> Int -> H.HalogenM State Action () Output m Unit
focusItem pfx idx = do
  mel <- H.getHTMLElementRef (itemRef pfx idx)
  for_ mel (liftEffect <<< HTMLElement.focus)

-- | Item-aligned positioning (radix Select's default): the listbox overlays the trigger
-- | with the SELECTED option aligned to it, not a popper dropdown below. Needs the trigger,
-- | the content, and the selected item's element.
reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  mtrigger <- H.getHTMLElementRef triggerRef
  mcontent <- H.getHTMLElementRef contentRef
  msel <- H.getHTMLElementRef (itemRef st.idPrefix (selectedIndex st))
  case mtrigger, mcontent, msel of
    Just trigger, Just content, Just selectedItem ->
      liftEffect (Popper.positionItemAligned { trigger, content, selectedItem, padding: st.padding })
    _, _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openMenu else closeMenu
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
  SetValue v a -> do
    st <- H.get
    let res = change v st.sel
    H.modify_ _ { sel = res.next }
    H.raise (ValueChanged res.emit)
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.sel)))