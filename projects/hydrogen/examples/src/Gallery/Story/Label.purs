-- | radix Label `Styled` story (components-label--styled): a single styled label
-- | reading "Label". Stateless — a static story.
module Gallery.Story.Label (story) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, staticStory)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Label (label)

story :: Story
story = staticStory "label" view

view :: H.ComponentHTML Void () Aff
view =
  HH.div
    [ HP.style "display:contents" ]
    [ label { for: "", class_: cn "label-root" } [ HH.text "Label" ] ]
