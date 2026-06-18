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

import Data.Array (any, findIndex, mapWithIndex, null, (!!))
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
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigateMask)
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
  -- | Optional inner wrapper around ALL items, rendered as a single `<div>` child of
  -- | the root (e.g. the themed RadioGroup's `rt-Flex rt-r-fd-column rt-r-gap-2`
  -- | column). Empty (default) → no wrapper, items are direct children of the root
  -- | (the RadioCards grid layout).
  , flex :: ClassNames
  -- | Optional per-item wrapper element: a `<label>` carrying these classes (e.g. the
  -- | themed RadioGroup's `rt-Text rt-r-size-2`). Empty (default) → no `<label>`, the
  -- | button is emitted bare (RadioCards). When non-empty each item becomes
  -- | `<label class=itemLabel> <div class=itemInner> [button, …labelText] </div> </label>`.
  , itemLabel :: ClassNames
  -- | The inner flex inside each item `<label>` wrapper (e.g.
  -- | `rt-Flex rt-r-ai-center rt-r-gap-2`). Only used when `itemLabel` is non-empty.
  , itemInner :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-radio-group"
  , item: cn "rdx-radio-group-item"
  , indicator: cn "rdx-radio-group-indicator"
  , flex: cn ""
  , itemLabel: cn ""
  , itemInner: cn ""
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
  -- | Where each item's `label` renders relative to the radio button. When false
  -- | (default, RadioCards) the label is the button's CHILDREN. When true (the themed
  -- | RadioGroup) the label renders as a SIBLING after the button — inside the
  -- | per-item `itemInner` wrapper — and the button itself is empty.
  , labelOutside :: Boolean
  -- | The form field name shared by every item's hidden bubble input (radix
  -- | `RadioGroupContextValue.name`). Empty (default) → no name attr.
  , name :: String
  -- | Form participation (Wave C). When the group is inside (or SSR-defaults into) a
  -- | `<form>`, each Radio resolves `isFormControl` true and renders a hidden bubble
  -- | `<input type="radio" aria-hidden tabindex=-1>` SIBLING of its trigger (name shared,
  -- | value per item, required mirrored, the CHECKED item's input `checked`). A bare group
  -- | with no `<form>` ancestor resolves false post-mount ⇒ no inputs (the default).
  , isFormControl :: Boolean
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
  , labelOutside: false
  , name: ""
  , isFormControl: false
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
  , labelOutside :: Boolean
  , name :: String
  , isFormControl :: Boolean
  , uid :: String       -- generated on Initialize; makes ids unique per instance
  -- The roving tab stop, radix `currentTabStopId` — the item value that currently
  -- carries tabindex=0. `Nothing` at rest (no item is tabbable; the ROOT is the single
  -- tab stop, tabindex=0), set to the focused/selected item once focus enters the group
  -- (Tab/click/arrow). Matches RovingFocusGroup: items are `currentTabStopId===id ? 0 : -1`
  -- with currentTabStopId starting null.
  , tabStop :: Maybe String
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
  , labelOutside: input.labelOutside
  , name: input.name
  , isFormControl: input.isFormControl
  , uid: ""
  , tabStop: Nothing
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
      -- roving `tabindex` and `style="outline: none;"`. The root is the single tab stop
      -- (tabindex=0) while any item is focusable; when EVERY item is disabled
      -- (focusableItemsCount===0) it drops to -1, matching RovingFocusGroup
      -- (`isTabbingBackOut || focusableItemsCount === 0 ? -1 : 0`). Any caller `rootStyle`
      -- (the Grid custom property for RadioCards) is appended after, matching the merge order.
      , HP.attr (HH.AttrName "tabindex") (if anyFocusable st then "0" else "-1")
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
    -- Optional inner-flex wrapper (themed RadioGroup column); empty `flex` → items are
    -- direct children of the root (RadioCards grid).
    ( if null (unClassNames st.style.flex) then items
      else [ HH.div [ classes st.style.flex ] items ]
    )
  where
  items = mapWithIndex (renderItem st) st.items

-- | The hidden bubble `<input type="radio">` (radix `RadioBubbleInput`) rendered per item
-- | AFTER its trigger so the group submits with the enclosing form + drives native
-- | validation. Absolutely-positioned, 0-opacity, tabindex=-1, aria-hidden; the DOM oracle
-- | normalizes every `…px` to `<px>`, so we emit literal 0px sizes. name shared, value per
-- | item, required mirrored; the SELECTED item's input is `checked`; per-item `disabled`.
radioBubbleInput :: forall m. State -> Item -> Boolean -> Boolean -> H.ComponentHTML Action () m
radioBubbleInput st item selected itemDisabled =
  HH.input
    ( [ HP.type_ HP.InputRadio
      , aria "hidden" "true"
      , HP.tabIndex (-1)
      , HP.name st.name
      , HP.attr (HH.AttrName "value") item.value
      , HP.attr (HH.AttrName "style") "position: absolute; pointer-events: none; opacity: 0; margin: 0px; transform: translateX(-100%); width: 0px; height: 0px;"
      ]
        <> (if selected then [ HP.attr (HH.AttrName "checked") "" ] else [])
        <> (if st.required then [ HP.attr (HH.AttrName "required") "" ] else [])
        <> (if itemDisabled then [ HP.attr (HH.AttrName "disabled") "" ] else [])
    )

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st _ item =
  let
    selected = current st.ctrl == item.value
    itemDisabled = item.disabled || st.disabled
    -- roving tabindex: the item is tabbable (0) only when it is the current tab stop
    -- (radix `currentTabStopId===id ? 0 : -1`). At rest tabStop is Nothing → every item
    -- is -1 and the ROOT carries the single tab stop.
    isTabStop = st.tabStop == Just item.value
    showIndicator = not (null (unClassNames st.style.indicator))
    indicator =
      if selected && showIndicator then
        [ HH.span [ dataState "checked", classes st.style.indicator ] [] ]
      else []
    -- RadioCards: the label is the button's CHILDREN. RadioGroup (`labelOutside`): the
    -- button is empty and the label renders as a sibling inside the inner-flex wrapper.
    buttonChildren = (if st.labelOutside then [] else map HH.fromPlainHTML item.label) <> indicator
    button =
      HH.button
        ( [ HP.type_ HP.ButtonButton
          , HP.ref (itemRef item.value)
          , role "radio"
          , aria "checked" (if selected then "true" else "false")
          , dataState (if selected then "checked" else "unchecked")
          -- Collection.ItemSlot (inside RovingFocusGroup.Item) stamps each radio button.
          , dataAttr "radix-collection-item" ""
          , HP.attr (HH.AttrName "value") item.value
          , HP.tabIndex (if isTabStop then 0 else -1)
          , HP.disabled itemDisabled
          , classes st.style.item
          , HE.onClick \_ -> Selected item.value
          ]
            <> (if st.itemIds then [ HP.id (itemId st item.value) ] else [])
            <> (if st.explicitOrientation then [ dataOrientation st.orientation ] else [])
            <> (if itemDisabled then [ dataAttr "disabled" "" ] else [])
        )
        buttonChildren
    -- The hidden bubble input is a SIBLING rendered immediately AFTER the trigger (radix
    -- renders `<button/>` then `<RadioBubbleInput/>`); empty when not a form control.
    bubble = if st.isFormControl then [ radioBubbleInput st item selected itemDisabled ] else []
  in
    -- No `itemLabel` wrapper → bare button (RadioCards). With a wrapper → the themed
    -- RadioGroup chrome: `<label> <div class=inner> [button, bubble?, …labelText] </div> </label>`.
    if null (unClassNames st.style.itemLabel) then
      -- Bare item: when a form control, button + bubble are siblings, so wrap in a
      -- `display:contents` div the DOM-oracle normalizer strips; else the bare button.
      if st.isFormControl then HH.div [ HP.attr (HH.AttrName "style") "display:contents" ] ([ button ] <> bubble)
      else button
    else
      HH.label [ classes st.style.itemLabel ]
        [ HH.div [ classes st.style.itemInner ]
            ([ button ] <> bubble <> (if st.labelOutside then map HH.fromPlainHTML item.label else []))
        ]

itemId :: State -> String -> String
itemId st value = base st <> "-item-" <> value

-- | The index of the roving tab stop: the selected item's index, or 0 when
-- | nothing is selected (the first item is the keyboard entry point).
selectedIndex :: State -> Int
selectedIndex st = fromMaybe 0 (findIndex (\i -> i.value == current st.ctrl) st.items)

-- | Whether the group has ANY focusable (enabled) item. When false (every item
-- | disabled, or the whole group disabled) the root drops to tabindex=-1.
anyFocusable :: State -> Boolean
anyFocusable st = (not st.disabled) && any (\i -> not i.disabled) st.items

-- | The item value the keyboard ENTRY focus lands on: the selected item, or the first
-- | ENABLED item when nothing is selected (radix entry-focus skips disabled items).
entryValue :: State -> Maybe String
entryValue st =
  let cur = current st.ctrl
  in if cur /= "" then Just cur
     else map _.value (findFirst (\i -> not (i.disabled || st.disabled)) st.items)
  where
  findFirst p xs = case findIndex p xs of
    Just i -> xs !! i
    Nothing -> Nothing

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
      , labelOutside = input.labelOutside
      , name = input.name
      , isFormControl = input.isFormControl
      }
  -- A click both selects the item AND makes it the roving tab stop (it now carries focus).
  Selected value -> do
    H.modify_ _ { tabStop = Just value }
    selectValue value
  ListKeyDown ke -> do
    st <- H.get
    let
      key = KE.key ke
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      -- focusable mask = per-item enabled flag (radix navigates the FOCUSABLE items only,
      -- skipping disabled neighbours; a whole-group disable masks everything out).
      mask = map (\i -> not (i.disabled || st.disabled)) st.items
      pos = { mask, current: selectedIndex st }
      -- selection-follows-focus is gated on a physical ARROW key (upstream
      -- radio-group.tsx:182-225 isArrowKeyPressedRef: onFocus clicks only when an arrow
      -- is held). ARROW_KEYS excludes Home/End, so Home/End MOVE focus but do NOT check.
      isArrow = key == "ArrowUp" || key == "ArrowDown" || key == "ArrowLeft" || key == "ArrowRight"
    case navigateMask cfg pos key of
      Stay -> pure unit
      MoveTo idx -> case st.items !! idx of
        Nothing -> pure unit
        -- the mask already excludes disabled items, so the landing index is always
        -- enabled; the guard is belt-and-suspenders (a fully-disabled group yields
        -- the unchanged current index, which may itself be disabled — then no-op).
        Just item -> when (not (item.disabled || st.disabled)) do
          -- the focused item becomes the roving tab stop (radix moves currentTabStopId onto
          -- it); focus it; SELECT only on an ARROW key (selection-follows-focus).
          H.modify_ _ { tabStop = Just item.value }
          focusItemAt idx
          when isArrow (selectValue item.value)
  -- Tab-into-group: forward container focus to the entry item (the selected radio, or the
  -- first ENABLED item when nothing is selected) and make it the roving tab stop.
  EntryFocus -> do
    st <- H.get
    case entryValue st of
      Nothing -> pure unit
      Just v -> do
        H.modify_ _ { tabStop = Just v }
        case findIndex (\i -> i.value == v) st.items of
          Just idx -> focusItemAt idx
          Nothing -> pure unit

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
