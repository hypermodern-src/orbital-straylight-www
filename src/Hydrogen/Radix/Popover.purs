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
-- | v1 (by feel): non-modal, no Presence exit animation (mount/unmount), no portal
-- | (content is position:fixed in place), single instance per page (fixed ids).
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
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName, aria)
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
  , contentStyle :: String      -- extra inline style on the content (e.g. --width/--max-width)
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
  , contentNode :: Maybe Node
  , contentId :: String  -- generated on Initialize; trigger aria-controls target + content id
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | EscapePressed
  | PointerDown Event
  | ContentKeyDown KE.KeyboardEvent
  | Reposition

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-popover-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-popover-content"

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
  , contentNode: Nothing
  , contentId: ""
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div_
      [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , classes st.style.trigger
            , aria "expanded" (if open then "true" else "false")
            , aria "haspopup" "dialog"
            , dataState (if open then "open" else "closed")
            , HE.onClick \_ -> TriggerClicked
            ]
              <> (if open then [ aria "controls" st.contentId ] else [])
          )
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
          , HP.tabIndex (-1)
          -- the style string stays CONSTANT across renders (contentStyle is from input) so
          -- Halogen never rewrites it and clobbers the left/top Popper applies via FFI.
          , HP.style ("position:fixed;left:0;top:0;" <> st.contentStyle <> (if open then "" else "display:none;"))
          , HE.onKeyDown ContentKeyDown
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
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closePopover else openPopover
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body + focus.
  AfterOpen -> do
    reposition
    finalize true
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
    psid <- scheduleAfterOpen
    H.modify_ _
      { contentNode = mcNode
      , subs = [ escSub, ptrSub, scrollSub, resizeSub ]
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
-- | adopt the content into body — and, on open, focus into it AFTER the move so the
-- | appendChild doesn't blur it.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  mbody <- liftEffect Portal.documentBody
  mc <- H.getHTMLElementRef contentRef
  case mbody, mc of
    Just body, Just content ->
      liftEffect $ Portal.afterFrame do
        Portal.adopt body (HTMLElement.toElement content)
        when focusToo (void (captureFocus content))
    _, _ -> pure unit

closePopover :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closePopover = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing }
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
    if v then openPopover else closePopover
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
