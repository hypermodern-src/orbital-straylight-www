-- | Hydrogen.Radix.Select — a button-triggered listbox with a selected value
-- | (radix `Select`).
-- |
-- | Select IS a MODAL `DropdownMenu` whose floating content is ITEM-ALIGNED rather than
-- | popper-positioned: a button trigger + a `role=listbox` content + Escape/pointer-outside
-- | dismissal + reposition + a selected value. It adds **listbox semantics**:
-- |   * content is `role=listbox`, items are `role=option`;
-- |   * a SECOND controllable (`sel :: Controllable String`) carries the chosen value
-- |     alongside `ctrl :: Controllable Boolean` (open). Both are refreshed from input on
-- |     `Receive` (`sync input.open st.ctrl`, `sync input.value st.sel`);
-- |   * opening focuses the listbox CONTENT (radix focuses the content on open, not an
-- |     item, not the trigger), and item-aligns the listbox so the SELECTED option overlays
-- |     the trigger;
-- |   * choosing an item sets `sel`, raises `ValueChanged`, and closes (restoring focus to
-- |     the trigger).
-- |
-- | MODAL envelope (mirrors DropdownMenu): on open the body is scroll-locked
-- | (`data-scroll-locked` + `pointer-events:none`), the two focus-guard sentinels bracket
-- | the body, and every other body child is aria-hidden. Torn down on close.
-- |
-- | Portal-to-body: the listbox sits inside a plain POSITION WRAPPER (`wrapperRef`) that is
-- | ALWAYS mounted (hidden with `display:none` when closed) so Halogen only patches — never
-- | removes — the node, which makes adopting the WRAPPER into `document.body` safe. On open
-- | we schedule `AfterOpen` via a one-shot MICROTASK; it `reposition`s (item-aligned, which
-- | sets the whole wrapper style) then `finalize`s SYNCHRONOUSLY: adopt the wrapper into
-- | body, layer the modal envelope, and focus the content. `Reposition` (scroll/resize)
-- | re-asserts placement only.
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

import Data.Array (find, findIndex, index, length, mapWithIndex, null)
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Traversable (traverse)
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
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Envelope as Envelope
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, role, aria)
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

type SelectItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { trigger :: ClassNames
  , value :: ClassNames          -- the trigger's inner value slot (rt-SelectTriggerInner)
  , content :: ClassNames        -- the role=listbox content
  , scrollRoot :: ClassNames     -- rt-ScrollAreaRoot
  , scrollViewport :: ClassNames -- rt-ScrollAreaViewport rt-SelectViewport
  , group :: ClassNames          -- the option group (role=group)
  , label :: ClassNames          -- the group label
  , item :: ClassNames
  , indicator :: ClassNames      -- the selected-item check slot (rt-SelectItemIndicator)
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-select-trigger"
  , value: cn "rdx-select-value"
  , content: cn "rdx-select-content"
  , scrollRoot: cn "rdx-select-scroll-root"
  , scrollViewport: cn "rdx-select-scroll-viewport"
  , group: cn "rdx-select-group"
  , label: cn "rdx-select-label"
  , item: cn "rdx-select-item"
  , indicator: cn "rdx-select-indicator"
  }

type Input =
  { items :: Array SelectItem
  , open :: Maybe Boolean
  , defaultOpen :: Boolean
  , value :: Maybe String
  , defaultValue :: String
  , offset :: Number
  , padding :: Number
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML       -- rendered AFTER the value slot (e.g. the chevron)
  , groupLabel :: Array HH.PlainHTML    -- optional label heading the option group
  , checkIcon :: Array HH.PlainHTML     -- placed in the indicator slot of the selected item
  , placeholder :: Array HH.PlainHTML   -- shown in the value slot when nothing is selected; gates data-placeholder
  , contentStyle :: String              -- the content's CONSTANT style (box-sizing/flex/outline/pointer-events)
  , portalAttrs :: Array (Tuple String String)  -- data-* on the content (theme re-application)
  , name :: String      -- form field name; "" ⇒ NO hidden native <select> (BubbleSelect) rendered
  , required :: Boolean  -- aria-required on the trigger AND `required` on the hidden native select
  , disabled :: Boolean  -- disabled trigger (button[disabled] + data-disabled); the popup never opens
  }

