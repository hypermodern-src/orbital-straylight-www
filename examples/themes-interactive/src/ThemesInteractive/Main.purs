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
import Hydrogen.Radix.AlertDialog as AlertDialog
import Hydrogen.Radix.ContextMenu as ContextMenu
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.DropdownMenu as DropdownMenu
import Hydrogen.Radix.Foundation.Style (Align(..), Side(..), cn, dataAttr)
import Hydrogen.Radix.HoverCard as HoverCard
import Hydrogen.Radix.Popover as Popover
import Hydrogen.Radix.Select as Select
import Hydrogen.Radix.Tooltip as Tooltip
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Prop (Prop(..))
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
  , select :: Select.Slot Unit
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

_select :: Proxy "select"
_select = Proxy

main :: Effect Unit
main = do
  c <- queryParam "c"
  HA.runHalogenAff do
    HA.awaitLoad
    mEl <- HA.selectElement (QuerySelector "#root")
    for_ mEl \el -> void (runUI (root c) unit el)

root :: forall q i o. String -> H.Component q i o Aff
root c =
  H.mkComponent
    { initialState: const unit
    , render: const (view c)
    , eval: H.mkEval H.defaultEval
    }

-- | The ROOT theme — a `<div class="radix-themes light" data-…>` inside #root, exactly as
-- | upstream nests it (the <body> stays bare). Each demo is then wrapped in `Box p="6"` as
-- | the golden wraps its pages. Portaled overlays re-apply the theme themselves (so adopted-
-- | to-body content stays themed) — see `portalThemeAttrs`.
view :: String -> H.ComponentHTML Void Slots Aff
view c =
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
            "dropdownmenu" -> HH.slot_ _dropdownmenu unit DropdownMenu.component dropdownMenuInput
            "contextmenu" -> HH.slot_ _contextmenu unit ContextMenu.component contextMenuInput
            "select" -> HH.slot_ _select unit Select.component selectInput
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
  , contentStyle = "--max-width: 300px;"
  , trigger = [ HH.text "@radix_ui" ]
  , content =
      [ textAs "div" [ Size "1", Color "gray" ]
          [ HH.text "The design system for building modern web applications." ]
      ]
  }

hoverCardStyle :: HoverCard.Style
hoverCardStyle =
  { trigger: cn "rt-reset rt-Text rt-Link rt-HoverCardTrigger rt-underline-auto"
  , content: cn "rt-HoverCardContent rt-PopperContent rt-r-max-w rt-r-size-2"
  }

-- | The themed DropdownMenu: a soft "Options" trigger opening a solid menu panel with
-- | items, ⌘-shortcuts, separators, and a red Delete (the upstream demo). Menus position
-- | via Popper, so defaultOpen stays false and the driver clicks open.
dropdownMenuInput :: DropdownMenu.Input
dropdownMenuInput = DropdownMenu.defaultInput
  { style = menuStyle
  , trigger = [ HH.text "Options", chevron ]
  , entries =
      [ menuRow "edit" "Edit" "⌘ E" ""
      , menuRow "duplicate" "Duplicate" "⌘ D" ""
      , DropdownMenu.menuSeparator
      , menuRow "archive" "Archive" "⌘ N" ""
      , DropdownMenu.menuSeparator
      , menuRow "delete" "Delete" "⌘ ⌫" "red"
      ]
  }

-- | One themed menu item: label + right-aligned shortcut + optional accent.
menuRow :: String -> String -> String -> String -> DropdownMenu.MenuEntry
menuRow value label shortcut accent =
  DropdownMenu.MenuItemEntry
    { value
    , label: [ HH.text label ]
    , shortcut: [ HH.text shortcut ]
    , accent
    , disabled: false
    }

-- | Radix Themes' DropdownMenu class vocabulary (from the open-state golden).
menuStyle :: DropdownMenu.Style
menuStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
  , content: cn "rt-BaseMenuContent rt-DropdownMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , viewport: cn "rt-BaseMenuViewport rt-DropdownMenuViewport"
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
  , trigger =
      [ flex
          [ Align "center", Justify "center", Width "240px", Height "120px"
          , StyleProp "border" "1px dashed var(--gray-6)", StyleProp "border-radius" "var(--radius-3)"
          ]
          [ textAs "span" [ Size "2", Color "gray" ] [ HH.text "Right-click here" ] ]
      ]
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
  { trigger: cn ""
  , content: cn "rt-BaseMenuContent rt-ContextMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"
  , viewport: cn "rt-BaseMenuViewport rt-ContextMenuViewport"
  , item: cn "rt-BaseMenuItem rt-ContextMenuItem rt-reset"
  , shortcut: cn "rt-BaseMenuShortcut rt-ContextMenuShortcut"
  , separator: cn "rt-BaseMenuSeparator rt-ContextMenuSeparator"
  }

-- | The themed Select: a surface trigger showing the selected value + chevron, opening a
-- | solid listbox with a "Fruits" group and a check indicator on the selected option.
-- | Apple is the default value. Listbox positions via Popper, so the driver clicks open.
selectInput :: Select.Input
selectInput = Select.defaultInput
  { defaultValue = "apple"
  , style = selectStyle
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
  , content: cn "rt-SelectContent rt-r-size-2 rt-variant-solid"
  , viewport: cn "rt-SelectViewport"
  , group: cn "rt-SelectGroup"
  , label: cn "rt-SelectLabel"
  , item: cn "rt-SelectItem"
  , indicator: cn "rt-SelectItemIndicator"
  , itemText: cn ""
  }

-- | The down-chevron (radix's TriggerIcon / SelectIcon) — same 9×9 currentColor path
-- | upstream uses. Rendered in the SVG namespace so it paints. `chevron` is the bare
-- | menu-trigger icon; `chevronCls` adds a class (rt-SelectIcon for the select trigger).
chevron :: forall w i. HH.HTML w i
chevron = chevronCls ""

chevronCls :: forall w i. String -> HH.HTML w i
chevronCls klass =
  HH.elementNS svgNS (HH.ElemName "svg")
    ( (if klass == "" then [] else [ HP.attr (HH.AttrName "class") klass ])
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
