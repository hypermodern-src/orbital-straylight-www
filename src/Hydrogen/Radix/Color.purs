-- | Radix UI color scales, ported to native PureScript (data + a small CSS emitter).
-- |
-- | Source of truth: the @radix-ui/colors@ npm package (light.ts / dark.ts /
-- | blackA.ts / whiteA.ts). This is a mechanical DATA port: the hex/rgba strings
-- | are copied verbatim. No FFI, no JS.
-- |
-- | ## What is included
-- |
-- |   * SOLID scales for all 31 hues, in both Light and Dark appearances.
-- |     (gray mauve slate sage olive sand tomato red ruby crimson pink plum
-- |      purple violet iris indigo blue cyan teal jade green grass brown bronze
-- |      gold sky mint lime yellow amber orange)
-- |   * ALPHA (translucent) scales for all 31 hues, Light and Dark.
-- |   * The blackA / whiteA neutral alpha overlays.
-- |
-- | ## What is DEFERRED
-- |
-- | The P3 wide-gamut variants (@*P3@, @*P3A@) are intentionally NOT ported.
-- | They roughly double the data and their values are @color(display-p3 ...)@
-- | function strings rather than plain hex, so they do not fit the @Scale@
-- | (12 hex strings) shape cleanly. Add them later as a separate P3 layer if
-- | wide-gamut output is needed.
-- |
-- | ## Naming convention
-- |
-- | Every scale is a top-level @Scale@ value named:
-- |
-- |     <hue><Variant?><Appearance>
-- |
-- |   * @tomatoLight@,  @tomatoDark@            -- solid
-- |   * @tomatoAlphaLight@, @tomatoAlphaDark@   -- alpha
-- |   * @blackAlpha@, @whiteAlpha@              -- neutral overlays (appearance-free)
-- |
-- | The "gray families" (gray mauve slate sage olive sand) are just hues like
-- | any other; they have no special casing here.
-- |
-- | ## The 12-step semantics (radix's fixed meaning — load-bearing for presets)
-- |
-- |   1  - app background
-- |   2  - subtle app background
-- |   3  - component background
-- |   4  - hover component background
-- |   5  - active / selected component background
-- |   6  - subtle border / separator
-- |   7  - border / focus ring
-- |   8  - strong border / hovered border
-- |   9  - solid background (e.g. button fill)
-- |   10 - hovered solid background
-- |   11 - low-contrast text
-- |   12 - high-contrast text
-- |
-- | Steps 1-2 backgrounds, 3-5 component fills, 6-8 borders, 9-10 solids,
-- | 11-12 text.
module Hydrogen.Radix.Color
  ( Scale
  , Appearance(..)
  , Hue(..)
  , hueName
  , allHues
  , scale
  , step
  , steps
  , alphaScale
  , blackAlpha
  , whiteAlpha
  , cssVars
  , accentVars
  , grayLight
  , grayDark
  , mauveLight
  , mauveDark
  , slateLight
  , slateDark
  , sageLight
  , sageDark
  , oliveLight
  , oliveDark
  , sandLight
  , sandDark
  , tomatoLight
  , tomatoDark
  , redLight
  , redDark
  , rubyLight
  , rubyDark
  , crimsonLight
  , crimsonDark
  , pinkLight
  , pinkDark
  , plumLight
  , plumDark
  , purpleLight
  , purpleDark
  , violetLight
  , violetDark
  , irisLight
  , irisDark
  , indigoLight
  , indigoDark
  , blueLight
  , blueDark
  , cyanLight
  , cyanDark
  , tealLight
  , tealDark
  , jadeLight
  , jadeDark
  , greenLight
  , greenDark
  , grassLight
  , grassDark
  , brownLight
  , brownDark
  , bronzeLight
  , bronzeDark
  , goldLight
  , goldDark
  , skyLight
  , skyDark
  , mintLight
  , mintDark
  , limeLight
  , limeDark
  , yellowLight
  , yellowDark
  , amberLight
  , amberDark
  , orangeLight
  , orangeDark
  , grayAlphaLight
  , grayAlphaDark
  , mauveAlphaLight
  , mauveAlphaDark
  , slateAlphaLight
  , slateAlphaDark
  , sageAlphaLight
  , sageAlphaDark
  , oliveAlphaLight
  , oliveAlphaDark
  , sandAlphaLight
  , sandAlphaDark
  , tomatoAlphaLight
  , tomatoAlphaDark
  , redAlphaLight
  , redAlphaDark
  , rubyAlphaLight
  , rubyAlphaDark
  , crimsonAlphaLight
  , crimsonAlphaDark
  , pinkAlphaLight
  , pinkAlphaDark
  , plumAlphaLight
  , plumAlphaDark
  , purpleAlphaLight
  , purpleAlphaDark
  , violetAlphaLight
  , violetAlphaDark
  , irisAlphaLight
  , irisAlphaDark
  , indigoAlphaLight
  , indigoAlphaDark
  , blueAlphaLight
  , blueAlphaDark
  , cyanAlphaLight
  , cyanAlphaDark
  , tealAlphaLight
  , tealAlphaDark
  , jadeAlphaLight
  , jadeAlphaDark
  , greenAlphaLight
  , greenAlphaDark
  , grassAlphaLight
  , grassAlphaDark
  , brownAlphaLight
  , brownAlphaDark
  , bronzeAlphaLight
  , bronzeAlphaDark
  , goldAlphaLight
  , goldAlphaDark
  , skyAlphaLight
  , skyAlphaDark
  , mintAlphaLight
  , mintAlphaDark
  , limeAlphaLight
  , limeAlphaDark
  , yellowAlphaLight
  , yellowAlphaDark
  , amberAlphaLight
  , amberAlphaDark
  , orangeAlphaLight
  , orangeAlphaDark
  ) where

import Prelude

import Data.Array ((..), mapWithIndex)
import Data.Foldable (intercalate)
import Data.String (toLower)

-- | A 12-step Radix color scale. Each field is a CSS color string
-- | (hex like @"#fffcfc"@, or @rgba(...)@ for the neutral overlays).
type Scale =
  { step1 :: String
  , step2 :: String
  , step3 :: String
  , step4 :: String
  , step5 :: String
  , step6 :: String
  , step7 :: String
  , step8 :: String
  , step9 :: String
  , step10 :: String
  , step11 :: String
  , step12 :: String
  }

-- | Light or dark appearance. Selects which table a scale is drawn from.
data Appearance = Light | Dark

derive instance eqAppearance :: Eq Appearance
derive instance ordAppearance :: Ord Appearance

instance showAppearance :: Show Appearance where
  show Light = "Light"
  show Dark = "Dark"

-- | The 31 Radix hues.
data Hue = Gray | Mauve | Slate | Sage | Olive | Sand | Tomato | Red | Ruby | Crimson | Pink | Plum | Purple | Violet | Iris | Indigo | Blue | Cyan | Teal | Jade | Green | Grass | Brown | Bronze | Gold | Sky | Mint | Lime | Yellow | Amber | Orange

derive instance eqHue :: Eq Hue
derive instance ordHue :: Ord Hue

instance showHue :: Show Hue where
  show = hueName

-- | All hues, in canonical radix order.
allHues :: Array Hue
allHues =
  [ Gray
  , Mauve
  , Slate
  , Sage
  , Olive
  , Sand
  , Tomato
  , Red
  , Ruby
  , Crimson
  , Pink
  , Plum
  , Purple
  , Violet
  , Iris
  , Indigo
  , Blue
  , Cyan
  , Teal
  , Jade
  , Green
  , Grass
  , Brown
  , Bronze
  , Gold
  , Sky
  , Mint
  , Lime
  , Yellow
  , Amber
  , Orange
  ]

