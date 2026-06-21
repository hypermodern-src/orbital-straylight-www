-- | Overlay open-state invariance template (STR-383, fork #2): the SAME Popover rendered
-- | under four presets, ONE per page (story ids ovl-popover-<preset>), so the open overlay's
-- | body-portaled content is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, drives it open, waits for the literal OVLOPEN
-- | text (the popover content has no role, so this text is how open is detected), snapshots the
-- | whole body, and asserts the open behavioral DOM is byte-identical across all four presets
-- | (only class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlPopover (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (popover :: Popover.Slot Unit)

_popover :: Proxy "popover"
_popover = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-PopoverTrigger", b: "rt-PopperContent rt-PopoverContent" }
  , { name: "shadcn", a: "inline-flex items-center rounded-md border px-4 py-2", b: "z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md" }
  , { name: "daisy", a: "btn", b: "card bg-base-100 shadow-xl p-4" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-popover-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-popover-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-popover-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _popover unit Popover.component (input s) ]

  input s = Popover.defaultInput
    { trigger = [ HH.text "Open" ]
    , content = [ HH.text "OVLOPEN" ]
    , style = Popover.defaultStyle
        { trigger = cn s.a
        , content = cn s.b
        }
    }
