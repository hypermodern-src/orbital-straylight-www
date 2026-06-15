-- | Live demo of the stateful Hydrogen.Themes.Tooltip (hover-triggered floating label).
-- | Driven by testing/playwright/scripts/tooltip-interaction.mjs.
module TooltipExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Tooltip as Tooltip
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (tooltip :: forall q. H.Slot q Void Unit)

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

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
  -- Generous top/left padding so the trigger sits away from the viewport edge —
  -- the tooltip is placed ABOVE the trigger, so it needs vertical room.
  view :: H.ComponentHTML Void Slots Aff
  view =
    theme
      [ box [ Pt "9", Pl "9", P "6" ]
          [ HH.slot_ _tooltip unit Tooltip.component input ]
      ]

  input :: Tooltip.Input
  input =
    { triggerLabel: "Hover me"
    , content: "Tooltips appear on hover after a short delay and vanish on mouse-leave."
    }
