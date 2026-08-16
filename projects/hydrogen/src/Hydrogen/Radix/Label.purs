-- | Hydrogen.Radix.Label — a form label (radix `Label`). Stateless render fn.
-- | `for` associates it with a control by id.
-- |
-- | Upstream (label.tsx) is a `Primitive.label` that spreads `{...props}` (so id /
-- | data-* / aria-* / title / style / handlers all pass through) and adds an
-- | `onMouseDown` that suppresses text selection on multi-click (detail > 1) UNLESS the
-- | mousedown target is inside a button/input/select/textarea. That pointer behavior is
-- | a browser-selection side effect (NOT DOM-observable in a structural snapshot) and is
-- | tracked as a residual — `labelWith` here closes the DOM-observable surface: the
-- | `for` association attribute and arbitrary prop/attr pass-through.
module Hydrogen.Radix.Label
  ( label
  , label_
  , labelWith
  , Slot
  , Input
  , GuardAction(..)
  , component
  ) where

import Prelude

import Data.Const (Const)
import Data.Maybe (Maybe(..), isJust)
import DOM.HTML.Indexed (HTMLlabel)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)
import Web.DOM.Element (closest, fromEventTarget) as Element
import Web.DOM.ParentNode (QuerySelector(..))
import Web.Event.Event (defaultPrevented, preventDefault, target) as Event
import Web.UIEvent.MouseEvent (MouseEvent, toEvent, toUIEvent) as ME
import Web.UIEvent.UIEvent (detail) as UIEvent

label :: forall w i. { for :: String, class_ :: ClassNames } -> Array HH.PlainHTML -> HH.HTML w i
label opts children =
  HH.label [ HP.for opts.for, classes opts.class_ ] (map HH.fromPlainHTML children)

label_ :: forall w i. Array HH.PlainHTML -> HH.HTML w i
label_ children = HH.label_ (map HH.fromPlainHTML children)

-- | `labelWith` — the full prop surface: `for` association, own classes, and arbitrary
-- | native label attrs (id / data-* / aria-* / title / style / handlers), mirroring
-- | upstream's `{...props}` spread. `attrs` is appended LAST (last-wins on collision).
labelWith
  :: forall w i
   . { for :: String, class_ :: ClassNames, attrs :: Array (HH.IProp HTMLlabel i) }
  -> Array HH.PlainHTML
  -> HH.HTML w i
labelWith o children =
  HH.label
    ([ HP.for o.for, classes o.class_ ] <> o.attrs)
    (map HH.fromPlainHTML children)

-- ─────────────────────────────────────────────────────────────────────────────
-- The onMouseDown text-selection guard (label.tsx:19-27).
--
-- Upstream's ONLY non-trivial behavior over a bare <label>: an `onMouseDown` that
--   1. RETURNS EARLY when the mousedown target is inside a button/input/select/
--      textarea (so wrapping an interactive control does NOT consume its pointer
--      interaction — and the user's onMouseDown is intentionally skipped on that
--      path), and
--   2. otherwise, after the user's handler ran, calls `preventDefault()` IFF the
--      event is not already default-prevented AND `event.detail > 1` (a double/
--      multi-click) — suppressing the browser's text-selection-on-multi-click.
--
-- This is genuinely missing from the pure render functions above (a render fn can
-- emit no handler). The faithful reproduction needs a node that owns an action, so
-- `component` is a self-contained Halogen component carrying exactly this listener
-- and nothing else — node-for-node a <label> plus the guard. The DOM snapshot is
-- unchanged by the guard (preventDefault leaves no attribute), so a normalized-DOM
-- oracle sees golden==port trivially; the behavior is adjudicated by a driver that
-- dispatches a detail=2 mousedown and asserts `event.defaultPrevented`.
--
-- The interactive-control selector is upstream's verbatim "button, input, select,
-- textarea".

type Slot id = H.Slot (Const Void) Void id

-- | A guarded label: `for` association, own classes, arbitrary native attrs, and
-- | inner children — same surface as `labelWith`, plus the onMouseDown guard. The
-- | attrs may not themselves emit actions (the only action is the internal guard).
type Input =
  { for :: String
  , class_ :: ClassNames
  , attrs :: Array (HH.IProp HTMLlabel GuardAction)
  , children :: Array HH.PlainHTML
  }

-- | The component's single action: a mousedown to be adjudicated by the guard.
data GuardAction = MouseDown ME.MouseEvent

component :: forall o m. MonadEffect m => H.Component (Const Void) Input o m
component =
  H.mkComponent
    { initialState: identity
    , render
    , eval: H.mkEval H.defaultEval { handleAction = handleAction }
    }
  where
  render st =
    HH.label
      ( [ HP.for st.for
        , classes st.class_
        , HE.onMouseDown MouseDown
        ]
          <> st.attrs
      )
      (map (map absurd <<< HH.fromPlainHTML) st.children)

  handleAction (MouseDown me) = do
    let
      ev = ME.toEvent me
    -- target.closest('button, input, select, textarea') → return early.
    inControl <- liftEffect case Event.target ev >>= Element.fromEventTarget of
      Just el -> do
        m <- Element.closest (QuerySelector "button, input, select, textarea") el
        pure (isJust m)
      Nothing -> pure false
    when (not inControl) do
      -- (user onMouseDown would run here) — then: !defaultPrevented && detail>1 ⇒ preventDefault.
      already <- liftEffect (Event.defaultPrevented ev)
      let multi = UIEvent.detail (ME.toUIEvent me) > 1
      when (not already && multi) (liftEffect (Event.preventDefault ev))
