-- | Hydrogen.Radix.Toast — a time-driven notification (radix `Toast`).
-- |
-- | Toast is the hardest overlay to oracle because it is CLOCK-driven (auto-dismiss +
-- | swipe + a notification queue). The DOM/a11y contract that IS deterministic — and the
-- | scope this v1 reproduces byte-identical to upstream — is a single toast held OPEN with
-- | its auto-dismiss timer defused (`duration = Infinity`), plus its CLOSING exit lifecycle
-- | (Escape on the focused toast → `data-state=closed` lingers through the exit animation,
-- | then unmounts). That is exactly what the open/closing DOM oracles capture from bare
-- | @radix-ui/react-toast.
-- |
-- | Anatomy (matches upstream exactly; the component root is display:contents, stripped by
-- | the DOM-oracle normalizer like Dialog's):
-- |
-- |   <div role=region aria-label=<label> tabindex=-1 style=…>   the VIEWPORT region wrapper
-- |     <span …visuallyHidden+position:fixed tabindex=0>          head focus proxy (gated on hasToasts)
-- |     <ol tabindex=-1>                                          the toast list
-- |       <li data-radix-collection-item data-state=open|closed   the toast (Presence-mounted)
-- |           data-swipe-direction=<dir>
-- |           style="user-select: none; touch-action: none;" tabindex=0>
-- |         <div>…title…</div>
-- |         <div>…description…</div>
-- |         <button data-radix-toast-announce-exclude                 the action
-- |                 data-radix-toast-announce-alt=<altText> type=button>…
-- |         <button data-radix-toast-announce-exclude aria-label=… type=button>…  the close
-- |     <span …visuallyHidden+position:fixed tabindex=0>          tail focus proxy
-- |   <span role=status aria-live=… …visuallyHidden>              the SR-announce mirror (→ body)
-- |
-- | The role=status ANNOUNCE node is an SR-only mirror radix portals to body, fills with the
-- | toast text, and self-unmounts ~1000ms after open. It is part of the a11y contract (the
-- | a11y oracle snapshots it) but a determinism hazard for the DOM oracle (timer-driven
-- | presence/content), so the DOM normalizer strips it symmetrically from golden AND port.
-- | The port renders a STATIC announce mirror (label + visible toast text, action included,
-- | close/announce-excluded parts omitted) so the a11y tree matches upstream.
-- |
-- | Substrate reused (per the port design): `Presence` (the open→closing→closed lifecycle +
-- | animationend, verbatim from Dialog), `Portal` (adopt the <li> into the <ol> and the
-- | announce node into body, with the AfterOpen/AfterClose re-adopt discipline), the
-- | `DismissableLayer.escape` emitter (Escape-to-close while a toast is focused), and
-- | `VisuallyHidden.inlineStyle` (focus proxies + announce node). NOT a modal layer: no
-- | scroll-lock / hideOthers / focus-guards (toast is non-modal).
-- |
-- | v1 scope: ONE toast, controlled `open` (held true with `duration=Infinity`) or
-- | uncontrolled (`defaultOpen=true`, internal open live so Escape can close it). The timer
-- | model (per-item setTimeout, pause/resume), the multi-toast queue, and swipe are deferred —
-- | the deterministic open/closing oracle does not exercise them.
module Hydrogen.Radix.Toast
  ( component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , ToastType(..)
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (null)
import Data.Foldable (for_)
import Data.Int (round)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Data.String (trim)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Subscription as HS
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.DismissableLayer as Dismiss
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, dataStateOf, hasAnimation, animationEnd)
import Hydrogen.Radix.Foundation.Dom as Dom
import Hydrogen.Radix.Foundation.Portal as Portal
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes)
import Hydrogen.Radix.VisuallyHidden (inlineStyle)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Foreground toasts announce assertively (interrupt the SR); background ones politely.
data ToastType = Foreground | Background

derive instance eqToastType :: Eq ToastType

