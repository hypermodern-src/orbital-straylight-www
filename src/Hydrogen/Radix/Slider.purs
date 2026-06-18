-- | Hydrogen.Radix.Slider — a single-thumb range slider (radix `Slider`).
-- |
-- | This is the one explicitly-deferred interactive primitive: keyboard-drivable, so it
-- | fits the DOM/a11y/APG oracle without pointer simulation. It mirrors the at-rest
-- | `Hydrogen.Themes.Slider` anatomy but is now a STATEFUL Halogen component — the thumb
-- | is a focusable `role=slider` element whose `aria-valuenow` and inline position follow a
-- | `Controllable Int` value that the keyboard steps.
-- |
-- | Anatomy (the rt-Slider* class set is supplied by the caller's `Style`; the primitive
-- | owns the behavioral attributes + the value→position geometry):
-- |
-- |   Root  <span class=root>  — `aria-disabled`, `data-orientation`, `dir`, and the
-- |     `--radix-slider-thumb-transform: translateX(-50%)` custom property.
-- |   Track <span class=track> — `data-orientation`.
-- |   Range <span class=range> — `data-orientation`, `style="left: 0%; right: {100-pct}%"`.
-- |   Thumb wrapper <span>     — `style="transform: var(--radix-slider-thumb-transform);
-- |     position: absolute; left: calc({pct}% + 0px)"` (the in-bounds offset is 0 at first
-- |     paint, before the thumb is measured; it normalizes to `<px>` in the oracle anyway).
-- |   Thumb <span class=thumb> — `role=slider`, `aria-valuemin/valuemax/valuenow`,
-- |     `aria-orientation`, `data-orientation`, `data-radix-collection-item`, `tabindex=0`,
-- |     an empty `style=` (upstream forwards the thumb-trigger's empty style), and the
-- |     keyboard handler.
-- |
-- | value→position is PURE: `pct = (value - min) / (max - min) * 100`, clamped to [0,100].
-- | The percentage is NOT normalized by the DOM oracle, so it must be computed byte-identically.
-- |
-- | Keyboard (APG slider pattern), single horizontal LTR thumb:
-- |   * ArrowRight / ArrowUp     → +step
-- |   * ArrowLeft  / ArrowDown   → -step
-- |   * PageUp                    → +step·10
-- |   * PageDown                  → -step·10
-- |   * Home                      → min
-- |   * End                       → max
-- | each clamped (and snapped to the step grid) to [min,max]. RTL flips the horizontal arrows;
-- | vertical orientation swaps the active axis (Up/Down step). `disabled` suppresses all steps
-- | and drops the thumb tabindex.
module Hydrogen.Radix.Slider
  ( component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  -- Wave-D: multi-thumb / range variant (value is an Array Int).
  , rangeComponent
  , RangeInput
  , RangeOutput(..)
  , RangeQuery(..)
  , RangeSlot
  , defaultRangeInput
  ) where

import Prelude

import Data.Int (round, toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_, minimum, maximum)
import Data.Array (mapWithIndex, length, index, updateAt, (!!))
import Data.Number.Format (toString) as Num
import Data.Ord (clamp)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..), dirName)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), classes, cn, dataAttr, dataOrientation, orientationName, role, aria)
import Hydrogen.Radix.Float.Popper as Popper
import Halogen.Query.Event (eventListener)
import Web.Event.Event (preventDefault, EventType(..))
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type Style =
  { root :: ClassNames
  , track :: ClassNames
  , range :: ClassNames
  , thumb :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-slider-root"
  , track: cn "rdx-slider-track"
  , range: cn "rdx-slider-range"
  , thumb: cn "rdx-slider-thumb"
  }

