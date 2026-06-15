-- | Live demo of the stateful Hydrogen.Themes.Popover (anchored floating overlay).
-- | Driven by testing/playwright/scripts/popover-interaction.mjs.
module PopoverExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Popover as Popover
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (popover :: forall q. H.Slot q Void Unit)

_popover :: Proxy "popover"
_popover = Proxy

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
          [ HH.slot_ _popover unit Popover.component input ]
      ]

  input :: Popover.Input
  input =
    { triggerLabel: "Comments"
    , body: "Popovers anchor a floating panel to their trigger. Click outside or press Escape to dismiss."
    }
