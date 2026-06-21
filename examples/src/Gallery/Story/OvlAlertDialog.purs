-- | Overlay open-state invariance template (STR-383, fork #2): the SAME AlertDialog rendered
-- | under four presets, ONE per page (story ids ovl-alertdialog-<preset>), so the open overlay's
-- | body-portaled content is unambiguous — no portal-pairing needed. The invariance gate
-- | (invariance.mjs --overlay) loads each page, drives it open, waits for the literal OVLOPEN
-- | text, snapshots the whole body, and asserts the open behavioral DOM is byte-identical across
-- | all four presets (only class/style differ).
-- |
-- | Exports `stories` (4) rather than a single `story`; NOT pixel stories.
module Gallery.Story.OvlAlertDialog (stories, ids) where

import Prelude

import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.AlertDialog as AlertDialog
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))

type Slots = (alertDialog :: AlertDialog.Slot Unit)

_alertDialog :: Proxy "alertDialog"
_alertDialog = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-BaseDialogOverlay rt-AlertDialogOverlay", b: "rt-BaseDialogContent rt-AlertDialogContent" }
  , { name: "shadcn", a: "fixed inset-0 z-50 bg-black/80", b: "fixed left-1/2 top-1/2 z-50 grid w-full max-w-lg gap-4 border bg-background p-6 shadow-lg" }
  , { name: "daisy", a: "modal modal-open", b: "modal-box" }
  ]

-- | The 4 story ids the overlay gate drives (ovl-alertdialog-unstyled … -daisy).
ids :: Array String
ids = map (\s -> "ovl-alertdialog-" <> s.name) skins

stories :: Array Story
stories = map mk skins
  where
  mk s = { id: "ovl-alertdialog-" <> s.name, component: comp s }

  comp :: Skin -> StoryComponent
  comp s = H.mkComponent
    { initialState: const unit
    , render: const (view s)
    , eval: H.mkEval H.defaultEval
    }

  view :: Skin -> H.ComponentHTML Void Slots Aff
  view s =
    HH.div [ HP.style "display:contents" ]
      [ HH.slot_ _alertDialog unit AlertDialog.component (input s) ]

  input s = AlertDialog.defaultInput
    { trigger = [ HH.text "Delete account" ]
    , title = [ HH.text "Are you absolutely sure?" ]
    , description = [ HH.text "This action cannot be undone." ]
    , content = [ HH.text "OVLOPEN" ]
    , style = AlertDialog.defaultStyle
        { trigger = cn s.a
        , overlay = cn s.a
        , scroll = cn s.b
        , scrollPadding = cn s.b
        , content = cn s.a
        , title = cn s.b
        , description = cn s.a
        }
    }
