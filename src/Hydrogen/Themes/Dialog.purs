-- | Hydrogen.Themes.Dialog — the REFERENCE stateful/overlay component for Bucket B.
-- |
-- | Where the at-rest components (Button, Card, …) are pure `Prop → HTML`, the
-- | overlay family (Dialog, AlertDialog, Popover, HoverCard, Tooltip,
-- | DropdownMenu, Select) are *stateful Halogen components*: they open/close, trap
-- | Escape, close on a backdrop click, lock body scroll, and move focus. This
-- | module is the template the rest of Bucket B follows.
-- |
-- | The pattern:
-- |   * State `{ open, restoreOverflow }`; a trigger `<button>` toggles `open`.
-- |   * Escape is caught at the DOCUMENT level (a `H.subscribe` keydown listener on
-- |     Initialize), not via element focus — robust regardless of where focus sits.
-- |   * The backdrop closes on a *self-target* click (the padding itself, not its
-- |     content) — `Portal.isSelfTarget`.
-- |   * Opening locks `document.body` scroll (`Portal.setBodyOverflow "hidden"`,
-- |     restored on close) and focuses the content (`Portal.focus` via a ref).
-- |   * The rendered DOM mirrors upstream `dialog.tsx`: overlay
-- |     `rt-BaseDialogOverlay rt-DialogOverlay` → scroll → padding
-- |     (`… rt-r-align-center`) → content `rt-BaseDialogContent rt-DialogContent
-- |     rt-r-size-3` (`role=dialog`, `data-state`).
-- |
-- | The overlay is PORTALED: rendered unconditionally (a stable VDOM child, so
-- | Halogen patches it in place by reference) and adopted into a body-level
-- | `.radix-themes` container (`Portal.ensureContainer`/`adopt`) so its fixed
-- | positioning escapes any ancestor stacking/overflow/transform containing block.
-- | Halogen re-parents matched children back into the component root on each patch,
-- | so the adopt is re-asserted on `Portal.afterFrame` (a requestAnimationFrame that
-- | runs after the render). `display:none` hides it when closed.
module Hydrogen.Themes.Dialog
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
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.MouseEvent as ME

import Hydrogen.Themes.Portal as Portal

-- | What the dialog announces: the trigger label, the heading, and the body copy.
-- | (Reusable confirm-style dialog; richer content composes the same machinery.)
type Input =
  { triggerLabel :: String
  , title :: String
  , description :: String
  }

type State =
  { input :: Input
  , open :: Boolean
  , restoreOverflow :: String
  }

data Action
  = Initialize
  | OpenD
  | CloseD
  | KeyDown KE.KeyboardEvent
  | BackdropClick MouseEvent

contentRef :: H.RefLabel
contentRef = H.RefLabel "dialog-content"

overlayRef :: H.RefLabel
overlayRef = H.RefLabel "dialog-overlay"

-- | The shared body-level container every overlay portals into.
portalRoot :: String
portalRoot = "hydrogen-portal-root"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, restoreOverflow: "" }
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
    void $ H.subscribe $
      eventListener
        KET.keydown
        (HTMLDocument.toEventTarget doc)
        (\e -> KeyDown <$> KE.fromEvent e)
    portalize

  OpenD -> do
    prev <- liftEffect (Portal.setBodyOverflow "hidden")
    H.modify_ _ { open = true, restoreOverflow = prev }
    -- re-assert the body-mount AFTER this render (Halogen re-parents matched
    -- children into the component root on patch), then focus the content.
    portalize
    H.getHTMLElementRef contentRef >>= case _ of
      Just he -> liftEffect (Portal.focus (HTMLElement.toElement he))
      Nothing -> pure unit

  CloseD -> do
    st <- H.get
    when st.open do
      void $ liftEffect (Portal.setBodyOverflow st.restoreOverflow)
      H.modify_ _ { open = false }

  KeyDown ke ->
    when (KE.key ke == "Escape") (handleAction CloseD)

  BackdropClick me -> do
    self <- liftEffect (Portal.isSelfTarget (ME.toEvent me))
    when self (handleAction CloseD)

-- | Body-mount the overlay into the shared portal container. Halogen re-parents
-- | matched children back into the component root on every patch, so the actual
-- | `adopt` is deferred to `afterFrame` — it runs AFTER Halogen's render, leaving
-- | the overlay in the body container (the fixed-position layer thus escapes any
-- | ancestor stacking/overflow/transform). Idempotent; called on init + each open.
portalize :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
portalize = do
  container <- liftEffect (Portal.ensureContainer portalRoot)
  H.getHTMLElementRef overlayRef >>= case _ of
    Just he -> liftEffect (Portal.afterFrame (Portal.adopt container (HTMLElement.toElement he)))
    Nothing -> pure unit

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div_
    [ trigger, overlay ]
  where
  dataState b = if b then "open" else "closed"

  trigger =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] [ Variant "solid", Size "2" ]
          <> [ HP.type_ HP.ButtonButton
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HE.onClick (\_ -> OpenD)
             ]
      )
      [ HH.text st.input.triggerLabel ]

  overlay =
    HH.div
      ( [ HP.ref overlayRef
        , HP.class_ (HH.ClassName "rt-BaseDialogOverlay rt-DialogOverlay")
        , HP.attr (HH.AttrName "data-state") (dataState st.open)
        ]
          -- always mounted (so the adopted node is patched in place, never
          -- re-inserted); `display:none` when closed hides it + kills pointer events.
          <> (if st.open then [] else [ HP.style "display: none" ])
      )
      [ HH.div
          [ HP.class_ (HH.ClassName "rt-BaseDialogScroll rt-DialogScroll") ]
          [ HH.div
              [ HP.class_ (HH.ClassName "rt-BaseDialogScrollPadding rt-DialogScrollPadding rt-r-align-center")
              , HE.onClick BackdropClick
              ]
              [ content ]
          ]
      ]

  content =
    HH.div
      ( attrs [ "rt-BaseDialogContent", "rt-DialogContent" ] [ Size "3", StyleProp "max-width" "600px" ]
          <> [ HP.ref contentRef
             , HP.attr (HH.AttrName "role") "dialog"
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HP.tabIndex (-1)
             ]
      )
      [ HH.h1
          (attrs [ "rt-Heading" ] [ Size "5", Mb "3", Trim "start" ])
          [ HH.text st.input.title ]
      , HH.p
          (attrs [ "rt-Text" ] [ Size "3" ])
          [ HH.text st.input.description ]
      , HH.div
          (attrs [ "rt-Flex" ] [ Justify "end", Gap "3", Mt "4" ])
          [ closeButton "soft" "gray" "Cancel"
          , closeButton "solid" "" "Save"
          ]
      ]

  closeButton variant color label =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ]
          ([ Variant variant, Size "2" ] <> if color == "" then [] else [ Color color ])
          <> [ HP.type_ HP.ButtonButton, HE.onClick (\_ -> CloseD) ]
      )
      [ HH.text label ]
