-- | Hydrogen.Radix.PasswordToggleField — a password input paired with a
-- | show/hide toggle (radix `PasswordToggleField`).
-- |
-- | The simplest stateful port: clone Toggle.purs's eval skeleton but render TWO
-- | sibling nodes (an `<input>` + a `<button>`) instead of one, and swap the input
-- | TYPE (password↔text) instead of `aria-pressed`. The upstream `Root` renders no
-- | DOM (a context provider); the Halogen component IS the Root, so the two siblings
-- | are wrapped in a `display:contents` div that the open-state DOM oracle's
-- | normalizer strips (themes-open-dom.mjs lines 53-56).
-- |
-- | UPSTREAM DOM CONTRACT (verified against the committed golden-dom oracles —
-- | passwordtoggle.{hidden,visible}). The captured DOM is POST-hydration:
-- |   * Input  → `<input type="password|text" id=inputId autocomplete=…
-- |     autocapitalize="off" spellcheck="false">`. NO role/aria-*/data-* of its own.
-- |   * Toggle → `<button type="button" aria-controls=inputId id=inputId>`. The
-- |     `id=inputId` is an UPSTREAM QUIRK (the button is given the SAME id as the
-- |     input — a real id collision at upstream line 303); reproduced for byte-
-- |     identity. NO aria-pressed, NO data-state, NO aria-hidden, NO tabindex.
-- |     `aria-label` is OMITTED when the button has inner text (the golden uses a
-- |     text Slot Show/Hide) — the accessible name comes from the text; we only emit
-- |     `aria-label` when `toggleChildren` are empty.
-- |
-- | The visibility flip is synchronous (upstream wraps `setVisible` in `flushSync`),
-- | so type=password→text and Show→Hide settle before the snapshot. No Presence, no
-- | portal, no roving focus, no positioning — the lightest stateful primitive.
module Hydrogen.Radix.PasswordToggleField
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

import Data.Array (null)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as ARIA
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | Per-part class lists: the `input` and the `toggle` button (the Root emits no
-- | DOM, so it has no style slot).
type Style = { input :: ClassNames, toggle :: ClassNames }

defaultStyle :: Style
defaultStyle = { input: cn "rdx-password-input", toggle: cn "rdx-password-toggle" }

type Input =
  { visible :: Maybe Boolean              -- controlled visibility (Nothing = uncontrolled)
  , defaultVisible :: Boolean             -- initial visibility when uncontrolled
  , inputId :: Maybe String               -- explicit input id; Nothing ⇒ minted on Initialize
  , autoComplete :: String                -- input autocomplete (default "current-password")
  , showLabel :: String                   -- aria-label when toggle has no inner text (hidden)
  , hideLabel :: String                   -- aria-label when toggle has no inner text (visible)
  , disabled :: Boolean                   -- pass-through native disabled on BOTH input + toggle
  , iconOnly :: Boolean                    -- the toggle content is icon-only (empty textContent):
                                           -- upstream's MutationObserver applies the auto aria-label
                                           -- when textContent is empty; the consumer declares it here
                                           -- (the DOM outcome is identical + deterministic).
  , toggleVisible :: Array HH.PlainHTML    -- toggle content shown when password is VISIBLE (e.g. "Hide")
  , toggleHidden :: Array HH.PlainHTML     -- toggle content shown when password is HIDDEN (e.g. "Show")
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { visible: Nothing
  , defaultVisible: false
  , inputId: Nothing
  , autoComplete: "current-password"
  , showLabel: "Show password"
  , hideLabel: "Hide password"
  , disabled: false
  , iconOnly: false
  , toggleVisible: []
  , toggleHidden: []
  , style: defaultStyle
  }

-- | Emitted whenever the user toggles — including in controlled mode, where the
-- | parent is expected to update `visible` in response.
data Output = VisibilityChanged Boolean

data Query a
  = SetVisible Boolean a
  | GetVisible (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , inputId :: Maybe String
  , autoComplete :: String
  , showLabel :: String
  , hideLabel :: String
  , disabled :: Boolean
  , iconOnly :: Boolean
  , toggleVisible :: Array HH.PlainHTML
  , toggleHidden :: Array HH.PlainHTML
  , style :: Style
  }

data Action
  = Initialize
  | Toggled
  | Receive Input

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
  { ctrl: controllable input.visible input.defaultVisible
  , inputId: input.inputId
  , autoComplete: input.autoComplete
  , showLabel: input.showLabel
  , hideLabel: input.hideLabel
  , disabled: input.disabled
  , iconOnly: input.iconOnly
  , toggleVisible: input.toggleVisible
  , toggleHidden: input.toggleHidden
  , style: input.style
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    visible = current st.ctrl
    idv = fromMaybe "" st.inputId
    toggleKids = if visible then st.toggleVisible else st.toggleHidden
    -- "has visible text" mirrors upstream's textContent check: an icon-only toggle has empty
    -- textContent (so the auto aria-label applies) even though it has child elements.
    hasText = not (null toggleKids) && not st.iconOnly
    autoLabel = if visible then st.hideLabel else st.showLabel
  in
    -- `display:contents` wrapper: the upstream Root renders no element, so the
    -- oracle normalizer strips this single-attribute contents-only div and renders
    -- the input+button at the same depth (themes-open-dom.mjs lines 53-56).
    HH.div
      [ HP.style "display:contents" ]
      [ HH.input
          ( [ HP.type_ (if visible then HP.InputText else HP.InputPassword)
            , HP.id idv
            , HP.attr (HH.AttrName "autocomplete") st.autoComplete
            , HP.attr (HH.AttrName "autocapitalize") "off"
            , HP.attr (HH.AttrName "spellcheck") "false"
            , classes st.style.input
            ]
              <> (if st.disabled then [ HP.attr (HH.AttrName "disabled") "" ] else [])
          )
      , HH.button
          ( [ HP.type_ HP.ButtonButton
            , ARIA.controls idv
            , HP.id idv
            , classes st.style.toggle
            , HE.onClick \_ -> Toggled
            ]
              <> (if hasText then [] else [ ARIA.label autoLabel ])
              <> (if st.disabled then [ HP.attr (HH.AttrName "disabled") "" ] else [])
          )
          (map HH.fromPlainHTML toggleKids)
      ]

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    st <- H.get
    case st.inputId of
      Just _ -> pure unit
      Nothing -> do
        i <- useId
        H.modify_ _ { inputId = Just i }
  Toggled -> do
    st <- H.get
    let res = change (not (current st.ctrl)) st.ctrl
    H.modify_ _ { ctrl = res.next }
    H.raise (VisibilityChanged res.emit)
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.visible st.ctrl
      , autoComplete = input.autoComplete
      , showLabel = input.showLabel
      , hideLabel = input.hideLabel
      , disabled = input.disabled
      , iconOnly = input.iconOnly
      , toggleVisible = input.toggleVisible
      , toggleHidden = input.toggleHidden
      , style = input.style
      -- inputId: an explicit id from input takes effect; once minted, keep ours.
      , inputId = case input.inputId of
          Just _ -> input.inputId
          Nothing -> st.inputId
      }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetVisible v a -> do
    H.modify_ \st -> st { ctrl = (change v st.ctrl).next }
    pure (Just a)
  GetVisible reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
