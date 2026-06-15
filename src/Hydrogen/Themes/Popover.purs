-- | Hydrogen.Themes.Popover — the ANCHORED-overlay reference (Bucket B).
-- |
-- | Where Dialog/AlertDialog are viewport-centered modals, the floating family
-- | (Popover, DropdownMenu, HoverCard, Tooltip, ContextMenu, Select) anchors a
-- | panel to its trigger. This module establishes that pattern + the floating
-- | primitive the rest reuse:
-- |   * On open, measure the trigger's viewport rect (`Portal.anchorRect`) and place
-- |     a `position: fixed` panel below it (side=bottom, align=start, sideOffset 8 —
-- |     upstream's Popover defaults). Collision flipping is the documented next step.
-- |   * NON-modal: no scroll-lock, no dimming backdrop. Closes on Escape (document
-- |     keydown) or an OUTSIDE click (document click + `Portal.containsTarget` over
-- |     the panel and the trigger — an inside click keeps it open).
-- |   * Panel is PORTALED to the body `.radix-themes` container (same afterFrame
-- |     re-adopt as Dialog), so its fixed position escapes ancestor containing blocks.
-- |   * DOM mirrors upstream `popover.tsx`: `rt-PopperContent rt-PopoverContent
-- |     rt-r-size-2` with `data-state` / `data-side` / `data-align`.
module Hydrogen.Themes.Popover
  ( Input
  , component
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
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
import Web.UIEvent.MouseEvent.EventTypes as MET

import Hydrogen.Themes.Portal as Portal

-- | The trigger label + the panel's body copy.
type Input =
  { triggerLabel :: String
  , body :: String
  }

type State =
  { input :: Input
  , open :: Boolean
  , top :: Number
  , left :: Number
  }

data Action
  = Initialize
  | ToggleD
  | CloseD
  | KeyDown KE.KeyboardEvent
  | DocClick Event.Event

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "popover-trigger"

panelRef :: H.RefLabel
panelRef = H.RefLabel "popover-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

sideOffset :: Number
sideOffset = 8.0

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, top: 0.0, left: 0.0 }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadEffect m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    doc <- liftEffect (window >>= Window.document)
    let target = HTMLDocument.toEventTarget doc
    void $ H.subscribe $ eventListener KET.keydown target (\e -> KeyDown <$> KE.fromEvent e)
    -- outside-click close: a document click listener (bubble phase) fires AFTER the
    -- trigger's own onClick, so by the time DocClick evaluates the toggle is applied.
    void $ H.subscribe $ eventListener MET.click target (Just <<< DocClick)
    portalize

  ToggleD -> do
    st <- H.get
    if st.open then handleAction CloseD
    else H.getHTMLElementRef triggerRef >>= case _ of
      Nothing -> pure unit
      Just he -> do
        r <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        H.modify_ _ { open = true, top = r.bottom + sideOffset, left = r.left }
        portalize

  CloseD ->
    H.modify_ _ { open = false }

  KeyDown ke ->
    when (KE.key ke == "Escape") (handleAction CloseD)

  DocClick ev -> do
    st <- H.get
    when st.open do
      inPanel <- refContains panelRef ev
      inTrigger <- refContains triggerRef ev
      when (not inPanel && not inTrigger) (handleAction CloseD)

refContains :: forall o m. MonadEffect m => H.RefLabel -> Event.Event -> H.HalogenM State Action () o m Boolean
refContains ref ev =
  H.getHTMLElementRef ref >>= case _ of
    Nothing -> pure false
    Just he -> liftEffect (Portal.containsTarget (HTMLElement.toElement he) ev)

portalize :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
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
  dataState b = if b then "open" else "closed"

  trigger =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] [ Variant "soft", Size "2" ]
          <> [ HP.ref triggerRef
             , HP.type_ HP.ButtonButton
             , HP.attr (HH.AttrName "aria-haspopup") "dialog"
             , HP.attr (HH.AttrName "aria-expanded") (if st.open then "true" else "false")
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HE.onClick (\_ -> ToggleD)
             ]
      )
      [ HH.text st.input.triggerLabel ]

  panel =
    HH.div
      ( attrs [ "rt-PopperContent", "rt-PopoverContent" ] [ Size "2", StyleProp "max-width" "480px" ]
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") "bottom"
            , HP.attr (HH.AttrName "data-align") "start"
            , HP.style (positionStyle st)
            ]
      )
      [ HH.p (attrs [ "rt-Text" ] [ Size "2" ]) [ HH.text st.input.body ] ]

positionStyle :: State -> String
positionStyle st =
  if st.open then
    "position: fixed; top: " <> show st.top <> "px; left: " <> show st.left <> "px"
  else
    "display: none"
