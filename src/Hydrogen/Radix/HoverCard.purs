-- | Hydrogen.Radix.HoverCard — rich floating content opened by HOVERING a
-- | trigger (radix `HoverCard`).
-- |
-- | A `Popover` whose open/close is driven by pointer/focus rather than click:
-- | the card is for previewing content (a link card, a user card) and so its
-- | content is rich (can contain links). It composes:
-- |   * `ControllableState` open;
-- |   * `Float.Popper.position` on open + on scroll/resize (anchor = trigger ref,
-- |     floating = content ref) → applies coords + yields the resolved placement,
-- |     stamped as `data-side`/`data-align`;
-- |   * `DismissableLayer` — Escape only (document keydown); subscription set up on
-- |     open, torn down on close. NO pointer-outside dismiss (radix HoverCard has
-- |     none), NO focus trap.
-- |   * portal-to-body: the content is appended to `document.body` after open so
-- |     its `position:fixed` escapes any ancestor stacking/overflow/transform
-- |     context (mirrors the Popover template; STR-335 floating template).
-- |   * the stable surface: data-state/data-side/data-align on the content.
-- |
-- | Hover semantics: BOTH the trigger and the content carry
-- | `onMouseEnter → Show` / `onMouseLeave → Hide`. Because the content keeps the
-- | card open while hovered, moving the mouse from the trigger into the card does
-- | not close it. The trigger additionally opens on focus and closes on blur (so
-- | it is keyboard-reachable).
-- |
-- | v1 (by feel): non-modal, no Presence exit animation (the content node is
-- | ALWAYS mounted, hidden with display:none when closed — so Halogen never
-- | removes it and portaling it into body is safe). The content id is generated
-- | per mount (Behavior.Id) so instances don't collide; the fixed RefLabels stay
-- | single-instance. HoverCard does NOT trap or move focus, so the portal finalize
-- | re-asserts placement without focusing.
-- | NOTE: radix has open/close *delays* (openDelay/closeDelay) so brushing past the
-- | trigger doesn't flash the card; we skip them for v1 (open/close are immediate).
module Hydrogen.Radix.HoverCard
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
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName)
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
  { trigger: cn "rdx-hover-card-trigger"
  , content: cn "rdx-hover-card-content"
  }

type Input =
  { open :: Maybe Boolean       -- controlled
  , defaultOpen :: Boolean      -- uncontrolled initial
  , side :: Side                -- preferred side
  , align :: Align              -- alignment along the side
  , offset :: Number            -- gap from the trigger
  , padding :: Number           -- min gap from viewport edges
  , style :: Style
  , triggerHref :: String       -- the trigger is an inline link (radix HoverCard semantics)
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String      -- extra inline style on the content (e.g. --max-width)
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
  , triggerHref: "#"
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
  , triggerHref :: String
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (whatever was focused before open)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen
  , contentId :: String         -- generated on Initialize (unique content id)
  }

data Action
  = Initialize
  | Receive Input
  | Show
  | Hide
  | AfterOpen           -- after the open render flushed: position + portal
  | EscapePressed
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-hover-card-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-hover-card-content"

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
  , triggerHref: input.triggerHref
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
      -- The trigger is an inline <a> (radix HoverCard wraps a link), not a button —
      -- so it sits inline in prose and matches the rt-HoverCardTrigger/rt-Link look.
      [ HH.a
          [ HP.href st.triggerHref
          , HP.ref triggerRef
          , classes st.style.trigger
          -- radix's Link always carries data-accent-color; its empty value means
          -- "inherit the theme accent". rt-Link's color rule keys off the attribute's
          -- PRESENCE (without it the link falls back to gray-12). Inert without themes CSS.
          , dataAttr "accent-color" ""
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
          , classes st.style.content
          , dataState (if open then "open" else "closed")
          , dataAttr "side" (sideName st.placedSide)
          , dataAttr "align" (alignName st.placedAlign)
          -- CONSTANT style string (contentStyle is from input) so Halogen never clobbers
          -- the left/top Popper applies via FFI.
          , HP.style ("position:fixed;left:0;top:0;" <> st.contentStyle <> (if open then "" else "display:none;"))
          , HE.onMouseEnter \_ -> Show
          , HE.onMouseLeave \_ -> Hide
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
      , triggerHref = input.triggerHref
      , trigger = input.trigger
      , content = input.content
      , contentStyle = input.contentStyle
      }
  Show -> openCard
  Hide -> closeCard
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body. NO
  -- focus — HoverCard does not trap or move focus.
  AfterOpen -> do
    reposition
    finalize
  EscapePressed -> closeCard
  -- scroll/resize: re-place, then re-assert the portal (the placement modify re-parents
  -- the content back out of body, so re-adopt on the following frame).
  Reposition -> do
    reposition
    finalize

openCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openCard = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target BEFORE opening, so no post-open `modify` is needed for
    -- it (which would un-portal the content).
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
-- | adopt the content into body. HoverCard does not move focus, so no captureFocus.
finalize :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finalize = do
  mbody <- liftEffect Portal.documentBody
  mc <- H.getHTMLElementRef contentRef
  case mbody, mc of
    Just body, Just content ->
      liftEffect $ Portal.afterFrame (Portal.adopt body (HTMLElement.toElement content))
    _, _ -> pure unit

closeCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeCard = do
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
    if v then openCard else closeCard
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
