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
-- | by click or by arrow-key navigation. Default orientation is `Vertical`. The item
-- | ids combine the readable `idPrefix` with a per-mount generated id (Behavior.Id),
-- | so two default-prefixed groups on a page don't collide.
-- |
-- | DOM-fidelity knobs (so the themed RadioCards usage is byte-identical to upstream):
-- |
-- |   * `explicitOrientation` — upstream radix RadioGroup.Root only emits
-- |     `aria-orientation`/`data-orientation` when an explicit `orientation` prop is
-- |     passed; RadioCards passes none, so both are omitted by default (set true to
-- |     emit them). Likewise the item button omits `data-orientation` unless explicit.
-- |   * `aria-required` is ALWAYS rendered (true|false), matching the primitive's
-- |     `aria-required={required}`.
-- |   * `dir` is always rendered (ltr|rtl) from `useDirection`.
-- |   * `rootStyle` — an inline style string merged onto the single root div (the
-- |     themed `Grid asChild` `--grid-template-columns` custom property).
-- |   * `itemIds` — when false the per-item `id` is suppressed (RadioCards.Item
-- |     buttons carry no id upstream).
-- |   * the selected-item indicator `<span>` is rendered ONLY when the indicator
-- |     ClassNames are non-empty; RadioCards passes an empty indicator (selection is
-- |     the `[data-state=checked]` outline) so no span is emitted.
-- |   * each item button always carries its `value` attribute (RadioTrigger forwards
-- |     `value={value}` to the primitive button).
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

import Data.Array (findIndex, length, mapWithIndex, null, (!!))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..), dirName)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, orientationName, role, aria, unClassNames)
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
  -- | When false (default) the `aria-orientation`/`data-orientation` attrs are
  -- | OMITTED on the root and items — upstream only emits them when an explicit
  -- | `orientation` prop is passed (RadioCards passes none).
  , explicitOrientation :: Boolean
  -- | An inline style string applied verbatim to the root div (e.g. the themed
  -- | RadioCards Grid `--grid-template-columns: …`). Empty → no style attr.
  , rootStyle :: String
  -- | When false the per-item `id` is suppressed (RadioCards.Item has no id).
  , itemIds :: Boolean
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
  , explicitOrientation: false
  , rootStyle: ""
  , itemIds: true
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
  , explicitOrientation :: Boolean
  , rootStyle :: String
  , itemIds :: Boolean
  , uid :: String       -- generated on Initialize; makes ids unique per instance
  }

data Action
  = Initialize
  | Receive Input
  | Selected String
  | ListKeyDown KE.KeyboardEvent
  | EntryFocus

-- | The effective, per-instance unique id base: readable prefix + the id minted on
-- | Initialize (so two default-prefixed RadioGroups on a page never collide).
base :: State -> String
base st = if st.uid == "" then st.idPrefix else st.idPrefix <> "-" <> st.uid

-- | The ref label for an item button. COMPONENT-INTERNAL (Halogen scopes refs per
-- | component instance) and never serialized to the DOM, so it does NOT need the
-- | per-mount `uid` — and MUST NOT use it: a ref label that changes after mount (uid is
-- | minted on Initialize, after the first render) leaves `getHTMLElementRef` unable to
-- | resolve the element. Key off the stable item value alone.
itemRef :: String -> H.RefLabel
itemRef value = H.RefLabel ("item-" <> value)

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
  { items: input.items
  , ctrl: controllable input.value (initialValue input)
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , required: input.required
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  , explicitOrientation: input.explicitOrientation
  , rootStyle: input.rootStyle
  , itemIds: input.itemIds
  , uid: ""
  }

-- | The uncontrolled starting value: the `defaultValue` if given, else `""`
-- | (the no-selection sentinel — radios may start with nothing checked).
initialValue :: Input -> String
initialValue input = fromMaybe "" input.defaultValue

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( [ role "radiogroup"
      , aria "required" (if st.required then "true" else "false")
      , HP.attr (HH.AttrName "dir") (dirName st.dir)
      -- RovingFocusGroup.Root is asChild-merged onto the radiogroup div: it carries the
      -- roving `tabindex="0"` (focusable items present, not tabbing out) and
      -- `style="outline: none;"`. Any caller `rootStyle` (e.g. the Grid custom property
      -- for RadioCards) is appended after, matching upstream's style merge order.
      , HP.attr (HH.AttrName "tabindex") "0"
      , HP.attr (HH.AttrName "style") (if st.rootStyle == "" then "outline: none;" else "outline: none; " <> st.rootStyle)
      , classes st.style.root
      , HE.onKeyDown ListKeyDown
      -- Tab-into-group: the container (the roving tabindex=0 element) receives focus;
      -- forward it to the current roving item. `focus` does not bubble, so a child
      -- item receiving focus never re-triggers this — no re-entry loop.
      , HE.onFocus (const EntryFocus)
      ]
        -- orientation attrs only when an explicit orientation was passed (upstream
        -- omits aria-orientation/data-orientation otherwise, e.g. RadioCards).
        <>
          ( if st.explicitOrientation then
              [ aria "orientation" (orientationName st.orientation), dataOrientation st.orientation ]
            else []
          )
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
    showIndicator = not (null (unClassNames st.style.indicator))
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef item.value)
        , role "radio"
        , aria "checked" (if selected then "true" else "false")
        , dataState (if selected then "checked" else "unchecked")
        -- Collection.ItemSlot (inside RovingFocusGroup.Item) stamps each radio button.
        , dataAttr "radix-collection-item" ""
        , HP.attr (HH.AttrName "value") item.value
        , HP.tabIndex (tabIndexFor curIdx idx)
        , HP.disabled itemDisabled
        , classes st.style.item
        , HE.onClick \_ -> Selected item.value
        ]
          <> (if st.itemIds then [ HP.id (itemId st item.value) ] else [])
          <> (if st.explicitOrientation then [ dataOrientation st.orientation ] else [])
          <> (if itemDisabled then [ dataAttr "disabled" "" ] else [])
      )
      ( map HH.fromPlainHTML item.label
          <>
            ( if selected && showIndicator then
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
itemId st value = base st <> "-item-" <> value

-- | The index of the roving tab stop: the selected item's index, or 0 when
-- | nothing is selected (the first item is the keyboard entry point).
selectedIndex :: State -> Int
selectedIndex st = fromMaybe 0 (findIndex (\i -> i.value == current st.ctrl) st.items)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    uid <- useId
    H.modify_ _ { uid = uid }
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
      , explicitOrientation = input.explicitOrientation
      , rootStyle = input.rootStyle
      , itemIds = input.itemIds
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
          focusItemAt idx
          selectValue item.value
  -- Tab-into-group: forward container focus to the current roving item (the selected
  -- radio, or item 0 when nothing is selected).
  EntryFocus -> do
    st <- H.get
    focusItemAt (selectedIndex st)

-- | Focus the item at the given index via its existing ref (the same mechanism
-- | ListKeyDown uses). No-op when the index is out of range.
focusItemAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusItemAt idx = do
  st <- H.get
  case st.items !! idx of
    Nothing -> pure unit
    Just item -> do
      mel <- H.getHTMLElementRef (itemRef item.value)
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
