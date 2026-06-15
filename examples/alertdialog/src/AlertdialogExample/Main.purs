-- | Live demo of the stateful Hydrogen.Themes.AlertDialog (forced-decision modal).
-- | Driven by testing/playwright/scripts/alertdialog-interaction.mjs.
module AlertdialogExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.AlertDialog as AlertDialog
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (alertdialog :: forall q. H.Slot q Void Unit)

_alertdialog :: Proxy "alertdialog"
_alertdialog = Proxy

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
          [ HH.slot_ _alertdialog unit AlertDialog.component input ]
      ]

  input :: AlertDialog.Input
  input =
    { triggerLabel: "Revoke access"
    , title: "Revoke access"
    , description: "Are you sure? This application will no longer be accessible and any existing sessions will be expired."
    , confirmLabel: "Revoke access"
    }