type Input =
  { value :: Maybe Int          -- controlled value
  , defaultValue :: Int         -- uncontrolled initial
  , min :: Int
  , max :: Int
  , step :: Int
  , orientation :: Orientation
  , dir :: Dir
  , disabled :: Boolean
  , idPrefix :: String          -- reserved for future id wiring; minted on Initialize
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { value: Nothing
  , defaultValue: 0
  , min: 0
  , max: 100
  , step: 1
  , orientation: Horizontal
  , dir: LTR
  , disabled: false
  , idPrefix: "rdx-slider"
  , style: defaultStyle
  }

data Output = ValueChanged Int

data Query a
  = SetValue Int a
  | GetValue (Int -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Int
  , min :: Int
  , max :: Int
  , step :: Int
  , orientation :: Orientation
  , dir :: Dir
  , disabled :: Boolean
  , idPrefix :: String
  , style :: Style
  , uid :: String        -- minted on Initialize (parity with the other primitives)
  , dragging :: Boolean  -- a pointer slide is in progress
  , dragSubs :: Array H.SubscriptionId  -- the document mousemove/up subscriptions during a drag
  }

data Action
  = Initialize
  | Receive Input
  | ThumbKeyDown KE.KeyboardEvent
  | SlideStart ME.MouseEvent   -- pointer-down on the track: jump the thumb + begin dragging
  | SlideMove ME.MouseEvent    -- document pointer-move while dragging
  | SlideEnd                   -- document pointer-up: end the drag

-- | The thumb ref — component-internal, keyed off a stable label (never serialized; the
-- | per-mount `uid` is minted after first render, so it must NOT key the ref).
thumbRef :: H.RefLabel
thumbRef = H.RefLabel "slider-thumb"

-- | The root <span> ref — measured (getBoundingClientRect) to map a pointer X/Y to a value.
rootRef :: H.RefLabel
rootRef = H.RefLabel "slider-root"

component :: forall m. MonadEffect m => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        , initialize = Just Initialize
        }
    }

initialState :: Input -> State
initialState input =
  { ctrl: controllable input.value input.defaultValue
  , min: input.min
  , max: input.max
  , step: input.step
  , orientation: input.orientation
  , dir: input.dir
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  , uid: ""
  , dragging: false
  , dragSubs: []
  }

-- | value→percentage, pure and clamped to [0,100] — radix `convertValueToPercentage`.
-- | Formatted JS-style (an integral percentage prints without a decimal: `45`, not `45.0`),
-- | so the inline `left`/`right` strings are byte-identical to the upstream golden.
percent :: State -> Int -> Number
percent st value =
  let
    span = toNumber (st.max - st.min)
    raw = if span == 0.0 then 0.0 else toNumber (value - st.min) * 100.0 / span
  in
    clamp 0.0 100.0 raw

