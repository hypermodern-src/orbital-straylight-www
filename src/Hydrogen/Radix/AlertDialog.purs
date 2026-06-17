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
-- | Portal-to-body (mirrors `Dialog`): the overlay wrapper is rendered while present
-- | (Open OR Closing); on open it is adopted into `document.body` after the next frame
-- | (`AfterOpen`), so the backdrop/content escape any ancestor stacking/overflow/transform
-- | context. The restore target (the trigger) is captured in the open handler BEFORE the
-- | portal, so no post-open `modify` (which would re-parent the wrapper back out of body)
-- | is needed for focus.
-- |
-- | Exit animation (mirrors `Dialog`): on close the overlay+content stay MOUNTED with
-- | `data-state=closed` (and the modal envelope — scroll-lock marker, focus guards,
-- | hideOthers — stays in place) until the content's exit animation (`rt-dialog-content-hide`)
-- | ends, THEN the envelope is torn down and the overlay unmounts — mirroring radix
-- | `Presence`. If the content has no exit animation, the close is immediate (no gap).
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
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
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
  , presence :: Presence  -- Open / Closing (mounted, exiting) / Closed (unmounted)
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
  , animSub :: Maybe H.SubscriptionId  -- content `animationend` subscription during exit
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
  | AfterClose          -- runs after the closing render flushed: re-portal + arm exit animation
  | AnimDone            -- the content exit animation finished: finishExit + tear down envelope

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
  , presence: if startOpen then Open else Closed
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
  , animSub: Nothing
  , locked: false
  , contentId: ""
  , titleId: ""
  , descriptionId: ""
  }
  where
  startOpen = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

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
      ( [ HH.button
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
        ]
          -- the overlay is rendered while `isRendered presence` (Open OR Closing): on close it
          -- LINGERS with data-state=closed through its exit animation, then unmounts at Closed.
          <> (if isRendered st.presence then [ overlayContent st ] else [])
      )

-- | The overlay is rendered while present (Open OR Closing); on open it is adopted into
-- | `document.body` (AfterOpen), kept through the exit animation on close (Presence), and
-- | dropped at Closed. Anatomy mirrors upstream: body > overlay > scroll > scrollPadding >
-- | content. The overlay is the portaled, themed root carrying the backdrop. An alert dialog
-- | does NOT close on outside click, so the overlay has NO click handler (backdrop only).
overlayContent :: forall m. State -> H.ComponentHTML Action () m
overlayContent st =
  HH.div
    ( [ HP.ref portalRef
      , classes st.style.overlay
      , dataState (dataStateOf st.presence)
      -- the rt-BaseDialogOverlay class supplies position:fixed/inset:0; inline only carries
      -- pointer-events:auto — present in BOTH Open and Closing (radix keeps the closing overlay visible).
      , HP.style "pointer-events: auto;"
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
                  , dataState (dataStateOf st.presence)
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
  -- runs on the frame after the CLOSING render flushed. Halogen re-parented the overlay back
  -- under the component root on the close re-render, so re-adopt it into body (it must linger
  -- there with data-state=closed through the exit animation). Then read the content ref and
  -- arm the exit: if it has a running CSS exit animation, finishClose when `animationend` fires;
  -- otherwise finishClose now (no animation ⇒ immediate unmount, like radix). The modal envelope
  -- (scroll-lock marker, guards, hideOthers) is intentionally NOT torn down here — it lingers until AnimDone.
  AfterClose -> do
    -- Arm the exit FIRST (the `animSub` modify re-renders, which re-parents the overlay back
    -- under the component root), THEN re-adopt into body as the LAST effect so no subsequent
    -- render moves it out again (mirrors AfterOpen's "no modify after adopt" discipline).
    mnode <- H.getHTMLElementRef contentRef
    armed <- case mnode of
      Nothing -> pure false
      Just node -> do
        animates <- liftEffect (hasAnimation node)
        if animates then do
          sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
          H.modify_ _ { animSub = Just sub }
          pure true
        else pure false
    if armed then do
      -- re-adopt the overlay BEFORE the trailing focus guard (the guards already exist; a
      -- plain appendChild would land it after the trail guard and break body order).
      mwrap <- H.getHTMLElementRef portalRef
      for_ mwrap \wrap -> liftEffect (Envelope.reAdoptBeforeTrail wrap)
      -- release the pointer block the OPEN envelope set: radix's RemoveScroll disables the
      -- moment `open` flips false (the body `pointer-events:none` and the content's
      -- `pointer-events:auto` go away), while the closing node lingers for the exit animation.
      -- The `data-scroll-locked` marker + focus guards + hideOthers stay until unmount.
      liftEffect Envelope.releaseScrollPointer
      for_ mnode \node -> liftEffect (Envelope.clearPointerEvents (HTMLElement.toElement node))
    else finishClose
  AnimDone -> finishClose

openDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openDialog = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- remember who had focus (the trigger) BEFORE we open, to restore on close — done
    -- now, before the portal, so no post-open `modify` is needed (which would un-portal).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    -- re-opening cancels any in-flight exit (the overlay is still mounted/Closing).
    for_ st.animSub H.unsubscribe
    H.modify_ _ { ctrl = (change true st.ctrl).next, restoreEl = mprev, presence = Open, animSub = Nothing }
    H.raise (OpenChanged true)
    sub <-
      if st.closeOnEscape then
        Just <$> H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      else pure Nothing
    -- portal + focus happen AFTER the render flushes (the content ref isn't live yet).
    psid <- scheduleAfter AfterOpen
    H.modify_ _ { escSub = sub, postSub = Just psid, locked = true }

-- | Dispatch `act` on the next animation frame (after Halogen patches the render). A one-shot
-- | subscription; the open path tracks it in `postSub` (torn down in closeDialog).
scheduleAfter :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfter act = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (act <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | Begin the close: flip controllable + Presence to Closing (the overlay stays MOUNTED with
-- | data-state=closed, still portaled in body, envelope still up), tear down the open-time
-- | document subscriptions, restore focus to the trigger, and schedule AfterClose to arm the
-- | exit animation on the next frame. The envelope teardown + unmount happen at AnimDone.
closeDialog :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeDialog = do
  st <- H.get
  when (current st.ctrl) do
    for_ st.escSub H.unsubscribe
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, presence = present false st.presence, escSub = Nothing, postSub = Nothing }
    H.raise (OpenChanged false)
    psid <- scheduleAfter AfterClose
    H.modify_ _ { postSub = Just psid }

-- | The exit animation finished (or there was none): tear down the modal envelope, drop the
-- | overlay (Presence Closing → Closed unmounts it), and clear the exit subscriptions.
finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  when st.locked (liftEffect (Envelope.showOthers *> Envelope.removeFocusGuards *> Envelope.unlockScroll))
  H.modify_ _ { presence = finishExit st.presence, restoreEl = Nothing, animSub = Nothing, postSub = Nothing, locked = false }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openDialog else closeDialog
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
