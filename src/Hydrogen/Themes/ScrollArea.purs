-- | Hydrogen.Themes.ScrollArea — the custom-scrollbar container (Bucket B's outlier).
-- |
-- | Not an overlay: no portal, no floating. A viewport scrolls its overflowing
-- | content, and a STYLED thumb mirrors that scroll (radix hides the native
-- | scrollbar and paints its own). Mirrors upstream `scroll-area.tsx`:
-- |   `rt-ScrollAreaRoot` (flex column, overflow hidden) >
-- |     `rt-ScrollAreaViewport` (the scroll container) + content,
-- |     `rt-ScrollAreaScrollbar rt-r-size-1` (data-orientation=vertical) >
-- |       `rt-ScrollAreaThumb`.
-- |
-- | The behaviour (the stateful part): on the viewport's `scroll`, read its
-- | geometry (`scrollTop` / `scrollHeight` / `clientHeight` via the `_metrics` FFI)
-- | and size+offset the thumb proportionally — thumb height = (client/scroll)·track,
-- | thumb offset = (scrollTop/scroll)·track, with track ≈ the viewport height. The
-- | initial thumb is set on `afterFrame` (once the content has laid out). This is a
-- | simplified port — drag-to-scroll on the thumb and the horizontal bar are deferred.
module Hydrogen.Themes.ScrollArea
  ( Input
  , component
  ) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (attrs)
import Web.DOM (Element)
import Web.HTML.HTMLElement as HTMLElement

-- | The viewport pixel height (it scrolls when the content is taller) + the lines.
type Input =
  { heightPx :: Int
  , items :: Array String
  }

type Metrics =
  { scrollTop :: Number, scrollHeight :: Number, clientHeight :: Number }

foreign import _metrics :: Element -> Effect Metrics

type State =
  { input :: Input
  , thumbH :: Number -- thumb height, % of the track
  , thumbT :: Number -- thumb top offset, % of the track
  }

data Action
  = Initialize
  | Scrolled

viewportRef :: H.RefLabel
viewportRef = H.RefLabel "scrollarea-viewport"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, thumbH: 0.0, thumbT: 0.0 }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadEffect m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  -- Initialize runs after the first render, so the viewport + content are laid out;
  -- compute the initial thumb from the real geometry.
  Initialize -> recompute
  Scrolled -> recompute

-- | Read the viewport geometry and size+offset the thumb proportionally.
recompute :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
recompute =
  H.getHTMLElementRef viewportRef >>= case _ of
    Nothing -> pure unit
    Just he -> do
      m <- liftEffect (_metrics (HTMLElement.toElement he))
      -- as PERCENTAGES of the scroll height, so they map directly onto the track via
      -- CSS top/height % (relative to the scrollbar) — at max scroll top%+height%=100%,
      -- so the thumb's bottom meets the track's bottom exactly, regardless of insets.
      let
        h = if m.scrollHeight <= 0.0 then 100.0 else (m.clientHeight / m.scrollHeight) * 100.0
        t = if m.scrollHeight <= 0.0 then 0.0 else (m.scrollTop / m.scrollHeight) * 100.0
      H.modify_ _ { thumbH = h, thumbT = t }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( attrs [ "rt-ScrollAreaRoot" ] []
        <> [ HP.style ("position: relative; height: " <> show st.input.heightPx <> "px") ]
    )
    [ HH.div
        ( attrs [ "rt-ScrollAreaViewport" ] []
            <>
              [ HP.ref viewportRef
              , HP.style "overflow-y: auto; height: 100%; scrollbar-width: none"
              , HE.onScroll (\_ -> Scrolled)
              ]
        )
        (mapWithIndex line st.input.items)
    , HH.div
        ( attrs [ "rt-ScrollAreaScrollbar" ] [ ]
            <>
              [ HP.attr (HH.AttrName "data-orientation") "vertical"
              , HP.class_ (HH.ClassName "rt-ScrollAreaScrollbar rt-r-size-1")
              , HP.style "position: absolute; top: 4px; right: 4px; bottom: 4px; width: 8px"
              ]
        )
        [ HH.div
            [ HP.class_ (HH.ClassName "rt-ScrollAreaThumb")
            , HP.style ("position: absolute; left: 0; right: 0; height: " <> show st.thumbH <> "%; top: " <> show st.thumbT <> "%")
            ]
            []
        ]
    ]
  where
  line i s =
    HH.p
      (attrs [ "rt-Text" ] [] <> [ HP.style "padding: 4px 8px; margin: 0" ])
      [ HH.text (show (i + 1) <> ". " <> s) ]