-- | The lowercase css/radix name of a hue (e.g. @Tomato -> "tomato"@).
hueName :: Hue -> String
hueName Gray = "gray"
hueName Mauve = "mauve"
hueName Slate = "slate"
hueName Sage = "sage"
hueName Olive = "olive"
hueName Sand = "sand"
hueName Tomato = "tomato"
hueName Red = "red"
hueName Ruby = "ruby"
hueName Crimson = "crimson"
hueName Pink = "pink"
hueName Plum = "plum"
hueName Purple = "purple"
hueName Violet = "violet"
hueName Iris = "iris"
hueName Indigo = "indigo"
hueName Blue = "blue"
hueName Cyan = "cyan"
hueName Teal = "teal"
hueName Jade = "jade"
hueName Green = "green"
hueName Grass = "grass"
hueName Brown = "brown"
hueName Bronze = "bronze"
hueName Gold = "gold"
hueName Sky = "sky"
hueName Mint = "mint"
hueName Lime = "lime"
hueName Yellow = "yellow"
hueName Amber = "amber"
hueName Orange = "orange"

-- | Select the solid scale for an appearance + hue.
scale :: Appearance -> Hue -> Scale
scale Light Gray = grayLight
scale Dark Gray = grayDark
scale Light Mauve = mauveLight
scale Dark Mauve = mauveDark
scale Light Slate = slateLight
scale Dark Slate = slateDark
scale Light Sage = sageLight
scale Dark Sage = sageDark
scale Light Olive = oliveLight
scale Dark Olive = oliveDark
scale Light Sand = sandLight
scale Dark Sand = sandDark
scale Light Tomato = tomatoLight
scale Dark Tomato = tomatoDark
scale Light Red = redLight
scale Dark Red = redDark
scale Light Ruby = rubyLight
scale Dark Ruby = rubyDark
scale Light Crimson = crimsonLight
scale Dark Crimson = crimsonDark
scale Light Pink = pinkLight
scale Dark Pink = pinkDark
scale Light Plum = plumLight
scale Dark Plum = plumDark
scale Light Purple = purpleLight
scale Dark Purple = purpleDark
scale Light Violet = violetLight
scale Dark Violet = violetDark
scale Light Iris = irisLight
scale Dark Iris = irisDark
scale Light Indigo = indigoLight
scale Dark Indigo = indigoDark
scale Light Blue = blueLight
scale Dark Blue = blueDark
scale Light Cyan = cyanLight
scale Dark Cyan = cyanDark
scale Light Teal = tealLight
scale Dark Teal = tealDark
scale Light Jade = jadeLight
scale Dark Jade = jadeDark
scale Light Green = greenLight
scale Dark Green = greenDark
scale Light Grass = grassLight
scale Dark Grass = grassDark
scale Light Brown = brownLight
scale Dark Brown = brownDark
scale Light Bronze = bronzeLight
scale Dark Bronze = bronzeDark
scale Light Gold = goldLight
scale Dark Gold = goldDark
scale Light Sky = skyLight
scale Dark Sky = skyDark
scale Light Mint = mintLight
scale Dark Mint = mintDark
scale Light Lime = limeLight
scale Dark Lime = limeDark
scale Light Yellow = yellowLight
scale Dark Yellow = yellowDark
scale Light Amber = amberLight
scale Dark Amber = amberDark
scale Light Orange = orangeLight
scale Dark Orange = orangeDark

-- | Select the alpha (translucent) scale for an appearance + hue.
alphaScale :: Appearance -> Hue -> Scale
alphaScale Light Gray = grayAlphaLight
alphaScale Dark Gray = grayAlphaDark
alphaScale Light Mauve = mauveAlphaLight
alphaScale Dark Mauve = mauveAlphaDark
alphaScale Light Slate = slateAlphaLight
alphaScale Dark Slate = slateAlphaDark
alphaScale Light Sage = sageAlphaLight
alphaScale Dark Sage = sageAlphaDark
alphaScale Light Olive = oliveAlphaLight
alphaScale Dark Olive = oliveAlphaDark
alphaScale Light Sand = sandAlphaLight
alphaScale Dark Sand = sandAlphaDark
alphaScale Light Tomato = tomatoAlphaLight
alphaScale Dark Tomato = tomatoAlphaDark
alphaScale Light Red = redAlphaLight
alphaScale Dark Red = redAlphaDark
alphaScale Light Ruby = rubyAlphaLight
alphaScale Dark Ruby = rubyAlphaDark
alphaScale Light Crimson = crimsonAlphaLight
alphaScale Dark Crimson = crimsonAlphaDark
alphaScale Light Pink = pinkAlphaLight
alphaScale Dark Pink = pinkAlphaDark
alphaScale Light Plum = plumAlphaLight
alphaScale Dark Plum = plumAlphaDark
alphaScale Light Purple = purpleAlphaLight
alphaScale Dark Purple = purpleAlphaDark
alphaScale Light Violet = violetAlphaLight
alphaScale Dark Violet = violetAlphaDark
alphaScale Light Iris = irisAlphaLight
alphaScale Dark Iris = irisAlphaDark
alphaScale Light Indigo = indigoAlphaLight
alphaScale Dark Indigo = indigoAlphaDark
alphaScale Light Blue = blueAlphaLight
alphaScale Dark Blue = blueAlphaDark
alphaScale Light Cyan = cyanAlphaLight
alphaScale Dark Cyan = cyanAlphaDark
alphaScale Light Teal = tealAlphaLight
alphaScale Dark Teal = tealAlphaDark
alphaScale Light Jade = jadeAlphaLight
alphaScale Dark Jade = jadeAlphaDark
alphaScale Light Green = greenAlphaLight
alphaScale Dark Green = greenAlphaDark
alphaScale Light Grass = grassAlphaLight
alphaScale Dark Grass = grassAlphaDark
alphaScale Light Brown = brownAlphaLight
alphaScale Dark Brown = brownAlphaDark
alphaScale Light Bronze = bronzeAlphaLight
alphaScale Dark Bronze = bronzeAlphaDark
alphaScale Light Gold = goldAlphaLight
alphaScale Dark Gold = goldAlphaDark
alphaScale Light Sky = skyAlphaLight
alphaScale Dark Sky = skyAlphaDark
alphaScale Light Mint = mintAlphaLight
alphaScale Dark Mint = mintAlphaDark
alphaScale Light Lime = limeAlphaLight
alphaScale Dark Lime = limeAlphaDark
alphaScale Light Yellow = yellowAlphaLight
alphaScale Dark Yellow = yellowAlphaDark
alphaScale Light Amber = amberAlphaLight
alphaScale Dark Amber = amberAlphaDark
alphaScale Light Orange = orangeAlphaLight
alphaScale Dark Orange = orangeAlphaDark

-- | Read a 1-based step (1..12) out of a scale. Out-of-range indices are
-- | clamped into 1..12.
step :: Scale -> Int -> String
step s n = case clampStep n of
  1 -> s.step1
  2 -> s.step2
  3 -> s.step3
  4 -> s.step4
  5 -> s.step5
  6 -> s.step6
  7 -> s.step7
  8 -> s.step8
  9 -> s.step9
  10 -> s.step10
  11 -> s.step11
  _ -> s.step12

clampStep :: Int -> Int
clampStep n
  | n < 1 = 1
  | n > 12 = 12
  | otherwise = n

-- | All 12 steps of a scale, in order (step 1 first).
steps :: Scale -> Array String
steps s = map (step s) (1 .. 12)

-- | Emit CSS custom properties for a hue's scale, one per line:
-- |
-- |     --tomato-1: #fffcfc;
-- |     ...
-- |     --tomato-12: #5c271f;
-- |
-- | The @prefix@ is the variable name stem; pass @{ prefix: "tomato" }@ for
-- | radix-style @--tomato-N@, or any other stem you like.
cssVars :: { prefix :: String } -> Appearance -> Hue -> String
cssVars { prefix } appearance hue =
  emitVars prefix (steps (scale appearance hue))

-- | Emit the scale of a hue as the semantic @--accent-1 .. --accent-12@
-- | aliases that radix themes uses when a color is chosen as the accent.
accentVars :: Appearance -> Hue -> String
accentVars appearance hue =
  emitVars "accent" (steps (scale appearance hue))

