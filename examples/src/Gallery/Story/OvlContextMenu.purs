-- | Overlay open-state invariance template (STR-383): the SAME ContextMenu rendered under
-- | four presets, ONE per page (story ids ovl-contextmenu-<preset>), so the open overlay's
-- | body-portaled content is unambiguous. The invariance gate (invariance.mjs --overlay) loads
-- | each page, drives it open (right-click the trigger AREA), waits for the literal `OVLOPEN`
-- | item, snapshots the body, and asserts the open behavioral DOM is byte-identical across all
-- | four presets (only class/style differ).
-- |
-- | NB: ContextMenu has NO button trigger — its trigger is a right-click target DIV (role-less),
-- | so the gate's open gesture must be a `contextmenu` (right-click) on the trigger div, not a
-- | click on a button.
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlContextMenu (stories, ids) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.ContextMenu as ContextMenu
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (contextMenu :: ContextMenu.Slot Unit)

_contextMenu :: Proxy "contextMenu"
_contextMenu = Proxy

type Skin = { name :: String, content :: String, item :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", content: "", item: "" }
  , { name: "themes", content: "rt-PopperContent rt-BaseMenuContent rt-ContextMenuContent", item: "rt-BaseMenuItem rt-ContextMenuItem" }
  , { name: "shadcn", content: "z-50 min-w-[8rem] rounded-md border bg-popover p-1 shadow-md", item: "relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none" }
  , { name: "daisy", content: "menu rounded-box bg-base-100 p-2 shadow", item: "" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-contextmenu-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-contextmenu-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-contextmenu-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _contextMenu unit ContextMenu.component (input s) ]

  input s = ContextMenu.defaultInput
    { trigger = [ HH.text "Right-click here" ]
    , entries =
        [ ContextMenu.menuItem "open" [ HH.text "OVLOPEN" ]
        , ContextMenu.menuItem "back" [ HH.text "Back" ]
        , ContextMenu.MenuItemEntry { value: "forward", label: [ HH.text "Forward" ], shortcut: [], accent: "", disabled: true }
        , ContextMenu.menuItem "reload" [ HH.text "Reload" ]
        ]
    , style = ContextMenu.defaultStyle
        { content = cn s.content
        , item = cn s.item
        }
    }
