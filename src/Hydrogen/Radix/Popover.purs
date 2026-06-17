-- | Hydrogen.Radix.Popover — floating content anchored to a trigger (radix
-- | `Popover`).
-- |
-- | THE TEMPLATE for a Float-consumer (Tooltip/HoverCard/DropdownMenu/Select all
-- | follow this). It composes:
-- |   * `ControllableState` open;
-- |   * `Float.Popper.position` on open + on scroll/resize (anchor = trigger ref,
-- |     floating = content ref) → applies coords + yields the resolved placement,
-- |     stamped as `data-side`/`data-align`;
-- |   * `DismissableLayer` — Escape (document keydown) AND pointer-outside
-- |     (document pointerdown + `isOutside` the content) — subscriptions set up on
-- |     open, torn down on close;
-- |   * `FocusScope.captureFocus` on open + `tabLoop` on content key-down;
-- |   * the stable surface: aria-expanded/haspopup on the trigger,
-- |     data-state/data-side/data-align on the content.
-- |
-- | Exit animation: on close the popper-wrapper stays MOUNTED with the content carrying
-- | `data-state=closed` (and `data-side`/`data-align` preserved) until the content's exit
-- | animation (`rt-slide-to-*`/`rt-fade-out`) ends, THEN the wrapper unmounts and the focus
-- | guards are removed — mirroring radix `Presence`. Non-modal: no scroll-lock/hideOthers,
-- | so the only envelope teardown is `removeFocusGuards`. No exit animation ⇒ immediate close.
-- |
-- | v1 (by feel): non-modal, single instance per page (fixed ids).
module Hydrogen.Radix.Popover
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

import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.FocusScope (captureFocus, tabLoop)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Envelope as Envelope
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName, aria, role)
import Web.DOM.Node (Node)
import Web.Event.Event (Event, EventType(..), preventDefault)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Style =
  { trigger :: ClassNames
  , content :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-popover-trigger"
  , content: cn "rdx-popover-content"
  }

type Input =
  { open :: Maybe Boolean       -- controlled
  , defaultOpen :: Boolean      -- uncontrolled initial
  , side :: Side                -- preferred side
  , align :: Align              -- alignment along the side
  , offset :: Number            -- gap from the trigger
  , padding :: Number           -- min gap from viewport edges
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String      -- the content's CONSTANT style (--width + the var aliases)
  , triggerAttrs :: Array (Tuple String String)  -- data-* on the trigger (e.g. accent-color)
  , portalAttrs :: Array (Tuple String String)   -- data-* on the content (theme re-application)
  }

defaultInput :: Input
defaultInput =
  { open: Nothing
  , defaultOpen: false
  , side: Bottom
  , align: Center
  , offset: 8.0
  , padding: 8.0
  , style: defaultStyle
  , trigger: []
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
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen / AfterClose
  , animSub :: Maybe H.SubscriptionId  -- content `animationend` subscription during exit
  , contentNode :: Maybe Node
  , contentId :: String  -- generated on Initialize; trigger aria-controls target + content id
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | AfterClose          -- after the closing render flushed: re-adopt + arm exit animation
  | AnimDone            -- the content exit animation finished: finishExit + removeFocusGuards
  | EscapePressed
  | PointerDown Event
  | ContentKeyDown KE.KeyboardEvent
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-popover-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-popover-content"

-- | The popper-wrapper (the positioned `data-radix-popper-content-wrapper` div) — the
-- | portal root adopted into body; the content sits statically inside it.
wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-popover-wrapper"

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

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
  , side: input.side
  , align: input.align
  , offset: input.offset
  , padding: input.padding
  , style: input.style
  , trigger: input.trigger
  , content: input.content
  , contentStyle: input.contentStyle
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
  , placedSide: input.side
  , placedAlign: input.align
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , animSub: Nothing
  , contentNode: Nothing
  , contentId: ""
  }
  where
  startOpen = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , classes st.style.trigger
            , aria "expanded" (if open then "true" else "false")
            , aria "haspopup" "dialog"
            , dataState (if open then "open" else "closed")
            , dataAttr "radix-popper-side" (sideName st.placedSide)
            , dataAttr "radix-popper-align" (alignName st.placedAlign)
            , HE.onClick \_ -> TriggerClicked
            ]
              <> (if open then [ aria "controls" st.contentId ] else [])
              <> portalData st.triggerAttrs
          )
          (map HH.fromPlainHTML st.trigger)
      -- The popper WRAPPER (the portal root) is ALWAYS mounted (hidden when closed) so
      -- Halogen never removes it — only patches it — which makes adopting it into body safe.
      -- Its style is set out-of-band by Popper.positionWrapper; the rendered string stays
      -- CONSTANT (only the display toggle) so Halogen never clobbers the FFI writes. While
      -- `isRendered presence` (Open OR Closing) it carries `position: fixed;` and the FFI
      -- coords linger through the exit animation; only at Closed does it drop to display:none.
      , HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          -- position:fixed from the start so the content is shrink-to-fit (max-content) when
          -- Popper measures it for the flip; the rest of the style is FFI (and position:fixed
          -- stays first in the serialization, matching upstream's order).
          , HP.style (if isRendered st.presence then "position: fixed;" else "display:none;")
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , HP.id st.contentId
                , classes st.style.content
                , role "dialog"
                -- data-state mirrors Presence: open while Open, closed while Closing (so the
                -- rt-slide-to-*/rt-fade-out exit animation runs) AND when unmounted.
                , dataState (dataStateOf st.presence)
                , dataAttr "side" (sideName st.placedSide)
                , dataAttr "align" (alignName st.placedAlign)
                , HP.tabIndex (-1)
                -- the content's CONSTANT style: --width + the --radix-popover-content-* var
                -- aliases (the wrapper positions; the content itself is unpositioned).
                , HP.style st.contentStyle
                , HE.onKeyDown ContentKeyDown
                ] <> portalData st.portalAttrs
              )
              (map HH.fromPlainHTML st.content)
          ]
      ]

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    cid <- useId
    H.modify_ _ { contentId = cid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , side = input.side
      , align = input.align
      , offset = input.offset
      , padding = input.padding
      , style = input.style
      , trigger = input.trigger
      , content = input.content
      , contentStyle = input.contentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closePopover else openPopover
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body + focus.
  AfterOpen -> do
    reposition
    finalize true
  -- runs on the frame after the CLOSING render flushed. The close re-render re-parented the
  -- wrapper back under the component root, so re-adopt it into body (before the trailing focus
  -- guard) — it must linger there with the content data-state=closed through the exit animation.
  -- Then read the content ref and arm the exit: if it has a running CSS exit animation, finish
  -- when `animationend` fires; otherwise finish now (no animation ⇒ immediate unmount).
  AfterClose -> do
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
      -- re-adopt the wrapper BEFORE the trailing focus guard (the guards still exist; a plain
      -- appendChild would land it after the trail guard and break body order).
      mwrap <- H.getHTMLElementRef wrapperRef
      for_ mwrap \wrap -> liftEffect (Envelope.reAdoptBeforeTrail wrap)
    else finishClose
  AnimDone -> finishClose
  EscapePressed -> closePopover
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside closePopover
  ContentKeyDown ke -> do
    mnode <- H.getHTMLElementRef contentRef
    for_ mnode \node -> do
      handled <- liftEffect (tabLoop true node ke)
      when handled (liftEffect (preventDefault (KE.toEvent ke)))
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame). No re-focus.
  Reposition -> do
    reposition
    finalize false

