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
-- | v1 (by feel): non-modal, no Presence, no portal, single instance (fixed ids),
-- | no typeahead. The trigger renders `input.trigger` (Array PlainHTML) as-is
-- | followed by the current selected value as text — a deliberate simplification
-- | (radix resolves the selected item's `label`; here it is the raw value string,
-- | or nothing when unselected). Those are noted follow-ups.
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

import Data.Array (findIndex, length, mapWithIndex)
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..), fromMaybe)
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
  , content :: ClassNames
  , item :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-select-trigger"
  , content: cn "rdx-select-content"
  , item: cn "rdx-select-item"
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
  , trigger :: Array HH.PlainHTML
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
  , subs :: Array H.SubscriptionId
  , contentNode :: Maybe Node
  }

data Action
  = Receive Input
  | TriggerClicked
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
  , subs: []
  , contentNode: Nothing
  }

-- | The index of the currently selected item, or 0 when nothing matches.
selectedIndex :: State -> Int
selectedIndex st =
  fromMaybe 0 (findIndex (\item -> item.value == current st.sel) st.items)

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
            , aria "haspopup" "listbox"
            , aria "expanded" (if open then "true" else "false")
            , dataState (if open then "open" else "closed")
            , HE.onClick \_ -> TriggerClicked
            ]
              <> (if selected == "" then [ dataAttr "placeholder" "" ] else [])
          )
          -- v1: render the static trigger content, then the selected value as text.
          (map HH.fromPlainHTML st.trigger <> [ HH.text selected ])
      , if open then
          HH.div
            [ HP.ref contentRef
            , role "listbox"
            , classes st.style.content
            , dataState "open"
            , dataAttr "side" (sideName st.placedSide)
            , dataAttr "align" (alignName st.placedAlign)
            , HP.tabIndex (-1)
            , HP.style "position:fixed;left:0;top:0;"
            , HE.onKeyDown ListKeyDown
            ]
            (mapWithIndex (renderItem st) st.items)
        else HH.text ""
      ]

renderItem :: forall m. State -> Int -> SelectItem -> H.ComponentHTML Action () m
renderItem st idx item =
  let
    isSelected = item.value == current st.sel
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef st.idPrefix idx)
        , role "option"
        , classes st.style.item
        , aria "selected" (if isSelected then "true" else "false")
        , dataState (if isSelected then "checked" else "unchecked")
        , HP.tabIndex (tabIndexFor st.focused idx)
        , HP.disabled item.disabled
        , HE.onClick \_ -> ItemChosen item.value
        ]
          <> (if item.disabled then [ dataAttr "disabled" "" ] else [])
      )
      (map HH.fromPlainHTML item.label)

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
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closeMenu else openMenu
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
  Reposition -> reposition

openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = do
  st <- H.get
  when (not (current st.ctrl)) do
    let start = selectedIndex st
    H.modify_ _ { ctrl = (change true st.ctrl).next, focused = start }
    H.raise (OpenChanged true)
    reposition
    focusItem st.idPrefix start
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
  SetValue v a -> do
    st <- H.get
    let res = change v st.sel
    H.modify_ _ { sel = res.next }
    H.raise (ValueChanged res.emit)
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.sel)))
