-- | radix Tooltip story: an uncontrolled hover/focus floating label. Drives the
-- | real Hydrogen.Radix.Tooltip so portal-to-body + Popper positioning + Escape
-- | dismiss (STR-335 floating template) can be verified
-- | (testing/playwright/scripts/tooltip-portal.mjs).
module Gallery.Story.Tooltip (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Tooltip as Tooltip
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "tooltip", component }

type Slots = (tooltip :: Tooltip.Slot Unit)

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

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
    [ HH.slot_ _tooltip unit Tooltip.component input ]
  where
  input = Tooltip.defaultInput
    { trigger = [ HH.text "Hover me" ]
    , content = [ HH.text "Tooltip label content" ]
    , style = Tooltip.defaultStyle { content = cn "tooltip-content" }
    }