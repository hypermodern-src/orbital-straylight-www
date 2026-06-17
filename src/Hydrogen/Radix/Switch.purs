-- | Hydrogen.Radix.Switch — a toggle switch (radix `Switch`).
-- |
-- | A two-state form control: a `button[role="switch"]` whose `aria-checked` /
-- | `data-state` ("checked"/"unchecked") track a controllable Boolean, plus a
-- | child `span` "thumb" part that carries the same `data-state` for CSS to slide.
-- |
-- | Structurally identical to `Toggle` (the canonical stateful template) — same
-- | `Behavior.ControllableState` controlled/uncontrolled core, same `Receive`
-- | refresh, same Set/Get `Query` + change `Output` — but with switch semantics:
-- |   * `checked` (controlled) / `defaultChecked` (uncontrolled) instead of pressed;
-- |   * a two-part `Style` (`root` button + `thumb` span);
-- |   * form-control props (`required`, `name`, `value`) emitted as ARIA/state.
-- |
-- | NOTE (v1): the hidden bubble `<input>` radix renders to participate in native
-- | form submission/`formData` is intentionally omitted. `name`/`value`/`required`
-- | are surfaced (as `data-*` / `aria-required`) but form submission without JS is
-- | not yet wired; add a `VisuallyHidden` checkbox input when form integration lands.
module Hydrogen.Radix.Switch
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

-- | Per-part class lists. Switch has two parts: the `root` button and the
-- | `thumb` span that slides between the two ends.
type Style = { root :: ClassNames, thumb :: ClassNames }

-- | Semantic default — a preset (orbital/daisy/…) supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-switch"
  , thumb: cn "rdx-switch-thumb"
  }

type Input =
  { checked :: Maybe Boolean        -- controlled checked state (Nothing = uncontrolled)
  , defaultChecked :: Boolean       -- initial state when uncontrolled
  , disabled :: Boolean
  , required :: Boolean
  , name :: String
  , value :: String                 -- form value when checked (default "on")
  , style :: Style
  , children :: Array HH.PlainHTML   -- static content rendered inside the root
  }

defaultInput :: Input
defaultInput =
  { checked: Nothing
  , defaultChecked: false
  , disabled: false
  , required: false
  , name: ""
  , value: "on"
  , style: defaultStyle
  , children: []
  }

-- | Emitted whenever the user requests a change — including in controlled mode,
-- | where the parent is expected to update `checked` in response.
data Output = CheckedChanged Boolean

-- | External control.
data Query a
  = SetChecked Boolean a
  | GetChecked (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
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

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    checked = current st.ctrl
    stateName = if checked then "checked" else "unchecked"
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , ARIA.role "switch"
        , ARIA.checked (if checked then "true" else "false")
        , dataState stateName
        , HP.value st.value
        , HP.disabled st.disabled
        , classes st.style.root
        , HE.onClick \_ -> Clicked
        ]
          <> (if st.required then [ ARIA.required "true" ] else [])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
      )
      ( [ HH.span
            ( [ dataState stateName
              , classes st.style.thumb
              ]
                <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
            )
            []
        ]
          <> map HH.fromPlainHTML st.children
      )

handleAction :: forall m. Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Clicked -> do
    st <- H.get
    when (not st.disabled) do
      let res = change (not (current st.ctrl)) st.ctrl
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
