-- | Hydrogen.Radix.Tooltip — a hover/focus-triggered floating label (radix
-- | `Tooltip`).
-- |
-- | A `Popover` whose trigger is opened by hover/focus instead of click, with NO
-- | focus trap and NO pointer-outside dismiss (a tooltip never steals focus and
-- | never owns a dismissable layer beyond Escape). It composes:
-- |   * `ControllableState` open;
-- |   * `Float.Popper.position` on open + on scroll/resize (anchor = trigger ref,
-- |     floating = content ref) → applies coords + yields the resolved placement,
-- |     stamped as `data-side`/`data-align`;
-- |   * `DismissableLayer.escape` ONLY — Escape (document keydown) dismisses;
-- |     no pointer-outside subscription;
-- |   * portal-to-body — the content is always mounted (hidden when closed) and
-- |     adopted into `document.body` after open so its position:fixed escapes any
-- |     ancestor stacking/overflow/transform context (radix's portal mechanism);
-- |   * the stable surface: aria-describedby on the trigger → content id,
-- |     data-state/data-side/data-align on the content, role="tooltip".
-- |
-- | v1 (by feel): no open/close delay (`delayMs` is a follow-up — show/hide fire
-- | immediately), no Presence exit animation (mount/unmount). The content id is
-- | generated per mount (Behavior.Id) so multiple instances don't collide; the
-- | fixed RefLabels are still single-instance.
module Hydrogen.Radix.Tooltip
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
import Data.Foldable (for_, traverse_)
import Data.Tuple (Tuple(..))
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName, aria, role)
import Web.Event.Event (EventType(..))
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Style =
  { trigger :: ClassNames
  , content :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-tooltip-trigger"
  , content: cn "rdx-tooltip-content"
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
  , contentStyle :: String      -- the content's CONSTANT style (--max-width + var aliases)
  , arrow :: Array HH.PlainHTML  -- optional arrow svg, positioned at the content edge
  , triggerAttrs :: Array (Tuple String String)  -- data-* on the trigger (e.g. accent-color)
  , portalAttrs :: Array (Tuple String String)   -- data-* on the content (theme re-application)
  , delayMs :: Int               -- hover-open delay (radix DEFAULT_DELAY_DURATION=700); focus opens instantly
  , ariaLabel :: String          -- aria-label on Content: overrides the role=tooltip VisuallyHidden copy's accessible name (ariaLabel||children); consumed, never spread onto the content node
  }

defaultInput :: Input
defaultInput =
  { open: Nothing
  , defaultOpen: false
  , side: Top
  , align: Center
  , offset: 4.0
  , padding: 8.0
  , style: defaultStyle
  , trigger: []
  , content: []
  , contentStyle: ""
  , arrow: []
  , triggerAttrs: []
  , portalAttrs: []
  , delayMs: 700
  , ariaLabel: ""
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
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String
  , arrow :: Array HH.PlainHTML
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentId :: String         -- generated on Initialize; trigger aria-describedby → content id
  , wasDelayed :: Boolean       -- the open path: hover (delayed-open) vs focus (instant-open)
  , delayMs :: Int              -- hover-open delay
  , pendingOpen :: Maybe Dom.TimeoutId       -- the live hover-open timer (cancel on early leave)
  , pendingSub :: Maybe H.SubscriptionId     -- the emitter subscription feeding `Opened` from that timer
  , ariaLabel :: String                      -- aria-label override for the role=tooltip copy
  }

data Action
  = Initialize
  | Receive Input
  | Show         -- pointer/hover enter → arm the delay timer (delayed-open after delayMs)
  | Opened       -- the hover-delay timer fired → actually open (delayed-open stateAttribute)
  | FocusShow    -- focus open → instant-open stateAttribute (wasOpenDelayedRef=false)
  | Hide
  | AfterOpen           -- after the open render flushed: position + portal
  | Reposition
  | EscapePressed

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-tooltip-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-tooltip-content"

arrowRef :: H.RefLabel
arrowRef = H.RefLabel "rdx-tooltip-arrow"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-tooltip-wrapper"

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

