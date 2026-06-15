-- | Hydrogen.Themes.HoverCard — the HOVER-INTENT anchored overlay (Bucket B).
-- |
-- | Upstream: radix-ui-themes `hover-card.tsx` / `hover-card.props.tsx` /
-- | `hover-card.css`. Like Tooltip it opens on HOVER after an `openDelay` (200ms)
-- | and closes after a `closeDelay` (150ms) — but the content is RICH and, crucially,
-- | the card STAYS OPEN while the pointer is over the CARD ITSELF. The hover-intent
-- | therefore tracks hovering of BOTH the trigger and the content: a `mouseleave`
-- | from the trigger that lands inside the card must NOT close it, and vice-versa.
-- | Closing only happens once the pointer has left BOTH for `closeDelay`.
-- |
-- | Anchored exactly like Popover: on open, measure the trigger's viewport rect
-- | (`Portal.anchorRect`) and place a `position: fixed` panel below it
-- | (side=bottom, align=start, sideOffset 8, maxWidth 480 — upstream's defaults).
-- | The panel is PORTALED to the body `.radix-themes` container (afterFrame re-adopt)
-- | so its fixed position escapes ancestor containing blocks. NON-modal: no
-- | scroll-lock, no backdrop. Escape (document keydown) also closes.
-- |
-- | DOM mirrors upstream: trigger is `a.rt-Text rt-reset rt-Link rt-HoverCardTrigger`
-- | (an inline link), content is `rt-PopperContent rt-HoverCardContent rt-r-size-2`
-- | with `data-state` / `data-side` / `data-align`.
-- |
-- | Hover-intent uses `MonadAff` + `H.fork`/`H.kill`: every enter/leave kills the
-- | pending timer fiber and (on leave) forks a fresh delayed close that only fires
-- | if, at the moment it elapses, neither the trigger nor the content is hovered.
module Hydrogen.Themes.HoverCard
  ( Input
  , component
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Effect.Aff (delay)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Themes.Prop (Prop(..), attrs)
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET

import Hydrogen.Themes.Portal as Portal

-- | The inline trigger label + the rich card heading/body copy.
type Input =
  { triggerLabel :: String
  , heading :: String
  , body :: String
  }

type State =
  { input :: Input
  , open :: Boolean
  , top :: Number
  , left :: Number
  , hoverTrigger :: Boolean
  , hoverContent :: Boolean
  -- the pending open/close timer fiber, so a fresh enter/leave can cancel it.
  , timer :: Maybe H.ForkId
  }

data Action
  = Initialize
  | EnterTrigger
  | LeaveTrigger
  | EnterContent
  | LeaveContent
  | OpenNow
  | CloseNow
  | KeyDown KE.KeyboardEvent

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "hovercard-trigger"

panelRef :: H.RefLabel
panelRef = H.RefLabel "hovercard-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

sideOffset :: Number
sideOffset = 8.0

openDelay :: Milliseconds
openDelay = Milliseconds 200.0

closeDelay :: Milliseconds
closeDelay = Milliseconds 150.0

component :: forall q o m. MonadAff m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input ->
        { input
        , open: false
        , top: 0.0
        , left: 0.0
        , hoverTrigger: false
        , hoverContent: false
        , timer: Nothing
        }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

-- | Cancel any pending open/close timer (idempotent).
cancelTimer :: forall o m. MonadAff m => H.HalogenM State Action () o m Unit
cancelTimer = do
  st <- H.get
  case st.timer of
    Just fid -> do
      H.kill fid
      H.modify_ _ { timer = Nothing }
    Nothing -> pure unit

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    doc <- liftEffect (window >>= Window.document)
    let target = HTMLDocument.toEventTarget doc
    void $ H.subscribe $ eventListener KET.keydown target (\e -> KeyDown <$> KE.fromEvent e)
    portalize

  EnterTrigger -> do
    cancelTimer
    H.modify_ _ { hoverTrigger = true }
    st <- H.get
    when (not st.open) do
      -- open-intent: after openDelay, open (unless the pointer has since left).
      fid <- H.fork do
        liftEffect (pure unit)
        H.liftAff (delay openDelay)
        st' <- H.get
        when (st'.hoverTrigger || st'.hoverContent) (handleAction OpenNow)
      H.modify_ _ { timer = Just fid }

  EnterContent -> do
    cancelTimer
    H.modify_ _ { hoverContent = true }

  LeaveTrigger -> do
    H.modify_ _ { hoverTrigger = false }
    scheduleClose

  LeaveContent -> do
    H.modify_ _ { hoverContent = false }
    scheduleClose

  OpenNow -> do
    H.modify_ _ { timer = Nothing }
    H.getHTMLElementRef triggerRef >>= case _ of
      Nothing -> pure unit
      Just he -> do
        r <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        H.modify_ _ { open = true, top = r.bottom + sideOffset, left = r.left }
        portalize

  CloseNow -> do
    -- only actually close if, now that the delay has elapsed, the pointer is over
    -- NEITHER the trigger nor the card (moving from one into the other keeps it open).
    st <- H.get
    H.modify_ _ { timer = Nothing }
    when (not st.hoverTrigger && not st.hoverContent) do
      H.modify_ _ { open = false }

  KeyDown ke ->
    when (KE.key ke == "Escape") do
      cancelTimer
      H.modify_ _ { open = false, hoverTrigger = false, hoverContent = false }

-- | Schedule a delayed close. The fork re-reads the hover flags at fire time, so an
-- | enter on the opposite element (which flips the flag back true) keeps it open.
scheduleClose :: forall o m. MonadAff m => H.HalogenM State Action () o m Unit
scheduleClose = do
  cancelTimer
  fid <- H.fork do
    H.liftAff (delay closeDelay)
    handleAction CloseNow
  H.modify_ _ { timer = Just fid }

portalize :: forall o m. MonadAff m => H.HalogenM State Action () o m Unit
portalize = do
  container <- liftEffect (Portal.ensureContainer portalRoot)
  H.getHTMLElementRef panelRef >>= case _ of
    Just he -> liftEffect (Portal.afterFrame (Portal.adopt container (HTMLElement.toElement he)))
    Nothing -> pure unit

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.span_
    [ trigger, panel ]
  where
  dataState b = if b then "open" else "closed"

  -- The trigger is an inline link (rt-Link), matching upstream's typical usage of a
  -- HoverCard around inline text. Real anchor; onMouseEnter/Leave drive hover-intent.
  trigger =
    HH.a
      ( attrs [ "rt-reset", "rt-Text", "rt-Link", "rt-HoverCardTrigger" ] [ Color "indigo" ]
          <>
            [ HP.ref triggerRef
            , HP.href "#"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-accent-color") ""
            , HE.onMouseEnter (\_ -> EnterTrigger)
            , HE.onMouseLeave (\_ -> LeaveTrigger)
            ]
      )
      [ HH.text st.input.triggerLabel ]

  panel =
    HH.div
      ( attrs [ "rt-PopperContent", "rt-HoverCardContent" ] [ Size "2" ]
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") "bottom"
            , HP.attr (HH.AttrName "data-align") "start"
            , HP.attr (HH.AttrName "role") "dialog"
            , HP.style (positionStyle st)
            , HE.onMouseEnter (\_ -> EnterContent)
            , HE.onMouseLeave (\_ -> LeaveContent)
            ]
      )
      [ HH.p (attrs [ "rt-Heading" ] [ Size "3", Weight "bold", Mb "1" ]) [ HH.text st.input.heading ]
      , HH.p (attrs [ "rt-Text" ] [ Size "2" ]) [ HH.text st.input.body ]
      ]

positionStyle :: State -> String
positionStyle st =
  if st.open then
    "position: fixed; max-width: 480px; top: " <> show st.top <> "px; left: " <> show st.left <> "px"
  else
    "display: none"
