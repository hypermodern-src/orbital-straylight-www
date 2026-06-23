-- | Multi-component behavioral-invariance subject (STR-383). Renders several primitives,
-- | each in a `[data-invariance="<Component>"]` group containing four `[data-preset]`
-- | variants (unstyled · themes · shadcn · daisy) that differ ONLY in their Style class
-- | lists. The invariance gate (invariance.mjs) proves, per group, that the behavioral DOM
-- | is byte-identical across all four presets. Many components, one page, one build.
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.Presets (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.AspectRatio as AspectRatio
import Hydrogen.Radix.Checkbox as Checkbox
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Label as Label
import Hydrogen.Radix.Progress as Progress
import Hydrogen.Radix.Separator as Separator
import Hydrogen.Radix.Switch as Switch
import Hydrogen.Radix.Toggle as Toggle
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "presets", component }

type Slots =
  ( toggle :: Toggle.Slot Int
  , switch :: Switch.Slot Int
  , checkbox :: Checkbox.Slot Int
  )

_toggle :: Proxy "toggle"
_toggle = Proxy

_switch :: Proxy "switch"
_switch = Proxy

_checkbox :: Proxy "checkbox"
_checkbox = Proxy

-- | Four skins, each just a different class vocabulary on whatever parts a component has.
-- | `a` is the primary/root part, `b` the secondary part (thumb / indicator). The strings
-- | are deliberately unrelated design systems — invariance must hold regardless.
type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-BaseButton", b: "rt-Thumb" }
  , { name: "shadcn", a: "peer inline-flex h-6 w-11 shrink-0 rounded-full border-2", b: "pointer-events-none block h-5 w-5 rounded-full bg-background" }
  , { name: "daisy", a: "toggle toggle-primary", b: "toggle-mark" }
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
    [ group "Toggle" (mapWithIndex toggleCell skins)
    , group "Switch" (mapWithIndex switchCell skins)
    , group "Checkbox" (mapWithIndex checkboxCell skins)
    , group "Separator" (mapWithIndex separatorCell skins)
    , group "AspectRatio" (mapWithIndex aspectRatioCell skins)
    , group "Progress" (mapWithIndex progressCell skins)
    , group "Label" (mapWithIndex labelCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  toggleCell i s = preset s $
    HH.slot_ _toggle i Toggle.component
      (Toggle.defaultInput
        { style = { root: cn s.a }
        , ariaLabel = Just "Toggle"
        , children = [ HH.text "B" ]
        })

  switchCell i s = preset s $
    HH.slot_ _switch i Switch.component
      (Switch.defaultInput { style = { root: cn s.a, thumb: cn s.b } })

  checkboxCell i s = preset s $
    HH.slot_ _checkbox i Checkbox.component
      (Checkbox.defaultInput { style = { root: cn s.a, indicator: cn s.b } })

  -- Stateless render-fn primitives (no slots): their behavioral surface
  -- (role / aria-* / data-*) is class-independent, so invariance must hold.
  separatorCell _ s = preset s $
    Separator.separator (Separator.defaultInput { class_ = cn s.a })

  aspectRatioCell _ s = preset s $
    AspectRatio.aspectRatio (AspectRatio.defaultInput { class_ = cn s.a }) [ HH.text "A" ]

  progressCell _ s = preset s $
    Progress.progress { value: Just 25.0, max: 100.0, class_: cn s.a, indicator: cn s.b, rootAttrs: [] }

  -- same `for` across all skins — the variants differ ONLY in class (per-instance ids
  -- would be radix-generated and normalized; a hand-set `for` must be constant).
  labelCell _ s = preset s $
    Label.label { for: "demo-label", class_: cn s.a } [ HH.text "L" ]
