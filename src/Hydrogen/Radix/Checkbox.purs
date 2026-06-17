-- | Hydrogen.Radix.Checkbox — a tri-state checkbox (radix `Checkbox`).
-- |
-- | A stateful primitive, following the `Toggle` template exactly: a Halogen
-- | component with a `Slot`/`Query`/`Output` surface, controlled OR uncontrolled
-- | state via `Behavior.ControllableState`, the controlled prop refreshed from
-- | input on `receive`, and the stable behavioral surface CSS targets emitted
-- | alongside per-part classes from the component's `Style` record.
-- |
-- | radix's checked value is `boolean | 'indeterminate'`; we model it faithfully
-- | as the three-valued `CheckedState`. A click toggles Unchecked↔Checked and
-- | Indeterminate→Checked (when not disabled), raising `CheckedChanged` on every
-- | user-requested change (controlled mode too — the parent updates `checked` in
-- | response).
-- |
-- | The rendered element is a `<button role="checkbox">` carrying
-- | `aria-checked` ("true"/"false"/"mixed"), `aria-required`, `data-state`
-- | ("checked"/"unchecked"/"indeterminate"), `data-disabled`, `disabled`, `value`,
-- | plus the `style.root` classes and any `extraAttrs` (the Group/Cards RovingFocus
-- | + Collection attributes). The indicator (the check/dash) is rendered with
-- | `asChild` semantics: when Checked or Indeterminate the single `children`
-- | element IS the indicator (the icon svg already carrying the indicator classes,
-- | `data-state`, and `pointer-events: none`), with NO wrapping span — matching
-- | upstream's CheckboxIndicator asChild.
-- |
-- | NOTE: radix also renders a hidden bubble `<input type="checkbox">` so the
-- | control participates in native form submission/validation, but only when the
-- | control is inside (or SSR-defaults into) a `<form>`. A bare mounted checkbox
-- | with no `<form>` ancestor resolves `isFormControl` false post-mount, so no
-- | bubble input is rendered — which is the case for these gallery pages.
module Hydrogen.Radix.Checkbox
  ( CheckedState(..)
  , component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as ARIA
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState, dataAttr)
import Web.Event.Event (preventDefault)
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | The tri-state checked value (radix `boolean | 'indeterminate'`).
data CheckedState = Unchecked | Checked | Indeterminate

derive instance eqCheckedState :: Eq CheckedState

-- | Per-part class lists: the button root and the indicator span.
type Style = { root :: ClassNames, indicator :: ClassNames }

-- | Semantic default — a preset (orbital/daisy/…) supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-checkbox"
  , indicator: cn "rdx-checkbox-indicator"
  }

type Input =
  { checked :: Maybe CheckedState   -- controlled checked state (Nothing = uncontrolled)
  , defaultChecked :: CheckedState  -- initial state when uncontrolled
  , disabled :: Boolean
  , required :: Boolean
  , name :: String
  , value :: String
  , style :: Style
  , children :: Array HH.PlainHTML   -- the asChild indicator element (check/dash icon)
  -- Extra raw attributes stamped on the button. Group/Cards contexts inject the
  -- attributes RovingFocus + the Collection ItemSlot merge onto the item button
  -- (e.g. `data-radix-collection-item`, `tabindex`, an explicit `aria-required`);
  -- for a bare standalone checkbox this is empty.
  , extraAttrs :: Array (Tuple String String)
  }

defaultInput :: Input
defaultInput =
  { checked: Nothing
  , defaultChecked: Unchecked
  , disabled: false
  , required: false
  , name: ""
  , value: "on"
  , style: defaultStyle
  , children: []
  , extraAttrs: []
  }

-- | Emitted whenever the user requests a change — including in controlled mode,
-- | where the parent is expected to update `checked` in response.
data Output = CheckedChanged CheckedState

-- | External control.
data Query a
  = SetChecked CheckedState a
  | GetChecked (CheckedState -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable CheckedState
  , disabled :: Boolean
  , required :: Boolean
  , name :: String
  , value :: String
  , style :: Style
  , children :: Array HH.PlainHTML
  , extraAttrs :: Array (Tuple String String)
  }

data Action
  = Clicked
  | KeyDowned KE.KeyboardEvent
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
        }
    }

initialState :: Input -> State
initialState input =
  { ctrl: controllable input.checked input.defaultChecked
  , disabled: input.disabled
  , required: input.required
  , name: input.name
  , value: input.value
  , style: input.style
  , children: input.children
  , extraAttrs: input.extraAttrs
  }

-- | The next value on click: Indeterminate resolves to Checked, otherwise toggle.
toggleChecked :: CheckedState -> CheckedState
toggleChecked = case _ of
  Indeterminate -> Checked
  Checked -> Unchecked
  Unchecked -> Checked

-- | `data-state` / radix `getState` realization.
stateName :: CheckedState -> String
stateName = case _ of
  Checked -> "checked"
  Unchecked -> "unchecked"
  Indeterminate -> "indeterminate"

-- | `aria-checked` realization (indeterminate → "mixed").
ariaCheckedName :: CheckedState -> String
ariaCheckedName = case _ of
  Checked -> "true"
  Unchecked -> "false"
  Indeterminate -> "mixed"

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    checked = current st.ctrl
    showIndicator = checked == Checked || checked == Indeterminate
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , ARIA.role "checkbox"
        , ARIA.checked (ariaCheckedName checked)
        , dataState (stateName checked)
        , HP.value st.value
        , HP.disabled st.disabled
        , classes st.style.root
        , HE.onClick \_ -> Clicked
        -- WAI-ARIA: checkboxes do NOT activate on Enter; only Space toggles. Upstream
        -- preventDefaults Enter on the trigger (checkbox.tsx:169-172) — without this a
        -- native <button> would fire a click on Enter (toggling) and, inside a <form>,
        -- submit the form. Mirror it: swallow Enter, leave Space to the native button.
        , HE.onKeyDown KeyDowned
        ]
          <> (if st.required then [ ARIA.required "true" ] else [])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
          <> map (\(Tuple k v) -> HP.attr (HH.AttrName k) v) st.extraAttrs
      )
      ( if showIndicator then
          -- asChild semantics: the Indicator merges its classes/data-state/pointer-
          -- events onto the SINGLE child element (the icon svg) — no wrapping span.
          -- The gallery supplies a child already carrying the rt-* indicator classes,
          -- data-state, and `style="pointer-events: none;"` (see Main.purs helpers),
          -- matching upstream's CheckboxIndicator asChild render byte-for-byte.
          map HH.fromPlainHTML st.children
        else
          []
      )

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Clicked -> do
    st <- H.get
    when (not st.disabled) do
      let res = change (toggleChecked (current st.ctrl)) st.ctrl
      H.modify_ _ { ctrl = res.next }
      H.raise (CheckedChanged res.emit)
  -- Enter is preventDefaulted (it must NOT toggle the checkbox or submit an enclosing form);
  -- Space falls through to the native button click → Clicked.
  KeyDowned ke ->
    when (KE.key ke == "Enter") (liftEffect (preventDefault (KE.toEvent ke)))
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.checked st.ctrl
      , disabled = input.disabled
      , required = input.required
      , name = input.name
      , value = input.value
      , style = input.style
      , children = input.children
      , extraAttrs = input.extraAttrs
      }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetChecked v a -> do
    H.modify_ \st -> st { ctrl = (change v st.ctrl).next }
    pure (Just a)
  GetChecked reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
