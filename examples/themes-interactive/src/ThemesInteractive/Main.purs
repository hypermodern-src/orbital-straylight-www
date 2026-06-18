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
import Hydrogen.Radix.AspectRatio as AspectRatio
import Hydrogen.Radix.Label as Label
import Hydrogen.Radix.Separator as Separator
import Hydrogen.Radix.VisuallyHidden as VisuallyHidden
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
import Hydrogen.Themes.Avatar (avatar) as Avatar
import Hydrogen.Radix.Avatar as RadixAvatar
import Hydrogen.Themes.Progress (progress) as Progress
import Hydrogen.Radix.Progress (progress) as RadixProgress
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.TabNav (tabNavLink, tabNavRoot)
import Hydrogen.Themes.TextArea (textArea)
import Hydrogen.Themes.TextField (textField, textFieldValue)
import Hydrogen.Themes.Typography (textAs)
import Hydrogen.Themes.Separator (separator) as ThemesSeparator
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
  , dropdownmenuchecks :: DropdownMenu.Slot Unit
  , contextmenuchecks :: ContextMenu.Slot Unit
  , menubarchecks :: Menubar.Slot Unit
  , selectplaceholder :: Select.Slot Unit
  , avatarx :: RadixAvatar.Slot Unit
  , selectform :: Select.Slot Unit
  , dropdownmenugroup :: DropdownMenu.Slot Unit
  , sliderrange :: Slider.RangeSlot Unit
  , sliderrangeform :: Slider.RangeSlot Unit
  , labelguard :: Label.Slot Unit
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

_dropdownmenuchecks :: Proxy "dropdownmenuchecks"
_dropdownmenuchecks = Proxy

_contextmenuchecks :: Proxy "contextmenuchecks"
_contextmenuchecks = Proxy

_menubarchecks :: Proxy "menubarchecks"
_menubarchecks = Proxy

_selectplaceholder :: Proxy "selectplaceholder"
_selectplaceholder = Proxy
_avatarx :: Proxy "avatarx"
_avatarx = Proxy

_selectform :: Proxy "selectform"
_selectform = Proxy