-- | Internal: render @--<prefix>-<n>: <value>;@ lines, newline-joined.
emitVars :: String -> Array String -> String
emitVars prefix values =
  intercalate "\n" (mapWithIndex line values)
  where
  line :: Int -> String -> String
  line i v = "--" <> toLower prefix <> "-" <> show (i + 1) <> ": " <> v <> ";"

-- ---------------------------------------------------------------------------
-- Scale data (mechanical port).
-- ---------------------------------------------------------------------------

grayLight :: Scale
grayLight = { step1: "#fcfcfc", step2: "#f9f9f9", step3: "#f0f0f0", step4: "#e8e8e8", step5: "#e0e0e0", step6: "#d9d9d9", step7: "#cecece", step8: "#bbbbbb", step9: "#8d8d8d", step10: "#838383", step11: "#646464", step12: "#202020" }

grayDark :: Scale
grayDark = { step1: "#111111", step2: "#191919", step3: "#222222", step4: "#2a2a2a", step5: "#313131", step6: "#3a3a3a", step7: "#484848", step8: "#606060", step9: "#6e6e6e", step10: "#7b7b7b", step11: "#b4b4b4", step12: "#eeeeee" }

mauveLight :: Scale
mauveLight = { step1: "#fdfcfd", step2: "#faf9fb", step3: "#f2eff3", step4: "#eae7ec", step5: "#e3dfe6", step6: "#dbd8e0", step7: "#d0cdd7", step8: "#bcbac7", step9: "#8e8c99", step10: "#84828e", step11: "#65636d", step12: "#211f26" }

mauveDark :: Scale
mauveDark = { step1: "#121113", step2: "#1a191b", step3: "#232225", step4: "#2b292d", step5: "#323035", step6: "#3c393f", step7: "#49474e", step8: "#625f69", step9: "#6f6d78", step10: "#7c7a85", step11: "#b5b2bc", step12: "#eeeef0" }

slateLight :: Scale
slateLight = { step1: "#fcfcfd", step2: "#f9f9fb", step3: "#f0f0f3", step4: "#e8e8ec", step5: "#e0e1e6", step6: "#d9d9e0", step7: "#cdced6", step8: "#b9bbc6", step9: "#8b8d98", step10: "#80838d", step11: "#60646c", step12: "#1c2024" }

slateDark :: Scale
slateDark = { step1: "#111113", step2: "#18191b", step3: "#212225", step4: "#272a2d", step5: "#2e3135", step6: "#363a3f", step7: "#43484e", step8: "#5a6169", step9: "#696e77", step10: "#777b84", step11: "#b0b4ba", step12: "#edeef0" }

sageLight :: Scale
sageLight = { step1: "#fbfdfc", step2: "#f7f9f8", step3: "#eef1f0", step4: "#e6e9e8", step5: "#dfe2e0", step6: "#d7dad9", step7: "#cbcfcd", step8: "#b8bcba", step9: "#868e8b", step10: "#7c8481", step11: "#5f6563", step12: "#1a211e" }

sageDark :: Scale
sageDark = { step1: "#101211", step2: "#171918", step3: "#202221", step4: "#272a29", step5: "#2e3130", step6: "#373b39", step7: "#444947", step8: "#5b625f", step9: "#63706b", step10: "#717d79", step11: "#adb5b2", step12: "#eceeed" }

oliveLight :: Scale
oliveLight = { step1: "#fcfdfc", step2: "#f8faf8", step3: "#eff1ef", step4: "#e7e9e7", step5: "#dfe2df", step6: "#d7dad7", step7: "#cccfcc", step8: "#b9bcb8", step9: "#898e87", step10: "#7f847d", step11: "#60655f", step12: "#1d211c" }

oliveDark :: Scale
oliveDark = { step1: "#111210", step2: "#181917", step3: "#212220", step4: "#282a27", step5: "#2f312e", step6: "#383a36", step7: "#454843", step8: "#5c625b", step9: "#687066", step10: "#767d74", step11: "#afb5ad", step12: "#eceeec" }

sandLight :: Scale
sandLight = { step1: "#fdfdfc", step2: "#f9f9f8", step3: "#f1f0ef", step4: "#e9e8e6", step5: "#e2e1de", step6: "#dad9d6", step7: "#cfceca", step8: "#bcbbb5", step9: "#8d8d86", step10: "#82827c", step11: "#63635e", step12: "#21201c" }

sandDark :: Scale
sandDark = { step1: "#111110", step2: "#191918", step3: "#222221", step4: "#2a2a28", step5: "#31312e", step6: "#3b3a37", step7: "#494844", step8: "#62605b", step9: "#6f6d66", step10: "#7c7b74", step11: "#b5b3ad", step12: "#eeeeec" }

tomatoLight :: Scale
tomatoLight = { step1: "#fffcfc", step2: "#fff8f7", step3: "#feebe7", step4: "#ffdcd3", step5: "#ffcdc2", step6: "#fdbdaf", step7: "#f5a898", step8: "#ec8e7b", step9: "#e54d2e", step10: "#dd4425", step11: "#d13415", step12: "#5c271f" }

tomatoDark :: Scale
tomatoDark = { step1: "#181111", step2: "#1f1513", step3: "#391714", step4: "#4e1511", step5: "#5e1c16", step6: "#6e2920", step7: "#853a2d", step8: "#ac4d39", step9: "#e54d2e", step10: "#ec6142", step11: "#ff977d", step12: "#fbd3cb" }

redLight :: Scale
redLight = { step1: "#fffcfc", step2: "#fff7f7", step3: "#feebec", step4: "#ffdbdc", step5: "#ffcdce", step6: "#fdbdbe", step7: "#f4a9aa", step8: "#eb8e90", step9: "#e5484d", step10: "#dc3e42", step11: "#ce2c31", step12: "#641723" }

redDark :: Scale
redDark = { step1: "#191111", step2: "#201314", step3: "#3b1219", step4: "#500f1c", step5: "#611623", step6: "#72232d", step7: "#8c333a", step8: "#b54548", step9: "#e5484d", step10: "#ec5d5e", step11: "#ff9592", step12: "#ffd1d9" }

rubyLight :: Scale
rubyLight = { step1: "#fffcfd", step2: "#fff7f8", step3: "#feeaed", step4: "#ffdce1", step5: "#ffced6", step6: "#f8bfc8", step7: "#efacb8", step8: "#e592a3", step9: "#e54666", step10: "#dc3b5d", step11: "#ca244d", step12: "#64172b" }

rubyDark :: Scale
rubyDark = { step1: "#191113", step2: "#1e1517", step3: "#3a141e", step4: "#4e1325", step5: "#5e1a2e", step6: "#6f2539", step7: "#883447", step8: "#b3445a", step9: "#e54666", step10: "#ec5a72", step11: "#ff949d", step12: "#fed2e1" }

crimsonLight :: Scale
crimsonLight = { step1: "#fffcfd", step2: "#fef7f9", step3: "#ffe9f0", step4: "#fedce7", step5: "#facedd", step6: "#f3bed1", step7: "#eaacc3", step8: "#e093b2", step9: "#e93d82", step10: "#df3478", step11: "#cb1d63", step12: "#621639" }

crimsonDark :: Scale
crimsonDark = { step1: "#191114", step2: "#201318", step3: "#381525", step4: "#4d122f", step5: "#5c1839", step6: "#6d2545", step7: "#873356", step8: "#b0436e", step9: "#e93d82", step10: "#ee518a", step11: "#ff92ad", step12: "#fdd3e8" }

pinkLight :: Scale
pinkLight = { step1: "#fffcfe", step2: "#fef7fb", step3: "#fee9f5", step4: "#fbdcef", step5: "#f6cee7", step6: "#efbfdd", step7: "#e7acd0", step8: "#dd93c2", step9: "#d6409f", step10: "#cf3897", step11: "#c2298a", step12: "#651249" }

pinkDark :: Scale
pinkDark = { step1: "#191117", step2: "#21121d", step3: "#37172f", step4: "#4b143d", step5: "#591c47", step6: "#692955", step7: "#833869", step8: "#a84885", step9: "#d6409f", step10: "#de51a8", step11: "#ff8dcc", step12: "#fdd1ea" }

