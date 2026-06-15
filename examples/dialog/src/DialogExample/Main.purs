-- | Live demo of the stateful Hydrogen.Themes.Dialog (the Bucket B reference).
-- | Mounts the Dialog component inside a `.radix-themes` Theme root so its rt-*
-- | classes are styled; the Playwright interaction harness (testing/playwright/
-- | dialog-interaction.mjs) drives open / Escape / backdrop / button-close.
module DialogExample.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Dialog as Dialog
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (dialog :: forall q. H.Slot q Void Unit)

_dialog :: Proxy "dialog"
_dialog = Proxy

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
          [ HH.slot_ _dialog unit Dialog.component input ]
      ]

  input :: Dialog.Input
  input =
    { triggerLabel: "Edit profile"
    , title: "Edit profile"
    , description: "Make changes to your profile here. Click save when you're done."
    }
