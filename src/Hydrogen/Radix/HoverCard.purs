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
-- | Exit animation (STR-335): non-modal, NO focus guards / envelope. On close the
-- | popper-wrapper + content STAY MOUNTED with `data-state=closed` (the wrapper keeps
-- | its out-of-band Popper coords, the content keeps data-side/align) until the content's
-- | exit animation (`rt-slide-to-* , rt-fade-out`) ends, THEN the wrapper unmounts —
-- | mirroring radix `Presence`. If the content has no running exit animation the close
-- | is immediate. This is the lightest of the Presence kinds: no scroll-lock, no focus
-- | guards, no hideOthers — just keep the popper node alive through the exit, then drop it.
-- | The content id is generated per mount (Behavior.Id) so instances don't collide; the
-- | fixed RefLabels stay single-instance. HoverCard does NOT trap or move focus, so the
-- | portal finalize re-asserts placement without focusing.
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
import Hydrogen.Radix.Behavior.FocusScope (tabbables)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName)
import Web.DOM.Element (setAttribute) as Element
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
  , wrapperClass :: ClassNames  -- the inline prose wrapper around the trigger (e.g. rt-Text)
  , proseBefore :: Array HH.PlainHTML  -- text before the trigger link, inside the wrapper
  , proseAfter :: Array HH.PlainHTML   -- text after the trigger link
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String      -- the content's CONSTANT style (--max-width + var aliases)
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
  , triggerHref: "#"
  , wrapperClass: cn ""
  , proseBefore: []
  , proseAfter: []
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
  , triggerHref :: String
  , wrapperClass :: ClassNames
  , proseBefore :: Array HH.PlainHTML
  , proseAfter :: Array HH.PlainHTML
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , contentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (whatever was focused before open)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen / AfterClose
  , animSub :: Maybe H.SubscriptionId  -- content `animationend` subscription during exit
  , contentId :: String         -- generated on Initialize (unique content id)
  }

data Action
  = Initialize
  | Receive Input
  | Show
  | Hide
  | AfterOpen           -- after the open render flushed: position + portal
  | AfterClose          -- after the closing render flushed: re-portal + arm exit animation
  | AnimDone            -- the content exit animation finished: finishExit + unmount
  | EscapePressed
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-hover-card-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-hover-card-content"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-hover-card-wrapper"

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
  , triggerHref: input.triggerHref
  , wrapperClass: input.wrapperClass
  , proseBefore: input.proseBefore
  , proseAfter: input.proseAfter
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
      -- the trigger is an inline <a> (radix HoverCard wraps a link) sitting inside a prose
      -- wrapper span (e.g. rt-Text) with text before/after — matching the upstream tree.
      ( [ HH.span [ classes st.wrapperClass ]
            ( map HH.fromPlainHTML st.proseBefore
                <> [ HH.a
                      ( [ HP.href st.triggerHref
                        , HP.ref triggerRef
                        , classes st.style.trigger
                        , dataState (if open then "open" else "closed")
                        , dataAttr "radix-popper-side" (sideName st.placedSide)
                        , dataAttr "radix-popper-align" (alignName st.placedAlign)
                        , HE.onMouseEnter \_ -> Show
                        , HE.onMouseLeave \_ -> Hide
                        , HE.onFocus \_ -> Show
                        , HE.onBlur \_ -> Hide
                        ] <> portalData st.triggerAttrs
                      )
                      (map HH.fromPlainHTML st.trigger)
                  ]
                <> map HH.fromPlainHTML st.proseAfter
            )
        ]
      -- the popper WRAPPER (portal root); content statically inside, positioned by Popper.
      -- Rendered while `isRendered presence` (Open OR Closing): on close it LINGERS — the
      -- wrapper keeps its out-of-band Popper coords (rendered style stays the constant
      -- `position: fixed;` so Halogen never clobbers them) and the content flips to
      -- data-state=closed for its exit animation, then unmounts at Closed.
        <> (if isRendered st.presence then [ wrapperContent st ] else [])
      )

