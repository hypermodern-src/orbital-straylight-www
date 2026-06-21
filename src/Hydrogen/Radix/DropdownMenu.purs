-- | Hydrogen.Radix.DropdownMenu — a button-triggered menu (radix `DropdownMenu`).
-- |
-- | THE TEMPLATE for a Float + RovingFocus combination (ContextMenu, Menubar,
-- | Select all follow it). It is `Popover` (trigger + Popper-positioned content +
-- | Escape/pointer-outside dismissal + reposition + portal-to-body) PLUS a roving
-- | menu:
-- |   * items are DATA (`items :: Array MenuItem`);
-- |   * `role=menu` content with `role=menuitem` buttons, a roving tab stop, and
-- |     ArrowDown/Up navigation via `RovingFocus.navigate` (Vertical) → focus the
-- |     item ref;
-- |   * open focuses the first item; selecting an item raises `ItemSelected` and
-- |     closes.
-- |
-- | Portal-to-body follows the Popover template: the content is ALWAYS mounted
-- | (hidden with display:none when closed) so Halogen only patches — never removes —
-- | the node, which makes adopting it into `body` safe. On open we schedule
-- | `AfterOpen` via a one-shot rAF; it repositions then `finalize`s (adopt into body +
-- | focus the first item on the following frame). Reposition (scroll/resize) re-asserts
-- | the portal without re-focusing, because the placement modify re-parents the content
-- | out of body.
-- |
-- | Exit animation (Presence): on close the wrapper + content STAY mounted (the wrapper keeps
-- | its popper position style, the content flips to data-state="closed") and the modal envelope
-- | (scroll-lock marker, focus guards, hideOthers) stays in place until the content's CSS exit
-- | animation ends — THEN the envelope is torn down and the content drops to display:none. The
-- | pointer block (body pointer-events:none + content pointer-events:auto) is released at the
-- | START of the close (radix RemoveScroll disables the moment open flips false). If the content
-- | has no exit animation the close is immediate. Mirrors Dialog's Presence close lifecycle.
-- |
-- | v1 (by feel): single instance (fixed ids), no typeahead, no submenus. Those are
-- | noted follow-ups.
module Hydrogen.Radix.DropdownMenu
  ( component
  , MenuItem
  , CheckItem
  , RadioGroupData
  , RadioOption
  , GroupData
  , SubData
  , MenuEntry(..)
  , CheckState(..)
  , menuItem
  , menuSeparator
  , menuCheckbox
  , menuRadioGroup
  , menuGroup
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
import Data.Maybe (Maybe(..), maybe, isJust, fromMaybe)
import Data.Traversable (for)
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
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigatePaged, tabIndexFor)
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
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type MenuItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML  -- right-aligned shortcut hint (empty = none)
  , accent :: String                -- per-item data-accent-color (e.g. "red"); "" = none
  , disabled :: Boolean
  }

-- | Tri-state check status for a CheckboxItem (radix CheckboxItem checked may be a
-- | boolean OR 'indeterminate'). data-state ↔ aria-checked:
-- |   Checked       → data-state=checked       aria-checked=true   (indicator present)
-- |   Unchecked     → data-state=unchecked     aria-checked=false  (indicator absent)
-- |   Indeterminate → data-state=indeterminate aria-checked=mixed  (indicator present)
data CheckState = Checked | Unchecked | Indeterminate

derive instance eqCheckState :: Eq CheckState

-- | A CheckboxItem (role=menuitemcheckbox). Like a MenuItem but carries a tri-state
-- | `check` and renders a Presence-gated ItemIndicator span when checked/indeterminate.
type CheckItem =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , check :: CheckState
  , disabled :: Boolean
  }

-- | One RadioItem option inside a RadioGroup (role=menuitemradio).
type RadioOption =
  { value :: String
  , label :: Array HH.PlainHTML
  , shortcut :: Array HH.PlainHTML
  , disabled :: Boolean
  }

-- | A RadioGroup (role=group wrapper) with a single selected `value`. Each option is
-- | menuitemradio with aria-checked gated on `value == option.value`.
type RadioGroupData =
  { value :: String
  , options :: Array RadioOption
  }

-- | A menu is a list of ENTRIES: focusable items interleaved with non-focusable
-- | separators. Roving focus + ArrowDown/Up navigate the items only; separators are
-- | skipped (they carry no ref and no role=menuitem). CheckboxItem and RadioItem are
-- | focusable items too (role=menuitemcheckbox / menuitemradio) — they take roving
-- | indices alongside plain items.
-- | A labelled group of plain items (radix `DropdownMenu.Group` + `DropdownMenu.Label`).
-- | Renders a role=group wrapper whose aria-labelledby points at a NON-interactive Label
-- | div (NOT a role=menuitem, NOT in the roving order). The inner items DO participate in
-- | the roving order, sharing the same idx counter as their siblings (like a RadioGroup).
type GroupData =
  { label :: Array HH.PlainHTML  -- the Label heading ([] = unlabelled group, aria-labelledby omitted)
  , items :: Array MenuItem
  }

-- | A SUBMENU entry (radix `DropdownMenu.Sub`): a SubTrigger row (role=menuitem,
-- | aria-haspopup=menu) that opens a nested SubContent (its own role=menu, positioned to
-- | the side). The SubTrigger participates in the PARENT roving order as one focusable; the
-- | nested `entries` get their OWN roving order inside the SubContent. One level (the realistic
-- | depth + what the golden exercises); the `entries` may themselves contain plain items +
-- | separators.
type SubData =
  { value :: String                 -- identifies the sub (aria ids derived from it)
  , label :: Array HH.PlainHTML      -- the SubTrigger label
  , shortcut :: Array HH.PlainHTML   -- usually empty — the chevron icon is appended automatically
  , disabled :: Boolean
  , entries :: Array MenuEntry       -- the nested SubContent entries
  }

data MenuEntry
  = MenuItemEntry MenuItem
  | MenuSeparator
  | MenuCheckboxEntry CheckItem
  | MenuRadioGroupEntry RadioGroupData
  | MenuGroupEntry GroupData
  | MenuSubEntry SubData

-- | Smart constructor for a plain item (no shortcut/accent, enabled).
menuItem :: String -> Array HH.PlainHTML -> MenuEntry
menuItem value label = MenuItemEntry { value, label, shortcut: [], accent: "", disabled: false }

