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

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))

import Hydrogen.Radix.Accordion as Accordion
import Hydrogen.Radix.AlertDialog as AlertDialog
import Hydrogen.Radix.Collapsible as Collapsible
import Hydrogen.Radix.ContextMenu as ContextMenu
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.DropdownMenu as DropdownMenu
import Hydrogen.Radix.Foundation.Style (Align(..), Orientation(..), Side(..), cn)
import Hydrogen.Radix.Toolbar as Toolbar
import Hydrogen.Radix.HoverCard as HoverCard
import Hydrogen.Radix.Menubar as Menubar
import Hydrogen.Radix.NavigationMenu as NavigationMenu
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.ScrollArea as ScrollArea
import Hydrogen.Radix.Select as Select
import Hydrogen.Radix.Toast as Toast
import Hydrogen.Radix.Toggle as Toggle
import Hydrogen.Radix.ToggleGroup as ToggleGroup
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
ids =
  [ "toggle", "accordion", "dialog", "popover", "tooltip", "hovercard", "navigationmenu"
  , "dropdownmenu", "contextmenu", "menubar", "select", "scrollarea", "collapsible", "toast", "togglegroup"
  , "alertdialog", "toolbar"
  ]

type Slots =
  ( toggle :: Toggle.Slot Unit
  , accordion :: Accordion.Slot Unit
  , alertdialog :: AlertDialog.Slot Unit
  , toolbar :: Toolbar.Slot Unit
  , dialog :: Dialog.Slot Unit
  , popover :: Popover.Slot Unit
  , tooltip :: Tooltip.Slot Unit
  , hovercard :: HoverCard.Slot Unit
  , navigationmenu :: NavigationMenu.Slot Unit
  , dropdownmenu :: DropdownMenu.Slot Unit
  , contextmenu :: ContextMenu.Slot Unit
  , menubar :: Menubar.Slot Unit
  , select :: Select.Slot Unit
  , scrollarea :: ScrollArea.Slot Unit
  , collapsible :: Collapsible.Slot Unit
  , toast :: Toast.Slot Unit
  , togglegroup :: ToggleGroup.Slot Unit
  )

_toggle :: Proxy "toggle"
_toggle = Proxy

_accordion :: Proxy "accordion"
_accordion = Proxy

_alertdialog :: Proxy "alertdialog"
_alertdialog = Proxy

_toolbar :: Proxy "toolbar"
_toolbar = Proxy

_dialog :: Proxy "dialog"
_dialog = Proxy

_popover :: Proxy "popover"
_popover = Proxy

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

_hovercard :: Proxy "hovercard"
_hovercard = Proxy

_navigationmenu :: Proxy "navigationmenu"
_navigationmenu = Proxy

_dropdownmenu :: Proxy "dropdownmenu"
_dropdownmenu = Proxy

_contextmenu :: Proxy "contextmenu"
_contextmenu = Proxy

_menubar :: Proxy "menubar"
_menubar = Proxy

_select :: Proxy "select"
_select = Proxy

_scrollarea :: Proxy "scrollarea"
_scrollarea = Proxy

_collapsible :: Proxy "collapsible"
_collapsible = Proxy

_toast :: Proxy "toast"
_toast = Proxy

_togglegroup :: Proxy "togglegroup"
_togglegroup = Proxy

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
  "hovercard" -> HH.slot_ _hovercard unit HoverCard.component hoverCardInput
  "navigationmenu" -> HH.slot_ _navigationmenu unit NavigationMenu.component navigationMenuInput
  "dropdownmenu" -> HH.slot_ _dropdownmenu unit DropdownMenu.component dropdownMenuInput
  "contextmenu" -> HH.slot_ _contextmenu unit ContextMenu.component contextMenuInput
  "menubar" -> HH.slot_ _menubar unit Menubar.component menubarInput
  "select" -> HH.slot_ _select unit Select.component selectInput
  "scrollarea" -> HH.slot_ _scrollarea unit ScrollArea.component scrollAreaInput
  "collapsible" -> HH.slot_ _collapsible unit Collapsible.component collapsibleInput
  "toast" -> HH.slot_ _toast unit Toast.component toastInput
  "togglegroup" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupInput
  "alertdialog" -> HH.slot_ _alertdialog unit AlertDialog.component alertDialogInput
  "toolbar" -> HH.slot_ _toolbar unit Toolbar.component toolbarInput
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

