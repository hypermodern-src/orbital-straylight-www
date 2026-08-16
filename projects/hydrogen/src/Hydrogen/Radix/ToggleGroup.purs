-- | Hydrogen.Radix.ToggleGroup — a group of toggle buttons with roving focus
-- | (radix `ToggleGroup`).
-- |
-- | This composes the two idioms already established by the templates:
-- |   * `Tabs` — items as DATA in `Input`, a single roving tab stop over the
-- |     items, arrow-key navigation via `RovingFocus.navigate` → focus a ref;
-- |   * `Toggle` — each item is a pressed/unpressed button emitting `aria-pressed`
-- |     + `data-state` ("on"/"off") + `data-disabled`.
-- |
-- | SIMPLIFICATION (v1). Radix splits the selection model into two props:
-- | `type="single"` (value is `string | undefined`) and `type="multiple"` (value
-- | is `string[]`). We model the value UNIFORMLY as `value :: Array String` — the
-- | set of currently-pressed item values — and expose a single `single :: Boolean`
-- | flag that enforces "at most one pressed" on toggle (pressing an item clears the
-- | others). So:
-- |   * multiple mode  = `single: false`  → toggling adds/removes from the set;
-- |   * single mode    = `single: true`   → toggling sets the set to `[value]`
-- |                                         (or `[]` when toggling the active one
-- |                                         off).
-- | This loses radix's `rovingFocus={false}` and `type="single"` non-array output
-- | shape, but keeps ONE state path and ONE `ValueChanged (Array String)` output.
-- |
-- | UPSTREAM DOM CONTRACT (verified against committed golden-dom oracles):
-- |   * Root → `<div role="group" dir="ltr" tabindex="0" style="outline: none">`
-- |     (optional `aria-label`). RovingFocusGroup.Root passes no orientation prop,
-- |     so NO `aria-orientation` / `data-orientation` is stamped.
-- |   * Item → `<button type="button" data-state="on|off" data-radix-collection-item
-- |     tabindex>` plus, in SINGLE mode, `role="radio" aria-checked` and NO
-- |     `aria-pressed` (ToggleGroupItemImpl singleProps overrides aria-pressed away);
-- |     in MULTIPLE mode the bare Toggle's `aria-pressed`. No item data-orientation.
-- |
-- | Activation is manual: arrow keys move focus ONLY (roving focus); click (or the
-- | button's native Enter/Space) toggles. The roving tab stop is the first pressed
-- | item's index, or 0 when nothing is pressed.
-- |
-- | Single instance per page for the fixed id prefix (note in Input).
module Hydrogen.Radix.ToggleGroup
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

import Data.Array (elem, filter, find, findIndex, length, mapWithIndex, snoc, (!!))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..), dirName)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, role, aria)
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
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-toggle-group"
  , item: cn "rdx-toggle-group-item"
  }

