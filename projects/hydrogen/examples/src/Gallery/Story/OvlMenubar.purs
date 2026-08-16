-- | Overlay open-state invariance template (STR-383): the SAME Menubar rendered under four
-- | presets, ONE per page (story ids ovl-menubar-<preset>), so the open overlay's body-portaled
-- | content is unambiguous. The invariance gate (invariance.mjs --overlay) loads each page, drives
-- | the FIRST menu open (click the first trigger), waits for the literal `OVLOPEN` item, snapshots
-- | the body, and asserts the open behavioral DOM is byte-identical across all four presets (only
-- | class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlMenubar (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Menubar as Menubar
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (menubar :: Menubar.Slot Unit)

_menubar :: Proxy "menubar"
_menubar = Proxy

type Skin = { name :: String, root :: String, trigger :: String, content :: String, item :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", root: "", trigger: "", content: "", item: "" }
  , { name: "themes", root: "rt-BaseMenubarRoot rt-MenubarRoot", trigger: "rt-reset rt-BaseMenubarTrigger rt-MenubarTrigger", content: "rt-PopperContent rt-BaseMenuContent rt-MenubarContent", item: "rt-BaseMenuItem rt-MenubarItem" }
  , { name: "shadcn", root: "flex h-10 items-center space-x-1 rounded-md border bg-background p-1", trigger: "flex cursor-default select-none items-center rounded-sm px-3 py-1.5 text-sm font-medium outline-none", content: "z-50 min-w-[12rem] rounded-md border bg-popover p-1 shadow-md", item: "relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none" }
  , { name: "daisy", root: "menu menu-horizontal rounded-box bg-base-200 p-1", trigger: "btn btn-ghost btn-sm", content: "menu dropdown-content rounded-box bg-base-100 p-2 shadow", item: "" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-menubar-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-menubar-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-menubar-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _menubar unit Menubar.component (input s) ]

  input s = Menubar.defaultInput
    { menus =
        [ { value: "file"
          , trigger: [ HH.text "File" ]
          , disabled: false
          , entries:
              [ Menubar.menuItem "open" [ HH.text "OVLOPEN" ]
              , Menubar.menuItem "new" [ HH.text "New" ]
              , Menubar.MenuItemEntry { value: "save-as", label: [ HH.text "Save As" ], shortcut: [], accent: "", disabled: true }
              , Menubar.menuItem "save" [ HH.text "Save" ]
              ]
          }
        , { value: "edit"
          , trigger: [ HH.text "Edit" ]
          , disabled: false
          , entries:
              [ Menubar.menuItem "undo" [ HH.text "Undo" ]
              , Menubar.menuItem "redo" [ HH.text "Redo" ]
              ]
          }
        ]
    , style = Menubar.defaultStyle
        { root = cn s.root
        , trigger = cn s.trigger
        , content = cn s.content
        , item = cn s.item
        }
    }
