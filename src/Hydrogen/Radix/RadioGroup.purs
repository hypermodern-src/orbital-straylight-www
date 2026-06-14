-- | Hydrogen.Radix.RadioGroup — single-select radio group (radix `RadioGroup`).
-- |
-- | Structurally this IS `Tabs` (a RovingFocus-consumer): items are DATA in
-- | `Input` (`items :: Array Item`), selection is `ControllableState String`, the
-- | roving tab stop is the selected item's index, and arrow keys navigate via
-- | `RovingFocus.navigate` (pure) → focus the target's ref + (automatic
-- | activation) select it. It differs from Tabs in three ways:
-- |
-- |   * no panels — a radio group is just the group of buttons (an optional
-- |     `indicator` span renders inside the selected item);
-- |   * radio ARIA — role=radiogroup/radio, aria-checked, aria-required,
-- |     aria-orientation; data-state checked/unchecked, data-disabled;
-- |   * a radio group may start with NOTHING selected. We use `""` as the
-- |     no-selection sentinel: `current st.ctrl == ""` means nothing is checked,
-- |     and the roving tab stop falls back to index 0 (the first item is the
-- |     keyboard entry point, per WAI-ARIA). `""` is therefore reserved and must
-- |     not be used as a real item value.
-- |
-- | Like radix, Enter does NOT activate (WAI-ARIA radio semantics); selection is
-- | by click or by arrow-key navigation. Default orientation is `Vertical`.
-- | Single instance per page for the fixed id prefix (note in Input).
module Hydrogen.Radix.RadioGroup
  ( component
  , Item
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
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, orientationName, role, aria)
import Web.HTML.HTMLElement as HTMLElement
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Item =
  { value :: String
  , label :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { root :: ClassNames
  , item :: ClassNames
  , indicator :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-radio-group"
  , item: cn "rdx-radio-group-item"
  , indicator: cn "rdx-radio-group-indicator"
  }

type Input =
  { items :: Array Item
  , value :: Maybe String          -- controlled selected value
  , defaultValue :: Maybe String   -- uncontrolled initial (else nothing selected)
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , required :: Boolean            -- aria-required on the group
  , disabled :: Boolean            -- disables the whole group
  , idPrefix :: String             -- for item ids (unique per instance)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { items: []
  , value: Nothing
  , defaultValue: Nothing
  , orientation: Vertical
  , dir: LTR
  , loop: true
  , required: false
  , disabled: false
  , idPrefix: "rdx-radio-group"
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
  { items :: Array Item
  , ctrl :: Controllable String
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , required :: Boolean
  , disabled :: Boolean
  , idPrefix :: String
  , style :: Style
  }

data Action
  = Receive Input
  | Selected String
  | ListKeyDown KE.KeyboardEvent

itemRef :: String -> String -> H.RefLabel
itemRef pfx value = H.RefLabel (pfx <> "-item-" <> value)

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
  { items: input.items
  , ctrl: controllable input.value (initialValue input)
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , required: input.required
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  }

-- | The uncontrolled starting value: the `defaultValue` if given, else `""`
-- | (the no-selection sentinel — radios may start with nothing checked).
initialValue :: Input -> String
initialValue input = fromMaybe "" input.defaultValue

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( [ role "radiogroup"
      , aria "orientation" (orientationName st.orientation)
      , dataOrientation st.orientation
      , classes st.style.root
      , HE.onKeyDown ListKeyDown
      ]
        <> (if st.required then [ aria "required" "true" ] else [])
        <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
    )
    (mapWithIndex (renderItem st) st.items)

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st _ item =
  let
    selected = current st.ctrl == item.value
    curIdx = selectedIndex st
    idx = fromMaybe 0 (findIndex (\i -> i.value == item.value) st.items)
    itemDisabled = item.disabled || st.disabled
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef st.idPrefix item.value)
        , HP.id (itemId st item.value)
        , role "radio"
        , aria "checked" (if selected then "true" else "false")
        , dataState (if selected then "checked" else "unchecked")
        , dataOrientation st.orientation
        , HP.tabIndex (tabIndexFor curIdx idx)
        , HP.disabled itemDisabled
        , classes st.style.item
        , HE.onClick \_ -> Selected item.value
        ]
          <> (if itemDisabled then [ dataAttr "disabled" "" ] else [])
      )
      ( map HH.fromPlainHTML item.label
          <>
            ( if selected then
                [ HH.span
                    [ dataState "checked"
                    , classes st.style.indicator
                    ]
                    []
                ]
              else []
            )
      )

itemId :: State -> String -> String
itemId st value = st.idPrefix <> "-item-" <> value

-- | The index of the roving tab stop: the selected item's index, or 0 when
-- | nothing is selected (the first item is the keyboard entry point).
selectedIndex :: State -> Int
selectedIndex st = fromMaybe 0 (findIndex (\i -> i.value == current st.ctrl) st.items)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , ctrl = sync input.value st.ctrl
      , orientation = input.orientation
      , dir = input.dir
      , loop = input.loop
      , required = input.required
      , disabled = input.disabled
      , idPrefix = input.idPrefix
      , style = input.style
      }
  Selected value -> selectValue value
  ListKeyDown ke -> do
    st <- H.get
    let
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length st.items, current: selectedIndex st }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case st.items !! idx of
        Nothing -> pure unit
        Just item -> when (not (item.disabled || st.disabled)) do
          -- focus the target item, then (automatic activation) select it
          mel <- H.getHTMLElementRef (itemRef st.idPrefix item.value)
          for_ mel (liftEffect <<< HTMLElement.focus)
          selectValue item.value

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