type Input =
  { items :: Array Item
  , value :: Maybe (Array String)   -- controlled pressed set (Nothing = uncontrolled)
  , defaultValue :: Array String    -- initial pressed set when uncontrolled
  , single :: Boolean               -- enforce at-most-one pressed on toggle
  , orientation :: Orientation
  , explicitOrientation :: Boolean  -- true ⇒ an orientation prop was actually passed, so
                                    -- RovingFocusGroup stamps data-orientation on root+items
                                    -- (the Themes default story passes none → no stamp).
  , dir :: Dir
  , loop :: Boolean
  , disabled :: Boolean             -- disable the whole group
  , idPrefix :: String              -- for item refs (unique per instance)
  , ariaLabel :: Maybe String       -- group label (radix `aria-label`); omitted when Nothing
  , trailing :: Array HH.PlainHTML  -- extra nodes appended after the items (e.g. the themed
                                    -- SegmentedControl sliding-indicator div)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { items: []
  , value: Nothing
  , defaultValue: []
  , single: false
  , orientation: Horizontal
  , explicitOrientation: false
  , dir: LTR
  , loop: true
  , disabled: false
  , idPrefix: "rdx-toggle-group"
  , ariaLabel: Nothing
  , trailing: []
  , style: defaultStyle
  }

-- | Emitted whenever the user requests a change to the pressed set — including in
-- | controlled mode, where the parent is expected to update `value` in response.
data Output = ValueChanged (Array String)

data Query a
  = SetValue (Array String) a
  | GetValue (Array String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { items :: Array Item
  , ctrl :: Controllable (Array String)
  , single :: Boolean
  , orientation :: Orientation
  , explicitOrientation :: Boolean
  , dir :: Dir
  , loop :: Boolean
  , disabled :: Boolean
  , idPrefix :: String
  , ariaLabel :: Maybe String
  , trailing :: Array HH.PlainHTML
  , style :: Style
  , focusEntered :: Boolean   -- false ⇒ every item -1 (the root holds the tab stop);
                              -- true once focus enters the group (RovingFocusGroup migrates
                              -- the tab stop from the root onto the current item).
  , focusedValue :: Maybe String  -- the item that currently holds focus (the roving cursor
                                  -- origin). Tracks the LAST focused item so arrow nav steps
                                  -- relative to where focus actually is — NOT the pressed
                                  -- value (which is constant when activation is manual).
  }

data Action
  = Receive Input
  | Toggled String
  | ListKeyDown KE.KeyboardEvent
  | EntryFocus
  | ItemFocused String

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
  , ctrl: controllable input.value input.defaultValue
  , single: input.single
  , orientation: input.orientation
  , explicitOrientation: input.explicitOrientation
  , dir: input.dir
  , loop: input.loop
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , ariaLabel: input.ariaLabel
  , trailing: input.trailing
  , style: input.style
  , focusEntered: false
  , focusedValue: Nothing
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( [ role "group"
      , HP.attr (HH.AttrName "dir") (dirName st.dir)
      , HP.tabIndex 0
      , HP.style "outline: none;"
      , classes st.style.root
      , HE.onKeyDown ListKeyDown
      -- Tab-into-group: the container (the roving tabindex=0 element) receives focus;
      -- forward it to the current roving item. `focus` does not bubble, so a child
      -- item receiving focus never re-triggers this — no re-entry loop.
      , HE.onFocus (const EntryFocus)
      ]
        <> (case st.ariaLabel of
              Just l -> [ aria "label" l ]
              Nothing -> [])
        -- RovingFocusGroup stamps data-orientation only when an orientation prop was passed
        -- (the Themes default story passes none, so the existing oracles stay un-stamped).
        <> (if st.explicitOrientation then [ dataOrientation st.orientation ] else [])
    )
    (mapWithIndex (renderItem st) st.items <> map HH.fromPlainHTML st.trailing)

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st idx item =
  let
    pressedSet = current st.ctrl
    on = item.value `elem` pressedSet
    disabled = st.disabled || item.disabled
    curIdx = tabStopIndex st
    -- roving tabindex: -1 on every item until focus enters the group (the root is the
    -- single tab stop); once entered, 0 migrates onto the current item. Matches
    -- RovingFocusGroup, which starts with currentTabStopId=null (root holds the stop).
    ti = if not st.focusEntered then (-1) else tabIndexFor curIdx idx
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef st.idPrefix item.value)
        , dataState (if on then "on" else "off")
        , dataAttr "radix-collection-item" ""
        , HP.tabIndex ti
        , HP.disabled disabled
        , classes st.style.item
        , HE.onClick \_ -> Toggled item.value
        , HE.onFocus (const (ItemFocused item.value))
        ]
          -- single mode → radio semantics (role + aria-checked, NO aria-pressed),
          -- mirroring upstream ToggleGroupItemImpl's singleProps; multiple mode keeps
          -- the bare Toggle's aria-pressed.
          <> (if st.single then [ role "radio", aria "checked" (if on then "true" else "false") ]
              else [ aria "pressed" (if on then "true" else "false") ])
          <> (if disabled then [ dataAttr "disabled" "" ] else [])
          -- data-orientation on items mirrors the root (RovingFocusGroup.Item), only when
          -- an orientation prop was explicitly passed.
          <> (if st.explicitOrientation then [ dataOrientation st.orientation ] else [])
      )
      (map HH.fromPlainHTML item.label)

