-- | radix Separator `Styled` story (components-separator--styled): a horizontal
-- | semantic + decorative separator, then a vertical semantic + decorative pair in
-- | a flex row. Stateless — a static story.
module Gallery.Story.Separator (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, staticStory)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (Orientation(..), cn)
import Hydrogen.Radix.Separator (separator)

story :: Story
story = staticStory "separator" view

view :: H.ComponentHTML Void () Aff
view =
  HH.div
    [ HP.style "display:contents" ]
    [ HH.h1_ [ HH.text "Horizontal" ]
    , HH.p_ [ HH.text "The following separator is horizontal and has semantic meaning." ]
    , sep Horizontal false
    , HH.p_ [ HH.text "The following separator is horizontal and is purely decorative. Assistive technology will ignore this element." ]
    , sep Horizontal true
    , HH.h1_ [ HH.text "Vertical" ]
    , HH.div
        [ HP.style "display: flex; align-items: center" ]
        [ HH.p_ [ HH.text "The following separator is vertical and has semantic meaning." ]
        , sep Vertical false
        , HH.p_ [ HH.text "The following separator is vertical and is purely decorative. Assistive technology will ignore this element." ]
        , sep Vertical true
        ]
    ]
  where
  sep orientation decorative = separator { orientation, decorative, class_: cn "separator-root" }
