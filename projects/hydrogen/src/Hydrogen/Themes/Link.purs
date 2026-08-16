-- | Hydrogen.Themes.Link — the Radix Themes Link.
-- |
-- | Mirrors `link.tsx`: Link renders a `<Text asChild>` whose Slot merges its
-- | class onto the child `<a>`. The resulting anchor therefore carries Text's
-- | `rt-Text` plus Link's own `rt-reset rt-Link` (see link.tsx's
-- | `classNames('rt-reset', 'rt-Link', className)`), with the realized prop
-- | tokens. Per link.props.tsx the only enum with a default is `underline`
-- | (default `auto` → `rt-underline-auto`); `size`/`weight`/`color` etc. have no
-- | default and are applied only when passed. `color` realizes to
-- | `data-accent-color`, `underline` to `rt-underline-*`, `size` to `rt-r-size-*`.
-- | `asChild`/Slot collapses to this single `<a>` tag (cf. Typography).
module Hydrogen.Themes.Link
  ( link
  , underline
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `link "#" [ Size "3" ] [ HH.text "docs" ]` → an `<a href="#">` carrying
-- | `rt-reset rt-Link rt-Text rt-underline-auto` plus any caller tokens. The
-- | underline default is written FIRST so a later `underline` (last-wins axis)
-- | overrides it.
link :: forall w i. String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
link href props =
  el "a" [ "rt-reset", "rt-Link", "rt-Text" ]
    ([ RawAttr "href" href, underline "auto", DataAttr "accent-color" "" ] <> props)

-- | The `underline` enum token (`auto` | `always` | `hover` | `none`) →
-- | `rt-underline-<value>`. Not a built-in engine axis, so emitted as a raw class.
underline :: String -> Prop
underline v = Class ("rt-underline-" <> v)
