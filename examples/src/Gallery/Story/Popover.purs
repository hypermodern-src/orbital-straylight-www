-- | radix Popover story: an uncontrolled floating popover. Drives the real
-- | Hydrogen.Radix.Popover so portal-to-body + Popper positioning + focus/dismiss
-- | (STR-335 floating template) can be verified (testing/playwright/scripts/popover-portal.mjs).
module Gallery.Story.Popover (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "popover", component }

type Slots = (popover :: Popover.Slot Unit)

_popover :: Proxy "popover"
_popover = Proxy

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
    [ HH.slot_ _popover unit Popover.component input ]
  where
  input = Popover.defaultInput
    { trigger = [ HH.text "Open" ]
    , content = [ HH.text "Popover body content" ]
    , style = Popover.defaultStyle { content = cn "popover-content" }
    }