-- | The roving tab stop: the first pressed item's index, else the first ENABLED
-- | item's index (a disabled item is never the tab stop — RovingFocusGroup builds
-- | the tab stop over focusable items only), else 0.
tabStopIndex :: State -> Int
tabStopIndex st =
  let
    pressedSet = current st.ctrl
    enabledAt i = not (st.disabled || i.disabled)
  in
    case findIndex (\i -> i.value `elem` pressedSet && enabledAt i) st.items of
      Just k -> k
      Nothing -> fromMaybe 0 (findIndex enabledAt st.items)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , ctrl = sync input.value st.ctrl
      , single = input.single
      , orientation = input.orientation
      , explicitOrientation = input.explicitOrientation
      , dir = input.dir
      , loop = input.loop
      , disabled = input.disabled
      , idPrefix = input.idPrefix
      , ariaLabel = input.ariaLabel
      , trailing = input.trailing
      , style = input.style
      }
  Toggled value -> do
    st <- H.get
    when (not st.disabled) do
      let
        cur = current st.ctrl
        next =
          if value `elem` cur then filter (_ /= value) cur
          else if st.single then [ value ]
          else snoc cur value
      setValue next
  ListKeyDown ke -> do
    st <- H.get
    -- upstream RovingFocusGroup returns early when any modifier is held
    -- (roving-focus-group onKeyDown: metaKey||ctrlKey||altKey||shiftKey) — modifier-laden
    -- arrows are ignored so they don't hijack browser/AT shortcuts.
    let
      modified = KE.metaKey ke || KE.ctrlKey ke || KE.altKey ke || KE.shiftKey ke
    -- upstream RovingFocusGroup filters candidateNodes to focusable items
    -- (roving-focus-group.tsx:271 getItems().filter(item => item.focusable),
    -- ToggleGroupItem focusable={!disabled}). So arrows navigate WITHIN the enabled
    -- subset and SKIP disabled items entirely (rather than stalling on one). The roving
    -- cursor origin is the LAST FOCUSED item (st.focusedValue) — NOT the pressed value,
    -- which stays put under manual activation (so loop/clamp must step from real focus).
    let
      enabled = filter (\i -> not (st.disabled || i.disabled)) st.items
      curValue = current st.ctrl
      originValue = case st.focusedValue of
        Just v -> v
        Nothing -> fromMaybe "" (map _.value (find (\i -> i.value `elem` curValue) enabled))
      curEnabled = fromMaybe 0 (findIndex (\i -> i.value == originValue) enabled)
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length enabled, current: curEnabled }
    when (not modified && length enabled > 0) $ case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case enabled !! idx of
        Nothing -> pure unit
        Just item -> do
          -- roving focus only: move focus, do NOT toggle (activation is manual)
          H.modify_ _ { focusEntered = true, focusedValue = Just item.value }
          focusItemByValue item.value
  -- Tab-into-group: forward container focus to the current roving item — the first
  -- pressed ENABLED item, or the first enabled item when nothing is pressed. (A disabled
  -- item is never a roving stop, matching RovingFocusGroup.Item focusable={!disabled}.)
  EntryFocus -> do
    H.modify_ _ { focusEntered = true }
    st <- H.get
    let
      enabled = filter (\i -> not (st.disabled || i.disabled)) st.items
      curValue = current st.ctrl
      target = case findIndex (\i -> i.value `elem` curValue) enabled of
        Just k -> enabled !! k
        Nothing -> enabled !! 0
    for_ target \item -> do
      H.modify_ _ { focusedValue = Just item.value }
      focusItemByValue item.value
  -- An item received focus directly (the native button focus on click, or a programmatic
  -- .focus()) — mark focus as entered so the roving tab stop migrates from the root onto
  -- an item (matching RovingFocusGroup.Item onFocus → currentTabStopId ← me), and record
  -- it as the roving cursor origin for subsequent arrow navigation.
  ItemFocused value -> H.modify_ _ { focusEntered = true, focusedValue = Just value }

-- | Focus the item with the given value via its existing ref (the same mechanism
-- | ListKeyDown uses). No-op when no such item exists.
focusItemByValue :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
focusItemByValue value = do
  st <- H.get
  mel <- H.getHTMLElementRef (itemRef st.idPrefix value)
  for_ mel (liftEffect <<< HTMLElement.focus)

setValue :: forall m. Array String -> H.HalogenM State Action () Output m Unit
setValue value = do
  st <- H.get
  when (current st.ctrl /= value) do
    H.modify_ _ { ctrl = (change value st.ctrl).next }
    H.raise (ValueChanged value)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    setValue v
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