plumLight :: Scale
plumLight = { step1: "#fefcff", step2: "#fdf7fd", step3: "#fbebfb", step4: "#f7def8", step5: "#f2d1f3", step6: "#e9c2ec", step7: "#deade3", step8: "#cf91d8", step9: "#ab4aba", step10: "#a144af", step11: "#953ea3", step12: "#53195d" }

plumDark :: Scale
plumDark = { step1: "#181118", step2: "#201320", step3: "#351a35", step4: "#451d47", step5: "#512454", step6: "#5e3061", step7: "#734079", step8: "#92549c", step9: "#ab4aba", step10: "#b658c4", step11: "#e796f3", step12: "#f4d4f4" }

purpleLight :: Scale
purpleLight = { step1: "#fefcfe", step2: "#fbf7fe", step3: "#f7edfe", step4: "#f2e2fc", step5: "#ead5f9", step6: "#e0c4f4", step7: "#d1afec", step8: "#be93e4", step9: "#8e4ec6", step10: "#8347b9", step11: "#8145b5", step12: "#402060" }

purpleDark :: Scale
purpleDark = { step1: "#18111b", step2: "#1e1523", step3: "#301c3b", step4: "#3d224e", step5: "#48295c", step6: "#54346b", step7: "#664282", step8: "#8457aa", step9: "#8e4ec6", step10: "#9a5cd0", step11: "#d19dff", step12: "#ecd9fa" }

violetLight :: Scale
violetLight = { step1: "#fdfcfe", step2: "#faf8ff", step3: "#f4f0fe", step4: "#ebe4ff", step5: "#e1d9ff", step6: "#d4cafe", step7: "#c2b5f5", step8: "#aa99ec", step9: "#6e56cf", step10: "#654dc4", step11: "#6550b9", step12: "#2f265f" }

violetDark :: Scale
violetDark = { step1: "#14121f", step2: "#1b1525", step3: "#291f43", step4: "#33255b", step5: "#3c2e69", step6: "#473876", step7: "#56468b", step8: "#6958ad", step9: "#6e56cf", step10: "#7d66d9", step11: "#baa7ff", step12: "#e2ddfe" }

irisLight :: Scale
irisLight = { step1: "#fdfdff", step2: "#f8f8ff", step3: "#f0f1fe", step4: "#e6e7ff", step5: "#dadcff", step6: "#cbcdff", step7: "#b8baf8", step8: "#9b9ef0", step9: "#5b5bd6", step10: "#5151cd", step11: "#5753c6", step12: "#272962" }

irisDark :: Scale
irisDark = { step1: "#13131e", step2: "#171625", step3: "#202248", step4: "#262a65", step5: "#303374", step6: "#3d3e82", step7: "#4a4a95", step8: "#5958b1", step9: "#5b5bd6", step10: "#6e6ade", step11: "#b1a9ff", step12: "#e0dffe" }

indigoLight :: Scale
indigoLight = { step1: "#fdfdfe", step2: "#f7f9ff", step3: "#edf2fe", step4: "#e1e9ff", step5: "#d2deff", step6: "#c1d0ff", step7: "#abbdf9", step8: "#8da4ef", step9: "#3e63dd", step10: "#3358d4", step11: "#3a5bc7", step12: "#1f2d5c" }

indigoDark :: Scale
indigoDark = { step1: "#11131f", step2: "#141726", step3: "#182449", step4: "#1d2e62", step5: "#253974", step6: "#304384", step7: "#3a4f97", step8: "#435db1", step9: "#3e63dd", step10: "#5472e4", step11: "#9eb1ff", step12: "#d6e1ff" }

blueLight :: Scale
blueLight = { step1: "#fbfdff", step2: "#f4faff", step3: "#e6f4fe", step4: "#d5efff", step5: "#c2e5ff", step6: "#acd8fc", step7: "#8ec8f6", step8: "#5eb1ef", step9: "#0090ff", step10: "#0588f0", step11: "#0d74ce", step12: "#113264" }

blueDark :: Scale
blueDark = { step1: "#0d1520", step2: "#111927", step3: "#0d2847", step4: "#003362", step5: "#004074", step6: "#104d87", step7: "#205d9e", step8: "#2870bd", step9: "#0090ff", step10: "#3b9eff", step11: "#70b8ff", step12: "#c2e6ff" }

cyanLight :: Scale
cyanLight = { step1: "#fafdfe", step2: "#f2fafb", step3: "#def7f9", step4: "#caf1f6", step5: "#b5e9f0", step6: "#9ddde7", step7: "#7dcedc", step8: "#3db9cf", step9: "#00a2c7", step10: "#0797b9", step11: "#107d98", step12: "#0d3c48" }

cyanDark :: Scale
cyanDark = { step1: "#0b161a", step2: "#101b20", step3: "#082c36", step4: "#003848", step5: "#004558", step6: "#045468", step7: "#12677e", step8: "#11809c", step9: "#00a2c7", step10: "#23afd0", step11: "#4ccce6", step12: "#b6ecf7" }

tealLight :: Scale
tealLight = { step1: "#fafefd", step2: "#f3fbf9", step3: "#e0f8f3", step4: "#ccf3ea", step5: "#b8eae0", step6: "#a1ded2", step7: "#83cdc1", step8: "#53b9ab", step9: "#12a594", step10: "#0d9b8a", step11: "#008573", step12: "#0d3d38" }

tealDark :: Scale
tealDark = { step1: "#0d1514", step2: "#111c1b", step3: "#0d2d2a", step4: "#023b37", step5: "#084843", step6: "#145750", step7: "#1c6961", step8: "#207e73", step9: "#12a594", step10: "#0eb39e", step11: "#0bd8b6", step12: "#adf0dd" }

jadeLight :: Scale
jadeLight = { step1: "#fbfefd", step2: "#f4fbf7", step3: "#e6f7ed", step4: "#d6f1e3", step5: "#c3e9d7", step6: "#acdec8", step7: "#8bceb6", step8: "#56ba9f", step9: "#29a383", step10: "#26997b", step11: "#208368", step12: "#1d3b31" }

jadeDark :: Scale
jadeDark = { step1: "#0d1512", step2: "#121c18", step3: "#0f2e22", step4: "#0b3b2c", step5: "#114837", step6: "#1b5745", step7: "#246854", step8: "#2a7e68", step9: "#29a383", step10: "#27b08b", step11: "#1fd8a4", step12: "#adf0d4" }

greenLight :: Scale
greenLight = { step1: "#fbfefc", step2: "#f4fbf6", step3: "#e6f6eb", step4: "#d6f1df", step5: "#c4e8d1", step6: "#adddc0", step7: "#8eceaa", step8: "#5bb98b", step9: "#30a46c", step10: "#2b9a66", step11: "#218358", step12: "#193b2d" }

greenDark :: Scale
greenDark = { step1: "#0e1512", step2: "#121b17", step3: "#132d21", step4: "#113b29", step5: "#174933", step6: "#20573e", step7: "#28684a", step8: "#2f7c57", step9: "#30a46c", step10: "#33b074", step11: "#3dd68c", step12: "#b1f1cb" }

grassLight :: Scale
grassLight = { step1: "#fbfefb", step2: "#f5fbf5", step3: "#e9f6e9", step4: "#daf1db", step5: "#c9e8ca", step6: "#b2ddb5", step7: "#94ce9a", step8: "#65ba74", step9: "#46a758", step10: "#3e9b4f", step11: "#2a7e3b", step12: "#203c25" }

grassDark :: Scale
grassDark = { step1: "#0e1511", step2: "#141a15", step3: "#1b2a1e", step4: "#1d3a24", step5: "#25482d", step6: "#2d5736", step7: "#366740", step8: "#3e7949", step9: "#46a758", step10: "#53b365", step11: "#71d083", step12: "#c2f0c2" }

brownLight :: Scale
brownLight = { step1: "#fefdfc", step2: "#fcf9f6", step3: "#f6eee7", step4: "#f0e4d9", step5: "#ebdaca", step6: "#e4cdb7", step7: "#dcbc9f", step8: "#cea37e", step9: "#ad7f58", step10: "#a07553", step11: "#815e46", step12: "#3e332e" }

