-- | Hydrogen.Themes.AccessibleIcon — the Radix Themes AccessibleIcon.
-- |
-- | Upstream: radix-ui/themes `src/components/accessible-icon.tsx`, which simply
-- | re-exports the primitive `@radix-ui/react-accessible-icon`'s `Root`
-- | (`primitives/packages/react/accessible-icon/src/accessible-icon.tsx`).
-- |
-- | The primitive renders a React Fragment (NO wrapper element):
-- |   1. the single icon child, cloned with the accessibility attributes
-- |      `aria-hidden="true"` and `focusable="false"` injected onto it, then
-- |   2. a `<VisuallyHidden>` holding the `label` string.
-- |
-- | `VisuallyHidden` (`primitives/.../visually-hidden/src/visually-hidden.tsx`)
-- | is a bare `<span>` with NO class — only the frozen Bootstrap visually-hidden
-- | inline style block (position:absolute; border:0; width:1px; height:1px;
-- | padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0);
-- | white-space:nowrap; word-wrap:normal). We reproduce that exact style string so
-- | the label is announced to screen readers but takes no layout space — the
-- | visible pixels are just the icon.
-- |
-- | Since the icon child arrives here as opaque `HH.HTML`, we cannot clone attrs
-- | onto it the way React does; callers author the icon with `aria-hidden="true"`
-- | and `focusable="false"` already set (the demo does). The rendered DOM —
-- | `<svg …>…</svg><span style="…">label</span>` as siblings — matches upstream.
module Hydrogen.Themes.AccessibleIcon
  ( accessibleIcon
  , visuallyHiddenStyle
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

-- | The frozen Bootstrap visually-hidden style block, byte-for-byte the order the
-- | primitive's `VISUALLY_HIDDEN_STYLES` object enumerates (React serializes a
-- | style object in insertion order; numeric values render as px). This is the
-- | only styling the VisuallyHidden span carries.
visuallyHiddenStyle :: String
visuallyHiddenStyle =
  "position: absolute; "
    <> "border: 0; "
    <> "width: 1px; "
    <> "height: 1px; "
    <> "padding: 0; "
    <> "margin: -1px; "
    <> "overflow: hidden; "
    <> "clip: rect(0, 0, 0, 0); "
    <> "white-space: nowrap; "
    <> "word-wrap: normal;"

-- | `accessibleIcon "Settings" gearSvg` → the icon followed by a visually-hidden
-- | `<span>` announcing the label. The icon should already carry
-- | `aria-hidden="true"` / `focusable="false"` (as upstream injects). Returns the
-- | two siblings as an array — Halogen has no Fragment node, so the caller splices
-- | this into a parent's children (the primitive's React Fragment adds no wrapper).
accessibleIcon :: forall w i. String -> HH.HTML w i -> Array (HH.HTML w i)
accessibleIcon label icon =
  [ icon
  , HH.span
      [ HP.attr (HH.AttrName "style") visuallyHiddenStyle ]
        [ HH.text label ]
    ]
