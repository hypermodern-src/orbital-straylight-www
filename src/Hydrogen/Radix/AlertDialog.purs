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
-- | The content references its title via `aria-labelledby` and its description via
-- | `aria-describedby` (alert dialogs point at their description so assistive tech
-- | reads the consequence). Both ids are generated per mount (Behavior.Id), so two
-- | AlertDialogs in one document don't collide; each link is emitted only when its
-- | part is non-empty (matching radix).
-- |
-- | Portal-to-body (mirrors `Dialog`): the overlay wrapper is ALWAYS mounted (a
-- | stable VDOM child Halogen patches by reference, never removes — so moving it to
-- | `body` never trips Halogen's removal), hidden with `display:none` when closed. On
-- | open it is adopted into `document.body` after the next frame (`AfterOpen`), so the
-- | backdrop/content escape any ancestor stacking/overflow/transform context. The
-- | restore target (the trigger) is captured in the open handler BEFORE the portal,
-- | so no post-open `modify` (which would re-parent the wrapper back out of body) is
-- | needed for focus.
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

import Data.Array (null)
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.FocusScope (captureFocus, tabLoop)
import Hydrogen.Radix.Foundation.Envelope as Envelope
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState)
import Web.Event.Event as Event
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

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
  { trigger: cn "rdx-alert-dialog-trigger"
  , overlay: cn "rdx-alert-dialog-overlay"
  , scroll: cn "rdx-alert-dialog-scroll"
  , scrollPadding: cn "rdx-alert-dialog-scroll-padding"
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
  , contentStyle :: String         -- extra inline style on the content (e.g. --max-width)
  , triggerAttrs :: Array (Tuple String String)  -- data-* attrs for the trigger (e.g. accent-color)
  , portalAttrs :: Array (Tuple String String)   -- data-* attrs for the portaled overlay (theme re-application)
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
  , contentStyle: ""
  , triggerAttrs: []
  , portalAttrs: []
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
  , contentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
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
  | ContentKeyDown KE.KeyboardEvent
  | EscapePressed
  | AfterOpen           -- runs after the open render flushed: portal + focus

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-alert-dialog-content"

-- | The portaled overlay wrapper — adopted into `document.body` on open.
portalRef :: H.RefLabel
portalRef = H.RefLabel "rdx-alert-dialog-portal"

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
  , closeOnEscape: input.closeOnEscape
  , style: input.style
  , trigger: input.trigger
  , title: input.title
  , description: input.description
  , content: input.content
  , contentStyle: input.contentStyle
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
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

-- | Render `data-<k>=<v>` for each (k,v) — the preset's theme/accent attrs.
portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
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
              <> portalData st.triggerAttrs
          )
          (map HH.fromPlainHTML st.trigger)
      , overlayContent open st
      ]

-- | The overlay is ALWAYS mounted (a stable VDOM child Halogen patches by reference,
-- | never removes — so moving it to `body` never trips Halogen's removal), hidden with
-- | `display:none` when closed. On open it is adopted into `document.body` (AfterOpen).
-- | Anatomy mirrors upstream: body > overlay > scroll > scrollPadding > content. The
-- | overlay is the portaled, themed root carrying the backdrop. An alert dialog does NOT
-- | close on outside click, so the overlay has NO click handler (backdrop only).
overlayContent :: forall m. Boolean -> State -> H.ComponentHTML Action () m
overlayContent open st =
  HH.div
    ( [ HP.ref portalRef
      , classes st.style.overlay
      , dataState (if open then "open" else "closed")
      , HP.style (if open then "pointer-events: auto;" else "display:none;")
      ] <> portalData st.portalAttrs
    )
    [ HH.div [ classes st.style.scroll ]
        [ HH.div [ classes st.style.scrollPadding ]
            [ HH.div
                ( [ HP.ref contentRef
                  , HP.id st.contentId
                  , classes st.style.content
                  , roleAttr "alertdialog"
                  -- NOTE: upstream does NOT set aria-modal — it aria-hides siblings via hideOthers.
                  , dataState (if open then "open" else "closed")
                  , HP.tabIndex (-1)
                  , HP.style st.contentStyle
                  , HE.onKeyDown ContentKeyDown
                  ]
                    <> (if null st.title then [] else [ aria "labelledby" st.titleId ])
                    <> (if null st.description then [] else [ aria "describedby" st.descriptionId ])
                )
                ( [ HH.h1 ([ classes st.style.title ] <> (if null st.title then [] else [ HP.id st.titleId ])) (map HH.fromPlainHTML st.title)
                  , HH.p ([ classes st.style.description ] <> (if null st.description then [] else [ HP.id st.descriptionId ])) (map HH.fromPlainHTML st.description)
                  ] <> map HH.fromPlainHTML st.content
                )
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
      , closeOnEscape = input.closeOnEscape
      , style = input.style
      , trigger = input.trigger
      , title = input.title
      , description = input.description
      , content = input.content
      , contentStyle = input.contentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
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
    -- the modal document envelope (alert dialog is always modal), now the overlay is a body
    -- child: scroll-lock + focus guards + aria-hide siblings. No `modify` (pure DOM effects).
    for_ mwrap \wrap -> liftEffect do
      Envelope.lockScroll
      Envelope.addFocusGuards
      Envelope.hideOthers wrap

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
    sub <-
      if st.closeOnEscape then
        Just <$> H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      else pure Nothing
    -- portal + focus happen AFTER the render flushes (the content ref isn't live yet).
    psid <- scheduleAfterOpen
    H.modify_ _ { escSub = sub, postSub = Just psid, locked = true }

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
    when st.locked (liftEffect (Envelope.showOthers *> Envelope.removeFocusGuards *> Envelope.unlockScroll))
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
