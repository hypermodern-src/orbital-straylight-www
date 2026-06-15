-- | Live demo of the stateful Hydrogen.Themes.HoverCard (hover-intent anchored
-- | overlay). Driven by testing/playwright/scripts/hovercard-interaction.mjs.
module HoverCardExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.HoverCard as HoverCard
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (hovercard :: forall q. H.Slot q Void Unit)

_hovercard :: Proxy "hovercard"
_hovercard = Proxy

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
          [ HH.slot_ _hovercard unit HoverCard.component input ]
      ]

  input :: HoverCard.Input
  input =
    { triggerLabel: "@radix_ui"
    , heading: "Radix UI"
    , body: "A hover card surfaces rich preview content on hover. Moving the pointer from the trigger into the card keeps it open; leaving both dismisses it."
    }