menuSeparator :: MenuEntry
menuSeparator = MenuSeparator

-- | Smart constructor for a checkbox item.
menuCheckbox :: String -> Array HH.PlainHTML -> CheckState -> MenuEntry
menuCheckbox value label check = MenuCheckboxEntry { value, label, shortcut: [], check, disabled: false }

-- | Smart constructor for a radio group.
menuRadioGroup :: String -> Array RadioOption -> MenuEntry
menuRadioGroup value options = MenuRadioGroupEntry { value, options }

-- | Smart constructor for a labelled item group.
menuGroup :: Array HH.PlainHTML -> Array MenuItem -> MenuEntry
menuGroup label items = MenuGroupEntry { label, items }

-- | Smart constructor for a submenu (SubTrigger label + nested entries).
menuSub :: String -> Array HH.PlainHTML -> Array MenuEntry -> MenuEntry
menuSub value label entries = MenuSubEntry { value, label, shortcut: [], disabled: false, entries }

-- | The number of focusable items in the ROVING order — non-separator AND
-- | non-disabled (upstream menu.tsx:540 `getItems().filter(!disabled)`, :720
-- | `focusable={!disabled}`). Disabled items render but are excluded from the roving
-- | order entirely, so arrows skip OVER them. This is the navigate() modulus.
itemCount :: Array MenuEntry -> Int
itemCount = foldl (\n e -> n + entryFocusables e) 0

-- | The number of focusable (enabled) roving items an entry contributes: a plain item
-- | or checkbox is 1 (0 if disabled), a radio group is its enabled-option count, a
-- | separator is 0.
entryFocusables :: MenuEntry -> Int
entryFocusables = case _ of
  MenuItemEntry item -> if item.disabled then 0 else 1
  MenuCheckboxEntry item -> if item.disabled then 0 else 1
  MenuRadioGroupEntry grp -> Array.length (Array.filter (not <<< _.disabled) grp.options)
  MenuGroupEntry grp -> Array.length (Array.filter (not <<< _.disabled) grp.items)
  MenuSubEntry sub -> if sub.disabled then 0 else 1
  MenuSeparator -> 0

-- | The enabled focusable value at roving index `n` (the keyboard-selection target).
-- | Mirrors the same enabled-only ordering `renderEntries` assigns refs/tabindex over,
-- | now spanning plain items, checkbox items, and radio options.
enabledValueAt :: Int -> Array MenuEntry -> Maybe String
enabledValueAt n entries = Array.index (Array.concatMap enabledValues entries) n
  where
  enabledValues = case _ of
    MenuItemEntry item | not item.disabled -> [ item.value ]
    MenuCheckboxEntry item | not item.disabled -> [ item.value ]
    MenuRadioGroupEntry grp -> map _.value (Array.filter (not <<< _.disabled) grp.options)
    MenuGroupEntry grp -> map _.value (Array.filter (not <<< _.disabled) grp.items)
    MenuSubEntry sub | not sub.disabled -> [ sub.value ]
    _ -> []

type Style =
  { trigger :: ClassNames
  , content :: ClassNames
  , scrollRoot :: ClassNames     -- rt-ScrollAreaRoot
  , scrollViewport :: ClassNames -- rt-ScrollAreaViewport
  , menuViewport :: ClassNames   -- rt-BaseMenuViewport (the items wrapper)
  , focusRing :: ClassNames      -- rt-ScrollAreaViewportFocusRing
  , item :: ClassNames
  , shortcut :: ClassNames    -- the right-aligned shortcut span
  , separator :: ClassNames
  , checkboxItem :: ClassNames   -- rt-BaseMenuCheckboxItem rt-BaseMenuItem … (no rt-reset)
  , radioGroup :: ClassNames     -- rt-BaseMenuRadioGroup … (role=group wrapper)
  , radioItem :: ClassNames      -- rt-BaseMenuItem rt-BaseMenuRadioItem …
  , indicator :: ClassNames      -- rt-BaseMenuItemIndicator … (the gated indicator span)
  , group :: ClassNames          -- rt-BaseMenuGroup … (role=group wrapper for a labelled group)
  , groupLabel :: ClassNames     -- rt-BaseMenuLabel … (the non-interactive labelling div)
  , checkIndicator :: Array HH.PlainHTML  -- the checkbox indicator svg (full <svg>, Themes quirk class)
  , radioIndicator :: Array HH.PlainHTML  -- the radio indicator svg (full <svg>)
  , subTrigger :: ClassNames     -- rt-BaseMenuItem rt-BaseMenuSubTrigger … (the SubTrigger row)
  , subContent :: ClassNames     -- the SubContent content classes (… rt-BaseMenuSubContent …)
  , subIcon :: Array HH.PlainHTML -- the SubTrigger chevron svg (lives inside a shortcut div)
  , subContentColor :: String    -- the SubContent's bare `color` attr (Themes quirk, e.g. "indigo"); "" = none
  }

defaultStyle :: Style
defaultStyle =
  { trigger: cn "rdx-dropdown-trigger"
  , content: cn "rdx-dropdown-content"
  , scrollRoot: cn "rdx-dropdown-scroll-root"
  , scrollViewport: cn "rdx-dropdown-scroll-viewport"
  , menuViewport: cn "rdx-dropdown-viewport"
  , focusRing: cn "rdx-dropdown-focus-ring"
  , item: cn "rdx-dropdown-item"
  , shortcut: cn "rdx-dropdown-shortcut"
  , separator: cn "rdx-dropdown-separator"
  , checkboxItem: cn "rdx-dropdown-checkbox-item"
  , radioGroup: cn "rdx-dropdown-radio-group"
  , radioItem: cn "rdx-dropdown-radio-item"
  , indicator: cn "rdx-dropdown-indicator"
  , group: cn "rdx-dropdown-group"
  , groupLabel: cn "rdx-dropdown-group-label"
  , checkIndicator: []
  , radioIndicator: []
  , subTrigger: cn "rdx-dropdown-subtrigger"
  , subContent: cn "rdx-dropdown-subcontent"
  , subIcon: []
  , subContentColor: ""
  }

