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
-- | ("checked"/"unchecked"/"indeterminate"), `data-disabled`, and `disabled`,
-- | plus the `style.root` classes. The indicator part (the check/dash) renders
-- | as a `<span>` inside the button only when Checked or Indeterminate, carrying
-- | its own `data-state` + `style.indicator` classes.
-- |
-- | NOTE: radix also renders a hidden bubble `<input type="checkbox">` so the
-- | control participates in native form submission/validation. That requires
-- | DOM-ref plumbing (size mirroring, event bubbling) we deliberately skip in
-- | v1; this is a controlled/ARIA checkbox only, not yet a native form control.
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
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as ARIA
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, sync)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataState, dataAttr)

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
  , children :: Array HH.PlainHTML   -- static indicator content (check/dash icon)
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
  }

data Action
  = Clicked
  | Receive Input

component :: forall m. H.Component Query Input Output m
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
        , ARIA.checked (ariaCheckedName checked)
        , dataState (stateName checked)
        , HP.disabled st.disabled
        , classes st.style.root
        , HE.onClick \_ -> Clicked
        ]
          <> (if st.required then [ ARIA.required "true" ] else [])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
      )
      ( if showIndicator then
          [ HH.span
              [ dataState (stateName checked)
              , classes st.style.indicator
              ]
              (map HH.fromPlainHTML st.children)
          ]
        else
          []
      )

handleAction :: forall m. Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Clicked -> do
    st <- H.get
    when (not st.disabled) do
      let res = change (toggleChecked (current st.ctrl)) st.ctrl
      H.modify_ _ { ctrl = res.next }
      H.raise (CheckedChanged res.emit)
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.checked st.ctrl
      , disabled = input.disabled
      , required = input.required
      , name = input.name
      , value = input.value
      , style = input.style
      , children = input.children
      }

handleQuery :: forall m a. Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetChecked v a -> do
    H.modify_ \st -> st { ctrl = (change v st.ctrl).next }
    pure (Just a)
  GetChecked reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
