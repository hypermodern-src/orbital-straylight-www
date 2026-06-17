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
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLlabel)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

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
