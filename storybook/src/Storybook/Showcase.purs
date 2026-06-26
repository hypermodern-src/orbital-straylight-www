-- | Storybook.Showcase — live, themed demos of the stateful `Hydrogen.Radix.*`
-- | primitives for Storybook.
-- |
-- | The display `Hydrogen.Themes.*` components are plain render functions, so the
-- | Storybook `Mount` renders them as static HTML. The INTERACTIVE primitives, by
-- | contrast, are full Halogen `H.Component`s (state / queries / slots / timers), so
-- | they must be mounted as live child components. This module is the slot-host: one
-- | component, keyed by a string id, that slots the requested primitive with a themed,
-- | happy-path `Input` (the rt-* `Style` records over the primitive, exactly as the
-- | verification harness drives them). The Storybook preview decorator supplies the
-- | `.radix-themes` root + `themes.css`, so a demo renders themed.
-- |
-- | Coverage grows one batch at a time; `ids` lists what is wired so `Mount` can route.
module Storybook.Showcase
  ( component
  , ids
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))

import Hydrogen.Radix.Accordion as Accordion
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Toggle as Toggle

-- | The component ids this module renders live (a Storybook story id that resolves to a
-- | live primitive rather than a static Themes render). Kept disjoint from the existing
-- | `Themes/` display-component story ids so those stories + baselines are untouched.
ids :: Array String
ids = [ "toggle", "accordion" ]

type Slots =
  ( toggle :: Toggle.Slot Unit
  , accordion :: Accordion.Slot Unit
  )

_toggle :: Proxy "toggle"
_toggle = Proxy

_accordion :: Proxy "accordion"
_accordion = Proxy

-- | The slot-host: render the primitive named by the input id, or nothing for an
-- | unknown id (Mount only routes ids in `ids`).
component :: forall q o m. MonadAff m => H.Component q String o m
component =
  H.mkComponent
    { initialState: identity
    , render
    , eval: H.mkEval H.defaultEval
    }

render :: forall m. MonadAff m => String -> H.ComponentHTML Unit Slots m
render cid = case cid of
  "toggle" -> HH.slot_ _toggle unit Toggle.component toggleInput
  "accordion" ->
    HH.div [ HP.style "max-width: 360px;" ]
      [ HH.slot_ _accordion unit Accordion.component accordionInput ]
  _ -> HH.text ""

-- ─────────────────────────────────────────────────────────────────────────────
-- Showcase inputs — the happy-path themed instance of each primitive.
-- ─────────────────────────────────────────────────────────────────────────────

toggleInput :: Toggle.Input
toggleInput = Toggle.defaultInput
  { ariaLabel = Just "Bold"
  , style = { root: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft" }
  , children = [ HH.text "B" ]
  }

accordionInput :: Accordion.Input
accordionInput = Accordion.defaultInput
  { items =
      [ { value: "item-1", header: [ HH.text "Is it accessible?" ], content: [ HH.text "Yes. It adheres to the WAI-ARIA design pattern." ], disabled: false }
      , { value: "item-2", header: [ HH.text "Is it styled?" ], content: [ HH.text "No. It is unstyled by default." ], disabled: false }
      , { value: "item-3", header: [ HH.text "Is it animated?" ], content: [ HH.text "Yes, with CSS." ], disabled: false }
      ]
  , style =
      { root: cn ""
      , item: cn ""
      , header: cn ""
      , trigger: cn ""
      , content: cn ""
      }
  }