hoverCardInput :: HoverCard.Input
hoverCardInput = HoverCard.defaultInput
  { align = Start
  -- Radix Themes' HoverCard pins openDelay=200/closeDelay=150 (not the bare 700/300).
  , openDelay = 200
  , closeDelay = 150
  , style = hoverCardStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 9999px; " <> popperContentVars "hover-card"
  , wrapperClass = cn "rt-Text"
  , proseBefore = [ HH.text "Follow " ]
  , proseAfter = [ HH.text " for updates." ]
  , trigger = [ HH.text "@radix_ui" ]
  , content =
      [ textAs "div" [ Size "1", Color "gray" ]
          [ HH.text "The design system for building modern web applications." ]
      ]
  }

hoverCardStyle :: HoverCard.Style
hoverCardStyle =
  { trigger: cn "rt-reset rt-Text rt-Link rt-HoverCardTrigger rt-underline-auto"
  , content: cn "light radix-themes rt-HoverCardContent rt-PopperContent rt-r-max-w rt-r-size-2"
  }

navigationMenuInput :: NavigationMenu.Input
navigationMenuInput = NavigationMenu.defaultInput
  { items =
      [ { value: "overview"
        , trigger: [ HH.text "Overview" ]
        , links:
            [ { href: "#intro", label: [ HH.text "Introduction" ], active: false }
            , { href: "#start", label: [ HH.text "Getting started" ], active: false }
            ]
        }
      , { value: "components"
        , trigger: [ HH.text "Components" ]
        , links:
            [ { href: "#primitives", label: [ HH.text "Primitives" ], active: false }
            , { href: "#themes", label: [ HH.text "Themes" ], active: false }
            ]
        }
      ]
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Menu chrome (shared by DropdownMenu / ContextMenu / Menubar / Select)
-- ─────────────────────────────────────────────────────────────────────────────

-- | The down-chevron (radix TriggerIcon / SelectIcon). Bare = menu trigger icon; classed
-- | (aria-hidden) = the SelectIcon.
chevron :: forall w i. HH.HTML w i
chevron = chevronCls ""

chevronCls :: forall w i. String -> HH.HTML w i
chevronCls klass =
  HH.elementNS svgNS (HH.ElemName "svg")
    ( (if klass == "" then [] else [ HP.attr (HH.AttrName "class") klass, HP.attr (HH.AttrName "aria-hidden") "true" ])
        <>
          [ HP.attr (HH.AttrName "width") "9"
          , HP.attr (HH.AttrName "height") "9"
          , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
          , HP.attr (HH.AttrName "fill") "currentcolor"
          , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
          ]
    )
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "d") "M0.135232 3.15803C0.324102 2.95657 0.640521 2.94637 0.841971 3.13523L4.5 6.56464L8.158 3.13523C8.3595 2.94637 8.6759 2.95657 8.8648 3.15803C9.0536 3.35949 9.0434 3.67591 8.842 3.86477L4.84197 7.6148C4.64964 7.7951 4.35036 7.7951 4.15803 7.6148L0.158031 3.86477C-0.0434285 3.67591 -0.0536285 3.35949 0.135232 3.15803Z" ]
        []
    ]

-- | The selected-option check (radix ThickCheckIcon).
checkSvg :: forall w i. HH.HTML w i
checkSvg =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") "rt-SelectItemIndicatorIcon"
    , HP.attr (HH.AttrName "width") "9"
    , HP.attr (HH.AttrName "height") "9"
    , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
    , HP.attr (HH.AttrName "fill") "currentcolor"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "fill-rule") "evenodd"
        , HP.attr (HH.AttrName "clip-rule") "evenodd"
        , HP.attr (HH.AttrName "d") "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z" ]
        []
    ]

