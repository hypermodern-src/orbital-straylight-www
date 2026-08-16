-- | Hydrogen.Radix.Separator — a visual/semantic divider (radix `Separator`).
-- | Stateless. Decorative separators are hidden from the a11y tree (`role=none`);
-- | semantic ones get `role=separator` and `aria-orientation` (only when vertical,
-- | matching radix — horizontal is the separator default).
-- |
-- | Upstream (separator.tsx) emits `data-orientation={orientation}` ALWAYS, then the
-- | semantic props (role / aria-orientation), then spreads `{...domProps}` LAST so a
-- | caller attr can override the computed role/aria. We mirror that ordering: the
-- | caller's `attrs` array is appended after the data/semantic attrs (Halogen keeps the
-- | LAST attribute of a duplicated name, matching React's `{...semanticProps}{...domProps}`).
module Hydrogen.Radix.Separator
  ( separator
  , separator_
  , Input
  , defaultInput
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv)
import Halogen.HTML as HH
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), classes, dataOrientation, orientationName, role, aria)

-- | `class_` is the separator's own classes; `attrs` is the arbitrary-prop escape hatch
-- | (id / style / data-* / handlers), appended LAST so callers can also override role/aria.
type Input i =
  { orientation :: Orientation
  , decorative :: Boolean
  , class_ :: ClassNames
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

-- | `defaultInput` — horizontal, semantic, no class, no extra attrs.
defaultInput :: forall i. Input i
defaultInput = { orientation: Horizontal, decorative: false, class_: mempty, attrs: [] }

separator :: forall w i. Input i -> HH.HTML w i
separator o =
  HH.div
    ( [ classes o.class_, dataOrientation o.orientation ]
        <> semantics
        <> o.attrs
    )
    []
  where
  semantics =
    if o.decorative then [ role "none" ]
    else case o.orientation of
      Vertical -> [ role "separator", aria "orientation" (orientationName Vertical) ]
      Horizontal -> [ role "separator" ]

-- | `separator_ orientation decorative` — the common case without extra class/attrs.
separator_ :: forall w i. Orientation -> Boolean -> HH.HTML w i
separator_ orientation decorative =
  separator (defaultInput { orientation = orientation, decorative = decorative })
