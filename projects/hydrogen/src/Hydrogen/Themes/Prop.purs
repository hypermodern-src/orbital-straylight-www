-- | Hydrogen.Themes.Prop — the Radix Themes prop→class engine, ported.
-- |
-- | Upstream (radix-ui/themes) styles every component by feeding a declarative
-- | `propDefs` table through a runtime `extractProps` reflection pass that turns
-- | prop values into `rt-*` class tokens, `data-*` attributes, and inline styles.
-- | We port the *output*, typed: a `Prop` value realizes to exactly the same token
-- | upstream produces —
-- |
-- |   * enum-with-className  →  `{className}-{value}`   (e.g. `rt-variant-solid`)
-- |   * boolean-with-className → `{className}` when set  (e.g. `rt-high-contrast`)
-- |   * color / radius (non-styling enums) → `data-accent-color` / `data-radius`
-- |
-- | Single-value axes (size, variant, each margin/padding/flex prop) are keyed, so
-- | a later value OVERRIDES an earlier one. That is how a component applies its
-- | default (`Size "2"` first) which the caller can then replace (`Size "3"` later)
-- | — `realize base (defaults <> callerProps)`, last wins.
-- |
-- | Responsive-object props and the arbitrary-value (`--custom-property`) path are
-- | deliberately omitted from this first cut; they extend this same fold.
module Hydrogen.Themes.Prop
  ( Prop(..)
  , attrs
  , el
  , Resolved
  , resolve
  ) where

import Prelude

import Data.Array (filter)
import Data.Foldable (foldl)
import Data.Map (Map)
import Data.Map as Map
import Data.String (joinWith)
import Data.Tuple (Tuple(..), snd)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

-- | A Radix Themes styling prop.
data Prop
  = Class String
  -- styling axes (enum-with-className)
  | Size String
  | Variant String
  | Weight String
  | Trim String
  | Display String
  | Direction String
  | Align String
  | Justify String
  | Wrap String
  | Gap String
  | Position String
  -- grid axes (rt-Grid)
  | Columns String
  | Rows String
  | Flow String
  | AlignContent String
  | JustifyItems String
  -- inset axes (rt-Inset)
  | Side String
  | Clip String
  -- margin / padding
  | M String
  | Mx String
  | My String
  | Mt String
  | Mr String
  | Mb String
  | Ml String
  | P String
  | Px String
  | Py String
  | Pt String
  | Pr String
  | Pb String
  | Pl String
  -- boolean-with-className
  | HighContrast
  -- non-styling enums → data-attrs
  | Color String
  | Radius String
  -- escape hatches
  | DataAttr String String
  | RawAttr String String
  | Width String
  | Height String
  | StyleProp String String

type Acc =
  { axes :: Map String String -- single-value axis key → class token (last wins)
  , free :: Array String -- raw Class tokens, order preserved
  , dataAttrs :: Map String String -- data-* name → value
  , rawAttrs :: Map String String -- plain attribute name → value
  , styles :: Map String String -- inline style property → value
  }

