-- | radix AlertDialog story: an uncontrolled modal alert dialog. Drives the real
-- | Hydrogen.Radix.AlertDialog so portal-to-body + focus-trap/restore + Escape-dismiss
-- | (always modal, NO close-on-outside-click) can be verified.
module Gallery.Story.AlertDialog (story) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.AlertDialog as AlertDialog
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "alert-dialog", component }

type Slots = (alertDialog :: AlertDialog.Slot Unit)

_alertDialog :: Proxy "alertDialog"
_alertDialog = Proxy

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
    [ HH.slot_ _alertDialog unit AlertDialog.component input ]
  where
  input = AlertDialog.defaultInput
    { trigger = [ HH.text "Delete account" ]
    , title = [ HH.text "Are you absolutely sure?" ]
    , description = [ HH.text "This action cannot be undone. This will permanently delete your account." ]
    , content = [ HH.text "Cancel / Confirm actions go here." ]
    , style = AlertDialog.defaultStyle { content = cn "alert-dialog-content" }
    }
