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
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.FocusScope (captureFocus, tabLoop)
import Hydrogen.Radix.Behavior.ScrollLock as ScrollLock
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState)
import Web.Event.Event as Event
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Per-part class lists. `scroll`/`scrollPadding` are the layout wrappers between the
-- | overlay and the content (radix-themes' centering + scroll-when-tall structure); the
-- | bare primitive leaves them semantic, a preset supplies the rt-* classes.
type Style =
  { trigger :: ClassNames
  , overlay :: ClassNames
  , scroll :: ClassNames
  , scrollPadding :: ClassNames
  , content :: ClassNames
  , title :: ClassNames
  , description :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-dialog-trigger"
  , overlay: cn "rdx-dialog-overlay"
  , scroll: cn "rdx-dialog-scroll"
  , scrollPadding: cn "rdx-dialog-scroll-padding"
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
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , escSub :: Maybe H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , locked :: Boolean
  , contentId :: String      -- generated on Initialize, trigger aria-controls target + content id
  , titleId :: String        -- generated on Initialize, aria-labelledby target
  , descriptionId :: String  -- generated on Initialize, aria-describedby target
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | OverlayClicked ME.MouseEvent
  | ContentKeyDown KE.KeyboardEvent
  | EscapePressed
  | AfterOpen           -- runs after the open render flushed: portal + focus

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-dialog-content"

-- | The portaled overlay wrapper — adopted into `document.body` on open.
portalRef :: H.RefLabel
portalRef = H.RefLabel "rdx-dialog-portal"

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
  , restoreEl: Nothing
  , escSub: Nothing
  , postSub: Nothing
  , locked: false
  , contentId: ""
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
          ( [ HP.type_ HP.ButtonButton
            , classes st.style.trigger
            , aria "expanded" (show open)
            , aria "haspopup" "dialog"
            , dataState (if open then "open" else "closed")
            , HE.onClick \_ -> TriggerClicked
            ]
              -- aria-controls references the content only while open (upstream gates it)
              <> (if open then [ aria "controls" st.contentId ] else [])
          )
          (map HH.fromPlainHTML st.trigger)
      , overlayContent open st
      ]

-- | The overlay is ALWAYS mounted (a stable VDOM child Halogen patches by reference,
-- | never removes — so moving it to `body` never trips Halogen's removal), hidden with
-- | `display:none` when closed. On open it is adopted into `document.body` (AfterOpen).
overlayContent :: forall m. Boolean -> State -> H.ComponentHTML Action () m
overlayContent open st =
  -- The OVERLAY is the portaled, themed root (matches upstream: body > overlay > scroll >
  -- scrollPadding > content). It carries the backdrop (position:fixed inset:0) and the
  -- click-outside handler; the scroll/padding wrappers center the content + scroll-when-tall.
  HH.div
    [ HP.ref portalRef
    , classes st.style.overlay
    , dataState (if open then "open" else "closed")
    , HP.style ("position:fixed;inset:0;" <> (if open then "" else "display:none;"))
    , HE.onClick OverlayClicked
    ]
    [ HH.div [ classes st.style.scroll ]
        [ HH.div [ classes st.style.scrollPadding ]
            [ HH.div
                ( [ HP.ref contentRef
                  , HP.id st.contentId
                  , classes st.style.content
                  , roleAttr "dialog"
                  -- NOTE: upstream does NOT set aria-modal — it aria-hides siblings via hideOthers.
                  , dataState (if open then "open" else "closed")
                  , HP.tabIndex (-1)
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
        ]
    ]

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    cid <- useId
    tid <- useId
    did <- useId
    H.modify_ _ { contentId = cid, titleId = tid, descriptionId = did }
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
  -- click on the overlay/scroll/padding (outside the content) closes — guard with
  -- isOutside so a click on the content (which bubbles up here) does NOT close.
  OverlayClicked me -> do
    st <- H.get
    when st.closeOnOutsideClick do
      mc <- H.getHTMLElementRef contentRef
      for_ mc \content -> do
        outside <- liftEffect (Dismiss.isOutside (HTMLElement.toNode content) (ME.toEvent me))
        when outside closeDialog
  EscapePressed -> do
    st <- H.get
    when st.closeOnEscape closeDialog
  ContentKeyDown ke -> do
    mnode <- H.getHTMLElementRef contentRef
    for_ mnode \node -> do
      handled <- liftEffect (tabLoop true node ke)
      when handled (liftEffect (Event.preventDefault (KE.toEvent ke)))
  -- runs on the frame after the open render flushed, so the refs are live. Adopt the
  -- overlay into body FIRST, THEN focus into the dialog — focusing after the move means
  -- the appendChild doesn't blur it. No `modify` here: a re-render would re-parent the
  -- wrapper back out of body (the restore target was already captured in openDialog).
  AfterOpen -> do
    mbody <- liftEffect Portal.documentBody
    mwrap <- H.getHTMLElementRef portalRef
    case mbody, mwrap of
      Just body, Just wrap -> liftEffect (Portal.adopt body (HTMLElement.toElement wrap))
      _, _ -> pure unit
    mnode <- H.getHTMLElementRef contentRef
    for_ mnode \node -> liftEffect (void (captureFocus node))

openDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openDialog = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- remember who had focus (the trigger) BEFORE we open, to restore on close — done
    -- now, before the portal, so no post-open `modify` is needed (which would un-portal).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, restoreEl = mprev }
    H.raise (OpenChanged true)
    when st.modal (liftEffect ScrollLock.lock)
    sub <-
      if st.closeOnEscape then do
        Just <$> H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      else pure Nothing
    -- portal + focus happen AFTER the render flushes (the content ref isn't live yet).
    psid <- scheduleAfterOpen
    H.modify_ _ { escSub = sub, postSub = Just psid, locked = st.modal }

-- | Dispatch `AfterOpen` on the next animation frame (after Halogen patches the open
-- | render). A one-shot subscription, torn down in `closeDialog`.
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

closeDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeDialog = do
  st <- H.get
  when (current st.ctrl) do
    for_ st.escSub H.unsubscribe
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    when st.locked (liftEffect ScrollLock.unlock)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, escSub = Nothing, postSub = Nothing, locked = false }
    H.raise (OpenChanged false)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openDialog else closeDialog
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
