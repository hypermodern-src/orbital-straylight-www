-- | Hydrogen.Radix.Menubar — a horizontal roving bar of DropdownMenu-style menus
-- | (radix `Menubar`).
-- |
-- | Menubar IS DropdownMenu under a RovingFocus bar: each `MenubarMenu` is a
-- | `MenubarTrigger` (role=menuitem button, the RovingFocus.Item AND the menu's anchor)
-- | plus a portaled `role=menu` content positioned by the Popper, dismissed by Escape /
-- | pointer-outside, kept mounted through its exit by Presence. This module REUSES the
-- | DropdownMenu machinery wholesale (Float.Popper, Foundation.Portal/Envelope,
-- | Behavior.{Presence,DismissableLayer,ControllableState,Id,RovingFocus}) and adds only:
-- |
-- |   * the trigger BAR — N role=menuitem triggers in a `role=menubar` div with a HORIZONTAL
-- |     RovingFocus tab stop (ArrowLeft/Right/Home/End move between triggers; the same pure
-- |     `RovingFocus.navigate` used vertically inside the content);
-- |   * a single open-value (which menu is open) — exactly ONE popper/content is rendered at a
-- |     time, anchored to the open menu's trigger;
-- |   * the signature menubar behaviors: ArrowDown on a closed trigger opens + focuses the
-- |     first item; ArrowRight/ArrowLeft from INSIDE an open menu close it + open the adjacent
-- |     trigger's menu (cross-menu); pointerenter on a trigger while another menu is open
-- |     switches the open menu to it (open-on-hover).
-- |
-- | MODALITY: MenubarMenu is `modal={false}` — UNLIKE DropdownMenu it does NOT scroll-lock,
-- | aria-hide siblings, or block body pointer-events. It DOES still render the two
-- | `data-radix-focus-guard` sentinels (FocusGuards is independent of modality) and uses the
-- | dismiss + reposition + focus-restore path. So the open envelope here is the NON-MODAL
-- | subset: `addFocusGuards` + `reAdoptBeforeTrail` only — never lockScroll/hideOthers.
-- |
-- | v1 (mirrors DropdownMenu v1): no typeahead, no submenus, no checkbox/radio items. The
-- | content has NO ScrollArea nesting (the bare primitive renders items as direct children of
-- | the role=menu div).
module Hydrogen.Radix.Menubar
  ( component
  , Menu
  , MenuEntry(..)
  , MenuItem
  , CheckItem
  , RadioGroupData
  , RadioOption
  , SubData
  , CheckState(..)
  , menuItem
  , menuSeparator
  , menuCheckbox
  , menuRadioGroup
  , menuSub
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl, for_, traverse_)
import Data.Maybe (Maybe(..), fromMaybe, maybe, isJust)
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Direction (Dir(..), dirName)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, navigatePaged, tabIndexFor)
import Hydrogen.Radix.Behavior.Typeahead (nextMatch, isTypeaheadChar) as Typeahead
import Hydrogen.Radix.Float.Popper as Popper
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Envelope as Envelope
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, Side(..), Align(..), Orientation(..), cn, classes, dataState, dataAttr, sideName, alignName, role, aria)
import Web.DOM.Node (Node, textContent)
import Web.Event.Event (Event, EventType(..), preventDefault)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface — MenuItem/MenuEntry mirror DropdownMenu verbatim.
-- ─────────────────────────────────────────────────────────────────────────────

type MenuItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , accent :: String
  , disabled :: Boolean
  }

-- | Tri-state check status for a CheckboxItem (mirrors DropdownMenu.CheckState).
data CheckState = Checked | Unchecked | Indeterminate

derive instance eqCheckState :: Eq CheckState

type CheckItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , check :: CheckState
  , disabled :: Boolean
  }

type RadioOption =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , disabled :: Boolean
  }

type RadioGroupData =
  { value :: String
  , options :: Array RadioOption
  }

type SubData =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , disabled :: Boolean
  , entries :: Array MenuEntry
  }

data MenuEntry
  = MenuItemEntry MenuItem
  | MenuSeparator
  | MenuCheckboxEntry CheckItem
  | MenuRadioGroupEntry RadioGroupData
  | MenuSubEntry SubData

menuItem :: String -> Array HH.PlainHTML -> MenuEntry
menuItem value label = MenuItemEntry { value, label, shortcut: [], accent: "", disabled: false }

-- | Smart constructor for a submenu (SubTrigger label + nested entries).
menuSub :: String -> Array HH.PlainHTML -> Array MenuEntry -> MenuEntry
menuSub value label entries = MenuSubEntry { value, label, shortcut: [], disabled: false, entries }

menuSeparator :: MenuEntry
menuSeparator = MenuSeparator

menuCheckbox :: String -> Array HH.PlainHTML -> CheckState -> MenuEntry
menuCheckbox value label check = MenuCheckboxEntry { value, label, shortcut: [], check, disabled: false }

menuRadioGroup :: String -> Array RadioOption -> MenuEntry
menuRadioGroup value options = MenuRadioGroupEntry { value, options }

-- | The roving order counts only ENABLED items (upstream re-exports react-menu's
-- | `getItems().filter(!disabled)` / `focusable={!disabled}`). A disabled item renders
-- | but is excluded from the roving order, so vertical arrows skip OVER it. Checkbox items
-- | count as 1; a radio group contributes its enabled-option count.
itemCount :: Array MenuEntry -> Int
itemCount = foldl (\n e -> n + entryFocusables e) 0

entryFocusables :: MenuEntry -> Int
entryFocusables = case _ of
  MenuItemEntry item -> if item.disabled then 0 else 1
  MenuCheckboxEntry item -> if item.disabled then 0 else 1
  MenuRadioGroupEntry grp -> Array.length (Array.filter (not <<< _.disabled) grp.options)
  MenuSubEntry sub -> if sub.disabled then 0 else 1
  MenuSeparator -> 0

-- | The enabled focusable value at roving index `n` (the keyboard-selection target).
enabledValueAt :: Int -> Array MenuEntry -> Maybe String
enabledValueAt n entries = Array.index (Array.concatMap enabledValues entries) n
  where
  enabledValues = case _ of
    MenuItemEntry item | not item.disabled -> [ item.value ]
    MenuCheckboxEntry item | not item.disabled -> [ item.value ]
    MenuRadioGroupEntry grp -> map _.value (Array.filter (not <<< _.disabled) grp.options)
    MenuSubEntry sub | not sub.disabled -> [ sub.value ]
    _ -> []

