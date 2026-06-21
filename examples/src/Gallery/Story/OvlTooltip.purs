-- | Overlay open-state invariance template (STR-383, fork #2): the SAME Tooltip rendered
-- | under four presets, ONE per page (story ids ovl-tooltip-<preset>), so the open overlay's
-- | body-portaled content is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, drives it open via HOVER, snapshots the whole
-- | body, and asserts the open behavioral DOM is byte-identical across all four presets (only
-- | class/style differ). The content carries the literal `OVLOPEN` text the gate waits for.
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlTooltip (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Tooltip as Tooltip
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (tooltip :: Tooltip.Slot Unit)

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-BaseTooltipTrigger", b: "rt-TooltipContent" }
  , { name: "shadcn", a: "inline-flex items-center", b: "z-50 overflow-hidden rounded-md bg-primary px-3 py-1.5 text-xs text-primary-foreground" }
  , { name: "daisy", a: "tooltip", b: "tooltip-content" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-tooltip-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-tooltip-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-tooltip-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _tooltip unit Tooltip.component (input s) ]

  input s = Tooltip.defaultInput
    { trigger = [ HH.text "Hover me" ]
    , content = [ HH.text "OVLOPEN" ]
    , delayMs = 0
    , style = Tooltip.defaultStyle
        { trigger = cn s.a
        , content = cn s.b
        }
    }
