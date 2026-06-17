-- | Hydrogen.Radix.AccessibleIcon — give a decorative icon an accessible name
-- | (radix `AccessibleIcon`). Stateless.
-- |
-- | Upstream (accessible-icon.tsx:14-26) renders a React FRAGMENT — NO wrapper
-- | element — of exactly two siblings:
-- |   1. the single icon child, `cloneElement`-ed with `aria-hidden="true"` +
-- |      `focusable="false"` injected ONTO the icon node itself, then
-- |   2. a `<VisuallyHidden>` holding the `label`.
-- |
-- | Halogen HTML is opaque once built, so we cannot `cloneElement` attrs onto the
-- | passed icon the way React does. The contract therefore is: the caller authors
-- | the icon already carrying `aria-hidden="true"` / `focusable="false"` (so the
-- | a11y attrs land on the svg itself, NOT on an extra wrapper span the way a naive
-- | port would do), and this primitive splices `[icon, VisuallyHidden label]` as
-- | siblings with NO wrapping element — node-for-node the upstream fragment.
module Hydrogen.Radix.AccessibleIcon
  ( accessibleIcon
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Radix.VisuallyHidden (visuallyHidden_)

-- | `accessibleIcon { label } iconSiblings` → the icon child(ren) followed by a
-- | visually-hidden label span, as SIBLINGS (no wrapper). The icon should already
-- | carry `aria-hidden="true"` / `focusable="false"` (as upstream injects onto it).
accessibleIcon :: forall w i. { label :: String } -> Array HH.PlainHTML -> Array (HH.HTML w i)
accessibleIcon o icon =
  map HH.fromPlainHTML icon
    <> [ visuallyHidden_ [ HH.text o.label ] ]