fmtPct :: Number -> String
fmtPct = Num.toString

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    value = current st.ctrl
    pct = percent st value
    -- The orientation picks the CSS edges (radix SliderHorizontal/SliderVertical): horizontal
    -- LTR slides from the left (startEdge=left, endEdge=right, thumb-transform translateX(-50%));
    -- vertical slides from the bottom (startEdge=bottom, endEdge=top, thumb-transform translateY(50%)).
    -- Range stamps `{startEdge}: 0%; {endEdge}: {100-pct}%`; the thumb wrapper stamps
    -- `{startEdge}: calc({pct}% + <px>)`. Key ORDER (start then end) matches React's style object.
    isVertical = st.orientation == Vertical
    startEdge = if isVertical then "bottom" else "left"
    endEdge = if isVertical then "top" else "right"
    thumbTransform = if isVertical then "translateY(50%)" else "translateX(-50%)"
    rangeEnd = fmtPct (100.0 - pct)
    thumbStart = fmtPct pct
  in
    HH.span
      ( [ classes st.style.root
        , HP.ref rootRef
        , aria "disabled" (if st.disabled then "true" else "false")
        , dataOrientation st.orientation
        , HP.attr (HH.AttrName "style") ("--radix-slider-thumb-transform: " <> thumbTransform <> ";")
        ]
          -- only SliderHorizontal forwards `dir` to SliderImpl (radix); SliderVertical omits it.
          <> (if isVertical then [] else [ HP.attr (HH.AttrName "dir") (dirName st.dir) ])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [ HE.onMouseDown SlideStart ])
      )
      [ HH.span
          ( [ classes st.style.track
            , dataOrientation st.orientation
            ]
              <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
          )
          [ HH.span
              ( [ classes st.style.range
                , dataOrientation st.orientation
                , HP.attr (HH.AttrName "style") (startEdge <> ": 0%; " <> endEdge <> ": " <> rangeEnd <> "%;")
                ]
                  <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
              )
              []
          ]
      , HH.span
          [ HP.attr (HH.AttrName "style")
              ("transform: var(--radix-slider-thumb-transform); position: absolute; " <> startEdge <> ": calc(" <> thumbStart <> "% + 0px);")
          ]
          [ HH.span
              ( [ classes st.style.thumb
                , HP.ref thumbRef
                , role "slider"
                , aria "valuemin" (show st.min)
                , aria "valuenow" (show value)
                , aria "valuemax" (show st.max)
                , aria "orientation" (orientationName st.orientation)
                , dataOrientation st.orientation
                , dataAttr "radix-collection-item" ""
                -- upstream forwards the thumb-trigger's (empty) `style` prop onto the thumb;
                -- the resolved value is `undefined`, which serializes as an empty `style=`.
                , HP.attr (HH.AttrName "style") ""
                , HE.onKeyDown ThumbKeyDown
                ]
                  <> (if st.disabled then [] else [ HP.tabIndex 0 ])
                  <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
              )
              []
          ]
      ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Keyboard (APG slider pattern), pure step computation
-- ─────────────────────────────────────────────────────────────────────────────

-- | The next value for a keydown, given current value + config. `Nothing` for keys the
-- | slider ignores (so the handler can skip preventing default / re-rendering). Mirrors
-- | radix: Home→min, End→max, Page keys ±step·10, arrows ±step (RTL flips horizontal,
-- | vertical swaps the active axis), each snapped to the step grid and clamped to [min,max].
nextValue :: State -> Int -> String -> Boolean -> Maybe Int
nextValue st value key shiftKey =
  let
    horizontal = st.orientation == Horizontal
    -- RTL flips the horizontal arrow meaning.
    k = case st.dir, key of
      RTL, "ArrowLeft" -> "ArrowRight"
      RTL, "ArrowRight" -> "ArrowLeft"
      _, _ -> key
    -- radix `isSkipKey = isPageKey || (shiftKey && ARROW_KEYS)` → 10× step. Shift+Arrow is
    -- the page-equivalent skip; an arrow without shift is a single step.
    isArrow = case k of
      "ArrowUp" -> true
      "ArrowDown" -> true
      "ArrowLeft" -> true
      "ArrowRight" -> true
      _ -> false
    mult = if shiftKey && isArrow then 10 else 1
    stepBy n = Just (snapClamp st (value + n * mult * st.step))
  in
    case k of
      "Home" -> Just st.min
      "End" -> Just st.max
      "PageUp" -> Just (snapClamp st (value + 10 * st.step))
      "PageDown" -> Just (snapClamp st (value - 10 * st.step))
      "ArrowUp" -> if horizontal then Nothing else stepBy 1
      "ArrowDown" -> if horizontal then Nothing else stepBy (-1)
      "ArrowLeft" -> if horizontal then stepBy (-1) else Nothing
      "ArrowRight" -> if horizontal then stepBy 1 else Nothing
      _ -> Nothing

-- | Snap to the step grid relative to `min` (radix `Math.round((v-min)/step)*step+min`),
-- | then clamp to [min,max].
snapClamp :: State -> Int -> Int
snapClamp st v =
  let
    snapped =
      if st.step <= 0 then v
      else round (toNumber (v - st.min) / toNumber st.step) * st.step + st.min
  in
    clamp st.min st.max snapped

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    uid <- useId
    H.modify_ _ { uid = uid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.value st.ctrl
      , min = input.min
      , max = input.max
      , step = input.step
      , orientation = input.orientation
      , dir = input.dir
      , disabled = input.disabled
      , idPrefix = input.idPrefix
      , style = input.style
      }
  ThumbKeyDown ke -> do
    st <- H.get
    when (not st.disabled) do
      case nextValue st (current st.ctrl) (KE.key ke) (KE.shiftKey ke) of
        Nothing -> pure unit
        Just v -> do
          -- prevent the browser default (page scroll on arrows / Home / End / Page keys)
          liftEffect (preventDefault (KE.toEvent ke))
          setValue v
          -- keep focus on the thumb (radix re-focuses the active thumb on every change)
          focusThumb
  -- pointer-down anywhere on the slider: jump the value to the pointer, focus the thumb, and
  -- begin a drag (radix handleSlideStart). Document-level move/up subscriptions track the drag
  -- past the thumb's bounds (setPointerCapture-equivalent).
  SlideStart me -> do
    st <- H.get
    when (not st.disabled) do
      liftEffect (preventDefault (ME.toEvent me))
      commitFromPointer me
      focusThumb
      doc <- liftEffect (HTML.window >>= Window.document)
      let docTarget = HTMLDocument.toEventTarget doc
      moveSub <- H.subscribe (eventListener (EventType "mousemove") docTarget (map SlideMove <<< ME.fromEvent))
      upSub <- H.subscribe (eventListener (EventType "mouseup") docTarget (\_ -> Just SlideEnd))
      H.modify_ _ { dragging = true, dragSubs = [ moveSub, upSub ] }
  SlideMove me -> do
    st <- H.get
    when st.dragging (commitFromPointer me)
  SlideEnd -> do
    st <- H.get
    for_ st.dragSubs H.unsubscribe
    H.modify_ _ { dragging = false, dragSubs = [] }

-- | Commit a new value (uncontrolled advances; controlled reports only) and emit it.
setValue :: forall m. Int -> H.HalogenM State Action () Output m Unit
setValue v = do
  st <- H.get
  when (current st.ctrl /= v) do
    H.modify_ _ { ctrl = (change v st.ctrl).next }
    H.raise (ValueChanged v)

focusThumb :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
focusThumb = do
  mel <- H.getHTMLElementRef thumbRef
  for_ mel (liftEffect <<< HTMLElement.focus)

-- | Map the pointer position to a snapped value (the root's getBoundingClientRect → fraction
-- | along the active axis → value), then commit it. Horizontal LTR runs left→right; RTL flips;
-- | vertical runs bottom→top. Mirrors radix `getValueFromPointer` + the orientation's edge map.
commitFromPointer :: forall m. MonadEffect m => ME.MouseEvent -> H.HalogenM State Action () Output m Unit
commitFromPointer me = do
  st <- H.get
  mroot <- H.getHTMLElementRef rootRef
  for_ mroot \root -> do
    rect <- liftEffect (Popper.measureRect root)
    let
      fraction
        | st.orientation == Vertical =
            -- bottom origin: 0 at the bottom edge, 1 at the top
            if rect.height == 0.0 then 0.0
            else clamp 0.0 1.0 ((rect.y + rect.height - toNumber (ME.clientY me)) / rect.height)
        | otherwise =
            let f = if rect.width == 0.0 then 0.0 else clamp 0.0 1.0 ((toNumber (ME.clientX me) - rect.x) / rect.width)
            in if st.dir == RTL then 1.0 - f else f
      raw = toNumber st.min + fraction * toNumber (st.max - st.min)
    setValue (snapClamp st (round raw))

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    st <- H.get
    setValue (snapClamp st v)
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))