-- | The SubTrigger chevron (right caret) with a caller-supplied icon class.
subTriggerChevron :: String -> HH.PlainHTML
subTriggerChevron iconClass =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") iconClass
    , HP.attr (HH.AttrName "width") "9"
    , HP.attr (HH.AttrName "height") "9"
    , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
    , HP.attr (HH.AttrName "fill") "currentcolor"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "d") "M3.23826 0.201711C3.54108 -0.0809141 4.01567 -0.0645489 4.29829 0.238264L7.79829 3.98826C8.06724 4.27642 8.06724 4.72359 7.79829 5.01174L4.29829 8.76174C4.01567 9.06455 3.54108 9.08092 3.23826 8.79829C2.93545 8.51567 2.91909 8.04108 3.20171 7.73826L6.22409 4.5L3.20171 1.26174C2.91909 0.958928 2.93545 0.484337 3.23826 0.201711Z"
        , HP.attr (HH.AttrName "fill-rule") "evenodd"
        , HP.attr (HH.AttrName "clip-rule") "evenodd"
        ]
        []
    ]

-- | The ItemIndicator (check) icon with a caller-supplied class.
menuIndicatorIcon :: String -> HH.PlainHTML
menuIndicatorIcon iconClass =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") iconClass
    , HP.attr (HH.AttrName "width") "9"
    , HP.attr (HH.AttrName "height") "9"
    , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
    , HP.attr (HH.AttrName "fill") "currentcolor"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "fill-rule") "evenodd"
        , HP.attr (HH.AttrName "clip-rule") "evenodd"
        , HP.attr (HH.AttrName "d") "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z" ]
        []
    ]

-- ─────────────────────────────────────────────────────────────────────────────
-- DropdownMenu
-- ─────────────────────────────────────────────────────────────────────────────

menuRow :: String -> String -> String -> String -> Boolean -> DropdownMenu.MenuEntry
menuRow value label shortcut accent disabled =
  DropdownMenu.MenuItemEntry
    { value, label: [ HH.text label ], shortcut: [ HH.text shortcut ], accent, disabled }

dropdownMenuInput :: DropdownMenu.Input
dropdownMenuInput = DropdownMenu.defaultInput
  { style = menuStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "dropdown-menu" <> " pointer-events: auto;"
  , subContentStyle = "outline: none; pointer-events: auto; " <> popperContentVars "dropdown-menu"
  , trigger = [ HH.text "Options", chevron ]
  , entries =
      [ menuRow "edit" "Edit" "⌘ E" "" false
      , menuRow "duplicate" "Duplicate" "⌘ D" "" false
      , DropdownMenu.menuSeparator
      , menuRow "archive" "Archive" "⌘ N" "" false
      , DropdownMenu.menuSeparator
      , menuRow "delete" "Delete" "⌘ ⌫" "red" false
      ]
  }

menuStyle :: DropdownMenu.Style
menuStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "light radix-themes rt-BaseMenuContent rt-DropdownMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , subTrigger: cn "rt-BaseMenuItem rt-BaseMenuSubTrigger rt-DropdownMenuItem rt-DropdownMenuSubTrigger"
  , subContent: cn "light radix-themes rt-BaseMenuContent rt-BaseMenuSubContent rt-DropdownMenuContent rt-DropdownMenuSubContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , subContentColor: "indigo"
  , subIcon: [ subTriggerChevron "rt-BaseMenuSubTriggerIcon rt-DropdownMenuSubtriggerIcon" ]
  , scrollRoot: cn "rt-ScrollAreaRoot"
  , scrollViewport: cn "rt-ScrollAreaViewport"
  , menuViewport: cn "rt-BaseMenuViewport rt-DropdownMenuViewport"
  , focusRing: cn "rt-ScrollAreaViewportFocusRing"
  , item: cn "rt-BaseMenuItem rt-DropdownMenuItem rt-reset"
  , shortcut: cn "rt-BaseMenuShortcut rt-DropdownMenuShortcut"
  , separator: cn "rt-BaseMenuSeparator rt-DropdownMenuSeparator"
  , checkboxItem: cn "rt-BaseMenuCheckboxItem rt-BaseMenuItem rt-DropdownMenuCheckboxItem rt-DropdownMenuItem"
  , radioGroup: cn "rt-BaseMenuRadioGroup rt-DropdownMenuRadioGroup"
  , radioItem: cn "rt-BaseMenuItem rt-BaseMenuRadioItem rt-DropdownMenuItem rt-DropdownMenuRadioItem"
  , indicator: cn "rt-BaseMenuItemIndicator rt-DropdownMenuItemIndicator"
  , group: cn "rt-BaseMenuGroup rt-DropdownMenuGroup"
  , groupLabel: cn "rt-BaseMenuLabel rt-DropdownMenuLabel"
  , checkIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-ContextMenuItemIndicatorIcon" ]
  , radioIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-DropdownMenuItemIndicatorIcon" ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- ContextMenu
