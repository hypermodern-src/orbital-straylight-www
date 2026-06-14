-- | radix Collapsible `Styled` story (components-collapsible--styled): an
-- | uncontrolled collapsible (starts closed) with a "Trigger" button and hidden
-- | "Content 1". Stateful — mounts the Collapsible component.
module Gallery.Story.Collapsible (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Collapsible as Collapsible
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "collapsible", component }

type Slots = (collapsible :: Collapsible.Slot Unit)

_collapsible :: Proxy "collapsible"
_collapsible = Proxy

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
    [ HH.slot_ _collapsible unit Collapsible.component styledInput ]
  where
  styledInput = Collapsible.defaultInput
    { style = Collapsible.defaultStyle
        { root = cn "collapsible-root"
        , trigger = cn "collapsible-trigger"
        , content = cn "collapsible-content"
        }
    , trigger = [ HH.text "Trigger" ]
    , content = [ HH.text "Content 1" ]
    }
