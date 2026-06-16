-- | radix DropdownMenu story: an uncontrolled button-triggered roving menu. Drives the
-- | real Hydrogen.Radix.DropdownMenu so portal-to-body + Popper positioning +
-- | focus/dismiss + roving menu navigation (STR-335 floating template) can be verified
-- | (testing/playwright/scripts/dropdown-portal.mjs).
module Gallery.Story.DropdownMenu (story) where

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

story :: Story
story = { id: "dropdown-menu", component }

type Slots = (dropdown :: DropdownMenu.Slot Unit)

_dropdown :: Proxy "dropdown"
_dropdown = Proxy

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
    [ HH.slot_ _dropdown unit DropdownMenu.component input ]
  where
  input = DropdownMenu.defaultInput
    { trigger = [ HH.text "Open" ]
    , entries =
        [ DropdownMenu.menuItem "new" [ HH.text "New Tab" ]
        , DropdownMenu.menuItem "window" [ HH.text "New Window" ]
        , DropdownMenu.MenuItemEntry { value: "private", label: [ HH.text "New Private Window" ], shortcut: [], accent: "", disabled: true }
        , DropdownMenu.menuItem "share" [ HH.text "Share" ]
        ]
    , style = DropdownMenu.defaultStyle { content = cn "dropdown-content" }
    }