-- ─────────────────────────────────────────────────────────────────────────────

ctxRow :: String -> String -> String -> String -> Boolean -> ContextMenu.MenuEntry
ctxRow value label shortcut accent disabled =
  ContextMenu.MenuItemEntry
    { value, label: [ HH.text label ], shortcut: [ HH.text shortcut ], accent, disabled }

contextMenuInput :: ContextMenu.Input
contextMenuInput = ContextMenu.defaultInput
  { side = Right
  , style = contextMenuStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "context-menu" <> " pointer-events: auto;"
  , subContentStyle = "outline: none; pointer-events: auto; " <> popperContentVars "context-menu"
  , triggerStyle = "width: 240px; height: 120px; border: 1px dashed var(--gray-6); border-radius: var(--radius-3);"
  , trigger = [ textAs "span" [ Size "2", Color "gray" ] [ HH.text "Right-click here" ] ]
  , entries =
      [ ctxRow "edit" "Edit" "⌘ E" "" false
      , ctxRow "duplicate" "Duplicate" "⌘ D" "" false
      , ContextMenu.menuSeparator
      , ctxRow "delete" "Delete" "⌘ ⌫" "red" false
      ]
  }

contextMenuStyle :: ContextMenu.Style
contextMenuStyle =
  { trigger: cn "rt-Flex rt-r-ai-center rt-r-jc-center"
  , content: cn "light radix-themes rt-BaseMenuContent rt-ContextMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , scrollRoot: cn "rt-ScrollAreaRoot"
  , scrollViewport: cn "rt-ScrollAreaViewport"
  , menuViewport: cn "rt-BaseMenuViewport rt-ContextMenuViewport"
  , focusRing: cn "rt-ScrollAreaViewportFocusRing"
  , item: cn "rt-BaseMenuItem rt-ContextMenuItem rt-reset"
  , shortcut: cn "rt-BaseMenuShortcut rt-ContextMenuShortcut"
  , separator: cn "rt-BaseMenuSeparator rt-ContextMenuSeparator"
  , checkboxItem: cn "rt-BaseMenuCheckboxItem rt-BaseMenuItem rt-ContextMenuCheckboxItem rt-ContextMenuItem"
  , radioGroup: cn "rt-BaseMenuRadioGroup rt-ContextMenuRadioGroup"
  , radioItem: cn "rt-BaseMenuItem rt-BaseMenuRadioItem rt-ContextMenuItem rt-ContextMenuRadioItem"
  , indicator: cn "rt-BaseMenuItemIndicator rt-ContextMenuItemIndicator"
  , checkIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-ContextMenuItemIndicatorIcon" ]
  , radioIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-ContextMenuItemIndicatorIcon" ]
  , subTrigger: cn "rt-BaseMenuItem rt-BaseMenuSubTrigger rt-ContextMenuItem rt-ContextMenuSubTrigger"
  , subContent: cn "light radix-themes rt-BaseMenuContent rt-BaseMenuSubContent rt-ContextMenuContent rt-ContextMenuSubContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , subContentColor: "indigo"
  , subIcon: [ subTriggerChevron "rt-BaseMenuSubTriggerIcon rt-ContextMenuSubTriggerIcon" ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Menubar (bare @radix-ui primitive — no rt-* chrome)
-- ─────────────────────────────────────────────────────────────────────────────

menubarInput :: Menubar.Input
menubarInput = Menubar.defaultInput
  { align = Start
  , contentStyle = "outline: none; " <> popperContentVars "menubar"
  , menus =
      [ { value: "file"
        , trigger: [ HH.text "File" ]
        , disabled: false
        , entries:
            [ Menubar.menuItem "new-tab" [ HH.text "New Tab" ]
            , Menubar.menuItem "new-window" [ HH.text "New Window" ]
            , Menubar.menuSeparator
            , Menubar.menuItem "print" [ HH.text "Print" ]
            ]
        }
      , { value: "edit"
        , trigger: [ HH.text "Edit" ]
        , disabled: false
        , entries: [ Menubar.menuItem "undo" [ HH.text "Undo" ], Menubar.menuItem "redo" [ HH.text "Redo" ] ]
        }
      , { value: "view"
        , trigger: [ HH.text "View" ]
        , disabled: false
        , entries: [ Menubar.menuItem "zoom-in" [ HH.text "Zoom In" ], Menubar.menuItem "zoom-out" [ HH.text "Zoom Out" ] ]
        }
      ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Select
-- ─────────────────────────────────────────────────────────────────────────────

selectInput :: Select.Input
selectInput = Select.defaultInput
  { defaultValue = "apple"
  , style = selectStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "box-sizing: border-box; max-height: 100%; display: flex; flex-direction: column; outline: none; pointer-events: auto;"
  , trigger = [ chevronCls "rt-SelectIcon" ]
  , groupLabel = [ HH.text "Fruits" ]
  , checkIcon = [ checkSvg ]
  , items =
      [ { value: "apple", label: [ HH.text "Apple" ], disabled: false }
      , { value: "orange", label: [ HH.text "Orange" ], disabled: false }
      , { value: "grape", label: [ HH.text "Grape" ], disabled: false }
      ]
  }

selectStyle :: Select.Style
selectStyle =
  { trigger: cn "rt-reset rt-SelectTrigger rt-r-size-2 rt-variant-surface"
  , value: cn "rt-SelectTriggerInner"
  , content: cn "light radix-themes rt-SelectContent rt-r-size-2 rt-variant-solid"
  , scrollRoot: cn "rt-ScrollAreaRoot"
  , scrollViewport: cn "rt-ScrollAreaViewport rt-SelectViewport"
  , group: cn "rt-SelectGroup"
  , label: cn "rt-SelectLabel"
  , item: cn "rt-SelectItem"
  , indicator: cn "rt-SelectItemIndicator"
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- ScrollArea
-- ─────────────────────────────────────────────────────────────────────────────

scrollAreaInput :: ScrollArea.Input
scrollAreaInput = ScrollArea.defaultInput
  { widthPx = 200
  , heightPx = 120
  , style =
      { root: cn "rt-ScrollAreaRoot"
      , viewport: cn "rt-ScrollAreaViewport"
      , focusRing: cn "rt-ScrollAreaViewportFocusRing"
      , scrollbar: cn "rt-ScrollAreaScrollbar rt-r-size-1"
      , thumb: cn "rt-ScrollAreaThumb"
      , corner: cn "rt-ScrollAreaCorner"
      }
  , content =
      [ box [ P "2", Width "160px" ]
          ( map (\n -> textAs "p" [ Size "2" ] [ HH.text "Line ", HH.text (show n) ]) (Array.range 1 12) )
      ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Collapsible
-- ─────────────────────────────────────────────────────────────────────────────

collapsibleInput :: Collapsible.Input
collapsibleInput = Collapsible.defaultInput
  { defaultOpen = false
  , style =
      { root: cn ""
      , trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
      , content: cn ""
      }
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , trigger = [ HH.text "Toggle content" ]
  , content = [ box [ Pt "2" ] [ textAs "div" [ Size "2" ] [ HH.text "Disclosed content line one." ] ] ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Toast (bare @radix-ui primitive — open at first paint)
-- ─────────────────────────────────────────────────────────────────────────────

toastInput :: Toast.Input
toastInput = Toast.defaultInput
  { open = Nothing
  , defaultOpen = true
  , duration = Nothing
  , label = "Notifications (F8)"
  , swipeDirection = "right"
  , announceLabel = "Notification"
  , announceText = "Notification ScheduledFriday at 5pmUndo"
  , altText = "Undo"
  , closeLabel = "Close"
  , style =
      { viewport: cn ""
      , wrapper: cn ""
      , root: cn ""
      , title: cn ""
      , description: cn ""
      , action: cn ""
      , close: cn ""
      }
  , title = [ HH.text "Scheduled" ]
  , description = [ HH.text "Friday at 5pm" ]
  , action = [ HH.text "Undo" ]
  , close = [ HH.text "×" ]
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- ToggleGroup (bare @radix-ui primitive — single-select, Center pressed)
-- ─────────────────────────────────────────────────────────────────────────────

toggleGroupInput :: ToggleGroup.Input
toggleGroupInput = ToggleGroup.defaultInput
  { single = true
  , defaultValue = [ "b" ]
  , ariaLabel = Just "Text alignment"
  , items =
      [ { value: "a", label: [ HH.text "Left" ], disabled: false }
      , { value: "b", label: [ HH.text "Center" ], disabled: false }
      , { value: "c", label: [ HH.text "Right" ], disabled: false }
      ]
  , style = { root: cn "", item: cn "" }
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- AlertDialog
-- ─────────────────────────────────────────────────────────────────────────────

alertDialogInput :: AlertDialog.Input
alertDialogInput = AlertDialog.defaultInput
  { style = alertDialogStyle
  , triggerAttrs = [ Tuple "accent-color" "red" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 450px; pointer-events: auto;"
  , closeLabels = [ "Cancel", "Revoke access" ]
  , trigger = [ HH.text "Revoke access" ]
  , title = [ HH.text "Revoke access" ]
  , description = [ HH.text "Are you sure? This application will no longer be accessible." ]
  , content =
      [ flex [ Gap "3", Mt "4", Justify "end" ]
          [ button [ Variant "soft", Color "gray" ] [ HH.text "Cancel" ]
          , button [ Color "red" ] [ HH.text "Revoke access" ]
          ]
      ]
  }

alertDialogStyle :: AlertDialog.Style
alertDialogStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-solid"
  , overlay: cn "light radix-themes rt-BaseDialogOverlay rt-AlertDialogOverlay"
  , scroll: cn "rt-BaseDialogScroll rt-AlertDialogScroll"
  , scrollPadding: cn "rt-BaseDialogScrollPadding rt-AlertDialogScrollPadding rt-r-align-center"
  , content: cn "rt-BaseDialogContent rt-AlertDialogContent rt-r-max-w rt-r-size-3"
  , title: cn "rt-Heading rt-r-lt-start rt-r-mb-3 rt-r-size-5"
  , description: cn "rt-Text rt-r-size-2"
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Toolbar (bare @radix-ui primitive — a roving formatting bar)
-- ─────────────────────────────────────────────────────────────────────────────

toolbarInput :: Toolbar.Input
toolbarInput = Toolbar.defaultInput
  { orientation = Horizontal
  , ariaLabel = Just "Formatting"
  , items =
      [ Toolbar.Button { value: "new", label: [ HH.text "New" ], disabled: false }
      , Toolbar.Link { value: "edit", label: [ HH.text "Edit" ], href: "#", disabled: false }
      , Toolbar.Sep
      , Toolbar.ToggleGroup
          { items:
              [ { value: "left", label: [ HH.text "L" ], disabled: false }
              , { value: "center", label: [ HH.text "C" ], disabled: false }
              ]
          , single: true
          , defaultValue: [ "left" ]
          , ariaLabel: Just "Align"
          }
      ]
  , style =
      { root: cn ""
      , button: cn ""
      , link: cn ""
      , separator: cn ""
      , toggleGroup: cn ""
      , toggleItem: cn ""
      }
  }
