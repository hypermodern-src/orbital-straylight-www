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
  ) where

import Prelude

import Data.Int (round, toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_)
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
import Web.Event.Event (preventDefault)
import Web.HTML.HTMLElement as HTMLElement
import Web.UIEvent.KeyboardEvent as KE

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
  }

data Action
  = Initialize
  | Receive Input
  | ThumbKeyDown KE.KeyboardEvent

-- | The thumb ref — component-internal, keyed off a stable label (never serialized; the
-- | per-mount `uid` is minted after first render, so it must NOT key the ref).
thumbRef :: H.RefLabel
thumbRef = H.RefLabel "slider-thumb"

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
        , aria "disabled" (if st.disabled then "true" else "false")
        , dataOrientation st.orientation
        , HP.attr (HH.AttrName "style") ("--radix-slider-thumb-transform: " <> thumbTransform <> ";")
        ]
          -- only SliderHorizontal forwards `dir` to SliderImpl (radix); SliderVertical omits it.
          <> (if isVertical then [] else [ HP.attr (HH.AttrName "dir") (dirName st.dir) ])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
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

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    st <- H.get
    setValue (snapClamp st v)
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
