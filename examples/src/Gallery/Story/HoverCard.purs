-- | radix HoverCard story: an uncontrolled hover-opened floating card. Drives the
-- | real Hydrogen.Radix.HoverCard so portal-to-body + Popper positioning + hover/
-- | Escape dismiss (STR-335 floating template) can be verified.
module Gallery.Story.HoverCard (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.HoverCard as HoverCard
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "hover-card", component }

type Slots = (hoverCard :: HoverCard.Slot Unit)

_hoverCard :: Proxy "hoverCard"
_hoverCard = Proxy

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
    [ HH.slot_ _hoverCard unit HoverCard.component input ]
  where
  input = HoverCard.defaultInput
    { trigger = [ HH.text "Hover me" ]
    , content = [ HH.text "Hover card body content" ]
    , style = HoverCard.defaultStyle { content = cn "hover-card-content" }
    }
