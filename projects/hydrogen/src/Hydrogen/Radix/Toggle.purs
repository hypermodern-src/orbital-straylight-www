-- | Hydrogen.Radix.Toggle — a two-state button (radix `Toggle`).
-- |
-- | THE TEMPLATE for a stateful primitive port. It demonstrates, end-to-end, the
-- | idiom every interactive radix primitive follows in Halogen:
-- |
-- |   * a Halogen component with a `Slot`/`Query`/`Output` surface;
-- |   * controlled OR uncontrolled state via `Behavior.ControllableState`
-- |     (`pressed` controlled prop, `defaultPressed` uncontrolled initial);
-- |   * the controlled prop refreshed from input on `receive`;
-- |   * the stable behavioral surface CSS targets — `aria-pressed` + `data-state`
-- |     ("on"/"off") + `data-disabled` — emitted alongside per-part classes from
-- |     the component's `Style` record (`Style.classes style.root`);
-- |   * static children passed as `Array HH.PlainHTML` (the common case: a label
-- |     or icon). Interactive nested content would use slots; toggles don't need it.
-- |   * a `defaultStyle` of semantic class names; presets supply alternatives.
module Hydrogen.Radix.Toggle
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

-- | Per-part class lists. Toggle is single-part (the button root).
type Style = { root :: ClassNames }

-- | Semantic default — a preset (orbital/daisy/…) supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle = { root: cn "rdx-toggle" }

type Input =
  { pressed :: Maybe Boolean       -- controlled pressed state (Nothing = uncontrolled)
  , defaultPressed :: Boolean      -- initial state when uncontrolled
  , disabled :: Boolean
  , ariaLabel :: Maybe String      -- accessible label (radix `aria-label`); omitted when Nothing
  , style :: Style
  , children :: Array HH.PlainHTML  -- static label/icon content
  }

defaultInput :: Input
defaultInput =
  { pressed: Nothing
  , defaultPressed: false
  , disabled: false
  , ariaLabel: Nothing
  , style: defaultStyle
  , children: []
  }

-- | Emitted whenever the user requests a change — including in controlled mode,
-- | where the parent is expected to update `pressed` in response.
data Output = PressedChanged Boolean

-- | External control.
data Query a
  = SetPressed Boolean a
  | GetPressed (Boolean -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { ctrl :: Controllable Boolean
  , disabled :: Boolean
  , ariaLabel :: Maybe String
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
  { ctrl: controllable input.pressed input.defaultPressed
  , disabled: input.disabled
  , ariaLabel: input.ariaLabel
  , style: input.style
  , children: input.children
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  let
    on = current st.ctrl
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , ARIA.pressed (show on)
        , dataState (if on then "on" else "off")
        , HP.disabled st.disabled
        , classes st.style.root
        , HE.onClick \_ -> Clicked
        ]
          <> (case st.ariaLabel of
                Just l -> [ ARIA.label l ]
                Nothing -> [])
          <> (if st.disabled then [ dataAttr "disabled" "" ] else [])
      )
      (map HH.fromPlainHTML st.children)

handleAction :: forall m. Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Clicked -> do
    st <- H.get
    when (not st.disabled) do
      let res = change (not (current st.ctrl)) st.ctrl
      H.modify_ _ { ctrl = res.next }
      H.raise (PressedChanged res.emit)
  Receive input ->
    H.modify_ \st -> st
      { ctrl = sync input.pressed st.ctrl
      , disabled = input.disabled
      , ariaLabel = input.ariaLabel
      , style = input.style
      , children = input.children
      }

handleQuery :: forall m a. Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetPressed v a -> do
    H.modify_ \st -> st { ctrl = (change v st.ctrl).next }
    pure (Just a)
  GetPressed reply -> do
    st <- H.get
    pure (Just (reply (current st.ctrl)))
