-- | Hydrogen.Radix.Tabs — tabbed interface (radix `Tabs`).
-- |
-- | THE TEMPLATE for a RovingFocus-consumer. It shows the idiom the menu/radio/
-- | toolbar family follows:
-- |   * items are DATA in `Input` (`tabs :: Array Tab`) — no Collection needed;
-- |   * selection is `ControllableState String` (the active value);
-- |   * the roving tab stop is the selected item's index; each trigger gets
-- |     `tabIndexFor`, a `HP.ref` (so we can focus it), and arrow-key handling via
-- |     `RovingFocus.navigate` (pure) → focus the target's ref + (automatic mode)
-- |     select it;
-- |   * the stable surface: role=tablist/tab/tabpanel, aria-selected/controls/
-- |     labelledby/orientation, data-state active/inactive, data-orientation.
-- |
-- | v1 scope (by feel): automatic activation (arrow moves selection); `manual`
-- | mode (arrow moves focus only, Enter/Space selects) is noted, not built. The
-- | tab/panel ids combine the readable `idPrefix` with a per-mount generated id
-- | (Behavior.Id), so two default-prefixed Tabs on a page don't collide.
module Hydrogen.Radix.Tabs
  ( component
  , Tab
  , Input
  , ActivationMode(..)
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (filter, findIndex, length, mapWithIndex, (!!))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, orientationName, role, aria)
import Web.HTML.HTMLElement as HTMLElement
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Tab =
  { value :: String
  , label :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { root :: ClassNames
  , list :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-tabs-root"
  , list: cn "rdx-tabs-list"
  , trigger: cn "rdx-tabs-trigger"
  , content: cn "rdx-tabs-content"
  }

-- | Activation mode (radix `activationMode`). `Automatic` (default): arrow keys move
-- | focus AND select the focused tab. `Manual`: arrow keys move focus only; Enter/Space
-- | on the focused trigger activates it. (tabs.tsx:61,73,192-202.)
data ActivationMode = Automatic | Manual

derive instance eqActivationMode :: Eq ActivationMode

type Input =
  { tabs :: Array Tab
  , value :: Maybe String          -- controlled active value
  , defaultValue :: Maybe String   -- uncontrolled initial (else first tab)
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , activationMode :: ActivationMode
  , idPrefix :: String             -- for tab/panel ids (unique per instance)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { tabs: []
  , value: Nothing
  , defaultValue: Nothing
  , orientation: Horizontal
  , dir: LTR
  , loop: true
  , activationMode: Automatic
  , idPrefix: "rdx-tabs"
  , style: defaultStyle
  }

data Output = ValueChanged String

data Query a
  = SetValue String a
  | GetValue (String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { tabs :: Array Tab
  , ctrl :: Controllable String
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , activationMode :: ActivationMode
  , idPrefix :: String
  , style :: Style
  , uid :: String       -- generated on Initialize; makes ids unique per instance
  , initialValue :: String  -- the originally-selected value (mount-animation-prevented panel)
  , focusEntered :: Boolean -- false until focus/interaction enters: pre-entry NO trigger is the
                            -- roving tab stop (all tabindex=-1) and the mount-selected panel keeps
                            -- `animation-duration: 0s` (upstream RovingFocus null tabstop +
                            -- isMountAnimationPrevented, both resolved on the first render after entry)
  }

data Action
  = Initialize
  | Receive Input
  | Selected String
  | TriggerMouseDown String ME.MouseEvent
  | ListKeyDown KE.KeyboardEvent
  | TriggerKeyDown String KE.KeyboardEvent
  | EntryFocus

-- | The effective, per-instance unique id base: the readable prefix + the id minted
-- | on Initialize (so two default-prefixed Tabs on a page never collide).
base :: State -> String
base st
  | st.uid == "" = st.idPrefix
  | st.idPrefix == "" = st.uid
  | otherwise = st.idPrefix <> "-" <> st.uid

-- | The ref label for a trigger. This is COMPONENT-INTERNAL (Halogen scopes refs per
-- | component instance) and is never serialized to the DOM, so it does NOT need the
-- | per-mount `uid` for cross-instance uniqueness — and MUST NOT use it: a ref label
-- | that changes after mount (uid is minted on Initialize, after the first render)
-- | leaves `getHTMLElementRef` unable to resolve the element. Key off the stable
-- | tab value alone.
tabRef :: String -> H.RefLabel
tabRef value = H.RefLabel ("tab-" <> value)

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
  { tabs: input.tabs
  , ctrl: controllable input.value (firstValue input)
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , activationMode: input.activationMode
  , idPrefix: input.idPrefix
  , style: input.style
  , uid: ""
  , initialValue: firstValue input
  , focusEntered: false
  }

-- | The initial active value. Upstream is `value ?? defaultValue ?? ''` (tabs.tsx:80) — a
-- | controlled `value` wins, else the uncontrolled `defaultValue`, else the EMPTY string
-- | (zero-selected: no tab aria-selected, no panel visible). We do NOT fall back to tabs[0]:
-- | that would force a selection upstream never makes when no default is given.
firstValue :: Input -> String
firstValue input = case input.value of
  Just v -> v
  Nothing -> fromMaybe "" input.defaultValue

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    [ classes st.style.root
    , dataOrientation st.orientation
    , HP.attr (HH.AttrName "dir") (dirName st.dir)
    ]
    ( [ HH.div
          [ classes st.style.list
          , aria "orientation" (orientationName st.orientation)
          , dataOrientation st.orientation
          , role "tablist"
          -- RovingFocusGroup gives the tablist outline:none + a roving tabstop of its own.
          , HP.attr (HH.AttrName "style") "outline: none;"
          , HP.tabIndex 0
          , HE.onKeyDown ListKeyDown
          -- Tab-into-tablist: the container (the roving tabindex=0 element) receives
          -- focus; forward it to the active trigger. `focus` does not bubble, so a
          -- child trigger receiving focus never re-triggers this — no re-entry loop.
          , HE.onFocus (const EntryFocus)
          ]
          (mapWithIndex (renderTrigger st) st.tabs)
      ]
        -- Panels are direct children of the root (no wrapper div); every panel renders,
        -- non-selected ones carrying `hidden` (matching the committed oracle).
        <> map (renderPanel st) st.tabs
    )

dirName :: Dir -> String
dirName = case _ of
  LTR -> "ltr"
  RTL -> "rtl"

renderTrigger :: forall m. State -> Int -> Tab -> H.ComponentHTML Action () m
renderTrigger st _ tab =
  let
    selected = current st.ctrl == tab.value
    curIdx = selectedIndex st
    idx = fromMaybe 0 (findIndex (\t -> t.value == tab.value) st.tabs)
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (tabRef tab.value)
        , HP.id (triggerId st tab.value)
        , role "tab"
        , aria "selected" (if selected then "true" else "false")
        , aria "controls" (panelId st tab.value)
        , dataAttr "radix-collection-item" ""
        , dataState (if selected then "active" else "inactive")
        , dataOrientation st.orientation
        -- Pre-entry the RovingFocusGroup tab stop is null → EVERY trigger is tabindex=-1; once
        -- focus/interaction enters, the selected trigger becomes the single tab stop.
        , HP.tabIndex (if st.focusEntered then tabIndexFor curIdx idx else (-1))
        , HP.disabled tab.disabled
        , classes st.style.trigger
        , HE.onClick \_ -> Selected tab.value
        -- Activation fires on pointer-DOWN (left button, no ctrl), not waiting for mouseup
        -- (tabs.tsx onMouseDown). onClick stays as a redundant idempotent backstop.
        , HE.onMouseDown (TriggerMouseDown tab.value)
        -- Per-trigger Enter/Space activation (tabs.tsx:192-202). In manual mode this is the
        -- ONLY way to select; in automatic mode it is redundant with arrow-select but matches
        -- upstream, which always wires the trigger keydown regardless of activationMode.
        , HE.onKeyDown (TriggerKeyDown tab.value)
        ]
          <> (if tab.disabled then [ dataAttr "disabled" "" ] else [])
      )
      (map HH.fromPlainHTML tab.label)

-- | Every panel renders. The selected one is `data-state=active` and carries its
-- | content; non-selected panels are `data-state=inactive hidden` with no children.
-- | The originally-selected panel additionally carries an (empty) `style` attribute —
-- | upstream's mount-animation-prevention (`isMountAnimationPreventedRef`) stamps an
-- | inline `animation-duration` only on the panel that was selected at mount.
renderPanel :: forall m. State -> Tab -> H.ComponentHTML Action () m
renderPanel st tab =
  let
    selected = current st.ctrl == tab.value
    isInitial = tab.value == st.initialValue
  in
    HH.div
      ( [ HP.id (panelId st tab.value)
        , role "tabpanel"
        , aria "labelledby" (triggerId st tab.value)
        , dataState (if selected then "active" else "inactive")
        , dataOrientation st.orientation
        , HP.tabIndex 0
        , classes st.style.content
        ]
          <> (if selected then [] else [ HP.attr (HH.AttrName "hidden") "" ])
          -- mount-animation-prevention: the panel selected AT MOUNT carries
          -- `animation-duration: 0s` until the first render after focus/interaction enters, then a
          -- bare `style=`. Non-mount-selected panels carry no style attr. (upstream
          -- isMountAnimationPreventedRef, cleared by rAF → reflected on the next render.)
          <> (if isInitial then [ HP.attr (HH.AttrName "style") (if st.focusEntered then "" else "animation-duration: 0s;") ] else [])
      )
      (if selected then map HH.fromPlainHTML tab.content else [])

triggerId :: State -> String -> String
triggerId st value = base st <> "-trigger-" <> value

panelId :: State -> String -> String
panelId st value = base st <> "-content-" <> value

-- | The index of the selected tab, or -1 when the active value matches NO tab (the
-- | zero-selected state, upstream `value ?? defaultValue ?? ''`). -1 makes `tabIndexFor`
-- | stamp tabindex=-1 on EVERY trigger (no roving tab stop), matching upstream's null
-- | currentTabStopId before any focus.
selectedIndex :: State -> Int
selectedIndex st = fromMaybe (-1) (findIndex (\t -> t.value == current st.ctrl) st.tabs)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    uid <- useId
    H.modify_ _ { uid = uid }
  Receive input ->
    H.modify_ \st -> st
      { tabs = input.tabs
      , ctrl = sync input.value st.ctrl
      , orientation = input.orientation
      , dir = input.dir
      , loop = input.loop
      , activationMode = input.activationMode
      , idPrefix = input.idPrefix
      , style = input.style
      }
  Selected value -> do
    H.modify_ _ { focusEntered = true }
    selectValue value
  -- Activate on left-button pointer-down with no ctrl (tabs.tsx onMouseDown); other buttons /
  -- ctrl+click do not select (the contextmenu/modifier path).
  TriggerMouseDown value me -> do
    H.modify_ _ { focusEntered = true }
    when (ME.button me == 0 && not (ME.ctrlKey me)) (selectValue value)
  ListKeyDown ke -> do
    H.modify_ _ { focusEntered = true }
    st <- H.get
    -- upstream RovingFocusGroup.Item focusable={!disabled} (tabs.tsx:168-169) → arrows
    -- navigate WITHIN the enabled subset and SKIP disabled tabs entirely (rather than
    -- stalling on a disabled neighbour). Build the enabled subset, find the selected tab's
    -- index within it, navigate there, focus + (automatic activation) select the result.
    let
      enabled = filter (not <<< _.disabled) st.tabs
      curEnabled = fromMaybe 0 (findIndex (\t -> t.value == current st.ctrl) enabled)
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length enabled, current: curEnabled }
    when (length enabled > 0) $ case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case enabled !! idx of
        Nothing -> pure unit
        Just tab -> do
          -- focus the target trigger; in AUTOMATIC mode also select it. In MANUAL mode
          -- (tabs.tsx:192-202) the arrow only moves focus — selection waits for Enter/Space.
          focusTabByValue tab.value
          when (st.activationMode == Automatic) (selectValue tab.value)
  -- Enter/Space on a focused trigger activates it regardless of activationMode (tabs.tsx:192).
  TriggerKeyDown value ke -> do
    H.modify_ _ { focusEntered = true }
    when (KE.key ke == "Enter" || KE.key ke == " ") (selectValue value)
  -- Tab-into-tablist: forward container focus to the active trigger. When nothing is
  -- selected (selectedIndex = -1, the zero-selected state) upstream focuses the FIRST
  -- focusable tab instead, so fall back to index 0.
  EntryFocus -> do
    H.modify_ _ { focusEntered = true }
    st <- H.get
    let idx = selectedIndex st
    focusTabAt (if idx < 0 then 0 else idx)

-- | Focus the trigger at the given index via its existing ref (the same mechanism
-- | ListKeyDown uses). No-op when the index is out of range.
focusTabAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusTabAt idx = do
  st <- H.get
  case st.tabs !! idx of
    Nothing -> pure unit
    Just tab -> focusTabByValue tab.value

-- | Focus the trigger with the given value via its ref (enabled-subset indices differ
-- | from full-list indices, so navigation focuses by value, not raw index).
focusTabByValue :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
focusTabByValue value = do
  mel <- H.getHTMLElementRef (tabRef value)
  for_ mel (liftEffect <<< HTMLElement.focus)

selectValue :: forall m. String -> H.HalogenM State Action () Output m Unit
selectValue value = do
  st <- H.get
  when (current st.ctrl /= value) do
    H.modify_ _ { ctrl = (change value st.ctrl).next }
    H.raise (ValueChanged value)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    selectValue v
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
