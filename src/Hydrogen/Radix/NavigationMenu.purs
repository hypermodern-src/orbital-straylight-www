-- | Hydrogen.Radix.NavigationMenu — a navigation bar of disclosure menus (radix
-- | `NavigationMenu`), viewport mode.
-- |
-- | UNLIKE DropdownMenu/Menubar this is NOT a portal overlay: there is no Popper, no
-- | Portal-to-body, no Envelope (it is non-modal — no scroll-lock, no focus-trap, no
-- | hideOthers). The open content lives IN-FLOW, proxied into the `Viewport` — a sibling
-- | of the trigger `List` under the root `nav`. The module composes:
-- |
-- |   * `ControllableState String` — the open value ("" = none); exactly one item open.
-- |   * `Behavior.Presence` — the shared viewport/content exit lifecycle. The bare primitive
-- |     ships NO exit animation, so on value-clear the content unmounts synchronously (the
-- |     closing oracle is deliberately omitted, like select/tooltip/menubar).
-- |   * `Behavior.RovingFocus.focusIntent` — key→intent mapping for the horizontal FocusGroup
-- |     (triggers + open-content links). NOTE: NavigationMenu's FocusGroup does NOT loop and
-- |     the entry key (ArrowDown horizontal) crosses INTO the content rather than roving — so
-- |     `RovingFocus.navigate` isn't used directly; the move is a NON-looping clamp over a flat
-- |     focus-item list, and the entry key is a separate branch.
-- |   * `Behavior.DismissableLayer.escape` — Escape closes + restores focus to the trigger.
-- |   * `Behavior.Id` — the per-mount id base; trigger/content ids are `${base}-trigger-${value}`
-- |     / `${base}-content-${value}` (radix makeTriggerId/makeContentId verbatim).
-- |   * `Foundation.Dom.offsetMetrics` — the Indicator measures the active trigger's
-- |     offsetWidth/offsetLeft (→ width + translateX), the Viewport measures the active
-- |     content's offsetWidth/offsetHeight (→ the --radix-navigation-menu-viewport-* vars).
-- |     Upstream reads `offset*` (NOT getBoundingClientRect), so the port does too.
-- |
-- | v1 scope: viewport mode only (Content proxied into the Viewport), root menu only (no Sub),
-- | links + triggers, the open-delay/close timers are NOT modeled (the golden + port `open`
-- | story renders OPEN at first paint via `defaultValue`, off the timer path; the keyboard
-- | close path is the APG gate). No typeahead.
module Hydrogen.Radix.NavigationMenu
  ( component
  , MenuEntry
  , NavLink
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
import Data.Foldable (for_)
import Data.Int (round) as Int
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Tuple (Tuple(..))
import Unsafe.Reference (unsafeRefEq)
import Web.Event.EventTarget (EventTarget)
import Web.UIEvent.FocusEvent (FocusEvent, relatedTarget)
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.Subscription as HS
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered)
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataState, dataAttr, dataOrientation, aria)
import Web.DOM.Node as Node
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.Event.Event (Event, preventDefault)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | One menu item: a trigger label + its disclosure content (a list of links).
type MenuEntry =
  { value :: String
  , trigger :: Array HH.PlainHTML
  , links :: Array NavLink
  }

-- | A link inside a menu's content (carries data-radix-collection-item, the FocusGroup hook).
type NavLink =
  { href :: String
  , label :: Array HH.PlainHTML
  , active :: Boolean
  }

-- | (A bare top-level Link variant — a FocusGroup item with no disclosure content — is deferred;
-- | the golden story is all menu items, the DOM contract this v1 reproduces.)

type Style =
  { root :: ClassNames
  , list :: ClassNames
  , item :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  , link :: ClassNames
  , indicator :: ClassNames
  , viewport :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn ""
  , list: cn ""
  , item: cn ""
  , trigger: cn ""
  , content: cn ""
  , link: cn ""
  , indicator: cn ""
  , viewport: cn ""
  }

