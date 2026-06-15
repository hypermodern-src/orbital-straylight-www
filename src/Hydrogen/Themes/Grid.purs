-- | Hydrogen.Themes.Grid — Grid, the CSS grid layout primitive.
-- |
-- | Upstream: radix-ui/themes src/components/grid.tsx (+ grid.props.tsx,
-- | grid.css). A `<div class="rt-Grid">`; `.rt-Grid` sets `display: grid`
-- | (plus the stretch / flex-start / single-column initial values), so there
-- | is NO size/variant default — every track/gap/alignment token comes from
-- | the caller's props.
-- |
-- | The grid axes are all in the engine: `Columns`/`Rows` (→ `rt-r-gtc`/
-- | `rt-r-gtr`, enum 1–9), `Flow` (→ `rt-r-gaf`), `Gap` (→ `rt-r-gap`),
-- | `Align` (align-items → `rt-r-ai`), `Justify` (justify-content → `rt-r-jc`,
-- | with `between`→`space-between`), `AlignContent` (→ `rt-r-ac`) and
-- | `JustifyItems` (→ `rt-r-ji`). Margin/padding props apply too. `Color`
-- | realizes to `data-accent-color`, `Radius` to `data-radius`.
module Hydrogen.Themes.Grid
  ( grid
  ) where

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop, el)

-- | A CSS grid container. `grid [ Columns "3", Gap "3" ] [ … ]`. `rt-Grid`
-- | provides `display: grid`; pass `Columns`/`Rows`/`Flow`/`Gap`/`Align`/
-- | `Justify`/`AlignContent`/`JustifyItems` as props.
grid :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
grid = el "div" [ "rt-Grid" ]
