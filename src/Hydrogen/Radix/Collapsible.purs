-- | Hydrogen.Radix.Collapsible — a disclosure (radix `Collapsible`).
-- |
-- | The SIMPLEST composed disclosure: a `button` trigger that toggles an `open`
-- | Boolean, and a `div` of content shown while open — kept mounted through its
-- | exit animation via `Behavior.Presence`, then dropped. No focus trap, no
-- | scroll lock, no dismissable layer (those belong to Dialog/Popover); the
-- | disclosure is pure open/closed.
-- |
-- |   * `ControllableState` for open/closed (controlled `open :: Maybe Boolean`
-- |     OR uncontrolled `defaultOpen`); the controlled slot refreshed on `receive`.
-- |   * `Presence` for the content: on open → `Open` (rendered, `data-state=open`);
-- |     on close → `present false` → `Closing` (still rendered, `data-state=closed`)
-- |     and we read the content ref — `hasAnimation`? subscribe `animationEnd`
-- |     (→ `AnimDone` → `finishExit` + unsubscribe) else `finishExit` now.
-- |   * the stable surface CSS targets — `data-state`, `data-disabled`,
-- |     `aria-expanded`, `aria-controls` (gated on open), plus the
-- |     `--radix-collapsible-content-{height,width}` size vars on the open content —
-- |     plus per-part classes from `Style`.
-- |
-- | The content `id` (the `aria-controls` target) is generated per mount
-- | (Behavior.Id), so multiple Collapsibles on a page don't collide. Parts taken as
-- | `Array HH.PlainHTML` (trigger label + content); the compound Trigger/Content
-- | component API is deferred.
module Hydrogen.Radix.Collapsible
  ( component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Behavior.Presence (Presence(..), present, finishExit, isRendered, hasAnimation, animationEnd)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState, dataAttr, aria)
import Web.HTML.HTMLElement as HTMLElement

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Per-part class lists: the root, the trigger button, the content panel.
type Style =
  { root :: ClassNames
  , trigger :: ClassNames
  , content :: ClassNames
  }

-- | Semantic default — a preset supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-collapsible"
  , trigger: cn "rdx-collapsible-trigger"
  , content: cn "rdx-collapsible-content"
  }

type Input =
  { open :: Maybe Boolean          -- controlled open state (Nothing = uncontrolled)
  , defaultOpen :: Boolean         -- initial state when uncontrolled
  , disabled :: Boolean
  , style :: Style
  , triggerAttrs :: Array (Tuple String String)  -- extra data-* on the trigger (e.g. accent-color)
  , trigger :: Array HH.PlainHTML  -- static trigger label/icon
  , content :: Array HH.PlainHTML  -- disclosed content
  , exitCss :: String              -- optional <style> (an exit keyframe on the closing content)
  }

defaultInput :: Input
defaultInput =
  { open: Nothing
  , defaultOpen: false
  , disabled: false
  , style: defaultStyle
  , triggerAttrs: []
  , trigger: []
  , content: []
  , exitCss: ""
  }

-- | Emitted on every user-requested change — including in controlled mode, where
-- | the parent is expected to update `open` in response.
data Output = OpenChanged Boolean

-- | External control.
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
  , disabled :: Boolean
  , style :: Style
  , triggerAttrs :: Array (Tuple String String)
  , trigger :: Array HH.PlainHTML
  , content :: Array HH.PlainHTML
  , exitCss :: String
  , animSub :: Maybe H.SubscriptionId
  , contentId :: String  -- generated on Initialize; the trigger aria-controls target
  }

data Action
  = Initialize
  | Receive Input
  | Toggle
  | AnimDone

contentRef :: H.RefLabel
contentRef = H.RefLabel "rdx-collapsible-content"

-- | The CSS custom properties upstream CollapsibleContentImpl stamps on the content
-- | div (measured via getBoundingClientRect). Any px works — the oracle normalizer
-- | maps `<int>px`→`<px>`, so the SET of declarations is what matters.
contentSizeVars :: String
contentSizeVars =
  "--radix-collapsible-content-height: 100px; --radix-collapsible-content-width: 200px;"

