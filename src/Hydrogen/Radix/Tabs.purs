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
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (findIndex, length, mapWithIndex, (!!))
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

type Input =
  { tabs :: Array Tab
  , value :: Maybe String          -- controlled active value
  , defaultValue :: Maybe String   -- uncontrolled initial (else first tab)
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
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
  , idPrefix :: String
  , style :: Style
  , uid :: String       -- generated on Initialize; makes ids unique per instance
  , initialValue :: String  -- the originally-selected value (mount-animation-prevented panel)
  }

data Action
  = Initialize
  | Receive Input
  | Selected String
  | ListKeyDown KE.KeyboardEvent

-- | The effective, per-instance unique id base: the readable prefix + the id minted
-- | on Initialize (so two default-prefixed Tabs on a page never collide).
base :: State -> String
base st
  | st.uid == "" = st.idPrefix
  | st.idPrefix == "" = st.uid
  | otherwise = st.idPrefix <> "-" <> st.uid

tabRef :: String -> String -> H.RefLabel
tabRef pfx value = H.RefLabel (pfx <> "-tab-" <> value)

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
  , idPrefix: input.idPrefix
  , style: input.style
  , uid: ""
  , initialValue: firstValue input
  }

firstValue :: Input -> String
firstValue input = case input.defaultValue of
  Just v -> v
  Nothing -> case input.tabs !! 0 of
    Just t -> t.value
    Nothing -> ""

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
        , HP.ref (tabRef (base st) tab.value)
        , HP.id (triggerId st tab.value)
        , role "tab"
        , aria "selected" (if selected then "true" else "false")
        , aria "controls" (panelId st tab.value)
        , dataAttr "radix-collection-item" ""
        , dataState (if selected then "active" else "inactive")
        , dataOrientation st.orientation
        , HP.tabIndex (tabIndexFor curIdx idx)
        , HP.disabled tab.disabled
        , classes st.style.trigger
        , HE.onClick \_ -> Selected tab.value
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
          <> (if isInitial then [ HP.attr (HH.AttrName "style") "" ] else [])
      )
      (if selected then map HH.fromPlainHTML tab.content else [])

triggerId :: State -> String -> String
triggerId st value = base st <> "-trigger-" <> value

panelId :: State -> String -> String
panelId st value = base st <> "-content-" <> value

selectedIndex :: State -> Int
selectedIndex st = fromMaybe 0 (findIndex (\t -> t.value == current st.ctrl) st.tabs)

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
      , idPrefix = input.idPrefix
      , style = input.style
      }
  Selected value -> selectValue value
  ListKeyDown ke -> do
    st <- H.get
    let
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length st.tabs, current: selectedIndex st }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case st.tabs !! idx of
        Nothing -> pure unit
        Just tab -> when (not tab.disabled) do
          -- focus the target trigger, then (automatic activation) select it
          mel <- H.getHTMLElementRef (tabRef (base st) tab.value)
          for_ mel (liftEffect <<< HTMLElement.focus)
          selectValue tab.value

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
