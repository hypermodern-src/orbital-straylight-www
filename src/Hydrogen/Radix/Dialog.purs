-- | Hydrogen.Radix.Dialog — modal dialog (radix `Dialog`).
-- |
-- | THE TEMPLATE for a *composed* primitive: it wires the behavior substrate
-- | together in one Halogen eval —
-- |   * `ControllableState` for open/closed (controlled or uncontrolled);
-- |   * `FocusScope.captureFocus` on open (focus first tabbable + a `Restore`),
-- |     `FocusScope.tabLoop` on content key-down (trap Tab), restore on close;
-- |   * `ScrollLock` while modal;
-- |   * `DismissableLayer.escape` (a document subscription set up on open, torn
-- |     down on close) for Escape-to-close; overlay click for outside-to-close;
-- |   * the stable surface — `role="dialog"`, `aria-modal`, `data-state` — plus
-- |     per-part classes from the `Style` record.
-- |
-- | v1 scope (by feel): single layer/scope (no nested-layer stack), portal
-- | rendered in place with `position:fixed` (no portal-to-body), no exit-animation
-- | Presence. NOTE: focus-on-open reads the content ref right after the open
-- | `modify`; if Halogen hasn't flushed the render the capture is skipped —
-- | validate under `hydrogen_test` and add a render-flush step if needed.
-- |
-- | Compound API (separate Trigger/Content/Title/… components) is deferred; v1
-- | takes the parts as `Array HH.PlainHTML` in input, which covers the common case.
module Hydrogen.Radix.Dialog
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

import Data.Array (null)
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Id (useId)
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
  { trigger: cn "rdx-dialog-trigger"
  , overlay: cn "rdx-dialog-overlay"
  , content: cn "rdx-dialog-content"
  , title: cn "rdx-dialog-title"
  , description: cn "rdx-dialog-description"
  }

type Input =
  { open :: Maybe Boolean          -- controlled open state
  , defaultOpen :: Boolean         -- uncontrolled initial
  , modal :: Boolean               -- lock scroll + aria-modal
  , closeOnEscape :: Boolean
  , closeOnOutsideClick :: Boolean
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
  , modal: true
  , closeOnEscape: true
  , closeOnOutsideClick: true
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
  , modal :: Boolean
  , closeOnEscape :: Boolean
  , closeOnOutsideClick :: Boolean
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , title :: Array HH.PlainHTML
  , description :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , restore :: Maybe Restore
  , escSub :: Maybe H.SubscriptionId
  , locked :: Boolean
  , titleId :: String        -- generated on Initialize, aria-labelledby target
  , descriptionId :: String  -- generated on Initialize, aria-describedby target
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | OverlayClicked
  | ContentKeyDown KE.KeyboardEvent
  | EscapePressed

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-dialog-content"

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
  , modal: input.modal
  , closeOnEscape: input.closeOnEscape
  , closeOnOutsideClick: input.closeOnOutsideClick
  , style: input.style
  , trigger: input.trigger
  , title: input.title
  , description: input.description
  , content: input.content
  , restore: Nothing
  , escSub: Nothing
  , locked: false
  , titleId: ""
  , descriptionId: ""
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
        , HE.onClick \_ -> OverlayClicked
        ]
        []
    , HH.div
        ( [ HP.ref contentRef
          , classes st.style.content
          , roleAttr "dialog"
          , aria "modal" (show st.modal)
          , dataState "open"
          , HP.tabIndex (-1)
          , HP.style "position:fixed;"
          , HE.onKeyDown ContentKeyDown
          ]
            -- link title/description only when present (radix is conditional)
            <> (if null st.title then [] else [ aria "labelledby" st.titleId ])
            <> (if null st.description then [] else [ aria "describedby" st.descriptionId ])
        )
        [ HH.div ([ classes st.style.title ] <> (if null st.title then [] else [ HP.id st.titleId ])) (map HH.fromPlainHTML st.title)
        , HH.div ([ classes st.style.description ] <> (if null st.description then [] else [ HP.id st.descriptionId ])) (map HH.fromPlainHTML st.description)
        , HH.div_ (map HH.fromPlainHTML st.content)
        ]
    ]

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    tid <- useId
    did <- useId
    H.modify_ _ { titleId = tid, descriptionId = did }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , modal = input.modal
      , closeOnEscape = input.closeOnEscape
      , closeOnOutsideClick = input.closeOnOutsideClick
      , style = input.style
      , trigger = input.trigger
      , title = input.title
      , description = input.description
      , content = input.content
      }
  TriggerClicked -> openDialog
  OverlayClicked -> do
    st <- H.get
    when st.closeOnOutsideClick closeDialog
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
    when st.modal (liftEffect ScrollLock.lock)
    sub <-
      if st.closeOnEscape then do
        doc <- liftEffect (HTML.window >>= Window.document)
        Just <$> H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      else pure Nothing
    H.modify_ _ { restore = restore, escSub = sub, locked = st.modal }

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
