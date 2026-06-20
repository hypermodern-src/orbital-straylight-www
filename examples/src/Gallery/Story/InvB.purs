-- | Multi-component behavioral-invariance subject (STR-383, batch B). Renders the
-- | item-based stateful primitives, each in a `[data-invariance="<Component>"]` group
-- | containing four `[data-preset]` variants (unstyled · themes · shadcn · daisy) that
-- | differ ONLY in their Style class lists. The invariance gate (invariance.mjs) proves,
-- | per group, that the behavioral DOM (role=radiogroup/radio/group, aria-checked,
-- | data-state, roving tabindex) is byte-identical across all four presets.
-- |
-- | Both subjects are RovingFocus consumers carrying `items :: Array Item` as DATA: we
-- | pass the SAME fixed items + same `defaultValue` to all four skins and render AT REST,
-- | varying ONLY the class lists. RadioGroup's `indicator` is left empty across all skins
-- | (an indicator span is emitted ONLY when its ClassNames are non-empty, which would make
-- | the DOM skin-dependent and break invariance).
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.InvB (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.RadioGroup as RadioGroup
import Hydrogen.Radix.ToggleGroup as ToggleGroup
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-b", component }

type Slots =
  ( radioGroup :: RadioGroup.Slot Int
  , toggleGroup :: ToggleGroup.Slot Int
  )

_radioGroup :: Proxy "radioGroup"
_radioGroup = Proxy

_toggleGroup :: Proxy "toggleGroup"
_toggleGroup = Proxy

-- | Four skins, each a different class vocabulary on the two parts every subject has:
-- | `a` is the root part, `b` the per-item part. The strings are deliberately unrelated
-- | design systems — invariance must hold regardless of class content.
type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-RadioGroupRoot", b: "rt-RadioGroupItem" }
  , { name: "shadcn", a: "grid gap-2", b: "aspect-square h-4 w-4 rounded-full border" }
  , { name: "daisy", a: "form-control", b: "radio radio-primary" }
  ]

-- | One fixed item set, shared verbatim by every skin of both subjects. Labels are
-- | constant PlainHTML so the only thing differing between presets is the class list.
radioItems :: Array RadioGroup.Item
radioItems =
  [ { value: "1", label: [ HH.text "Default" ], disabled: false }
  , { value: "2", label: [ HH.text "Comfortable" ], disabled: false }
  , { value: "3", label: [ HH.text "Compact" ], disabled: false }
  ]

toggleItems :: Array ToggleGroup.Item
toggleItems =
  [ { value: "left", label: [ HH.text "L" ], disabled: false }
  , { value: "center", label: [ HH.text "C" ], disabled: false }
  , { value: "right", label: [ HH.text "R" ], disabled: false }
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
    [ group "RadioGroup" (mapWithIndex radioGroupCell skins)
    , group "ToggleGroup" (mapWithIndex toggleGroupCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  radioGroupCell i s = preset s $
    HH.slot_ _radioGroup i RadioGroup.component
      (RadioGroup.defaultInput
        { items = radioItems
        , defaultValue = Just "1"
        , style = RadioGroup.defaultStyle { root = cn s.a, item = cn s.b }
        })

  toggleGroupCell i s = preset s $
    HH.slot_ _toggleGroup i ToggleGroup.component
      (ToggleGroup.defaultInput
        { items = toggleItems
        , single = true
        , defaultValue = [ "center" ]
        , ariaLabel = Just "Text alignment"
        , style = { root: cn s.a, item: cn s.b }
        })
