-- | Hydrogen.Themes interactive port — the INTERACTIVE Radix Themes components (Dialog,
-- | …) as styled wrappers over the `Hydrogen.Radix` primitives: the primitive supplies
-- | the behavior + anatomy, a themed `Style` (the rt-* classes) supplies the look, and
-- | the content is built from the at-rest `Hydrogen.Themes.*` components. Routed `?c=<id>`
-- | + the same compiled `themes.css` as the golden, so the open-state DOM/screenshot diff
-- | reduces to "our themed overlay == upstream's".
module ThemesInteractive.Main where

import Prelude

import Data.Array as Array
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Data.String (drop, indexOf, splitAt) as Str
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Radix.Accordion as Accordion
import Hydrogen.Radix.AlertDialog as AlertDialog
import Hydrogen.Radix.Checkbox as Checkbox
import Hydrogen.Radix.Collapsible as Collapsible
import Hydrogen.Radix.ContextMenu as ContextMenu
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.DropdownMenu as DropdownMenu
import Hydrogen.Radix.Form as Form
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Foundation.Style (Align(..), Orientation(..), Side(..), cn, dataAttr)
import Hydrogen.Radix.HoverCard as HoverCard
import Hydrogen.Radix.Menubar as Menubar
import Hydrogen.Radix.NavigationMenu as NavigationMenu
import Hydrogen.Radix.OneTimePasswordField as Otp
import Hydrogen.Radix.PasswordToggleField as PasswordToggleField
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.RadioGroup as RadioGroup
import Hydrogen.Radix.ScrollArea as ScrollArea
import Hydrogen.Radix.Select as Select
import Hydrogen.Radix.Slider as Slider
import Hydrogen.Radix.Switch as Switch
import Hydrogen.Radix.Tabs as Tabs
import Hydrogen.Radix.Toast as Toast
import Hydrogen.Radix.Toggle as Toggle
import Hydrogen.Radix.ToggleGroup as ToggleGroup
import Hydrogen.Radix.Toolbar as Toolbar
import Hydrogen.Radix.Tooltip as Tooltip
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.AccessibleIcon (accessibleIcon) as AccessibleIcon
import Hydrogen.Themes.Progress (progress) as Progress
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.TabNav (tabNavLink, tabNavRoot)
import Hydrogen.Themes.TextArea (textArea)
import Hydrogen.Themes.TextField (textField, textFieldValue)
import Hydrogen.Themes.Typography (textAs)
import Type.Proxy (Proxy(..))
import Web.DOM.ParentNode (QuerySelector(..))
import Web.HTML as HTML
import Web.HTML.Location as Location
import Web.HTML.Window as Window

type Slots =
  ( dialog :: Dialog.Slot Unit
  , alertdialog :: AlertDialog.Slot Unit
  , popover :: Popover.Slot Unit
  , tooltip :: Tooltip.Slot Unit
  , hovercard :: HoverCard.Slot Unit
  , dropdownmenu :: DropdownMenu.Slot Unit
  , contextmenu :: ContextMenu.Slot Unit
  , menubar :: Menubar.Slot Unit
  , navigationmenu :: NavigationMenu.Slot Unit
  , select :: Select.Slot Unit
  , slider :: Slider.Slot Unit
  , accordion :: Accordion.Slot Unit
  , collapsible :: Collapsible.Slot Unit
  , toast :: Toast.Slot Unit
  , tabs :: Tabs.Slot Unit
  , radiogroup :: RadioGroup.Slot Unit
  , checkbox :: Checkbox.Slot Unit
  , switch :: Switch.Slot Unit
  , toggle :: Toggle.Slot Unit
  , togglegroup :: ToggleGroup.Slot Unit
  , segmentedcontrol :: ToggleGroup.Slot Unit
  , checkboxgroup :: Checkbox.Slot Unit
  , radiocards :: RadioGroup.Slot Unit
  , checkboxcards :: Checkbox.Slot Unit
  , scrollarea :: ScrollArea.Slot Unit
  , passwordtoggle :: PasswordToggleField.Slot Unit
  , toolbar :: Toolbar.Slot Unit
  , otp :: Otp.Slot Unit
  , form :: Form.Slot Unit
  )

_dialog :: Proxy "dialog"
_dialog = Proxy

_alertdialog :: Proxy "alertdialog"
_alertdialog = Proxy

_popover :: Proxy "popover"
_popover = Proxy

_tooltip :: Proxy "tooltip"
_tooltip = Proxy

_hovercard :: Proxy "hovercard"
_hovercard = Proxy

_dropdownmenu :: Proxy "dropdownmenu"
_dropdownmenu = Proxy

_contextmenu :: Proxy "contextmenu"
_contextmenu = Proxy

_menubar :: Proxy "menubar"
_menubar = Proxy

_navigationmenu :: Proxy "navigationmenu"
_navigationmenu = Proxy

_select :: Proxy "select"
_select = Proxy

_slider :: Proxy "slider"
_slider = Proxy

_accordion :: Proxy "accordion"
_accordion = Proxy

_collapsible :: Proxy "collapsible"
_collapsible = Proxy

_toast :: Proxy "toast"
_toast = Proxy

_tabs :: Proxy "tabs"
_tabs = Proxy

_radiogroup :: Proxy "radiogroup"
_radiogroup = Proxy

_checkbox :: Proxy "checkbox"
_checkbox = Proxy

_switch :: Proxy "switch"
_switch = Proxy

_toggle :: Proxy "toggle"
_toggle = Proxy

_togglegroup :: Proxy "togglegroup"
_togglegroup = Proxy

_segmentedcontrol :: Proxy "segmentedcontrol"
_segmentedcontrol = Proxy

_checkboxgroup :: Proxy "checkboxgroup"
_checkboxgroup = Proxy

_radiocards :: Proxy "radiocards"
_radiocards = Proxy

_checkboxcards :: Proxy "checkboxcards"
_checkboxcards = Proxy

_scrollarea :: Proxy "scrollarea"
_scrollarea = Proxy

_passwordtoggle :: Proxy "passwordtoggle"
_passwordtoggle = Proxy

_toolbar :: Proxy "toolbar"
_toolbar = Proxy

_otp :: Proxy "otp"
_otp = Proxy

_form :: Proxy "form"
_form = Proxy

main :: Effect Unit
main = do
  c <- queryParam "c"
  s <- queryParam "s"
  HA.runHalogenAff do
    HA.awaitLoad
    mEl <- HA.selectElement (QuerySelector "#root")
    for_ mEl \el -> void (runUI (root c s) unit el)

