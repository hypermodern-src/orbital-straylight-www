-- | Live demo of Hydrogen.Themes.ScrollArea (custom scrollbar, thumb tracks scroll).
-- | Driven by testing/playwright/scripts/scrollarea-interaction.mjs.
module ScrollAreaExample.Main where

import Prelude

import Data.Array ((..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Layout (box)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.ScrollArea as ScrollArea
import Hydrogen.Themes.Theme (theme)
import Type.Proxy (Proxy(..))

type Slots = (scrollarea :: forall q. H.Slot q Void Unit)

_scrollarea :: Proxy "scrollarea"
_scrollarea = Proxy

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
      [ box [ P "6", StyleProp "max-width" "320px" ]
          [ HH.slot_ _scrollarea unit ScrollArea.component input ]
      ]

  input :: ScrollArea.Input
  input =
    { heightPx: 220
    , items: map (\i -> "Scrollable line of content number " <> show i) (1 .. 30)
    }