defaultInput :: Input
defaultInput =
  { items: []
  , open: Nothing
  , defaultOpen: false
  , value: Nothing
  , defaultValue: ""
  , offset: 4.0
  , padding: 8.0
  , idPrefix: "rdx-select"
  , style: defaultStyle
  , trigger: []
  , groupLabel: []
  , checkIcon: []
  , placeholder: []
  , contentStyle: ""
  , portalAttrs: []
  , name: ""
  , required: false
  , disabled: false
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
  , offset :: Number
  , padding :: Number
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , groupLabel :: Array HH.PlainHTML
  , checkIcon :: Array HH.PlainHTML
  , placeholder :: Array HH.PlainHTML
  , contentStyle :: String
  , portalAttrs :: Array (Tuple String String)
  , name :: String
  , required :: Boolean
  , disabled :: Boolean
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot subscription for AfterOpen
  , contentNode :: Maybe Node
  , contentId :: String   -- generated on Initialize; trigger aria-controls target + content id (= <id0>)
  , labelId :: String     -- generated on Initialize; group aria-labelledby + label id (= <id1>)
  , itemIds :: Array String  -- generated on Initialize; per-option value-span ids (= <id2>…)
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | TriggerKeyDown KE.KeyboardEvent
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

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-select-wrapper"

itemRef :: String -> Int -> H.RefLabel
itemRef pfx i = H.RefLabel (pfx <> "-item-" <> show i)

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

dir :: forall r i. String -> HP.IProp r i
dir = HP.attr (HH.AttrName "dir")

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
  , sel: controllable input.value input.defaultValue
  , items: input.items
  , focused: 0
  , offset: input.offset
  , padding: input.padding
  , idPrefix: input.idPrefix
  , style: input.style
  , trigger: input.trigger
  , groupLabel: input.groupLabel
  , checkIcon: input.checkIcon
  , placeholder: input.placeholder
  , contentStyle: input.contentStyle
  , portalAttrs: input.portalAttrs
  , name: input.name
  , required: input.required
  , disabled: input.disabled
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , contentNode: Nothing
  , contentId: ""
  , labelId: ""
  , itemIds: []
  }

-- | The index of the currently selected item, or 0 when nothing matches.
selectedIndex :: State -> Int
selectedIndex st =
  fromMaybe 0 (findIndex (\item -> item.value == current st.sel) st.items)

-- | True when nothing is selected — the trigger shows the placeholder + carries
-- | data-placeholder (upstream shouldShowPlaceholder: value is '' or no matching item).
showPlaceholder :: State -> Boolean
showPlaceholder st = case find (\item -> item.value == current st.sel) st.items of
  Just _ -> false
  Nothing -> true

