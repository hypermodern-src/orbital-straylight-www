-- | Overlay open-state invariance template (STR-383, fork #2): the SAME HoverCard rendered
-- | under four presets, ONE per page (story ids ovl-hovercard-<preset>), so the open overlay's
-- | body-portaled content is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, drives it open via HOVER, snapshots the whole
-- | body, and asserts the open behavioral DOM is byte-identical across all four presets (only
-- | class/style differ). The card content has NO role, so the literal `OVLOPEN` text in the
-- | content is the open-detect signal the gate waits for.
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlHoverCard (stories, ids) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.HoverCard as HoverCard
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (hoverCard :: HoverCard.Slot Unit)

_hoverCard :: Proxy "hoverCard"
_hoverCard = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-Link rt-underline-auto", b: "rt-HoverCardContent" }
  , { name: "shadcn", a: "underline", b: "z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md" }
  , { name: "daisy", a: "link", b: "card bg-base-100 shadow-xl" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-hovercard-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-hovercard-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-hovercard-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _hoverCard unit HoverCard.component (input s) ]

  input s = HoverCard.defaultInput
    { trigger = [ HH.text "Hover me" ]
    , content = [ HH.text "OVLOPEN" ]
    , openDelay = 0
    , closeDelay = 0
    , style = HoverCard.defaultStyle
        { trigger = cn s.a
        , content = cn s.b
        }
    }