root :: forall q i o. String -> String -> H.Component q i o Aff
root c s =
  H.mkComponent
    { initialState: const unit
    , render: const (view c s)
    , eval: H.mkEval H.defaultEval
    }

-- | The ROOT theme — a `<div class="radix-themes light" data-…>` inside #root, exactly as
-- | upstream nests it (the <body> stays bare). Each demo is then wrapped in `Box p="6"` as
-- | the golden wraps its pages. Portaled overlays re-apply the theme themselves (so adopted-
-- | to-body content stays themed) — see `portalThemeAttrs`.
view :: String -> String -> H.ComponentHTML Void Slots Aff
view c s =
  HH.div
    ( [ HP.class_ (HH.ClassName "radix-themes light")
      , HP.style "--default-font-family: 'Inter Variable', sans-serif;"
      ] <> themeDataAttrs true
    )
    [ box [ P "6" ]
        [ case c of
            "dialog" -> HH.slot_ _dialog unit Dialog.component dialogInput
            "alertdialog" -> HH.slot_ _alertdialog unit AlertDialog.component alertDialogInput
            "popover" -> HH.slot_ _popover unit Popover.component popoverInput
            "tooltip" -> HH.slot_ _tooltip unit Tooltip.component tooltipInput
            "hovercard" -> HH.slot_ _hovercard unit HoverCard.component hoverCardInput
            "dropdownmenu" -> HH.slot_ _dropdownmenu unit DropdownMenu.component (dropdownMenuInput s)
            "contextmenu" -> HH.slot_ _contextmenu unit ContextMenu.component contextMenuInput
            "menubar" -> HH.slot_ _menubar unit Menubar.component menubarInput
            "navigationmenu" -> HH.slot_ _navigationmenu unit NavigationMenu.component (navigationMenuInput s)
            "select" -> HH.slot_ _select unit Select.component selectInput
            "slider" -> box [ StyleProp "max-width" "320px" ] [ HH.slot_ _slider unit Slider.component (sliderInput s) ]
            "accordion" -> box [ StyleProp "max-width" "360px" ] [ HH.slot_ _accordion unit Accordion.component (accordionInput s) ]
            "collapsible" -> HH.slot_ _collapsible unit Collapsible.component collapsibleInput
            "toast" -> HH.slot_ _toast unit Toast.component toastInput
            "tabs" -> HH.slot_ _tabs unit Tabs.component tabsInput
            "radiogroup" -> HH.slot_ _radiogroup unit RadioGroup.component radioGroupInput
            "checkbox" -> HH.slot_ _checkbox unit Checkbox.component checkboxInput
            "switch" -> HH.slot_ _switch unit Switch.component switchInput
            "toggle" -> HH.slot_ _toggle unit Toggle.component toggleInput
            "togglegroup" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupInput
            "segmentedcontrol" -> HH.slot_ _segmentedcontrol unit ToggleGroup.component segmentedControlInput
            "checkboxgroup" -> checkboxGroupPage
            "radiocards" -> HH.slot_ _radiocards unit RadioGroup.component radioCardsInput
            "checkboxcards" -> checkboxCardsPage
            -- `Align` is ambiguous here (Prop.Align vs Foundation.Style.Align in scope),
            -- so spell the flex align class directly: align="center" → rt-r-ai-center.
            "accessibleicon" -> flex [ Class "rt-r-ai-center" ] (AccessibleIcon.accessibleIcon "Settings" gearIcon)
            "progress" -> box [ StyleProp "max-width" "320px" ] [ Progress.progress 25 [] ]
            "scrollarea" -> HH.slot_ _scrollarea unit ScrollArea.component scrollAreaInput
            "tabnav" -> tabNavPage
            "passwordtoggle" -> passwordTogglePage
            "toolbar" -> HH.slot_ _toolbar unit Toolbar.component (toolbarInput s)
            "otp" -> box [] [ HH.slot_ _otp unit Otp.component (otpInput s) ]
            "form" -> box [] [ HH.slot_ _form unit Form.component (formInput s) ]
            _ -> HH.div_ [ HH.text "pick a ?c=<component> (e.g. ?c=dialog)" ]
        ]
    ]

-- | The theme `data-*` attributes radix stamps on every `.radix-themes` root. `isRoot`
-- | distinguishes the page root (has-background + is-root-theme = true) from a re-themed
-- | portal (both false — it sits on the bare body, carrying no panel background).
themeDataAttrs :: forall r i. Boolean -> Array (HH.IProp r i)
themeDataAttrs isRoot =
  [ dataAttr "accent-color" "indigo"
  , dataAttr "gray-color" "slate"
  , dataAttr "has-background" (if isRoot then "true" else "false")
  , dataAttr "is-root-theme" (if isRoot then "true" else "false")
  , dataAttr "panel-background" "translucent"
  , dataAttr "radius" "medium"
  , dataAttr "scaling" "100%"
  ]

-- | The themed Dialog: the Radix primitive driven open, with the rt-* Style + content
-- | built from the at-rest Themes components. Driven open by the shared state driver
-- | (not defaultOpen — so the DOM-oracle driver, which clicks the trigger, can open it;
-- | a defaultOpen modal renders with the backdrop already over the trigger).
dialogInput :: Dialog.Input
dialogInput = Dialog.defaultInput
  { style = dialogStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 450px; pointer-events: auto;"
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

-- | The theme `data-*` attrs (as k/v pairs) a preset stamps on a portaled overlay so the
-- | adopted-to-body content stays themed — the portal variant (is-root-theme/has-background
-- | both false). Paired with `light radix-themes` in the overlay's class list.
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

-- | Radix Themes' Dialog class vocabulary (from the open-state golden). The overlay (the
-- | portaled root) carries `light radix-themes` so it re-themes the adopted content.
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