brownDark :: Scale
brownDark = { step1: "#12110f", step2: "#1c1816", step3: "#28211d", step4: "#322922", step5: "#3e3128", step6: "#4d3c2f", step7: "#614a39", step8: "#7c5f46", step9: "#ad7f58", step10: "#b88c67", step11: "#dbb594", step12: "#f2e1ca" }

bronzeLight :: Scale
bronzeLight = { step1: "#fdfcfc", step2: "#fdf7f5", step3: "#f6edea", step4: "#efe4df", step5: "#e7d9d3", step6: "#dfcdc5", step7: "#d3bcb3", step8: "#c2a499", step9: "#a18072", step10: "#957468", step11: "#7d5e54", step12: "#43302b" }

bronzeDark :: Scale
bronzeDark = { step1: "#141110", step2: "#1c1917", step3: "#262220", step4: "#302a27", step5: "#3b3330", step6: "#493e3a", step7: "#5a4c47", step8: "#6f5f58", step9: "#a18072", step10: "#ae8c7e", step11: "#d4b3a5", step12: "#ede0d9" }

goldLight :: Scale
goldLight = { step1: "#fdfdfc", step2: "#faf9f2", step3: "#f2f0e7", step4: "#eae6db", step5: "#e1dccf", step6: "#d8d0bf", step7: "#cbc0aa", step8: "#b9a88d", step9: "#978365", step10: "#8c7a5e", step11: "#71624b", step12: "#3b352b" }

goldDark :: Scale
goldDark = { step1: "#121211", step2: "#1b1a17", step3: "#24231f", step4: "#2d2b26", step5: "#38352e", step6: "#444039", step7: "#544f46", step8: "#696256", step9: "#978365", step10: "#a39073", step11: "#cbb99f", step12: "#e8e2d9" }

skyLight :: Scale
skyLight = { step1: "#f9feff", step2: "#f1fafd", step3: "#e1f6fd", step4: "#d1f0fa", step5: "#bee7f5", step6: "#a9daed", step7: "#8dcae3", step8: "#60b3d7", step9: "#7ce2fe", step10: "#74daf8", step11: "#00749e", step12: "#1d3e56" }

skyDark :: Scale
skyDark = { step1: "#0d141f", step2: "#111a27", step3: "#112840", step4: "#113555", step5: "#154467", step6: "#1b537b", step7: "#1f6692", step8: "#197cae", step9: "#7ce2fe", step10: "#a8eeff", step11: "#75c7f0", step12: "#c2f3ff" }

mintLight :: Scale
mintLight = { step1: "#f9fefd", step2: "#f2fbf9", step3: "#ddf9f2", step4: "#c8f4e9", step5: "#b3ecde", step6: "#9ce0d0", step7: "#7ecfbd", step8: "#4cbba5", step9: "#86ead4", step10: "#7de0cb", step11: "#027864", step12: "#16433c" }

mintDark :: Scale
mintDark = { step1: "#0e1515", step2: "#0f1b1b", step3: "#092c2b", step4: "#003a38", step5: "#004744", step6: "#105650", step7: "#1e685f", step8: "#277f70", step9: "#86ead4", step10: "#a8f5e5", step11: "#58d5ba", step12: "#c4f5e1" }

limeLight :: Scale
limeLight = { step1: "#fcfdfa", step2: "#f8faf3", step3: "#eef6d6", step4: "#e2f0bd", step5: "#d3e7a6", step6: "#c2da91", step7: "#abc978", step8: "#8db654", step9: "#bdee63", step10: "#b0e64c", step11: "#5c7c2f", step12: "#37401c" }

limeDark :: Scale
limeDark = { step1: "#11130c", step2: "#151a10", step3: "#1f2917", step4: "#29371d", step5: "#334423", step6: "#3d522a", step7: "#496231", step8: "#577538", step9: "#bdee63", step10: "#d4ff70", step11: "#bde56c", step12: "#e3f7ba" }

yellowLight :: Scale
yellowLight = { step1: "#fdfdf9", step2: "#fefce9", step3: "#fffab8", step4: "#fff394", step5: "#ffe770", step6: "#f3d768", step7: "#e4c767", step8: "#d5ae39", step9: "#ffe629", step10: "#ffdc00", step11: "#9e6c00", step12: "#473b1f" }

yellowDark :: Scale
yellowDark = { step1: "#14120b", step2: "#1b180f", step3: "#2d2305", step4: "#362b00", step5: "#433500", step6: "#524202", step7: "#665417", step8: "#836a21", step9: "#ffe629", step10: "#ffff57", step11: "#f5e147", step12: "#f6eeb4" }

amberLight :: Scale
amberLight = { step1: "#fefdfb", step2: "#fefbe9", step3: "#fff7c2", step4: "#ffee9c", step5: "#fbe577", step6: "#f3d673", step7: "#e9c162", step8: "#e2a336", step9: "#ffc53d", step10: "#ffba18", step11: "#ab6400", step12: "#4f3422" }

amberDark :: Scale
amberDark = { step1: "#16120c", step2: "#1d180f", step3: "#302008", step4: "#3f2700", step5: "#4d3000", step6: "#5c3d05", step7: "#714f19", step8: "#8f6424", step9: "#ffc53d", step10: "#ffd60a", step11: "#ffca16", step12: "#ffe7b3" }

orangeLight :: Scale
orangeLight = { step1: "#fefcfb", step2: "#fff7ed", step3: "#ffefd6", step4: "#ffdfb5", step5: "#ffd19a", step6: "#ffc182", step7: "#f5ae73", step8: "#ec9455", step9: "#f76b15", step10: "#ef5f00", step11: "#cc4e00", step12: "#582d1d" }

orangeDark :: Scale
orangeDark = { step1: "#17120e", step2: "#1e160f", step3: "#331e0b", step4: "#462100", step5: "#562800", step6: "#66350c", step7: "#7e451d", step8: "#a35829", step9: "#f76b15", step10: "#ff801f", step11: "#ffa057", step12: "#ffe0c2" }

grayAlphaLight :: Scale
grayAlphaLight = { step1: "#00000003", step2: "#00000006", step3: "#0000000f", step4: "#00000017", step5: "#0000001f", step6: "#00000026", step7: "#00000031", step8: "#00000044", step9: "#00000072", step10: "#0000007c", step11: "#0000009b", step12: "#000000df" }

grayAlphaDark :: Scale
grayAlphaDark = { step1: "#00000000", step2: "#ffffff09", step3: "#ffffff12", step4: "#ffffff1b", step5: "#ffffff22", step6: "#ffffff2c", step7: "#ffffff3b", step8: "#ffffff55", step9: "#ffffff64", step10: "#ffffff72", step11: "#ffffffaf", step12: "#ffffffed" }

mauveAlphaLight :: Scale
mauveAlphaLight = { step1: "#55005503", step2: "#2b005506", step3: "#30004010", step4: "#20003618", step5: "#20003820", step6: "#14003527", step7: "#10003332", step8: "#08003145", step9: "#05001d73", step10: "#0500197d", step11: "#0400119c", step12: "#020008e0" }

mauveAlphaDark :: Scale
mauveAlphaDark = { step1: "#00000000", step2: "#f5f4f609", step3: "#ebeaf814", step4: "#eee5f81d", step5: "#efe6fe25", step6: "#f1e6fd30", step7: "#eee9ff40", step8: "#eee7ff5d", step9: "#eae6fd6e", step10: "#ece9fd7c", step11: "#f5f1ffb7", step12: "#fdfdffef" }

slateAlphaLight :: Scale
slateAlphaLight = { step1: "#00005503", step2: "#00005506", step3: "#0000330f", step4: "#00002d17", step5: "#0009321f", step6: "#00002f26", step7: "#00062e32", step8: "#00083046", step9: "#00051d74", step10: "#00071b7f", step11: "#0007149f", step12: "#000509e3" }