-- | One menu in the bar: a stable `value` (the open-value key), the trigger label, and the
-- | menu entries. NO DOM of its own — collapses into Root's render (trigger + portal+content).
type Menu =
  { value :: String
  , trigger :: Array HH.PlainHTML
  , entries :: Array MenuEntry
  , disabled :: Boolean   -- a disabled top-level trigger: non-focusable, skipped in roving + cross-menu
  }

type Style =
  { root :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  , item :: ClassNames
  , shortcut :: ClassNames
  , separator :: ClassNames
  , checkboxItem :: ClassNames
  , radioGroup :: ClassNames
  , radioItem :: ClassNames
  , indicator :: ClassNames
  , checkIndicator :: Array HH.PlainHTML  -- the indicator content (e.g. ✓) for a checkbox
  , radioIndicator :: Array HH.PlainHTML  -- the indicator content for a radio item
  , subTrigger :: ClassNames
  , subContent :: ClassNames
  , subIcon :: Array HH.PlainHTML        -- SubTrigger icon (bare menubar has none → [])
  }

defaultStyle :: Style
defaultStyle =
  { root: cn ""
  , trigger: cn ""
  , content: cn ""
  , item: cn ""
  , shortcut: cn ""
  , separator: cn ""
  , checkboxItem: cn ""
  , radioGroup: cn ""
  , radioItem: cn ""
  , indicator: cn ""
  , checkIndicator: []
  , radioIndicator: []
  , subTrigger: cn ""
  , subContent: cn ""
  , subIcon: []
  }

type Input =
  { menus :: Array Menu
  , value :: Maybe String          -- controlled open-value ("" = none); Nothing = uncontrolled
  , defaultValue :: String         -- uncontrolled initial open-value ("" = none)
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , loop :: Boolean
  , dir :: Dir
  , idPrefix :: String
  , style :: Style
  , contentStyle :: String         -- the content's CONSTANT style (outline + menubar vars)
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  }

defaultInput :: Input
defaultInput =
  { menus: []
  , value: Nothing
  , defaultValue: ""
  , side: Bottom
  , align: Start
  , offset: 4.0
  , padding: 8.0
  , loop: true
  , dir: LTR
  , idPrefix: "rdx-menubar"
  , style: defaultStyle
  , contentStyle: ""
  , triggerAttrs: []
  , portalAttrs: []
  }

data Output
  = OpenChanged (Maybe String)              -- the open menu value (Nothing = none)
  | ItemSelected { menu :: String, item :: String }