-- | The selected item's LABEL (what radix shows in the trigger), not the raw value;
-- | the placeholder when nothing is selected (matches upstream Select.Value placeholder).
selectedLabel :: forall m. State -> Array (H.ComponentHTML Action () m)
selectedLabel st = case find (\item -> item.value == current st.sel) st.items of
  Just item -> map HH.fromPlainHTML item.label
  Nothing -> map HH.fromPlainHTML st.placeholder

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      ( [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , classes st.style.trigger
            , role "combobox"
            , aria "autocomplete" "none"
            , aria "expanded" (if open then "true" else "false")
            , dataState (if open then "open" else "closed")
            , dir "ltr"
            , HE.onClick \_ -> TriggerClicked
            , HE.onKeyDown TriggerKeyDown
            ]
              -- aria-required is stamped only when the field is required (upstream forwards
              -- the Root's `required` to the react-select trigger; unset ⇒ no attribute).
              <> (if st.required then [ aria "required" "true" ] else [])
              <> (if st.disabled then [ HP.disabled true, dataAttr "disabled" "" ] else [])
              <> (if open then [ aria "controls" st.contentId ] else [])
              <> (if showPlaceholder st then [ dataAttr "placeholder" "" ] else [])
          )
          -- the value slot (rt-SelectTriggerInner) wraps the selected value; the trigger
          -- PlainHTML (e.g. the chevron) renders after it.
          ( [ HH.span [ classes st.style.value ]
                [ HH.span [ HP.style "pointer-events: none;" ] (selectedLabel st) ]
            ] <> map HH.fromPlainHTML st.trigger
          )
      ]
      -- the POSITION WRAPPER (portal root) renders ONLY while open; fully UNMOUNTED when closed,
      -- matching upstream (no listbox node at closed-rest). finalize re-adopts it into body on
      -- each open. (Select unmounts synchronously on close — no exit linger.) Its whole style is
      -- written out-of-band by positionItemAligned after mount (display:flex; position:fixed; …).
      <> ( if open then
      [ HH.div
          [ HP.ref wrapperRef
          , HP.style ""
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , HP.id st.contentId
                , role "listbox"
                , classes st.style.content
                , dataState (if open then "open" else "closed")
                , dir "ltr"
                , HP.tabIndex (-1)
                , HP.style st.contentStyle
                , HE.onKeyDown ListKeyDown
                ] <> portalData st.portalAttrs
              )
              -- Select's rt-ScrollArea nesting:
              -- scrollRoot > scrollViewport > table-div > group > [ label, items… ]
              [ HH.div
                  [ classes st.style.scrollRoot
                  , dir "ltr"
                  , HP.style "position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;"
                  ]
                  [ HH.div
                      [ classes st.style.scrollViewport
                      , dataAttr "radix-scroll-area-viewport" ""
                      , dataAttr "radix-select-viewport" ""
                      , role "presentation"
                      , HP.style "overflow: hidden auto; position: relative; flex: 1 1 0%;"
                      ]
                      [ HH.div [ HP.style "min-width: 100%; display: table;" ]
                          [ HH.div
                              [ classes st.style.group
                              , role "group"
                              , aria "labelledby" st.labelId
                              ]
                              ( (if null st.groupLabel then [] else [ HH.div [ classes st.style.label, HP.id st.labelId ] (map HH.fromPlainHTML st.groupLabel) ])
                                  <> mapWithIndex (renderItem st) st.items
                              )
                          ]
                      ]
                  ]
              ]
          ]
      ] else [] )
        -- BubbleSelect: the hidden native <select> form-participation node (react-select
        -- SelectBubbleInput). Rendered ONLY when a form name is set (the port's analogue of
        -- upstream's isFormControl gate — the consumer opts in by giving the field a name AND
        -- wrapping the slot in a <form>). aria-hidden, tabindex=-1, visually-hidden, mirroring
        -- the selected value via <option selected>. `required`/`disabled` mirror the trigger.
        <> renderBubbleSelect st
      )

-- | The hidden native <select> (SelectBubbleInput) — present only when `name` is set.
-- | Visually-hidden (the upstream VISUALLY_HIDDEN_STYLES), aria-hidden, tabindex=-1, with
-- | one <option> per item (the selected one carrying `selected`). Mirrors the trigger's
-- | required/disabled. This is the node that participates in native form submission.
renderBubbleSelect :: forall m. State -> Array (H.ComponentHTML Action () m)
renderBubbleSelect st
  | st.name == "" = []
  | otherwise =
      [ HH.select
          ( [ aria "hidden" "true"
            , HP.name st.name
            , HP.tabIndex (-1)
            , HP.style bubbleSelectStyle
            ]
              <> (if st.required then [ HP.required true ] else [])
              <> (if st.disabled then [ HP.disabled true ] else [])
          )
          (map (renderBubbleOption (current st.sel)) st.items)
      ]

