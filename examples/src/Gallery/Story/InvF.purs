-- | Behavioral-invariance subjects (STR-383) for the two "heavy" non-overlay primitives:
-- | Form and NavigationMenu. Each rendered under four presets (unstyled/themes/shadcn/daisy)
-- | that differ ONLY in Style class lists; the invariance gate proves the behavioral DOM
-- | (role/aria-*/data-*/form-semantics) is byte-identical across all four.
-- |
-- | NavigationMenu is rendered CLOSED at rest (defaultValue="") — a deterministic snapshot
-- | (no viewport measurement / ResizeObserver timing). NOT a pixel story.
module Gallery.Story.InvF (story) where

import Prelude

import Data.Array (mapWithIndex)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Form as Form
import Hydrogen.Radix.NavigationMenu as NavigationMenu
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-f", component }

type Slots =
  ( form :: Form.Slot Int
  , nav :: NavigationMenu.Slot Int
  )

_form :: Proxy "form"
_form = Proxy

_nav :: Proxy "nav"
_nav = Proxy

type Skin = { name :: String, a :: String, b :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "" }
  , { name: "themes", a: "rt-reset rt-BaseForm", b: "rt-FormField" }
  , { name: "shadcn", a: "space-y-2 rounded-md border", b: "flex h-10 w-full px-3 py-2 text-sm" }
  , { name: "daisy", a: "form-control", b: "input input-bordered" }
  ]

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
    [ group "Form" (mapWithIndex formCell skins)
    , group "NavigationMenu" (mapWithIndex navCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids
  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  -- Same single required-email field + submit across all skins; only class lists vary.
  formCell i s = preset s $
    HH.slot_ _form i Form.component
      (Form.defaultInput
        { fields =
            [ Form.defaultField
                { name = "email"
                , label = [ HH.text "Email" ]
                , inputType = "email"
                , required = true
                }
            ]
        , submitLabel = [ HH.text "Submit" ]
        , style =
            { root: cn s.a, field: cn s.a, label: cn s.b
            , control: cn s.b, message: cn s.a, submit: cn s.b
            }
        })

  -- Same two closed menus across all skins (defaultValue="" → closed at rest); only classes vary.
  navCell i s = preset s $
    HH.slot_ _nav i NavigationMenu.component
      (NavigationMenu.defaultInput
        { items =
            [ { value: "one", trigger: [ HH.text "Item One" ]
              , links: [ { href: "#a", label: [ HH.text "Link A" ], active: false } ] }
            , { value: "two", trigger: [ HH.text "Item Two" ]
              , links: [ { href: "#b", label: [ HH.text "Link B" ], active: false } ] }
            ]
        , defaultValue = ""
        , idPrefix = "navinv"
        , style =
            { root: cn s.a, list: cn s.b, item: cn s.a, trigger: cn s.b
            , content: cn s.a, link: cn s.b, indicator: cn s.a, viewport: cn s.b
            }
        })
