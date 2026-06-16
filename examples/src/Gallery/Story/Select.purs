-- | radix Select story: an uncontrolled floating listbox. Drives the real
-- | Hydrogen.Radix.Select so portal-to-body + Popper positioning + roving focus +
-- | focus/dismiss (STR-335 floating template) can be verified
-- | (testing/playwright/scripts/select-portal.mjs).
module Gallery.Story.Select (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Select as Select
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "select", component }

type Slots = (select :: Select.Slot Unit)

_select :: Proxy "select"
_select = Proxy

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
    [ HH.slot_ _select unit Select.component input ]
  where
  input = Select.defaultInput
    { items =
        [ { value: "apple", label: [ HH.text "Apple" ], disabled: false }
        , { value: "banana", label: [ HH.text "Banana" ], disabled: false }
        , { value: "cherry", label: [ HH.text "Cherry" ], disabled: false }
        ]
    , trigger = [ HH.text "Pick a fruit: " ]
    , style = Select.defaultStyle { content = cn "select-content" }
    }