slateAlphaDark :: Scale
slateAlphaDark = { step1: "#00000000", step2: "#d8f4f609", step3: "#ddeaf814", step4: "#d3edf81d", step5: "#d9edfe25", step6: "#d6ebfd30", step7: "#d9edff40", step8: "#d9edff5d", step9: "#dfebfd6d", step10: "#e5edfd7b", step11: "#f1f7feb5", step12: "#fcfdffef" }

sageAlphaLight :: Scale
sageAlphaLight = { step1: "#00804004", step2: "#00402008", step3: "#002d1e11", step4: "#001f1519", step5: "#00180820", step6: "#00140d28", step7: "#00140a34", step8: "#000f0847", step9: "#00110b79", step10: "#00100a83", step11: "#000a07a0", step12: "#000805e5" }

sageAlphaDark :: Scale
sageAlphaDark = { step1: "#00000000", step2: "#f0f2f108", step3: "#f3f5f412", step4: "#f2fefd1a", step5: "#f1fbfa22", step6: "#edfbf42d", step7: "#edfcf73c", step8: "#ebfdf657", step9: "#dffdf266", step10: "#e5fdf674", step11: "#f4fefbb0", step12: "#fdfffeed" }

oliveAlphaLight :: Scale
oliveAlphaLight = { step1: "#00550003", step2: "#00490007", step3: "#00200010", step4: "#00160018", step5: "#00180020", step6: "#00140028", step7: "#000f0033", step8: "#040f0047", step9: "#050f0078", step10: "#040e0082", step11: "#020a00a0", step12: "#010600e3" }

oliveAlphaDark :: Scale
oliveAlphaDark = { step1: "#00000000", step2: "#f1f2f008", step3: "#f4f5f312", step4: "#f3fef21a", step5: "#f2fbf122", step6: "#f4faed2c", step7: "#f2fced3b", step8: "#edfdeb57", step9: "#ebfde766", step10: "#f0fdec74", step11: "#f6fef4b0", step12: "#fdfffded" }

sandAlphaLight :: Scale
sandAlphaLight = { step1: "#55550003", step2: "#25250007", step3: "#20100010", step4: "#1f150019", step5: "#1f180021", step6: "#19130029", step7: "#19140035", step8: "#1915014a", step9: "#0f0f0079", step10: "#0c0c0083", step11: "#080800a1", step12: "#060500e3" }

sandAlphaDark :: Scale
sandAlphaDark = { step1: "#00000000", step2: "#f4f4f309", step3: "#f6f6f513", step4: "#fefef31b", step5: "#fbfbeb23", step6: "#fffaed2d", step7: "#fffbed3c", step8: "#fff9eb57", step9: "#fffae965", step10: "#fffdee73", step11: "#fffcf4b0", step12: "#fffffded" }

tomatoAlphaLight :: Scale
tomatoAlphaLight = { step1: "#ff000003", step2: "#ff200008", step3: "#f52b0018", step4: "#ff35002c", step5: "#ff2e003d", step6: "#f92d0050", step7: "#e7280067", step8: "#db250084", step9: "#df2600d1", step10: "#d72400da", step11: "#cd2200ea", step12: "#460900e0" }

tomatoAlphaDark :: Scale
tomatoAlphaDark = { step1: "#f1121208", step2: "#ff55330f", step3: "#ff35232b", step4: "#fd201142", step5: "#fe332153", step6: "#ff4f3864", step7: "#fd644a7d", step8: "#fe6d4ea7", step9: "#fe5431e4", step10: "#ff6847eb", step11: "#ff977d", step12: "#ffd6cefb" }

redAlphaLight :: Scale
redAlphaLight = { step1: "#ff000003", step2: "#ff000008", step3: "#f3000d14", step4: "#ff000824", step5: "#ff000632", step6: "#f8000442", step7: "#df000356", step8: "#d2000571", step9: "#db0007b7", step10: "#d10005c1", step11: "#c40006d3", step12: "#55000de8" }

redAlphaDark :: Scale
redAlphaDark = { step1: "#f4121209", step2: "#f22f3e11", step3: "#ff173f2d", step4: "#fe0a3b44", step5: "#ff204756", step6: "#ff3e5668", step7: "#ff536184", step8: "#ff5d61b0", step9: "#fe4e54e4", step10: "#ff6465eb", step11: "#ff9592", step12: "#ffd1d9" }

rubyAlphaLight :: Scale
rubyAlphaLight = { step1: "#ff005503", step2: "#ff002008", step3: "#f3002515", step4: "#ff002523", step5: "#ff002a31", step6: "#e4002440", step7: "#ce002553", step8: "#c300286d", step9: "#db002cb9", step10: "#d2002cc4", step11: "#c10030db", step12: "#550016e8" }

rubyAlphaDark :: Scale
rubyAlphaDark = { step1: "#f4124a09", step2: "#fe5a7f0e", step3: "#ff235d2c", step4: "#fd195e42", step5: "#fe2d6b53", step6: "#ff447665", step7: "#ff577d80", step8: "#ff5c7cae", step9: "#fe4c70e4", step10: "#ff617beb", step11: "#ff949d", step12: "#ffd3e2fe" }

crimsonAlphaLight :: Scale
crimsonAlphaLight = { step1: "#ff005503", step2: "#e0004008", step3: "#ff005216", step4: "#f8005123", step5: "#e5004f31", step6: "#d0004b41", step7: "#bf004753", step8: "#b6004a6c", step9: "#e2005bc2", step10: "#d70056cb", step11: "#c4004fe2", step12: "#530026e9" }

crimsonAlphaDark :: Scale
crimsonAlphaDark = { step1: "#f4126709", step2: "#f22f7a11", step3: "#fe2a8b2a", step4: "#fd158741", step5: "#fd278f51", step6: "#fe459763", step7: "#fd559b7f", step8: "#fe5b9bab", step9: "#fe418de8", step10: "#ff5693ed", step11: "#ff92ad", step12: "#ffd5eafd" }

pinkAlphaLight :: Scale
pinkAlphaLight = { step1: "#ff00aa03", step2: "#e0008008", step3: "#f4008c16", step4: "#e2008b23", step5: "#d1008331", step6: "#c0007840", step7: "#b6006f53", step8: "#af006f6c", step9: "#c8007fbf", step10: "#c2007ac7", step11: "#b60074d6", step12: "#59003bed" }

pinkAlphaDark :: Scale
pinkAlphaDark = { step1: "#f412bc09", step2: "#f420bb12", step3: "#fe37cc29", step4: "#fc1ec43f", step5: "#fd35c24e", step6: "#fd51c75f", step7: "#fd62c87b", step8: "#ff68c8a2", step9: "#fe49bcd4", step10: "#ff5cc0dc", step11: "#ff8dcc", step12: "#ffd3ecfd" }

plumAlphaLight :: Scale
plumAlphaLight = { step1: "#aa00ff03", step2: "#c000c008", step3: "#cc00cc14", step4: "#c200c921", step5: "#b700bd2e", step6: "#a400b03d", step7: "#9900a852", step8: "#9000a56e", step9: "#89009eb5", step10: "#7f0092bb", step11: "#730086c1", step12: "#40004be6" }

plumAlphaDark :: Scale
plumAlphaDark = { step1: "#f112f108", step2: "#f22ff211", step3: "#fd4cfd27", step4: "#f646ff3a", step5: "#f455ff48", step6: "#f66dff56", step7: "#f07cfd70", step8: "#ee84ff95", step9: "#e961feb6", step10: "#ed70ffc0", step11: "#f19cfef3", step12: "#feddfef4" }

purpleAlphaLight :: Scale
purpleAlphaLight = { step1: "#aa00aa03", step2: "#8000e008", step3: "#8e00f112", step4: "#8d00e51d", step5: "#8000db2a", step6: "#7a01d03b", step7: "#6d00c350", step8: "#6600c06c", step9: "#5c00adb1", step10: "#53009eb8", step11: "#52009aba", step12: "#250049df" }