_dropdownmenugroup :: Proxy "dropdownmenugroup"
_dropdownmenugroup = Proxy
_sliderrange :: Proxy "sliderrange"
_sliderrange = Proxy
_sliderrangeform :: Proxy "sliderrangeform"
_sliderrangeform = Proxy
_labelguard :: Proxy "labelguard"
_labelguard = Proxy

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
            "popover" -> HH.slot_ _popover unit Popover.component (popoverInput s)
            "tooltip" -> HH.slot_ _tooltip unit Tooltip.component tooltipInput
            "hovercard" -> HH.slot_ _hovercard unit HoverCard.component (hoverCardInput s)
            "dropdownmenu" -> HH.slot_ _dropdownmenu unit DropdownMenu.component (dropdownMenuInput s)
            "contextmenu" -> HH.slot_ _contextmenu unit ContextMenu.component (contextMenuInput s)
            "menubar" -> HH.slot_ _menubar unit Menubar.component (menubarInput s)
            "navigationmenu" -> HH.slot_ _navigationmenu unit NavigationMenu.component (navigationMenuInput s)
            "select" -> HH.slot_ _select unit Select.component selectInput
            "slider" ->
              -- `?s=vertical` swaps the wrapper to a fixed-height box (matching the golden's
              -- height:160 box) and drives the vertical-orientation slider; otherwise the
              -- horizontal max-width:320 box.
              if s == "vertical" then box [ StyleProp "height" "160px" ] [ HH.slot_ _slider unit Slider.component (sliderInput s) ]
              else box [ StyleProp "max-width" "320px" ] [ HH.slot_ _slider unit Slider.component (sliderInput s) ]
            "accordion" -> box [ StyleProp "max-width" "360px" ] [ HH.slot_ _accordion unit Accordion.component (accordionInput s) ]
            -- `?s=disabled` renders the Root disabled (data-disabled stamping). The primitive
            -- injects (via exitCss) the golden story's exit keyframe on the closing content so
            -- the port's Presence keeps it mounted through the pinned exit (the closing oracle's
            -- lingering node); <style> is in the normalizer SKIP set, so it never diffs.
            "collapsible" -> HH.slot_ _collapsible unit Collapsible.component (collapsibleInput s)
            "toast" -> HH.slot_ _toast unit Toast.component (toastInput s)
            "tabs" -> HH.slot_ _tabs unit Tabs.component (tabsInput s)
            "togglegroup" -> HH.slot_ _togglegroup unit ToggleGroup.component (toggleGroupInput s)
            "radiogroup" -> formWrap s (HH.slot_ _radiogroup unit RadioGroup.component (radioGroupInput s))
            "checkbox" -> formWrap s (HH.slot_ _checkbox unit Checkbox.component (checkboxInput s))
            "switch" -> formWrap s (HH.slot_ _switch unit Switch.component (switchInput s))
            "toggle" -> HH.slot_ _toggle unit Toggle.component (toggleInput s)
            "segmentedcontrol" -> HH.slot_ _segmentedcontrol unit ToggleGroup.component segmentedControlInput
            "checkboxgroup" -> checkboxGroupPage
            "radiocards" -> HH.slot_ _radiocards unit RadioGroup.component radioCardsInput
            "checkboxcards" -> checkboxCardsPage
            -- `Align` is ambiguous here (Prop.Align vs Foundation.Style.Align in scope),
            -- so spell the flex align class directly: align="center" → rt-r-ai-center.
            "accessibleicon" -> flex [ Class "rt-r-ai-center" ] (AccessibleIcon.accessibleIcon "Settings" gearIcon)
            -- fallback-only avatar (no src): the at-rest error/fallback branch — a single
            -- rt-AvatarFallback span, NO <img>. Matches `<Avatar fallback="A" />`.
            -- `?s=loaded` swaps to the Radix Avatar primitive with a data-URI src + rt-*
            -- classes: the LOADED steady-state (img mounted, alt, fallback gone, no
            -- data-state on the img). Else the fallback-only Themes Avatar.
            "avatar" | s == "loaded" -> HH.slot_ _avatarx unit RadixAvatar.component avatarLoadedInput
            -- `?s=loadedattrs` (wave D): the loaded steady-state plus img-attr passthrough
            -- (referrerPolicy/crossOrigin rest-spread onto the <img>).
            "avatar" | s == "loadedattrs" -> HH.slot_ _avatarx unit RadixAvatar.component avatarLoadedAttrsInput
            "avatar" -> Avatar.avatar "A" []
            "progress" -> box [ StyleProp "max-width" "320px" ] [ progressVariant s ]
            "scrollarea" -> HH.slot_ _scrollarea unit ScrollArea.component scrollAreaInput
            "tabnav" -> tabNavPage
            "passwordtoggle" -> passwordTogglePage s
            "toolbar" -> HH.slot_ _toolbar unit Toolbar.component (toolbarInput s)
            "otp" -> box [] [ HH.slot_ _otp unit Otp.component (otpInput s) ]
            "form" -> box [] [ HH.slot_ _form unit Form.component (formInput s) ]
            -- Wave-B stateless depth oracles: the bare Hydrogen.Radix primitives, driven
            -- into at-rest variant stories by `s`. DOM (role/aria/data-*/inline-style) is
            -- the oracle, diffed node-for-node against the bare @radix-ui/react-* golden.
            "separatorprim" -> separatorPrimPage s
            "aspectratioprim" -> aspectRatioPrimPage s
            "visuallyhiddenprim" -> visuallyHiddenPrimPage s
            "labelprim" -> labelPrimPage
            -- Wave-C menus depth: a SECOND DropdownMenu exercising CheckboxItem / RadioItem
            -- (defaultOpen, ?s=checkbox|radio). Distinct slot/id so the existing dropdownmenu
            -- oracles are untouched.
            "dropdownmenuchecks" -> HH.slot_ _dropdownmenuchecks unit DropdownMenu.component (dropdownChecksInput s)
            "contextmenuchecks" -> HH.slot_ _contextmenuchecks unit ContextMenu.component (contextChecksInput s)
            "menubarchecks" -> HH.slot_ _menubarchecks unit Menubar.component (menubarChecksInput s)
            "selectplaceholder" -> HH.slot_ _selectplaceholder unit Select.component selectPlaceholderInput
            -- Wave-C: Tabs activationMode="manual" — arrows move focus only, Enter/Space
            -- activates the focused trigger. Separate route so the existing automatic-mode
            -- `tabs` story stays byte-identical.
            "tabsmanual" -> HH.slot_ _tabs unit Tabs.component (tabsManualInput s)
            -- Wave-C ToggleGroup depth stories: group-disabled, loop=false, vertical.
            "togglegroupdisabled" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupDisabledInput
            "togglegroupnoloop" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupNoLoopInput
            "togglegroupvert" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupVertInput
            -- Wave-C Accordion: type=single COLLAPSIBLE (open trigger closeable, NOT aria-disabled).
            "accordioncollapsible" -> box [ StyleProp "max-width" "360px" ] [ HH.slot_ _accordion unit Accordion.component accordionCollapsibleInput ]
            -- Wave-C Toolbar: loop=false end-stop + a type=multiple toggle group (aria-pressed).
            "toolbarnoloop" -> HH.slot_ _toolbar unit Toolbar.component toolbarNoLoopInput
            "toolbarmultiple" -> HH.slot_ _toolbar unit Toolbar.component toolbarMultipleInput
            -- Wave-C ScrollArea family: ?s=horizontal → one horizontal bar; ?s=both → two
            -- bars + corner. Same primitive, the `scrollbars` field selects the family.
            "scrollareax" -> HH.slot_ _scrollarea unit ScrollArea.component (scrollAreaXInput s)
            "separatorthemes" -> separatorThemesPage s
            -- Wave-D menus depth: Select FORM integration. Wrapped in a <form> so the port
            -- renders the hidden native <select> (BubbleSelect); `?s=required` (aria-required
            -- + required bubble) / `?s=disabledtrigger` (disabled trigger + disabled bubble).
            "selectform" -> HH.form [] [ HH.slot_ _selectform unit Select.component (selectFormInput s) ]
            -- Wave-D menus depth: DropdownMenu Group/Label parts (two labelled groups).
            "dropdownmenugroup" -> HH.slot_ _dropdownmenugroup unit DropdownMenu.component dropdownGroupInput
            -- Wave-D: Toast swipeDirection="up" variant (data-swipe-direction=up).
            "toast-up" -> HH.slot_ _toast unit Toast.component toastUpInput
            -- Wave-D Tabs depth: vertical orientation, RTL (swapped horizontal arrows), and the
            -- zero-selected (no defaultValue → '') contract. All reuse the _tabs slot (one page
            -- renders at a time), separate routes so the `tabs` story stays byte-identical.
            "tabsvert" -> HH.slot_ _tabs unit Tabs.component tabsVertInput
            "tabsrtl" -> HH.slot_ _tabs unit Tabs.component tabsRtlInput
            "tabsnone" -> HH.slot_ _tabs unit Tabs.component tabsNoneInput
            -- Wave-D Accordion horizontal, ToggleGroup rtl, Toolbar rtl depth stories.
            "accordionhoriz" -> box [ StyleProp "max-width" "360px" ] [ HH.slot_ _accordion unit Accordion.component accordionHorizInput ]
            "togglegrouprtl" -> HH.slot_ _togglegroup unit ToggleGroup.component toggleGroupRtlInput
            "toolbarrtl" -> HH.slot_ _toolbar unit Toolbar.component toolbarRtlInput
            -- Wave-D multi-thumb / range slider: ?s=triple → 3 thumbs (Value n of m
            -- labelling); ?s=minsteps → minStepsBetweenThumbs keyboard rejection; default
            -- → the 2-thumb [25,75] range (Minimum/Maximum, range between the thumbs).
            "sliderrange" -> box [ StyleProp "max-width" "320px" ] [ HH.slot_ _sliderrange unit Slider.rangeComponent (sliderRangeInput s) ]
            -- STR-330: named range slider inside a <form> → one hidden SliderBubbleInput
            -- (`<input style=display:none name="band[]">`) per thumb, sibling of each thumb.
            "sliderrangeform" -> HH.form [] [ box [ StyleProp "max-width" "320px" ] [ HH.slot_ _sliderrangeform unit Slider.rangeComponent (sliderRangeFormInput s) ] ]
            -- Wave-D Label depth: the onMouseDown text-selection guard (label.tsx:19-27)
            -- as a self-contained component. ?s=plain → bare label (detail>1 ⇒ preventDefault);
            -- ?s=control → label WRAPPING an input (mousedown inside it ⇒ early return, NO
            -- preventDefault). The DOM is a <label>+children; the guard is driver-adjudicated.
            "labelguard" -> HH.slot_ _labelguard unit Label.component (labelGuardInput s)
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
-- | ?s=close adds a `Popover.Close` "Comment" submit button (size 1) below the textarea —
-- | a click closes the popover + restores focus (PopoverClose). Every other `s` renders the
-- | original textarea-only content (matching the default golden). Append-only: a new branch
-- | inside this one binding, no existing case line touched.
popoverInput :: String -> Popover.Input
popoverInput s = Popover.defaultInput
  { align = Start
  , style = popoverStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "--width: 360px; --max-width: 9999px; " <> popperContentVars "popover"
  , trigger = [ HH.text "Comment" ]
  , closeLabels = if s == "close" then [ "Comment" ] else []
  , content =
      [ flex [ Gap "3" ]
          [ box [ Class "rt-r-fg-1" ]
              ( [ textArea "Write a comment…" [ Height "80px" ] ]
                  <> ( if s == "close" then
                        [ flex [ Gap "3", Mt "3", Justify "end" ]
                            [ button [ Size "1" ] [ HH.text "Comment" ] ]
                        ]
                      else []
                     )
              )
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
hoverCardInput :: String -> HoverCard.Input
hoverCardInput s = HoverCard.defaultInput
  { align = Start
  -- Radix Themes' HoverCard wrapper pins openDelay=200/closeDelay=150 (not the bare
  -- primitive's 700/300) — match it so the open/close timing tracks the Themes golden.
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
  -- ?s=richcontent → a card holding a tabbable <a> (which the open effect must remove from the
  -- tab order, tabindex=-1). Any other path renders the plain prose (the canonical open oracle).
  , content =
      if s == "richcontent" then
        [ textAs "div" [ Size "1", Color "gray" ]
            [ HH.text "See the "
            , HH.a
                [ HP.href "https://radix-ui.com"
                , HP.class_ (HH.ClassName "rt-Link rt-Text rt-reset rt-underline-auto")
                , HP.attr (HH.AttrName "data-accent-color") ""
                ]
                [ HH.text "docs" ]
            , HH.text " for details."
            ]
        ]
      else
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
  -- the SubContent orders pointer-events BEFORE the popper var aliases (a Themes quirk).
  , subContentStyle = "outline: none; pointer-events: auto; " <> popperContentVars "dropdown-menu"
  , trigger = [ HH.text "Options", chevron ]
  , entries =
      -- `?s=disabled` disables the SECOND item (Duplicate) so the APG disabled-skip
      -- check proves roving navigation skips OVER it to Archive.
      [ menuRow "edit" "Edit" "⌘ E" "" false
      , menuRow "duplicate" "Duplicate" "⌘ D" "" (s == "disabled")
      , DropdownMenu.menuSeparator
      , menuRow "archive" "Archive" "⌘ N" "" false
      ]
        -- `?s=submenu` → a SubTrigger ("More") opening a SubContent of 3 plain items.
        <> (if s == "submenu" then [ submenuEntry ] else [])
        <> [ DropdownMenu.menuSeparator
           , menuRow "delete" "Delete" "⌘ ⌫" "red" false
           ]
  }

-- | The `?s=submenu` submenu: a SubTrigger "More" with three plain (no-shortcut) items.
submenuEntry :: DropdownMenu.MenuEntry
submenuEntry = DropdownMenu.menuSub "more" [ HH.text "More" ]
  [ plainRow "move-project" "Move to project…"
  , plainRow "move-folder" "Move to folder…"
  , DropdownMenu.menuSeparator
  , plainRow "advanced" "Advanced options…"
  ]

-- | A menu item with NO shortcut (the SubContent items carry no shortcut div, unlike menuRow
-- | whose `[HH.text ""]` would render an empty one).
plainRow :: String -> String -> DropdownMenu.MenuEntry
plainRow value label =
  DropdownMenu.MenuItemEntry { value, label: [ HH.text label ], shortcut: [], accent: "", disabled: false }

-- | The SubTrigger chevron (right-pointing caret) — the Radix Themes SubTriggerIcon svg, with a
-- | caller-supplied icon class (DropdownMenu uses `rt-DropdownMenuSubtriggerIcon` (lowercase t),
-- | ContextMenu `rt-ContextMenuSubTriggerIcon` (capital T) — a real Themes inconsistency).
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
  -- Radix Themes quirk: the CHECKBOX indicator icon carries `rt-ContextMenuItemIndicatorIcon`
  -- (shared icon styling), while the RADIO indicator icon carries `rt-DropdownMenuItemIndicatorIcon`.
  , checkIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-ContextMenuItemIndicatorIcon" ]
  , radioIndicator: [ menuIndicatorIcon "rt-BaseMenuItemIndicatorIcon rt-DropdownMenuItemIndicatorIcon" ]
  }

-- | The ItemIndicator icon svg (the check mark) with a caller-supplied class. No data-state
-- | / style on the svg itself — the gated wrapper <span> carries data-state (matches the golden).
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
    [ thickCheckPath ]

-- | The Wave-C DropdownMenu-checks story: a defaultOpen menu whose `?s=` selects a CheckboxItem
-- | pair (one checked, one unchecked) or a RadioGroup (medium selected). Reuses menuStyle so the
-- | content/trigger chrome matches the canonical dropdownmenu; only the entries differ.
dropdownChecksInput :: String -> DropdownMenu.Input
dropdownChecksInput s = DropdownMenu.defaultInput
  { style = menuStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "dropdown-menu" <> " pointer-events: auto;"
  , trigger = [ HH.text "View", chevron ]
  , entries =
      if s == "radio" then
        [ DropdownMenu.MenuRadioGroupEntry
            { value: "medium"
            , options:
                [ { value: "small", label: [ HH.text "Small" ], shortcut: [], disabled: false }
                , { value: "medium", label: [ HH.text "Medium" ], shortcut: [], disabled: false }
                , { value: "large", label: [ HH.text "Large" ], shortcut: [], disabled: false }
                ]
            }
        ]
      else
        [ DropdownMenu.MenuCheckboxEntry { value: "toolbar", label: [ HH.text "Show Toolbar" ], shortcut: [], check: DropdownMenu.Checked, disabled: false }
        , DropdownMenu.MenuCheckboxEntry { value: "sidebar", label: [ HH.text "Show Sidebar" ], shortcut: [], check: DropdownMenu.Unchecked, disabled: false }
        ]
  }

-- | The themed ContextMenu: a dashed right-click area opening a solid menu panel. The
-- | dashed box is the trigger CONTENT (its border is inline style the classes-only Style
-- | can't carry); the primitive's wrapper div carries the contextmenu handler + data-state.
-- | NOTE: the menu anchors to the trigger element (below it), not the cursor point — true
-- | point-anchoring is the documented Float.Popper follow-up (STR-336).
contextMenuInput :: String -> ContextMenu.Input
contextMenuInput s = ContextMenu.defaultInput
  { side = Right   -- radix point-anchors the menu to the right of the cursor (data-side=right)
  , style = contextMenuStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "context-menu" <> " pointer-events: auto;"
  , subContentStyle = "outline: none; pointer-events: auto; " <> popperContentVars "context-menu"
  -- the trigger AREA is the dashed box itself (rt-Flex classes via style.trigger, size/border
  -- via triggerStyle, the text as its content) — radix's asChild Trigger, one element.
  , triggerStyle = "width: 240px; height: 120px; border: 1px dashed var(--gray-6); border-radius: var(--radius-3);"
  , trigger = [ textAs "span" [ Size "2", Color "gray" ] [ HH.text "Right-click here" ] ]
  , entries =
      -- `?s=disabled` disables the SECOND item (Duplicate) so the APG disabled-skip
      -- check proves roving navigation skips it (menu.tsx:540 filter(!disabled)).
      [ ctxRow "edit" "Edit" "⌘ E" "" false
      , ctxRow "duplicate" "Duplicate" "⌘ D" "" (s == "disabled")
      , ContextMenu.menuSeparator
      ]
        -- `?s=submenu` → a SubTrigger ("More") opening a SubContent of 3 plain items.
        <> (if s == "submenu" then [ ctxSubmenuEntry ] else [])
        <> [ ctxRow "delete" "Delete" "⌘ ⌫" "red" false ]
  }

ctxSubmenuEntry :: ContextMenu.MenuEntry
ctxSubmenuEntry = ContextMenu.menuSub "more" [ HH.text "More" ]
  [ ContextMenu.MenuItemEntry { value: "move-project", label: [ HH.text "Move to project…" ], shortcut: [], accent: "", disabled: false }
  , ContextMenu.MenuItemEntry { value: "move-folder", label: [ HH.text "Move to folder…" ], shortcut: [], accent: "", disabled: false }
  , ContextMenu.menuSeparator
  , ContextMenu.MenuItemEntry { value: "advanced", label: [ HH.text "Advanced options…" ], shortcut: [], accent: "", disabled: false }
  ]

ctxRow :: String -> String -> String -> String -> Boolean -> ContextMenu.MenuEntry
ctxRow value label shortcut accent disabled =
  ContextMenu.MenuItemEntry
    { value, label: [ HH.text label ], shortcut: [ HH.text shortcut ], accent, disabled }

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

-- | The Wave-C ContextMenu-checks story: a right-click menu whose `?s=` selects a CheckboxItem
-- | pair or a RadioGroup. Reuses contextMenuStyle so the chrome matches the canonical contextmenu.
contextChecksInput :: String -> ContextMenu.Input
contextChecksInput s = ContextMenu.defaultInput
  { side = Right
  , style = contextMenuStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "context-menu" <> " pointer-events: auto;"
  , triggerStyle = "width: 240px; height: 120px; border: 1px dashed var(--gray-6); border-radius: var(--radius-3);"
  , trigger = [ textAs "span" [ Size "2", Color "gray" ] [ HH.text "Right-click here" ] ]
  , entries =
      if s == "radio" then
        [ ContextMenu.MenuRadioGroupEntry
            { value: "medium"
            , options:
                [ { value: "small", label: [ HH.text "Small" ], shortcut: [], disabled: false }
                , { value: "medium", label: [ HH.text "Medium" ], shortcut: [], disabled: false }
                , { value: "large", label: [ HH.text "Large" ], shortcut: [], disabled: false }
                ]
            }
        ]
      else
        [ ContextMenu.MenuCheckboxEntry { value: "toolbar", label: [ HH.text "Show Toolbar" ], shortcut: [], check: ContextMenu.Checked, disabled: false }
        , ContextMenu.MenuCheckboxEntry { value: "sidebar", label: [ HH.text "Show Sidebar" ], shortcut: [], check: ContextMenu.Unchecked, disabled: false }
        ]
  }

-- | menubar — the bare @radix-ui Menubar primitive (Radix Themes ships none, so NO rt-*
-- | classes; the golden is the unstyled primitive). A horizontal roving bar of three menus
-- | (File/Edit/View); File's menu has New Tab / New Window / sep / Print, the same structure
-- | and labels as the golden story. Bare ⇒ every Style slot empty, no portalAttrs. The content
-- | style carries outline:none + the `--radix-menubar-*` popper var aliases (NO pointer-events:
-- | the menus are modal={false}, so no scroll-lock/pointer block — see Menubar's non-modal env).
menubarInput :: String -> Menubar.Input
menubarInput s = Menubar.defaultInput
  { align = Start
  , contentStyle = "outline: none; " <> popperContentVars "menubar"
  , menus =
      [ { value: "file"
        , trigger: [ HH.text "File" ]
        , entries:
            -- `?s=disabled` disables "New Window" so the APG disabled-skip check proves
            -- vertical roving skips it (react-menu filter(!disabled)).
            [ Menubar.menuItem "new-tab" [ HH.text "New Tab" ]
            , Menubar.MenuItemEntry { value: "new-window", label: [ HH.text "New Window" ], shortcut: [], accent: "", disabled: s == "disabled" }
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

-- | The Wave-C Menubar-checks story: a single "View" menu whose `?s=` selects a CheckboxItem
-- | pair (one checked) or a RadioGroup (medium selected). Bare primitive ⇒ empty Style classes;
-- | the ItemIndicator content is a "✓" text child (matching the golden story), gated on checked.
menubarChecksInput :: String -> Menubar.Input
menubarChecksInput s = Menubar.defaultInput
  { align = Start
  , contentStyle = "outline: none; " <> popperContentVars "menubar"
  , style = Menubar.defaultStyle { checkIndicator = [ HH.text "✓" ], radioIndicator = [ HH.text "✓" ] }
  , menus =
      [ { value: "view"
        , trigger: [ HH.text "View" ]
        , entries:
            if s == "radio" then
              [ Menubar.MenuRadioGroupEntry
                  { value: "medium"
                  , options:
                      [ { value: "small", label: [ HH.text "Small" ], shortcut: [], disabled: false }
                      , { value: "medium", label: [ HH.text "Medium" ], shortcut: [], disabled: false }
                      , { value: "large", label: [ HH.text "Large" ], shortcut: [], disabled: false }
                      ]
                  }
              ]
            else
              [ Menubar.MenuCheckboxEntry { value: "toolbar", label: [ HH.text "Show Toolbar" ], shortcut: [], check: Menubar.Checked, disabled: false }
              , Menubar.MenuCheckboxEntry { value: "sidebar", label: [ HH.text "Show Sidebar" ], shortcut: [], check: Menubar.Unchecked, disabled: false }
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
  { defaultValue = if s == "open" || s == "clicktoggle" || s == "vertical" || s == "rtl" then "one" else ""
  , orientation = if s == "vertical" then Vertical else Horizontal
  -- Wave-D: ?s=rtl drives dir=RTL (the FocusGroup swaps the horizontal roving keys + the
  -- dir attribute is stamped on the nav/list/content). Every other path stays LTR.
  , dir = if s == "rtl" then RTL else LTR
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

-- | The Wave-C Select-placeholder story: NO defaultValue + a placeholder, so the at-rest
-- | trigger shows "Pick a fruit…" and carries data-placeholder. Reuses selectStyle.
selectPlaceholderInput :: Select.Input
selectPlaceholderInput = Select.defaultInput
  { style = selectStyle
  , portalAttrs = portalThemeAttrs
  , contentStyle = "box-sizing: border-box; max-height: 100%; display: flex; flex-direction: column; outline: none; pointer-events: auto;"
  , trigger = [ chevronCls "rt-SelectIcon" ]
  , groupLabel = [ HH.text "Fruits" ]
  , checkIcon = [ checkSvg ]
  , placeholder = [ HH.text "Pick a fruit…" ]
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
  , orientation = if s == "vertical" then Vertical else Horizontal
  , style =
      { root: cn "rt-SliderRoot rt-r-size-2 rt-variant-surface"
      , track: cn "rt-SliderTrack"
      , range: cn "rt-SliderRange"
      , thumb: cn "rt-SliderThumb"
      }
  }

-- | progress variants — the `?s` value/max contract states the at-rest pixel oracle never
-- | exercised. `shown`/default → the themed `Progress.progress 25 []` (byte-identical to the
-- | committed shown golden). The named variants drive the Radix primitive directly with the
-- | themed rt-ProgressRoot/Indicator classes + the matching `--progress-*` custom props upstream
-- | Themes stamps: indeterminate (no value → no style, no aria-valuenow/data-value), complete
-- | (value===max=100 → data-state=complete), custommax (max=200,value=50 → aria-valuemax=200,
-- | aria-valuetext=25%, BOTH --progress-value AND --progress-max).
progressVariant :: forall w i. String -> HH.HTML w i
progressVariant s = case s of
  "indeterminate" -> prim Nothing 100.0 ""
  "complete" -> prim (Just 100.0) 100.0 "--progress-value: 100;"
  "custommax" -> prim (Just 50.0) 200.0 "--progress-value: 50; --progress-max: 200;"
  -- `?s=invalid` — value=150 > max=100: the primitive's validValue clamps the ARIA to
  -- indeterminate (data-state=indeterminate, NO aria-valuenow/data-value), but the Themes
  -- wrapper still stamps --progress-value from the RAW value (upstream parity).
  "invalid" -> prim (Just 150.0) 100.0 "--progress-value: 150;"
  -- `?s=accent` — explicit color + radius: the themes wrapper stamps data-accent-color
  -- + data-radius on the root (the default omits both). Same surface variant + value.
  "accent" -> primA (Just 25.0) 100.0 "--progress-value: 25;" "cyan" "full"
  _ -> Progress.progress 25 []
  where
  prim mv mx styl = RadixProgress.progress
    { value: mv
    , max: mx
    , class_: cn "rt-ProgressRoot rt-r-size-2 rt-variant-surface"
    , indicator: cn "rt-ProgressIndicator"
    , rootAttrs: if styl == "" then [] else [ HP.style styl ]
    }
  primA mv mx styl accent rad = RadixProgress.progress
    { value: mv
    , max: mx
    , class_: cn "rt-ProgressRoot rt-r-size-2 rt-variant-surface"
    , indicator: cn "rt-ProgressIndicator"
    , rootAttrs:
        [ HP.attr (HH.AttrName "data-accent-color") accent
        , HP.attr (HH.AttrName "data-radius") rad
        , HP.style styl
        ]
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
      , corner: cn "rt-ScrollAreaCorner"
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
  -- `?s=single` → type="single" NON-collapsible with item-1 open: the open trigger can't be
  -- closed, so it carries aria-disabled=true (accordion.tsx:452). Else type="multiple" closed.
  , single = s == "single"
  , collapsible = false
  , defaultValue = if s == "single" then [ "item-1" ] else []
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
collapsibleInput :: String -> Collapsible.Input
collapsibleInput s = Collapsible.defaultInput
  -- `?s=controlled` (wave D): the parent OWNS open (open = Just true) and never updates it,
  -- so clicking the trigger fires onOpenChange but the content STAYS open (controlled-mode
  -- contract). All other states are uncontrolled (open = Nothing).
  { open = if s == "controlled" then Just true else Nothing
  , defaultOpen = false
  , disabled = s == "disabled"
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
  -- mirror the golden story's exit keyframe on the closing content so the closing li lingers
  -- (see CLOSE.collapsible / themes-closing-dom CLOSED_SEL). <style> is in the normalizer SKIP set.
  , exitCss = "@keyframes collapsibleExit { from { opacity: 1 } to { opacity: 0 } } div[data-state=\"closed\"][id] { animation: collapsibleExit 100ms ease-out; }"
  }

-- | toast — the BARE @radix-ui Toast primitive (Radix Themes ships none, so NO rt-* classes;
-- | EMPTY style slots, same as the golden's unstyled story). Rendered UNCONTROLLED (open=
-- | Nothing, defaultOpen=true → mounted open at first paint, internal open live so Escape can
-- | close it) so it matches the golden's open AND closing oracle. The announce mirror text is
-- | the literal upstream string ("Notification" label + the concatenated visible non-excluded
-- | part text) — supplied here since PlainHTML is not introspectable. Same structure/labels as
-- | the golden: Title "Scheduled", Description "Friday at 5pm", Action "Undo" (altText="Undo"),
-- | Close "×" (aria-label "Close").
toastInput :: String -> Toast.Input
toastInput s = Toast.defaultInput
  { open = Nothing
  , defaultOpen = true
  -- `?s=autodismiss` → a finite 400ms auto-dismiss (matches the golden story); any other
  -- state holds it open (Nothing) for the stable open/closing DOM oracle.
  , duration = if s == "autodismiss" then Just 1500 else Nothing
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
-- | `?s=disabled-skip` disables the MIDDLE tab (Documents) so the APG roving check proves
-- | ArrowRight skips OVER it (keyboard-only — no new DOM golden).
tabsInput :: String -> Tabs.Input
tabsInput s = Tabs.defaultInput
  { tabs =
      [ { value: "account", label: tabsTriggerLabel "Account", content: [ textAs "span" [ Size "2" ] [ HH.text "Make changes to your account." ] ], disabled: false }
      , { value: "documents", label: tabsTriggerLabel "Documents", content: [ textAs "span" [ Size "2" ] [ HH.text "Access and update your documents." ] ], disabled: s == "disabled-skip" }
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
radioGroupInput :: String -> RadioGroup.Input
radioGroupInput s = RadioGroup.defaultInput
  { items =
      -- `?s=keys`/`?s=mixed` → the 3-item disabled-skip fixture (middle item disabled);
      -- `?s=loopoff`/`?s=rtl` → 3-item groups (all enabled) for end-stop / RTL roving;
      -- `?s=alldisabled` → 2-item group with EVERY item disabled (root tabindex=-1);
      -- otherwise the committed 2-item group the `checked` driver exercises.
      if s == "keys" || s == "mixed" then
        [ { value: "1", label: [ HH.text " Default" ], disabled: false }
        , { value: "2", label: [ HH.text " Comfortable" ], disabled: true }
        , { value: "3", label: [ HH.text " Compact" ], disabled: false }
        ]
      else if s == "loopoff" || s == "rtl" then
        [ { value: "1", label: [ HH.text " Default" ], disabled: false }
        , { value: "2", label: [ HH.text " Comfortable" ], disabled: false }
        , { value: "3", label: [ HH.text " Compact" ], disabled: false }
        ]
      else if s == "alldisabled" then
        [ { value: "1", label: [ HH.text " Default" ], disabled: true }
        , { value: "2", label: [ HH.text " Comfortable" ], disabled: true }
        ]
      else
        [ { value: "1", label: [ HH.text " Default" ], disabled: false }
        , { value: "2", label: [ HH.text " Comfortable" ], disabled: false }
        ]
  , defaultValue = Just "1"
  -- `?s=disabledgroup` → the whole group disabled; `?s=horizontal`/`?s=rtl` → horizontal.
  , disabled = s == "disabledgroup"
  -- `?s=rtl` is a horizontal group under dir=rtl (the live arrows swap); `?s=loopoff`
  -- stays vertical (Up/Down clamp). `?s=alldisabled` is the default vertical orientation.
  , orientation = if s == "horizontal" || s == "rtl" then Horizontal else Vertical
  , explicitOrientation = s == "horizontal" || s == "rtl"
  -- `?s=rtl` → dir=rtl so RovingFocus swaps the horizontal arrows.
  , dir = if s == "rtl" then RTL else LTR
  -- `?s=loopoff` → loop disabled: arrow keys clamp at the ends instead of wrapping.
  , loop = s /= "loopoff"
  , itemIds = false
  , labelOutside = true
  -- `?s=form` (Wave C): name + required, inside a <form> → per-item hidden bubble inputs.
  , name = if s == "form" then "plan" else ""
  , required = s == "form"
  , isFormControl = s == "form"
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
-- | `?s=indeterminate` → the mixed state (divider indicator, data-state=indeterminate);
-- | `?s=disabled` → checked + disabled (the indicator carries data-disabled='' too).
checkboxInput :: String -> Checkbox.Input
checkboxInput s = Checkbox.defaultInput
  -- `?s=controlled` (Wave D): a CONTROLLED checkbox (checked pinned Checked, no parent
  -- update) — a click/Space fires onCheckedChange but must NOT mutate the DOM (aria-checked
  -- / data-state stay checked, the indicator stays mounted). Other states are uncontrolled.
  { checked = if s == "controlled" then Just Checkbox.Checked else Nothing
  , defaultChecked = case s of
      "indeterminate" -> Checkbox.Indeterminate
      "disabled" -> Checkbox.Checked
      -- `?s=form` (Wave C): checked + required, inside a <form> → the hidden bubble input.
      "form" -> Checkbox.Checked
      _ -> Checkbox.Unchecked
  , disabled = s == "disabled"
  -- `?s=form` matches the golden story's name/value/required on a checked checkbox.
  , required = s == "form"
  , name = if s == "form" then "agree" else ""
  , value = if s == "form" then "yes" else "on"
  -- isFormControl=true for `?s=form` so the port renders the hidden bubble
  -- <input type=checkbox aria-hidden tabindex=-1 checked> sibling (the form story
  -- wraps the slot in a <form>, exactly as upstream resolves isFormControl post-mount).
  , isFormControl = s == "form"
  , style =
      { root: cn "rt-reset rt-BaseCheckboxRoot rt-CheckboxRoot rt-r-size-2 rt-variant-surface"
      , indicator: cn "rt-BaseCheckboxIndicator rt-CheckboxIndicator"
      }
  , children = case s of
      "indeterminate" -> [ checkIndicatorWith "indeterminate" false dividerPath ]
      "disabled" -> [ checkIndicatorWith "checked" true thickCheckPath ]
      -- controlled is checked-at-rest, so the indicator is mounted with data-state=checked.
      "controlled" -> [ checkIndicatorWith "checked" false thickCheckPath ]
      "form" -> [ thickCheckIconPlain ]
      _ -> [ thickCheckIconPlain ]
  }

-- | switch — a single OFF Themes switch; the driver clicks to turn it on. `?s=disabled`
-- | seeds the disabled no-op variant; `?s=required` documents aria-required=true.
switchInput :: String -> Switch.Input
switchInput s = Switch.defaultInput
  -- `?s=controlled` (Wave D): a CONTROLLED switch (checked pinned true, no parent update) —
  -- a click fires onCheckedChange but must NOT mutate the DOM (data-state stays checked).
  { checked = if s == "controlled" then Just true else Nothing
  -- `?s=form` (Wave C): a checked + required switch inside a <form> → the hidden bubble input.
  , defaultChecked = s == "form"
  , disabled = s == "disabled"
  , required = s == "required" || s == "form"
  , name = if s == "form" then "notify" else ""
  , value = "on"
  , isFormControl = s == "form"
  , style =
      { root: cn "rt-reset rt-SwitchRoot rt-r-size-2 rt-variant-surface"
      , thumb: cn "rt-SwitchThumb"
      }
  }

-- | toggle — a soft "B" toggle, unpressed; the driver clicks to press. `?s=disabled`
-- | seeds the disabled (no-op + data-disabled='') variant.
toggleInput :: String -> Toggle.Input
toggleInput s = Toggle.defaultInput
  -- `?s=controlled` (Wave D): a CONTROLLED toggle (pressed pinned true, the parent never
  -- updates it) — a click fires onPressedChange but must NOT mutate the DOM (data-state /
  -- aria-pressed stay on). Every other state is uncontrolled (pressed = Nothing).
  { pressed = if s == "controlled" then Just true else Nothing
  -- `?s=disabledpressed` (Wave C): start pressed AND disabled (the locked-on combination).
  , defaultPressed = s == "disabledpressed"
  , disabled = s == "disabled" || s == "disabledpressed"
  , ariaLabel = Just "Bold"
  , style = { root: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft" }
  , children = [ HH.text "B" ]
  }

-- | togglegroup — the bare @radix-ui ToggleGroup primitive (no Radix Themes wrapper),
-- | single-select, Center pre-pressed; the driver clicks the first item (Left). The
-- | upstream nodes are classless, so the Style is empty to match.
-- | `?s=disabled-skip` disables the MIDDLE item (b/Center) so the APG roving check proves
-- | arrows skip OVER it; `?s=multiple` renders type=multiple (items keep aria-pressed, NOT
-- | role=radio) with two items pressed. Every other state is the canonical single-mode
-- | instance (Center pre-pressed) the pressed oracle pins.
toggleGroupInput :: String -> ToggleGroup.Input
toggleGroupInput s
  | s == "multiple" = ToggleGroup.defaultInput
      { single = false
      , defaultValue = [ "a", "c" ]
      , ariaLabel = Just "Text formatting"
      , items =
          [ { value: "a", label: [ HH.text "Bold" ], disabled: false }
          , { value: "b", label: [ HH.text "Italic" ], disabled: false }
          , { value: "c", label: [ HH.text "Underline" ], disabled: false }
          ]
      , style = { root: cn "", item: cn "" }
      }
  | otherwise =
      let
        disableMiddle = s == "disabled-skip"
      in
        ToggleGroup.defaultInput
          { single = true
          , defaultValue = [ if disableMiddle then "a" else "b" ]
          , ariaLabel = Just "Text alignment"
          , items =
              [ { value: "a", label: [ HH.text "Left" ], disabled: false }
              , { value: "b", label: [ HH.text "Center" ], disabled: disableMiddle }
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
passwordTogglePage :: String -> H.ComponentHTML Void Slots Aff
passwordTogglePage s =
  -- `?s=formreset` wraps the field in a <form> with a reset button so the port's form
  -- reset listener (forces visibility→hidden) is exercised; otherwise the bare box.
  if s == "formreset" then
    box []
      [ HH.form_
          [ HH.label
              [ HP.attr (HH.AttrName "for") "password" ]
              [ HH.text "Password" ]
          , HH.slot_ _passwordtoggle unit PasswordToggleField.component (passwordToggleInput s)
          , HH.button [ HP.type_ HP.ButtonReset ] [ HH.text "Reset" ]
          ]
      ]
  else
    box []
      [ HH.label
          [ HP.attr (HH.AttrName "for") "password" ]
          [ HH.text "Password" ]
      , HH.slot_ _passwordtoggle unit PasswordToggleField.component (passwordToggleInput s)
      ]

-- | The icon-only toggle content for `?s=autolabel` — an aria-hidden SVG with no inner text,
-- | byte-identical to the golden so the auto aria-label ("Show password") is what names the button.
passwordToggleIcon :: HH.PlainHTML
passwordToggleIcon =
  HH.elementNS (HH.Namespace "http://www.w3.org/2000/svg") (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "width") "15"
    , HP.attr (HH.AttrName "height") "15"
    , HP.attr (HH.AttrName "viewBox") "0 0 15 15"
    , HP.attr (HH.AttrName "aria-hidden") "true"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    ]
    [ HH.elementNS (HH.Namespace "http://www.w3.org/2000/svg") (HH.ElemName "circle")
        [ HP.attr (HH.AttrName "cx") "7.5"
        , HP.attr (HH.AttrName "cy") "7.5"
        , HP.attr (HH.AttrName "r") "2"
        , HP.attr (HH.AttrName "fill") "currentColor"
        ]
        []
    ]

passwordToggleInput :: String -> PasswordToggleField.Input
passwordToggleInput s = PasswordToggleField.defaultInput
  { inputId = Just "password"
  -- `?s=autolabel` → icon-only toggle (no text) so the auto aria-label applies; otherwise the
  -- text Slot (Show/Hide). `?s=disabled` → native disabled on both input + toggle.
  , toggleVisible = if s == "autolabel" then [ passwordToggleIcon ] else [ HH.text "Hide" ]
  , toggleHidden = if s == "autolabel" then [ passwordToggleIcon ] else [ HH.text "Show" ]
  , iconOnly = s == "autolabel"
  , disabled = s == "disabled"
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
      [ Toolbar.Button { value: "new", label: [ HH.text "New" ], disabled: s == "disabled" }
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
      -- `?s=paste` starts EMPTY (like empty/typed) so the Wave-D paste driver can dump a
      -- full code into the first slot and exercise the PASTE reducer.
      if s == "empty" || s == "typed" || s == "paste" then ""
      else if s == "alpha" then "abc"
      else "123"
  -- `?s=alpha` exercises the Alpha validation set (inputmode=text, pattern=[a-zA-Z]{1}).
  , validation = if s == "alpha" then Otp.Alpha else Otp.Numeric
  -- Wave-C state-variants: password masks slots, disabled drops them from the roving
  -- order + stamps disabled, readonly stamps readonly.
  , password = s == "password"
  , disabled = s == "disabled"
  , readOnly = s == "readonly"
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
  -- `?s=reset` renders a `<button type=reset>Reset</button>` so the form-reset path
  -- (clears each field's derived validity → Messages unmount) is exercised.
  , resetLabel = if s == "reset" then [ HH.text "Reset" ] else []
  , fields =
      [ Form.defaultField
          { name = "email"
          , label = [ HH.text "Email" ]
          , inputType = "email"
          , required = true
          , serverInvalid = s == "serverInvalid"
          , messages =
              -- `?s=defaultMessage` forceMatches a single valueMissing Message with EMPTY text →
              -- the default built-in message text fallback (radix DEFAULT_BUILT_IN_MESSAGES).
              if s == "defaultMessage" then
                [ { match: Form.ValueMissing, forceMatch: true, text: [] } ]
              -- `?s=reset` has a SINGLE (non-forced) valueMissing Message — it mounts on the
              -- Submit click, then unmounts when the form is reset (matching the golden story).
              else if s == "reset" then
                [ { match: Form.ValueMissing, forceMatch: false, text: [ HH.text "This value is missing" ] } ]
              else
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
thickCheckIconPlain = checkIndicatorWith "checked" false thickCheckPath

-- | The ThickCheckIcon asChild indicator with a CALLER-SUPPLIED class set (the
-- | CheckboxGroup/CheckboxCards item indicators carry a different class). data-state is
-- | always "checked" (these callers only render the checked indicator).
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
    [ thickCheckPath ]

-- | The asChild indicator svg with a baked `data-state` and (optional) `data-disabled=''`,
-- | parameterized over the inner path — `thickCheckPath` (checked) or `dividerPath`
-- | (indeterminate). Merges the asChild indicator props upstream's CheckboxIndicator stamps
-- | onto its child (class, data-state, optional data-disabled, pointer-events:none). NB:
-- | SVGElement.className is a read-only SVGAnimatedString, so class/data-state must be set
-- | via setAttribute (HP.attr).
checkIndicatorWith :: String -> Boolean -> HH.PlainHTML -> HH.PlainHTML
checkIndicatorWith state disabled innerPath =
  HH.elementNS svgNS (HH.ElemName "svg")
    ( [ HP.attr (HH.AttrName "class") "rt-BaseCheckboxIndicator rt-CheckboxIndicator"
      , HP.attr (HH.AttrName "data-state") state
      , HP.attr (HH.AttrName "width") "9"
      , HP.attr (HH.AttrName "height") "9"
      , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
      , HP.attr (HH.AttrName "fill") "currentcolor"
      , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
      , HP.style "pointer-events: none;"
      ]
        <> (if disabled then [ HP.attr (HH.AttrName "data-disabled") "" ] else [])
    )
    [ innerPath ]

-- | The ThickCheckIcon path (the check mark).
thickCheckPath :: HH.PlainHTML
thickCheckPath =
  HH.elementNS svgNS (HH.ElemName "path")
    [ HP.attr (HH.AttrName "fill-rule") "evenodd"
    , HP.attr (HH.AttrName "clip-rule") "evenodd"
    , HP.attr (HH.AttrName "d")
        "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
    ]
    []

-- | The ThickDividerHorizontalIcon path (the indeterminate dash).
dividerPath :: HH.PlainHTML
dividerPath =
  HH.elementNS svgNS (HH.ElemName "path")
    [ HP.attr (HH.AttrName "fill-rule") "evenodd"
    , HP.attr (HH.AttrName "clip-rule") "evenodd"
    , HP.attr (HH.AttrName "d")
        "M0.75 4.5C0.75 4.08579 1.08579 3.75 1.5 3.75H7.5C7.91421 3.75 8.25 4.08579 8.25 4.5C8.25 4.91421 7.91421 5.25 7.5 5.25H1.5C1.08579 5.25 0.75 4.91421 0.75 4.5Z"
    ]
    []

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

-- ── Wave-B stateless depth-oracle pages (bare Hydrogen.Radix primitives) ──────────

-- | Separator: four at-rest combos keyed off `s` — semantic ⇒ role=separator (+ aria-
-- | orientation only when vertical); decorative ⇒ role=none. data-orientation always.
separatorPrimPage :: forall w i. String -> HH.HTML w i
separatorPrimPage s =
  Separator.separator_ orientation decorative
  where
  orientation = if s == "vsem" || s == "vdec" then Vertical else Horizontal
  decorative = s == "hdec" || s == "vdec"

-- | AspectRatio: ratio variants + the `styled` story (caller style merged before the
-- | inset override, id/aria/data-* + class on the INNER div).
aspectRatioPrimPage :: forall w i. String -> HH.HTML w i
aspectRatioPrimPage s
  | s == "styled" =
      AspectRatio.aspectRatio
        ( AspectRatio.defaultInput
            { ratio = 16.0 / 9.0
            , class_ = cn "my-inner"
            , style = "background-color: red; "
            , attrs =
                [ HP.id "ar-inner"
                , HP.attr (HH.AttrName "aria-label") "cover"
                , HP.attr (HH.AttrName "data-foo") "bar"
                ]
            }
        )
        [ HH.span_ [ HH.text "X" ] ]
  | otherwise =
      AspectRatio.aspectRatio_ ratio [ HH.span_ [ HH.text "X" ] ]
      where
      ratio = if s == "wide" then 16.0 / 9.0 else if s == "tall" then 1.0 / 2.0 else if s == "verywide" then 21.0 / 9.0 else 1.0

-- | VisuallyHidden: plain (canonical clip style + text), props (id/aria-*/data-*
-- | passthrough), stylemerge (caller style overrides one default key in place + appends).
visuallyHiddenPrimPage :: forall w i. String -> HH.HTML w i
visuallyHiddenPrimPage s
  | s == "props" =
      VisuallyHidden.visuallyHiddenWith
        { class_: mempty
        , style: []
        , attrs:
            [ HP.id "vh-1"
            , HP.attr (HH.AttrName "aria-live") "polite"
            , HP.attr (HH.AttrName "data-state") "x"
            ]
        }
        [ HH.text "required" ]
  | s == "stylemerge" =
      VisuallyHidden.visuallyHiddenWith
        { class_: mempty
        , style: [ Tuple "position" "fixed", Tuple "color" "red" ]
        , attrs: []
        }
        [ HH.text "required" ]
  | otherwise =
      VisuallyHidden.visuallyHidden_ [ HH.text "required" ]

-- | Label: the for-association attribute + arbitrary prop passthrough (id/data-*/aria-
-- | describedby/title) on the <label>, with the associated <input id="email"> sibling.
labelPrimPage :: forall w i. HH.HTML w i
labelPrimPage =
  HH.div_
    [ Label.labelWith
        { for: "email"
        , class_: mempty
        , attrs:
            [ HP.id "email-label"
            , HP.attr (HH.AttrName "data-foo") "bar"
            , HP.attr (HH.AttrName "aria-describedby") "hint"
            , HP.attr (HH.AttrName "title") "Your email"
            ]
        }
        [ HH.text "Email" ]
    , HH.input [ HP.id "email" ]
    ]

-- | Themes.Separator WRAPPER (distinct from the bare primitive): decorative defaults
-- | TRUE → role OMITTED (not role=none); color → data-accent-color (default gray);
-- | size → rt-r-size-N (default 1); orientation is class-only (no data-orientation).
-- | The semantic case mirrors upstream's role={decorative?undefined:'separator'} by
-- | adding role=separator; vertical replaces the orientation class (engine last-wins).
separatorThemesPage :: forall w i. String -> HH.HTML w i
separatorThemesPage s
  | s == "semantic" = ThemesSeparator.separator [ RawAttr "role" "separator" ]
  | s == "size4" = ThemesSeparator.separator [ Size "4" ]
  | s == "accent" = ThemesSeparator.separator [ Color "cyan" ]
  | s == "vertical" = ThemesSeparator.separator [ Class "rt-r-orientation-vertical" ]
  | otherwise = ThemesSeparator.separator []

-- | Label onMouseDown guard (Wave-D). `plain` = a bare label whose text-multi-click
-- | mousedown is preventDefault-ed (detail>1). `control` = a label wrapping an <input>
-- | so a mousedown on the input hits the early-return (closest('…input…')) path and is
-- | NOT preventDefault-ed. Both render a <label for=…> carrying the guard listener.
labelGuardInput :: String -> Label.Input
labelGuardInput s
  | s == "control" =
      { for: "lg-input"
      , class_: mempty
      , attrs: [ HP.id "lg-label" ]
      , children: [ HH.text "Name ", HH.input [ HP.id "lg-input" ] ]
      }
  | otherwise =
      { for: "lg-input"
      , class_: mempty
      , attrs: [ HP.id "lg-label" ]
      , children: [ HH.text "Email" ]
      }

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

-- | tabs (manual activation) — same anatomy as `tabsInput` but activationMode=Manual:
-- | arrows move the roving focus WITHOUT selecting; Enter/Space on the focused trigger
-- | activates it (tabs.tsx:61,192-202). Drives the `tabsmanual` route / APG check.
tabsManualInput :: String -> Tabs.Input
tabsManualInput s = (tabsInput s) { activationMode = Tabs.Manual }

-- | togglegroup (group disabled) — Root `disabled` ORs into every item; the whole group
-- | is non-focusable / non-togglable. Single-mode, Center pre-pressed.
toggleGroupDisabledInput :: ToggleGroup.Input
toggleGroupDisabledInput = ToggleGroup.defaultInput
  { single = true
  , disabled = true
  , defaultValue = [ "b" ]
  , ariaLabel = Just "Text alignment"
  , items =
      [ { value: "a", label: [ HH.text "Left" ], disabled: false }
      , { value: "b", label: [ HH.text "Center" ], disabled: false }
      , { value: "c", label: [ HH.text "Right" ], disabled: false }
      ]
  , style = { root: cn "", item: cn "" }
  }

-- | togglegroup (loop=false) — arrow navigation clamps at the ends (no wrap). Single-mode,
-- | Left pre-pressed.
toggleGroupNoLoopInput :: ToggleGroup.Input
toggleGroupNoLoopInput = ToggleGroup.defaultInput
  { single = true
  , loop = false
  , defaultValue = [ "a" ]
  , ariaLabel = Just "Text alignment"
  , items =
      [ { value: "a", label: [ HH.text "Left" ], disabled: false }
      , { value: "b", label: [ HH.text "Center" ], disabled: false }
      , { value: "c", label: [ HH.text "Right" ], disabled: false }
      ]
  , style = { root: cn "", item: cn "" }
  }

-- | togglegroup (vertical) — ArrowUp/ArrowDown navigate; data-orientation=vertical.
toggleGroupVertInput :: ToggleGroup.Input
toggleGroupVertInput = ToggleGroup.defaultInput
  { single = true
  , orientation = Vertical
  , explicitOrientation = true
  , defaultValue = [ "a" ]
  , ariaLabel = Just "Text alignment"
  , items =
      [ { value: "a", label: [ HH.text "Left" ], disabled: false }
      , { value: "b", label: [ HH.text "Center" ], disabled: false }
      , { value: "c", label: [ HH.text "Right" ], disabled: false }
      ]
  , style = { root: cn "", item: cn "" }
  }

-- | accordion (single, collapsible) — item-1 open at first paint; clicking the open
-- | trigger CLOSES it (empty open set). collapsible=true ⇒ the open trigger is NOT
-- | aria-disabled (the contrast to the non-collapsible `single` story).
accordionCollapsibleInput :: Accordion.Input
accordionCollapsibleInput = Accordion.defaultInput
  { items =
      [ { value: "item-1", header: [ HH.text "Is it accessible?" ], content: [ HH.text "Yes. It adheres to the WAI-ARIA design pattern." ], disabled: false }
      , { value: "item-2", header: [ HH.text "Is it styled?" ], content: [ HH.text "No. It is unstyled by default." ], disabled: false }
      , { value: "item-3", header: [ HH.text "Is it animated?" ], content: [ HH.text "Yes, with CSS." ], disabled: false }
      ]
  , single = true
  , collapsible = true
  , defaultValue = [ "item-1" ]
  , style =
      { root: cn ""
      , item: cn ""
      , header: cn ""
      , trigger: cn ""
      , content: cn ""
      }
  }

-- | toolbar (loop=false) — 3 buttons; arrow navigation clamps at the ends (no wrap).
toolbarNoLoopInput :: Toolbar.Input
toolbarNoLoopInput = Toolbar.defaultInput
  { orientation = Horizontal
  , dir = LTR
  , loop = false
  , ariaLabel = Just "Formatting"
  , items =
      [ Toolbar.Button { value: "new", label: [ HH.text "New" ], disabled: false }
      , Toolbar.Button { value: "open", label: [ HH.text "Open" ], disabled: false }
      , Toolbar.Button { value: "save", label: [ HH.text "Save" ], disabled: false }
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

-- | toolbar (multiple toggle group) — a single type=multiple ToggleGroup: items keep
-- | aria-pressed (NOT role=radio), two can be on at once, each toggles independently.
toolbarMultipleInput :: Toolbar.Input
toolbarMultipleInput = Toolbar.defaultInput
  { orientation = Horizontal
  , dir = LTR
  , ariaLabel = Just "Formatting"
  , items =
      [ Toolbar.ToggleGroup
          { items:
              [ { value: "bold", label: [ HH.text "B" ], disabled: false }
              , { value: "italic", label: [ HH.text "I" ], disabled: false }
              , { value: "underline", label: [ HH.text "U" ], disabled: false }
              ]
          , single: false
          , defaultValue: [ "bold" ]
          , ariaLabel: Just "Text formatting"
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
-- | formWrap (Wave C) — for the `?s=form` controls states (checkbox/switch/radiogroup),
-- | wrap the slot in a real `<form>` so the port's hidden bubble input renders inside it,
-- | matching upstream's `isFormControl`-resolves-true DOM. Every other state passes the
-- | content through untouched (no wrapper), keeping the existing oracles byte-identical.
formWrap :: String -> H.ComponentHTML Void Slots Aff -> H.ComponentHTML Void Slots Aff
formWrap s content
  | s == "form" = HH.form [] [ content ]
  | otherwise = content
-- ── Wave-C ScrollArea family input (horizontal + both+corner) ───────────────────
-- | The themed Radix ScrollArea exercising the MISSING-IN-PORT scrollbar family.
-- | `?s=horizontal` → scrollbars=Horizontal' (one horizontal bar, overflow scroll
-- | hidden, --thumb-width, translate3d X). Else `?s=both` → scrollbars=Both (TWO
-- | bars in upstream order horizontal-then-vertical, overflow:scroll, + a
-- | rt-ScrollAreaCorner with non-zero --radix-scroll-area-corner-{width,height}).
-- | Content is wide+tall (width:400 nowrap rows) so BOTH axes overflow at rest.
scrollAreaXInput :: String -> ScrollArea.Input
scrollAreaXInput s = ScrollArea.defaultInput
  { widthPx = 200
  , heightPx = 120
  , scrollbars = if s == "horizontal" then ScrollArea.Horizontal' else ScrollArea.Both
  -- `?s=radius` exercises the themes `radius` prop: upstream stamps data-radius=full on
  -- EVERY scrollbar; the other states leave it absent (themes default undefined).
  , radius = if s == "radius" then "full" else ""
  , style =
      { root: cn "rt-ScrollAreaRoot"
      , viewport: cn "rt-ScrollAreaViewport"
      , focusRing: cn "rt-ScrollAreaViewportFocusRing"
      , scrollbar: cn "rt-ScrollAreaScrollbar rt-r-size-1"
      , thumb: cn "rt-ScrollAreaThumb"
      , corner: cn "rt-ScrollAreaCorner"
      }
  , content =
      [ box [ P "2", Width "400px" ]
          ( map
              ( \n -> textAs "p" [ Size "2", StyleProp "white-space" "nowrap" ]
                  [ HH.text "Line ", HH.text (show n), HH.text " — a long row that overflows horizontally as well" ] )
              (Array.range 1 12)
          )
      ]
  }

-- ── Wave-C Avatar loaded-state input (Radix Avatar primitive, themed) ───────────
-- | The themed Radix Avatar primitive at the LOADED steady-state: a data-URI src that
-- | loads synchronously, so the img mounts (rt-AvatarImage, alt, NO data-state) and the
-- | fallback drops out. The Root span carries rt-reset/rt-AvatarRoot + the size/variant
-- | classes and the always-present empty `data-accent-color` (upstream Themes parity).
avatarLoadedInput :: RadixAvatar.Input
avatarLoadedInput = RadixAvatar.defaultInput
  { src = onePxPng
  , alt = "Profile photo"
  , fallback = [ HH.text "A" ]
  , rootAttrs = [ dataAttr "accent-color" "" ]
  , style =
      { root: cn "rt-reset rt-AvatarRoot rt-r-size-3 rt-variant-soft"
      , image: cn "rt-AvatarImage"
      , fallback: cn "rt-AvatarFallback rt-one-letter"
      }
  }

-- | Wave-D: the loaded Avatar with img-attr PASSTHROUGH. The themes Avatar.Image
-- | rest-spreads (...t) referrerPolicy/crossOrigin onto the <img>; this binding exercises
-- | the port's `imageAttrs` escape hatch so those attributes land on the loaded image
-- | (matching the golden's ?s=loadedattrs story). Same loaded steady-state otherwise.
avatarLoadedAttrsInput :: RadixAvatar.Input
avatarLoadedAttrsInput = avatarLoadedInput
  { imageAttrs =
      [ HP.attr (HH.AttrName "referrerpolicy") "no-referrer"
      , HP.attr (HH.AttrName "crossorigin") "anonymous"
      ]
  }

-- A 1×1 transparent PNG data-URI (loads synchronously from cache) — the Avatar reaches
-- the LOADED steady-state deterministically, matching the golden story's ONE_PX_PNG.
onePxPng :: String
onePxPng = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC"

-- ── Wave-D menus depth (STR-330) ────────────────────────────────────────────────

-- | The Select FORM-integration story. `?s=required` → aria-required + a required hidden
-- | native <select> (BubbleSelect); `?s=disabledtrigger` → disabled trigger + disabled
-- | bubble. The route wraps the slot in a <form> so the BubbleSelect renders. Reuses
-- | selectStyle so the trigger/content chrome matches the canonical select.
selectFormInput :: String -> Select.Input
selectFormInput s = Select.defaultInput
  { defaultValue = "apple"
  , name = "fruit"
  , required = s /= "disabledtrigger"
  , disabled = s == "disabledtrigger"
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

-- | The DropdownMenu GROUP/LABEL story: two labelled groups (File / Edit) separated by a
-- | Separator. The Group renders a role=group wrapper; the Label is a non-interactive div
-- | (Radix Themes wires NO aria-labelledby/id between them). Reuses menuStyle + the new
-- | group/groupLabel class slots.
dropdownGroupInput :: DropdownMenu.Input
dropdownGroupInput = DropdownMenu.defaultInput
  { style = menuStyle
  , triggerAttrs = [ Tuple "accent-color" "" ]
  , portalAttrs = portalThemeAttrs
  , contentStyle = "outline: none; " <> popperContentVars "dropdown-menu" <> " pointer-events: auto;"
  , trigger = [ HH.text "Actions", chevron ]
  , entries =
      [ DropdownMenu.menuGroup [ HH.text "File" ]
          [ { value: "new", label: [ HH.text "New" ], shortcut: [], accent: "", disabled: false }
          , { value: "open", label: [ HH.text "Open" ], shortcut: [], accent: "", disabled: false }
          ]
      , DropdownMenu.menuSeparator
      , DropdownMenu.menuGroup [ HH.text "Edit" ]
          [ { value: "cut", label: [ HH.text "Cut" ], shortcut: [], accent: "", disabled: false }
          , { value: "copy", label: [ HH.text "Copy" ], shortcut: [], accent: "", disabled: false }
          ]
      ]
  }
-- | Wave-D: Toast swipeDirection="up" variant — identical to `toastInput` but the swipe
-- | axis is physical-up, so data-swipe-direction=up on the <li> (the stable contract; the
-- | pointer-drag clamp/CSS-var math is non-deterministic in a headless capture, deferred).
toastUpInput :: Toast.Input
toastUpInput = (toastInput "") { swipeDirection = "up" }
-- | tabs (vertical) — same anatomy/Style as `tabsInput` but orientation=Vertical: ArrowUp/
-- | ArrowDown navigate, Left/Right inert, data-orientation=vertical + aria-orientation=vertical.
tabsVertInput :: Tabs.Input
tabsVertInput = (tabsInput "") { orientation = Vertical }

-- | tabs (rtl) — same anatomy/Style as `tabsInput` but dir=RTL: the horizontal arrows are
-- | SWAPPED (ArrowLeft → next, ArrowRight → prev) and the root emits dir=rtl.
tabsRtlInput :: Tabs.Input
tabsRtlInput = (tabsInput "") { dir = RTL }

-- | tabs (zero-selected) — NO defaultValue (and uncontrolled value=Nothing) → the active value
-- | is '' (upstream `value ?? defaultValue ?? ''`): no tab aria-selected, no panel visible.
tabsNoneInput :: Tabs.Input
tabsNoneInput = (tabsInput "") { defaultValue = Nothing }

-- | accordion (horizontal) — orientation=Horizontal: ArrowLeft/ArrowRight rove between
-- | triggers, ArrowUp/Down inert; data-orientation=horizontal on the parts. type=multiple.
accordionHorizInput :: Accordion.Input
accordionHorizInput = (accordionInput "") { orientation = Horizontal }

-- | togglegroup (rtl) — single-mode, Left pre-pressed, dir=RTL: ArrowLeft roves to the NEXT
-- | (rightmost) item, ArrowRight to the previous. Bare ⇒ empty Style.
toggleGroupRtlInput :: ToggleGroup.Input
toggleGroupRtlInput = ToggleGroup.defaultInput
  { single = true
  , dir = RTL
  , defaultValue = [ "a" ]
  , ariaLabel = Just "Text alignment"
  , items =
      [ { value: "a", label: [ HH.text "Left" ], disabled: false }
      , { value: "b", label: [ HH.text "Center" ], disabled: false }
      , { value: "c", label: [ HH.text "Right" ], disabled: false }
      ]
  , style = { root: cn "", item: cn "" }
  }

-- | toolbar (rtl) — three plain buttons, dir=RTL: ArrowLeft roves to the NEXT item, ArrowRight
-- | to the previous. Bare ⇒ empty Style (same anatomy as the noloop story).
toolbarRtlInput :: Toolbar.Input
toolbarRtlInput = Toolbar.defaultInput
  { dir = RTL
  , ariaLabel = Just "Formatting"
  , items =
      [ Toolbar.Button { value: "new", label: [ HH.text "New" ], disabled: false }
      , Toolbar.Button { value: "open", label: [ HH.text "Open" ], disabled: false }
      , Toolbar.Button { value: "save", label: [ HH.text "Save" ], disabled: false }
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
-- | sliderRange — Wave-D multi-thumb / range slider (Slider.rangeComponent). One role=slider
-- | thumb per value; ?s=triple → [20,50,80] (3 thumbs, "Value n of m" labels), ?s=minsteps →
-- | [40,60] with minStepsBetweenThumbs=10 (a keyboard step within 10·step of the neighbour is
-- | rejected), default → [25,75] (Minimum/Maximum, range between the two thumbs). Same rt-Slider*
-- | class anatomy as the single-thumb slider.
sliderRangeInput :: String -> Slider.RangeInput
sliderRangeInput s = Slider.defaultRangeInput
  { defaultValue =
      if s == "triple" then [ 20, 50, 80 ]
      else if s == "minsteps" then [ 40, 60 ]
      else [ 25, 75 ]
  , min = 0
  , max = 100
  , step = 1
  , minStepsBetweenThumbs = if s == "minsteps" then 10 else 0
  , style =
      { root: cn "rt-SliderRoot rt-r-size-2 rt-variant-surface"
      , track: cn "rt-SliderTrack"
      , range: cn "rt-SliderRange"
      , thumb: cn "rt-SliderThumb"
      }
  }

-- | sliderRangeForm (STR-330) — the named [25,75] range slider for the `sliderrangeform`
-- | page: isFormControl=true (the route wraps it in a <form>) + name="band", so each thumb
-- | renders a hidden SliderBubbleInput sibling (`<input style=display:none name="band[]">`,
-- | defaultValue = the thumb's value). Same rt-Slider* class anatomy as `sliderRangeInput`.
sliderRangeFormInput :: String -> Slider.RangeInput
sliderRangeFormInput _ = Slider.defaultRangeInput
  { defaultValue = [ 25, 75 ]
  , min = 0
  , max = 100
  , step = 1
  , name = "band"
  , isFormControl = true
  , style =
      { root: cn "rt-SliderRoot rt-r-size-2 rt-variant-surface"
      , track: cn "rt-SliderTrack"
      , range: cn "rt-SliderRange"
      , thumb: cn "rt-SliderThumb"
      }
  }
