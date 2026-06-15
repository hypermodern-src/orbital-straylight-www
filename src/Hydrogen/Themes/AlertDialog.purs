-- | Hydrogen.Themes.AlertDialog — the forced-decision modal (Bucket B).
-- |
-- | A Dialog variant (see [[Hydrogen.Themes.Dialog]] for the full overlay/portal
-- | pattern) for confirmations the user MUST resolve: it does NOT close on a
-- | backdrop click — only via its action buttons (and Escape). DOM mirrors upstream
-- | `alert-dialog.tsx`: `rt-BaseDialogOverlay rt-AlertDialogOverlay` → scroll →
-- | padding (`… rt-r-align-center`) → content `rt-BaseDialogContent
-- | rt-AlertDialogContent rt-r-size-3` (`role=alertdialog`). Same body-mount
-- | (portal into the `.radix-themes` body container, re-asserted on afterFrame),
-- | scroll-lock, and document-level Escape as Dialog.
module Hydrogen.Themes.AlertDialog
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

import Hydrogen.Themes.Portal as Portal

-- | triggerLabel opens it; title/description are the prompt; confirmLabel is the
-- | (solid red) destructive action. Cancel is always present.
type Input =
  { triggerLabel :: String
  , title :: String
  , description :: String
  , confirmLabel :: String
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

contentRef :: H.RefLabel
contentRef = H.RefLabel "alertdialog-content"

overlayRef :: H.RefLabel
overlayRef = H.RefLabel "alertdialog-overlay"

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
      eventListener KET.keydown (HTMLDocument.toEventTarget doc) (\e -> KeyDown <$> KE.fromEvent e)
    portalize

  OpenD -> do
    prev <- liftEffect (Portal.setBodyOverflow "hidden")
    H.modify_ _ { open = true, restoreOverflow = prev }
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
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] [ Variant "solid", Color "red", Size "2" ]
          <> [ HP.type_ HP.ButtonButton
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HE.onClick (\_ -> OpenD)
             ]
      )
      [ HH.text st.input.triggerLabel ]

  -- no onClick on the padding: an alert dialog is a forced decision, no backdrop close.
  overlay =
    HH.div
      ( [ HP.ref overlayRef
        , HP.class_ (HH.ClassName "rt-BaseDialogOverlay rt-AlertDialogOverlay")
        , HP.attr (HH.AttrName "data-state") (dataState st.open)
        ]
          <> (if st.open then [] else [ HP.style "display: none" ])
      )
      [ HH.div
          [ HP.class_ (HH.ClassName "rt-BaseDialogScroll rt-AlertDialogScroll") ]
          [ HH.div
              [ HP.class_ (HH.ClassName "rt-BaseDialogScrollPadding rt-AlertDialogScrollPadding rt-r-align-center") ]
              [ content ]
          ]
      ]

  content =
    HH.div
      ( attrs [ "rt-BaseDialogContent", "rt-AlertDialogContent" ] [ Size "3", StyleProp "max-width" "480px" ]
          <> [ HP.ref contentRef
             , HP.attr (HH.AttrName "role") "alertdialog"
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HP.tabIndex (-1)
             ]
      )
      [ HH.h1 (attrs [ "rt-Heading" ] [ Size "5", Mb "3", Trim "start" ]) [ HH.text st.input.title ]
      , HH.p (attrs [ "rt-Text" ] [ Size "3" ]) [ HH.text st.input.description ]
      , HH.div
          (attrs [ "rt-Flex" ] [ Justify "end", Gap "3", Mt "4" ])
          [ actionButton "soft" "gray" "Cancel"
          , actionButton "solid" "red" st.input.confirmLabel
          ]
      ]

  actionButton variant color label =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] [ Variant variant, Color color, Size "2" ]
          <> [ HP.type_ HP.ButtonButton, HE.onClick (\_ -> CloseD) ]
      )
      [ HH.text label ]