data Query a
  = SetOpen (Maybe String) a
  | GetOpen (Maybe String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

-- | "" is the open-value sentinel for "no menu open" (mirrors DropdownMenu's Boolean ctrl,
-- | here a String identifying which menu). Controllable String threads controlled/uncontrolled.
type State =
  { ctrl :: Controllable String     -- the open menu value ("" = none)
  , presence :: Presence            -- the open menu's content lifecycle
  , menus :: Array Menu
  , triggerFocus :: Int             -- roving tab stop among the triggers (horizontal)
  , itemFocus :: Int                -- roving tab stop inside the open content (vertical)
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , loop :: Boolean
  , dir :: Dir
  , placedSide :: Side
  , placedAlign :: Align
  , idPrefix :: String
  , style :: Style
  , contentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , restoreEl :: Maybe HTMLElement.HTMLElement
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId
  , animSub :: Maybe H.SubscriptionId
  , contentNode :: Maybe Node
  , triggerIds :: Array String      -- one per menu (generated on Initialize)
  , contentIds :: Array String      -- one per menu
  , openFocus :: Maybe Int          -- post-open focus: Nothing = content, Just i = item i
  -- ── typeahead (type-to-focus inside the open menu; radix useTypeahead) ──
  , search :: String   -- the accumulated search buffer (reset lazily after ~1s of no input)
  , lastKey :: Number  -- performance.now() of the last typeahead key; the idle-reset clock
  -- ── submenu (one open at a time, inside the active menu's content) ──
  , subOpen :: Maybe String
  , subFocused :: Int
  , subAnchorIdx :: Int
  , subPlacedSide :: Side
  , subPlacedAlign :: Align
  , subOpenFocus :: Maybe Int
  , subSubs :: Array H.SubscriptionId
  , subPostSub :: Maybe H.SubscriptionId
  , subGenTriggerId :: String
  , subGenContentId :: String
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked Int
  | TriggerKeyDown Int KE.KeyboardEvent
  | TriggerPointerEnter Int
  | TriggerFocused Int
  | AfterOpen
  | AfterClose
  | AnimDone
  | EscapePressed
  | PointerDown Event
  | MenuKeyDown KE.KeyboardEvent
  | ItemClicked String
  | Reposition
  -- ── submenu ──
  | SubTriggerEnter String Int
  | SubTriggerActivate String Int
  | SubAfterOpen
  | SubReposition
  | SubKeyDown KE.KeyboardEvent
  | SubItemClicked String
  | CloseSub

triggerRef :: String -> Int -> H.RefLabel
triggerRef pfx i = H.RefLabel (pfx <> "-trigger-" <> show i)

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-menubar-content"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-menubar-wrapper"

itemRef :: String -> Int -> H.RefLabel
itemRef pfx i = H.RefLabel (pfx <> "-item-" <> show i)

subWrapperRef :: H.RefLabel
subWrapperRef = H.RefLabel "rdx-menubar-subwrapper"

subContentRef :: H.RefLabel
subContentRef = H.RefLabel "rdx-menubar-subcontent"

subItemRef :: String -> Int -> H.RefLabel
subItemRef pfx i = H.RefLabel (pfx <> "-subitem-" <> show i)

findSub :: String -> Array MenuEntry -> Maybe SubData
findSub value = Array.findMap case _ of
  MenuSubEntry sub | sub.value == value -> Just sub
  _ -> Nothing

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

-- | The open menu's index (Nothing if none open).
openIndex :: State -> Maybe Int
openIndex st =
  let v = current st.ctrl
  in if v == "" then Nothing else Array.findIndex (\m -> m.value == v) st.menus

-- | The currently-open menu's entries (empty if none).
openEntries :: State -> Array MenuEntry
openEntries st = fromMaybe [] (openIndex st >>= \i -> Array.index st.menus i <#> _.entries)

component :: forall m. MonadEffect m => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        , initialize = Just Initialize
        }
    }

initialState :: Input -> State
initialState input =
  { ctrl: controllable input.value input.defaultValue
  , presence: if startVal /= "" then Open else Closed
  , menus: input.menus
  , triggerFocus: -1  -- no trigger is the tab stop until focus enters (root holds tabindex=0,
                      -- all triggers -1, matching upstream RovingFocus entry semantics); a
                      -- click/arrow/keyboard interaction migrates the tab stop onto a trigger.
  , itemFocus: 0
  , side: input.side
  , align: input.align
  , offset: input.offset
  , padding: input.padding
  , loop: input.loop
  , dir: input.dir
  , placedSide: input.side
  , placedAlign: input.align
  , idPrefix: input.idPrefix
  , style: input.style
  , contentStyle: input.contentStyle
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , animSub: Nothing
  , contentNode: Nothing
  , triggerIds: []
  , contentIds: []
  , openFocus: Nothing
  , search: ""
  , lastKey: 0.0
  , subOpen: Nothing
  , subFocused: -1
  , subAnchorIdx: -1
  , subPlacedSide: Right
  , subPlacedAlign: Start
  , subOpenFocus: Nothing
  , subSubs: []
  , subPostSub: Nothing
  , subGenTriggerId: ""
  , subGenContentId: ""
  }
  where
  startVal = case input.value of
    Just v -> v
    Nothing -> input.defaultValue

-- | The id for menu index `i` (generated on Initialize; falls back to "" pre-init).
triggerIdAt :: State -> Int -> String
triggerIdAt st i = fromMaybe "" (Array.index st.triggerIds i)

contentIdAt :: State -> Int -> String
contentIdAt st i = fromMaybe "" (Array.index st.contentIds i)

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    rendered = isRendered st.presence
    mOpenI = openIndex st
    orientName = "horizontal"
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      ( [ HH.div
          [ role "menubar"
          , classes st.style.root
          , dataAttr "orientation" orientName
          , HP.style "outline: none;"
          , HP.tabIndex 0
          ]
          (Array.mapWithIndex (renderTrigger st mOpenI) st.menus)
      ]
      -- the popper WRAPPER renders ONLY while `rendered` (a menu Open OR exiting Closing); fully
      -- UNMOUNTED at Closed, matching upstream (no wrapper at closed-rest). finalize re-adopts the
      -- freshly-mounted wrapper into body on each open. position:fixed up front (shrink-to-fit).
      <> ( if rendered then
      [ HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          , dir (dirName st.dir)
          , HP.style "position: fixed;"
          ]
          ( case mOpenI of
              Nothing -> []
              Just i -> [ renderContent st i ]
          )
      ] else [] )
        -- the open SUBMENU layer (anchored to the SubTrigger inside the active menu's content).
        <> maybe [] (\sub -> [ renderSubContent st sub ]) (st.subOpen >>= \v -> findSub v (openEntries st))
      )

renderTrigger :: forall m. State -> Maybe Int -> Int -> Menu -> H.ComponentHTML Action () m
renderTrigger st mOpenI i menu =
  let
    open = mOpenI == Just i
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (triggerRef st.idPrefix i)
        , HP.id (triggerIdAt st i)
        , role "menuitem"
        , classes st.style.trigger
        , aria "haspopup" "menu"
        , aria "expanded" (if open then "true" else "false")
        , dataAttr "orientation" "horizontal"
        , dataAttr "radix-collection-item" ""
        , dataState (if open then "open" else "closed")
        , HP.tabIndex (tabIndexFor st.triggerFocus i)
        , HE.onClick \_ -> TriggerClicked i
        , HE.onKeyDown (TriggerKeyDown i)
        -- focus syncs the roving index onto this trigger (Tab/.focus()/arrow entry), so the
        -- bar tab stop migrates off the root and ArrowLeft/Right rove from here. At rest (no
        -- focus) triggerFocus stays -1 → all triggers tabindex=-1, root=0 (upstream parity).
        , HE.onFocus \_ -> TriggerFocused i
        , HE.onMouseEnter \_ -> TriggerPointerEnter i
        ]
          <> (if open then [ aria "controls" (contentIdAt st i) ] else [])
          <> (if open then [ dataAttr "radix-popper-side" (sideName st.placedSide), dataAttr "radix-popper-align" (alignName st.placedAlign) ] else [])
          -- a disabled trigger carries the HTML `disabled` attr + `data-disabled` (menubar.tsx:239-240);
          -- it is inherently non-focusable (browser) so it drops out of the roving order, and the
          -- cross-menu / openIndex helpers filter it (menubar.tsx:367 getItems().filter(!disabled)).
          <> (if menu.disabled then [ HP.disabled true, dataAttr "disabled" "" ] else [])
          <> portalData st.triggerAttrs
      )
      (map HH.fromPlainHTML menu.trigger)

renderContent :: forall m. State -> Int -> H.ComponentHTML Action () m
renderContent st i =
  let
    menu = fromMaybe { value: "", trigger: [], entries: [], disabled: false } (Array.index st.menus i)
  in
    HH.div
      ( [ HP.ref contentRef
        , HP.id (contentIdAt st i)
        , role "menu"
        , classes st.style.content
        , aria "labelledby" (triggerIdAt st i)
        , aria "orientation" "vertical"
        , dataState (dataStateOf st.presence)
        , dataAttr "side" (sideName st.placedSide)
        , dataAttr "align" (alignName st.placedAlign)
        , dataAttr "orientation" "vertical"
        , dataAttr "radix-menu-content" ""
        , dataAttr "radix-menubar-content" ""
        , dir (dirName st.dir)
        , HP.tabIndex (-1)
        , HP.style st.contentStyle
        , HE.onKeyDown MenuKeyDown
        ] <> portalData st.portalAttrs
      )
      (renderEntries st menu.entries)

dir :: forall r i. String -> HP.IProp r i
dir = HP.attr (HH.AttrName "dir")

