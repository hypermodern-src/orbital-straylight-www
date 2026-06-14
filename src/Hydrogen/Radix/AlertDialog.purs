-- | Hydrogen.Radix.AlertDialog — modal alert dialog (radix `AlertDialog`).
-- |
-- | An `AlertDialog` IS a `Dialog` (same behavior substrate: `ControllableState`
-- | for open/closed, `FocusScope.captureFocus` on open, `ScrollLock`,
-- | `DismissableLayer.escape`) with three radix-mandated differences:
-- |
-- |   1. `role="alertdialog"` (not `"dialog"`) — it interrupts the user and
-- |      demands a response.
-- |   2. NO close-on-outside-click. An alert dialog must be dismissed by an
-- |      explicit action; radix prevents `onPointerDownOutside`/`onInteractOutside`.
-- |      So there is no `closeOnOutsideClick` input and the overlay click is a
-- |      no-op (the backdrop still renders). Escape close is kept (radix's
-- |      AlertDialog closes on Escape by default), gated on `closeOnEscape`.
-- |   3. It is always modal — there is no `modal` field; scroll lock is always on.
-- |
-- | The content references its description via `aria-describedby` (alert dialogs
-- | point at their description so assistive tech reads the consequence). The id is
-- | a fixed prefix — NOTE: single-instance limitation (two AlertDialogs in one
-- | document would collide on the description id); a per-instance id lands when a
-- | second instance is needed.
-- |
-- | v1 scope mirrors `Dialog`: single layer/scope (no nested-layer stack), portal
-- | rendered in place with `position:fixed` (no portal-to-body), no exit-animation
-- | Presence. NOTE: focus-on-open reads the content ref right after the open
-- | `modify`; if Halogen hasn't flushed the render the capture is skipped.
-- |
-- | Compound API (separate Trigger/Content/Action/Cancel components) is deferred;
-- | v1 takes the parts as `Array HH.PlainHTML` in input.
module Hydrogen.Radix.AlertDialog
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
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.FocusScope (Restore, captureFocus, tabLoop)
import Hydrogen.Radix.Behavior.ScrollLock as ScrollLock
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState)
import Web.Event.Event as Event
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Per-part class lists.
type Style =
  { trigger :: ClassNames
  , overlay :: ClassNames
  , content :: ClassNames
  , title :: ClassNames
  , description :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-alert-dialog-trigger"
  , overlay: cn "rdx-alert-dialog-overlay"
  , content: cn "rdx-alert-dialog-content"
  , title: cn "rdx-alert-dialog-title"
  , description: cn "rdx-alert-dialog-description"
  }

type Input =
  { open :: Maybe Boolean          -- controlled open state
  , defaultOpen :: Boolean         -- uncontrolled initial
  , closeOnEscape :: Boolean
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , title :: Array HH.PlainHTML
  , description :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  }

defaultInput :: Input
defaultInput =
  { open: Nothing
  , defaultOpen: false
  , closeOnEscape: true
  , style: defaultStyle
  , trigger: []
  , title: []
  , description: []
  , content: []
  }

data Output = OpenChanged Boolean

data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , closeOnEscape :: Boolean
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , title :: Array HH.PlainHTML
  , description :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , restore :: Maybe Restore
  , escSub :: Maybe H.SubscriptionId
  , locked :: Boolean
  }

data Action
  = Receive Input
  | TriggerClicked
  | ContentKeyDown KE.KeyboardEvent
  | EscapePressed

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-alert-dialog-content"

-- | Fixed description id (single-instance limitation — see module note).
descriptionId :: String
descriptionId = "rdx-alert-dialog-description"

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
  { ctrl: controllable input.open input.defaultOpen
  , closeOnEscape: input.closeOnEscape
  , style: input.style
  , trigger: input.trigger
  , title: input.title
  , description: input.description
  , content: input.content
  , restore: Nothing
  , escSub: Nothing
  , locked: false
  }

aria :: forall r i. String -> String -> HP.IProp r i
aria name val = HP.attr (HH.AttrName ("aria-" <> name)) val

roleAttr :: forall r i. String -> HP.IProp r i
roleAttr = HP.attr (HH.AttrName "role")

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div_
      [ HH.button
          [ HP.type_ HP.ButtonButton
          , classes st.style.trigger
          , aria "expanded" (show open)
          , aria "haspopup" "dialog"
          , HE.onClick \_ -> TriggerClicked
          ]
          (map HH.fromPlainHTML st.trigger)
      , if open then overlayContent st else HH.text ""
      ]

overlayContent :: forall m. State -> H.ComponentHTML Action () m
overlayContent st =
  HH.div_
    [ HH.div
        [ classes st.style.overlay
        , dataState "open"
        , HP.style "position:fixed;inset:0;"
        -- NOTE: alert dialog does NOT close on outside click; backdrop only.
        ]
        []
    , HH.div
        [ HP.ref contentRef
        , classes st.style.content
        , roleAttr "alertdialog"
        , aria "modal" "true"
        , aria "describedby" descriptionId
        , dataState "open"
        , HP.tabIndex (-1)
        , HP.style "position:fixed;"
        , HE.onKeyDown ContentKeyDown
        ]
        [ HH.div [ classes st.style.title ] (map HH.fromPlainHTML st.title)
        , HH.div
            [ HP.id descriptionId, classes st.style.description ]
            (map HH.fromPlainHTML st.description)
        , HH.div_ (map HH.fromPlainHTML st.content)
        ]
    ]

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , closeOnEscape = input.closeOnEscape
      , style = input.style
      , trigger = input.trigger
      , title = input.title
      , description = input.description
      , content = input.content
      }
  TriggerClicked -> openDialog
  EscapePressed -> do
    st <- H.get
    when st.closeOnEscape closeDialog
  ContentKeyDown ke -> do
    mnode <- H.getHTMLElementRef contentRef
    for_ mnode \node -> do
      handled <- liftEffect (tabLoop true node ke)
      when handled (liftEffect (Event.preventDefault (KE.toEvent ke)))

openDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openDialog = do
  st <- H.get
  when (not (current st.ctrl)) do
    H.modify_ _ { ctrl = (change true st.ctrl).next }
    H.raise (OpenChanged true)
    -- post-open setup (see NOTE on ref timing)
    mnode <- H.getHTMLElementRef contentRef
    restore <- case mnode of
      Just node -> Just <$> liftEffect (captureFocus node)
      Nothing -> pure Nothing
    -- always modal: lock scroll unconditionally.
    liftEffect ScrollLock.lock
    sub <-
      if st.closeOnEscape then do
        doc <- liftEffect (HTML.window >>= Window.document)
        Just <$> H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      else pure Nothing
    H.modify_ _ { restore = restore, escSub = sub, locked = true }

closeDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeDialog = do
  st <- H.get
  when (current st.ctrl) do
    for_ st.escSub H.unsubscribe
    liftEffect (fromMaybe (pure unit) st.restore)
    when st.locked (liftEffect ScrollLock.unlock)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restore = Nothing, escSub = Nothing, locked = false }
    H.raise (OpenChanged false)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openDialog else closeDialog
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