openPopover :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openPopover = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, restoreEl = mprev }
    H.raise (OpenChanged true)
    mcNode <- map HTMLElement.toNode <$> H.getHTMLElementRef contentRef
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    ptrSub <- H.subscribe (Dismiss.pointerDown docTarget PointerDown)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    -- re-opening cancels any in-flight exit (the wrapper is still mounted/Closing).
    for_ st.animSub H.unsubscribe
    psid <- scheduleAfter AfterOpen
    H.modify_ _
      { presence = Open
      , animSub = Nothing
      , contentNode = mcNode
      , subs = [ escSub, ptrSub, scrollSub, resizeSub ]
      , postSub = Just psid
      }

-- | Dispatch `act` on the next animation frame (after Halogen patches the render). A one-shot
-- | subscription; the caller tracks it in `postSub`.
scheduleAfter :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfter act = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (act <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | On the next frame (after the placement modify's render re-parents the content),
-- | adopt the content into body — and, on open, focus into it AFTER the move so the
-- | appendChild doesn't blur it.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  mc <- H.getHTMLElementRef contentRef
  case mbody, mwrap of
    Just body, Just wrap ->
      liftEffect $ Portal.afterFrame do
        -- adopt the WRAPPER (the positioned portal root); on open add the focus-guard
        -- sentinels AFTER it (so the trailing guard lands last) and focus into the content.
        Portal.adopt body (HTMLElement.toElement wrap)
        when focusToo do
          Envelope.addFocusGuards
          for_ mc \content -> void (captureFocus content)
    _, _ -> pure unit

-- | Begin the close: flip controllable + Presence to Closing (the wrapper stays MOUNTED with
-- | the content data-state=closed, still portaled in body, focus guards still up), tear down
-- | the open-time document subscriptions, restore focus to the trigger, and schedule AfterClose
-- | to arm the exit animation on the next frame. The guard teardown + unmount happen at AnimDone.
closePopover :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closePopover = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, presence = present false st.presence, subs = [], postSub = Nothing, contentNode = Nothing }
    H.raise (OpenChanged false)
    psid <- scheduleAfter AfterClose
    H.modify_ _ { postSub = Just psid }

-- | The exit animation finished (or there was none): remove the focus guards (the only
-- | non-modal envelope state), drop the wrapper (Presence Closing → Closed unmounts it), and
-- | clear the exit subscriptions.
finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  liftEffect Envelope.removeFocusGuards
  H.modify_ _ { presence = finishExit st.presence, restoreEl = Nothing, animSub = Nothing, postSub = Nothing }

-- | Measure + solve, position the WRAPPER (not the content), and stamp the resolved
-- | placement for the trigger/content data-side/align.
reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  manchor <- H.getHTMLElementRef triggerRef
  mwrap <- H.getHTMLElementRef wrapperRef
  mfloat <- H.getHTMLElementRef contentRef
  case manchor, mwrap, mfloat of
    Just anchor, Just wrapper, Just floating -> do
      placed <- liftEffect (Popper.positionWrapper
        { anchor, wrapper, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
    _, _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openPopover else closePopover
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
