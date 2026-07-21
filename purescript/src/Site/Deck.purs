-- | The deck: horizontal = sections, vertical = depth within a section.
-- | Halogen owns the state machine (page, overlay, theme, input); the
-- | scroll-linked painting (reveal, rails, count-ups) is ported FFI, called
-- | at the moments the original orbital-site.js called it.
module Site.Deck
  ( view
  , component
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Milliseconds(..), delay)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Core (AttrName(..))
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.Subscription as HS
import Site.Chrome as Chrome
import Site.Content (panels)
import Site.Types (Action(..), State, darkPanels, initialState, panelCount)
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET
import Web.UIEvent.MouseEvent (MouseEvent)

-- ============================================================
-- FFI (ported from orbital-site.js / orbital-theme.js)
-- ============================================================

foreign import initEffectsImpl :: Effect Unit
foreign import pageEffectsImpl :: Int -> Effect Unit
foreign import setBodyDarkImpl :: Boolean -> Effect Unit
foreign import scrubIndexImpl :: MouseEvent -> Int -> Effect Int
foreign import scrollActiveImpl :: String -> Effect Unit
foreign import onHorizontalPageImpl :: (Int -> Effect Unit) -> Effect Unit
foreign import onSwipeImpl :: (Int -> Effect Unit) -> Effect Unit
foreign import applyThemeImpl :: Boolean -> Effect Unit
foreign import storedDarkImpl :: Effect Boolean

-- ============================================================
-- VIEW (shared by SSG and the live component)
-- ============================================================

view :: forall w. State -> HH.HTML w Action
view state =
  HH.div_
    [ Chrome.amb
    , Chrome.nav state
    , Chrome.overlay state
    , Chrome.footer state
    , Chrome.vrail
    , Chrome.shint
    , HH.div
        [ HP.class_ (HH.ClassName "tk")
        , HP.id "tk"
        , HP.attr (AttrName "style") ("transform: translateX(-" <> show (state.page * 100) <> "vw)")
        ]
        (Array.mapWithIndex panel panels)
    ]
  where
  panel i p =
    HH.section
      [ HP.class_ $ HH.ClassName $ "pn"
          <> (if p.dark then " pn--dk" else "")
          <> (if i == state.page then " active" else "")
      , HP.attr (AttrName "data-i") (show i)
      , HP.attr (AttrName "data-screen-label") p.label
      ]
      [ p.body ]

-- ============================================================
-- COMPONENT
-- ============================================================

component :: forall q i o m. MonadAff m => H.Component q i o m
component = H.mkComponent
  { initialState: const initialState
  , render: view
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      , initialize = Just Initialize
      }
  }

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    dark <- H.liftEffect storedDarkImpl
    H.liftEffect $ applyThemeImpl dark
    H.modify_ _ { dark = dark }
    H.liftEffect initEffectsImpl
    { emitter, listener } <- H.liftEffect HS.create
    -- keyboard
    win <- H.liftEffect window
    void $ H.subscribe $ eventListener KET.keydown (Window.toEventTarget win)
      (map KeyDown <<< KE.fromEvent)
    -- wheel (horizontal-dominant) and touch swipe page the deck
    H.liftEffect $ onHorizontalPageImpl (\d -> HS.notify listener (Paged d))
    H.liftEffect $ onSwipeImpl (\d -> HS.notify listener (Paged d))
    void $ H.subscribe emitter

  Go i -> go i

  Paged d -> do
    st <- H.get
    when (not st.overlayOpen) $ go (st.page + d)

  Scrub me -> do
    i <- H.liftEffect $ scrubIndexImpl me panelCount
    go i

  OpenOverlay -> H.modify_ _ { overlayOpen = true }

  CloseOverlay -> H.modify_ _ { overlayOpen = false }

  ToggleTheme -> do
    st <- H.modify \s -> s { dark = not s.dark }
    H.liftEffect $ applyThemeImpl st.dark

  KeyDown ke -> do
    st <- H.get
    if st.overlayOpen then
      when (KE.key ke == "Escape") $ H.modify_ _ { overlayOpen = false }
    else case KE.key ke of
      "ArrowRight" -> prevent ke *> go (st.page + 1)
      "ArrowLeft" -> prevent ke *> go (st.page - 1)
      "ArrowDown" -> prevent ke *> scroll "down"
      "ArrowUp" -> prevent ke *> scroll "up"
      "PageDown" -> prevent ke *> scroll "pgdn"
      " " -> prevent ke *> scroll "pgdn"
      "PageUp" -> prevent ke *> scroll "pgup"
      "Home" -> prevent ke *> scroll "top"
      "End" -> prevent ke *> scroll "end"
      "Escape" -> H.modify_ _ { overlayOpen = false }
      _ -> pure unit

  Unlock -> H.modify_ _ { locked = false }
  where
  prevent = H.liftEffect <<< Event.preventDefault <<< KE.toEvent
  scroll = H.liftEffect <<< scrollActiveImpl

  go i = do
    st <- H.get
    when (i >= 0 && i < panelCount && i /= st.page && not st.locked) do
      H.modify_ _ { page = i, overlayOpen = false, locked = true }
      H.liftEffect $ setBodyDarkImpl (darkPanels i)
      H.liftEffect $ pageEffectsImpl i
      void $ H.fork do
        H.liftAff $ delay (Milliseconds 900.0)
        handleAction Unlock