type Input =
  { entries :: Array MenuEntry
  , open :: Maybe Boolean
  , defaultOpen :: Boolean
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , contentStyle :: String     -- the content's CONSTANT style (outline + menu vars + pointer-events)
  , subContentStyle :: String  -- the SubContent's CONSTANT style (Themes orders pointer-events BEFORE the vars)
  , triggerAttrs :: Array (Tuple String String)  -- data-* on the trigger (e.g. accent-color)
  , portalAttrs :: Array (Tuple String String)   -- data-* on the content (theme re-application)
  }

defaultInput :: Input
defaultInput =
  { entries: []
  , open: Nothing
  , defaultOpen: false
  , side: Bottom
  , align: Start
  , offset: 4.0
  , padding: 8.0
  , idPrefix: "rdx-dropdown"
  , style: defaultStyle
  , trigger: []
  , contentStyle: ""
  , subContentStyle: ""
  , triggerAttrs: []
  , portalAttrs: []
  }

data Output
  = OpenChanged Boolean
  | ItemSelected String

data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , presence :: Presence         -- Open / Closing (mounted, exiting) / Closed (display:none)
  , entries :: Array MenuEntry
  , focused :: Int               -- roving tab stop among focusable items
  , side :: Side
  , align :: Align
  , offset :: Number
  , padding :: Number
  , placedSide :: Side
  , placedAlign :: Align
  , idPrefix :: String
  , style :: Style
  , trigger :: Array HH.PlainHTML
  , contentStyle :: String
  , subContentStyle :: String
  , triggerAttrs :: Array (Tuple String String)
  , portalAttrs :: Array (Tuple String String)
  , restoreEl :: Maybe HTMLElement.HTMLElement  -- element to refocus on close (the trigger)
  , subs :: Array H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId  -- one-shot rAF subscription for AfterOpen / AfterClose
  , animSub :: Maybe H.SubscriptionId  -- content `animationend` subscription during exit
  , contentNode :: Maybe Node
  , triggerId :: String   -- generated on Initialize; the content's aria-labelledby source
  , contentId :: String   -- generated on Initialize; the trigger's aria-controls target + content id
  , openFocus :: Maybe Int  -- post-open focus target: Nothing = the content (click-open), Just i = item i (keyboard-open)
  -- ── typeahead (type-to-focus; radix useTypeahead) ──
  , search :: String   -- the accumulated search buffer (reset lazily after ~1s of no input)
  , lastKey :: Number  -- performance.now() of the last typeahead key; the idle-reset clock
  -- ── submenu (one open at a time) ──
  , subOpen :: Maybe String   -- the open sub's value (Nothing = none)
  , subFocused :: Int         -- roving tab stop within the open SubContent
  , subAnchorIdx :: Int       -- the open SubTrigger's parent roving index (the Popper anchor)
  , subPlacedSide :: Side
  , subPlacedAlign :: Align
  , subOpenFocus :: Maybe Int -- post-sub-open focus: Nothing = stay (hover), Just i = sub item i (keyboard)
  , subSubs :: Array H.SubscriptionId
  , subPostSub :: Maybe H.SubscriptionId
  , subGenTriggerId :: String  -- useId-generated (so the normalizer canonicalizes it); v1 single-sub
  , subGenContentId :: String
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked
  | TriggerKeyDown KE.KeyboardEvent
  | AfterOpen           -- after the open render flushed: position + portal + focus
  | AfterClose          -- after the closing render flushed: re-portal + arm exit animation
  | AnimDone            -- the content exit animation finished: finishExit + tear down envelope
  | EscapePressed
  | PointerDown Event
  | MenuKeyDown KE.KeyboardEvent
  | ItemClicked String
  | Reposition
  -- ── submenu ──
  | SubTriggerEnter String Int   -- hover the SubTrigger (value, parent roving idx) → open the sub
  | SubTriggerActivate String Int -- click / ArrowRight / Enter on the SubTrigger → open (+ focus first)
  | SubAfterOpen                 -- after the sub render flushed: position + portal (+ focus)
  | SubReposition
  | SubKeyDown KE.KeyboardEvent  -- key handling inside the open SubContent
  | SubItemClicked String
  | CloseSub                     -- ArrowLeft / Escape / leave → close the sub, refocus the trigger

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "rdx-dropdown-trigger"

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-dropdown-content"

wrapperRef :: H.RefLabel
wrapperRef = H.RefLabel "rdx-dropdown-wrapper"

itemRef :: String -> Int -> H.RefLabel
itemRef pfx i = H.RefLabel (pfx <> "-item-" <> show i)

subWrapperRef :: H.RefLabel
subWrapperRef = H.RefLabel "rdx-dropdown-subwrapper"

subContentRef :: H.RefLabel
subContentRef = H.RefLabel "rdx-dropdown-subcontent"

subItemRef :: String -> Int -> H.RefLabel
subItemRef pfx i = H.RefLabel (pfx <> "-subitem-" <> show i)

-- | Look up a SubData by value among the entries.
findSub :: String -> Array MenuEntry -> Maybe SubData
findSub value = Array.findMap case _ of
  MenuSubEntry sub | sub.value == value -> Just sub
  _ -> Nothing

