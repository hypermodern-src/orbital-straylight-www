-- | Hydrogen.Radix.Collapsible — a disclosure (radix `Collapsible`).
-- |
-- | The SIMPLEST composed disclosure: a `button` trigger that toggles an `open`
-- | Boolean, and a `div` of content shown while open — kept mounted through its
-- | exit animation via `Behavior.Presence`, then dropped. No focus trap, no
-- | scroll lock, no dismissable layer (those belong to Dialog/Popover); the
-- | disclosure is pure open/closed.
-- |
-- |   * `ControllableState` for open/closed (controlled `open :: Maybe Boolean`
-- |     OR uncontrolled `defaultOpen`); the controlled slot refreshed on `receive`.
-- |   * `Presence` for the content: on open → `Open` (rendered, `data-state=open`);
-- |     on close → `present false` → `Closing` (still rendered, `data-state=closed`)
-- |     and we read the content ref — `hasAnimation`? subscribe `animationEnd`
-- |     (→ `AnimDone` → `finishExit` + unsubscribe) else `finishExit` now.
-- |   * the stable surface CSS targets — `data-state`, `data-disabled`,
-- |     `aria-expanded`, `aria-controls` — plus per-part classes from `Style`.
-- |
-- | The content `id` (the `aria-controls` target) is generated per mount
-- | (Behavior.Id), so multiple Collapsibles on a page don't collide. Parts taken as
-- | `Array HH.PlainHTML` (trigger label + content); the compound Trigger/Content
-- | component API is deferred.
module Hydrogen.Radix.Collapsible
  ( component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState, dataAttr, aria)
import Web.HTML.HTMLElement as HTMLElement

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Per-part class lists: the root, the trigger button, the content panel.
type Style =
  { root :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  }

-- | Semantic default — a preset supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-collapsible"
  , trigger: cn "rdx-collapsible-trigger"
  , content: cn "rdx-collapsible-content"
  }

type Input =
  { open :: Maybe Boolean          -- controlled open state (Nothing = uncontrolled)
  , defaultOpen :: Boolean         -- initial state when uncontrolled
  , disabled :: Boolean
  , style :: Style
  , trigger :: Array HH.PlainHTML  -- static trigger label/icon
  , content :: Array HH.PlainHTML  -- disclosed content
  }

defaultInput :: Input
defaultInput =
  { open: Nothing
  , defaultOpen: false
  , disabled: false
  , style: defaultStyle
  , trigger: []
  , content: []
  }

-- | Emitted on every user-requested change — including in controlled mode, where
-- | the parent is expected to update `open` in response.
data Output = OpenChanged Boolean

-- | External control.
data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , presence :: Presence
  , disabled :: Boolean
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , animSub :: Maybe H.SubscriptionId
  , contentId :: String  -- generated on Initialize; the trigger aria-controls target
  }

data Action
  = Initialize
  | Receive Input
  | Toggle
  | AnimDone

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-collapsible-content"

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
  { ctrl: controllable input.open input.defaultOpen
  , presence: if open then Open else Closed
  , disabled: input.disabled
  , style: input.style
  , trigger: input.trigger
  , content: input.content
  , animSub: Nothing
  , contentId: ""
  }
  where
  open = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div
      [ classes st.style.root
      , dataState (if open then "open" else "closed")
      ]
      ( [ HH.button
            ( [ HP.type_ HP.ButtonButton
              , aria "expanded" (show open)
              , aria "controls" st.contentId
              , dataState (if open then "open" else "closed")
              , HP.disabled st.disabled
              , classes st.style.trigger
              , HE.onClick \_ -> Toggle
              ]
                <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
            )
            (map HH.fromPlainHTML st.trigger)
        ]
          <>
            ( if isRendered st.presence then
                [ HH.div
                    ( [ HP.ref contentRef
                      , HP.id st.contentId
                      , dataState (dataStateOf st.presence)
                      , classes st.style.content
                      ]
                        <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
                    )
                    (map HH.fromPlainHTML st.content)
                ]
              else []
            )
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    cid <- useId
    H.modify_ _ { contentId = cid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , disabled = input.disabled
      , style = input.style
      , trigger = input.trigger
      , content = input.content
      }
  Toggle -> do
    st <- H.get
    when (not st.disabled) (setOpen (not (current st.ctrl)))
  AnimDone -> do
    st <- H.get
    for_ st.animSub H.unsubscribe
    H.modify_ _ { presence = finishExit st.presence, animSub = Nothing }

-- | Drive open/closed: advance the controllable, raise the change, and run the
-- | Presence transition (open → mounted; close → exit animation, then unmount).
setOpen :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
setOpen target = do
  st <- H.get
  when (current st.ctrl /= target) do
    let res = change target st.ctrl
    H.modify_ _ { ctrl = res.next }
    H.raise (OpenChanged res.emit)
    if target then
      -- opening: cancel any pending exit, mount immediately
      do
        for_ st.animSub H.unsubscribe
        H.modify_ _ { presence = Open, animSub = Nothing }
    else
      -- closing: enter Closing (still rendered), then run/skip the exit animation
      do
        H.modify_ _ { presence = present false st.presence }
        mnode <- H.getHTMLElementRef contentRef
        case mnode of
          Nothing -> H.modify_ \s -> s { presence = finishExit s.presence }
          Just node -> do
            animates <- liftEffect (hasAnimation node)
            if animates then do
              sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
              H.modify_ _ { animSub = Just sub }
            else
              H.modify_ \s -> s { presence = finishExit s.presence }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    setOpen v
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