step :: Acc -> Prop -> Acc
step a = case _ of
  Class s -> a { free = a.free <> [ s ] }
  Size v -> axis "size" ("rt-r-size-" <> v)
  Variant v -> axis "variant" ("rt-variant-" <> v)
  Weight v -> axis "weight" ("rt-r-weight-" <> v)
  Trim v -> axis "trim" ("rt-r-lt-" <> v) -- `trim` → leading-trim class `rt-r-lt`
  Display v -> axis "display" ("rt-r-display-" <> v)
  Direction v -> axis "fd" ("rt-r-fd-" <> v)
  Align v -> axis "ai" ("rt-r-ai-" <> v)
  -- justify carries a parseValue: the prop value "between" → class "space-between"
  -- (start/center/end pass through, mapping to flex-start/center/flex-end in CSS).
  Justify v -> axis "jc" ("rt-r-jc-" <> (if v == "between" then "space-between" else v))
  Wrap v -> axis "fw" ("rt-r-fw-" <> v)
  Gap v -> axis "gap" ("rt-r-gap-" <> v)
  Position v -> axis "position" ("rt-r-position-" <> v)
  -- grid: columns/rows are enum→class for 1–9 (parseValue passes enums through);
  -- arbitrary track strings (the custom-property path) are deferred like the
  -- responsive-object path. flow → rt-r-gaf.
  Columns v -> axis "gtc" ("rt-r-gtc-" <> v)
  Rows v -> axis "gtr" ("rt-r-gtr-" <> v)
  Flow v -> axis "gaf" ("rt-r-gaf-" <> v)
  -- alignContent carries a parseValue: between→space-between, around→space-around,
  -- evenly→space-evenly (start/center/end/baseline/stretch pass through).
  AlignContent v -> axis "ac" ("rt-r-ac-" <> alignContentValue v)
  JustifyItems v -> axis "ji" ("rt-r-ji-" <> v)
  -- inset: side (rt-r-side, default all) + clip (rt-r-clip, default border-box).
  Side v -> axis "side" ("rt-r-side-" <> v)
  Clip v -> axis "clip" ("rt-r-clip-" <> v)
  M v -> axis "m" ("rt-r-m-" <> v)
  Mx v -> axis "mx" ("rt-r-mx-" <> v)
  My v -> axis "my" ("rt-r-my-" <> v)
  Mt v -> axis "mt" ("rt-r-mt-" <> v)
  Mr v -> axis "mr" ("rt-r-mr-" <> v)
  Mb v -> axis "mb" ("rt-r-mb-" <> v)
  Ml v -> axis "ml" ("rt-r-ml-" <> v)
  P v -> axis "p" ("rt-r-p-" <> v)
  Px v -> axis "px" ("rt-r-px-" <> v)
  Py v -> axis "py" ("rt-r-py-" <> v)
  Pt v -> axis "pt" ("rt-r-pt-" <> v)
  Pr v -> axis "pr" ("rt-r-pr-" <> v)
  Pb v -> axis "pb" ("rt-r-pb-" <> v)
  Pl v -> axis "pl" ("rt-r-pl-" <> v)
  HighContrast -> axis "hc" "rt-high-contrast"
  Color v -> dataA "accent-color" v
  Radius v -> dataA "radius" v
  DataAttr k v -> dataA k v
  RawAttr k v -> a { rawAttrs = Map.insert k v a.rawAttrs }
  Width v -> sty "width" v
  Height v -> sty "height" v
  StyleProp k v -> sty k v
  where
  axis k cls = a { axes = Map.insert k cls a.axes }
  dataA k v = a { dataAttrs = Map.insert k v a.dataAttrs }
  sty k v = a { styles = Map.insert k v a.styles }
  alignContentValue v = case v of
    "between" -> "space-between"
    "around" -> "space-around"
    "evenly" -> "space-evenly"
    _ -> v

-- | Realize base classes + props into Halogen attributes (class, style, data-*,
-- | raw). Class-token order is base, then raw `Class` tokens, then axes by key —
-- | order is irrelevant to the rendered pixels (the same classes apply the same
-- | CSS), so this is deterministic without mirroring upstream's exact ordering.
-- | The resolved, framework-agnostic parts of a base+props set: the joined class
-- | string, the serialized inline style (empty if none), and the data-*/raw attr
-- | k/v lists. `attrs` is `resolve` rendered to Halogen IProps; a preset wrapper that
-- | hands the class/style/data to a PRIMITIVE (e.g. Themes.Progress → Radix.Progress)
-- | uses `resolve` directly so it doesn't re-emit a parallel class attribute.
type Resolved =
  { class_ :: String
  , style :: String
  , dataAttrs :: Array (Tuple String String)
  , rawAttrs :: Array (Tuple String String)
  }

resolve :: Array String -> Array Prop -> Resolved
resolve base props =
  let
    a = foldl step { axes: Map.empty, free: base, dataAttrs: Map.empty, rawAttrs: Map.empty, styles: Map.empty } props
    classTokens = filter (_ /= "") (a.free <> map snd (Map.toUnfoldable a.axes :: Array (Tuple String String)))
    styleList = Map.toUnfoldable a.styles :: Array (Tuple String String)
  in
    { class_: joinWith " " classTokens
    -- each declaration ends with `;` so the serialized style attribute matches the
    -- browser's own (and React's) form — `height: 80px;`, not `height: 80px`.
    , style: joinWith " " (map (\(Tuple k v) -> k <> ": " <> v <> ";") styleList)
    , dataAttrs: Map.toUnfoldable a.dataAttrs
    , rawAttrs: Map.toUnfoldable a.rawAttrs
    }

attrs :: forall r i. Array String -> Array Prop -> Array (HH.IProp (class :: String, style :: String | r) i)
attrs base props =
  let
    r = resolve base props
    classAttr = [ HP.class_ (HH.ClassName r.class_) ]
    styleAttr = if r.style == "" then [] else [ HP.style r.style ]
    mkData (Tuple k v) = HP.attr (HH.AttrName ("data-" <> k)) v
    mkRaw (Tuple k v) = HP.attr (HH.AttrName k) v
  in
    classAttr <> styleAttr <> map mkData r.dataAttrs <> map mkRaw r.rawAttrs

-- | Render an element with a tag, base classes, props, and children.
el :: forall w i. String -> Array String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
el tag base props children = HH.element (HH.ElemName tag) (attrs base props) children