-- | The VISUALLY_HIDDEN_STYLES serialization React emits (px-normalized in the oracle). Order
-- | and values mirror @radix-ui/react-visually-hidden so the at-rest DOM is byte-identical.
bubbleSelectStyle :: String
bubbleSelectStyle =
  "position: absolute; border: 0px; width: 1px; height: 1px; padding: 0px; margin: -1px; "
    <> "overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; overflow-wrap: normal;"

renderBubbleOption :: forall m. String -> SelectItem -> H.ComponentHTML Action () m
renderBubbleOption selected item =
  HH.option
    -- the selected option carries a bare `selected` attribute (matching React's
    -- defaultValue-driven serialization: `selected=`), gating native form value.
    ([ HP.value item.value ] <> (if item.value == selected then [ HP.attr (HH.AttrName "selected") "" ] else []))
    (map HH.fromPlainHTML item.label)

-- | A select option is a DIV (role=option) carrying aria-labelledby/aria-selected/data-state,
-- | a check indicator when selected, and a value span (id only, no class). The SELECTED
-- | option also carries `data-highlighted` (radix highlights the selected one on open).
renderItem :: forall m. State -> Int -> SelectItem -> H.ComponentHTML Action () m
renderItem st idx item =
  let
    isSelected = item.value == current st.sel
    itemId = fromMaybe "" (index st.itemIds idx)
  in
    HH.div
      ( [ HP.ref (itemRef st.idPrefix idx)
        , role "option"
        , classes st.style.item
        , aria "labelledby" itemId
        , aria "selected" (if isSelected then "true" else "false")
        , dataState (if isSelected then "checked" else "unchecked")
        , dataAttr "radix-collection-item" ""
        , HP.tabIndex (-1)
        , HE.onClick \_ -> ItemChosen item.value
        ]
          <> (if st.focused == idx then [ dataAttr "highlighted" "" ] else [])
          <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
      )
      ( (if isSelected then [ HH.span [ classes st.style.indicator, aria "hidden" "true" ] (map HH.fromPlainHTML st.checkIcon) ] else [])
          <> [ HH.span [ HP.id itemId ] (map HH.fromPlainHTML item.label) ]
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  -- mint ids in the order the golden canonicalizes them: contentId (<id0>), labelId (<id1>),
  -- then one per item in order (<id2>, <id3>, …).
  Initialize -> do
    st <- H.get
    cid <- useId
    lid <- useId
    iids <- traverse (const useId) st.items
    H.modify_ _ { contentId = cid, labelId = lid, itemIds = iids }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , sel = sync input.value st.sel
      , items = input.items
      , offset = input.offset
      , padding = input.padding
      , idPrefix = input.idPrefix
      , style = input.style
      , trigger = input.trigger
      , groupLabel = input.groupLabel
      , checkIcon = input.checkIcon
      , placeholder = input.placeholder
      , contentStyle = input.contentStyle
      , portalAttrs = input.portalAttrs
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closeMenu else openMenu
  -- APG listbox/combobox: Space/Enter/ArrowUp/ArrowDown on the focused trigger OPEN the
  -- listbox (upstream select.tsx:31 OPEN_KEYS, :380-389 handleOpen + preventDefault). On
  -- open radix focuses the SELECTED option (openMenu sets focused=selectedIndex). Without
  -- this a keyboard-only user could not open the select at all.
  TriggerKeyDown ke -> do
    st <- H.get
    let key = KE.key ke
    when ((key == " " || key == "Enter" || key == "ArrowUp" || key == "ArrowDown")
      && not (current st.ctrl)) do
      liftEffect (preventDefault (KE.toEvent ke))
      openMenu
  -- after the open render flushed (refs live): item-align, then SYNCHRONOUSLY adopt the
  -- wrapper into body, layer the modal envelope, and focus the content.
  AfterOpen -> do
    reposition
    finalize
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
    case KE.key ke of
      -- APG listbox: Enter/Space commits the highlighted option, closes, and restores
      -- focus to the trigger (via closeMenu's restoreEl). preventDefault so the synthesized
      -- activation does NOT click-through to the (now refocused) trigger and re-open.
      "Enter" -> liftEffect (preventDefault (KE.toEvent ke)) *> commitFocused
      " " -> liftEffect (preventDefault (KE.toEvent ke)) *> commitFocused
      _ -> case navigate cfg pos (KE.key ke) of
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
  -- scroll/resize: just re-place. Item-aligned has no side/align to stamp, so no modify is
  -- needed (and a modify would re-render and re-parent the portaled wrapper out of body).
  Reposition -> reposition

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    let start = selectedIndex st
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the wrapper).
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

-- | Dispatch `AfterOpen` on the next MICROTASK (after the open render flushes) — a microtask,
-- | not a frame, so the content is focused before any keypress lands on the stale focus.
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | Adopt the WRAPPER into body; layer the MODAL select envelope (scroll-lock + focus guards
-- | + aria-hide siblings) and focus the SELECTED option (upstream focusSelectedItem,
-- | select.tsx:683-714 `focusFirst([selectedItem, content])`) — falling back to the listbox
-- | CONTENT when nothing is selected. SYNCHRONOUS (not an afterFrame): the item-aligned
-- | reposition does not modify, so there's no pending re-render to re-parent the wrapper, and
-- | the target can be focused in this same frame.
finalize :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finalize = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  mcontent <- H.getHTMLElementRef contentRef
  -- the selected option's element (Nothing when nothing is selected → focus the content).
  -- selectedIndex falls back to 0, so only resolve the option when a value actually matches.
  let hasSelection = isJust (findIndex (\item -> item.value == current st.sel) st.items)
  mselected <- if hasSelection then H.getHTMLElementRef (itemRef st.idPrefix (selectedIndex st)) else pure Nothing
  case mbody, mwrap of
    Just body, Just wrap -> liftEffect do
      Portal.adopt body (HTMLElement.toElement wrap)
      Envelope.lockScroll
      Envelope.addFocusGuards
      Envelope.hideOthers wrap
      case mselected of
        Just sel -> HTMLElement.focus sel
        Nothing -> for_ mcontent HTMLElement.focus
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
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing }
    H.raise (OpenChanged false)