-- | Per-part class lists. The bare primitive leaves them semantic; a preset supplies rt-*.
type Style =
  { viewport :: ClassNames   -- the <ol>
  , wrapper :: ClassNames    -- the role=region wrapper div
  , root :: ClassNames       -- the <li>
  , title :: ClassNames
  , description :: ClassNames
  , action :: ClassNames
  , close :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { viewport: cn "rdx-toast-viewport"
  , wrapper: cn "rdx-toast-wrapper"
  , root: cn "rdx-toast-root"
  , title: cn "rdx-toast-title"
  , description: cn "rdx-toast-description"
  , action: cn "rdx-toast-action"
  , close: cn "rdx-toast-close"
  }

type Input =
  { label :: String                  -- viewport aria-label (default "Notifications (F8)")
  , swipeDirection :: String         -- data-swipe-direction (default "right")
  , announceLabel :: String          -- the announce-node label prefix (default "Notification")
  , open :: Maybe Boolean            -- controlled open (Just true held = no auto-dismiss)
  , defaultOpen :: Boolean           -- uncontrolled initial (default true)
  , duration :: Maybe Int            -- auto-dismiss after N ms (radix default 5000); Nothing = held open
                                      -- (the at-rest DOM oracle pins duration=Nothing so it never closes)
  , toastType :: ToastType           -- assertive | polite announce
  , closeOnEscape :: Boolean
  , style :: Style
  , title :: Array HH.PlainHTML
  , description :: Array HH.PlainHTML
  , action :: Array HH.PlainHTML
  , altText :: String                -- the action's announce-alt
  , close :: Array HH.PlainHTML
  , closeLabel :: String             -- the close button's aria-label
  , announceText :: String           -- the SR-mirror text (label + visible non-excluded text);
                                      -- supplied by the caller since PlainHTML is not introspectable
  , exitCss :: String                -- optional <style> (e.g. an exit keyframe on the closing
                                      -- li) so the close lifecycle has a real animation to linger
                                      -- through; emitted inside the (stripped) display:contents root
  }

defaultInput :: Input
defaultInput =
  { label: "Notifications (F8)"
  , swipeDirection: "right"
  , announceLabel: "Notification"
  , open: Nothing
  , defaultOpen: true
  , duration: Nothing
  , toastType: Foreground
  , closeOnEscape: true
  , style: defaultStyle
  , title: []
  , description: []
  , action: []
  , altText: ""
  , close: []
  , closeLabel: "Close"
  , announceText: ""
  , exitCss: ""
  }

data Output = OpenChanged Boolean | Escaped

data Query a
  = SetOpen Boolean a
  | GetOpen (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , presence :: Presence
  , label :: String
  , swipeDirection :: String
  , announceLabel :: String
  , toastType :: ToastType
  , closeOnEscape :: Boolean
  , style :: Style
  , title :: Array HH.PlainHTML
  , description :: Array HH.PlainHTML
  , action :: Array HH.PlainHTML
  , altText :: String
  , close :: Array HH.PlainHTML
  , closeLabel :: String
  , announceText :: String   -- the SR mirror's text (label + title + description + action)
  , exitCss :: String
  , escSub :: Maybe H.SubscriptionId
  , postSub :: Maybe H.SubscriptionId
  , animSub :: Maybe H.SubscriptionId
  , duration :: Maybe Int
  , durSub :: Maybe (Tuple Dom.TimeoutId H.SubscriptionId)  -- the live auto-dismiss timer
  , durRemaining :: Maybe Int      -- ms left to run (preserved across a hover pause)
  , durStart :: Maybe Number       -- performance.now() when the live timer was last armed
  }

data Action
  = Initialize
  | Receive Input
  | ActionClicked
  | CloseClicked
  | DurationElapsed   -- the auto-dismiss timer fired → close
  | PauseTimer        -- pointer/focus entered the viewport → pause auto-dismiss, keep remaining
  | ResumeTimer       -- pointer/focus left the viewport → resume with the remaining time
  | EscapePressed
  | AfterMount   -- portal the announce node into body after the open render flushed
  | AfterClose   -- arm the exit animation on the closing re-render
  | AnimDone

-- | The portaled toast <li> (we keep it under the <ol> in render; no body re-parent needed —
-- | Halogen owns the ol, the li is its child by construction).
liRef :: H.RefLabel
liRef = H.RefLabel "rdx-toast-li"

-- | The SR-announce mirror, adopted into document.body (matches upstream placement).
announceRef :: H.RefLabel
announceRef = H.RefLabel "rdx-toast-announce"

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
  , label: input.label
  , swipeDirection: input.swipeDirection
  , announceLabel: input.announceLabel
  , toastType: input.toastType
  , closeOnEscape: input.closeOnEscape
  , style: input.style
  , title: input.title
  , description: input.description
  , action: input.action
  , altText: input.altText
  , close: input.close
  , closeLabel: input.closeLabel
  , announceText: input.announceText
  , exitCss: input.exitCss
  , escSub: Nothing
  , postSub: Nothing
  , animSub: Nothing
  , duration: input.duration
  , durSub: Nothing
  , durRemaining: Nothing
  , durStart: Nothing
  }
  where
  startOpen = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

