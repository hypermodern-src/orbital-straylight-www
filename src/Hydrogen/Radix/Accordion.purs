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
-- |   * RovingFocus over the header buttons: the triggers register with the
-- |     roving-focus collection (`data-radix-collection-item`); arrows move focus
-- |     among triggers only (manual activation) — Enter/Space/click toggle.
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

import Control.Monad.Maybe.Trans (MaybeT(..), runMaybeT)
import Control.Monad.Trans.Class (lift)
import Data.Array (elem, filter, find, findIndex, length, mapWithIndex, snoc, (!!))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_)
import Data.Traversable (traverse)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Web.DOM.Element as Element
import Web.Event.Event as Event
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, role, aria)
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
  , uid :: String        -- generated on Initialize; makes ids unique per instance
  , ids :: Array ItemIds  -- per-item trigger/panel ids (bare useId tokens), minted on Initialize
  }

-- | Per-item generated ids: bare `useId` tokens (`radix-<n>`) for the trigger and its
-- | panel, so the id↔reference linkage is the only thing the DOM oracle diff sees.
type ItemIds =
  { value :: String
  , trigger :: String
  , panel :: String
  }

data Action
  = Initialize
  | Receive Input
  | Toggle String
  | HeadersKeyDown KE.KeyboardEvent

-- | The effective, per-instance unique id base: readable prefix + the id minted on
-- | Initialize (so two default-prefixed Accordions on a page never collide).
base :: State -> String
base st = if st.uid == "" then st.idPrefix else st.idPrefix <> "-" <> st.uid

-- | RefLabel for an item's trigger. Keyed off the STABLE item value alone — NOT
-- | `base st`, whose embedded `uid` is minted on Initialize (after the first render):
-- | a ref label that changes after mount leaves `getHTMLElementRef` unable to resolve
-- | the element (same discipline as Tabs.tabRef). Arrow-key focus depends on this.
triggerRef :: String -> H.RefLabel
triggerRef value = H.RefLabel ("rdx-accordion-trigger-" <> value)

-- | The inline style upstream AccordionContent + CollapsibleContentImpl stamp on the
-- | OPEN content node: the accordion→collapsible var aliases plus the measured
-- | collapsible content height/width (any px; the oracle normalizer maps `<int>px`→`<px>`).
openContentStyle :: String
openContentStyle =
  "--radix-accordion-content-height: var(--radix-collapsible-content-height); "
    <> "--radix-accordion-content-width: var(--radix-collapsible-content-width); "
    <> "--radix-collapsible-content-height: 100px; "
    <> "--radix-collapsible-content-width: 200px;"

-- | The CLOSED content node carries only the accordion→collapsible var aliases (no
-- | measured px), since the collapsible content is not measured while hidden.
closedContentStyle :: String
closedContentStyle =
  "--radix-accordion-content-height: var(--radix-collapsible-content-height); "
    <> "--radix-accordion-content-width: var(--radix-collapsible-content-width);"

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
  , ctrl: controllable input.value input.defaultValue
  , single: input.single
  , collapsible: input.collapsible
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  , uid: ""
  , ids: []
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    [ dataOrientation st.orientation
    , classes st.style.root
    , HE.onKeyDown HeadersKeyDown
    ]
    (mapWithIndex (renderItem st) st.items)

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st _ item =
  let
    open = item.value `elem` current st.ctrl
    disabled = st.disabled || item.disabled
  in
    HH.div
      ( [ dataState (if open then "open" else "closed")
        , dataOrientation st.orientation
        , classes st.style.item
        ]
          <> (if disabled then [ dataAttr "disabled" "" ] else [])
      )
      [ HH.h3
          ( [ classes st.style.header
            , dataState (if open then "open" else "closed")
            , dataOrientation st.orientation
            ]
              <> (if disabled then [ dataAttr "disabled" "" ] else [])
          )
          [ HH.button
              ( [ HP.type_ HP.ButtonButton
                , HP.ref (triggerRef item.value)
                , HP.id (triggerId st item.value)
                , aria "expanded" (if open then "true" else "false")
                , dataState (if open then "open" else "closed")
                , dataOrientation st.orientation
                -- registers with the roving-focus collection (upstream Collection.ItemSlot)
                , dataAttr "radix-collection-item" ""
                , HP.disabled disabled
                , classes st.style.trigger
                , HE.onClick \_ -> Toggle item.value
                ]
                  -- aria-controls present ONLY when open (upstream CollapsibleTrigger)
                  <> (if open then [ aria "controls" (panelId st item.value) ] else [])
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
            , HP.style openContentStyle
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
            , HP.style closedContentStyle
            , HP.attr (HH.AttrName "hidden") ""
            ]
            []
      ]

-- | The trigger id for an item: the minted bare useId token if present (so it
-- | canonicalizes against upstream), else the readable composite fallback.
triggerId :: State -> String -> String
triggerId st value = case find (\i -> i.value == value) st.ids of
  Just ids -> ids.trigger
  Nothing -> base st <> "-trigger-" <> value

panelId :: State -> String -> String
panelId st value = case find (\i -> i.value == value) st.ids of
  Just ids -> ids.panel
  Nothing -> base st <> "-panel-" <> value

-- | Mint a bare-useId trigger + panel id pair for one item.
mintItemIds :: forall m. MonadEffect m => Item -> H.HalogenM State Action () Output m ItemIds
mintItemIds it = do
  trigger <- useId
  panel <- useId
  pure { value: it.value, trigger, panel }

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    uid <- useId
    items <- H.gets _.items
    ids <- traverse mintItemIds items
    H.modify_ _ { uid = uid, ids = ids }
  Receive input -> do
    -- preserve already-minted ids; mint for any item that lacks one (id stability)
    prev <- H.gets _.ids
    ids <- traverse
      ( \it -> case find (\p -> p.value == it.value) prev of
          Just p -> pure p
          Nothing -> mintItemIds it
      )
      input.items
    H.modify_ \st -> st
      { items = input.items
      , ids = ids
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
    -- upstream (accordion.tsx:235-240): the navigable collection EXCLUDES disabled
    -- triggers, and the nav origin is the CURRENTLY FOCUSED trigger (event.target),
    -- not the open/first item. Resolve the focused trigger from the event target's id,
    -- find its index WITHIN the non-disabled collection, navigate there, focus the result.
    mTargetId <- liftEffect $ runMaybeT do
      tgt <- MaybeT $ pure (Event.target (KE.toEvent ke))
      el <- MaybeT $ pure (Element.fromEventTarget tgt)
      lift (Element.id el)
    let
      enabled = filter (\i -> not (st.disabled || i.disabled)) st.items
      focusedIdx = case mTargetId of
        Just tid -> fromMaybe 0 (findIndex (\i -> triggerId st i.value == tid) enabled)
        Nothing -> 0
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      pos = { count: length enabled, current: focusedIdx }
    when (length enabled > 0) $ case navigate cfg pos (KE.key ke) of
      Stay -> pure unit
      MoveTo idx -> case enabled !! idx of
        Nothing -> pure unit
        Just item -> do
          -- manual activation: move focus only; toggling stays on click/Enter/Space
          mel <- H.getHTMLElementRef (triggerRef item.value)
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
