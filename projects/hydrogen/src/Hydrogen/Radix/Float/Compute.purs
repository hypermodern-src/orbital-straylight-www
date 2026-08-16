-- | Hydrogen.Radix.Float.Compute — native floating-ui positioning, the pure core.
-- |
-- | A CLOSED-FORM function over the finite placement lattice (`Side × Align` = 12
-- | placements) — no middleware loop, no reset, no fuel (see PORTING.md). Total by
-- | construction: `flip` is `find fits` over a fixed candidate list, `shift` is a
-- | clamp, `offset` is arithmetic. All geometry is pure PureScript; only the
-- | rect measurements (Float.Popper) touch the DOM.
-- |
-- |   computePosition ≈ shift ∘ coordsFromPlacement ∘ flip
-- |
-- | Reuses `Style.Side`/`Style.Align` as the placement axes.
module Hydrogen.Radix.Float.Compute
  ( Rect
  , Size
  , Coords
  , Placement
  , Positioned
  , Options
  , oppositeSide
  , flipPlacement
  , coordsFromPlacement
  , fits
  , flip
  , shift
  , computePosition
  ) where

import Prelude hiding (flip)

import Data.Array (find)
import Data.Maybe (fromMaybe)
import Hydrogen.Radix.Foundation.Style (Side(..), Align(..))

-- | A measured rectangle in viewport coordinates.
type Rect = { x :: Number, y :: Number, width :: Number, height :: Number }

-- | Just the dimensions of the floating element (its position is what we solve).
type Size = { width :: Number, height :: Number }

type Coords = { x :: Number, y :: Number }

-- | A placement = which side of the anchor + alignment along that side.
type Placement = { side :: Side, align :: Align }

-- | The solved position + the placement actually used (may differ from requested
-- | after `flip`), which the floating element echoes as `data-side`/`data-align`.
type Positioned = { x :: Number, y :: Number, placement :: Placement }

type Options =
  { anchor :: Rect       -- the trigger/anchor rect
  , floating :: Size     -- the floating element's size
  , placement :: Placement
  , offset :: Number     -- gap between anchor and floating, main axis
  , boundary :: Rect     -- the clipping boundary (usually the viewport)
  , padding :: Number    -- min gap from the boundary edges
  }

oppositeSide :: Side -> Side
oppositeSide = case _ of
  Top -> Bottom
  Bottom -> Top
  Left -> Right
  Right -> Left

-- | Flip to the opposite side, keeping alignment.
flipPlacement :: Placement -> Placement
flipPlacement p = p { side = oppositeSide p.side }

-- | The floating element's top-left for a given placement around the anchor.
coordsFromPlacement :: Rect -> Size -> Number -> Placement -> Coords
coordsFromPlacement anchor fl offset { side, align } =
  case side of
    Top -> { x: alignX, y: anchor.y - fl.height - offset }
    Bottom -> { x: alignX, y: anchor.y + anchor.height + offset }
    Left -> { x: anchor.x - fl.width - offset, y: alignY }
    Right -> { x: anchor.x + anchor.width + offset, y: alignY }
  where
  alignX = case align of
    Start -> anchor.x
    Center -> anchor.x + (anchor.width - fl.width) / 2.0
    End -> anchor.x + anchor.width - fl.width
  alignY = case align of
    Start -> anchor.y
    Center -> anchor.y + (anchor.height - fl.height) / 2.0
    End -> anchor.y + anchor.height - fl.height

-- | Does the floating element at these coords fit within the boundary?
fits :: Rect -> Size -> Coords -> Boolean
fits boundary fl c =
  c.x >= boundary.x
    && c.y >= boundary.y
    && c.x + fl.width <= boundary.x + boundary.width
    && c.y + fl.height <= boundary.y + boundary.height

-- | Shrink a rect inward on all sides by `p` — the collision boundary radix uses for
-- | flip/shift is the viewport inset by `collisionPadding`, NOT the raw viewport.
insetRect :: Number -> Rect -> Rect
insetRect p r = { x: r.x + p, y: r.y + p, width: r.width - 2.0 * p, height: r.height - 2.0 * p }

-- | Pick the first placement that fits: the requested one, else its opposite, else (fall
-- | back to) the requested one. The fits-check is against the boundary inset by `padding`
-- | (the collision boundary), matching radix — otherwise a placement that overflows the
-- | collision gutter is wrongly judged to fit and never flips. Closed-form over the
-- | finite candidates.
flip :: Options -> Placement
flip o =
  let
    boundary = insetRect o.padding o.boundary
    candidates = [ o.placement, flipPlacement o.placement ]
    ok p = fits boundary o.floating (coordsFromPlacement o.anchor o.floating o.offset p)
  in
    fromMaybe o.placement (find ok candidates)

-- | Clamp the coords so the floating element stays within the padded boundary.
shift :: Rect -> Size -> Number -> Coords -> Coords
shift boundary fl padding c =
  { x: clampN (boundary.x + padding) (boundary.x + boundary.width - fl.width - padding) c.x
  , y: clampN (boundary.y + padding) (boundary.y + boundary.height - fl.height - padding) c.y
  }

-- | clamp that degrades gracefully when the range is inverted (floating bigger
-- | than boundary): the low bound wins, so the element pins to the start edge.
clampN :: Number -> Number -> Number -> Number
clampN lo hi v = max lo (min hi v)

-- | The whole closed-form solve.
computePosition :: Options -> Positioned
computePosition o =
  let
    placement = flip o
    c0 = coordsFromPlacement o.anchor o.floating o.offset placement
    c = shift o.boundary o.floating o.padding c0
  in
    { x: c.x, y: c.y, placement }
