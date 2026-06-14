-- | radix Switch `Styled` story (components-switch--styled): an uncontrolled switch
-- | nested inside a label. Stateful — mounts the Switch component.
module Gallery.Story.Switch (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Switch as Switch
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "switch", component }

type Slots = (switch :: Switch.Slot Unit)

_switch :: Proxy "switch"
_switch = Proxy

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
    [ HH.p_ [ HH.text "This switch is nested inside a label. The state is uncontrolled." ]
    , HH.label_
        [ HH.text "This is the label "
        , HH.slot_ _switch unit Switch.component styledInput
        ]
    ]
  where
  styledInput = Switch.defaultInput
    { style = Switch.defaultStyle { root = cn "switch-root", thumb = cn "switch-thumb" } }
