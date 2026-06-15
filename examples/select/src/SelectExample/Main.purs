-- | Live demo of the stateful Hydrogen.Themes.Select (anchored single-select
-- | listbox). Driven by testing/playwright/scripts/select-interaction.mjs.
module SelectExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Select as Select
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (select :: forall q. H.Slot q Void Unit)

_select :: Proxy "select"
_select = Proxy

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
          [ HH.slot_ _select unit Select.component input ]
      ]

  input :: Select.Input
  input =
    { items:
        [ { value: "apple", label: "Apple" }
        , { value: "orange", label: "Orange" }
        , { value: "grape", label: "Grape" }
        , { value: "pear", label: "Pear" }
        ]
    , selected: "apple"
    }