purpleAlphaDark :: Scale
purpleAlphaDark = { step1: "#b412f90b", step2: "#b744f714", step3: "#c150ff2d", step4: "#bb53fd42", step5: "#be5cfd51", step6: "#c16dfd61", step7: "#c378fd7a", step8: "#c47effa4", step9: "#b661ffc2", step10: "#bc6fffcd", step11: "#d19dff", step12: "#f1ddfffa" }

violetAlphaLight :: Scale
violetAlphaLight = { step1: "#5500aa03", step2: "#4900ff07", step3: "#4400ee0f", step4: "#4300ff1b", step5: "#3600ff26", step6: "#3100fb35", step7: "#2d01dd4a", step8: "#2b00d066", step9: "#2400b7a9", step10: "#2300abb2", step11: "#1f0099af", step12: "#0b0043d9" }

violetAlphaDark :: Scale
violetAlphaDark = { step1: "#4422ff0f", step2: "#853ff916", step3: "#8354fe36", step4: "#7d51fd50", step5: "#845ffd5f", step6: "#8f6cfd6d", step7: "#9879ff83", step8: "#977dfea8", step9: "#8668ffcc", step10: "#9176fed7", step11: "#baa7ff", step12: "#e3defffe" }

irisAlphaLight :: Scale
irisAlphaLight = { step1: "#0000ff02", step2: "#0000ff07", step3: "#0011ee0f", step4: "#000bff19", step5: "#000eff25", step6: "#000aff34", step7: "#0008e647", step8: "#0008d964", step9: "#0000c0a4", step10: "#0000b6ae", step11: "#0600abac", step12: "#000246d8" }

irisAlphaDark :: Scale
irisAlphaDark = { step1: "#3636fe0e", step2: "#564bf916", step3: "#525bff3b", step4: "#4d58ff5a", step5: "#5b62fd6b", step6: "#6d6ffd7a", step7: "#7777fe8e", step8: "#7b7afeac", step9: "#6a6afed4", step10: "#7d79ffdc", step11: "#b1a9ff", step12: "#e1e0fffe" }

indigoAlphaLight :: Scale
indigoAlphaLight = { step1: "#00008002", step2: "#0040ff08", step3: "#0047f112", step4: "#0044ff1e", step5: "#0044ff2d", step6: "#003eff3e", step7: "#0037ed54", step8: "#0034dc72", step9: "#0031d2c1", step10: "#002ec9cc", step11: "#002bb7c5", step12: "#001046e0" }

indigoAlphaDark :: Scale
indigoAlphaDark = { step1: "#1133ff0f", step2: "#3354fa17", step3: "#2f62ff3c", step4: "#3566ff57", step5: "#4171fd6b", step6: "#5178fd7c", step7: "#5a7fff90", step8: "#5b81feac", step9: "#4671ffdb", step10: "#5c7efee3", step11: "#9eb1ff", step12: "#d6e1ff" }

blueAlphaLight :: Scale
blueAlphaLight = { step1: "#0080ff04", step2: "#008cff0b", step3: "#008ff519", step4: "#009eff2a", step5: "#0093ff3d", step6: "#0088f653", step7: "#0083eb71", step8: "#0084e6a1", step9: "#0090ff", step10: "#0086f0fa", step11: "#006dcbf2", step12: "#002359ee" }

blueAlphaDark :: Scale
blueAlphaDark = { step1: "#004df211", step2: "#1166fb18", step3: "#0077ff3a", step4: "#0075ff57", step5: "#0081fd6b", step6: "#0f89fd7f", step7: "#2a91fe98", step8: "#3094feb9", step9: "#0090ff", step10: "#3b9eff", step11: "#70b8ff", step12: "#c2e6ff" }

cyanAlphaLight :: Scale
cyanAlphaLight = { step1: "#0099cc05", step2: "#009db10d", step3: "#00c2d121", step4: "#00bcd435", step5: "#01b4cc4a", step6: "#00a7c162", step7: "#009fbb82", step8: "#00a3c0c2", step9: "#00a2c7", step10: "#0094b7f8", step11: "#007491ef", step12: "#00323ef2" }

cyanAlphaDark :: Scale
cyanAlphaDark = { step1: "#0091f70a", step2: "#02a7f211", step3: "#00befd28", step4: "#00baff3b", step5: "#00befd4d", step6: "#00c7fd5e", step7: "#14cdff75", step8: "#11cfff95", step9: "#00cfffc3", step10: "#28d6ffcd", step11: "#52e1fee5", step12: "#bbf3fef7" }

tealAlphaLight :: Scale
tealAlphaLight = { step1: "#00cc9905", step2: "#00aa800c", step3: "#00c69d1f", step4: "#00c39633", step5: "#00b49047", step6: "#00a6855e", step7: "#0099807c", step8: "#009783ac", step9: "#009e8ced", step10: "#009684f2", step11: "#008573", step12: "#00332df2" }

tealAlphaDark :: Scale
tealAlphaDark = { step1: "#00deab05", step2: "#12fbe60c", step3: "#00ffe61e", step4: "#00ffe92d", step5: "#00ffea3b", step6: "#1cffe84b", step7: "#2efde85f", step8: "#32ffe775", step9: "#13ffe49f", step10: "#0dffe0ae", step11: "#0afed5d6", step12: "#b8ffebef" }

jadeAlphaLight :: Scale
jadeAlphaLight = { step1: "#00c08004", step2: "#00a3460b", step3: "#00ae4819", step4: "#00a85129", step5: "#00a2553c", step6: "#009a5753", step7: "#00945f74", step8: "#00976ea9", step9: "#00916bd6", step10: "#008764d9", step11: "#007152df", step12: "#002217e2" }

jadeAlphaDark :: Scale
jadeAlphaDark = { step1: "#00de4505", step2: "#27fba60c", step3: "#02f99920", step4: "#00ffaa2d", step5: "#11ffb63b", step6: "#34ffc24b", step7: "#45fdc75e", step8: "#48ffcf75", step9: "#38feca9d", step10: "#31fec7ab", step11: "#21fec0d6", step12: "#b8ffe1ef" }

greenAlphaLight :: Scale
greenAlphaLight = { step1: "#00c04004", step2: "#00a32f0b", step3: "#00a43319", step4: "#00a83829", step5: "#019c393b", step6: "#00963c52", step7: "#00914071", step8: "#00924ba4", step9: "#008f4acf", step10: "#008647d4", step11: "#00713fde", step12: "#002616e6" }

greenAlphaDark :: Scale
greenAlphaDark = { step1: "#00de4505", step2: "#29f99d0b", step3: "#22ff991e", step4: "#11ff992d", step5: "#2bffa23c", step6: "#44ffaa4b", step7: "#50fdac5e", step8: "#54ffad73", step9: "#44ffa49e", step10: "#43fea4ab", step11: "#46fea5d4", step12: "#bbffd7f0" }

grassAlphaLight :: Scale
grassAlphaLight = { step1: "#00c00004", step2: "#0099000a", step3: "#00970016", step4: "#009f0725", step5: "#00930536", step6: "#008f0a4d", step7: "#018b0f6b", step8: "#008d199a", step9: "#008619b9", step10: "#007b17c1", step11: "#006514d5", step12: "#002006df" }

grassAlphaDark :: Scale
grassAlphaDark = { step1: "#00de1205", step2: "#5ef7780a", step3: "#70fe8c1b", step4: "#57ff802c", step5: "#68ff8b3b", step6: "#71ff8f4b", step7: "#77fd925d", step8: "#77fd9070", step9: "#65ff82a1", step10: "#72ff8dae", step11: "#89ff9fcd", step12: "#ceffceef" }

brownAlphaLight :: Scale
brownAlphaLight = { step1: "#aa550003", step2: "#aa550009", step3: "#a04b0018", step4: "#9b4a0026", step5: "#9f4d0035", step6: "#a04e0048", step7: "#a34e0060", step8: "#9f4a0081", step9: "#823c00a7", step10: "#723300ac", step11: "#522100b9", step12: "#140600d1" }

brownAlphaDark :: Scale
brownAlphaDark = { step1: "#91110002", step2: "#fba67c0c", step3: "#fcb58c19", step4: "#fbbb8a24", step5: "#fcb88931", step6: "#fdba8741", step7: "#ffbb8856", step8: "#ffbe8773", step9: "#feb87da8", step10: "#ffc18cb3", step11: "#fed1aad9", step12: "#feecd4f2" }

