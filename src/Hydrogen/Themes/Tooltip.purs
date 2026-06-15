-- | Hydrogen.Themes.Tooltip — the HOVER-triggered floating label (Bucket B).
-- |
-- | Upstream `tooltip.tsx` / `tooltip.props.tsx` / `tooltip.css`: a Radix
-- | `Tooltip.Content` (`rt-TooltipContent`, maxWidth 360px, role="tooltip",
-- | sideOffset 4, side=top) wrapping a `<Text as="p" class="rt-TooltipText"
-- | size="1">` with the content. Unlike Popover (click-toggle), a Tooltip is
-- | driven by HOVER with a short open delay (hover-intent):
-- |   * trigger `mouseenter` FORKS a delayed-open fiber (~200ms). `mouseleave`
-- |     KILLs that fiber (if it hasn't fired yet) AND closes — so a fleeting pass
-- |     over the trigger never opens the tooltip.
-- |   * Anchored + collision-aware (`Hydrogen.Themes.Floating` + `Portal.solveAnchored`):
-- |     on open we measure the trigger + the panel (visibility:hidden → real size) +
-- |     the viewport, then place the tooltip BELOW the trigger, flipping above near
-- |     the bottom edge. (Below, not upstream's side=top, because a panel just above a
-- |     small trigger lands near the pointer and flickers enter/leave — radix avoids
-- |     that with pointer-events handling on the content; deferred.)
-- |   * Escape (document keydown) also closes; non-modal, no scroll-lock, no
-- |     backdrop. Panel is PORTALED to the body container (afterFrame re-adopt),
-- |     so the fixed position escapes ancestor containing blocks.
-- |   * NEVER click-toggled: the trigger has NO onClick open.
module Hydrogen.Themes.Tooltip
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
import Hydrogen.Themes.Floating (measureSize, panelStyle)
import Hydrogen.Themes.Prop (attrs)
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET

import Hydrogen.Themes.Portal as Portal

-- | The trigger label + the tooltip text.
type Input =
  { triggerLabel :: String
  , content :: String
  }

type State =
  { input :: Input
  , open :: Boolean
  , top :: Number
  , left :: Number
  , side :: String
  , hovering :: Boolean -- pointer currently over the trigger
  , timer :: Maybe H.ForkId -- the pending delayed-open fiber
  }

data Action
  = Initialize
  | HoverEnter
  | HoverLeave
  | OpenNow
  | CloseD
  | KeyDown KE.KeyboardEvent

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "tooltip-trigger"

panelRef :: H.RefLabel
panelRef = H.RefLabel "tooltip-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

-- | Upstream side=top sideOffset 4.
sideOffset :: Number
sideOffset = 4.0

-- | Placed BELOW the trigger (collision-aware: flips above near the bottom edge,
-- | shifts in near a side edge). Below — not upstream's side=top — because a panel
-- | just above a small trigger lands near the pointer and flickers enter/leave;
-- | radix avoids that with pointer-events management on the content (deferred).
placement :: Portal.Anchored
placement = { preferTop: false, align: "start", offset: sideOffset, pad: 8.0 }

-- | Hover-intent open delay.
openDelay :: Milliseconds
openDelay = Milliseconds 200.0

component :: forall q o m. MonadAff m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, top: 0.0, left: 0.0, side: "bottom", hovering: false, timer: Nothing }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    doc <- liftEffect (window >>= Window.document)
    let target = HTMLDocument.toEventTarget doc
    void $ H.subscribe $ eventListener KET.keydown target (\e -> KeyDown <$> KE.fromEvent e)
    portalize

  -- mouseenter: on a GENUINE enter (not already hovering — the browser can emit a
  -- burst of enters), mark hovering + fork a delayed open. The fork re-reads
  -- `hovering` at fire time (flag-based hover-intent, like HoverCard); the guard
  -- stops repeated enters from cancelling + re-forking (which never lets it fire).
  HoverEnter -> do
    st <- H.get
    when (not st.hovering) do
      H.modify_ _ { hovering = true }
      when (not st.open) do
        fid <- H.fork do
          liftAffDelay openDelay
          st' <- H.get
          when st'.hovering (handleAction OpenNow)
        H.modify_ _ { timer = Just fid }

  -- mouseleave: clear hovering (so a pending fork won't open) and close.
  HoverLeave -> do
    H.modify_ _ { hovering = false }
    cancelTimer
    handleAction CloseD

  OpenNow ->
    H.getHTMLElementRef triggerRef >>= case _ of
      Nothing -> pure unit
      Just he -> do
        -- Measure the panel (visibility:hidden → real size) + the trigger + viewport,
        -- then solve placement: side=top preferred, flipping below near the top edge.
        -- The panel is invisible until placed, so there's no overlapping-placeholder
        -- flicker (which used to self-trigger a mouseleave→close).
        anchor <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        panel <- measureSize panelRef
        vp <- liftEffect Portal.viewportSize
        let p = Portal.solveAnchored placement anchor panel vp
        H.modify_ _ { open = true, timer = Nothing, top = p.top, left = p.left, side = p.side }
        portalize

  CloseD ->
    H.modify_ _ { open = false }

  KeyDown ke ->
    when (KE.key ke == "Escape") do
      cancelTimer
      H.modify_ _ { hovering = false, open = false }

-- | Run an Aff delay inside HalogenM.
liftAffDelay :: forall o m. MonadAff m => Milliseconds -> H.HalogenM State Action () o m Unit
liftAffDelay ms = H.liftAff (delay ms)

-- | Cancel the pending delayed-open fiber, if any.
cancelTimer :: forall o m. MonadAff m => H.HalogenM State Action () o m Unit
cancelTimer = do
  st <- H.get
  case st.timer of
    Just fid -> do
      H.kill fid
      H.modify_ _ { timer = Nothing }
    Nothing -> pure unit

portalize :: forall o m. MonadAff m => H.HalogenM State Action () o m Unit
portalize = do
  container <- liftEffect (Portal.ensureContainer portalRoot)
  H.getHTMLElementRef panelRef >>= case _ of
    Just he -> liftEffect (Portal.afterFrame (Portal.adopt container (HTMLElement.toElement he)))
    Nothing -> pure unit

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div_
    [ trigger, panel ]
  where
  dataState b = if b then "delayed-open" else "closed"

  trigger =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] []
          <>
            [ HP.ref triggerRef
            , HP.type_ HP.ButtonButton
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HE.onMouseEnter (\_ -> HoverEnter)
            , HE.onMouseLeave (\_ -> HoverLeave)
            ]
      )
      [ HH.text st.input.triggerLabel ]

  panel =
    HH.div
      ( attrs [ "rt-TooltipContent" ] []
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "role") "tooltip"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") st.side
            , HP.style (positionStyle st)
            ]
      )
      [ HH.span (attrs [ "rt-TooltipText" ] []) [ HH.text st.input.content ] ]

positionStyle :: State -> String
positionStyle st = panelStyle st.open st.top st.left "360px"
