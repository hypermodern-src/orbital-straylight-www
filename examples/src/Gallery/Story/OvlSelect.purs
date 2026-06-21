-- | Overlay open-state invariance template (STR-383, fork): the SAME Select rendered
-- | under four presets, ONE per page (story ids ovl-select-<preset>), so the open overlay's
-- | body-portaled listbox is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, clicks the trigger button to drive it open,
-- | waits for the literal "OVLOPEN" option text, snapshots the whole body, and asserts the
-- | open behavioral DOM is byte-identical across all four presets (only class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlSelect (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Select as Select
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (select :: Select.Slot Unit)

_select :: Proxy "select"
_select = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-SelectTrigger", b: "rt-SelectContent" }
  , { name: "shadcn", a: "flex h-10 w-full items-center justify-between rounded-md border bg-background px-3 py-2", b: "relative z-50 max-h-96 overflow-hidden rounded-md border bg-popover shadow-md" }
  , { name: "daisy", a: "select select-bordered", b: "menu bg-base-200 rounded-box" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-select-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-select-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-select-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _select unit Select.component (input s) ]

  input s = Select.defaultInput
    { items =
        [ { value: "apple", label: [ HH.text "Apple" ], disabled: false }
        , { value: "ovlopen", label: [ HH.text "OVLOPEN" ], disabled: false }
        , { value: "cherry", label: [ HH.text "Cherry" ], disabled: false }
        ]
    , trigger = [ HH.text "Pick a fruit: " ]
    , style = Select.defaultStyle
        { trigger = cn s.a
        , content = cn s.b
        }
    }