renderEntries :: forall m. State -> Array MenuEntry -> Array (H.ComponentHTML Action () m)
renderEntries st entries = _.html (foldl step { idx: 0, html: [] } entries)
  where
  step acc = case _ of
    MenuSeparator -> acc { html = acc.html <> [ renderSep st ] }
    MenuItemEntry item
      | item.disabled -> acc { html = acc.html <> [ renderItem st Nothing item ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderItem st (Just acc.idx) item ]
          }
    MenuCheckboxEntry item
      | item.disabled -> acc { html = acc.html <> [ renderCheckbox st Nothing item ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderCheckbox st (Just acc.idx) item ]
          }
    MenuRadioGroupEntry grp ->
      let
        inner = foldl (radioStep grp.value) { idx: acc.idx, html: [] } grp.options
      in
        acc
          { idx = inner.idx
          , html = acc.html <> [ HH.div [ classes st.style.radioGroup, role "group" ] inner.html ]
          }
    MenuSubEntry sub
      | sub.disabled -> acc { html = acc.html <> [ renderSubTrigger st Nothing sub ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderSubTrigger st (Just acc.idx) sub ]
          }
  radioStep selected innerAcc opt
    | opt.disabled = innerAcc { html = innerAcc.html <> [ renderRadio st selected Nothing opt ] }
    | otherwise = innerAcc
        { idx = innerAcc.idx + 1
        , html = innerAcc.html <> [ renderRadio st selected (Just innerAcc.idx) opt ]
        }

