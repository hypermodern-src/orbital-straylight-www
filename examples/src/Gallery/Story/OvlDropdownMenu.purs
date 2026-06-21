-- | Overlay open-state invariance template (STR-383): the SAME DropdownMenu rendered under
-- | four presets, ONE per page (story ids ovl-dropdownmenu-<preset>), so the open overlay's
-- | body-portaled content is unambiguous. The invariance gate (invariance.mjs --overlay) loads
-- | each page, drives it open (click the trigger), waits for the literal `OVLOPEN` item, snapshots
-- | the body, and asserts the open behavioral DOM is byte-identical across all four presets (only
-- | class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlDropdownMenu (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.DropdownMenu as DropdownMenu
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (dropdown :: DropdownMenu.Slot Unit)

_dropdown :: Proxy "dropdown"
_dropdown = Proxy

type Skin = { name :: String, content :: String, item :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", content: "", item: "" }
  , { name: "themes", content: "rt-PopperContent rt-BaseMenuContent rt-DropdownMenuContent", item: "rt-BaseMenuItem rt-DropdownMenuItem" }
  , { name: "shadcn", content: "z-50 min-w-[8rem] rounded-md border bg-popover p-1 shadow-md", item: "relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none" }
  , { name: "daisy", content: "menu dropdown-content rounded-box bg-base-100 p-2 shadow", item: "" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-dropdownmenu-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-dropdownmenu-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-dropdownmenu-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _dropdown unit DropdownMenu.component (input s) ]

  input s = DropdownMenu.defaultInput
    { trigger = [ HH.text "Open" ]
    , entries =
        [ DropdownMenu.menuItem "open" [ HH.text "OVLOPEN" ]
        , DropdownMenu.menuItem "new" [ HH.text "New Tab" ]
        , DropdownMenu.MenuItemEntry { value: "private", label: [ HH.text "New Private Window" ], shortcut: [], accent: "", disabled: true }
        , DropdownMenu.menuItem "share" [ HH.text "Share" ]
        ]
    , style = DropdownMenu.defaultStyle
        { content = cn s.content
        , item = cn s.item
        }
    }
