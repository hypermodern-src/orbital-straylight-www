-- | Property-based coverage for Hydrogen.Radix.Float.Compute — the closed-form
-- | floating-ui solve over the finite `Side × Align` lattice. The example suite
-- | pins concrete placements; this quantifies the geometry invariants.
module Test.Prop.Compute (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Radix.Float.Compute (coordsFromPlacement, computePosition, fits, flipPlacement, oppositeSide)
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..))
import Hydrogen.Test.Gen (genAlign, genRect, genSide, genSize)
import Hydrogen.Test.Prop (prop)
import Test.QuickCheck ((/==), (<?>), (===))
import Test.QuickCheck.Gen (Gen, choose)

-- A non-negative gap (offset / padding) — main-axis spacing is always >= 0.
genGap :: Gen Number
genGap = choose 0.0 200.0

-- Floating-point slack. `shift` clamps to exactly `boundary edge - fl size`, where
-- `(X - f) + f` can round a sub-ULP past `X`; geometric inequalities at the exact
-- edge are checked within this epsilon (the involution/assignment props stay exact).
eps :: Number
eps = 1.0e-6

-- A boundary grown by epsilon on every side (absorbs sub-ULP clamp overflow).
padded :: forall r. { x :: Number, y :: Number, width :: Number, height :: Number | r } -> { x :: Number, y :: Number, width :: Number, height :: Number }
padded b = { x: b.x - eps, y: b.y - eps, width: b.width + 2.0 * eps, height: b.height + 2.0 * eps }

suite :: Effect Unit
suite = do
  -- oppositeSide is an involution: flipping a side twice is the identity.
  prop "oppositeSide is an involution" $
    genSide <#> \s -> oppositeSide (oppositeSide s) === s

  -- ...and a genuine swap, never the identity (catches a no-op bug).
  prop "oppositeSide is never the identity" $
    genSide <#> \s -> oppositeSide s /== s

  -- flipPlacement is an involution: the side returns and the align is untouched.
  prop "flipPlacement is an involution (side returns, align preserved)" $
    (\side align -> { side, align }) <$> genSide <*> genAlign <#> \p ->
      let p2 = flipPlacement (flipPlacement p)
      in (p2.side == p.side && p2.align == p.align)
           <?> ("flipPlacement² changed " <> show p.side <> "/" <> show p.align)

  -- flipPlacement swaps to the opposite side and keeps the alignment.
  prop "flipPlacement flips to the opposite side, keeping align" $
    (\side align -> { side, align }) <$> genSide <*> genAlign <#> \p ->
      let fp = flipPlacement p
      in (fp.side == oppositeSide p.side && fp.align == p.align)
           <?> ("flipPlacement of " <> show p.side <> "/" <> show p.align <> " = " <> show fp.side)

  -- coordsFromPlacement with align = Start pins the cross axis to the anchor's
  -- origin: x = anchor.x for Top/Bottom, y = anchor.y for Left/Right.
  prop "coordsFromPlacement (align = Start) pins the cross axis to the anchor" $
    (\anchor fl side off -> { anchor, fl, side, off })
      <$> genRect <*> genSize <*> genSide <*> genGap <#> \i ->
      let c = coordsFromPlacement i.anchor i.fl i.off { side: i.side, align: Start }
      in case i.side of
        Top -> c.x === i.anchor.x
        Bottom -> c.x === i.anchor.x
        Left -> c.y === i.anchor.y
        Right -> c.y === i.anchor.y

  -- The main axis respects the side: a Top placement sits fully above the anchor
  -- (its bottom edge is at or above anchor.y), a Bottom placement fully below.
  prop "coordsFromPlacement Top/Bottom places the floating on the correct main axis" $
    (\anchor fl align off -> { anchor, fl, align, off })
      <$> genRect <*> genSize <*> genAlign <*> genGap <#> \i ->
      let
        cTop = coordsFromPlacement i.anchor i.fl i.off { side: Top, align: i.align }
        cBot = coordsFromPlacement i.anchor i.fl i.off { side: Bottom, align: i.align }
      in
        (cTop.y + i.fl.height <= i.anchor.y + eps && cBot.y + eps >= i.anchor.y + i.anchor.height)
          <?> ("Top/Bottom main-axis wrong: cTop.y=" <> show cTop.y <> " cBot.y=" <> show cBot.y)

  -- shift clamps into the boundary: with a boundary at least as large as the
  -- floating element (and padding = 0), the shifted coords always fit.
  prop "computePosition into an oversized boundary always fits" $
    (\base fl slack off align side -> { base, fl, slack, off, align, side })
      <$> genRect <*> genSize <*> genSize <*> genGap <*> genAlign <*> genSide <#> \i ->
      let
        boundary =
          { x: i.base.x
          , y: i.base.y
          , width: i.fl.width + i.slack.width
          , height: i.fl.height + i.slack.height
          }
        positioned = computePosition
          { anchor: i.base
          , floating: i.fl
          , placement: { side: i.side, align: i.align }
          , offset: i.off
          , boundary
          , padding: 0.0
          }
      in
        fits (padded boundary) i.fl { x: positioned.x, y: positioned.y }
          <?> "shifted coords escaped an oversized boundary"

  -- computePosition's chosen side is either the requested side or its opposite —
  -- flip only ever picks from { requested, opposite }, never a third side.
  prop "computePosition.side is the requested side or its opposite" $
    (\anchor fl boundary off pad align side -> { anchor, fl, boundary, off, pad, align, side })
      <$> genRect <*> genSize <*> genRect <*> genGap <*> genGap <*> genAlign <*> genSide <#> \i ->
      let
        positioned = computePosition
          { anchor: i.anchor
          , floating: i.fl
          , placement: { side: i.side, align: i.align }
          , offset: i.off
          , boundary: i.boundary
          , padding: i.pad
          }
        chosen = positioned.placement.side
      in
        (chosen == i.side || chosen == oppositeSide i.side)
          <?> ("computePosition chose " <> show chosen <> " for requested " <> show i.side)
