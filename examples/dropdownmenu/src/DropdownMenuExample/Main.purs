-- | Live demo of the stateful Hydrogen.Themes.DropdownMenu (click-triggered anchored
-- | menu with a roving keyboard highlight).
-- | Driven by testing/playwright/scripts/dropdownmenu-interaction.mjs.
module DropdownMenuExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.DropdownMenu as DropdownMenu
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (dropdownmenu :: forall q. H.Slot q Void Unit)

_dropdownmenu :: Proxy "dropdownmenu"
_dropdownmenu = Proxy

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  void (runUI root unit body)

root :: forall q i o. H.Component q i o Aff
root =
  H.mkComponent
    { initialState: const unit
    , render: const view
    , eval: H.mkEval H.defaultEval
    }
  where
  view :: H.ComponentHTML Void Slots Aff
  view =
    theme
      [ box [ P "6" ]
          [ HH.slot_ _dropdownmenu unit DropdownMenu.component input ]
      ]

  input :: DropdownMenu.Input
  input =
    { triggerLabel: "Options"
    , items: [ "Edit", "Duplicate", "Archive", "Delete" ]
    }
