-- | Hydrogen.Themes.Quote — Quote (inline quotation).
-- |
-- | Upstream: radix-ui-themes/src/components/quote.tsx + quote.props.ts + quote.css.
-- | Renders a `q` element carrying the `rt-Quote` class. The propDefs are only
-- | asChild / truncate / textWrap (no size/variant/color), all of which are
-- | unset by default — so there are no component defaults to seed and the base
-- | element is just `el "q" [ "rt-Quote" ]`.
module Hydrogen.Themes.Quote
  ( quote
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

quote :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
quote = el "q" [ "rt-Quote" ]