type Input =
  { items :: Array MenuEntry
  , value :: Maybe String          -- controlled open value ("" = none); Nothing = uncontrolled
  , defaultValue :: String         -- uncontrolled initial open value ("" = none)
  , orientation :: Orientation
  , dir :: Dir
  , idPrefix :: String
  , withViewport :: Boolean        -- v1 supports viewport mode (true); inline mode deferred
  , withIndicator :: Boolean
  , delayDuration :: Int           -- ms a pointer must dwell on a trigger before it opens (radix 200)
  , skipDelayDuration :: Int       -- ms after closing during which the next open is INSTANT (radix 300)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { items: []
  , value: Nothing
  , defaultValue: ""
  , orientation: Horizontal
  , dir: LTR
  , idPrefix: ""
  , withViewport: true
  , withIndicator: true
  , delayDuration: 200
  , skipDelayDuration: 300
  , style: defaultStyle
  }

data Output = ValueChanged String

data Query a
  = SetValue String a
  | GetValue (String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type Measure = { width :: Number, height :: Number, left :: Number, top :: Number }

type State =
  { items :: Array MenuEntry
  , ctrl :: Controllable String     -- the open menu value ("" = none)
  , previousValue :: String         -- the value before the latest change (radix usePrevious) → data-motion
  , presence :: Presence            -- viewport/content exit lifecycle
  , orientation :: Orientation
  , dir :: Dir
  , idPrefix :: String
  , withViewport :: Boolean
  , withIndicator :: Boolean
  , style :: Style
  , uid :: String                   -- per-mount id base (minted on Initialize)
  , indicator :: Maybe Measure      -- active-trigger offset (Nothing until measured)
  , viewport :: Maybe Measure       -- active-content offset (Nothing until measured)
  , subs :: Array H.SubscriptionId
  -- ── pointer open/close TIMER state machine (radix delayDuration/skipDelayDuration) ──
  , delayDuration :: Int
  , skipDelayDuration :: Int
  , isOpenDelayed :: Boolean        -- true ⇒ a hover-open waits delayDuration; false ⇒ instant
  , openTimer :: Maybe (Tuple Dom.TimeoutId H.SubscriptionId)   -- pending hover→open
  , closeTimer :: Maybe (Tuple Dom.TimeoutId H.SubscriptionId)  -- pending leave→close (150ms)
  , skipTimer :: Maybe (Tuple Dom.TimeoutId H.SubscriptionId)   -- post-close instant-open window
  , hasPMOpen :: Boolean            -- guards onPointerMove from re-firing the open per trigger
  }

data Action
  = Initialize
  | Receive Input
  | TriggerClicked Int
  | TriggerKeyDown Int KE.KeyboardEvent
  | LinkKeyDown Int KE.KeyboardEvent
  | EscapePressed
  | AfterOpen   -- measure indicator/viewport after the open render flushes
  -- pointer machine: a mouse over trigger i (onPointerMove), leaving a trigger, entering/leaving
  -- the open content, and the three timers firing.
  | TriggerEnter Int
  | TriggerLeave
  | ContentEnter
  | ContentLeave
  | OpenTimerFired String
  | CloseTimerFired
  | SkipTimerFired
  | ProxyFocus Int FocusEvent   -- the FocusProxy span (after trigger i) received focus

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
  { items: input.items
  , ctrl: controllable input.value startVal
  , previousValue: ""
  , presence: if startVal /= "" then Open else Closed
  , orientation: input.orientation
  , dir: input.dir
  , idPrefix: input.idPrefix
  , withViewport: input.withViewport
  , withIndicator: input.withIndicator
  , style: input.style
  , uid: ""
  , indicator: Nothing
  , viewport: Nothing
  , subs: []
  , delayDuration: input.delayDuration
  , skipDelayDuration: input.skipDelayDuration
  , isOpenDelayed: true
  , openTimer: Nothing
  , closeTimer: Nothing
  , skipTimer: Nothing
  , hasPMOpen: false
  }
  where
  startVal = case input.value of
    Just v -> v
    Nothing -> input.defaultValue

base :: State -> String
base st
  | st.uid == "" = st.idPrefix
  | st.idPrefix == "" = st.uid
  | otherwise = st.idPrefix <> "-" <> st.uid

triggerId :: State -> String -> String
triggerId st value = base st <> "-trigger-" <> value

contentId :: State -> String -> String
contentId st value = base st <> "-content-" <> value

triggerRef :: Int -> H.RefLabel
triggerRef i = H.RefLabel ("nav-trigger-" <> show i)

linkRef :: Int -> H.RefLabel
linkRef i = H.RefLabel ("nav-link-" <> show i)

contentRef :: H.RefLabel
contentRef = H.RefLabel "nav-content"

openValue :: State -> String
openValue st = current st.ctrl

openIndex :: State -> Maybe Int
openIndex st =
  let v = openValue st
  in if v == "" then Nothing else Array.findIndex (\m -> m.value == v) st.items

-- | The `data-motion` direction for the ACTIVE content (radix motionAttribute, navigation-menu
-- | .tsx:890-916). The item-value order is reversed under RTL. For the open content (its value ==
-- | current), the transition from `previousValue` yields from-end (moved here from an earlier
-- | item) / from-start (from a later item); the initial open (no previous) yields Nothing — no
-- | attribute. (to-start/to-end live on the LEAVING content, which needs the multi-mount/exit
-- | model; the bare port unmounts it synchronously.)
motionAttr :: State -> String -> Maybe String
motionAttr st value =
  let
    order = (if st.dir == RTL then Array.reverse else identity) (map _.value st.items)
    index = Array.elemIndex value order
    prevIndex = Array.elemIndex st.previousValue order
  in case index, prevIndex of
    Just i, Just p | i /= p && p >= 0 -> Just (if i > p then "from-end" else "from-start")
    _, _ -> Nothing

isHorizontal :: State -> Boolean
isHorizontal st = st.orientation == Horizontal

dirName :: Dir -> String
dirName = case _ of
  LTR -> "ltr"
  RTL -> "rtl"

dirAttr :: forall r i. String -> HP.IProp r i
dirAttr = HP.attr (HH.AttrName "dir")

-- | The visually-hidden inline style upstream's VisuallyHidden stamps on the FocusProxy span.
visuallyHiddenStyle :: String
visuallyHiddenStyle =
  "position: absolute; border: 0px; width: 1px; height: 1px; padding: 0px; margin: -1px; "
    <> "overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; overflow-wrap: normal;"

-- ─────────────────────────────────────────────────────────────────────────────
-- Render
-- ─────────────────────────────────────────────────────────────────────────────

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    mOpenI = openIndex st
    rendered = isRendered st.presence
  in
    -- transparent component root (display:contents) — the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      [ HH.nav
          [ aria "label" "Main"
          , dataOrientation st.orientation
          , dirAttr (dirName st.dir)
          , classes st.style.root
          ]
          ( [ -- the indicator-track: a relative div wrapping the List (the indicator's slot).
              HH.div [ HP.style "position: relative;" ]
                ( [ HH.ul
                      [ dataOrientation st.orientation
                      , dirAttr (dirName st.dir)
                      , classes st.style.list
                      ]
                      (Array.mapWithIndex (renderItem st mOpenI) st.items)
                  ]
                    -- the Indicator: portaled into the track (after the List). Renders only once
                    -- its position is measured (upstream returns null until then).
                    <> (if st.withIndicator then indicatorNode st else [])
                )
            ]
              -- the Viewport: an in-flow sibling of the track, hosting the active content.
              <> (if st.withViewport && rendered then [ renderViewport st mOpenI ] else [])
          )
      ]

renderItem :: forall m. State -> Maybe Int -> Int -> MenuEntry -> H.ComponentHTML Action () m
renderItem st mOpenI i menu =
  let
    open = mOpenI == Just i
  in
    HH.li [ classes st.style.item ]
      ( [ HH.button
            ( [ HP.ref (triggerRef i)
              , HP.id (triggerId st menu.value)
              , dataAttr "radix-collection-item" ""
              , dataState (if open then "open" else "closed")
              , aria "expanded" (if open then "true" else "false")
              , classes st.style.trigger
              , HE.onClick \_ -> TriggerClicked i
              , HE.onKeyDown (TriggerKeyDown i)
              -- pointer (mouse) open/close: onMouseMove arms the (delayed) open, onMouseLeave the
              -- close — radix's onPointerMove/onPointerLeave gated to mouse (whenMouse). Mouse
              -- events fire only for mouse input, so this matches whenMouse exactly. Handlers are
              -- not serialized, so the at-rest DOM oracle is unchanged.
              , HE.onMouseMove \_ -> TriggerEnter i
              , HE.onMouseLeave \_ -> TriggerLeave
              ]
                <> (if open then [ aria "controls" (contentId st menu.value) ] else [])
            )
            (map HH.fromPlainHTML menu.trigger)
        ]
          -- open only: the FocusProxy span (tab-order bridge), then EITHER the aria-owns span
          -- (viewport mode — the content lives in the Viewport) OR the content rendered IN-PLACE
          -- (inline mode, withViewport=false; navigation-menu.tsx:771-787 carries data-state).
          <> (if open then
                [ HH.span
                    [ aria "hidden" "true"
                    , HP.tabIndex 0
                    , HP.style visuallyHiddenStyle
                    -- Tab from the trigger lands here (next in DOM); onFocus bridges into the
                    -- content (radix FocusProxy.onFocus → onFocusProxyEnter → focus first/last link).
                    , HE.onFocus (ProxyFocus i)
                    ]
                    []
                ]
                  <> (if st.withViewport
                        then [ HH.span [ aria "owns" (contentId st menu.value) ] [] ]
                        else [ renderContent st true menu ])
              else [])
      )

-- | The Indicator node (portaled into the track). Empty until measured — exactly upstream's
-- | "return null until position is set". Visible iff a menu is open (data-state visible/hidden).
indicatorNode :: forall m. State -> Array (H.ComponentHTML Action () m)
indicatorNode st = case st.indicator of
  Nothing -> []
  Just m ->
    let
      visible = openValue st /= ""
      pos =
        if isHorizontal st
        then "position: absolute; left: 0px; width: " <> px m.width <> "; transform: translateX(" <> px m.left <> ");"
        else "position: absolute; top: 0px; height: " <> px m.height <> "; transform: translateY(" <> px m.top <> ");"
    in
      [ HH.div
          [ aria "hidden" "true"
          , dataState (if visible then "visible" else "hidden")
          , dataOrientation st.orientation
          , classes st.style.indicator
          , HP.style pos
          ]
          []
      ]

-- | The Viewport (in-flow sibling of the track). Carries data-state + the size vars (measured
-- | from the active content's offset dims) and hosts the active content.
renderViewport :: forall m. State -> Maybe Int -> H.ComponentHTML Action () m
renderViewport st mOpenI =
  let
    open = openValue st /= ""
    sizeVars = case st.viewport of
      Nothing -> ""
      Just m -> "--radix-navigation-menu-viewport-width: " <> px m.width <> "; --radix-navigation-menu-viewport-height: " <> px m.height <> ";"
  in
    HH.div
      [ dataState (if open then "open" else "closed")
      , dataOrientation st.orientation
      , classes st.style.viewport
      , HP.style sizeVars
      ]
      ( case mOpenI >>= Array.index st.items of
          Nothing -> []
          Just menu -> [ renderContent st false menu ]
      )

-- | The content panel. In VIEWPORT mode (`withState=false`) it is proxied into the Viewport and
-- | carries NO data-state (the Viewport wrapper does). In INLINE mode (`withState=true`) it
-- | renders in-place inside its Item and carries data-state=open (navigation-menu.tsx:771-787).
renderContent :: forall m. State -> Boolean -> MenuEntry -> H.ComponentHTML Action () m
renderContent st withState menu =
  HH.div
    ( [ HP.ref contentRef
    , HP.id (contentId st menu.value)
    , aria "labelledby" (triggerId st menu.value)
    , dataOrientation st.orientation
    , dirAttr (dirName st.dir)
    , classes st.style.content
    -- pointer over the open content cancels the pending close; leaving (re)starts it.
    , HE.onMouseEnter \_ -> ContentEnter
    , HE.onMouseLeave \_ -> ContentLeave
    ]
      <> (if withState then [ dataState "open" ] else [])
      <> (case motionAttr st menu.value of
            Just m -> [ dataAttr "motion" m ]
            Nothing -> [])
    )
    (Array.mapWithIndex (renderLink st) menu.links)

renderLink :: forall m. State -> Int -> NavLink -> H.ComponentHTML Action () m
renderLink st i link =
  HH.a
    ( [ HP.ref (linkRef i)
      , HP.href link.href
      , dataAttr "radix-collection-item" ""
      , classes st.style.link
      , HE.onKeyDown (LinkKeyDown i)
      ]
        <> (if link.active then [ dataAttr "active" "", aria "current" "page" ] else [])
    )
    (map HH.fromPlainHTML link.label)

-- | An offset metric as the integral px string upstream emits (offset* are integers; the DOM
-- | oracle normalizes any px to <px> regardless, so this is for shape, not exactness).
px :: Number -> String
px n = show (Int.round n) <> "px"

-- ─────────────────────────────────────────────────────────────────────────────
-- Behaviour
-- ─────────────────────────────────────────────────────────────────────────────

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    uid <- useId
    H.modify_ _ { uid = uid }
    -- if mounted OPEN (defaultValue), arm the dismiss subscriptions + measure. Initialize runs
    -- after the first render, so the trigger/content refs already resolve — measure inline.
    st <- H.get
    when (openValue st /= "") do
      armOpen
      measure
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , ctrl = sync input.value st.ctrl
      , orientation = input.orientation
      , dir = input.dir
      , idPrefix = input.idPrefix
      , withViewport = input.withViewport
      , withIndicator = input.withIndicator
      , delayDuration = input.delayDuration
      , skipDelayDuration = input.skipDelayDuration
      , style = input.style
      }
  TriggerClicked i -> do
    st <- H.get
    for_ (Array.index st.items i) \menu ->
      if openValue st == menu.value then closeMenu
      else openMenu menu.value
  -- On an OPEN trigger the entry key (ArrowDown horizontal / ArrowRight vertical) moves focus
  -- INTO the content. Otherwise the horizontal arrows / Home / End rove the FocusGroup
  -- (triggers + open links), NON-LOOPING.
  TriggerKeyDown i ke -> do
    st <- H.get
    let
      key = KE.key ke
      open = openIndex st == Just i
      entryKey = if isHorizontal st then "ArrowDown" else (if st.dir == RTL then "ArrowLeft" else "ArrowRight")
    if open && key == entryKey then do
      liftEffect (preventDefault (KE.toEvent ke))
      focusFirstLink
    else focusNav key (KE.toEvent ke) i Trigger
  LinkKeyDown i ke ->
    focusNav (KE.key ke) (KE.toEvent ke) i Link
  EscapePressed -> closeMenu
  AfterOpen -> measure
  -- onPointerMove (mouse) over trigger i: open it (delayed or instant per isOpenDelayed). The
  -- hasPMOpen latch makes the repeated mousemove fire the open exactly once (radix
  -- hasPointerMoveOpenedRef); it resets on leave.
  TriggerEnter i -> do
    st <- H.get
    when (not st.hasPMOpen) do
      H.modify_ _ { hasPMOpen = true }
      for_ (Array.index st.items i) \menu -> onTriggerEnter menu.value
  -- onPointerLeave (mouse) off a trigger: cancel any pending open, start the close timer.
  TriggerLeave -> do
    clearOpenTimer
    H.modify_ _ { hasPMOpen = false }
    startCloseTimer
  -- pointer over the open content cancels the close; leaving it (re)starts it.
  ContentEnter -> clearCloseTimer
  ContentLeave -> startCloseTimer
  -- the delayed-open timer elapsed: cancel any close and open for real.
  OpenTimerFired value -> do
    clearOpenTimer
    clearCloseTimer
    openMenu value
  CloseTimerFired -> do
    clearCloseTimer
    closeMenu
  -- the skip-delay window elapsed: subsequent hover-opens are delayed again.
  SkipTimerFired -> H.modify_ _ { isOpenDelayed = true, skipTimer = Nothing }
  -- the FocusProxy span (after the open trigger) received focus: bridge into the content.
  -- radix: if focus came from the trigger → enter the content from the START (first link); if it
  -- came from anywhere that ISN'T the content (e.g. shift+tabbing back from after the menu) →
  -- enter from the END (last link). Focus arriving FROM the content is the natural tab-out → leave it.
  ProxyFocus i fe -> do
    mtrig <- H.getHTMLElementRef (triggerRef i)
    mcont <- H.getHTMLElementRef contentRef
    let mrel = relatedTarget fe
        wasTrigger = case mrel, mtrig of
          Just rt, Just tr -> unsafeRefEq rt (HTMLElement.toEventTarget tr)
          _, _ -> false
    fromContent <- containsTarget mcont mrel
    when (wasTrigger || not fromContent) $
      if wasTrigger then focusFirstLink else focusLastLink

-- | A FocusGroup scope: the trigger bar, or the open menu's content links. Upstream wraps the
-- | List and each Content in SEPARATE FocusGroups, so a horizontal arrow rove stays WITHIN its
-- | group (it does not cross from the last trigger into the content links) and does NOT loop.
data FocusKind = Trigger | Link

-- | Rove WITHIN the keydown item's FocusGroup (triggers OR the open content's links),
-- | NON-LOOPING — clamped at the ends (radix slices from current, never wraps). The entry key
-- | (ArrowDown horizontal, into the content) is handled separately by the caller.
focusNav :: forall m. MonadEffect m => String -> Event -> Int -> FocusKind -> H.HalogenM State Action () Output m Unit
focusNav key ev which kind = do
  st <- H.get
  let
    count = case kind of
      Trigger -> Array.length st.items
      Link -> Array.length (fromMaybe [] (openIndex st >>= Array.index st.items <#> _.links))
    horiz = isHorizontal st
    -- the live in-axis keys, dir-adjusted (RTL swaps the horizontal arrows).
    k = case st.dir, key of
      RTL, "ArrowLeft" -> "ArrowRight"
      RTL, "ArrowRight" -> "ArrowLeft"
      _, _ -> key
    target = case k of
      "Home" -> Just 0
      "End" -> Just (count - 1)
      "ArrowLeft" -> if horiz then Just (clampLow (which - 1)) else Nothing
      "ArrowRight" -> if horiz then Just (clampHigh count (which + 1)) else Nothing
      "ArrowUp" -> if horiz then Nothing else Just (clampLow (which - 1))
      "ArrowDown" -> if horiz then Nothing else Just (clampHigh count (which + 1))
      _ -> Nothing
  case target of
    Nothing -> pure unit
    Just idx -> do
      liftEffect (preventDefault ev)
      mel <- case kind of
        Trigger -> H.getHTMLElementRef (triggerRef idx)
        Link -> H.getHTMLElementRef (linkRef idx)
      for_ mel (liftEffect <<< HTMLElement.focus)

clampLow :: Int -> Int
clampLow i = if i < 0 then 0 else i

clampHigh :: Int -> Int -> Int
clampHigh count i = if i >= count then count - 1 else i

focusFirstLink :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
focusFirstLink = do
  mel <- H.getHTMLElementRef (linkRef 0)
  for_ mel (liftEffect <<< HTMLElement.focus)

-- | Focus the LAST link of the open content (the proxy's 'end' entry — shift+tab back into it).
focusLastLink :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
focusLastLink = do
  st <- H.get
  let n = Array.length (fromMaybe [] (openIndex st >>= Array.index st.items <#> _.links))
  when (n > 0) do
    mel <- H.getHTMLElementRef (linkRef (n - 1))
    for_ mel (liftEffect <<< HTMLElement.focus)

-- | Whether `target` is contained within the element at `mel` (relatedTarget-inside-content test).
containsTarget :: forall m. MonadEffect m => Maybe HTMLElement.HTMLElement -> Maybe EventTarget -> H.HalogenM State Action () Output m Boolean
containsTarget mel mtarget = case mel, mtarget of
  Just el, Just t -> case HTMLElement.fromEventTarget t of
    Just te -> liftEffect (Node.contains (HTMLElement.toNode el) (HTMLElement.toNode te))
    Nothing -> pure false
  _, _ -> pure false

-- ─────────────────────────────────────────────────────────────────────────────
-- Open / close
-- ─────────────────────────────────────────────────────────────────────────────

openMenu :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
openMenu value = do
  st <- H.get
  when (openValue st /= value) do
    let already = openValue st /= ""
    -- record the prior open value (radix usePrevious) so the new content's data-motion can read
    -- the transition direction (from-start/from-end).
    H.modify_ _ { previousValue = openValue st, ctrl = (change value st.ctrl).next, presence = Open }
    -- radix setValue side-effect on open: cancel the skip-delay timer and (if skipDelay is
    -- enabled) drop into INSTANT-open mode while the menu is open.
    clearSkipTimer
    when (st.skipDelayDuration > 0) (H.modify_ _ { isOpenDelayed = false })
    H.raise (ValueChanged value)
    when (not already) armOpen
    -- the content/viewport are newly rendered this cycle; measure on the next microtask, once
    -- Halogen has flushed the render (the trigger/content refs only resolve then).
    scheduleAfterOpen

-- | The pointer-open dispatch (radix onTriggerEnter): cancel a pending open, then open delayed
-- | (a fresh hover waits delayDuration) or instantly (we're inside the skip-delay window).
onTriggerEnter :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
onTriggerEnter value = do
  clearOpenTimer
  st <- H.get
  if st.isOpenDelayed then handleDelayedOpen value else handleOpen value

handleOpen :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
handleOpen value = clearCloseTimer *> openMenu value

-- | Delayed hover-open: if this item is already open (transitioning content→trigger) just cancel
-- | the close; otherwise arm the open timer for delayDuration.
handleDelayedOpen :: forall m. MonadEffect m => String -> H.HalogenM State Action () Output m Unit
handleDelayedOpen value = do
  st <- H.get
  if openValue st == value then clearCloseTimer
  else do
    h <- armTimer st.delayDuration (OpenTimerFired value)
    H.modify_ _ { openTimer = Just h }

-- | Start (or restart) the 150ms close timer (radix startCloseTimer).
startCloseTimer :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
startCloseTimer = do
  clearCloseTimer
  h <- armTimer 150 CloseTimerFired
  H.modify_ _ { closeTimer = Just h }

-- | Arm a one-shot timer dispatching `act` after `ms`; returns (clock id, emitter sub) to cancel.
armTimer :: forall m. MonadEffect m => Int -> Action -> H.HalogenM State Action () Output m (Tuple Dom.TimeoutId H.SubscriptionId)
armTimer ms act = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (act <$ emitter)
  tid <- liftEffect (Dom.setTimeout ms (HS.notify listener unit))
  pure (Tuple tid sid)

clearOpenTimer :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
clearOpenTimer = do
  st <- H.get
  for_ st.openTimer \(Tuple tid sid) -> liftEffect (Dom.clearTimeout tid) *> H.unsubscribe sid
  H.modify_ _ { openTimer = Nothing }

clearCloseTimer :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
clearCloseTimer = do
  st <- H.get
  for_ st.closeTimer \(Tuple tid sid) -> liftEffect (Dom.clearTimeout tid) *> H.unsubscribe sid
  H.modify_ _ { closeTimer = Nothing }

clearSkipTimer :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
clearSkipTimer = do
  st <- H.get
  for_ st.skipTimer \(Tuple tid sid) -> liftEffect (Dom.clearTimeout tid) *> H.unsubscribe sid
  H.modify_ _ { skipTimer = Nothing }

armOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
armOpen = do
  doc <- liftEffect (HTML.window >>= Window.document)
  let docTarget = HTMLDocument.toEventTarget doc
  escSub <- H.subscribe (Dismiss.escape docTarget EscapePressed)
  H.modify_ \s -> s { subs = s.subs <> [ escSub ] }

scheduleAfterOpen :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
scheduleAfterOpen = do
  { emitter, listener } <- liftEffect HS.create
  void (H.subscribe (AfterOpen <$ emitter))
  liftEffect (Dom.queueMicrotask (HS.notify listener unit))

closeMenu :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeMenu = do
  -- cancel any pending hover-open so a close can't be immediately undone by a stale timer.
  clearOpenTimer
  st <- H.get
  when (openValue st /= "") do
    -- if focus is inside the closing content, restore it to the open trigger (radix's
    -- ROOT_CONTENT_DISMISS handler). Capture the trigger ref BEFORE the content unmounts.
    mtrig <- case openIndex st of
      Just i -> H.getHTMLElementRef (triggerRef i)
      Nothing -> pure Nothing
    insideContent <- focusInside contentRef
    for_ st.subs H.unsubscribe
    -- the bare primitive has no exit animation → the content unmounts synchronously.
    H.modify_ _
      { previousValue = openValue st
      , ctrl = (change "" st.ctrl).next
      , presence = finishExit (present false st.presence)
      , subs = []
      , viewport = Nothing
      , indicator = Nothing
      }
    H.raise (ValueChanged "")
    -- radix setValue side-effect on close: open the skip-delay window — for skipDelayDuration ms
    -- the next hover-open is INSTANT; after it elapses, hover-opens are delayed again.
    clearSkipTimer
    when (st.skipDelayDuration > 0) do
      h <- armTimer st.skipDelayDuration SkipTimerFired
      H.modify_ _ { skipTimer = Just h }
    -- restore focus: to the trigger if focus was in the content (keyboard close), else leave it.
    when insideContent $ for_ mtrig (liftEffect <<< HTMLElement.focus)

-- | Whether the active element is currently inside the element at `ref`.
focusInside :: forall m. MonadEffect m => H.RefLabel -> H.HalogenM State Action () Output m Boolean
focusInside ref = do
  mel <- H.getHTMLElementRef ref
  case mel of
    Nothing -> pure false
    Just el -> liftEffect do
      doc <- HTML.window >>= Window.document
      mact <- HTMLDocument.activeElement doc
      maybe (pure false) (\a -> Node.contains (HTMLElement.toNode el) (HTMLElement.toNode a)) mact

-- | Measure the active trigger (→ indicator width + offset) and the active content (→ viewport
-- | size vars), reading offset* exactly as upstream does. Run after the open render flushes.
measure :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
measure = do
  st <- H.get
  case openIndex st of
    Nothing -> pure unit
    Just i -> do
      mtrig <- H.getHTMLElementRef (triggerRef i)
      mcont <- H.getHTMLElementRef contentRef
      ind <- liftEffect (traverseMeasure mtrig)
      vp <- liftEffect (traverseMeasure mcont)
      H.modify_ _ { indicator = ind, viewport = vp }

traverseMeasure :: Maybe HTMLElement.HTMLElement -> Effect (Maybe Measure)
traverseMeasure = case _ of
  Nothing -> pure Nothing
  Just el -> Just <$> Dom.offsetMetrics el

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    if v == "" then closeMenu else openMenu v
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (openValue st)))
