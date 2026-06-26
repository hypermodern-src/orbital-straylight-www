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
import Data.Tuple (Tuple(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))

import Hydrogen.Radix.Accordion as Accordion
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..), cn)
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.Toggle as Toggle
import Hydrogen.Radix.Tooltip as Tooltip
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.TextArea (textArea)
import Hydrogen.Themes.TextField (textFieldValue)
import Hydrogen.Themes.Typography (textAs)

-- | The component ids this module renders live (a Storybook story id that resolves to a
-- | live primitive rather than a static Themes render). Kept disjoint from the existing
-- | `Themes/` display-component story ids so those stories + baselines are untouched.
ids :: Array String
ids = [ "toggle", "accordion", "dialog", "popover", "tooltip" ]

type Slots =
  ( toggle :: Toggle.Slot Unit
  , accordion :: Accordion.Slot Unit
  , dialog :: Dialog.Slot Unit
  , popover :: Popover.Slot Unit
  , tooltip :: Tooltip.Slot Unit
  )

_toggle :: Proxy "toggle"
_toggle = Proxy

_accordion :: Proxy "accordion"
_accordion = Proxy

_dialog :: Proxy "dialog"
_dialog = Proxy

_popover :: Proxy "popover"
_popover = Proxy

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

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
  "dialog" -> HH.slot_ _dialog unit Dialog.component dialogInput
  "popover" -> HH.slot_ _popover unit Popover.component popoverInput
  "tooltip" -> HH.slot_ _tooltip unit Tooltip.component tooltipInput
  _ -> HH.text ""

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared themed helpers (mirrored from the verification harness)
-- ─────────────────────────────────────────────────────────────────────────────

-- | The theme `data-*` attrs a preset stamps on a portaled overlay so the adopted-to-body
-- | content stays themed (the portal variant: is-root-theme / has-background both false).
portalThemeAttrs :: Array (Tuple String String)
portalThemeAttrs =
  [ Tuple "accent-color" "indigo"
  , Tuple "gray-color" "slate"
  , Tuple "has-background" "false"
  , Tuple "is-root-theme" "false"
  , Tuple "panel-background" "translucent"
  , Tuple "radius" "medium"
  , Tuple "scaling" "100%"
  ]

-- | The `--radix-<c>-content-*` / `--radix-<c>-trigger-*` aliases radix writes inline on a
-- | floating content, aliasing the wrapper's `--radix-popper-*` vars.
popperContentVars :: String -> String
popperContentVars c =
  "--radix-" <> c <> "-content-transform-origin: var(--radix-popper-transform-origin); "
    <> "--radix-" <> c <> "-content-available-width: var(--radix-popper-available-width); "
    <> "--radix-" <> c <> "-content-available-height: var(--radix-popper-available-height); "
    <> "--radix-" <> c <> "-trigger-width: var(--radix-popper-anchor-width); "
    <> "--radix-" <> c <> "-trigger-height: var(--radix-popper-anchor-height);"

svgNS :: HH.Namespace
svgNS = HH.Namespace "http://www.w3.org/2000/svg"

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

dialogInput :: Dialog.Input
dialogInput = Dialog.defaultInput
  { style = dialogStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 450px;"
  , closeLabels = [ "Cancel", "Save" ]
  , trigger = [ HH.text "Edit profile" ]
  , title = [ HH.text "Edit profile" ]
  , description = [ HH.text "Make changes to your profile." ]
  , content =
      [ flex [ Direction "column", Gap "3" ]
          [ HH.label_
              [ textAs "div" [ Size "2", Mb "1", Weight "bold" ] [ HH.text "Name" ]
              , textFieldValue "Enter your full name" "Freja Johnsen" []
              ]
          ]
      , flex [ Gap "3", Mt "4", Justify "end" ]
          [ button [ Variant "soft", Color "gray" ] [ HH.text "Cancel" ]
          , button [] [ HH.text "Save" ]
          ]
      ]
  }

dialogStyle :: Dialog.Style
dialogStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-solid"
  , overlay: cn "light radix-themes rt-BaseDialogOverlay rt-DialogOverlay"
  , scroll: cn "rt-BaseDialogScroll rt-DialogScroll"
  , scrollPadding: cn "rt-BaseDialogScrollPadding rt-DialogScrollPadding rt-r-align-center"
  , content: cn "rt-BaseDialogContent rt-DialogContent rt-r-max-w rt-r-size-3"
  , title: cn "rt-Heading rt-r-lt-start rt-r-size-5 rt-r-mb-3"
  , description: cn "rt-Text rt-r-size-2 rt-r-mb-4"
  }

popoverInput :: Popover.Input
popoverInput = Popover.defaultInput
  { align = Start
  , style = popoverStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--width: 360px; --max-width: 9999px; " <> popperContentVars "popover"
  , trigger = [ HH.text "Comment" ]
  , content =
      [ flex [ Gap "3" ]
          [ box [ Class "rt-r-fg-1" ]
              [ textArea "Write a comment…" [ Height "80px" ] ]
          ]
      ]
  }

popoverStyle :: Popover.Style
popoverStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "light radix-themes rt-PopoverContent rt-PopperContent rt-r-max-w rt-r-size-2 rt-r-w"
  }

tooltipInput :: Tooltip.Input
tooltipInput = Tooltip.defaultInput
  { style = tooltipStyle
  , offset = 8.0
  , padding = 10.0
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 9999px; " <> popperContentVars "tooltip"
  , trigger = [ HH.text "Hover me" ]
  , content = [ textAs "p" [ Size "1", Class "rt-TooltipText" ] [ HH.text "Add to library" ] ]
  , arrow = [ tooltipArrow ]
  }

tooltipStyle :: Tooltip.Style
tooltipStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "light radix-themes rt-TooltipContent rt-r-max-w"
  }

-- | The themed tooltip arrow (rt-TooltipArrow) — a 10×5 triangle the primitive rotates.
tooltipArrow :: forall w i. HH.HTML w i
tooltipArrow =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") "rt-TooltipArrow"
    , HP.attr (HH.AttrName "width") "10"
    , HP.attr (HH.AttrName "height") "5"
    , HP.attr (HH.AttrName "viewBox") "0 0 30 10"
    , HP.attr (HH.AttrName "preserveAspectRatio") "none"
    , HP.attr (HH.AttrName "style") "display: block;"
    ]
    [ HH.elementNS svgNS (HH.ElemName "polygon")
        [ HP.attr (HH.AttrName "points") "0,0 30,0 15,10" ]
        []
    ]
