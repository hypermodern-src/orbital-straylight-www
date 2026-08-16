-- | Hydrogen.Themes.AccessibleIcon — the Radix Themes AccessibleIcon.
-- |
-- | Upstream: radix-ui/themes `src/components/accessible-icon.tsx`, which simply
-- | re-exports the primitive `@radix-ui/react-accessible-icon`'s `Root`
-- | (`primitives/packages/react/accessible-icon/src/accessible-icon.tsx`).
-- |
-- | The primitive renders a React Fragment (NO wrapper element):
-- |   1. the single icon child, cloned with the accessibility attributes
-- |      `aria-hidden="true"` and `focusable="false"` injected ONTO IT, then
-- |   2. a `<VisuallyHidden>` holding the `label` string.
-- |
-- | The visually-hidden label span uses `Hydrogen.Radix.VisuallyHidden` so its
-- | sr-only style is the canonical (browser-normalized) radix string — node-for-node
-- | the upstream VisuallyHidden, matching the open-DOM oracle.
-- |
-- | Since the icon child arrives here as opaque `HH.HTML`, we cannot clone attrs
-- | onto it the way React does; callers author the icon with `aria-hidden="true"`
-- | and `focusable="false"` already set (the demo does). The rendered DOM —
-- | `<svg …>…</svg><span style="…">label</span>` as siblings — matches upstream.
module Hydrogen.Themes.AccessibleIcon
  ( accessibleIcon
  ) where

import Halogen.HTML as HH
import Hydrogen.Radix.VisuallyHidden (visuallyHidden_)

-- | `accessibleIcon "Settings" gearSvg` → the icon followed by a visually-hidden
-- | `<span>` announcing the label, as SIBLINGS (the primitive's React Fragment adds
-- | no wrapper; Halogen has no Fragment node, so the caller splices this array into a
-- | parent's children). The icon should already carry `aria-hidden="true"` /
-- | `focusable="false"` (as upstream injects).
accessibleIcon :: forall w i. String -> HH.HTML w i -> Array (HH.HTML w i)
accessibleIcon label icon =
  [ icon
  , visuallyHidden_ [ HH.text label ]
  ]
