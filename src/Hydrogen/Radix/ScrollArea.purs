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
-- |     Scrollbar(s) (data-orientation, data-state=visible, --radix-scroll-area-thumb-*) >
-- |       Thumb (data-state=visible, width/height = thumb vars, transform = translate3d)
-- |     Corner (only when scrollbars="both" — drives the corner-{width,height} vars)
-- |
-- | The thumb SIZE/POSITION are real measured px (upstream uses ResizeObserver +
-- | getComputedStyle; we measure the laid-out viewport/scrollbar geometry on
-- | Initialize and on every scroll). The oracle normalizes px to `<px>`, so the
-- | bar is STRUCTURAL byte-identity: the nesting, the rt-* classes, data-orientation/
-- | data-state, overflow styles, the var-shaped inline styles — not exact geometry.
-- |
-- | scope = `type="always"` (themes' deterministic preset): the scrollbar(s) are
-- | mounted unconditionally (no hover/scroll-idle timing), each thumb is sized +
-- | offset from live measurement, and scrolling the viewport re-offsets the thumb.
-- | The `scrollbars` field selects the scrollbar FAMILY:
-- |
-- |   * `Vertical`   — one vertical bar (overflow: hidden scroll), no corner.
-- |   * `Horizontal` — one horizontal bar (overflow: scroll hidden), no corner.
-- |   * `Both`       — BOTH bars (overflow: scroll) + a Corner; the corner-vars on
-- |                    Root resolve to the cross-axis bar thickness (non-zero) so the
-- |                    bars stop short of each other (upstream ScrollAreaCorner hasSize).
-- |
-- | DEFERRED (outside the structural at-rest oracle's scope, all live-JS interaction
-- | the px-normalizer tokenizes away): thumb-DRAG (pointer-capture → scroll), the
-- | hover/scroll `type` variants' hide-on-idle timing, RTL, forceMount. These change
-- | no at-rest structural DOM — the `always` anatomy this renders IS what the golden
-- | snapshots.
module Hydrogen.Radix.ScrollArea
  ( component
  , Input
  , Style
  , Slot
  , Scrollbars(..)
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Data.Int (round, toNumber)
import Data.Foldable (for_)
import Halogen.Query.Event (eventListener)
import Web.Event.Event (preventDefault, EventType(..))
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window as Window
import Web.UIEvent.MouseEvent as ME
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

-- | Which scrollbar(s) the Root renders. Mirrors radix-themes' `scrollbars` prop
-- | (`"vertical" | "horizontal" | "both"`). `Both` also renders the Corner.
data Scrollbars = Vertical' | Horizontal' | Both

derive instance eqScrollbars :: Eq Scrollbars

type Style =
  { root :: ClassNames
  , viewport :: ClassNames
  , focusRing :: ClassNames -- themes' rt-ScrollAreaViewportFocusRing sibling
  , scrollbar :: ClassNames
  , thumb :: ClassNames
  , corner :: ClassNames -- themes' rt-ScrollAreaCorner (only rendered for Both)
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-scroll-area-root"
  , viewport: cn "rdx-scroll-area-viewport"
  , focusRing: cn ""
  , scrollbar: cn "rdx-scroll-area-scrollbar"
  , thumb: cn "rdx-scroll-area-thumb"
  , corner: cn "rdx-scroll-area-corner"
  }

type Input =
  { content :: Array HH.PlainHTML
  -- the Root's fixed box: rendered verbatim as the tail of the root's inline style,
  -- exactly as upstream appends the consumer's `style` after its own position/corner-vars.
  , widthPx :: Int
  , heightPx :: Int
  , scrollbars :: Scrollbars
  -- the themes `radius` prop: stamped as `data-radius` on EVERY scrollbar (upstream
  -- scroll-area.tsx stamps `data-radius={radius}` on both ScrollAreaScrollbar nodes).
  -- The themes default is `undefined` (React omits the attr), so "" ⇒ no data-radius —
  -- matching the existing scrollbars goldens; a non-empty value stamps it on each bar.
  , radius :: String
  -- type="auto": a scrollbar is mounted only when its axis OVERFLOWS (content > viewport),
  -- measured on Initialize/scroll. Default false ⇒ type="always" (bars mounted unconditionally).
  , auto :: Boolean
  -- type="hover": like auto (overflow-gated) but ALSO only while the pointer is over the Root.
  -- Hidden at rest; the Root's pointerenter mounts the bar, pointerleave hides it.
  , hover :: Boolean
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { content: []
  , widthPx: 200
  , heightPx: 120
  , scrollbars: Vertical'
  , radius: ""
  , auto: false
  , hover: false
  , style: defaultStyle
  }

-- | No queries, no outputs (a self-contained measured scrollbar).
type Slot id = H.Slot (Const Void) Void id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type Axis =
  { sizePx :: Number -- measured thumb extent along the axis (the var value)
  , offsetPx :: Number -- measured thumb offset along the axis (the scroll position)
  , thicknessPx :: Number -- the cross-axis scrollbar thickness (→ corner var)
  }

zeroAxis :: Axis
zeroAxis = { sizePx: 18.0, offsetPx: 0.0, thicknessPx: 0.0 }

-- | A live thumb drag: the axis being dragged, the pointer + scroll position at grab, and the
-- | scale that maps a pointer delta (px) to a scroll delta (maxScroll / maxThumb).
type DragInfo =
  { axis :: Orientation
  , startPointer :: Number
  , startScroll :: Number
  , scale :: Number
  }

type State =
  { input :: Input
  , vert :: Axis -- vertical bar measurements (thumb height / Y offset)
  , horiz :: Axis -- horizontal bar measurements (thumb width / X offset)
  , overflowV :: Boolean -- vertical axis overflows (content > viewport) — gates the bar when auto
  , overflowH :: Boolean -- horizontal axis overflows
  , hovered :: Boolean   -- pointer is over the Root (type=hover: gates the bar's mount)
  , drag :: Maybe DragInfo
  , dragSubs :: Array H.SubscriptionId
  }

data Action
  = Initialize
  | Scrolled
  | RootEnter   -- pointer entered the Root (type=hover → show the scrollbar)
  | RootLeave   -- pointer left the Root (type=hover → hide the scrollbar)
  | ThumbDown Orientation ME.MouseEvent  -- pointer-down on a thumb → begin a drag
  | ThumbMove ME.MouseEvent              -- document pointer-move → scroll the viewport
  | ThumbUp

viewportRef :: H.RefLabel
viewportRef = H.RefLabel "scrollarea-viewport"

vScrollbarRef :: H.RefLabel
vScrollbarRef = H.RefLabel "scrollarea-scrollbar-v"

hScrollbarRef :: H.RefLabel
hScrollbarRef = H.RefLabel "scrollarea-scrollbar-h"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, vert: zeroAxis, horiz: zeroAxis, overflowV: false, overflowH: false, hovered: false, drag: Nothing, dragSubs: [] }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadEffect m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  -- Initialize runs after the first render: the viewport + scrollbar(s) are laid out,
  -- so the real geometry is available. Compute the initial thumb size(s) (ratio·track,
  -- min 18, upstream's `getThumbSize`) and offset(s) (0 at the start).
  Initialize -> recompute
  Scrolled -> recompute
  -- type=hover: pointer over the Root mounts the bar; re-measure so the freshly-mounted
  -- thumb is sized against the live track (the bar ref only resolves after this render).
  RootEnter -> H.modify_ _ { hovered = true } *> recompute
  RootLeave -> H.modify_ _ { hovered = false }
  -- pointer-down on a thumb: measure the axis to derive the pointer→scroll scale
  -- (maxScroll/maxThumb), then drag the viewport's scroll position (radix Thumb pointer-drag).
  ThumbDown axis me -> do
    liftEffect (preventDefault (ME.toEvent me))
    mvp <- H.getHTMLElementRef viewportRef
    for_ mvp \vp -> do
      let vpEl = HTMLElement.toElement vp
      info <- case axis of
        Vertical -> do
          vH <- liftEffect (HTMLElement.offsetHeight vp)
          cH <- liftEffect (Element.scrollHeight vpEl)
          sTop <- liftEffect (Element.scrollTop vpEl)
          track <- trackExtent vScrollbarRef
          pure { axis, startPointer: toN (ME.clientY me), startScroll: sTop, scale: dragScale (cH - vH) track (max 18.0 (track * ratioOf vH cH)) }
        Horizontal -> do
          vW <- liftEffect (HTMLElement.offsetWidth vp)
          cW <- liftEffect (Element.scrollWidth vpEl)
          sLeft <- liftEffect (Element.scrollLeft vpEl)
          track <- trackExtent hScrollbarRef
          pure { axis, startPointer: toN (ME.clientX me), startScroll: sLeft, scale: dragScale (cW - vW) track (max 18.0 (track * ratioOf vW cW)) }
      doc <- liftEffect (HTML.window >>= Window.document)
      let docTarget = HTMLDocument.toEventTarget doc
      moveSub <- H.subscribe (eventListener (EventType "mousemove") docTarget (map ThumbMove <<< ME.fromEvent))
      upSub <- H.subscribe (eventListener (EventType "mouseup") docTarget (\_ -> Just ThumbUp))
      H.modify_ _ { drag = Just info, dragSubs = [ moveSub, upSub ] }
  ThumbMove me -> do
    st <- H.get
    for_ st.drag \info -> do
      mvp <- H.getHTMLElementRef viewportRef
      for_ mvp \vp -> do
        let
          vpEl = HTMLElement.toElement vp
          pointer = case info.axis of
            Vertical -> toN (ME.clientY me)
            Horizontal -> toN (ME.clientX me)
          target = info.startScroll + (pointer - info.startPointer) * info.scale
        case info.axis of
          Vertical -> liftEffect (Element.setScrollTop (max 0.0 target) vpEl)
          Horizontal -> liftEffect (Element.setScrollLeft (max 0.0 target) vpEl)
        -- setScroll* fires a scroll event → Scrolled → recompute; recompute here too so the
        -- thumb tracks even if the event is coalesced.
        recompute
  ThumbUp -> do
    st <- H.get
    for_ st.dragSubs H.unsubscribe
    H.modify_ _ { drag = Nothing, dragSubs = [] }

-- | Measure the laid-out viewport (offset{Height,Width} = viewport, scroll{Height,Width}
-- | = content, scroll{Top,Left} = position) + each scrollbar (client{Height,Width} =
-- | track + the cross-axis client{Width,Height} = thickness), then size + offset each
-- | thumb exactly as upstream's `getThumbSize`/`getThumbOffsetFromScroll` do.
recompute :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
recompute = do
  mvp <- H.getHTMLElementRef viewportRef
  case mvp of
    Just vp -> do
      let vpEl = HTMLElement.toElement vp
      vH <- liftEffect (HTMLElement.offsetHeight vp)
      vW <- liftEffect (HTMLElement.offsetWidth vp)
      cH <- liftEffect (Element.scrollHeight vpEl)
      cW <- liftEffect (Element.scrollWidth vpEl)
      sTop <- liftEffect (Element.scrollTop vpEl)
      sLeft <- liftEffect (Element.scrollLeft vpEl)
      vert <- measureAxis vScrollbarRef vH cH sTop
      horiz <- measureAxis hScrollbarRef vW cW sLeft
      -- overflow per axis (content extent exceeds the viewport, +1px slack for sub-pixel
      -- rounding) — gates the scrollbar mount under type="auto". Thumb px are normalized to
      -- <px> in the oracle, so the bar's PRESENCE is the only thing this needs to be right.
      H.modify_ _ { vert = vert, horiz = horiz, overflowV = cH > vH + 1.0, overflowH = cW > vW + 1.0 }
    Nothing -> pure unit

-- | One axis: viewport extent / content extent / scroll position along the axis, the
-- | scrollbar's own client extent (track) and its cross-axis client extent (thickness,
-- | feeding the corner var). Mirrors upstream getThumbSize/getThumbOffsetFromScroll.
measureAxis
  :: forall o m
   . MonadEffect m
  => H.RefLabel
  -> Number -- viewport extent along axis
  -> Number -- content extent along axis
  -> Number -- scroll position along axis
  -> H.HalogenM State Action () o m Axis
measureAxis ref viewport content scrollPos = do
  msb <- H.getHTMLElementRef ref
  case msb of
    Just sb -> do
      let sbEl = HTMLElement.toElement sb
      -- the track is the scrollbar's extent ALONG the scroll axis; pick the larger of
      -- client width/height (the bar is long on its axis, thin on the cross axis).
      cw <- liftEffect (Element.clientWidth sbEl)
      ch <- liftEffect (Element.clientHeight sbEl)
      let
        track = max cw ch
        thickness = min cw ch
        ratio = if content <= 0.0 then 0.0 else viewport / content
        thumbSize = max 18.0 (track * ratio)
        maxScroll = content - viewport
        maxThumb = track - thumbSize
        offset =
          if maxScroll <= 0.0 then 0.0
          else (scrollPos / maxScroll) * maxThumb
      pure { sizePx: thumbSize, offsetPx: offset, thicknessPx: thickness }
    Nothing -> pure zeroAxis

toN :: Int -> Number
toN = toNumber

-- | The scrollbar's track extent ALONG its axis (the larger of its client width/height),
-- | matching `measureAxis`'s `track = max cw ch`.
trackExtent :: forall o m. MonadEffect m => H.RefLabel -> H.HalogenM State Action () o m Number
trackExtent ref = do
  msb <- H.getHTMLElementRef ref
  case msb of
    Just sb -> do
      let sbEl = HTMLElement.toElement sb
      cw <- liftEffect (Element.clientWidth sbEl)
      ch <- liftEffect (Element.clientHeight sbEl)
      pure (max cw ch)
    Nothing -> pure 0.0

-- | viewport/content ratio (the thumb-size fraction); 0 when content is unknown.
ratioOf :: Number -> Number -> Number
ratioOf viewport content = if content <= 0.0 then 0.0 else viewport / content

-- | The pointer-delta → scroll-delta scale: maxScroll / maxThumb (track − thumbSize). 0 if the
-- | thumb fills the track (nothing to scroll).
dragScale :: Number -> Number -> Number -> Number
dragScale maxScroll track thumbSize =
  let maxThumb = track - thumbSize
  in if maxThumb > 0.0 then maxScroll / maxThumb else 0.0

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( [ classes st.input.style.root
    , HP.attr (HH.AttrName "dir") "ltr"
    , HP.attr (HH.AttrName "style") rootStyle
    ]
      -- type=hover: the Root's pointer enter/leave toggle the scrollbar's mount.
      <> (if st.input.hover then [ HE.onMouseEnter (\_ -> RootEnter), HE.onMouseLeave (\_ -> RootLeave) ] else [])
    )
    ( [ -- Viewport: hides the native scrollbar, scrolls per scrollbars enabled. Upstream
        -- serializes overflowX/overflowY to a shorthand: vertical → "hidden scroll",
        -- horizontal → "scroll hidden", both → "scroll".
        HH.div
          [ classes st.input.style.viewport
          , HP.ref viewportRef
          , dataAttr "radix-scroll-area-viewport" ""
          , HP.attr (HH.AttrName "style") ("overflow: " <> overflowShorthand <> ";")
          , HE.onScroll (\_ -> Scrolled)
          ]
          [ -- the content div: `display: table` so it matches its children's size,
            -- `min-width: 100%` so it fills the viewport — upstream's exact inline style.
            HH.div
              [ HP.attr (HH.AttrName "style") "min-width: 100%; display: table;" ]
              (map HH.fromPlainHTML st.input.content)
          ]
      , -- the themes focus ring (an empty sibling div); rendered iff the Style supplies a class.
        HH.div [ classes st.input.style.focusRing ] []
      ]
        <> scrollbars
        <> corner
    )
  where
  -- the scrollbar FAMILY (which axes this Root carries), then the AUTO gate: under type="auto"
  -- a bar mounts only when its axis overflows (upstream Presence on ScrollAreaScrollbarAuto);
  -- under type="always" (auto=false) the bars are unconditional.
  famVert = st.input.scrollbars == Vertical' || st.input.scrollbars == Both
  famHoriz = st.input.scrollbars == Horizontal' || st.input.scrollbars == Both
  -- bar-mount gates: auto/hover mount only on overflow; hover additionally only while the
  -- Root is hovered. type=always (auto=hover=false) mounts the track unconditionally.
  needsOverflow = st.input.auto || st.input.hover
  needsHover = st.input.hover
  hasVert = famVert && (not needsOverflow || st.overflowV) && (not needsHover || st.hovered)
  hasHoriz = famHoriz && (not needsOverflow || st.overflowH) && (not needsHover || st.hovered)
  isBoth = hasVert && hasHoriz

  -- the scrollbar list, in UPSTREAM order: horizontal FIRST, then vertical (matches
  -- ScrollAreaScrollbarX/Y render order in the themes scrollbars="both" tree).
  scrollbars =
    (if hasHoriz then [ horizScrollbar ] else [])
      <> (if hasVert then [ vertScrollbar ] else [])

  -- upstream stamps `data-radius={radius}` on every scrollbar; the themes default
  -- (undefined) omits it, so only a non-empty `radius` Input adds the attribute.
  radiusAttr =
    if st.input.radius == "" then []
    else [ dataAttr "radius" st.input.radius ]

  -- the THUMB renders only when the axis actually has scrollable overflow (upstream's
  -- `hasThumb` gate — Presence on ScrollAreaThumb). The scrollbar TRACK can be present
  -- (type=always) with NO thumb when the content fits. Gated per-axis on the measured overflow.
  vertScrollbar =
    HH.div
      ( [ classes st.input.style.scrollbar
        , HP.ref vScrollbarRef
        , dataOrientation Vertical
        , dataState "visible"
        , HP.attr (HH.AttrName "style") vScrollbarStyle
        ] <> radiusAttr )
      ( if not st.overflowV then [] else
      [ HH.div
          [ classes st.input.style.thumb
          , dataState "visible"
          , HP.attr (HH.AttrName "style") thumbStyle
          , HE.onMouseDown (ThumbDown Vertical)
          ]
          []
      ] )

  horizScrollbar =
    HH.div
      ( [ classes st.input.style.scrollbar
        , HP.ref hScrollbarRef
        , dataOrientation Horizontal
        , dataState "visible"
        , HP.attr (HH.AttrName "style") hScrollbarStyle
        ] <> radiusAttr )
      ( if not st.overflowH then [] else
      [ HH.div
          [ classes st.input.style.thumb
          , dataState "visible"
          , HP.attr (HH.AttrName "style") thumbStyle
          , HE.onMouseDown (ThumbDown Horizontal)
          ]
          []
      ] )

  -- the Corner: only when both scrollbars are present (upstream gates on hasSize too,
  -- but with type="always" + overflow on both axes the bars are always present here).
  corner =
    if isBoth then
      [ HH.div
          [ classes st.input.style.corner
          , HP.attr (HH.AttrName "style") cornerStyle
          ]
          []
      ]
    else []

  overflowShorthand = case st.input.scrollbars of
    Vertical' -> "hidden scroll"
    Horizontal' -> "scroll hidden"
    Both -> "scroll"

  -- corner vars: 0 when no cross-axis bar, else the measured cross-axis bar thickness
  -- (so the bars stop short of the corner). Upstream order: position; corner vars; style.
  cornerWidthVar = if isBoth then pxN st.vert.thicknessPx else "0px"
  cornerHeightVar = if isBoth then pxN st.horiz.thicknessPx else "0px"

  rootStyle =
    "position: relative; "
      <> "--radix-scroll-area-corner-width: " <> cornerWidthVar <> "; "
      <> "--radix-scroll-area-corner-height: " <> cornerHeightVar <> "; "
      <> "width: " <> px st.input.widthPx <> "; "
      <> "height: " <> px st.input.heightPx <> ";"

  -- vertical bar: top:0; right:0; bottom: corner-height var; --thumb-height measured.
  vScrollbarStyle =
    "position: absolute; top: 0px; right: 0px; "
      <> "bottom: var(--radix-scroll-area-corner-height); "
      <> "--radix-scroll-area-thumb-height: " <> pxN st.vert.sizePx <> ";"

  -- horizontal bar: bottom:0; left:0; right: corner-width var; --thumb-width measured.
  hScrollbarStyle =
    "position: absolute; bottom: 0px; left: 0px; "
      <> "right: var(--radix-scroll-area-corner-width); "
      <> "--radix-scroll-area-thumb-width: " <> pxN st.horiz.sizePx <> ";"

  -- the corner box: upstream's ScrollAreaCorner measures the cross-axis bar thickness
  -- and writes RESOLVED px (width/height), not the var refs. right/bottom 0.
  cornerStyle =
    "width: " <> cornerWidthVar <> "; "
      <> "height: " <> cornerHeightVar <> "; "
      <> "position: absolute; right: 0px; bottom: 0px;"

  -- the thumb carries BOTH thumb vars; the per-axis translate3d is the scroll offset.
  thumbStyle =
    "width: var(--radix-scroll-area-thumb-width); "
      <> "height: var(--radix-scroll-area-thumb-height); "
      <> "transform: translate3d("
      <> pxN st.horiz.offsetPx <> ", " <> pxN st.vert.offsetPx <> ", 0px);"

  px :: Int -> String
  px n = show n <> "px"

  -- render a measured Number as an integer px (the engine resolves sub-px, but the
  -- normalizer tokenizes any `<n>px` regardless — an integer keeps the source tidy).
  pxN :: Number -> String
  pxN n = show (round n) <> "px"
