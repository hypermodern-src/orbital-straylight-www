-- | radix Dialog story: an uncontrolled modal. Drives the real Hydrogen.Radix.Dialog
-- | so the portal-to-body + focus-on-open behavior (STR-335) can be verified in a
-- | browser (testing/playwright/scripts/dialog-portal.mjs).
module Gallery.Story.Dialog (story) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "dialog", component }

type Slots = (dialog :: Dialog.Slot Unit)

_dialog :: Proxy "dialog"
_dialog = Proxy

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
    [ HH.slot_ _dialog unit Dialog.component input ]
  where
  input = Dialog.defaultInput
    { trigger = [ HH.text "Open" ]
    , title = [ HH.text "Dialog title" ]
    , description = [ HH.text "Dialog description." ]
    , content = [ HH.text "Body content" ]
    , style = Dialog.defaultStyle
        { overlay = cn "dialog-overlay"
        , content = cn "dialog-content"
        }
    }
