-- | Behavioral-invariance subject (STR-383): the SAME Toggle primitive rendered under
-- | four presets — unstyled / themes (rt-*) / shadcn / daisyUI — each only a different
-- | `Style.root` class list, each wrapped in a `[data-preset]` node. The invariance gate
-- | (testing/playwright/scripts/invariance.mjs) drives `?story=toggle-presets` and asserts
-- | the behavioral DOM (role/aria-pressed/data-state/type) is byte-identical across all
-- | four — proving behavior lives in the primitive and the skin is pure decoration.
-- |
-- | NOT a pixel story: excluded from the gallery manifest (no golden png), reachable only
-- | by id for the invariance gate.
module Gallery.Story.TogglePresets (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, cn)
import Hydrogen.Radix.Toggle as Toggle
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "toggle-presets", component }

type Slots = (toggle :: Toggle.Slot Int)

_toggle :: Proxy "toggle"
_toggle = Proxy

-- | The four preset skins for Toggle's single part — wildly different class vocabularies,
-- | identical behavior. (orbital lands last, on these same proven rails.)
presets :: Array { name :: String, root :: ClassNames }
presets =
  [ { name: "unstyled", root: cn "" }
  , { name: "themes",   root: cn "rt-reset rt-BaseButton rt-Button rt-ToggleButton" }
  , { name: "shadcn",   root: cn "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors" }
  , { name: "daisy",    root: cn "btn btn-ghost btn-sm" }
  ]

component :: StoryComponent
component = H.mkComponent
  { initialState: const unit
  , render: const view
  , eval: H.mkEval H.defaultEval
  }

view :: H.ComponentHTML Void Slots Aff
view =
  HH.div
    [ HP.style "display:contents" ]
    (mapWithIndex cell presets)
  where
  cell i p =
    HH.div
      [ HP.attr (HH.AttrName "data-preset") p.name ]
      [ HH.slot_ _toggle i Toggle.component
          (Toggle.defaultInput
            { style = Toggle.defaultStyle { root = p.root }
            , ariaLabel = Just "Toggle"
            , children = [ HH.text "Toggle" ]
            }
          )
      ]