-- ═════════════════════════════════════════════════════════════════════════════
-- Wave-D: multi-thumb / RANGE slider (radix Slider with value: number[])
-- ═════════════════════════════════════════════════════════════════════════════
-- |
-- | Upstream renders ONE `role=slider` thumb PER value. The structural deltas vs the
-- | single-thumb variant (all DOM-observable, all deterministic, all keyboard-drivable):
-- |
-- |   * Range geometry (radix SliderRange): with N>1 thumbs the range spans BETWEEN the
-- |     thumbs — `offsetStart = min(percentages)`, `offsetEnd = 100 - max(percentages)`,
-- |     so the range `style` is `{startEdge}: {min}%; {endEdge}: {100-max}%`. (Single-thumb
-- |     pins offsetStart=0; this variant pins it to the lower thumb.)
-- |   * Per-thumb aria-label (radix getLabel): exactly 2 thumbs ⇒ ["Minimum","Maximum"][i];
-- |     >2 thumbs ⇒ "Value {i+1} of {N}". (Single thumb ⇒ no aria-label, as in `component`.)
-- |   * Each thumb wrapper stamps `{startEdge}: calc({pct_i}% + 0px)` for ITS value.
-- |   * Each thumb is INDEPENDENTLY focusable (tabindex=0) and keyboard-steps ITS OWN index;
-- |     on focus radix sets `valueIndexToChangeRef = index` so the arrows drive that thumb.
-- |   * minStepsBetweenThumbs (radix `hasMinStepsBetweenValues`): a keyboard step that would
-- |     bring two adjacent thumbs closer than `minStepsBetweenThumbs * step` is REJECTED
-- |     (the value update is a no-op). With the default 0 thumbs may meet but the sorted
-- |     order is preserved (a thumb cannot keyboard past its neighbour).
-- |
-- | Keyboard semantics per-thumb are otherwise identical to the single-thumb `nextValue`
-- | (Home→min, End→max, Page/Shift ±10·step, arrows ±step, RTL/vertical axis swap), reused
-- | verbatim by constructing a transient single-thumb `State` view.

