-- | Hydrogen.Radix.Foundation.Style — the styling contract (the "amenity").
-- |
-- | Learned from radix-ui themes: theming is **data-attribute + CSS-variable
-- | driven**, not class-string soup. A ported primitive emits:
-- |
-- |   1. STABLE behavioral attributes — `data-state`, `data-orientation`,
-- |      `data-disabled`, `data-side`, … — that are part of radix's semantics and
-- |      that CSS targets for state styling (`[data-state="open"] { … }`). These
-- |      are NON-NEGOTIABLE; every preset relies on them.
-- |   2. A per-part class list drawn from the component's `Style` record. A
-- |      *preset* (semantic / tailwind / shadcn / daisy / **orbital**) is just a
-- |      set of `Style` values. The component is style-agnostic; swapping the
-- |      preset (or the CSS that targets the data-attrs) swaps the look.
-- |
-- | This module is the shared vocabulary every primitive draws on:
-- |   * `ClassNames` — a monoidal class list + its Halogen renderer.
-- |   * the cross-cutting style axes (Variant / Size / Radius / Side / Orientation)
-- |     and their string realizations, mirroring radix themes' prop vocabulary.
-- |   * `Accent` — reuses `Hydrogen.Radix.Foundation.Color.Hue` (the accent color IS a hue).
-- |   * `data-*` attribute helpers.
-- |
-- | Each component defines its OWN `Style` record (a `ClassNames` per part) plus a
-- | `defaultStyle` of semantic class names; presets supply alternative records.
module Hydrogen.Radix.Foundation.Style
  ( ClassNames(..)
  , cn
  , unClassNames
  , classes
  , Variant(..)
  , variantName
  , Size(..)
  , sizeName
  , Radius(..)
  , radiusName
  , Side(..)
  , sideName
  , Align(..)
  , alignName
  , Orientation(..)
  , orientationName
  , Accent
  , accentName
  , dataAttr
  , dataState
  , dataOrientation
  , dataSide
  , dataAccentColor
  , dataRadius
  , role
  , aria
  ) where

import Prelude

import Data.Array (filter)
import Data.String (Pattern(..), split, trim) as Str
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Color (Hue, hueName)

-- ─────────────────────────────────────────────────────────────────────────────
-- ClassNames — a monoidal class list
-- ─────────────────────────────────────────────────────────────────────────────

-- | A list of CSS class tokens. Monoid = concatenation, so a component composes
-- | `base <> variantClasses <> stateClasses`. Empty tokens are dropped by `cn`.
newtype ClassNames = ClassNames (Array String)

derive newtype instance semigroupClassNames :: Semigroup ClassNames
derive newtype instance monoidClassNames :: Monoid ClassNames
derive newtype instance eqClassNames :: Eq ClassNames

instance showClassNames :: Show ClassNames where
  show (ClassNames xs) = "(cn " <> show xs <> ")"

-- | Build a class list from a (possibly space-separated) string, dropping empties.
-- | `cn "rt-Badge rt-variant-soft"` → two tokens.
cn :: String -> ClassNames
cn s = ClassNames (filter (_ /= "") (map Str.trim (Str.split (Str.Pattern " ") s)))

unClassNames :: ClassNames -> Array String
unClassNames (ClassNames xs) = xs

-- | Render a class list as a Halogen `class` property.
classes :: forall r i. ClassNames -> HP.IProp (class :: String | r) i
classes (ClassNames xs) = HP.classes (map HH.ClassName xs)

-- ─────────────────────────────────────────────────────────────────────────────
-- Cross-cutting style axes (radix themes' shared prop vocabulary)
-- ─────────────────────────────────────────────────────────────────────────────

-- | Visual variant. Realized as a data/class the preset's CSS targets.
data Variant = Solid | Soft | Surface | Outline | Ghost | Classic

derive instance eqVariant :: Eq Variant
derive instance ordVariant :: Ord Variant

variantName :: Variant -> String
variantName = case _ of
  Solid -> "solid"
  Soft -> "soft"
  Surface -> "surface"
  Outline -> "outline"
  Ghost -> "ghost"
  Classic -> "classic"

-- | Size step. radix themes uses 1–4 for controls (1–9 for text); we keep the
-- | common control range and let text-like components extend as needed.
data Size = Size1 | Size2 | Size3 | Size4

derive instance eqSize :: Eq Size
derive instance ordSize :: Ord Size

sizeName :: Size -> String
sizeName = case _ of
  Size1 -> "1"
  Size2 -> "2"
  Size3 -> "3"
  Size4 -> "4"

-- | Corner radius token (scales a `--radius-factor` in CSS, radix-style).
data Radius = RadiusNone | RadiusSmall | RadiusMedium | RadiusLarge | RadiusFull

derive instance eqRadius :: Eq Radius
derive instance ordRadius :: Ord Radius

radiusName :: Radius -> String
radiusName = case _ of
  RadiusNone -> "none"
  RadiusSmall -> "small"
  RadiusMedium -> "medium"
  RadiusLarge -> "large"
  RadiusFull -> "full"

-- | Preferred side for floating content (popper). Emitted as `data-side`.
data Side = Top | Right | Bottom | Left

derive instance eqSide :: Eq Side
derive instance ordSide :: Ord Side

sideName :: Side -> String
sideName = case _ of
  Top -> "top"
  Right -> "right"
  Bottom -> "bottom"
  Left -> "left"

-- | Alignment of floating content along its side. Emitted as `data-align`.
data Align = Start | Center | End

derive instance eqAlign :: Eq Align
derive instance ordAlign :: Ord Align

alignName :: Align -> String
alignName = case _ of
  Start -> "start"
  Center -> "center"
  End -> "end"

-- | Orientation for roving-focus groups, tabs, toolbars, etc.
data Orientation = Horizontal | Vertical

derive instance eqOrientation :: Eq Orientation
derive instance ordOrientation :: Ord Orientation

orientationName :: Orientation -> String
orientationName = case _ of
  Horizontal -> "horizontal"
  Vertical -> "vertical"

-- | The accent color is exactly a radix color hue.
type Accent = Hue

accentName :: Accent -> String
accentName = hueName

-- ─────────────────────────────────────────────────────────────────────────────
-- data-* attribute helpers (the stable behavioral surface CSS targets)
-- ─────────────────────────────────────────────────────────────────────────────

-- | A generic `data-<name>="<value>"` attribute.
dataAttr :: forall r i. String -> String -> HP.IProp r i
dataAttr name val = HP.attr (HH.AttrName ("data-" <> name)) val

-- | `data-state` — the most-targeted attribute (open/closed, on/off, checked, …).
dataState :: forall r i. String -> HP.IProp r i
dataState = dataAttr "state"

dataOrientation :: forall r i. Orientation -> HP.IProp r i
dataOrientation o = dataAttr "orientation" (orientationName o)

dataSide :: forall r i. Side -> HP.IProp r i
dataSide s = dataAttr "side" (sideName s)

-- | `data-accent-color` — scopes the `--accent-*` CSS variables (see Color).
dataAccentColor :: forall r i. Accent -> HP.IProp r i
dataAccentColor a = dataAttr "accent-color" (accentName a)

dataRadius :: forall r i. Radius -> HP.IProp r i
dataRadius r = dataAttr "radius" (radiusName r)

-- | The `role` attribute.
role :: forall r i. String -> HP.IProp r i
role = HP.attr (HH.AttrName "role")

-- | A generic `aria-<name>="<value>"` attribute.
aria :: forall r i. String -> String -> HP.IProp r i
aria name val = HP.attr (HH.AttrName ("aria-" <> name)) val