focusItem :: forall m. MonadEffect m => String -> Int -> H.HalogenM State Action () Output m Unit
focusItem pfx idx = do
  mel <- H.getHTMLElementRef (itemRef pfx idx)
  for_ mel (liftEffect <<< HTMLElement.focus)

-- | Commit the currently-highlighted option (the roving `focused` index): set the value,
-- | raise ValueChanged, and close (restoring focus to the trigger). The keyboard analogue
-- | of clicking an option. A no-op for a disabled item.
commitFocused :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
commitFocused = do
  st <- H.get
  case index st.items st.focused of
    Just item | not item.disabled -> do
      let res = change item.value st.sel
      H.modify_ _ { sel = res.next }
      H.raise (ValueChanged res.emit)
      closeMenu
    _ -> pure unit

-- | Item-aligned positioning (radix Select's default): the listbox overlays the trigger with
-- | the SELECTED option aligned to it. `positionItemAligned` sets the whole WRAPPER style;
-- | we pass it the trigger, wrapper, content, and the selected item's element.
reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  mtrigger <- H.getHTMLElementRef triggerRef
  mwrapper <- H.getHTMLElementRef wrapperRef
  mcontent <- H.getHTMLElementRef contentRef
  msel <- H.getHTMLElementRef (itemRef st.idPrefix (selectedIndex st))
  case mtrigger, mwrapper, mcontent, msel of
    Just trigger, Just wrapper, Just content, Just selectedItem ->
      liftEffect (Popper.positionItemAligned { trigger, wrapper, content, selectedItem, padding: st.padding })
    _, _, _, _ -> pure unit

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