bronzeAlphaLight :: Scale
bronzeAlphaLight = { step1: "#55000003", step2: "#cc33000a", step3: "#92250015", step4: "#80280020", step5: "#7423002c", step6: "#7324003a", step7: "#6c1f004c", step8: "#671c0066", step9: "#551a008d", step10: "#4c150097", step11: "#3d0f00ab", step12: "#1d0600d4" }

bronzeAlphaDark :: Scale
bronzeAlphaDark = { step1: "#d1110004", step2: "#fbbc910c", step3: "#faceb817", step4: "#facdb622", step5: "#ffd2c12d", step6: "#ffd1c03c", step7: "#fdd0c04f", step8: "#ffd6c565", step9: "#fec7b09b", step10: "#fecab5a9", step11: "#ffd7c6d1", step12: "#fff1e9ec" }

goldAlphaLight :: Scale
goldAlphaLight = { step1: "#55550003", step2: "#9d8a000d", step3: "#75600018", step4: "#6b4e0024", step5: "#60460030", step6: "#64440040", step7: "#63420055", step8: "#633d0072", step9: "#5332009a", step10: "#492d00a1", step11: "#362100b4", step12: "#130c00d4" }

goldAlphaDark :: Scale
goldAlphaDark = { step1: "#91911102", step2: "#f9e29d0b", step3: "#f8ecbb15", step4: "#ffeec41e", step5: "#feecc22a", step6: "#feebcb37", step7: "#ffedcd48", step8: "#fdeaca5f", step9: "#ffdba690", step10: "#fedfb09d", step11: "#fee7c6c8", step12: "#fef7ede7" }

skyAlphaLight :: Scale
skyAlphaLight = { step1: "#00d5ff06", step2: "#00a4db0e", step3: "#00b3ee1e", step4: "#00ace42e", step5: "#00a1d841", step6: "#0092ca56", step7: "#0089c172", step8: "#0085bf9f", step9: "#00c7fe83", step10: "#00bcf38b", step11: "#00749e", step12: "#002540e2" }

skyAlphaDark :: Scale
skyAlphaDark = { step1: "#0044ff0f", step2: "#1171fb18", step3: "#1184fc33", step4: "#128fff49", step5: "#1c9dfd5d", step6: "#28a5ff72", step7: "#2badfe8b", step8: "#1db2fea9", step9: "#7ce3fffe", step10: "#a8eeff", step11: "#7cd3ffef", step12: "#c2f3ff" }

mintAlphaLight :: Scale
mintAlphaLight = { step1: "#00d5aa06", step2: "#00b18a0d", step3: "#00d29e22", step4: "#00cc9937", step5: "#00c0914c", step6: "#00b08663", step7: "#00a17d81", step8: "#009e7fb3", step9: "#00d3a579", step10: "#00c39982", step11: "#007763fd", step12: "#00312ae9" }

mintAlphaDark :: Scale
mintAlphaDark = { step1: "#00dede05", step2: "#00f9f90b", step3: "#00fff61d", step4: "#00fff42c", step5: "#00fff23a", step6: "#0effeb4a", step7: "#34fde55e", step8: "#41ffdf76", step9: "#92ffe7e9", step10: "#aefeedf5", step11: "#67ffded2", step12: "#cbfee9f5" }

limeAlphaLight :: Scale
limeAlphaLight = { step1: "#66990005", step2: "#6b95000c", step3: "#96c80029", step4: "#8fc60042", step5: "#81bb0059", step6: "#72aa006e", step7: "#61990087", step8: "#559200ab", step9: "#93e4009c", step10: "#8fdc00b3", step11: "#375f00d0", step12: "#1e2900e3" }

limeAlphaDark :: Scale
limeAlphaDark = { step1: "#11bb0003", step2: "#78f7000a", step3: "#9bfd4c1a", step4: "#a7fe5c29", step5: "#affe6537", step6: "#b2fe6d46", step7: "#b6ff6f57", step8: "#b6fd6d6c", step9: "#caff69ed", step10: "#d4ff70", step11: "#d1fe77e4", step12: "#e9febff7" }

yellowAlphaLight :: Scale
yellowAlphaLight = { step1: "#aaaa0006", step2: "#f4dd0016", step3: "#ffee0047", step4: "#ffe3016b", step5: "#ffd5008f", step6: "#ebbc0097", step7: "#d2a10098", step8: "#c99700c6", step9: "#ffe100d6", step10: "#ffdc00", step11: "#9e6c00", step12: "#2e2000e0" }

yellowAlphaDark :: Scale
yellowAlphaDark = { step1: "#d1510004", step2: "#f9b4000b", step3: "#ffaa001e", step4: "#fdb70028", step5: "#febb0036", step6: "#fec40046", step7: "#fdcb225c", step8: "#fdca327b", step9: "#ffe629", step10: "#ffff57", step11: "#fee949f5", step12: "#fef6baf6" }

amberAlphaLight :: Scale
amberAlphaLight = { step1: "#c0800004", step2: "#f4d10016", step3: "#ffde003d", step4: "#ffd40063", step5: "#f8cf0088", step6: "#eab5008c", step7: "#dc9b009d", step8: "#da8a00c9", step9: "#ffb300c2", step10: "#ffb300e7", step11: "#ab6400", step12: "#341500dd" }

amberAlphaDark :: Scale
amberAlphaDark = { step1: "#e63c0006", step2: "#fd9b000d", step3: "#fa820022", step4: "#fc820032", step5: "#fd8b0041", step6: "#fd9b0051", step7: "#ffab2567", step8: "#ffae3587", step9: "#ffc53d", step10: "#ffd60a", step11: "#ffca16", step12: "#ffe7b3" }

orangeAlphaLight :: Scale
orangeAlphaLight = { step1: "#c0400004", step2: "#ff8e0012", step3: "#ff9c0029", step4: "#ff91014a", step5: "#ff8b0065", step6: "#ff81007d", step7: "#ed6c008c", step8: "#e35f00aa", step9: "#f65e00ea", step10: "#ef5f00", step11: "#cc4e00", step12: "#431200e2" }

orangeAlphaDark :: Scale
orangeAlphaDark = { step1: "#ec360007", step2: "#fe6d000e", step3: "#fb6a0025", step4: "#ff590039", step5: "#ff61004a", step6: "#fd75045c", step7: "#ff832c75", step8: "#fe84389d", step9: "#fe6d15f7", step10: "#ff801f", step11: "#ffa057", step12: "#ffe0c2" }

blackAlpha :: Scale
blackAlpha = { step1: "rgba(0, 0, 0, 0.05)", step2: "rgba(0, 0, 0, 0.1)", step3: "rgba(0, 0, 0, 0.15)", step4: "rgba(0, 0, 0, 0.2)", step5: "rgba(0, 0, 0, 0.3)", step6: "rgba(0, 0, 0, 0.4)", step7: "rgba(0, 0, 0, 0.5)", step8: "rgba(0, 0, 0, 0.6)", step9: "rgba(0, 0, 0, 0.7)", step10: "rgba(0, 0, 0, 0.8)", step11: "rgba(0, 0, 0, 0.9)", step12: "rgba(0, 0, 0, 0.95)" }

whiteAlpha :: Scale
whiteAlpha = { step1: "rgba(255, 255, 255, 0.05)", step2: "rgba(255, 255, 255, 0.1)", step3: "rgba(255, 255, 255, 0.15)", step4: "rgba(255, 255, 255, 0.2)", step5: "rgba(255, 255, 255, 0.3)", step6: "rgba(255, 255, 255, 0.4)", step7: "rgba(255, 255, 255, 0.5)", step8: "rgba(255, 255, 255, 0.6)", step9: "rgba(255, 255, 255, 0.7)", step10: "rgba(255, 255, 255, 0.8)", step11: "rgba(255, 255, 255, 0.9)", step12: "rgba(255, 255, 255, 0.95)" }

