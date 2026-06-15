-- | Hydrogen.Themes.Skeleton — Skeleton.
-- |
-- | Upstream: radix-ui/themes src/components/skeleton.tsx (+ .props.tsx, .css).
-- | The loading-at-rest render (default `loading: true`) is a
-- | `<span class="rt-Skeleton" aria-hidden tabindex="-1" inert>{children}</span>`.
-- | When the child is plain text (NOT a valid React element) upstream also emits
-- | `data-inline-skeleton="true"` (which switches the CSS to a line-height:0,
-- | Arial-metrics inline box). When the child IS an element it renders via
-- | `Slot.Root` (merging onto the child) with no `data-inline-skeleton` — for the
-- | port both forms are a `<span>`, distinguished by whether the data-attr is set.
-- |
-- | `width` / `height` propDefs flow through to inline sizing; the only base class
-- | is `rt-Skeleton`. There are no size/variant/color axes. The shimmer is animated
-- | (`rt-skeleton-pulse`); the pixel gate freezes animations, so the at-rest DOM
-- | (this) is what matters. `inert` is React's empty-string sentinel → boolean attr.
-- |
-- |   * `skeleton`     — element/block form: `<span class="rt-Skeleton" …>` (no
-- |     `data-inline-skeleton`). Use over an Avatar/Box-sized child.
-- |   * `skeletonText` — inline text form: adds `data-inline-skeleton="true"`. Use
-- |     wrapping a Text run.
module Hydrogen.Themes.Skeleton
  ( skeleton
  , skeletonText
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `skeleton [] [ box… ]` → `<span class="rt-Skeleton" aria-hidden tabindex="-1"
-- | inert>…</span>`. The element/block form (no `data-inline-skeleton`), matching
-- | upstream's `Slot.Root` branch for a valid-element child.
skeleton :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
skeleton props =
  el "span" [ "rt-Skeleton" ]
    ( [ RawAttr "aria-hidden" "true"
      , RawAttr "tabindex" "-1"
      , RawAttr "inert" ""
      ] <> props
    )

-- | `skeletonText [] [ HH.text "…" ]` → adds `data-inline-skeleton="true"`, the
-- | plain-text branch of upstream's `<span>`. The CSS uses this to neutralize font
-- | metrics so the box matches the un-skeletoned text.
skeletonText :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
skeletonText props =
  el "span" [ "rt-Skeleton" ]
    ( [ RawAttr "aria-hidden" "true"
      , RawAttr "tabindex" "-1"
      , RawAttr "inert" ""
      , DataAttr "inline-skeleton" "true"
      ] <> props
    )
