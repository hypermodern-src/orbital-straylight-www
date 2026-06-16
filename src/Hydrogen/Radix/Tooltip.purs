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

import Data.Foldable (for_, traverse_)
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
  , contentStyle :: String      -- extra inline style on the content (e.g. --max-width)
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
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentId :: String         -- generated on Initialize; trigger aria-describedby → content id
  }

data Action
  = Initialize
  | Receive Input
  | Show
  | Hide
  | AfterOpen           -- after the open render flushed: position + portal
  | Reposition
  | EscapePressed

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-tooltip-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-tooltip-content"

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
  , placedSide: input.side
  , placedAlign: input.align
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , contentId: ""
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div_
      [ HH.button
          [ HP.type_ HP.ButtonButton
          , HP.ref triggerRef
          , classes st.style.trigger
          , aria "describedby" st.contentId
          , dataState (if open then "open" else "closed")
          , HE.onMouseEnter \_ -> Show
          , HE.onMouseLeave \_ -> Hide
          , HE.onFocus \_ -> Show
          , HE.onBlur \_ -> Hide
          ]
          (map HH.fromPlainHTML st.trigger)
      -- content is ALWAYS mounted (hidden when closed) so Halogen never removes the
      -- node — only patches it — which makes adopting it into body safe. The open-state
      -- style string is CONSTANT, so Halogen won't rewrite it on re-render and clobber
      -- the left/top Popper applies via FFI; closing adds display:none.
      , HH.div
          [ HP.ref contentRef
          , HP.id st.contentId
          , role "tooltip"
          , classes st.style.content
          , dataState (if open then "open" else "closed")
          , dataAttr "side" (sideName st.placedSide)
          , dataAttr "align" (alignName st.placedAlign)
          -- CONSTANT style string (contentStyle is from input) so Halogen never clobbers
          -- the left/top Popper applies via FFI.
          , HP.style ("position:fixed;left:0;top:0;" <> st.contentStyle <> (if open then "" else "display:none;"))
          ]
          (map HH.fromPlainHTML st.content)
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
      }
  Show -> openTooltip
  Hide -> closeTooltip
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body. A
  -- tooltip never takes focus, so finalize never focuses.
  AfterOpen -> do
    reposition
    finalize
  EscapePressed -> closeTooltip
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame).
  Reposition -> do
    reposition
    finalize

openTooltip :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openTooltip = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (the focused trigger) BEFORE opening, so no post-open
    -- `modify` is needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    H.modify_ _ { ctrl = (change true st.ctrl).next, restoreEl = mprev }
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
finalize :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finalize = do
  mbody <- liftEffect Portal.documentBody
  mc <- H.getHTMLElementRef contentRef
  case mbody, mc of
    Just body, Just content ->
      liftEffect $ Portal.afterFrame do
        Portal.adopt body (HTMLElement.toElement content)
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

-- | Measure + solve + apply, and stamp the resolved placement for data-side/align.
reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  manchor <- H.getHTMLElementRef triggerRef
  mfloat <- H.getHTMLElementRef contentRef
  case manchor, mfloat of
    Just anchor, Just floating -> do
      placed <- liftEffect (Popper.position
        { anchor, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
    _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openTooltip else closeTooltip
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))