-- | The themed AlertDialog: same modal anatomy as Dialog (overlay > scroll > scrollPadding
-- | > content) but role=alertdialog, no close-on-outside-click, and the upstream "Revoke
-- | access" demo content. `defaultOpen` so the open state renders.
alertDialogInput :: AlertDialog.Input
alertDialogInput = AlertDialog.defaultInput
  { style = alertDialogStyle
  , triggerAttrs = [ Tuple "accent-color" "red" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 450px; pointer-events: auto;"
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

-- | Radix Themes' AlertDialog class vocabulary (from the open-state golden).
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

-- | The themed Popover: floating content anchored bottom-start, the upstream "Comment"
-- | demo (a soft trigger + a 360px-wide textarea card). `defaultOpen` so it renders open.
-- NOTE: defaultOpen is FALSE (unlike the modal presets) — a floating overlay is
-- positioned by Popper inside openPopover, which only runs on an actual open
-- transition (trigger click), so the screenshot driver clicks it open.
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

-- | The `--radix-<c>-content-*` / `--radix-<c>-trigger-*` aliases radix writes inline on a
-- | floating content, aliasing the wrapper's `--radix-popper-*` vars. `c` is the component
-- | slug (popover / tooltip / hover-card).
popperContentVars :: String -> String
popperContentVars c =
  "--radix-" <> c <> "-content-transform-origin: var(--radix-popper-transform-origin); "
    <> "--radix-" <> c <> "-content-available-width: var(--radix-popper-available-width); "
    <> "--radix-" <> c <> "-content-available-height: var(--radix-popper-available-height); "
    <> "--radix-" <> c <> "-trigger-width: var(--radix-popper-anchor-width); "
    <> "--radix-" <> c <> "-trigger-height: var(--radix-popper-anchor-height);"

-- | The themed Tooltip: a small floating label opened by hover. Near the top of the
-- | viewport the preferred Top side collides and Popper flips to bottom (matching the
-- | golden's data-side=bottom). The driver hovers the trigger to open it.
tooltipInput :: Tooltip.Input
tooltipInput = Tooltip.defaultInput
  { style = tooltipStyle
  -- offset 8 holds the 5px arrow; padding 10 = radix's collisionPadding. Near the viewport
  -- top the preferred `top` overflows the gutter and genuinely flips to `bottom` (the
  -- content is now measured at its true max-content size, so the flip fires correctly).
  , offset = 8.0
  , padding = 10.0
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--max-width: 9999px; " <> popperContentVars "tooltip"
  , trigger = [ HH.text "Hover me" ]
  , content = [ textAs "p" [ Size "1", Class "rt-TooltipText" ] [ HH.text "Add to library" ] ]
  , arrow = [ tooltipArrow ]
  }

-- | The tooltip arrow (radix's rt-TooltipArrow) — a 10×5 down-pointing triangle; the
-- | primitive rotates it to face the trigger. fill comes from rt-TooltipArrow (the bg).
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

tooltipStyle :: Tooltip.Style
tooltipStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "light radix-themes rt-TooltipContent rt-r-max-w"
  }

-- | The themed HoverCard: an inline link trigger (@radix_ui) that, on hover, reveals a
-- | small gray-text card. bottom-start, 300px max-width (the upstream demo).
hoverCardInput :: HoverCard.Input
hoverCardInput = HoverCard.defaultInput
  { align = Start
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

-- | The themed DropdownMenu: a soft "Options" trigger opening a solid menu panel with
-- | items, ⌘-shortcuts, separators, and a red Delete (the upstream demo). Menus position
-- | via Popper, so defaultOpen stays false and the driver clicks open.
dropdownMenuInput :: String -> DropdownMenu.Input
dropdownMenuInput s = DropdownMenu.defaultInput
  { style = menuStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "dropdown-menu" <> " pointer-events: auto;"
  , trigger = [ HH.text "Options", chevron ]
  , entries =
      -- `?s=disabled` disables the SECOND item (Duplicate) so the APG disabled-skip
      -- check proves roving navigation skips OVER it to Archive.
      [ menuRow "edit" "Edit" "⌘ E" "" false
      , menuRow "duplicate" "Duplicate" "⌘ D" "" (s == "disabled")
      , DropdownMenu.menuSeparator
      , menuRow "archive" "Archive" "⌘ N" "" false
      , DropdownMenu.menuSeparator
      , menuRow "delete" "Delete" "⌘ ⌫" "red" false
      ]
  }

-- | One themed menu item: label + right-aligned shortcut + optional accent + disabled.
menuRow :: String -> String -> String -> String -> Boolean -> DropdownMenu.MenuEntry
menuRow value label shortcut accent disabled =
  DropdownMenu.MenuItemEntry
    { value
    , label: [ HH.text label ]
    , shortcut: [ HH.text shortcut ]
    , accent
    , disabled
    }

-- | Radix Themes' DropdownMenu class vocabulary (from the open-state golden).
menuStyle :: DropdownMenu.Style
menuStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "light radix-themes rt-BaseMenuContent rt-DropdownMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , scrollRoot: cn "rt-ScrollAreaRoot"
  , scrollViewport: cn "rt-ScrollAreaViewport"
  , menuViewport: cn "rt-BaseMenuViewport rt-DropdownMenuViewport"
  , focusRing: cn "rt-ScrollAreaViewportFocusRing"
  , item: cn "rt-BaseMenuItem rt-DropdownMenuItem rt-reset"
  , shortcut: cn "rt-BaseMenuShortcut rt-DropdownMenuShortcut"
  , separator: cn "rt-BaseMenuSeparator rt-DropdownMenuSeparator"
  }

-- | The themed ContextMenu: a dashed right-click area opening a solid menu panel. The
-- | dashed box is the trigger CONTENT (its border is inline style the classes-only Style
-- | can't carry); the primitive's wrapper div carries the contextmenu handler + data-state.
-- | NOTE: the menu anchors to the trigger element (below it), not the cursor point — true
-- | point-anchoring is the documented Float.Popper follow-up (STR-336).
contextMenuInput :: ContextMenu.Input
contextMenuInput = ContextMenu.defaultInput
  { side = Right   -- radix point-anchors the menu to the right of the cursor (data-side=right)
  , style = contextMenuStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "context-menu" <> " pointer-events: auto;"
  -- the trigger AREA is the dashed box itself (rt-Flex classes via style.trigger, size/border
  -- via triggerStyle, the text as its content) — radix's asChild Trigger, one element.
  , triggerStyle = "width: 240px; height: 120px; border: 1px dashed var(--gray-6); border-radius: var(--radius-3);"
  , trigger = [ textAs "span" [ Size "2", Color "gray" ] [ HH.text "Right-click here" ] ]
  , entries =
      [ ctxRow "edit" "Edit" "⌘ E" ""
      , ctxRow "duplicate" "Duplicate" "⌘ D" ""
      , ContextMenu.menuSeparator
      , ctxRow "delete" "Delete" "⌘ ⌫" "red"
      ]
  }

ctxRow :: String -> String -> String -> String -> ContextMenu.MenuEntry
ctxRow value label shortcut accent =
  ContextMenu.MenuItemEntry
    { value, label: [ HH.text label ], shortcut: [ HH.text shortcut ], accent, disabled: false }

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
  }

-- | menubar — the bare @radix-ui Menubar primitive (Radix Themes ships none, so NO rt-*
-- | classes; the golden is the unstyled primitive). A horizontal roving bar of three menus
-- | (File/Edit/View); File's menu has New Tab / New Window / sep / Print, the same structure
-- | and labels as the golden story. Bare ⇒ every Style slot empty, no portalAttrs. The content
-- | style carries outline:none + the `--radix-menubar-*` popper var aliases (NO pointer-events:
-- | the menus are modal={false}, so no scroll-lock/pointer block — see Menubar's non-modal env).
menubarInput :: Menubar.Input
menubarInput = Menubar.defaultInput
  { align = Start
  , contentStyle = "outline: none; " <> popperContentVars "menubar"
  , menus =
      [ { value: "file"
        , trigger: [ HH.text "File" ]
        , entries:
            [ Menubar.menuItem "new-tab" [ HH.text "New Tab" ]
            , Menubar.menuItem "new-window" [ HH.text "New Window" ]
            , Menubar.menuSeparator
            , Menubar.menuItem "print" [ HH.text "Print" ]
            ]
        }
      , { value: "edit"
        , trigger: [ HH.text "Edit" ]
        , entries:
            [ Menubar.menuItem "undo" [ HH.text "Undo" ]
            , Menubar.menuItem "redo" [ HH.text "Redo" ]
            ]
        }
      , { value: "view"
        , trigger: [ HH.text "View" ]
        , entries:
            [ Menubar.menuItem "zoom-in" [ HH.text "Zoom In" ]
            , Menubar.menuItem "zoom-out" [ HH.text "Zoom Out" ]
            ]
        }
      ]
  }

-- | navigationmenu — the bare @radix-ui NavigationMenu primitive (Radix Themes ships none, so
-- | NO rt-* classes; the golden is the unstyled primitive). Two menu items, the SAME structure
-- | and labels as the golden story: Item One (open via defaultValue="one") → Content One/Two
-- | links; Item Two → Content Three. Viewport mode (the Content is proxied into the Viewport
-- | sibling), with the measured Indicator + size vars. defaultValue="one" so it is OPEN at first
-- | paint (off the open-delay timer path). Bare ⇒ every Style slot empty.
navigationMenuInput :: String -> NavigationMenu.Input
navigationMenuInput s = NavigationMenu.defaultInput
  -- OPEN at first paint (defaultValue="one") ONLY for the explicit `open` capture (?s=open);
  -- every other path (the `closed`/`rest` capture, the index) renders at rest — mirroring the
  -- golden story's `currentState() === "open"` switch (so the a11y `rest` baseline matches too).
  { defaultValue = if s == "open" then "one" else ""
  , items =
      [ { value: "one"
        , trigger: [ HH.text "Item One" ]
        , links:
            [ { href: "#one", label: [ HH.text "Content One" ], active: false }
            , { href: "#two", label: [ HH.text "Content Two" ], active: false }
            ]
        }
      , { value: "two"
        , trigger: [ HH.text "Item Two" ]
        , links:
            [ { href: "#three", label: [ HH.text "Content Three" ], active: false }
            ]
        }
      ]
  }

-- | The themed Select: a surface trigger showing the selected value + chevron, opening a
-- | solid listbox with a "Fruits" group and a check indicator on the selected option.
-- | Apple is the default value. Listbox positions via Popper, so the driver clicks open.
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

-- | slider — the themed Radix Themes slider, driven by the real `Hydrogen.Radix.Slider`
-- | primitive (keyboard-conformant, APG slider pattern). A single horizontal thumb at value
-- | 40 (min 0, max 100, step 1); the driver focuses the thumb and presses ArrowRight 5× →
-- | value 45 (range `right: 55%`, thumb `left: calc(45% + …)`). The rt-Slider* class anatomy
-- | is supplied via the primitive's Style slots.
sliderInput :: String -> Slider.Input
sliderInput s = Slider.defaultInput
  { defaultValue = 40
  , min = 0
  , max = 100
  , step = 1
  , disabled = s == "disabled"
  , style =
      { root: cn "rt-SliderRoot rt-r-size-2 rt-variant-surface"
      , track: cn "rt-SliderTrack"
      , range: cn "rt-SliderRange"
      , thumb: cn "rt-SliderThumb"
      }
  }

-- | scrollarea — the themed Radix ScrollArea (type="always", scrollbars="vertical"): a
-- | 200×120 box whose 12-line content overflows vertically, so the styled scrollbar +
-- | thumb render at rest. The rt-* Style reproduces upstream's class anatomy; the content
-- | mirrors the golden story (a `rt-Box rt-r-p-2 width:160px` of `rt-Text rt-r-size-2`
-- | paragraphs, each "Line " + N as TWO text nodes, exactly as React splits the JSX).
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
      }
  , content =
      [ box [ P "2", Width "160px" ]
          ( map
              ( \n -> textAs "p" [ Size "2" ] [ HH.text "Line ", HH.text (show n) ] )
              (Array.range 1 12)
          )
      ]
  }

-- ── interactive (inline, non-portal) routes ─────────────────────────────────────
-- Each of the 13 component routes below renders the themed Radix primitive inline
-- (no portal): the primitive supplies behavior + the click-driven state transition
-- the DOM-oracle drives, and a themed `Style`/content reproduces the upstream rt-*
-- class anatomy. Each `*Input` binding is SELF-CONTAINED (one top-level binding) so a
-- later fan-out can perfect one without touching its neighbors.

-- | accordion — the bare @radix-ui Accordion primitive (Radix Themes ships none, so
-- | NO rt-* classes; the golden is the unstyled primitive). type=multiple, closed.
accordionInput :: String -> Accordion.Input
accordionInput s = Accordion.defaultInput
  { items =
      [ { value: "item-1", header: [ HH.text "Is it accessible?" ], content: [ HH.text "Yes. It adheres to the WAI-ARIA design pattern." ], disabled: false }
      -- `?s=disabled` disables the MIDDLE trigger so the APG disabled-skip check proves
      -- arrows skip OVER it (upstream filters disabled out of the navigable collection).
      , { value: "item-2", header: [ HH.text "Is it styled?" ], content: [ HH.text "No. It is unstyled by default." ], disabled: s == "disabled" }
      , { value: "item-3", header: [ HH.text "Is it animated?" ], content: [ HH.text "Yes, with CSS." ], disabled: false }
      ]
  , single = false
  , defaultValue = []
  , style =
      { root: cn ""
      , item: cn ""
      , header: cn ""
      , trigger: cn ""
      , content: cn ""
      }
  }

-- | collapsible — a themed soft Button trigger + a Box>Text content panel. The
-- | primitive Content div itself carries NO rt-* class (bare Primitive.div), so
-- | style.content is empty; the rt-Box/rt-Text classes live on the children.
collapsibleInput :: Collapsible.Input
collapsibleInput = Collapsible.defaultInput
  { open = Nothing
  , defaultOpen = false
  , style =
      { root: cn ""
      , trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
      , content: cn ""
      }
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , trigger = [ HH.text "Toggle content" ]
  , content =
      [ box [ Pt "2" ]
          [ textAs "div" [ Size "2" ] [ HH.text "Disclosed content line one." ] ]
      ]
  }

-- | toast — the BARE @radix-ui Toast primitive (Radix Themes ships none, so NO rt-* classes;
-- | EMPTY style slots, same as the golden's unstyled story). Rendered UNCONTROLLED (open=
-- | Nothing, defaultOpen=true → mounted open at first paint, internal open live so Escape can
-- | close it) so it matches the golden's open AND closing oracle. The announce mirror text is
-- | the literal upstream string ("Notification" label + the concatenated visible non-excluded
-- | part text) — supplied here since PlainHTML is not introspectable. Same structure/labels as
-- | the golden: Title "Scheduled", Description "Friday at 5pm", Action "Undo" (altText="Undo"),
-- | Close "×" (aria-label "Close").
toastInput :: Toast.Input
toastInput = Toast.defaultInput
  { open = Nothing
  , defaultOpen = true
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
  -- mirror the golden story's inline exit keyframe so the closing li lingers data-state=closed
  -- through its (pinned) exit animation (otherwise Presence unmounts it synchronously). <style>
  -- is in the normalizer SKIP set, so it never enters the DOM diff.
  , exitCss = "@keyframes toastExit { from { opacity: 1 } to { opacity: 0 } } li[data-state=\"closed\"][data-swipe-direction] { animation: toastExit 100ms ease-out; }"
  }

-- | tabs — three tabs (Account/Documents/Settings) starting on account; the driver
-- | clicks the second tab. Themed with the rt-Tabs* class vocabulary.
tabsInput :: Tabs.Input
tabsInput = Tabs.defaultInput
  { tabs =
      [ { value: "account", label: tabsTriggerLabel "Account", content: [ textAs "span" [ Size "2" ] [ HH.text "Make changes to your account." ] ], disabled: false }
      , { value: "documents", label: tabsTriggerLabel "Documents", content: [ textAs "span" [ Size "2" ] [ HH.text "Access and update your documents." ] ], disabled: false }
      , { value: "settings", label: tabsTriggerLabel "Settings", content: [ textAs "span" [ Size "2" ] [ HH.text "Edit your profile or update contact information." ] ], disabled: false }
      ]
  , defaultValue = Just "account"
  , idPrefix = ""
  , style =
      { root: cn "rt-TabsRoot"
      , list: cn "rt-BaseTabList rt-TabsList rt-r-size-2"
      , trigger: cn "rt-reset rt-BaseTabListTrigger rt-TabsTrigger"
      , content: cn "rt-TabsContent"
      }
  }

-- | The upstream Themes Tabs.Trigger label anatomy: a visible inner span + a hidden
-- | (bold) measuring span, the same inner/hidden pair as TabNav.Link. The primitive
-- | is theme-agnostic, so the rt-Tabs* span chrome is supplied here (gallery side).
tabsTriggerLabel :: String -> Array HH.PlainHTML
tabsTriggerLabel label =
  [ HH.span
      [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInner rt-TabsTriggerInner") ]
      [ HH.text label ]
  , HH.span
      [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInnerHidden rt-TabsTriggerInnerHidden") ]
      [ HH.text label ]
  ]

-- | radiogroup — the themed Radix Themes radio group, driven by the real
-- | `Hydrogen.Radix.RadioGroup` primitive (roving keyboard + onEntryFocus +
-- | selection-follows-focus, APG-conformant). Two options; Default is checked
-- | initially, the driver clicks/keys to Comfortable. The themed chrome (root column
-- | flex, per-item `<label> > inner-flex > [button, labelText]`) is supplied via the
-- | primitive's `flex`/`itemLabel`/`itemInner` Style slots + `labelOutside`.
radioGroupInput :: RadioGroup.Input
radioGroupInput = RadioGroup.defaultInput
  { items =
      [ { value: "1", label: [ HH.text " Default" ], disabled: false }
      , { value: "2", label: [ HH.text " Comfortable" ], disabled: false }
      ]
  , defaultValue = Just "1"
  , itemIds = false
  , labelOutside = true
  , style =
      { root: cn "rt-RadioGroupRoot"
      , item: cn "rt-reset rt-BaseRadioRoot rt-r-size-2 rt-variant-surface"
      , indicator: cn ""
      , flex: cn "rt-Flex rt-r-fd-column rt-r-gap-2"
      , itemLabel: cn "rt-Text rt-r-size-2"
      , itemInner: cn "rt-Flex rt-r-ai-center rt-r-gap-2"
      }
  }

-- | checkbox — a bare single Themes checkbox, unchecked; the driver clicks to check.
-- | The indicator content is the ThickCheckIcon SVG.
checkboxInput :: Checkbox.Input
checkboxInput = Checkbox.defaultInput
  { defaultChecked = Checkbox.Unchecked
  , value = "on"
  , style =
      { root: cn "rt-reset rt-BaseCheckboxRoot rt-CheckboxRoot rt-r-size-2 rt-variant-surface"
      , indicator: cn "rt-BaseCheckboxIndicator rt-CheckboxIndicator"
      }
  , children = [ thickCheckIconPlain ]
  }

-- | switch — a single OFF Themes switch; the driver clicks to turn it on.
switchInput :: Switch.Input
switchInput = Switch.defaultInput
  { defaultChecked = false
  , value = "on"
  , style =
      { root: cn "rt-reset rt-SwitchRoot rt-r-size-2 rt-variant-surface"
      , thumb: cn "rt-SwitchThumb"
      }
  }

-- | toggle — a soft "B" toggle, unpressed; the driver clicks to press.
toggleInput :: Toggle.Input
toggleInput = Toggle.defaultInput
  { pressed = Nothing
  , defaultPressed = false
  , ariaLabel = Just "Bold"
  , style = { root: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft" }
  , children = [ HH.text "B" ]
  }

-- | togglegroup — the bare @radix-ui ToggleGroup primitive (no Radix Themes wrapper),
-- | single-select, Center pre-pressed; the driver clicks the first item (Left). The
-- | upstream nodes are classless, so the Style is empty to match.
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

-- | segmentedcontrol — themes-only, driven by the ToggleGroup primitive (single). 3
-- | segments (Inbox/Drafts/Sent), Inbox default; the driver clicks Drafts. Each item
-- | label is the upstream separator+label sub-tree. NOTE: the trailing
-- | `rt-SegmentedControlIndicator` sibling div the golden carries is a primitive
-- | xFix (the ToggleGroup root does not emit it) — left for the fan-out.
segmentedControlInput :: ToggleGroup.Input
segmentedControlInput = ToggleGroup.defaultInput
  { single = true
  , defaultValue = [ "inbox" ]
  , items =
      [ { value: "inbox", label: segmentLabel "Inbox", disabled: false }
      , { value: "drafts", label: segmentLabel "Drafts", disabled: false }
      , { value: "sent", label: segmentLabel "Sent", disabled: false }
      ]
  -- upstream SegmentedControl.Root appends a trailing sliding-indicator div as the
  -- last child of the root (after the segment buttons) -- emitted via `trailing`.
  , trailing = [ HH.div [ HP.class_ (HH.ClassName "rt-SegmentedControlIndicator") ] [] ]
  , style =
      { root: cn "rt-SegmentedControlRoot rt-r-size-2 rt-variant-surface"
      , item: cn "rt-reset rt-SegmentedControlItem"
      }
  }

-- | The upstream SegmentedControl item inner sub-tree (separator span + label wrapper
-- | with active/inactive label spans), as the ToggleGroup Item label.
segmentLabel :: String -> Array HH.PlainHTML
segmentLabel label =
  [ HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemSeparator") ] []
  , HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabel") ]
      [ HH.span [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabelActive") ] [ HH.text label ]
      , HH.span
          [ HP.class_ (HH.ClassName "rt-SegmentedControlItemLabelInactive")
          , HP.attr (HH.AttrName "aria-hidden") "true"
          ]
          [ HH.text label ]
      ]
  ]

-- | checkboxgroup — themes-only, first-cut driven by the Checkbox primitive (a single
-- | item starting unchecked; the driver clicks to check). The golden wraps it in a
-- | label.rt-CheckboxGroupItem + rt-CheckboxGroupItemInner span — that label chrome and
-- | the svg-as-indicator (vs span wrapper) are primitive xFixes for the fan-out.
checkboxGroupInput :: Checkbox.Input
checkboxGroupInput = Checkbox.defaultInput
  { defaultChecked = Checkbox.Unchecked
  , value = "1"
  , style =
      { root: cn "rt-reset rt-BaseCheckboxRoot rt-CheckboxGroupItemCheckbox rt-r-size-2 rt-variant-surface"
      , indicator: cn "rt-BaseCheckboxIndicator"
      }
  -- The RovingFocus + group context attributes upstream merges onto the item button:
  -- aria-required=false (group required=false), data-radix-collection-item, and the
  -- roving tabindex (the single clicked item becomes the current tab stop -> 0).
  , extraAttrs =
      [ Tuple "aria-required" "false"
      , Tuple "data-radix-collection-item" ""
      , Tuple "tabindex" "0"
      ]
  , children = [ thickCheckIndicator "rt-BaseCheckboxIndicator" ]
  }

-- | radiocards — themes-only (RadioGroupPrimitive styled as cards). Three options,
-- | value 2 pre-selected? No: value 1 default, the driver clicks card 2. Each label is
-- | a bold rt-Text span. NOTE: the grid root style/attrs (aria-required, dir, the
-- | --grid-template-columns custom prop) and indicator-span suppression are primitive
-- | xFixes for the fan-out.
radioCardsInput :: RadioGroup.Input
radioCardsInput = RadioGroup.defaultInput
  { items =
      [ { value: "1", label: [ textAs "span" [ Weight "bold" ] [ HH.text "8-core CPU" ] ], disabled: false }
      , { value: "2", label: [ textAs "span" [ Weight "bold" ] [ HH.text "6-core CPU" ] ], disabled: false }
      , { value: "3", label: [ textAs "span" [ Weight "bold" ] [ HH.text "4-core CPU" ] ], disabled: false }
      ]
  , defaultValue = Just "1"
  , rootStyle = "--grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));"
  , itemIds = false
  , style =
      { root: cn "rt-Grid rt-RadioCardsRoot rt-r-size-2 rt-variant-surface rt-r-gtc rt-r-gap-4"
      , item: cn "rt-reset rt-BaseCard rt-RadioCardsItem"
      , indicator: cn ""
      -- RadioCards: no inner-flex wrapper (grid root) and no per-item `<label>` chrome —
      -- the button is a direct child of the grid and carries its own label children.
      , flex: cn ""
      , itemLabel: cn ""
      , itemInner: cn ""
      }
  }

-- | checkboxcards — themes-only, first-cut driven by the Checkbox primitive (single
-- | card starting unchecked; the driver clicks to check). The golden wraps it in a
-- | label.rt-BaseCard.rt-CheckboxCardsItem carrying a rt-Text label + the checkbox
-- | button, inside a grid root — that card/grid chrome is a fan-out refinement.
checkboxCardsInput :: Checkbox.Input
checkboxCardsInput = Checkbox.defaultInput
  { defaultChecked = Checkbox.Unchecked
  , value = "terms"
  , style =
      { root: cn "rt-reset rt-BaseCheckboxRoot rt-CheckboxCardCheckbox rt-r-size-2 rt-variant-surface"
      , indicator: cn "rt-BaseCheckboxIndicator"
      }
  -- The RovingFocus + group context attributes upstream merges onto the card button:
  -- aria-required=false, data-radix-collection-item, and the roving tabindex (the
  -- single clicked card becomes the current tab stop -> 0).
  , extraAttrs =
      [ Tuple "aria-required" "false"
      , Tuple "data-radix-collection-item" ""
      , Tuple "tabindex" "0"
      ]
  , children = [ thickCheckIndicator "rt-BaseCheckboxIndicator" ]
  }

-- | checkboxgroup page -- the CheckboxGroup.Root chrome (a roving <div role=group>) with a
-- | single CheckboxGroup.Item (a <label> wrapping the interactive checkbox button + the
-- | rt-CheckboxGroupItemInner span). The button is the live Checkbox primitive (slot), so
-- | the driver's click flips it to checked and the asChild indicator svg mounts.
checkboxGroupPage :: H.ComponentHTML Void Slots Aff
checkboxGroupPage =
  HH.div
    [ HP.class_ (HH.ClassName "rt-CheckboxGroupRoot")
    , HP.attr (HH.AttrName "dir") "ltr"
    , HP.attr (HH.AttrName "role") "group"
    , HP.style "outline: none;"
    , HP.attr (HH.AttrName "tabindex") "0"
    ]
    [ HH.label
        [ HP.class_ (HH.ClassName "rt-CheckboxGroupItem rt-Text rt-r-size-2") ]
        [ HH.slot_ _checkboxgroup unit Checkbox.component checkboxGroupInput
        , HH.span
            [ HP.class_ (HH.ClassName "rt-CheckboxGroupItemInner") ]
            [ HH.text "Fun" ]
        ]
    ]

-- | checkboxcards page -- the CheckboxCards.Root grid chrome (a roving <div role=group>) with
-- | a single CheckboxCards.Item: a <label class="rt-BaseCard rt-CheckboxCardsItem"> whose
-- | rt-Text label child renders FIRST, then the interactive checkbox button (slot). The
-- | label intercepts the click (native label -> control), toggling the checkbox to checked.
checkboxCardsPage :: H.ComponentHTML Void Slots Aff
checkboxCardsPage =
  HH.div
    [ HP.class_ (HH.ClassName "rt-CheckboxCardsRoot rt-Grid rt-r-gap-4 rt-r-gtc rt-r-size-2 rt-variant-surface")
    , HP.attr (HH.AttrName "dir") "ltr"
    , HP.attr (HH.AttrName "role") "group"
    , HP.style "outline: none; --grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));"
    , HP.attr (HH.AttrName "tabindex") "0"
    ]
    [ HH.label
        [ HP.class_ (HH.ClassName "rt-BaseCard rt-CheckboxCardsItem") ]
        [ textAs "span" [] [ HH.text "Agree to Terms and Conditions" ]
        , HH.slot_ _checkboxcards unit Checkbox.component checkboxCardsInput
        ]
    ]

-- | passwordtoggle — the bare @radix-ui PasswordToggleField primitive (Radix Themes
-- | ships none, so NO rt-* classes; the golden is the unstyled primitive). The page is a
-- | `<Box>` (inner rt-Box) wrapping a `<label for=password>Password</label>` sibling + the
-- | component (input+button). The explicit input id="password" makes inputId literal (no
-- | useId) so the toggle's id/aria-controls don't even need the id normalizer; a text Slot
-- | (Show/Hide) suppresses the auto aria-label. The driver clicks the toggle → type flips
-- | password→text and the Slot text Show→Hide.
passwordTogglePage :: H.ComponentHTML Void Slots Aff
passwordTogglePage =
  box []
    [ HH.label
        [ HP.attr (HH.AttrName "for") "password" ]
        [ HH.text "Password" ]
    , HH.slot_ _passwordtoggle unit PasswordToggleField.component passwordToggleInput
    ]

passwordToggleInput :: PasswordToggleField.Input
passwordToggleInput = PasswordToggleField.defaultInput
  { inputId = Just "password"
  , toggleVisible = [ HH.text "Hide" ]
  , toggleHidden = [ HH.text "Show" ]
  , style = { input: cn "", toggle: cn "" }
  }

-- | toolbar — the bare @radix-ui Toolbar primitive (Radix Themes ships none, so NO
-- | rt-* classes; the golden is the unstyled primitive). A "Formatting" toolbar with a
-- | Button (New), Link (Edit), Separator, and a single-select ToggleGroup (Align: L/C,
-- | Left pre-pressed). `?s=vertical` flips orientation (aria/data-orientation, and the
-- | separator's FLIPPED orientation). Bare ⇒ every Style slot empty.
toolbarInput :: String -> Toolbar.Input
toolbarInput s = Toolbar.defaultInput
  { orientation = if s == "vertical" then Vertical else Horizontal
  , dir = LTR
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

-- | otp — the bare @radix-ui OneTimePasswordField primitive (Radix Themes ships none,
-- | so NO rt-* classes; the golden is the unstyled primitive). A 3-slot numeric field
-- | wrapped in a `<Box>` (inner rt-Box). The default story seeds defaultValue="123"
-- | (filled); `?s=empty`/`?s=typed` render empty (the driver types "45" for typed).
otpInput :: String -> Otp.Input
otpInput s = Otp.defaultInput
  { length = 3
  , defaultValue =
      if s == "empty" || s == "typed" then ""
      else if s == "alpha" then "abc"
      else "123"
  -- `?s=alpha` exercises the Alpha validation set (inputmode=text, pattern=[a-zA-Z]{1}).
  , validation = if s == "alpha" then Otp.Alpha else Otp.Numeric
  , style = { root: cn "", input: cn "" }
  }

-- | form — the bare @radix-ui Form primitive (Radix Themes ships none, so NO rt-*
-- | classes; the golden is the unstyled primitive). A single required email field
-- | with a valueMissing + a typeMismatch Message, wrapped in a `<Box>` (inner rt-Box).
-- | `?s=serverInvalid` flips the field's serverInvalid prop (pure → data-invalid +
-- | aria-invalid); `?s=forceMatch` renders the valueMissing Message unconditionally
-- | (registers aria-describedby on first paint). The default (rest-valid/valueMissing)
-- | is the required-empty story; valueMissing fires when the driver clicks Submit.
formInput :: String -> Form.Input
formInput s = Form.defaultInput
  { submitLabel = [ HH.text "Submit" ]
  , fields =
      [ Form.defaultField
          { name = "email"
          , label = [ HH.text "Email" ]
          , inputType = "email"
          , required = true
          , serverInvalid = s == "serverInvalid"
          , messages =
              -- `?s=multiMessage` forceMatches BOTH messages → aria-describedby lists both ids
              -- in registration order (the multi-id describedby contract).
              [ { match: Form.ValueMissing
                , forceMatch: s == "forceMatch" || s == "multiMessage"
                , text: [ HH.text "This value is missing" ]
                }
              , { match: Form.TypeMismatch
                , forceMatch: s == "multiMessage"
                , text: [ HH.text "Provide a valid email" ]
                }
              ]
          }
      ]
  , style =
      { root: cn ""
      , field: cn ""
      , label: cn ""
      , control: cn ""
      , message: cn ""
      , submit: cn ""
      }
  }

-- | tabnav — themes-only AND at-rest (no Halogen component): rendered directly inline
-- | as the declarative active-link nav. Account is the active link.
tabNavPage :: forall w i. HH.HTML w i
tabNavPage =
  tabNavRoot []
    [ tabNavLink true "#account" [] [ HH.text "Account" ]
    , tabNavLink false "#documents" [] [ HH.text "Documents" ]
    , tabNavLink false "#settings" [] [ HH.text "Settings" ]
    ]

-- | The ThickCheckIcon as the bare Checkbox primitive's asChild indicator child -- it
-- | carries the standalone Checkbox indicator classes
-- | (`rt-BaseCheckboxIndicator rt-CheckboxIndicator`), `data-state="checked"`, and
-- | `style="pointer-events: none;"` (the merge upstream's CheckboxIndicator asChild
-- | performs onto its child).
thickCheckIconPlain :: HH.PlainHTML
thickCheckIconPlain = thickCheckIndicator "rt-BaseCheckboxIndicator rt-CheckboxIndicator"

-- | The ThickCheckIcon indicator svg with the given indicator class set, merging the
-- | asChild indicator props (class, data-state=checked, pointer-events:none) onto the
-- | icon svg -- exactly the node upstream's CheckboxIndicator emits. NB:
-- | SVGElement.className is a read-only SVGAnimatedString, so class/data-state must be
-- | set via setAttribute (HP.attr).
thickCheckIndicator :: String -> HH.PlainHTML
thickCheckIndicator indicatorClass =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") indicatorClass
    , HP.attr (HH.AttrName "data-state") "checked"
    , HP.attr (HH.AttrName "width") "9"
    , HP.attr (HH.AttrName "height") "9"
    , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
    , HP.attr (HH.AttrName "fill") "currentcolor"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    , HP.style "pointer-events: none;"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "fill-rule") "evenodd"
        , HP.attr (HH.AttrName "clip-rule") "evenodd"
        , HP.attr (HH.AttrName "d")
            "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
        ]
        []
    ]

-- | The down-chevron (radix's TriggerIcon / SelectIcon) — same 9×9 currentColor path
-- | upstream uses. Rendered in the SVG namespace so it paints. `chevron` is the bare
-- | menu-trigger icon; `chevronCls` adds a class (rt-SelectIcon for the select trigger).
chevron :: forall w i. HH.HTML w i
chevron = chevronCls ""

chevronCls :: forall w i. String -> HH.HTML w i
chevronCls klass =
  HH.elementNS svgNS (HH.ElemName "svg")
    -- a classed chevron is the SelectIcon (aria-hidden); the bare one is the menu TriggerIcon.
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
        [ HP.attr (HH.AttrName "d")
            "M0.135232 3.15803C0.324102 2.95657 0.640521 2.94637 0.841971 3.13523L4.5 6.56464L8.158 3.13523C8.3595 2.94637 8.6759 2.95657 8.8648 3.15803C9.0536 3.35949 9.0434 3.67591 8.842 3.86477L4.84197 7.6148C4.64964 7.7951 4.35036 7.7951 4.15803 7.6148L0.158031 3.86477C-0.0434285 3.67591 -0.0536285 3.35949 0.135232 3.15803Z"
        ]
        []
    ]

-- | The selected-option check (radix's ThickCheckIcon), with the indicator-icon class.
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
        , HP.attr (HH.AttrName "d")
            "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
        ]
        []
    ]

-- | The 15×15 Settings (gear) icon for the AccessibleIcon demo, authored already
-- | carrying `aria-hidden="true"` + `focusable="false"` ON the svg (upstream injects
-- | them onto the icon node via cloneElement) — so the rendered DOM matches the golden.
gearIcon :: forall w i. HH.HTML w i
gearIcon =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "width") "15"
    , HP.attr (HH.AttrName "height") "15"
    , HP.attr (HH.AttrName "viewBox") "0 0 15 15"
    , HP.attr (HH.AttrName "fill") "none"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    , HP.attr (HH.AttrName "aria-hidden") "true"
    , HP.attr (HH.AttrName "focusable") "false"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "fill-rule") "evenodd"
        , HP.attr (HH.AttrName "clip-rule") "evenodd"
        , HP.attr (HH.AttrName "fill") "currentColor"
        , HP.attr (HH.AttrName "d")
            "M7.07.65a1.5 1.5 0 0 0-1.14 0l-.69.29-.74-.18a1.5 1.5 0 0 0-1.07.2l-.6.43-.76.05a1.5 1.5 0 0 0-.98.55l-.42.6-.7.3a1.5 1.5 0 0 0-.78.78l-.3.7-.43.6a1.5 1.5 0 0 0-.2 1.07l.18.74-.29.69a1.5 1.5 0 0 0 0 1.14l.29.69-.18.74a1.5 1.5 0 0 0 .2 1.07l.43.6.3.7c.16.36.43.63.78.78l.7.3.42.6c.24.34.6.55.98.55l.76.05.6.43c.32.23.7.3 1.07.2l.74-.18.69.29c.36.15.78.15 1.14 0l.69-.29.74.18c.37.1.75.03 1.07-.2l.6-.43.76-.05c.38 0 .74-.21.98-.55l.42-.6.7-.3a1.5 1.5 0 0 0 .78-.78l.3-.7.43-.6c.23-.32.3-.7.2-1.07l-.18-.74.29-.69a1.5 1.5 0 0 0 0-1.14l-.29-.69.18-.74a1.5 1.5 0 0 0-.2-1.07l-.43-.6-.3-.7a1.5 1.5 0 0 0-.78-.78l-.7-.3-.42-.6a1.5 1.5 0 0 0-.98-.55l-.76-.05-.6-.43a1.5 1.5 0 0 0-1.07-.2l-.74.18L7.07.65ZM7.5 10a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"
        ]
        []
    ]

svgNS :: HH.Namespace
svgNS = HH.Namespace "http://www.w3.org/2000/svg"

-- ── ?c=<id> query param ─────────────────────────────────────────────────────────
queryParam :: String -> Effect String
queryParam key = do
  search <- HTML.window >>= Window.location >>= Location.search
  pure (lookupParam key search)

lookupParam :: String -> String -> String
lookupParam key search =
  let
    body = Str.drop 1 search
    pairs = splitOn "&" body
    match p = case Str.indexOf (Pattern "=") p of
      Just i -> let kv = Str.splitAt i p in if kv.before == key then Just (Str.drop 1 kv.after) else Nothing
      Nothing -> Nothing
  in
    fromMaybe "" (firstJust (map match pairs))

splitOn :: String -> String -> Array String
splitOn sep s = case Str.indexOf (Pattern sep) s of
  Nothing -> [ s ]
  Just i -> let kv = Str.splitAt i s in [ kv.before ] <> splitOn sep (Str.drop 1 kv.after)

firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust = case _ of
  [] -> Nothing
  xs -> case Array.find isJust xs of
    Just (Just a) -> Just a
    _ -> Nothing
  where
  isJust = case _ of
    Just _ -> true
    Nothing -> false
