-- | Hydrogen.Radix.ScrollArea — the custom-scrollbar container (radix `ScrollArea`).
-- |
-- | The one non-overlay STATEFUL primitive. Radix hides the native scrollbar and
-- | paints its OWN thumb whose size is the viewport/content ratio and whose offset
-- | is the scroll position. The anatomy mirrors upstream `scroll-area.tsx` exactly:
-- |
-- |   Root (position: relative, --radix-scroll-area-corner-{width,height}) >
-- |     Viewport (data-radix-scroll-area-viewport, overflow per scrollbarsEnabled) >
-- |       content (min-width: 100%; display: table) > children
-- |     FocusRing (themes' rt-ScrollAreaViewportFocusRing — a Style-supplied sibling)
-- |     Scrollbar (data-orientation, data-state=visible, --radix-scroll-area-thumb-height) >
-- |       Thumb (data-state=visible, width/height = thumb vars, transform = translate3d)
-- |
-- | The thumb SIZE/POSITION are real measured px (upstream uses ResizeObserver +
-- | getComputedStyle; we measure the laid-out viewport/scrollbar geometry on
-- | Initialize and on every scroll). The oracle normalizes px to `<px>`, so the
-- | bar is STRUCTURAL byte-identity: the nesting, the rt-* classes, data-orientation/
-- | data-state, overflow styles, the var-shaped inline styles — not exact geometry.
-- |
-- | v1 scope = `type="always"` vertical scrollbar (themes' deterministic preset): the
-- | scrollbar is mounted unconditionally (no hover/scroll-idle timing), the thumb is
-- | sized + offset from live measurement, and scrolling the viewport re-offsets the
-- | thumb. DEFERRED (outside the structural oracle's scope, all live-JS interaction
-- | the px-normalizer tokenizes away): thumb-DRAG (pointer-capture → scroll), the
-- | hover/scroll `type` variants' hide-on-idle timing, the horizontal scrollbar +
-- | corner. These change no at-rest structural DOM — the `always`/vertical anatomy
-- | this renders IS what the golden snapshots.
module Hydrogen.Radix.ScrollArea
  ( component
  , Input
  , Style
  , Slot
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Data.Int (round)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), classes, cn, dataAttr, dataOrientation, dataState)
import Web.DOM.Element as Element
import Web.HTML.HTMLElement as HTMLElement

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Style =
  { root :: ClassNames
  , viewport :: ClassNames
  , focusRing :: ClassNames -- themes' rt-ScrollAreaViewportFocusRing sibling
  , scrollbar :: ClassNames
  , thumb :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-scroll-area-root"
  , viewport: cn "rdx-scroll-area-viewport"
  , focusRing: cn ""
  , scrollbar: cn "rdx-scroll-area-scrollbar"
  , thumb: cn "rdx-scroll-area-thumb"
  }

type Input =
  { content :: Array HH.PlainHTML
  -- the Root's fixed box: rendered verbatim as the tail of the root's inline style,
  -- exactly as upstream appends the consumer's `style` after its own position/corner-vars.
  , widthPx :: Int
  , heightPx :: Int
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { content: []
  , widthPx: 200
  , heightPx: 120
  , style: defaultStyle
  }

-- | No queries, no outputs (v1: a self-contained measured scrollbar).
type Slot id = H.Slot (Const Void) Void id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { input :: Input
  , thumbSizePx :: Number -- measured: the vertical thumb height in px (var value)
  , thumbOffsetPx :: Number -- measured: the thumb's translateY in px (scroll offset)
  }

data Action
  = Initialize
  | Scrolled

viewportRef :: H.RefLabel
viewportRef = H.RefLabel "scrollarea-viewport"

scrollbarRef :: H.RefLabel
scrollbarRef = H.RefLabel "scrollarea-scrollbar"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, thumbSizePx: 18.0, thumbOffsetPx: 0.0 }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadEffect m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  -- Initialize runs after the first render: the viewport + scrollbar are laid out, so
  -- the real geometry is available. Compute the initial thumb size (ratio·track, min 18,
  -- upstream's `getThumbSize`) and offset (0 at the top).
  Initialize -> recompute
  Scrolled -> recompute

-- | Measure the laid-out viewport (offsetHeight = viewport, scrollHeight = content,
-- | scrollTop = position) + scrollbar (clientHeight = track), then size + offset the
-- | thumb exactly as upstream's `getThumbSize` / `getThumbOffsetFromScroll` do.
recompute :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
recompute = do
  mvp <- H.getHTMLElementRef viewportRef
  msb <- H.getHTMLElementRef scrollbarRef
  case mvp, msb of
    Just vp, Just sb -> do
      let vpEl = HTMLElement.toElement vp
      viewport <- liftEffect (HTMLElement.offsetHeight vp)
      content <- liftEffect (Element.scrollHeight vpEl)
      scrollTop <- liftEffect (Element.scrollTop vpEl)
      track <- liftEffect (Element.clientHeight (HTMLElement.toElement sb))
      let
        ratio = if content <= 0.0 then 0.0 else viewport / content
        -- upstream `getThumbSize`: (scrollbar.size - padding)·ratio, min 18. The themes
        -- scrollbar has no measurable inner padding here; px is normalized, so the exact
        -- value is moot — only a non-degenerate, real px matters for the structure.
        thumbSize = max 18.0 (track * ratio)
        -- upstream `getThumbOffsetFromScroll`: linear-scale scrollTop ∈ [0, maxScroll]
        -- onto thumbPos ∈ [0, track - thumbSize].
        maxScroll = content - viewport
        maxThumb = track - thumbSize
        offset =
          if maxScroll <= 0.0 then 0.0
          else (scrollTop / maxScroll) * maxThumb
      H.modify_ _ { thumbSizePx = thumbSize, thumbOffsetPx = offset }
    _, _ -> pure unit

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    [ classes st.input.style.root
    , HP.attr (HH.AttrName "dir") "ltr"
    , HP.attr (HH.AttrName "style") rootStyle
    ]
    [ -- Viewport: hides the native scrollbar, scrolls vertically. `overflow: hidden scroll`
      -- (X hidden because scrollbars="vertical"; Y scroll) — upstream serializes overflowX/
      -- overflowY to this shorthand.
      HH.div
        [ classes st.input.style.viewport
        , HP.ref viewportRef
        , dataAttr "radix-scroll-area-viewport" ""
        , HP.attr (HH.AttrName "style") "overflow: hidden scroll;"
        , HE.onScroll (\_ -> Scrolled)
        ]
        [ -- the content div: `display: table` so it matches its children's size, `min-width:
          -- 100%` so it fills the viewport — upstream's exact inline style, no class.
          HH.div
            [ HP.attr (HH.AttrName "style") "min-width: 100%; display: table;" ]
            (map HH.fromPlainHTML st.input.content)
        ]
    , -- the themes focus ring (an empty sibling div); rendered iff the Style supplies a class.
      HH.div [ classes st.input.style.focusRing ] []
    , -- the vertical scrollbar: absolutely positioned, data-state=visible (type="always"),
      -- carrying the measured thumb-height var. `bottom: var(--radix-scroll-area-corner-height)`
      -- + `top: 0px; right: 0px` matches upstream's ScrollAreaScrollbarY inline style.
      HH.div
        [ classes st.input.style.scrollbar
        , HP.ref scrollbarRef
        , dataOrientation Vertical
        , dataState "visible"
        , HP.attr (HH.AttrName "style") scrollbarStyle
        ]
        [ HH.div
            [ classes st.input.style.thumb
            , dataState "visible"
            , HP.attr (HH.AttrName "style") thumbStyle
            ]
            []
        ]
    ]
  where
  -- The corner vars are 0 (no horizontal scrollbar ⇒ no corner), then the consumer's
  -- width/height — upstream order: position; corner vars; ...props.style.
  rootStyle =
    "position: relative; "
      <> "--radix-scroll-area-corner-width: 0px; "
      <> "--radix-scroll-area-corner-height: 0px; "
      <> "width: " <> px st.input.widthPx <> "; "
      <> "height: " <> px st.input.heightPx <> ";"

  scrollbarStyle =
    "position: absolute; top: 0px; right: 0px; "
      <> "bottom: var(--radix-scroll-area-corner-height); "
      <> "--radix-scroll-area-thumb-height: " <> pxN st.thumbSizePx <> ";"

  thumbStyle =
    "width: var(--radix-scroll-area-thumb-width); "
      <> "height: var(--radix-scroll-area-thumb-height); "
      <> "transform: translate3d(0px, " <> pxN st.thumbOffsetPx <> ", 0px);"

  px :: Int -> String
  px n = show n <> "px"

  -- render a measured Number as an integer px (the engine resolves sub-px, but the
  -- normalizer tokenizes any `<n>px` regardless — an integer keeps the source tidy).
  pxN :: Number -> String
  pxN n = show (round n) <> "px"