-- | radix's VisuallyHidden inline style (the screen-reader-only tooltip-role copy).
visuallyHiddenStyle :: String
visuallyHiddenStyle = "position: absolute; border: 0px; width: 1px; height: 1px; padding: 0px; margin: -1px; overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; overflow-wrap: normal;"

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
  , side: input.side
  , align: input.align
  , offset: input.offset
  , padding: input.padding
  , style: input.style
  , trigger: input.trigger
  , content: input.content
  , contentStyle: input.contentStyle
  , arrow: input.arrow
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
  , placedSide: input.side
  , placedAlign: input.align
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , contentId: ""
  , wasDelayed: false
  , delayMs: input.delayMs
  , pendingOpen: Nothing
  , pendingSub: Nothing
  , ariaLabel: input.ariaLabel
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
    -- the tri-state stateAttribute: instant-open (focus / skip-window) vs delayed-open (hover).
    stateAttr = if open then (if st.wasDelayed then "delayed-open" else "instant-open") else "closed"
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      ( [ HH.button
          -- NOTE: the tooltip trigger has NO type=button and its open state is "delayed-open"
          -- (radix Tooltip shows after a delay), matching the golden.
          ( [ HP.ref triggerRef
            , classes st.style.trigger
            , dataState stateAttr
            , HE.onMouseEnter \_ -> Show
            , HE.onMouseLeave \_ -> Hide
            , HE.onFocus \_ -> FocusShow
            , HE.onBlur \_ -> Hide
            -- ACTIVATING the trigger dismisses the tooltip: upstream onPointerDown→onClose
            -- (when open) and onClick composes onClose (tooltip.tsx:308-319) — a tooltip is a
            -- transient hint, so committing to the trigger (clicking it) hides it.
            , HE.onClick \_ -> Hide
            ] <> portalData st.triggerAttrs
            -- aria-describedby points at the content id ONLY while open (upstream:
            -- `context.open ? contentId : undefined`); when closed the attr is absent.
            <> (if open then [ aria "describedby" st.contentId ] else [])
            -- data-radix-popper-side/align are stamped by Popper.Anchor while the Popper subtree
            -- is mounted (open); absent at closed-rest, matching upstream's unmounted Popper.
            <> (if open then [ dataAttr "radix-popper-side" (sideName st.placedSide), dataAttr "radix-popper-align" (alignName st.placedAlign) ] else [])
          )
          (map HH.fromPlainHTML st.trigger)
      ]
      -- the popper WRAPPER (portal root) renders ONLY while open (Tooltip unmounts synchronously
      -- on hide — no exit linger), so at closed-rest there is no content node, matching upstream
      -- (which unmounts the Popper). finalize re-adopts the freshly-mounted wrapper on each open.
      <> ( if open then
      [ HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          -- position:fixed up front so the content shrink-wraps (max-content) at flip-measure.
          , HP.style "position: fixed;"
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , classes st.style.content
                , dataState stateAttr
                , dataAttr "side" (sideName st.placedSide)
                , dataAttr "align" (alignName st.placedAlign)
                , HP.style st.contentStyle
                ] <> portalData st.portalAttrs
              )
              -- the visible label, then the arrow, then a VisuallyHidden role=tooltip copy
              -- carrying the id (the trigger's aria-describedby target). Radix's a11y shape.
              ( map HH.fromPlainHTML st.content
                  <> (if null st.arrow then [] else [ HH.span [ HP.ref arrowRef, HP.style "position: absolute;" ] (map HH.fromPlainHTML st.arrow) ])
                  -- the role=tooltip accessible-name copy: `ariaLabel || children` (upstream
                  -- tooltip.tsx:570-572) — a non-empty ariaLabel replaces the content text.
                  <> [ HH.span [ HP.id st.contentId, role "tooltip", HP.style visuallyHiddenStyle ]
                         (if st.ariaLabel == "" then map HH.fromPlainHTML st.content else [ HH.text st.ariaLabel ]) ]
              )
          ]
      ] else [] )
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    cid <- useId
    H.modify_ _ { contentId = cid }
    -- START-OPEN: controlled `open`/`defaultOpen` true at mount renders the tooltip open
    -- immediately. Initialize only mints the id; it never arms the open envelope, so we
    -- arm the SAME dismissal/reposition subs + AfterOpen the open path uses — MINUS the
    -- ctrl change (already open) and the OpenChanged raise. `defaultOpen` → instant-open
    -- (wasOpenDelayedRef defaults false upstream), so wasDelayed stays false.
    st <- H.get
    when (current st.ctrl) do
      doc <- liftEffect (HTML.window >>= Window.document)
      win <- liftEffect Popper.windowTarget
      let docTarget = HTMLDocument.toEventTarget doc
      escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
      scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
      resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
      psid <- scheduleAfterOpen
      H.modify_ _ { subs = [ escSub, scrollSub, resizeSub ], postSub = Just psid }
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
      , arrow = input.arrow
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      , delayMs = input.delayMs
      , ariaLabel = input.ariaLabel
      }
  Show -> scheduleOpen
  FocusShow -> cancelPending *> openTooltip false
  Opened -> openTooltip true
  Hide -> cancelPending *> closeTooltip
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body. A
  -- tooltip never takes focus, so finalize never focuses.
  AfterOpen -> do
    reposition
    finalize true
  EscapePressed -> closeTooltip
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame).
  Reposition -> do
    reposition
    finalize false

