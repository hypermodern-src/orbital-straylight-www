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

import Data.Array (elem, filter, findIndex, length, mapWithIndex, snoc, (!!))
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
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, role, aria)
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
  , dir :: Dir
  , loop :: Boolean
  , disabled :: Boolean
  , idPrefix :: String
  , ariaLabel :: Maybe String
  , trailing :: Array HH.PlainHTML
  , style :: Style
  }

data Action
  = Receive Input
  | Toggled String
  | ListKeyDown KE.KeyboardEvent
  | EntryFocus

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
  , dir: input.dir
  , loop: input.loop
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , ariaLabel: input.ariaLabel
  , trailing: input.trailing
  , style: input.style
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
    )
    (mapWithIndex (renderItem st) st.items <> map HH.fromPlainHTML st.trailing)

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st idx item =
  let
    pressedSet = current st.ctrl
    on = item.value `elem` pressedSet
    disabled = st.disabled || item.disabled
    curIdx = tabStopIndex st
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef st.idPrefix item.value)
        , dataState (if on then "on" else "off")
        , dataAttr "radix-collection-item" ""
        , HP.tabIndex (tabIndexFor curIdx idx)
        , HP.disabled disabled
        , classes st.style.item
        , HE.onClick \_ -> Toggled item.value
        ]
          -- single mode → radio semantics (role + aria-checked, NO aria-pressed),
          -- mirroring upstream ToggleGroupItemImpl's singleProps; multiple mode keeps
          -- the bare Toggle's aria-pressed.
          <> (if st.single then [ role "radio", aria "checked" (if on then "true" else "false") ]
              else [ aria "pressed" (if on then "true" else "false") ])
          <> (if disabled then [ dataAttr "disabled" "" ] else [])
      )
      (map HH.fromPlainHTML item.label)

-- | The roving tab stop: the first pressed item's index, else 0.
tabStopIndex :: State -> Int
tabStopIndex st =
  let pressedSet = current st.ctrl
  in fromMaybe 0 (findIndex (\i -> i.value `elem` pressedSet) st.items)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , ctrl = sync input.value st.ctrl
      , single = input.single
      , orientation = input.orientation
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
    let
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length st.items, current: tabStopIndex st }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case st.items !! idx of
        Nothing -> pure unit
        Just item -> when (not item.disabled) do
          -- roving focus only: move focus, do NOT toggle (activation is manual)
          focusItemAt idx
  -- Tab-into-group: forward container focus to the current roving item (the first
  -- pressed item, or item 0 when nothing is pressed).
  EntryFocus -> do
    st <- H.get
    focusItemAt (tabStopIndex st)

-- | Focus the item at the given index via its existing ref (the same mechanism
-- | ListKeyDown uses). No-op when the index is out of range.
focusItemAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusItemAt idx = do
  st <- H.get
  case st.items !! idx of
    Nothing -> pure unit
    Just item -> do
      mel <- H.getHTMLElementRef (itemRef st.idPrefix item.value)
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
