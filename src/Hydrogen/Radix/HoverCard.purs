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
-- |   * the stable surface: data-state/data-side/data-align on the content.
-- |
-- | Hover semantics: BOTH the trigger and the content carry
-- | `onMouseEnter → Show` / `onMouseLeave → Hide`. Because the content keeps the
-- | card open while hovered, moving the mouse from the trigger into the card does
-- | not close it. The trigger additionally opens on focus and closes on blur (so
-- | it is keyboard-reachable).
-- |
-- | v1 (by feel): non-modal, no Presence exit animation (mount/unmount), no portal
-- | (content is position:fixed in place). The content id is generated per mount
-- | (Behavior.Id) so instances don't collide; the fixed RefLabels stay single-instance.
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

import Data.Foldable (traverse_)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName)
import Web.Event.Event (EventType(..))
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
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
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
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
  , placedSide :: Side          -- resolved placement (for data-side)
  , placedAlign :: Align
  , subs :: Array H.SubscriptionId
  , contentId :: String         -- generated on Initialize (unique content id)
  }

data Action
  = Initialize
  | Receive Input
  | Show
  | Hide
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
  , trigger: input.trigger
  , content: input.content
  , placedSide: input.side
  , placedAlign: input.align
  , subs: []
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
          , dataState (if open then "open" else "closed")
          , HE.onMouseEnter \_ -> Show
          , HE.onMouseLeave \_ -> Hide
          , HE.onFocus \_ -> Show
          , HE.onBlur \_ -> Hide
          ]
          (map HH.fromPlainHTML st.trigger)
      , if open then
          HH.div
            [ HP.ref contentRef
            , HP.id st.contentId
            , classes st.style.content
            , dataState "open"
            , dataAttr "side" (sideName st.placedSide)
            , dataAttr "align" (alignName st.placedAlign)
            , HP.style "position:fixed;left:0;top:0;"
            , HE.onMouseEnter \_ -> Show
            , HE.onMouseLeave \_ -> Hide
            ]
            (map HH.fromPlainHTML st.content)
        else HH.text ""
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
      }
  Show -> openCard
  Hide -> closeCard
  EscapePressed -> closeCard
  Reposition -> reposition

openCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openCard = do
  st <- H.get
  when (not (current st.ctrl)) do
    H.modify_ _ { ctrl = (change true st.ctrl).next }
    H.raise (OpenChanged true)
    reposition
    -- dismissal (Escape only) + reposition subscriptions
    doc <- liftEffect (HTML.window >>= Window.document)
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    H.modify_ _ { subs = [ escSub, scrollSub, resizeSub ] }

closeCard :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeCard = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    H.modify_ _ { ctrl = (change false st.ctrl).next, subs = [] }
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