-- | Hover-enter: arm the open. radix waits `delayMs` (DEFAULT_DELAY_DURATION=700) before
-- | showing on pointer, so a glance that brushes past the trigger never flashes the tooltip.
-- | `delayMs <= 0` opens synchronously (used by the deterministic gates). A re-entry while a
-- | timer is already pending is a no-op; an early leave cancels it (`cancelPending`).
scheduleOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
scheduleOpen = do
  st <- H.get
  when (not (current st.ctrl)) do
    case st.pendingOpen of
      Just _ -> pure unit            -- a timer is already counting down; leave it
      Nothing
        | st.delayMs <= 0 -> openTooltip true
        | otherwise -> do
            { emitter, listener } <- liftEffect HS.create
            sid <- H.subscribe (Opened <$ emitter)
            tid <- liftEffect (Dom.setTimeout st.delayMs (HS.notify listener unit))
            H.modify_ _ { pendingOpen = Just tid, pendingSub = Just sid }

-- | Cancel a pending hover-open: clear the wall-clock timer and drop its emitter subscription.
-- | Safe to call when nothing is pending (both refs `Nothing`). Run on every leave/focus/close
-- | so a timer can never fire after the intent that armed it is gone.
cancelPending :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
cancelPending = do
  st <- H.get
  for_ st.pendingOpen (liftEffect <<< Dom.clearTimeout)
  for_ st.pendingSub H.unsubscribe
  H.modify_ _ { pendingOpen = Nothing, pendingSub = Nothing }

openTooltip :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
openTooltip delayed = do
  cancelPending
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (the focused trigger) BEFORE opening, so no post-open
    -- `modify` is needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, restoreEl = mprev, wasDelayed = delayed }
    H.raise (OpenChanged true)
    -- dismissal (Escape only) + reposition subscriptions
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    psid <- scheduleAfterOpen
    H.modify_ _
      { subs = [ escSub, scrollSub, resizeSub ]
      , postSub = Just psid
      }

-- | Dispatch `AfterOpen` on the next animation frame (after the open render flushes).
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | On the next frame (after the placement modify's render re-parents the content),
-- | adopt the content into body. A tooltip never takes focus, so this only moves the
-- | node — it does not capture focus.
-- | Adopt the WRAPPER into body. A tooltip never takes focus and (unlike popover/dialog)
-- | radix renders NO focus-guard sentinels around it.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize _ = do
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  case mbody, mwrap of
    Just body, Just wrap ->
      liftEffect $ Portal.afterFrame (Portal.adopt body (HTMLElement.toElement wrap))
    _, _ -> pure unit

closeTooltip :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeTooltip = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing }
    H.raise (OpenChanged false)

-- | Position the WRAPPER, stamp the placement, and pin the arrow to the content edge.
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
      marrow <- H.getHTMLElementRef arrowRef
      for_ marrow \arrow ->
        liftEffect (Popper.positionArrow { anchor, floating, arrow, side: placed.placement.side, padding: st.padding })
    _, _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openTooltip true else closeTooltip
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))