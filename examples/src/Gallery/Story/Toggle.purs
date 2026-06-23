-- | radix Toggle `Styled` story (components-toggle--styled): a single uncontrolled
-- | two-state button reading "Toggle", starting off. Stateful — mounts the Toggle.
module Gallery.Story.Toggle (story) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Toggle as Toggle
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "toggle", component }

type Slots = (toggle :: Toggle.Slot Unit)

_toggle :: Proxy "toggle"
_toggle = Proxy

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
    [ HH.slot_ _toggle unit Toggle.component styledInput ]
  where
  styledInput = Toggle.defaultInput
    { style = Toggle.defaultStyle { root = cn "toggle-root" }
    , children = [ HH.text "Toggle" ]
    }
