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
-- |   * Anchored like Popover: on open we measure the trigger's viewport rect
-- |     (`Portal.anchorRect`) and place the panel BELOW it (top = trigger.bottom + 4,
-- |     left = trigger.left), data-side="bottom". (Upstream defaults side=top;
-- |     placing above would need the panel height pre-measured without an overlapping
-- |     placeholder — an off-screen pre-measure — deferred. Below is robust: the panel
-- |     never sits under the pointer, so it can't self-trigger a mouseleave→close.)
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
  , pending :: Maybe H.ForkId
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

-- | Hover-intent open delay.
openDelay :: Milliseconds
openDelay = Milliseconds 200.0

component :: forall q o m. MonadAff m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, top: 0.0, left: 0.0, pending: Nothing }
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

  -- mouseenter: fork a delayed open. Store the fiber so mouseleave can cancel it
  -- before it fires (hover-intent — a fleeting pass never opens the tooltip).
  HoverEnter -> do
    st <- H.get
    case st.pending of
      Just _ -> pure unit
      Nothing -> do
        fid <- H.fork do
          liftAffDelay openDelay
          handleAction OpenNow
        H.modify_ _ { pending = Just fid }

  -- mouseleave: cancel the pending open (if still pending) and close.
  HoverLeave -> do
    st <- H.get
    case st.pending of
      Just fid -> H.kill fid
      Nothing -> pure unit
    H.modify_ _ { pending = Nothing }
    handleAction CloseD

  OpenNow ->
    H.getHTMLElementRef triggerRef >>= case _ of
      Nothing -> H.modify_ _ { pending = Nothing }
      Just he -> do
        r <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        -- Place the tooltip BELOW the trigger (side=bottom): the panel never sits
        -- under the pointer (which is on the trigger), so it can't trigger a
        -- mouseleave→close on open. (Upstream defaults side=top; placing above would
        -- need the panel height measured WITHOUT an overlapping placeholder — an
        -- off-screen pre-measure — deferred. Below is robust + a valid tooltip side.)
        H.modify_ _ { open = true, pending = Nothing, left = r.left, top = r.bottom + sideOffset }
        portalize

  CloseD ->
    H.modify_ _ { open = false }

  KeyDown ke ->
    when (KE.key ke == "Escape") do
      st <- H.get
      case st.pending of
        Just fid -> H.kill fid
        Nothing -> pure unit
      H.modify_ _ { pending = Nothing }
      handleAction CloseD

-- | Run an Aff delay inside HalogenM.
liftAffDelay :: forall o m. MonadAff m => Milliseconds -> H.HalogenM State Action () o m Unit
liftAffDelay ms = H.liftAff (delay ms)

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
            , HP.attr (HH.AttrName "data-side") "bottom"
            , HP.style (positionStyle st)
            ]
      )
      [ HH.span (attrs [ "rt-TooltipText" ] []) [ HH.text st.input.content ] ]

positionStyle :: State -> String
positionStyle st =
  if st.open then
    "position: fixed; max-width: 360px; top: " <> show st.top <> "px; left: " <> show st.left <> "px"
  else
    "display: none"
