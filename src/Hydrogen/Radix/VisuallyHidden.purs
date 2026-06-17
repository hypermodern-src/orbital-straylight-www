-- | Hydrogen.Radix.VisuallyHidden — content available to screen readers but
-- | visually hidden (radix `VisuallyHidden`). A stateless presentational
-- | primitive: a `<span>` carrying the canonical clip style.
-- |
-- | Idiom note: stateless primitives are plain render functions (no Halogen
-- | component / no Slot); they take their children as `Array HH.PlainHTML` and
-- | optional extra class names. Stateful primitives (see `Toggle`) are full
-- | components.
-- |
-- | Upstream (visually-hidden.tsx) spreads `{...props}` onto the span and merges
-- | `style={{ ...VISUALLY_HIDDEN_STYLES, ...props.style }}` — caller style overrides
-- | a default key IN PLACE and appends new keys at the end. `visuallyHiddenWith`
-- | reproduces that (arbitrary attrs + in-place style merge); `visuallyHidden` /
-- | `visuallyHidden_` are the no-extra-style convenience forms.
module Hydrogen.Radix.VisuallyHidden
  ( visuallyHidden
  , visuallyHidden_
  , visuallyHiddenWith
  , inlineStyle
  , baseStyles
  , mergeStyle
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLspan)
import Data.Array (find, snoc)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..), fst)
import Data.String (joinWith)
import Data.Foldable (foldl)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, classes)

-- | The canonical visually-hidden style as an ORDERED key→value list, in the
-- | BROWSER-NORMALIZED form the DOM-oracle sees (React sets it via the style
-- | PROPERTY, so `0`→`0px` and `word-wrap`→`overflow-wrap` when serialized).
baseStyles :: Array (Tuple String String)
baseStyles =
  [ Tuple "position" "absolute"
  , Tuple "border" "0px"
  , Tuple "width" "1px"
  , Tuple "height" "1px"
  , Tuple "padding" "0px"
  , Tuple "margin" "-1px"
  , Tuple "overflow" "hidden"
  , Tuple "clip" "rect(0px, 0px, 0px, 0px)"
  , Tuple "white-space" "nowrap"
  , Tuple "overflow-wrap" "normal"
  ]

-- | Serialize an ordered style list to the `k: v;`-joined attribute string React emits.
serialize :: Array (Tuple String String) -> String
serialize = joinWith " " <<< map (\(Tuple k v) -> k <> ": " <> v <> ";")

-- | Merge caller style over the base, React-style: override an existing key IN PLACE
-- | (keeping its slot) and append unknown keys at the END. `{ ...BASE, ...caller }`.
mergeStyle :: Array (Tuple String String) -> Array (Tuple String String) -> Array (Tuple String String)
mergeStyle base caller = foldl step base caller
  where
  step acc (Tuple k v) = case find (\t -> fst t == k) acc of
    Just _ -> map (\t -> if fst t == k then Tuple k v else t) acc
    Nothing -> snoc acc (Tuple k v)

-- | The canonical visually-hidden inline style string (no caller overrides). Authoring
-- | the normalized string makes the literal `style=` attribute byte-match upstream.
inlineStyle :: String
inlineStyle = serialize baseStyles

-- | A visually-hidden span with extra classes and static children.
visuallyHidden :: forall w i. ClassNames -> Array HH.PlainHTML -> HH.HTML w i
visuallyHidden extra children =
  HH.span
    [ HP.style inlineStyle, classes extra ]
    (map HH.fromPlainHTML children)

-- | A visually-hidden span with just children.
visuallyHidden_ :: forall w i. Array HH.PlainHTML -> HH.HTML w i
visuallyHidden_ = visuallyHidden mempty

-- | The full surface: arbitrary attrs (id / aria-* / data-* / handlers) spread onto the
-- | span, plus a caller `style` list merged in-place over the canonical clip style.
visuallyHiddenWith
  :: forall w i
   . { class_ :: ClassNames
     , style :: Array (Tuple String String)
     , attrs :: Array (HH.IProp HTMLspan i)
     }
  -> Array HH.PlainHTML
  -> HH.HTML w i
visuallyHiddenWith o children =
  HH.span
    ( [ classes o.class_
      , HP.style (serialize (mergeStyle baseStyles o.style))
      ] <> o.attrs
    )
    (map HH.fromPlainHTML children)