portalData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
portalData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

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
  { ctrl: controllable input.open input.defaultOpen
  , presence: if startOpen then Open else Closed
  , entries: input.entries
  , focused: 0
  , side: input.side
  , align: input.align
  , offset: input.offset
  , padding: input.padding
  , placedSide: input.side
  , placedAlign: input.align
  , idPrefix: input.idPrefix
  , style: input.style
  , trigger: input.trigger
  , contentStyle: input.contentStyle
  , subContentStyle: input.subContentStyle
  , triggerAttrs: input.triggerAttrs
  , portalAttrs: input.portalAttrs
  , restoreEl: Nothing
  , subs: []
  , postSub: Nothing
  , animSub: Nothing
  , contentNode: Nothing
  , triggerId: ""
  , contentId: ""
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
  startOpen = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
    -- the wrapper + content LINGER while the exit animation plays (Presence): rendered for
    -- Open AND Closing, dropped to display:none only at Closed. data-state follows Presence
    -- (closed through the exit) so the CSS exit animation runs.
    rendered = isRendered st.presence
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      ( [ HH.button
          ( [ HP.type_ HP.ButtonButton
            , HP.ref triggerRef
            , HP.id st.triggerId
            , classes st.style.trigger
            , aria "expanded" (if open then "true" else "false")
            , aria "haspopup" "menu"
            , dataState (if open then "open" else "closed")
            , HE.onClick \_ -> TriggerClicked
            , HE.onKeyDown TriggerKeyDown
            ]
              <> (if open then [ aria "controls" st.contentId ] else [])
              -- popper-side/align stamped on the trigger only while the Popper subtree is mounted
              -- (rendered = Open OR Closing); absent at closed-rest, matching upstream.
              <> (if rendered then [ dataAttr "radix-popper-side" (sideName st.placedSide), dataAttr "radix-popper-align" (alignName st.placedAlign) ] else [])
              <> portalData st.triggerAttrs
          )
          (map HH.fromPlainHTML st.trigger)
      ]
      -- the popper WRAPPER (portal root) renders ONLY while mounted (Open OR exiting Closing);
      -- fully UNMOUNTED at Closed, matching upstream (no content node at closed-rest). finalize
      -- re-adopts the freshly-mounted wrapper into body on each open. position:fixed up front
      -- (shrink-to-fit measure); the rest of its style is FFI (positionWrapper).
      <> ( if rendered then
      [ HH.div
          [ HP.ref wrapperRef
          , dataAttr "radix-popper-content-wrapper" ""
          , dir "ltr"
          , HP.style "position: fixed;"
          ]
          [ HH.div
              ( [ HP.ref contentRef
                , HP.id st.contentId
                , role "menu"
                , classes st.style.content
                , aria "labelledby" st.triggerId
                , aria "orientation" "vertical"
                , dataState (dataStateOf st.presence)
                , dataAttr "side" (sideName st.placedSide)
                , dataAttr "align" (alignName st.placedAlign)
                , dataAttr "orientation" "vertical"
                , dataAttr "radix-menu-content" ""
                , dir "ltr"
                , HP.tabIndex (-1)
                , HP.style st.contentStyle
                , HE.onKeyDown MenuKeyDown
                ] <> portalData st.portalAttrs
              )
              -- the rt-ScrollArea nesting upstream wraps menu items in:
              -- scrollRoot > [ scrollViewport > table-div > menuViewport > items, focusRing ]
              [ HH.div
                  [ classes st.style.scrollRoot
                  , dir "ltr"
                  , HP.style "position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;"
                  ]
                  [ HH.div
                      [ classes st.style.scrollViewport
                      , dataAttr "radix-scroll-area-viewport" ""
                      , HP.style "overflow: scroll;"
                      ]
                      [ HH.div [ HP.style "min-width: 100%; display: table;" ]
                          [ HH.div [ classes st.style.menuViewport ] (renderEntries st) ]
                      ]
                  , HH.div [ classes st.style.focusRing ] []
                  ]
              ]
          ]
      ] else [] )
        -- the open SUBMENU layer: a separate popper-content-wrapper, portal-adopted into body
        -- (SubAfterOpen), anchored to the open SubTrigger. Rendered only while a sub is open.
        <> maybe [] (\sub -> [ renderSubContent st sub ]) (st.subOpen >>= \v -> findSub v st.entries)
      )

dir :: forall r i. String -> HP.IProp r i
dir = HP.attr (HH.AttrName "dir")

-- | Render the entries, threading a running focusable-item index so separators are
-- | skipped in the roving order (only MenuItemEntry consumes an index / gets a ref).
-- | The roving index advances ONLY past enabled items, so a disabled item is NOT in
-- | the roving order (it renders with `Nothing` → tabindex -1, never highlighted) and
-- | arrows skip OVER it — upstream's `getItems().filter(!disabled)` semantics.
renderEntries :: forall m. State -> Array (H.ComponentHTML Action () m)
renderEntries st = _.html (foldl step { idx: 0, html: [] } st.entries)
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
    -- A labelled group: a role=group wrapper containing a NON-interactive Label div
    -- (rendered FIRST) then the group's items. The inner items share the roving idx counter
    -- (like a radio group), so arrows traverse across group boundaries seamlessly. NOTE:
    -- Radix THEMES does NOT wire aria-labelledby/id between the group and its label (unlike
    -- the bare primitive) — the label is purely visual — so neither is emitted, matching the
    -- captured golden (rt-BaseMenuGroup wrapper, rt-BaseMenuLabel div, no id/aria-labelledby).
    MenuGroupEntry grp ->
      let
        inner = foldl groupItemStep { idx: acc.idx, html: [] } grp.items
        labelled = if Array.null grp.label then [] else [ HH.div [ classes st.style.groupLabel ] (map HH.fromPlainHTML grp.label) ]
      in
        acc
          { idx = inner.idx
          , html = acc.html <> [ HH.div [ classes st.style.group, role "group" ] (labelled <> inner.html) ]
          }
    MenuSubEntry sub
      | sub.disabled -> acc { html = acc.html <> [ renderSubTrigger st Nothing sub ] }
      | otherwise -> acc
          { idx = acc.idx + 1
          , html = acc.html <> [ renderSubTrigger st (Just acc.idx) sub ]
          }
  groupItemStep innerAcc item
    | item.disabled = innerAcc { html = innerAcc.html <> [ renderItem st Nothing item ] }
    | otherwise = innerAcc
        { idx = innerAcc.idx + 1
        , html = innerAcc.html <> [ renderItem st (Just innerAcc.idx) item ]
        }
  radioStep selected innerAcc opt
    | opt.disabled = innerAcc { html = innerAcc.html <> [ renderRadio st selected Nothing opt ] }
    | otherwise = innerAcc
        { idx = innerAcc.idx + 1
        , html = innerAcc.html <> [ renderRadio st selected (Just innerAcc.idx) opt ]
        }

-- | A menu item is a DIV (radix uses generic elements, not buttons) with role=menuitem,
-- | a roving tab stop, optional per-item accent, and an optional right-aligned shortcut.
-- | `mIdx = Nothing` ⇒ the item is DISABLED — out of the roving order: tabindex -1,
-- | never `data-highlighted`, click is a no-op (the handler guards on disabled).
renderItem :: forall m. State -> Maybe Int -> MenuItem -> H.ComponentHTML Action () m
renderItem st mIdx item =
  HH.div
    ( [ role "menuitem"
      , classes st.style.item
      , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
        <> (if item.accent == "" then [] else [ dataAttr "accent-color" item.accent ])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

-- | A SubTrigger row: a role=menuitem (like renderItem) that opens a nested SubContent.
-- | Carries aria-haspopup=menu + aria-expanded + (when open) aria-controls / data-state=open /
-- | data-radix-popper-side|align, and an auto-appended chevron icon (inside a shortcut div).
-- | Hover OR click/ArrowRight opens it; it shares the parent roving index space (one focusable).
renderSubTrigger :: forall m. State -> Maybe Int -> SubData -> H.ComponentHTML Action () m
renderSubTrigger st mIdx sub =
  let open = st.subOpen == Just sub.value
  in HH.div
    ( [ role "menuitem"
      , classes st.style.subTrigger
      , HP.id st.subGenTriggerId
      , aria "haspopup" "menu"
      , aria "expanded" (if open then "true" else "false")
      , dataState (if open then "open" else "closed")
      , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> SubTriggerActivate sub.value (fromMaybe (-1) mIdx)
      , HE.onMouseEnter \_ -> SubTriggerEnter sub.value (fromMaybe (-1) mIdx)
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
        <> (if open then
              [ aria "controls" st.subGenContentId
              , dataAttr "radix-popper-side" (sideName st.subPlacedSide)
              , dataAttr "radix-popper-align" (alignName st.subPlacedAlign)
              ] else [])
        <> (if sub.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML sub.label
        <> [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML sub.shortcut <> map HH.fromPlainHTML st.style.subIcon) ]
    )

-- | The nested SubContent: a SEPARATE popper-content-wrapper (portal-adopted into body),
-- | anchored to the open SubTrigger, data-side=right data-align=start. Mirrors the root
-- | content's wrapper → content → ScrollArea nesting; its items get their OWN roving order.
renderSubContent :: forall m. State -> SubData -> H.ComponentHTML Action () m
renderSubContent st sub =
  HH.div
    [ HP.ref subWrapperRef
    , dataAttr "radix-popper-content-wrapper" ""
    , dir "ltr"
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
          , dir "ltr"
          , HP.tabIndex (-1)
          , HP.style st.subContentStyle
          , HE.onKeyDown SubKeyDown
          ]
            <> (if st.style.subContentColor == "" then [] else [ HP.attr (HH.AttrName "color") st.style.subContentColor ])
            <> portalData st.portalAttrs
        )
        [ HH.div
            [ classes st.style.scrollRoot
            , dir "ltr"
            , HP.style "position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;"
            ]
            [ HH.div
                [ classes st.style.scrollViewport
                , dataAttr "radix-scroll-area-viewport" ""
                , HP.style "overflow: scroll;"
                ]
                [ HH.div [ HP.style "min-width: 100%; display: table;" ]
                    [ HH.div [ classes st.style.menuViewport ] (renderSubEntries st sub.entries) ]
                ]
            , HH.div [ classes st.style.focusRing ] []
            ]
        ]
    ]

-- | Render the SubContent entries with their OWN roving index space (subFocused / subItemRef /
-- | SubItemClicked). v1: plain items + separators (nested subs / checkboxes are not modeled).
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

-- | A SubContent item — like renderItem but keyed off `subFocused` / `subItemRef` and raising
-- | SubItemClicked.
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

-- | aria-checked / data-state for a tri-state checkbox.
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

-- | The Presence-gated ItemIndicator span: rendered ONLY when checked/indeterminate (radix
-- | wraps it in Presence(checked)), carrying the supplied icon svg. data-state mirrors the item.
renderIndicator :: forall m. State -> Array HH.PlainHTML -> CheckState -> Array (H.ComponentHTML Action () m)
renderIndicator st icon cs
  | cs == Unchecked = []
  | otherwise =
      [ HH.span
          [ classes st.style.indicator, dataState (checkData cs) ]
          (map HH.fromPlainHTML icon)
      ]

-- | A CheckboxItem (role=menuitemcheckbox). Same roving/disabled semantics as a plain item,
-- | plus aria-checked/data-state and a gated leading ItemIndicator. `mIdx = Nothing` ⇒ disabled.
renderCheckbox :: forall m. State -> Maybe Int -> CheckItem -> H.ComponentHTML Action () m
renderCheckbox st mIdx item =
  HH.div
    ( [ role "menuitemcheckbox"
      , classes st.style.checkboxItem
      , aria "checked" (checkAria item.check)
      , dataState (checkData item.check)
      , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
      , dataAttr "radix-collection-item" ""
      , dataAttr "orientation" "vertical"
      , HE.onClick \_ -> ItemClicked item.value
      ]
        <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
        <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
        <> (if item.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
    )
    ( map HH.fromPlainHTML item.label
        <> renderIndicator st st.style.checkIndicator item.check
        <> (if Array.null item.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML item.shortcut) ])
    )

-- | A RadioItem (role=menuitemradio): aria-checked gated on `selected == opt.value`; a gated
-- | indicator on the selected option. `mIdx = Nothing` ⇒ disabled (out of the roving order).
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
        , HP.tabIndex (maybe (-1) (tabIndexFor st.focused) mIdx)
        , dataAttr "radix-collection-item" ""
        , dataAttr "orientation" "vertical"
        , HE.onClick \_ -> ItemClicked opt.value
        ]
          <> maybe [] (\i -> [ HP.ref (itemRef st.idPrefix i) ]) mIdx
          <> (if mIdx == Just st.focused then [ dataAttr "highlighted" "" ] else [])
          <> (if opt.disabled then [ dataAttr "disabled" "", aria "disabled" "true" ] else [])
      )
      ( map HH.fromPlainHTML opt.label
          <> renderIndicator st st.style.radioIndicator cs
          <> (if Array.null opt.shortcut then [] else [ HH.div [ classes st.style.shortcut ] (map HH.fromPlainHTML opt.shortcut) ])
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    tid <- useId
    cid <- useId
    stid <- useId
    scid <- useId
    H.modify_ _ { triggerId = tid, contentId = cid, subGenTriggerId = stid, subGenContentId = scid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , entries = input.entries
      , side = input.side
      , align = input.align
      , offset = input.offset
      , padding = input.padding
      , idPrefix = input.idPrefix
      , style = input.style
      , trigger = input.trigger
      , contentStyle = input.contentStyle
      , subContentStyle = input.subContentStyle
      , triggerAttrs = input.triggerAttrs
      , portalAttrs = input.portalAttrs
      }
  TriggerClicked -> do
    st <- H.get
    if current st.ctrl then closeMenu else openMenu
  -- APG menu-button: on a CLOSED menu, ArrowDown opens + highlights the FIRST item,
  -- ArrowUp opens + highlights the LAST. (When open, the content owns key handling.)
  TriggerKeyDown ke -> do
    st <- H.get
    when (not (current st.ctrl)) case KE.key ke of
      "ArrowDown" -> liftEffect (preventDefault (KE.toEvent ke)) *> openMenuAt 0
      "ArrowUp" -> liftEffect (preventDefault (KE.toEvent ke)) *> openMenuAt (itemCount st.entries - 1)
      _ -> pure unit
  -- after the open render flushed (content ref live): measure+place, then on the NEXT
  -- frame (after the placement modify's re-render) portal the content into body + focus
  -- the first item.
  AfterOpen -> do
    reposition
    finalize true
  -- runs on the frame after the CLOSING render flushed. Halogen re-parented the wrapper back
  -- under the component root on the close re-render, so re-adopt it into body (it must linger
  -- there with data-state=closed through the exit animation). Then read the content ref and
  -- arm the exit: if it has a running CSS exit animation, finishClose when `animationend` fires;
  -- otherwise finishClose now (no animation ⇒ immediate teardown, like radix). The modal envelope
  -- (scroll-lock marker, guards, hideOthers) is intentionally NOT torn down here — it lingers
  -- until AnimDone.
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
      -- re-adopt the wrapper BEFORE the trailing focus guard (the guards already exist; a plain
      -- appendChild would land it after the trail guard and break body order).
      mwrap <- H.getHTMLElementRef wrapperRef
      for_ mwrap \wrap -> liftEffect (Envelope.reAdoptBeforeTrail wrap)
      -- release the pointer block the OPEN envelope set: radix's RemoveScroll disables the moment
      -- `open` flips false (the body `pointer-events:none` and the content's `pointer-events:auto`
      -- go away), while the closing node lingers for the exit animation. The `data-scroll-locked`
      -- marker + focus guards + hideOthers stay until unmount.
      liftEffect Envelope.releaseScrollPointer
      for_ mnode \node -> liftEffect (Envelope.clearPointerEvents (HTMLElement.toElement node))
    else finishClose
  AnimDone -> finishClose
  EscapePressed -> closeMenu
  PointerDown e -> do
    st <- H.get
    for_ st.contentNode \node -> do
      outside <- liftEffect (Dismiss.isOutside node e)
      when outside closeMenu
  MenuKeyDown ke -> do
    st <- H.get
    let
      key = KE.key ke
      cfg = { orientation: Vertical, dir: LTR, loop: false } -- menu.tsx:362 loop default false (no wrap)
      pos = { count: itemCount st.entries, current: st.focused }
      -- the focused entry's value IF it is a SubTrigger (else Nothing): ArrowRight / Enter / Space
      -- on it OPENS the sub (and focuses its first item) rather than selecting/navigating.
      mFocusedSub = do
        v <- enabledValueAt st.focused st.entries
        _ <- findSub v st.entries
        pure v
    case mFocusedSub of
      Just v | key == "ArrowRight" || key == "Enter" || key == " " -> do
        liftEffect (preventDefault (KE.toEvent ke))
        openSub v st.focused (Just 0)
      _ ->
        -- Typeahead (radix useTypeahead): a printable character (and Space WHILE a search is
        -- already running — the space-guard) feeds the search buffer and moves focus to the
        -- next matching item, BEFORE the Enter/Space activation path. preventDefault stops a
        -- buffered Space from also scrolling/selecting.
        if Typeahead.isTypeaheadChar key (st.search /= "") then do
          liftEffect (preventDefault (KE.toEvent ke))
          typeahead key
        -- Enter/Space SELECT the focused item (upstream menu.tsx:667-680 SELECTION_KEYS →
        -- currentTarget.click() + preventDefault). Keyboard activation of items, previously
        -- impossible (navigate returned Stay for these keys).
        else if (key == "Enter" || key == " ") && st.focused >= 0 then do
          liftEffect (preventDefault (KE.toEvent ke))
          for_ (enabledValueAt st.focused st.entries) \v -> do
            H.raise (ItemSelected v)
            closeMenu
        else case navigatePaged cfg pos key of
          Stay -> pure unit
          MoveTo idx -> focusItem idx
  ItemClicked value -> do
    st <- H.get
    -- a disabled item is non-interactive (upstream menu.tsx:639 handleSelect disabled
    -- guard) — clicking it neither selects nor closes the menu.
    let
      -- the disabled status of whatever focusable carries `value` (item / checkbox / radio
      -- option). A disabled focusable is non-interactive — clicking it neither selects nor closes.
      pick = case _ of
        MenuItemEntry it | it.value == value -> Just it.disabled
        MenuCheckboxEntry it | it.value == value -> Just it.disabled
        MenuRadioGroupEntry grp -> map _.disabled (Array.find (\o -> o.value == value) grp.options)
        MenuGroupEntry grp -> map _.disabled (Array.find (\o -> o.value == value) grp.items)
        _ -> Nothing
      mDisabled = Array.findMap pick st.entries
    when (maybe true not mDisabled) do
      H.raise (ItemSelected value)
      closeMenu
  -- scroll/resize: just re-place. NOT re-adopt — the wrapper stays in body across renders
  -- (Halogen patches it in place), and re-adopting would move it past the trailing focus
  -- guard AND blur the focused content. (This bit the menu because lockScroll fires resize.)
  Reposition -> reposition
  -- ── submenu ──
  -- hover-open: open the sub WITHOUT moving focus into it (the SubTrigger stays the roving
  -- tab stop — data-highlighted, tabindex=0). radix opens on pointer-enter (after a small
  -- intent delay we elide for v1).
  SubTriggerEnter value idx -> openSub value idx Nothing
  -- click / ArrowRight / Enter: open AND move focus to the first sub item (APG).
  SubTriggerActivate value idx -> openSub value idx (Just 0)
  -- the opening re-render (subOpen + focused changed) re-parented BOTH popper wrappers under
  -- the component root; position the sub, then re-adopt both into body before the trailing
  -- focus guard (so body order matches: main wrapper, sub wrapper, trail guard).
  SubAfterOpen -> do
    repositionSub
    st <- H.get
    mwrap <- H.getHTMLElementRef wrapperRef
    mswrap <- H.getHTMLElementRef subWrapperRef
    for_ mwrap (liftEffect <<< Envelope.reAdoptBeforeTrail)
    for_ mswrap (liftEffect <<< Envelope.reAdoptBeforeTrail)
    -- keyboard-open focuses the first sub item; hover-open leaves focus where it is.
    for_ st.subOpenFocus \i -> do
      mitem <- H.getHTMLElementRef (subItemRef st.idPrefix i)
      for_ mitem (liftEffect <<< HTMLElement.focus)
  SubReposition -> repositionSub
  SubKeyDown ke -> do
    st <- H.get
    let
      key = KE.key ke
      subEntries = fromMaybe [] (map _.entries (st.subOpen >>= \v -> findSub v st.entries))
      cfg = { orientation: Vertical, dir: LTR, loop: false } -- menu.tsx:362 loop default false (no wrap)
      pos = { count: itemCount subEntries, current: st.subFocused }
    case key of
      -- ArrowLeft / Escape close the sub and return focus to the SubTrigger.
      "ArrowLeft" -> liftEffect (preventDefault (KE.toEvent ke)) *> closeSub
      "Escape" -> liftEffect (preventDefault (KE.toEvent ke)) *> closeSub
      _
        | (key == "Enter" || key == " ") && st.subFocused >= 0 -> do
            liftEffect (preventDefault (KE.toEvent ke))
            for_ (enabledValueAt st.subFocused subEntries) \v -> do
              H.raise (ItemSelected v)
              closeMenuAndSub
        | otherwise -> case navigatePaged cfg pos key of
            Stay -> pure unit
            MoveTo idx -> do
              H.modify_ _ { subFocused = idx }
              mwrap <- H.getHTMLElementRef wrapperRef
              mswrap <- H.getHTMLElementRef subWrapperRef
              mitem <- H.getHTMLElementRef (subItemRef st.idPrefix idx)
              liftEffect $ Dom.queueMicrotask do
                -- both wrappers were re-parented out of body by the focused-state re-render
                for_ mwrap Envelope.reAdoptBeforeTrail
                for_ mswrap Envelope.reAdoptBeforeTrail
                for_ mitem HTMLElement.focus
  SubItemClicked value -> do
    st <- H.get
    let subEntries = fromMaybe [] (map _.entries (st.subOpen >>= \v -> findSub v st.entries))
        pick = case _ of
          MenuItemEntry it | it.value == value -> Just it.disabled
          _ -> Nothing
        mDisabled = Array.findMap pick subEntries
    when (maybe true not mDisabled) do
      H.raise (ItemSelected value)
      closeMenuAndSub
  CloseSub -> closeSub

-- | Click-open: focus the menu CONTENT with NO item highlighted (the first ArrowDown
-- | highlights an item) — matches radix.
openMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
openMenu = openMenuWith (-1) Nothing

-- | Keyboard-open (APG menu-button): open with item `idx` highlighted and focused.
openMenuAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
openMenuAt idx = openMenuWith idx (Just idx)

openMenuWith :: forall m. MonadEffect m => Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
openMenuWith focusedIdx openFocus = do
  st <- H.get
  when (not (current st.ctrl)) do
    -- capture the restore target (trigger) BEFORE opening, so no post-open `modify` is
    -- needed for it (which would un-portal the content).
    doc <- liftEffect (HTML.window >>= Window.document)
    mprev <- liftEffect (HTMLDocument.activeElement doc)
    -- re-opening cancels any in-flight exit (the content is still mounted/Closing).
    for_ st.animSub H.unsubscribe
    H.modify_ _ { ctrl = (change true st.ctrl).next, presence = Open, focused = focusedIdx, restoreEl = mprev, openFocus = openFocus, animSub = Nothing }
    H.raise (OpenChanged true)
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

-- | Dispatch `AfterOpen` on the next animation frame (after the open render flushes).
scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterOpen <$ emitter)
  -- a MICROTASK, not a frame: AfterOpen must focus the content before the open-state driver's
  -- first arrow key (which fires on the next macrotask). A rAF would be a frame too late.
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | On the next frame (after the placement modify's render re-parents the content),
-- | adopt the content into body — and, on open, focus the first item AFTER the move so
-- | the appendChild doesn't blur it.
-- | Adopt the WRAPPER into body; on open layer the MODAL menu envelope (radix DropdownMenu
-- | is modal: scroll-lock + focus guards + aria-hide siblings) and focus the menu content.
-- | SYNCHRONOUS (not an afterFrame): with the guarded reposition there's no pending re-render
-- | to re-parent the wrapper, so the content can be focused in this same frame — the
-- | open-state driver fires its arrow keys immediately, before a deferred focus would land.
finalize :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
finalize focusToo = do
  st <- H.get
  mbody <- liftEffect Portal.documentBody
  mwrap <- H.getHTMLElementRef wrapperRef
  -- click-open focuses the menu CONTENT (role=menu, tabindex=-1); keyboard-open (APG
  -- menu-button) focuses the highlighted ITEM instead (openFocus = Just idx).
  mfocus <- if focusToo
    then case st.openFocus of
      Just idx -> H.getHTMLElementRef (itemRef st.idPrefix idx)
      Nothing -> H.getHTMLElementRef contentRef
    else pure Nothing
  case mbody, mwrap of
    Just body, Just wrap -> liftEffect do
      Portal.adopt body (HTMLElement.toElement wrap)
      when focusToo do
        Envelope.lockScroll
        Envelope.addFocusGuards
        Envelope.hideOthers wrap
        for_ mfocus HTMLElement.focus
    _, _ -> pure unit

-- | Begin the close: flip controllable + Presence to Closing (the wrapper + content stay
-- | MOUNTED — wrapper keeps its popper position style, content flips data-state="closed" —
-- | still portaled in body, the modal envelope still up), tear down the open-time document
-- | subscriptions, restore focus to the trigger, and schedule AfterClose to arm the exit
-- | animation on the next frame. The envelope teardown + drop-to-display:none happen at AnimDone.
closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  st <- H.get
  when (current st.ctrl) do
    traverse_ H.unsubscribe st.subs
    for_ st.postSub H.unsubscribe
    for_ st.restoreEl (liftEffect <<< HTMLElement.focus)
    H.modify_ _ { ctrl = (change false st.ctrl).next, presence = present false st.presence, restoreEl = Nothing, subs = [], postSub = Nothing, contentNode = Nothing, openFocus = Nothing, search = "", subOpen = Nothing, subFocused = -1 }
    H.raise (OpenChanged false)
    psid <- scheduleAfterClose
    H.modify_ _ { postSub = Just psid }

-- | Move the roving tab stop to item `idx` and focus it. The focused-state re-render
-- | re-parents the wrapper out of body; on the next microtask re-adopt it (before the
-- | trailing guard, preserving order) then focus the item. Shared by arrow navigation
-- | (RovingFocus) and typeahead.
focusItem :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusItem idx = do
  st <- H.get
  H.modify_ _ { focused = idx }
  mwrap <- H.getHTMLElementRef wrapperRef
  mitem <- H.getHTMLElementRef (itemRef st.idPrefix idx)
  liftEffect $ Dom.queueMicrotask do
    for_ mwrap Envelope.reAdoptBeforeTrail
    for_ mitem HTMLElement.focus

-- | Read the rendered item labels (textContent, incl. the shortcut suffix — exactly as radix's
-- | collection captures `textValue`) over the navigable index space, so the pure matcher works
-- | on the same indices `focused` uses.
readItemTexts :: forall m. MonadEffect m => String -> Int -> H.HalogenM State Action () Output m (Array String)
readItemTexts pfx count =
  for (Array.range 0 (count - 1)) \i -> do
    mel <- H.getHTMLElementRef (itemRef pfx i)
    case mel of
      Just el -> liftEffect (textContent (HTMLElement.toNode el))
      Nothing -> pure ""

-- | One typeahead keystroke (radix useTypeahead). The buffer resets lazily: if more than 1s
-- | has elapsed since the last key, the new character starts a fresh search; otherwise it
-- | extends the buffer (so "dd" cycles, "ad" refines). Using a `performance.now()` clock
-- | instead of a wall-clock timer avoids an idle re-render — the only re-render is on the key
-- | itself, which already moves focus via `focusItem`.
typeahead :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
typeahead key = do
  st <- H.get
  now <- liftEffect Dom.now
  let
    expired = now - st.lastKey > 1000.0
    search' = (if expired then "" else st.search) <> key
  texts <- readItemTexts st.idPrefix (itemCount st.entries)
  for_ (Typeahead.nextMatch search' texts st.focused) focusItem
  H.modify_ _ { search = search', lastKey = now }

-- | Dispatch `AfterClose` on the next microtask (after the closing render flushes).
scheduleAfterClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfterClose = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (AfterClose <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | The exit animation finished (or there was none): tear down the modal envelope, drop the
-- | wrapper to display:none (Presence Closing → Closed), and clear the exit subscriptions.
finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  liftEffect (Envelope.showOthers *> Envelope.removeFocusGuards *> Envelope.unlockScroll)
  H.modify_ _ { presence = finishExit st.presence, animSub = Nothing, postSub = Nothing }

reposition :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
reposition = do
  st <- H.get
  manchor <- H.getHTMLElementRef triggerRef
  mwrap <- H.getHTMLElementRef wrapperRef
  mfloat <- H.getHTMLElementRef contentRef
  case manchor, mwrap, mfloat of
    Just anchor, Just wrapper, Just floating -> do
      placed <- liftEffect (Popper.positionWrapper
        { anchor, wrapper, floating, side: st.side, align: st.align, offset: st.offset, padding: st.padding })
      -- only modify (→ re-render, which re-parents the portaled wrapper) when the placement
      -- actually changed; a no-op reposition (e.g. the resize lockScroll fires) must not
      -- re-render, or the wrapper leaves body and we'd need to re-adopt.
      when (placed.placement.side /= st.placedSide || placed.placement.align /= st.placedAlign) $
        H.modify_ _ { placedSide = placed.placement.side, placedAlign = placed.placement.align }
    _, _, _ -> pure unit

-- | Open the submenu `value` (whose SubTrigger is at parent roving index `idx`): mark it open,
-- | move the parent roving tab stop ONTO the SubTrigger (so it is data-highlighted / tabindex=0),
-- | and schedule the position+portal pass. `focus = Just i` (keyboard) focuses sub item i after;
-- | `Nothing` (hover) leaves focus on the SubTrigger. No-op if it is already the open sub.
openSub :: forall m. MonadEffect m => String -> Int -> Maybe Int -> H.HalogenM State Action () Output m Unit
openSub value idx focus = do
  st <- H.get
  when (current st.ctrl && st.subOpen /= Just value) do
    H.modify_ _
      { subOpen = Just value, focused = idx, subAnchorIdx = idx, subFocused = -1
      , subOpenFocus = focus, subPlacedSide = Right, subPlacedAlign = Start
      }
    psid <- scheduleSubAfterOpen
    H.modify_ _ { subPostSub = Just psid }

-- | Dispatch `SubAfterOpen` on the next microtask (after the sub render flushes) — same timing
-- | discipline as the root menu's open (focus before the next macrotask keypress).
scheduleSubAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m H.SubscriptionId
scheduleSubAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (SubAfterOpen <$ emitter)
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))
  pure sid

-- | Position the SubContent wrapper anchored to its SubTrigger (the parent item at
-- | `subAnchorIdx`), preferring side=right align=start. Only modifies on a real placement change
-- | (so the stable case doesn't trigger a re-render that would un-portal the wrappers).
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

-- | Close the submenu and return focus to its SubTrigger (the close re-render re-parents the
-- | main wrapper out of body, so re-adopt it on the next microtask before refocusing).
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

-- | Selecting a sub item closes the sub AND the whole menu.
closeMenuAndSub :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenuAndSub = do
  H.modify_ _ { subOpen = Nothing, subFocused = -1 }
  closeMenu

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    if v then openMenu else closeMenu
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))