type RangeInput =
  { value :: Maybe (Array Int)   -- controlled
  , defaultValue :: Array Int     -- uncontrolled initial (one entry per thumb)
  , min :: Int
  , max :: Int
  , step :: Int
  , minStepsBetweenThumbs :: Int
  , orientation :: Orientation
  , dir :: Dir
  , disabled :: Boolean
  , idPrefix :: String
  , style :: Style
  -- | The form field name. When set AND the slider sits inside a `<form>`, each thumb's
  -- | SliderThumbProvider resolves `isFormControl` true and renders a hidden
  -- | SliderBubbleInput SIBLING (a bare `<input style="display:none">`, NO type/aria-hidden/
  -- | tabindex; radix slider.tsx:790-799). The bubble's name is `name <> "[]"` for a
  -- | multi-thumb slider (radix resolvedName, slider.tsx:610-611). `""` ⇒ no bubble.
  , name :: String
  -- | Whether a `<form>` ancestor exists (resolved post-mount in upstream). The port has no
  -- | DOM ancestry at gen time, so the example route sets this explicitly — mirroring the
  -- | Checkbox/Switch/RadioGroup `isFormControl` pattern (Wave C). Bubble inputs render only
  -- | when `isFormControl && name /= ""`.
  , isFormControl :: Boolean
  }

defaultRangeInput :: RangeInput
defaultRangeInput =
  { value: Nothing
  , defaultValue: [ 25, 75 ]
  , min: 0
  , max: 100
  , step: 1
  , minStepsBetweenThumbs: 0
  , orientation: Horizontal
  , dir: LTR
  , disabled: false
  , idPrefix: "rdx-slider-range"
  , style: defaultStyle
  , name: ""
  , isFormControl: false
  }

data RangeOutput = RangeValueChanged (Array Int)

data RangeQuery a
  = SetRangeValue (Array Int) a
  | GetRangeValue (Array Int -> a)

type RangeSlot id = H.Slot RangeQuery RangeOutput id

type RangeState =
  { ctrl :: Controllable (Array Int)
  , min :: Int
  , max :: Int
  , step :: Int
  , minStepsBetweenThumbs :: Int
  , orientation :: Orientation
  , dir :: Dir
  , disabled :: Boolean
  , idPrefix :: String
  , style :: Style
  , uid :: String
  , name :: String
  , isFormControl :: Boolean
  }

data RangeAction
  = RangeInitialize
  | RangeReceive RangeInput
  | RangeThumbKeyDown Int KE.KeyboardEvent

-- | A stable ref per thumb index, so the changed thumb keeps focus across re-render.
rangeThumbRef :: Int -> H.RefLabel
rangeThumbRef i = H.RefLabel ("slider-range-thumb-" <> show i)

rangeComponent :: forall m. MonadEffect m => H.Component RangeQuery RangeInput RangeOutput m
rangeComponent =
  H.mkComponent
    { initialState: rangeInitialState
    , render: rangeRender
    , eval: H.mkEval H.defaultEval
        { handleAction = rangeHandleAction
        , handleQuery = rangeHandleQuery
        , receive = Just <<< RangeReceive
        , initialize = Just RangeInitialize
        }
    }

rangeInitialState :: RangeInput -> RangeState
rangeInitialState input =
  { ctrl: controllable input.value input.defaultValue
  , min: input.min
  , max: input.max
  , step: input.step
  , minStepsBetweenThumbs: input.minStepsBetweenThumbs
  , orientation: input.orientation
  , dir: input.dir
  , disabled: input.disabled
  , idPrefix: input.idPrefix
  , style: input.style
  , uid: ""
  , name: input.name
  , isFormControl: input.isFormControl
  }