-- | The popper WRAPPER + content. Mounted while `isRendered presence`. The wrapper's rendered
-- | inline style is the CONSTANT `position: fixed;` — Popper writes the solved left/top/transform
-- | and `--radix-popper-*` vars OUT OF BAND, and a constant rendered string keeps Halogen from
-- | re-patching (clobbering) them across the Open→Closing render. The content carries the exit
-- | animation (rt-slide-to-*/rt-fade-out on data-state=closed + data-side).
wrapperContent :: forall m. State -> H.ComponentHTML Action () m
wrapperContent st =
  HH.div
    [ HP.ref wrapperRef
    , dataAttr "radix-popper-content-wrapper" ""
    , HP.style "position: fixed;"
    ]
    [ HH.div
        ( [ HP.ref contentRef
          , classes st.style.content
          , dataState (dataStateOf st.presence)
          , dataAttr "side" (sideName st.placedSide)
          , dataAttr "align" (alignName st.placedAlign)
          , HP.style st.contentStyle
          , HE.onMouseEnter \_ -> Show
          , HE.onMouseLeave \_ -> Hide
          ] <> portalData st.portalAttrs
        )
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
      , wrapperClass = input.wrapperClass
      , proseBefore = input.proseBefore
      , proseAfter = input.proseAfter
      , trigger = input.trigger
      , content = input.content
      , contentStyle = input.contentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      }
  Show -> openCard
  Hide -> closeCard
  -- after the open render flushed: position the wrapper, then portal it into body + add the
  -- focus-guard sentinels (HoverCard, like popover, brackets the body). NO focus move.
  AfterOpen -> do
    reposition
    -- a hover-card is a PREVIEW, not a focus target: remove every tabbable content descendant
    -- from the tab order (upstream getTabbableNodes → setAttribute tabindex -1). The trigger
    -- itself stays focusable (it's outside the content).
    removeContentFromTabOrder
    finalize true
  -- runs on the frame after the CLOSING render flushed. The wrapper is still mounted (Presence
  -- Closing) with the content at data-state=closed; re-adopt it into body (Halogen re-parents
  -- the portaled node under the component root on every patch) and arm the exit: if the content
  -- has a running CSS exit animation, finishClose when `animationend` fires; otherwise finishClose
  -- now (no animation ⇒ immediate unmount, like radix). No envelope/guards to release.
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
    if armed then
      -- re-adopt the wrapper into body as the LAST effect (after the animSub modify re-render),
      -- so no subsequent render moves it out (mirrors AfterOpen's "adopt last" discipline).
      finalize false
    else finishClose
  AnimDone -> finishClose
  EscapePressed -> closeCard
  -- scroll/resize: re-place + re-assert the portal (no guards re-add, no focus).
  Reposition -> do
    reposition
    finalize false

openCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openCard = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target BEFORE opening, so no post-open `modify` is needed for
    -- it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    -- re-opening cancels any in-flight exit (the wrapper is still mounted/Closing).
    for_ st.animSub H.unsubscribe
    H.modify_ _ { ctrl = (change true st.ctrl).next, presence = Open, animSub = Nothing, restoreEl = mprev }
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

-- | Remove every tabbable descendant of the content from the tab order (tabindex=-1), so the
-- | card's links/buttons are not reachable by Tab — a hover-card previews, it never owns focus.
-- | Mirrors upstream's getTabbableNodes(content).forEach(setAttribute 'tabindex' '-1').
removeContentFromTabOrder :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
removeContentFromTabOrder = do
  mcontent <- H.getHTMLElementRef contentRef
  for_ mcontent \content -> do
    ts <- liftEffect (tabbables content)
    for_ ts \el ->
      liftEffect (Element.setAttribute "tabindex" "-1" (HTMLElement.toElement el))

-- | Adopt the WRAPPER into body. HoverCard does not trap or move focus and (like tooltip)
-- | radix renders NO focus-guard sentinels around it.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize _ = do
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  case mbody, mwrap of
    Just body, Just wrap ->
      liftEffect $ Portal.afterFrame (Portal.adopt body (HTMLElement.toElement wrap))
    _, _ -> pure unit

-- | Begin the close: flip controllable + Presence to Closing (the wrapper stays MOUNTED with
-- | the content at data-state=closed, still portaled in body), tear down the open-time
-- | scroll/resize/escape subscriptions, restore focus, and schedule AfterClose to arm the exit
-- | animation on the next frame. The actual unmount happens at AnimDone (or immediately, no anim).
closeCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeCard = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, presence = present false st.presence, restoreEl = Nothing, subs = [], postSub = Nothing }
    H.raise (OpenChanged false)
    psid <- scheduleAfterClose
    H.modify_ _ { postSub = Just psid }

-- | Dispatch `AfterClose` on the next animation frame (after the closing render flushes).
scheduleAfterClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterClose = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterClose <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | The exit animation finished (or there was none): drop the wrapper (Presence Closing →
-- | Closed unmounts it) and clear the exit subscriptions. No envelope/guards to tear down.
finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  H.modify_ _ { presence = finishExit st.presence, animSub = Nothing, postSub = Nothing }

-- | Position the WRAPPER and stamp the resolved placement for data-side/align.
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
    if v then openCard else closeCard
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
