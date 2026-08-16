-- | radix Checkbox `Styled` story (components-checkbox--styled): seven variants —
-- | custom Label + checkbox, native label + checkbox, native checkbox, and the
-- | htmlFor forms. All uncontrolled (unchecked → empty 30×30 box).
module Gallery.Story.Checkbox (story) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Checkbox as Checkbox
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "checkbox", component }

type Slots = (checkbox :: Checkbox.Slot Int)

_checkbox :: Proxy "checkbox"
_checkbox = Proxy

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
    [ HH.p_ [ HH.text "This checkbox is nested inside a label. The state is uncontrolled." ]
    , HH.h1_ [ HH.text "Custom label" ]
    , HH.label_ [ HH.text "Label ", box 0 ]
    , HH.br_
    , HH.br_
    , HH.h1_ [ HH.text "Native label" ]
    , HH.label_ [ HH.text "Label ", box 1 ]
    , HH.h1_ [ HH.text "Native label + native checkbox" ]
    , HH.label_ [ HH.text "Label ", nativeBox ]
    , HH.h1_ [ HH.text "Custom label + htmlFor" ]
    , HH.label_ [ HH.text "Label" ]
    , box 2
    , HH.br_
    , HH.br_
    , HH.h1_ [ HH.text "Native label + htmlFor" ]
    , HH.label_ [ HH.text "Label" ]
    , box 3
    , HH.h1_ [ HH.text "Native label + native checkbox" ]
    , HH.label_ [ HH.text "Label" ]
    , nativeBox
    ]
  where
  box i = HH.slot_ _checkbox i Checkbox.component styledInput
  nativeBox = HH.input [ HP.type_ HP.InputCheckbox ]

styledInput :: Checkbox.Input
styledInput = Checkbox.defaultInput
  { style = { root: cn "checkbox-root", indicator: cn "checkbox-indicator" } }
