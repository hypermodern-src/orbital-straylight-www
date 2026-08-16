-- | radix ContextMenu story: an uncontrolled right-click menu. Drives the real
-- | Hydrogen.Radix.ContextMenu so portal-to-body + Popper positioning + focus/dismiss
-- | (STR-335 floating template) can be verified (testing/playwright/scripts/context-menu-portal.mjs).
module Gallery.Story.ContextMenu (story) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.ContextMenu as ContextMenu
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "context-menu", component }

type Slots = (contextMenu :: ContextMenu.Slot Unit)

_contextMenu :: Proxy "contextMenu"
_contextMenu = Proxy

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
    [ HH.slot_ _contextMenu unit ContextMenu.component input ]
  where
  input = ContextMenu.defaultInput
    { trigger = [ HH.text "Right-click here" ]
    , entries =
        [ ContextMenu.menuItem "back" [ HH.text "Back" ]
        , ContextMenu.MenuItemEntry { value: "forward", label: [ HH.text "Forward" ], shortcut: [], accent: "", disabled: true }
        , ContextMenu.menuItem "reload" [ HH.text "Reload" ]
        ]
    , style = ContextMenu.defaultStyle { content = cn "context-menu-content" }
    }