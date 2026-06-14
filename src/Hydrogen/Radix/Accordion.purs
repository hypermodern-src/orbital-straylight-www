-- | Hydrogen.Radix.Accordion — a vertically stacked set of disclosures (radix
-- | `Accordion`).
-- |
-- | The COMPOSITE of the two templates: it is `Tabs` (items-as-data with a
-- | RovingFocus over the header buttons) wearing `Collapsible` per item (each
-- | header `button` toggles its panel's open/closed). The difference from Tabs is
-- | that the controllable value is a SET of open items (`Array String`), not a
-- | single active value, and the triggers *toggle* (manual activation) rather than
-- | selecting on arrow:
-- |
-- |   * open set via `ControllableState (Array String)` (controlled `value` +
-- |     uncontrolled `defaultValue`); the controlled slot refreshed on `receive`.
-- |   * `single` (radix `type="single"`) = at most one item open; `multiple` =
-- |     many. `collapsible` (single only) lets you close the open one — otherwise
-- |     the single open item can't be closed by clicking it.
-- |   * RovingFocus over the header buttons: the tab stop is the first OPEN item's
-- |     index (or 0); arrows move focus among triggers only (manual activation) —
-- |     Enter/Space/click toggle. `navigate`/`MoveTo`/`tabIndexFor`, exactly as Tabs.
-- |   * the stable surface per item: `data-state` open/closed, `data-disabled`,
-- |     `data-orientation`; the trigger's `aria-expanded`/`aria-controls`; the
-- |     panel's `role=region`/`aria-labelledby`.
-- |
-- | v1 scope: the content region is render-when-open (no `Presence` exit
-- | animation — that's the Collapsible refinement); `single` is a static prop of
-- | `Input` (no runtime switch). Vertical by default.
module Hydrogen.Radix.Accordion
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
  , header :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type Style =
  { root :: ClassNames
  , item :: ClassNames
  , header :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-accordion-root"
  , item: cn "rdx-accordion-item"
  , header: cn "rdx-accordion-header"
  , trigger: cn "rdx-accordion-trigger"
  , content: cn "rdx-accordion-content"
  }

type Input =
  { items :: Array Item
  , value :: Maybe (Array String)   -- controlled open items
  , defaultValue :: Array String    -- uncontrolled initial open items
  , single :: Boolean               -- at most one open (radix `type="single"`)
  , collapsible :: Boolean          -- (single) allow closing the open one
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , disabled :: Boolean
  , idPrefix :: String              -- for trigger/panel ids (unique per instance)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { items: []
  , value: Nothing
  , defaultValue: []
  , single: false
  , collapsible: false
  , orientation: Vertical
  , dir: LTR
  , loop: true
  , disabled: false
  , idPrefix: "rdx-accordion"
  , style: defaultStyle
  }

-- | Emitted on every user-requested change — including controlled mode, where the
-- | parent is expected to update `value` in response.
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
  , collapsible :: Boolean
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , disabled :: Boolean
  , idPrefix :: String
  , style :: Style
  }

data Action
  = Receive Input
  | Toggle String
  | HeadersKeyDown KE.KeyboardEvent

triggerRef :: String -> String -> H.RefLabel
triggerRef pfx value = H.RefLabel (pfx <> "-trigger-" <> value)

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
  , collapsible: input.collapsible
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    [ dataOrientation st.orientation
    , aria "orientation" (orientationName st.orientation)
    , classes st.style.root
    , HE.onKeyDown HeadersKeyDown
    ]
    (mapWithIndex (renderItem st) st.items)

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st _ item =
  let
    open = item.value `elem` current st.ctrl
    disabled = st.disabled || item.disabled
    curIdx = tabStopIndex st
    idx = fromMaybe 0 (findIndex (\i -> i.value == item.value) st.items)
  in
    HH.div
      ( [ dataState (if open then "open" else "closed")
        , dataOrientation st.orientation
        , classes st.style.item
        ]
          <> (if disabled then [ dataAttr "disabled" "" ] else [])
      )
      [ HH.h3
          [ classes st.style.header
          , dataState (if open then "open" else "closed")
          , dataOrientation st.orientation
          ]
          [ HH.button
              ( [ HP.type_ HP.ButtonButton
                , HP.ref (triggerRef st.idPrefix item.value)
                , HP.id (triggerId st item.value)
                , aria "expanded" (if open then "true" else "false")
                , aria "controls" (panelId st item.value)
                , dataState (if open then "open" else "closed")
                , dataOrientation st.orientation
                , HP.tabIndex (tabIndexFor curIdx idx)
                , HP.disabled disabled
                , classes st.style.trigger
                , HE.onClick \_ -> Toggle item.value
                ]
                  <> (if disabled then [ dataAttr "disabled" "" ] else [])
              )
              (map HH.fromPlainHTML item.header)
          ]
      , if open then
          HH.div
            [ HP.id (panelId st item.value)
            , role "region"
            , aria "labelledby" (triggerId st item.value)
            , dataState "open"
            , dataOrientation st.orientation
            , classes st.style.content
            ]
            (map HH.fromPlainHTML item.content)
        else
          HH.div
            [ HP.id (panelId st item.value)
            , role "region"
            , aria "labelledby" (triggerId st item.value)
            , dataState "closed"
            , dataOrientation st.orientation
            , classes st.style.content
            , HP.attr (HH.AttrName "hidden") ""
            ]
            []
      ]

triggerId :: State -> String -> String
triggerId st value = st.idPrefix <> "-trigger-" <> value

panelId :: State -> String -> String
panelId st value = st.idPrefix <> "-panel-" <> value

-- | The roving tab stop: the first OPEN item's index, else 0.
tabStopIndex :: State -> Int
tabStopIndex st =
  fromMaybe 0 (findIndex (\i -> i.value `elem` current st.ctrl) st.items)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , ctrl = sync input.value st.ctrl
      , single = input.single
      , collapsible = input.collapsible
      , orientation = input.orientation
      , dir = input.dir
      , loop = input.loop
      , disabled = input.disabled
      , idPrefix = input.idPrefix
      , style = input.style
      }
  Toggle value -> toggleItem value
  HeadersKeyDown ke -> do
    st <- H.get
    let
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length st.items, current: tabStopIndex st }
    case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case st.items !! idx of
        Nothing -> pure unit
        Just item -> when (not (st.disabled || item.disabled)) do
          -- manual activation: move focus only; toggling stays on click/Enter/Space
          mel <- H.getHTMLElementRef (triggerRef st.idPrefix item.value)
          for_ mel (liftEffect <<< HTMLElement.focus)

-- | Toggle item `value`'s membership in the open set, honoring single/collapsible.
-- |  * already open  → close it (remove), UNLESS `single && not collapsible` (the
-- |                    single open item can't be closed by clicking it).
-- |  * closed        → open it (add); when `single`, the set becomes just `[value]`.
toggleItem :: forall m. String -> H.HalogenM State Action () Output m Unit
toggleItem value = do
  st <- H.get
  let
    open = current st.ctrl
    isOpen = value `elem` open
    next =
      if isOpen then
        if st.single && not st.collapsible then open
        else filter (_ /= value) open
      else if st.single then [ value ]
      else snoc open value
  when (next /= open) (commit next)

commit :: forall m. Array String -> H.HalogenM State Action () Output m Unit
commit next = do
  st <- H.get
  H.modify_ _ { ctrl = (change next st.ctrl).next }
  H.raise (ValueChanged next)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    commit v
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