-- | `mIdx = Nothing` ⇒ DISABLED — out of the roving order: tabindex -1, never
-- | highlighted, click is a no-op (the handler guards on disabled).
renderItem :: forall m. State -> Maybe Int -> MenuItem -> H.ComponentHTML Action () m
renderItem st mIdx item =
  HH.div
    ( [ role "menuitem"
      , classes st.style.item
      , HP.tabIndex (maybe (-1) (tabIndexFor st.itemFocus) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.itemFocus then [ dataAttr "highlighted" "" ] else [])
        <> (if item.accent == "" then [] else [ dataAttr "accent-color" item.accent ])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

-- | A SubTrigger row (role=menuitem) opening a nested SubContent. Bare menubar adds
-- | `data-radix-menubar-subtrigger` and carries NO icon (so no trailing shortcut div unless
-- | the caller supplies one). One parent roving index; opens on hover / click / ArrowRight.
renderSubTrigger :: forall m. State -> Maybe Int -> SubData -> H.ComponentHTML Action () m
renderSubTrigger st mIdx sub =
  let
    open = st.subOpen == Just sub.value
    extra = map HH.fromPlainHTML sub.shortcut <> map HH.fromPlainHTML st.style.subIcon
  in HH.div
    ( [ role "menuitem"
      , classes st.style.subTrigger
      , HP.id st.subGenTriggerId
      , aria "haspopup" "menu"
      , aria "expanded" (if open then "true" else "false")
      , dataState (if open then "open" else "closed")
      , HP.tabIndex (maybe (-1) (tabIndexFor st.itemFocus) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "radix-menubar-subtrigger" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> SubTriggerActivate sub.value (fromMaybe (-1) mIdx)
      , HE.onMouseEnter \_ -> SubTriggerEnter sub.value (fromMaybe (-1) mIdx)
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.itemFocus then [ dataAttr "highlighted" "" ] else [])
        <> (if open then
              [ aria "controls" st.subGenContentId
              , dataAttr "radix-popper-side" (sideName st.subPlacedSide)
              , dataAttr "radix-popper-align" (alignName st.subPlacedAlign)
              ] else [])
        <> (if sub.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML sub.label
        <> (if Array.null extra then [] else [ HH.div [ classes st.style.shortcut ] extra ])
    )

-- | The nested SubContent: a separate popper-content-wrapper (portal-adopted into body),
-- | anchored to the open SubTrigger, data-side=right. Bare menubar = NO ScrollArea nesting
-- | (items are direct children) and carries both data-radix-menu-content + -menubar-content.
renderSubContent :: forall m. State -> SubData -> H.ComponentHTML Action () m
renderSubContent st sub =
  HH.div
    [ HP.ref subWrapperRef
    , dataAttr "radix-popper-content-wrapper" ""
    , dir (dirName st.dir)
    , HP.style "position: fixed;"
    ]
    [ HH.div
        ( [ HP.ref subContentRef
          , HP.id st.subGenContentId
          , role "menu"
          , classes st.style.subContent
          , aria "labelledby" st.subGenTriggerId
          , aria "orientation" "vertical"
          , dataState "open"
          , dataAttr "side" (sideName st.subPlacedSide)
          , dataAttr "align" (alignName st.subPlacedAlign)
          , dataAttr "orientation" "vertical"
          , dataAttr "radix-menu-content" ""
          , dataAttr "radix-menubar-content" ""
          , dir (dirName st.dir)
          , HP.tabIndex (-1)
          , HP.style st.contentStyle
          , HE.onKeyDown SubKeyDown
          ] <> portalData st.portalAttrs
        )
        (renderSubEntries st sub.entries)
    ]

renderSubEntries :: forall m. State -> Array MenuEntry -> Array (H.ComponentHTML Action () m)
renderSubEntries st entries = _.html (foldl step { idx: 0, html: [] } entries)
  where
  step acc = case _ of
    MenuSeparator -> acc { html = acc.html <> [ renderSep st ] }
    MenuItemEntry item
      | item.disabled -> acc { html = acc.html <> [ renderSubItem st Nothing item ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderSubItem st (Just acc.idx) item ]
          }
    _ -> acc

renderSubItem :: forall m. State -> Maybe Int -> MenuItem -> H.ComponentHTML Action () m
renderSubItem st mIdx item =
  HH.div
    ( [ role "menuitem"
      , classes st.style.item
      , HP.tabIndex (maybe (-1) (tabIndexFor st.subFocused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> SubItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (subItemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.subFocused then [ dataAttr "highlighted" "" ] else [])
        <> (if item.accent == "" then [] else [ dataAttr "accent-color" item.accent ])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

renderSep :: forall m. State -> H.ComponentHTML Action () m
renderSep st =
  HH.div
    [ classes st.style.separator
    , role "separator"
    , aria "orientation" "horizontal"
    ]
    []

checkAria :: CheckState -> String
checkAria = case _ of
  Checked -> "true"
  Unchecked -> "false"
  Indeterminate -> "mixed"

checkData :: CheckState -> String
checkData = case _ of
  Checked -> "checked"
  Unchecked -> "unchecked"
  Indeterminate -> "indeterminate"

-- | The Presence-gated ItemIndicator span (rendered only when checked/indeterminate). The bare
-- | @radix-ui/react-menubar renders the indicator BEFORE the label (child order), unlike the
-- | styled Themes menus — so the indicator leads the item's children.
renderIndicator :: forall m. State -> Array HH.PlainHTML -> CheckState -> Array (H.ComponentHTML Action () m)
renderIndicator st icon cs
  | cs == Unchecked = []
  | otherwise =
      [ HH.span
          [ classes st.style.indicator, dataState (checkData cs) ]
          (map HH.fromPlainHTML icon)
      ]

renderCheckbox :: forall m. State -> Maybe Int -> CheckItem -> H.ComponentHTML Action () m
renderCheckbox st mIdx item =
  HH.div
    ( [ role "menuitemcheckbox"
      , classes st.style.checkboxItem
      , aria "checked" (checkAria item.check)
      , dataState (checkData item.check)
      , HP.tabIndex (maybe (-1) (tabIndexFor st.itemFocus) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.itemFocus then [ dataAttr "highlighted" "" ] else [])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( renderIndicator st st.style.checkIndicator item.check
        <> map HH.fromPlainHTML item.label
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

renderRadio :: forall m. State -> String -> Maybe Int -> RadioOption -> H.ComponentHTML Action () m
renderRadio st selected mIdx opt =
  let
    cs = if selected == opt.value then Checked else Unchecked
  in
    HH.div
      ( [ role "menuitemradio"
        , classes st.style.radioItem
        , aria "checked" (checkAria cs)
        , dataState (checkData cs)
        , HP.tabIndex (maybe (-1) (tabIndexFor st.itemFocus) mIdx)
        , dataAttr "radix-collection-item" ""
        , dataAttr "orientation" "vertical"
        , HE.onClick \_ -> ItemClicked opt.value
        ]
          <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
          <> (if mIdx == Just st.itemFocus then [ dataAttr "highlighted" "" ] else [])
          <> (if opt.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
      )
      ( renderIndicator st st.style.radioIndicator cs
          <> map HH.fromPlainHTML opt.label
          <> (if Array.null opt.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML opt.shortcut) ])
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    st <- H.get
    -- one trigger id + one content id per menu, in order (so aria-labelledby/controls resolve).
    tids <- traverse (const useId) st.menus
    cids <- traverse (const useId) st.menus
    stid <- useId
    scid <- useId
    H.modify_ _ { triggerIds = tids, contentIds = cids, subGenTriggerId = stid, subGenContentId = scid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.value st.ctrl
      , menus = input.menus
      , side = input.side
      , align = input.align
      , offset = input.offset
      , padding = input.padding
      , loop = input.loop
      , dir = input.dir
      , idPrefix = input.idPrefix
      , style = input.style
      , contentStyle = input.contentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      }
  TriggerFocused i -> H.modify_ _ { triggerFocus = i }
  TriggerClicked i -> do
    st <- H.get
    -- the trigger that was clicked becomes the bar tab stop; toggle/switch its menu.
    H.modify_ _ { triggerFocus = i }
    if openIndex st == Just i then closeMenu true
    else if current st.ctrl /= "" then switchTo i (-1) Nothing
    else openMenuAt i (-1) Nothing
  -- On a CLOSED trigger ArrowDown opens + highlights the first item (APG menubar). The
  -- horizontal arrows / Home / End rove the BAR. (When open, the content owns key handling.)
  TriggerKeyDown i ke -> do
    st <- H.get
    when (current st.ctrl == "") case KE.key ke of
      "ArrowDown" -> liftEffect (preventDefault (KE.toEvent ke)) *> (H.modify_ _ { triggerFocus = i } *> openMenuAt i 0 (Just 0))
      "ArrowUp" -> liftEffect (preventDefault (KE.toEvent ke)) *> (H.modify_ _ { triggerFocus = i } *> openMenuAt i (lastItem st i) (Just (lastItem st i)))
      -- Enter / Space on a CLOSED trigger open the menu AND highlight the first item
      -- (upstream menubar.tsx:260-269: onMenuToggle + wasKeyboardTriggerOpenRef=true →
      -- onEntryFocus focuses the first item, exactly like ArrowDown). preventDefault stops
      -- the synthetic click that would otherwise re-open via the click path (no highlight).
      "Enter" -> liftEffect (preventDefault (KE.toEvent ke)) *> (H.modify_ _ { triggerFocus = i } *> openMenuAt i 0 (Just 0))
      " " -> liftEffect (preventDefault (KE.toEvent ke)) *> (H.modify_ _ { triggerFocus = i } *> openMenuAt i 0 (Just 0))
      key -> do
        let
          cfg = { orientation: Horizontal, dir: st.dir, loop: st.loop }
          -- rove over the ENABLED triggers only (a disabled trigger is non-focusable and out of
          -- the roving order): navigate within the enabled-index list, then map the position back.
          enabled = enabledTriggers st
          curPos = fromMaybe (-1) (Array.findIndex (_ == st.triggerFocus) enabled)
        case navigate cfg { count: Array.length enabled, current: curPos } key of
          Stay -> pure unit
          MoveTo posJ -> case Array.index enabled posJ of
            Nothing -> pure unit
            Just j -> do
              liftEffect (preventDefault (KE.toEvent ke))
              H.modify_ _ { triggerFocus = j }
              mt <- H.getHTMLElementRef (triggerRef st.idPrefix j)
              for_ mt (liftEffect <<< HTMLElement.focus)
  -- open-on-hover: while a menu is open, entering a DIFFERENT trigger switches the open menu
  -- to it and focuses that trigger (the signature menubar behavior).
  TriggerPointerEnter i -> do
    st <- H.get
    when (current st.ctrl /= "" && openIndex st /= Just i) do
      H.modify_ _ { triggerFocus = i }
      mt <- H.getHTMLElementRef (triggerRef st.idPrefix i)
      for_ mt (liftEffect <<< HTMLElement.focus)
      switchTo i (-1) Nothing
  AfterOpen -> do
    reposition
    finalize true
  AfterClose -> do
    mnode <- H.getHTMLElementRef contentRef
    armed <- case mnode of
      Nothing -> pure false
      Just node -> do
        animates <- liftEffect (hasAnimation node)
        if animates then do
          sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
          H.modify_ _ { animSub = Just sub }
          pure true
        else pure false
    if armed then do
      mwrap <- H.getHTMLElementRef wrapperRef
      for_ mwrap \wrap -> liftEffect (Envelope.reAdoptBeforeTrail wrap)
    else finishClose
  AnimDone -> finishClose
  EscapePressed -> closeMenu true
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside (closeMenu false)
  MenuKeyDown ke -> do
    st <- H.get
    let
      -- the open menu's VERTICAL item roving does not wrap (menu.tsx:362 loop default false);
      -- st.loop is the menubar's HORIZONTAL trigger-bar loop (cross-menu), a separate axis.
      cfg = { orientation: Vertical, dir: st.dir, loop: false }
      pos = { count: itemCount (openEntries st), current: st.itemFocus }
      -- the focused entry's value IF it is a SubTrigger: ArrowRight (and Enter/Space) must OPEN
      -- the sub, NOT switch to the adjacent top menu (the cross-menu vs sub guard).
      mFocusedSub = do
        v <- enabledValueAt st.itemFocus (openEntries st)
        _ <- findSub v (openEntries st)
        pure v
      -- direction-aware cross-menu / sub-open keys (menubar.tsx:358 prevMenuKey, menu.tsx:31-34
      -- SUB_OPEN_KEYS). In RTL the horizontal axis mirrors: NEXT menu / sub-open is ArrowLeft,
      -- PREV menu is ArrowRight.
      isRTL = st.dir == RTL
      nextMenuKey = if isRTL then "ArrowLeft" else "ArrowRight"
      prevMenuKey = if isRTL then "ArrowRight" else "ArrowLeft"
    case KE.key ke of
      k | k == nextMenuKey, Just v <- mFocusedSub -> liftEffect (preventDefault (KE.toEvent ke)) *> openSub v st.itemFocus (Just 0)
      -- cross-menu: the next/prev-menu key from inside the content closes it and opens the
      -- adjacent trigger's menu (handled via the menu list + wrap, NOT the vertical roving).
      k | k == nextMenuKey -> liftEffect (preventDefault (KE.toEvent ke)) *> adjacentMenu st 1
      k | k == prevMenuKey -> liftEffect (preventDefault (KE.toEvent ke)) *> adjacentMenu st (-1)
      -- Enter/Space SELECT the focused item + close (upstream re-exports menu.tsx:667-680
      -- SELECTION_KEYS). Keyboard activation of items was previously impossible.
      key
        -- Enter/Space on a SubTrigger OPENS the sub (focus its first item), not select.
        | (key == "Enter" || key == " "), Just v <- mFocusedSub ->
            liftEffect (preventDefault (KE.toEvent ke)) *> openSub v st.itemFocus (Just 0)
        | (key == "Enter" || key == " ") && st.itemFocus >= 0 -> do
            liftEffect (preventDefault (KE.toEvent ke))
            for_ (enabledValueAt st.itemFocus (openEntries st)) \v ->
              handleAction (ItemClicked v)
        -- Typeahead (radix useTypeahead): a printable character moves focus to the next
        -- matching item in the open menu (letters fall through the Enter/Space guards above).
        | Typeahead.isTypeaheadChar key (st.search /= "") -> do
            liftEffect (preventDefault (KE.toEvent ke))
            typeaheadMenu key
        -- Tab/Shift+Tab preventDefault inside the open menu (menu.tsx:531-532): focus trapped.
        | key == "Tab" -> liftEffect (preventDefault (KE.toEvent ke))
        | otherwise -> case navigatePaged cfg pos key of
            Stay -> pure unit
            MoveTo idx -> focusMenuItem idx
  -- ── submenu ──
  SubTriggerEnter value idx -> openSub value idx Nothing
  SubTriggerActivate value idx -> openSub value idx (Just 0)
  SubAfterOpen -> do
    repositionSub
    st <- H.get
    mwrap <- H.getHTMLElementRef wrapperRef
    mswrap <- H.getHTMLElementRef subWrapperRef
    for_ mwrap (liftEffect <<< Envelope.reAdoptBeforeTrail)
    for_ mswrap (liftEffect <<< Envelope.reAdoptBeforeTrail)
    for_ st.subOpenFocus \i -> do
      mitem <- H.getHTMLElementRef (subItemRef st.idPrefix i)
      for_ mitem (liftEffect <<< HTMLElement.focus)
  SubReposition -> repositionSub
  SubKeyDown ke -> do
    st <- H.get
    let
      key = KE.key ke
      subEntries = fromMaybe [] (map _.entries (st.subOpen >>= \v -> findSub v (openEntries st)))
      cfg = { orientation: Vertical, dir: st.dir, loop: st.loop }
      pos = { count: itemCount subEntries, current: st.subFocused }
      -- SUB_CLOSE_KEYS (menu.tsx:35-38): LTR=ArrowLeft, RTL=ArrowRight (mirrors sub-open).
      subCloseKey = if st.dir == RTL then "ArrowRight" else "ArrowLeft"
    case key of
      k | k == subCloseKey -> liftEffect (preventDefault (KE.toEvent ke)) *> closeSub
      "Escape" -> liftEffect (preventDefault (KE.toEvent ke)) *> closeSub
      _
        | (key == "Enter" || key == " ") && st.subFocused >= 0 -> do
            liftEffect (preventDefault (KE.toEvent ke))
            for_ (enabledValueAt st.subFocused subEntries) \v -> handleAction (SubItemClicked v)
        | otherwise -> case navigatePaged cfg pos key of
            Stay -> pure unit
            MoveTo idx -> do
              H.modify_ _ { subFocused = idx }
              mwrap <- H.getHTMLElementRef wrapperRef
              mswrap <- H.getHTMLElementRef subWrapperRef
              mitem <- H.getHTMLElementRef (subItemRef st.idPrefix idx)
              liftEffect $ Dom.queueMicrotask do
                for_ mwrap Envelope.reAdoptBeforeTrail
                for_ mswrap Envelope.reAdoptBeforeTrail
                for_ mitem HTMLElement.focus
  SubItemClicked value -> do
    st <- H.get
    let subEntries = fromMaybe [] (map _.entries (st.subOpen >>= \v -> findSub v (openEntries st)))
        pick = case _ of
          MenuItemEntry it | it.value == value -> Just it.disabled
          _ -> Nothing
        mDisabled = Array.findMap pick subEntries
    when (maybe true not mDisabled) do
      for_ (openIndex st >>= Array.index st.menus) \menu ->
        H.raise (ItemSelected { menu: menu.value, item: value })
      closeMenuAndSub
  CloseSub -> closeSub
  ItemClicked value -> do
    st <- H.get
    -- a disabled item is non-interactive — clicking it neither selects nor closes.
    let
      pick = case _ of
        MenuItemEntry it | it.value == value -> Just it.disabled
        MenuCheckboxEntry it | it.value == value -> Just it.disabled
        MenuRadioGroupEntry grp -> map _.disabled (Array.find (\o -> o.value == value) grp.options)
        _ -> Nothing
      mDisabled = Array.findMap pick (openEntries st)
    when (maybe true not mDisabled) do
      for_ (openIndex st >>= Array.index st.menus) \menu ->
        H.raise (ItemSelected { menu: menu.value, item: value })
      closeMenu true
  Reposition -> reposition

-- | The last focusable item index of menu `i` (for ArrowUp-open → highlight last).
lastItem :: State -> Int -> Int
lastItem st i = case Array.index st.menus i of
  Just menu -> itemCount menu.entries - 1
  Nothing -> 0

-- | Move to the menu `delta` away from the open one (wrapping), closing the current content
-- | and opening the adjacent one focused into its content. The cross-menu arrow behavior.
-- | The indices of the ENABLED top-level triggers (disabled triggers drop out of the roving
-- | order AND the cross-menu list — menubar.tsx:226 focusable={!disabled}, :367 filter(!disabled)).
enabledTriggers :: State -> Array Int
enabledTriggers st =
  Array.filter (\i -> maybe false (not <<< _.disabled) (Array.index st.menus i))
    (Array.range 0 (Array.length st.menus - 1))

adjacentMenu :: forall m. MonadEffect m => State -> Int -> H.HalogenM State Action () Output m Unit
adjacentMenu st delta = case openIndex st of
  Nothing -> pure unit
  Just i -> do
    let
      -- navigate over the ENABLED triggers only, so a disabled menu is skipped. loop=true wraps
      -- the cross-menu axis (menubar.tsx:373 wrapArray); loop=false slices past the end (no wrap).
      enabled = enabledTriggers st
      ne = Array.length enabled
      curPos = fromMaybe (-1) (Array.findIndex (_ == i) enabled)
      rawPos = curPos + delta
      posJ = if st.loop then (((rawPos `mod` ne) + ne) `mod` ne) else rawPos
      mJ = if curPos >= 0 && posJ >= 0 && posJ < ne then Array.index enabled posJ else Nothing
    case mJ of
      Just j | j /= i -> do
        H.modify_ _ { triggerFocus = j }
        switchTo j (-1) Nothing
      _ -> pure unit

-- | Open the submenu `value` (SubTrigger at the active content's roving index `idx`). The
-- | SubTrigger becomes the content's roving tab stop. See DropdownMenu.openSub.
openSub :: forall m. MonadEffect m => String -> Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
openSub value idx focus = do
  st <- H.get
  when (current st.ctrl /= "" && st.subOpen /= Just value) do
    H.modify_ _
      { subOpen = Just value, itemFocus = idx, subAnchorIdx = idx, subFocused = -1
      , subOpenFocus = focus, subPlacedSide = Right, subPlacedAlign = Start
      }
    psid <- scheduleSubAfterOpen
    H.modify_ _ { subPostSub = Just psid }

scheduleSubAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleSubAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (SubAfterOpen <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

repositionSub :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
repositionSub = do
  st <- H.get
  manchor <- H.getHTMLElementRef (itemRef st.idPrefix st.subAnchorIdx)
  mwrap <- H.getHTMLElementRef subWrapperRef
  mfloat <- H.getHTMLElementRef subContentRef
  case manchor, mwrap, mfloat of
    Just anchor, Just wrapper, Just floating -> do
      placed <- liftEffect (Popper.positionWrapper
        { anchor, wrapper, floating, side: Right, align: Start, offset: 0.0, padding: st.padding })
      when (placed.placement.side /= st.subPlacedSide || placed.placement.align /= st.subPlacedAlign) $
        H.modify_ _ { subPlacedSide = placed.placement.side, subPlacedAlign = placed.placement.align }
    _, _, _ -> pure unit

closeSub :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeSub = do
  st <- H.get
  when (isJust st.subOpen) do
    for_ st.subPostSub H.unsubscribe
    H.modify_ _ { subOpen = Nothing, subFocused = -1, subPostSub = Nothing }
    mwrap <- H.getHTMLElementRef wrapperRef
    mtrig <- H.getHTMLElementRef (itemRef st.idPrefix st.subAnchorIdx)
    liftEffect $ Dom.queueMicrotask do
      for_ mwrap Envelope.reAdoptBeforeTrail
      for_ mtrig HTMLElement.focus

closeMenuAndSub :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenuAndSub = do
  H.modify_ _ { subOpen = Nothing, subFocused = -1 }
  closeMenu true

openMenuAt :: forall m. MonadEffect m => Int -> Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
openMenuAt i focusedIdx openFocus = do
  st <- H.get
  for_ (Array.index st.menus i) \menu -> when (current st.ctrl /= menu.value) do
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    for_ st.animSub H.unsubscribe
    H.modify_ _ { ctrl = (change menu.value st.ctrl).next, presence = Open, itemFocus = focusedIdx, restoreEl = mprev, openFocus = openFocus, animSub = Nothing }
    H.raise (OpenChanged (Just menu.value))
    mcNode <- map HTMLElement.toNode <$> H.getHTMLElementRef contentRef
    win <- liftEffect Popper.windowTarget
    let docTarget = HTMLDocument.toEventTarget doc
    escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
    ptrSub <- H.subscribe (Dismiss.pointerDown docTarget PointerDown)
    scrollSub <- H.subscribe (eventListener (EventType "scroll") win (\_ -> Just Reposition))
    resizeSub <- H.subscribe (eventListener (EventType "resize") win (\_ -> Just Reposition))
    psid <- scheduleAfterOpen
    H.modify_ _
      { contentNode = mcNode
      , subs = [ escSub, ptrSub, scrollSub, resizeSub ]
      , postSub = Just psid
      }

-- | Switch the open menu to menu `i` WITHOUT tearing down the open-time subscriptions (the
-- | bar stays "open"). Re-points the open-value, resets item focus, and schedules a reposition
-- | + focus against the NEW trigger/content. Used by cross-menu arrow + open-on-hover.
switchTo :: forall m. MonadEffect m => Int -> Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
switchTo i focusedIdx openFocus = do
  st <- H.get
  for_ (Array.index st.menus i) \menu -> when (current st.ctrl /= menu.value) do
    -- ensure the open-time subscriptions exist (switching from a closed bar shouldn't happen,
    -- but if the previous open had no subs we (re)arm via openMenuAt instead).
    if Array.null st.subs then openMenuAt i focusedIdx openFocus
    else do
      H.modify_ _ { ctrl = (change menu.value st.ctrl).next, presence = Open, itemFocus = focusedIdx, openFocus = openFocus }
      H.raise (OpenChanged (Just menu.value))
      mcNode <- map HTMLElement.toNode <$> H.getHTMLElementRef contentRef
      psid <- scheduleAfterOpen
      H.modify_ _ { contentNode = mcNode, postSub = Just psid }

scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | Adopt the wrapper into body + (non-modal) add focus guards; focus the content (click-open)
-- | or the highlighted item (keyboard-open). NON-MODAL: NO lockScroll / hideOthers.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  mfocus <- if focusToo
    then case st.openFocus of
      Just idx -> H.getHTMLElementRef (itemRef st.idPrefix idx)
      Nothing -> H.getHTMLElementRef contentRef
    else pure Nothing
  case mbody, mwrap of
    Just _, Just wrap -> liftEffect do
      -- adopt BEFORE the trail focus-guard, not at body end: on a hover-SWITCH the guards
      -- already exist, so a plain appendChild would land the new content AFTER the trail guard
      -- (breaking body order). reAdoptBeforeTrail appends when there is no trail guard yet
      -- (initial open) and inserts before it once it exists (switch) — matching upstream.
      Envelope.reAdoptBeforeTrail wrap
      when focusToo do
        Envelope.addFocusGuards
        for_ mfocus HTMLElement.focus
    _, _ -> pure unit

-- | Close the open menu. `restore` returns focus to the trigger — true for Escape / selection /
-- | programmatic close, but FALSE for an outside pointer-dismiss (menubar.tsx:317,328-345
-- | hasInteractedOutsideRef: the user clicked elsewhere, so focus must NOT snap back).
closeMenu :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
closeMenu restore = do
  st <- H.get
  when (current st.ctrl /= "") do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    when restore $ for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change "" st.ctrl).next, presence = present false st.presence, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing, openFocus = Nothing, search = "", subOpen = Nothing, subFocused = -1 }
    H.raise (OpenChanged Nothing)
    psid <- scheduleAfterClose
    H.modify_ _ { postSub = Just psid }

-- | Move the open menu's roving tab stop to item `idx` and focus it (shared by arrow nav +
-- | typeahead). The focused-state re-render re-parents the wrapper; re-adopt before focusing.
focusMenuItem :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusMenuItem idx = do
  st <- H.get
  H.modify_ _ { itemFocus = idx }
  mwrap <- H.getHTMLElementRef wrapperRef
  mitem <- H.getHTMLElementRef (itemRef st.idPrefix idx)
  liftEffect $ Dom.queueMicrotask do
    for_ mwrap Envelope.reAdoptBeforeTrail
    for_ mitem HTMLElement.focus

-- | Read the open menu's item labels (textContent incl. shortcut — radix `textValue`) over the
-- | navigable index space, so the pure matcher works on the same indices `itemFocus` uses.
readItemTexts :: forall m. MonadEffect m => String -> Int -> H.HalogenM State Action () Output m (Array String)
readItemTexts pfx count =
  traverse
    ( \i -> do
        mel <- H.getHTMLElementRef (itemRef pfx i)
        case mel of
          Just el -> liftEffect (textContent (HTMLElement.toNode el))
          Nothing -> pure ""
    )
    (Array.range 0 (count - 1))

-- | One typeahead keystroke inside the open menu (radix useTypeahead). Lazy `performance.now()`
-- | reset (no idle timer → no spurious re-render): >1s starts fresh, else extends the buffer.
typeaheadMenu :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
typeaheadMenu key = do
  st <- H.get
  now <- liftEffect Dom.now
  let
    expired = now - st.lastKey > 1000.0
    search' = (if expired then "" else st.search) <> key
  texts <- readItemTexts st.idPrefix (itemCount (openEntries st))
  for_ (Typeahead.nextMatch search' texts st.itemFocus) focusMenuItem
  H.modify_ _ { search = search', lastKey = now }

scheduleAfterClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterClose = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterClose <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  liftEffect Envelope.removeFocusGuards
  H.modify_ _ { presence = finishExit st.presence, animSub = Nothing, postSub = Nothing }

reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  case openIndex st of
    Nothing -> pure unit
    Just i -> do
      manchor <- H.getHTMLElementRef (triggerRef st.idPrefix i)
      mwrap <- H.getHTMLElementRef wrapperRef
      mfloat <- H.getHTMLElementRef contentRef
      case manchor, mwrap, mfloat of
        Just anchor, Just wrapper, Just floating -> do
          placed <- liftEffect (Popper.positionWrapper
            { anchor, wrapper, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
          when (placed.placement.side /= st.placedSide || placed.placement.align /= st.placedAlign) $
            H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
        _, _, _ -> pure unit

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen mv a -> do
    st <- H.get
    case mv of
      Nothing -> closeMenu true
      Just v -> case Array.findIndex (\m -> m.value == v) st.menus of
        Just i -> openMenuAt i (-1) Nothing
        Nothing -> pure unit
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    let v = current st.ctrl
    pure (Just (reply (if v == "" then Nothing else Just v)))