-- | Map the extra trigger data-* pairs to Halogen props (e.g. `data-accent-color`).
triggerData :: forall r i. Array (Tuple String String) -> Array (HP.IProp r i)
triggerData = map (\(Tuple k v) -> HP.attr (HH.AttrName ("data-" <> k)) v)

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
  , presence: if open then Open else Closed
  , disabled: input.disabled
  , style: input.style
  , triggerAttrs: input.triggerAttrs
  , trigger: input.trigger
  , content: input.content
  , exitCss: input.exitCss
  , animSub: Nothing
  , contentId: ""
  }
  where
  open = case input.open of
    Just v -> v
    Nothing -> input.defaultOpen

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    open = current st.ctrl
  in
    HH.div
      ( [ classes st.style.root
        , dataState (if open then "open" else "closed")
        ]
          -- upstream stamps data-disabled="" on the Collapsible ROOT when disabled
          -- (collapsible.tsx:69 `data-disabled={disabled ? '' : undefined}`).
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
      )
      ( (if st.exitCss == "" then [] else [ HH.element (HH.ElemName "style") [] [ HH.text st.exitCss ] ])
          <>
          [ HH.button
            ( [ HP.type_ HP.ButtonButton
              , aria "expanded" (show open)
              , dataState (if open then "open" else "closed")
              , HP.disabled st.disabled
              , classes st.style.trigger
              , HE.onClick \_ -> Toggle
              ]
                -- aria-controls references the content only while open (upstream gates it)
                <> (if open then [ aria "controls" st.contentId ] else [])
                <> triggerData st.triggerAttrs
                <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
            )
            (map HH.fromPlainHTML st.trigger)
        ]
          <>
            -- The content WRAPPER div is ALWAYS in the DOM: upstream's CollapsibleContent passes
            -- a render-prop child to Presence, which makes Presence `forceMount` (always render
            -- the impl, gating visibility via `present`/`hidden`, NOT unmounting it). So even at
            -- closed-rest the div exists — hidden, empty, data-state="closed". `isOpen = open ||
            -- isPresent` (= the content is still rendered/animating-out) drives children + hidden.
            ( let
                isOpen = isRendered st.presence
              in
                [ HH.div
                    ( [ HP.ref contentRef
                      , HP.id st.contentId
                      -- data-state mirrors `getState(context.open)` — open's truth NOW, so during
                      -- the closing frame it is already "closed" (open=false, still present).
                      , dataState (if open then "open" else "closed")
                      , classes st.style.content
                      -- the cached measured size vars are populated only while the content is
                      -- rendered (open OR exiting); at closed-rest upstream emits an empty
                      -- `style=""` (height/width undefined) — match it exactly.
                      , HP.style (if isOpen then contentSizeVars else "")
                      ]
                        -- `hidden={!isOpen}`: hidden only when neither open nor exiting.
                        <> (if isOpen then [] else [ HP.attr (HH.AttrName "hidden") "" ])
                        <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
                    )
                    -- `{isOpen && children}`: children render while open OR exiting, empty otherwise.
                    (if isOpen then map HH.fromPlainHTML st.content else [])
                ]
            )
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    cid <- useId
    H.modify_ _ { contentId = cid }
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.open st.ctrl
      , disabled = input.disabled
      , style = input.style
      , triggerAttrs = input.triggerAttrs
      , trigger = input.trigger
      , content = input.content
      , exitCss = input.exitCss
      }
  Toggle -> do
    st <- H.get
    when (not st.disabled) (setOpen (not (current st.ctrl)))
  AnimDone -> do
    st <- H.get
    for_ st.animSub H.unsubscribe
    H.modify_ _ { presence = finishExit st.presence, animSub = Nothing }

-- | Drive open/closed: advance the controllable, raise the change, and run the
-- | Presence transition (open → mounted; close → exit animation, then unmount).
setOpen :: forall m. MonadEffect m => Boolean -> H.HalogenM State Action () Output m Unit
setOpen target = do
  st <- H.get
  when (current st.ctrl /= target) do
    let res = change target st.ctrl
    H.modify_ _ { ctrl = res.next }
    H.raise (OpenChanged res.emit)
    if target then
      -- opening: cancel any pending exit, mount immediately
      do
        for_ st.animSub H.unsubscribe
        H.modify_ _ { presence = Open, animSub = Nothing }
    else
      -- closing: enter Closing (still rendered), then run/skip the exit animation
      do
        H.modify_ _ { presence = present false st.presence }
        mnode <- H.getHTMLElementRef contentRef
        case mnode of
          Nothing -> H.modify_ \s -> s { presence = finishExit s.presence }
          Just node -> do
            animates <- liftEffect (hasAnimation node)
            if animates then do
              sub <- H.subscribe (animationEnd (HTMLElement.toEventTarget node) AnimDone)
              H.modify_ _ { animSub = Just sub }
            else
              H.modify_ \s -> s { presence = finishExit s.presence }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetOpen v a -> do
    setOpen v
    pure (Just a)
  GetOpen reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
