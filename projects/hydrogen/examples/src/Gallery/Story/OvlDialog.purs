-- | Overlay open-state invariance template (STR-383, fork #2): the SAME Dialog rendered
-- | under four presets, ONE per page (story ids ovl-dialog-<preset>), so the open overlay's
-- | body-portaled content is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, drives it open via the shared themes-states
-- | `dialog` driver, snapshots the whole body, and asserts the open behavioral DOM is
-- | byte-identical across all four presets (only class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlDialog (stories, ids) where

import Prelude

import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (dialog :: Dialog.Slot Unit)

_dialog :: Proxy "dialog"
_dialog = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-BaseDialogOverlay rt-DialogOverlay", b: "rt-BaseDialogContent rt-DialogContent" }
  , { name: "shadcn", a: "fixed inset-0 z-50 bg-black/80", b: "fixed left-1/2 top-1/2 z-50 grid w-full max-w-lg gap-4 border bg-background p-6 shadow-lg" }
  , { name: "daisy", a: "modal modal-open", b: "modal-box" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-dialog-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-dialog-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-dialog-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _dialog unit Dialog.component (input s) ]

  input s = Dialog.defaultInput
    { trigger = [ HH.text "Open" ]
    , title = [ HH.text "Dialog title" ]
    , description = [ HH.text "Dialog description." ]
    , content = [ HH.text "Body content" ]
    , style = Dialog.defaultStyle
        { trigger = cn s.a
        , overlay = cn s.a
        , scroll = cn s.b
        , scrollPadding = cn s.b
        , content = cn s.a
        , title = cn s.b
        , description = cn s.a
        }
    }
