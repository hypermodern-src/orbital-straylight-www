-- | Live demo of the stateful Hydrogen.Themes.ContextMenu (right-click menu).
-- | Driven by testing/playwright/scripts/contextmenu-interaction.mjs.
module ContextMenuExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.ContextMenu as ContextMenu
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (contextmenu :: forall q. H.Slot q Void Unit)

_contextmenu :: Proxy "contextmenu"
_contextmenu = Proxy

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
          [ HH.slot_ _contextmenu unit ContextMenu.component input ]
      ]

  input :: ContextMenu.Input
  input =
    { regionLabel: "Right-click here"
    , items: [ "Back", "Forward", "Reload", "Save As…" ]
    }
