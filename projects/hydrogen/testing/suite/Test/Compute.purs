-- | Coverage for Hydrogen.Radix.Float.Compute — the closed-form floating-ui solve.
-- | Pure geometry, so every expected coordinate is computed by hand from a fixed
-- | anchor/floating/offset. (Side/Align derive Eq but not Show, so placement
-- | identity is checked with `assert (… == …)` rather than `assertEqual`.)
module Test.Compute (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Radix.Float.Compute (coordsFromPlacement, computePosition, fits, flip, flipPlacement, oppositeSide, shift)
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..))
import Hydrogen.Test.Assert (assert, assertEqual, section)

-- A fixed scenario, all values chosen to stay exactly representable.
anchor :: { x :: Number, y :: Number, width :: Number, height :: Number }
anchor = { x: 100.0, y: 100.0, width: 50.0, height: 20.0 }

floating :: { width :: Number, height :: Number }
floating = { width: 80.0, height: 40.0 }

offset :: Number
offset = 8.0

viewport :: { x :: Number, y :: Number, width :: Number, height :: Number }
viewport = { x: 0.0, y: 0.0, width: 1000.0, height: 1000.0 }

suite :: Effect Unit
suite = do
  section "Compute — oppositeSide / flipPlacement" do
    assert "Top -> Bottom" (oppositeSide Top == Bottom)
    assert "Bottom -> Top" (oppositeSide Bottom == Top)
    assert "Left -> Right" (oppositeSide Left == Right)
    assert "Right -> Left" (oppositeSide Right == Left)
    let fp = flipPlacement { side: Bottom, align: Start }
    assert "flipPlacement flips side, keeps align" (fp.side == Top && fp.align == Start)

  section "Compute — coordsFromPlacement (anchor 100,100 50x20; floating 80x40; offset 8)" do
    assertEqual "Bottom/Start" { x: 100.0, y: 128.0 } (coordsFromPlacement anchor floating offset { side: Bottom, align: Start })
    assertEqual "Top/Start" { x: 100.0, y: 52.0 } (coordsFromPlacement anchor floating offset { side: Top, align: Start })
    assertEqual "Bottom/Center" { x: 85.0, y: 128.0 } (coordsFromPlacement anchor floating offset { side: Bottom, align: Center })
    assertEqual "Bottom/End" { x: 70.0, y: 128.0 } (coordsFromPlacement anchor floating offset { side: Bottom, align: End })
    assertEqual "Right/Start" { x: 158.0, y: 100.0 } (coordsFromPlacement anchor floating offset { side: Right, align: Start })
    assertEqual "Left/Start" { x: 12.0, y: 100.0 } (coordsFromPlacement anchor floating offset { side: Left, align: Start })

  section "Compute — fits" do
    assert "fits in a big viewport" (fits viewport floating { x: 100.0, y: 128.0 })
    assert "off the left edge does not fit" (not (fits viewport floating { x: -10.0, y: 0.0 }))
    assert "off the bottom edge does not fit" (not (fits viewport floating { x: 0.0, y: 970.0 }))
    assert "flush to the far corner fits" (fits viewport floating { x: 920.0, y: 960.0 })

  section "Compute — flip (requested if it fits, else opposite)" do
    -- Bottom fits in the big viewport -> keep Bottom.
    let keep = flip { anchor, floating, placement: { side: Bottom, align: Start }, offset, boundary: viewport, padding: 0.0 }
    assert "keeps Bottom when it fits" (keep.side == Bottom)
    -- Anchor near the bottom edge: Bottom overflows, Top fits -> flip to Top.
    let
      lowAnchor = { x: 50.0, y: 170.0, width: 50.0, height: 20.0 }
      smallVp = { x: 0.0, y: 0.0, width: 200.0, height: 200.0 }
      flipped = flip { anchor: lowAnchor, floating, placement: { side: Bottom, align: Start }, offset, boundary: smallVp, padding: 0.0 }
    assert "flips to Top when Bottom overflows" (flipped.side == Top)

  section "Compute — shift (clamp into the padded boundary)" do
    let small = { x: 0.0, y: 0.0, width: 100.0, height: 100.0 }
    assertEqual "clamps a negative x to the padded edge" { x: 5.0, y: 50.0 } (shift small floating 5.0 { x: -20.0, y: 50.0 })
    assertEqual "leaves an in-bounds coord alone" { x: 10.0, y: 10.0 } (shift small floating 5.0 { x: 10.0, y: 10.0 })

  section "Compute — computePosition (end to end)" do
    let p = computePosition { anchor, floating, placement: { side: Bottom, align: Start }, offset, boundary: viewport, padding: 0.0 }
    assertEqual "x of the solved position" 100.0 p.x
    assertEqual "y of the solved position" 128.0 p.y
    assert "placement echoes Bottom/Start" (p.placement.side == Bottom && p.placement.align == Start)
