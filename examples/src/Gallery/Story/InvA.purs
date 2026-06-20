-- | Multi-component behavioral-invariance subject (STR-383, batch A). Renders several
-- | primitives, each in a `[data-invariance="<Component>"]` group containing four
-- | `[data-preset]` variants (unstyled · themes · shadcn · daisy) that differ ONLY in
-- | their Style class lists. The invariance gate proves, per group, that the behavioral
-- | DOM (role / aria-* / data-* / tabindex / inline style geometry) is byte-identical
-- | across all four presets — same inputs everywhere, only the class vocabulary varies.
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.InvA (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Avatar as Avatar
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Slider as Slider
import Hydrogen.Radix.VisuallyHidden as VisuallyHidden
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-a", component }

type Slots =
  ( avatar :: Avatar.Slot Int
  , slider :: Slider.Slot Int
  )

_avatar :: Proxy "avatar"
_avatar = Proxy

_slider :: Proxy "slider"
_slider = Proxy

-- | Four skins, each just a different class vocabulary on whatever parts a component has.
-- | `a` is the primary/root part, `b`/`c`/`d` secondary parts (image / fallback / thumb /
-- | track / range). The strings are deliberately unrelated design systems — invariance
-- | must hold regardless of which one is on.
type Skin = { name :: String, a :: String, b :: String, c :: String, d :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "", c: "", d: "" }
  , { name: "themes", a: "rt-reset rt-AvatarRoot", b: "rt-AvatarImage", c: "rt-AvatarFallback", d: "rt-SliderThumb" }
  , { name: "shadcn", a: "relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full", b: "aspect-square h-full w-full", c: "flex h-full w-full items-center justify-center rounded-full bg-muted", d: "block h-5 w-5 rounded-full border-2 border-primary bg-background" }
  , { name: "daisy", a: "avatar", b: "mask mask-squircle", c: "placeholder", d: "range range-primary" }
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
    [ group "VisuallyHidden" (mapWithIndex visuallyHiddenCell skins)
    , group "Avatar" (mapWithIndex avatarCell skins)
    , group "Slider" (mapWithIndex sliderCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  -- Stateless render-fn: a <span> with the canonical clip inline-style; the only thing
  -- the skin varies is the extra class list. Behavioral surface (the style= attr +
  -- children) is class-independent.
  visuallyHiddenCell _ s = preset s $
    VisuallyHidden.visuallyHidden (cn s.a) [ HH.text "Screen-reader only" ]

  -- Stateful (Slot). Empty src ⇒ status resolves to "error" at rest, fallback shown,
  -- no <img>. data-state lives on the img (absent here), so the at-rest behavioral
  -- surface is the root span + fallback span — both class-only varying.
  avatarCell i s = preset s $
    HH.slot_ _avatar i Avatar.component
      (Avatar.defaultInput
        { src = ""
        , alt = "User avatar"
        , fallback = [ HH.text "AB" ]
        , style = { root: cn s.a, image: cn s.b, fallback: cn s.c }
        })

  -- Stateful (Slot). At rest the single thumb is role=slider, tabindex=0, with fixed
  -- aria-valuemin/now/max and deterministic inline position geometry — all class-
  -- independent. Same value/min/max/step across skins, only class lists vary.
  sliderCell i s = preset s $
    HH.slot_ _slider i Slider.component
      (Slider.defaultInput
        { value = Just 40
        , min = 0
        , max = 100
        , step = 1
        , style = { root: cn s.a, track: cn s.a, range: cn s.a, thumb: cn s.d }
        })