-- | Project the range state onto the single-thumb `State` shape so `percent`, `nextValue`
-- | and `snapClamp` are reused VERBATIM (one keyboard/geometry implementation, no drift).
asThumbState :: RangeState -> State
asThumbState st =
  { ctrl: controllable Nothing 0   -- unused: callers pass the explicit value
  , min: st.min
  , max: st.max
  , step: st.step
  , orientation: st.orientation
  , dir: st.dir
  , disabled: st.disabled
  , idPrefix: st.idPrefix
  , style: st.style
  , uid: st.uid
  , dragging: false   -- unused in the projection (range thumbs don't share the single drag state)
  , dragSubs: []
  }

-- | radix getLabel(index, total): 2 thumbs ⇒ Minimum/Maximum; >2 ⇒ "Value n of m"; 1 ⇒ none.
thumbLabel :: Int -> Int -> Maybe String
thumbLabel idx total
  | total > 2 = Just ("Value " <> show (idx + 1) <> " of " <> show total)
  | total == 2 = index [ "Minimum", "Maximum" ] idx
  | otherwise = Nothing

rangeRender :: forall m. RangeState -> H.ComponentHTML RangeAction () m
rangeRender st =
  let
    ts = asThumbState st
    values = current st.ctrl
    total = length values
    pcts = map (percent ts) values
    isVertical = st.orientation == Vertical
    startEdge = if isVertical then "bottom" else "left"
    endEdge = if isVertical then "top" else "right"
    thumbTransform = if isVertical then "translateY(50%)" else "translateX(-50%)"
    -- range spans between the extreme thumbs (radix offsetStart/offsetEnd).
    offsetStart = fromMaybe 0.0 (minimum pcts)
    offsetEnd = 100.0 - fromMaybe 0.0 (maximum pcts)
  in
    HH.span
      ( [ classes st.style.root
        , aria "disabled" (if st.disabled then "true" else "false")
        , dataOrientation st.orientation
        , HP.attr (HH.AttrName "style") ("--radix-slider-thumb-transform: " <> thumbTransform <> ";")
        ]
          <> (if isVertical then [] else [ HP.attr (HH.AttrName "dir") (dirName st.dir) ])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
      )
      ( [ HH.span
            ( [ classes st.style.track
              , dataOrientation st.orientation
              ]
                <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
            )
            [ HH.span
                ( [ classes st.style.range
                  , dataOrientation st.orientation
                  , HP.attr (HH.AttrName "style") (startEdge <> ": " <> fmtPct offsetStart <> "%; " <> endEdge <> ": " <> fmtPct offsetEnd <> "%;")
                  ]
                    <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
                )
                []
            ]
        ]
          <> join (mapWithIndex (rangeThumb st ts total startEdge) values)
      )

-- | The hidden SliderBubbleInput (radix slider.tsx:790-799): a bare `<input
-- | style="display:none">` carrying the thumb's value via `defaultValue` (→ the `value`
-- | attribute) and the resolved form name. Crucially it has NO `type` (defaults to text so
-- | FormData reads it — upstream explicitly avoids type=hidden), NO aria-hidden, and NO
-- | tabindex (unlike the Checkbox/Switch bubbles). Rendered as a SIBLING of the thumb
-- | wrapper, only when the slider is a form control with a name.
rangeBubbleInput :: forall m. String -> Int -> H.ComponentHTML RangeAction () m
rangeBubbleInput nm value =
  HH.input
    [ HP.name nm
    , HP.style "display: none;"
    -- upstream `defaultValue={value}` ⇒ the `value` HTML ATTRIBUTE (not the live property);
    -- emit it as a literal attribute so the DOM serializer shows it (HP.value sets the prop).
    , HP.attr (HH.AttrName "value") (show value)
    ]

-- | Render one thumb as [wrapperSpan] plus, when the slider is a form control with a name,
-- | its hidden SliderBubbleInput SIBLING — both direct children of Root (radix renders the
-- | thumb-trigger wrapper then the bubble input as a fragment, slider.tsx:726-740).
rangeThumb :: forall m. RangeState -> State -> Int -> String -> Int -> Int -> Array (H.ComponentHTML RangeAction () m)
rangeThumb st ts total startEdge idx value =
  [ wrapper ] <> bubble
  where
  bubble =
    if st.isFormControl && st.name /= "" then
      [ rangeBubbleInput (if length (current st.ctrl) > 1 then st.name <> "[]" else st.name) value ]
    else []
  wrapper =
    let
      pct = percent ts value
      mlabel = thumbLabel idx total
      -- radix getThumbInBoundsOffset(width,left,dir): for horizontal LTR the in-bounds
      -- offset is halfWidth·(1 − pct/50)·dir, i.e. POSITIVE when the thumb sits left of
      -- centre (pct < 50), zero at 50, NEGATIVE past centre (pct > 50). The magnitude is a
      -- post-measure px the DOM oracle normalizes to `<px>`, but the SIGN/operator is part of
      -- the serialized `calc()` and is deterministic from pct — so it must be reproduced.
      op = if pct > 50.0 then "-" else "+"
    in
      HH.span
      [ HP.attr (HH.AttrName "style")
          ("transform: var(--radix-slider-thumb-transform); position: absolute; " <> startEdge <> ": calc(" <> fmtPct pct <> "% " <> op <> " 0px);")
      ]
      [ HH.span
          ( [ classes st.style.thumb
            , HP.ref (rangeThumbRef idx)
            , role "slider"
            ]
              <> (case mlabel of
                    Just l -> [ aria "label" l ]
                    Nothing -> [])
              <>
                [ aria "valuemin" (show st.min)
                , aria "valuenow" (show value)
                , aria "valuemax" (show st.max)
                , aria "orientation" (orientationName st.orientation)
                , dataOrientation st.orientation
                , dataAttr "radix-collection-item" ""
                , HP.attr (HH.AttrName "style") ""
                , HE.onKeyDown (RangeThumbKeyDown idx)
                ]
              <> (if st.disabled then [] else [ HP.tabIndex 0 ])
              <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
          )
          []
      ]

