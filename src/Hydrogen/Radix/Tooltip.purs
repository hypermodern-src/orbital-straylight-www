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
-- |   * the stable surface: aria-describedby on the trigger → content id,
-- |     data-state/data-side/data-align on the content, role="tooltip".
-- |
-- | v1 (by feel): no open/close delay (`delayMs` is a follow-up — show/hide fire
-- | immediately), no Presence exit animation (mount/unmount), no portal (content is
-- | position:fixed in place). The content id is generated per mount (Behavior.Id) so
-- | multiple instances don't collide; the fixed RefLabels are still single-instance.
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
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), cn, classes, dataState, dataAttr, sideName, alignName, aria, role)
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
  , contentId :: String         -- generated on Initialize; trigger aria-describedby → content id
  }

data Action
  = Initialize
  | Receive Input
  | Show
  | Hide
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
          , aria "describedby" st.contentId
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
            , role "tooltip"
            , classes st.style.content
            , dataState "open"
            , dataAttr "side" (sideName st.placedSide)
            , dataAttr "align" (alignName st.placedAlign)
            , HP.style "position:fixed;left:0;top:0;"
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
  Show -> openTooltip
  Hide -> closeTooltip
  EscapePressed -> closeTooltip
  Reposition -> reposition

openTooltip :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openTooltip = do
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

closeTooltip :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeTooltip = do
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
    if v then openTooltip else closeTooltip
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