aria :: forall r i. String -> String -> HP.IProp r i
aria name val = HP.attr (HH.AttrName ("aria-" <> name)) val

roleAttr :: forall r i. String -> HP.IProp r i
roleAttr = HP.attr (HH.AttrName "role")

dataState' :: forall r i. String -> HP.IProp r i
dataState' = HP.attr (HH.AttrName "data-state")

dataAttr' :: forall r i. String -> String -> HP.IProp r i
dataAttr' name val = HP.attr (HH.AttrName ("data-" <> name)) val

-- | A VisuallyHidden focus proxy span: tabindex=0, position:fixed + the clip style. No role,
-- | no data-* (matches upstream's ToastFocusProxy exactly). The style string is the BROWSER-
-- | CANONICAL serialization the golden emits (React sets `position:fixed` over VisuallyHidden's
-- | clip styles as a style OBJECT, which the browser re-serializes: `position:fixed` wins over
-- | the overridden `position:absolute`, `border:0`→`border: 0px`, `word-wrap`→`overflow-wrap`).
-- | We write that exact serialized form so the raw `style` attribute matches byte-for-byte.
focusProxyStyle :: String
focusProxyStyle =
  "position: fixed; border: 0px; width: 1px; height: 1px; padding: 0px; "
    <> "margin: -1px; overflow: hidden; clip: rect(0px, 0px, 0px, 0px); "
    <> "white-space: nowrap; overflow-wrap: normal;"

focusProxy :: forall m. H.ComponentHTML Action () m
focusProxy =
  HH.span
    [ HP.style focusProxyStyle
    , HP.tabIndex 0
    ]
    []

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    hasToasts = isRendered st.presence
    -- the region wrapper carries pointer-events:none ONLY when empty (upstream gates it);
    -- with a toast mounted the inline style is empty.
    regionStyle = if hasToasts then "" else "pointer-events: none;"
  in
    -- display:contents wrapper: Halogen needs one root; the DOM-oracle normalizer strips it.
    HH.div [ HP.style "display:contents" ]
      ( (if st.exitCss == "" then [] else [ HH.element (HH.ElemName "style") [] [ HH.text st.exitCss ] ])
          <> [ HH.div
            [ roleAttr "region"
            , aria "label" st.label
            , HP.tabIndex (-1)
            , HP.style regionStyle
            , classes st.style.wrapper
            ]
            ( (if hasToasts then [ focusProxy ] else [])
                <> [ HH.ol
                       [ HP.tabIndex (-1)
                       , classes st.style.viewport
                       -- pointer/focus over the viewport pauses the auto-dismiss; leaving
                       -- resumes with the remaining time (radix pauses on the viewport, not
                       -- the li, so the whole region — incl. the close button — is a pause zone).
                       , HE.onMouseEnter \_ -> PauseTimer
                       , HE.onMouseLeave \_ -> ResumeTimer
                       , HE.onFocusIn \_ -> PauseTimer
                       , HE.onFocusOut \_ -> ResumeTimer
                       ]
                       (if hasToasts then [ toastLi st ] else [])
                   ]
                <> (if hasToasts then [ focusProxy ] else [])
            )
        ]
          -- the SR-announce mirror — rendered while the toast is present, adopted into body
          -- (AfterMount) to match upstream placement (a body child after #root).
          <> (if hasToasts then [ announceNode st ] else [])
      )

toastLi :: forall m. State -> H.ComponentHTML Action () m
toastLi st =
  HH.li
    [ HP.ref liRef
    , dataAttr' "radix-collection-item" ""
    , dataState' (dataStateOf st.presence)
    , dataAttr' "swipe-direction" st.swipeDirection
    , HP.style "user-select: none; touch-action: none;"
    , HP.tabIndex 0
    , classes st.style.root
    ]
    ( [ HH.div [ classes st.style.title ] (map HH.fromPlainHTML st.title)
      , HH.div [ classes st.style.description ] (map HH.fromPlainHTML st.description)
      , HH.button
          ( [ HP.type_ HP.ButtonButton
            , dataAttr' "radix-toast-announce-exclude" ""
            , dataAttr' "radix-toast-announce-alt" st.altText
            , classes st.style.action
            , HE.onClick \_ -> ActionClicked
            ]
          )
          (map HH.fromPlainHTML st.action)
      , HH.button
          ( [ HP.type_ HP.ButtonButton
            , dataAttr' "radix-toast-announce-exclude" ""
            , aria "label" st.closeLabel
            , classes st.style.close
            , HE.onClick \_ -> CloseClicked
            ]
          )
          (map HH.fromPlainHTML st.close)
      ]
    )

-- | The SR-announce live region (role=status, aria-live=assertive|polite, VisuallyHidden).
-- | Its text is the static `announceText`; portaled to body (AfterMount) like upstream.
ariaLiveFor :: ToastType -> String
ariaLiveFor Foreground = "assertive"
ariaLiveFor Background = "polite"

announceNode :: forall m. State -> H.ComponentHTML Action () m
announceNode st =
  HH.span
    [ HP.ref announceRef
    , roleAttr "status"
    , aria "live" (ariaLiveFor st.toastType)
    , HP.style inlineStyle
    ]
    (if trim st.announceText == "" then [] else [ HH.text st.announceText ])

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    st <- H.get
    -- subscribe Escape-to-close while a toast is present (document-level, like the overlays).
    when (isRendered st.presence && st.closeOnEscape) do
      doc <- liftEffect (HTML.window >>= Window.document)
      sub <- H.subscribe (Dismiss.escape (HTMLDocument.toEventTarget doc) EscapePressed)
      H.modify_ _ { escSub = Just sub }
    -- portal the announce node into body after the first render flushes.
    psid <- scheduleAfter AfterMount
    H.modify_ _ { postSub = Just psid }
    -- arm the auto-dismiss timer: radix schedules setTimeout(handleClose, duration) on open
    -- (default 5000ms) — the defining toast behavior. `duration = Nothing` holds it open
    -- (the controlled/at-rest-oracle path). Manual close/Escape cancels it (`cancelDuration`).
    when (isRendered st.presence) $ for_ st.duration \ms -> armDuration ms
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , label = input.label
      , swipeDirection = input.swipeDirection
      , announceLabel = input.announceLabel
      , toastType = input.toastType
      , closeOnEscape = input.closeOnEscape
      , style = input.style
      , title = input.title
      , description = input.description
      , action = input.action
      , altText = input.altText
      , close = input.close
      , closeLabel = input.closeLabel
      , announceText = input.announceText
      , exitCss = input.exitCss
      , duration = input.duration
      }
  ActionClicked -> closeToast
  CloseClicked -> closeToast
  DurationElapsed -> closeToast
  -- Pause the auto-dismiss while the pointer/focus is over the viewport: kill the live timer
  -- and bank the REMAINING time (radix toast.tsx pause). No live timer ⇒ already paused/no
  -- duration ⇒ no-op.
  PauseTimer -> do
    st <- H.get
    for_ st.durSub \(Tuple tid sid) -> do
      liftEffect (Dom.clearTimeout tid)
      H.unsubscribe sid
      elapsed <- liftEffect Dom.now
      let ran = round (elapsed - maybeNum st.durStart)
          rem = maybeInt st.durRemaining - ran
      H.modify_ _ { durSub = Nothing, durRemaining = Just (max 0 rem) }
  -- Resume on leave with the banked remaining time (radix toast.tsx resume). Only when paused
  -- (no live sub) but a finite duration was running.
  ResumeTimer -> do
    st <- H.get
    case st.durSub, st.duration, st.durRemaining of
      Nothing, Just _, Just rem | rem > 0 -> armDuration rem
      _, _, _ -> pure unit
  EscapePressed -> do
    st <- H.get
    when st.closeOnEscape do
      H.raise Escaped
      closeToast
  AfterMount -> do
    mbody <- liftEffect Portal.documentBody
    mann <- H.getHTMLElementRef announceRef
    case mbody, mann of
      Just body, Just ann -> liftEffect (Portal.adopt body (HTMLElement.toElement ann))
      _, _ -> pure unit
  AfterClose -> do
    -- re-adopt the announce node into body (a re-render re-parented it under the root), then
    -- arm the exit: if the li has a running exit animation, finishExit on animationend; else
    -- finishExit now (synchronous unmount, like an unstyled toast with no exit keyframe).
    mbody <- liftEffect Portal.documentBody
    mann <- H.getHTMLElementRef announceRef
    case mbody, mann of
      Just body, Just ann -> liftEffect (Portal.adopt body (HTMLElement.toElement ann))
      _, _ -> pure unit
    mnode <- H.getHTMLElementRef liRef
    armed <- case mnode of
      Nothing -> pure false
      Just node -> do
        animates <- liftEffect (hasAnimation node)
        if animates then do
          sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
          H.modify_ _ { animSub = Just sub }
          pure true
        else pure false
    when (not armed) finishClose
  AnimDone -> finishClose

-- | Arm a one-shot timer: after `ms`, dispatch `act`. Returns the cancel handle (wall-clock id
-- | + emitter subscription) so the pending auto-dismiss can be torn down on a manual close.
armTimer :: forall m. MonadEffect m => Int -> Action -> H.HalogenM State Action () Output m (Tuple Dom.TimeoutId H.SubscriptionId)
armTimer ms act = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (act <$ emitter)
  tid <- liftEffect (Dom.setTimeout ms (HS.notify listener unit))
  pure (Tuple tid sid)

-- | Arm (or re-arm) the auto-dismiss timer for `ms`, stamping `performance.now()` so a later
-- | pause can compute how much of `ms` has elapsed. Used on open (full duration) and on resume
-- | (the banked remaining time).
armDuration :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
armDuration ms = do
  start <- liftEffect Dom.now
  h <- armTimer ms DurationElapsed
  H.modify_ _ { durSub = Just h, durRemaining = Just ms, durStart = Just start }

-- | Cancel the auto-dismiss timer (clear the clock + drop its subscription + forget the
-- | remaining/start bookkeeping) so a toast closed manually/by Escape never fires a stale
-- | close or resumes a dead timer. Safe when no timer is pending.
cancelDuration :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
cancelDuration = do
  st <- H.get
  for_ st.durSub \(Tuple tid sid) -> liftEffect (Dom.clearTimeout tid) *> H.unsubscribe sid
  H.modify_ _ { durSub = Nothing, durRemaining = Nothing, durStart = Nothing }

-- | `Maybe Number`/`Maybe Int` readers defaulting to 0 — for the pause-elapsed arithmetic.
maybeNum :: Maybe Number -> Number
maybeNum = case _ of
  Just n -> n
  Nothing -> 0.0

maybeInt :: Maybe Int -> Int
maybeInt = case _ of
  Just n -> n
  Nothing -> 0

-- | Dispatch `act` on the next animation frame (after Halogen patches the render).
scheduleAfter :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m H.SubscriptionId
scheduleAfter act = do
  { emitter, listener } <- liftEffect HS.create
  sid <- H.subscribe (act <$ emitter)
  liftEffect (Portal.afterFrame (HS.notify listener unit))
  pure sid

-- | Begin the close: flip controllable + Presence to Closing (the li stays MOUNTED with
-- | data-state=closed through its exit animation), tear down the Escape subscription, and
-- | schedule AfterClose to arm the exit on the next frame.
closeToast :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
closeToast = do
  cancelDuration
  st <- H.get
  when (current st.ctrl) do
    for_ st.escSub H.unsubscribe
    H.modify_ _
      { ctrl = (change false st.ctrl).next
      , presence = present false st.presence
      , escSub = Nothing
      }
    H.raise (OpenChanged false)
    psid <- scheduleAfter AfterClose
    H.modify_ _ { postSub = Just psid }

finishClose :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
finishClose = do
  st <- H.get
  for_ st.animSub H.unsubscribe
  for_ st.postSub H.unsubscribe
  H.modify_ _ { presence = finishExit st.presence, animSub = Nothing, postSub = Nothing }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    when (not v) closeToast
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