-- | Clamp a proposed new value for thumb `idx` so it never crosses (or comes within
-- | minStepsBetweenThumbs·step of) its neighbours — radix `hasMinStepsBetweenValues`.
-- | If the constraint is violated the update is rejected (Nothing).
rangeClampNeighbour :: RangeState -> Array Int -> Int -> Int -> Maybe Int
rangeClampNeighbour st values idx proposed =
  let
    gap = st.minStepsBetweenThumbs * st.step
    lower = values !! (idx - 1)
    upper = values !! (idx + 1)
    okLower = case lower of
      Just lo -> proposed - lo >= gap
      Nothing -> true
    okUpper = case upper of
      Just hi -> hi - proposed >= gap
      Nothing -> true
  in
    if okLower && okUpper then Just proposed else Nothing

rangeHandleAction :: forall m. MonadEffect m => RangeAction -> H.HalogenM RangeState RangeAction () RangeOutput m Unit
rangeHandleAction = case _ of
  RangeInitialize -> do
    uid <- useId
    H.modify_ _ { uid = uid }
  RangeReceive input ->
    H.modify_ \st -> st
      { ctrl = sync input.value st.ctrl
      , min = input.min
      , max = input.max
      , step = input.step
      , minStepsBetweenThumbs = input.minStepsBetweenThumbs
      , orientation = input.orientation
      , dir = input.dir
      , disabled = input.disabled
      , idPrefix = input.idPrefix
      , style = input.style
      , name = input.name
      , isFormControl = input.isFormControl
      }
  RangeThumbKeyDown idx ke -> do
    st <- H.get
    when (not st.disabled) do
      let values = current st.ctrl
      case index values idx of
        Nothing -> pure unit
        Just cur ->
          case nextValue (asThumbState st) cur (KE.key ke) (KE.shiftKey ke) of
            Nothing -> liftEffect (preventDefault (KE.toEvent ke))
            Just proposed -> do
              liftEffect (preventDefault (KE.toEvent ke))
              case rangeClampNeighbour st values idx proposed of
                Nothing -> pure unit   -- minStepsBetweenThumbs rejected the move
                Just v ->
                  when (cur /= v) $
                    case updateAt idx v values of
                      Nothing -> pure unit
                      Just next' -> do
                        H.modify_ _ { ctrl = (change next' st.ctrl).next }
                        H.raise (RangeValueChanged next')
              rangeFocusThumb idx

rangeFocusThumb :: forall m. MonadEffect m => Int -> H.HalogenM RangeState RangeAction () RangeOutput m Unit
rangeFocusThumb idx = do
  mel <- H.getHTMLElementRef (rangeThumbRef idx)
  for_ mel (liftEffect <<< HTMLElement.focus)

rangeHandleQuery :: forall m a. MonadEffect m => RangeQuery a -> H.HalogenM RangeState RangeAction () RangeOutput m (Maybe a)
rangeHandleQuery = case _ of
  SetRangeValue vs a -> do
    st <- H.get
    when (current st.ctrl /= vs) do
      H.modify_ _ { ctrl = (change vs st.ctrl).next }
      H.raise (RangeValueChanged vs)
    pure (Just a)
  GetRangeValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
