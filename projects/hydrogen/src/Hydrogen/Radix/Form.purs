-- | Hydrogen.Radix.Form — accessible form fields with client-side validation
-- | (radix `Form`).
-- |
-- | A stateful component that takes the field set as Input DATA (the Tabs idiom:
-- | `fields :: Array Field`, like `tabs :: Array Tab`). Validity is tracked in State
-- | as a per-field set of FAILED matchers, fed by the native `invalid` event on each
-- | control (radix uses the NATIVE validity events, not React/Halogen onChange). The
-- | DOM is purely a function of that validity state: `data-invalid`, `aria-invalid`,
-- | and the conditionally-rendered `<span>` Messages (whose ids wire into the
-- | control's `aria-describedby`).
-- |
-- | UPSTREAM DOM CONTRACT (verified against the committed golden-dom oracles —
-- | form.{rest-valid,serverInvalid,forceMatch,valueMissing}). No portal, no Presence:
-- |   * Root → bare `<form>`.
-- |   * Field → `<div>` with `data-invalid="true"` ONLY when serverInvalid OR a
-- |     matcher has failed (ABSENT otherwise — never "false"). `data-valid` is only
-- |     emitted once validity has run AND passed; at rest (validity unknown) BOTH are
-- |     absent.
-- |   * Label → `<label for=<controlId>>` with the same `data-invalid` gating.
-- |   * Control → `<input id name required title="" type>` with `data-invalid` (same
-- |     gating), `aria-invalid="true"` ONLY when serverInvalid, and `aria-describedby`
-- |     = space-joined ids of the currently-mounted Messages (ABSENT when none).
-- |   * Message → `<span id=<msgId>>` rendered ONLY when its matcher failed OR
-- |     forceMatch; its id registers into the control's aria-describedby.
-- |   * Submit → `<button type="submit">`.
-- |
-- | CRITICAL: every conditional attribute is OMITTED (not ="false"/"") when its
-- | predicate is false — the Tabs `<> (if cond then […] else [])` idiom throughout.
module Hydrogen.Radix.Form
  ( component
  , Input
  , Field
  , Message
  , Matcher(..)
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  , defaultField
  ) where

import Prelude

import Data.Array (catMaybes, elem, filter, findIndex, mapWithIndex, null, (!!))
import Data.Array (filterA) as Array
import Data.Foldable (for_)
import Effect (Effect)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.String (joinWith)
import Data.Traversable (for)
import Data.Tuple (Tuple(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Radix.Behavior.Id (useId)
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes, dataAttr, aria)
import Web.Event.Event (EventType(..), preventDefault)
import Web.Event.Event as Event
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.HTMLInputElement as HTMLInputElement
import Web.HTML.ValidityState (ValidityState)
import Web.HTML.ValidityState as ValidityState

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | A built-in HTML validity matcher (subset; the deterministically oracle-able set).
data Matcher
  = ValueMissing
  | TypeMismatch
  | PatternMismatch
  | TooLong
  | TooShort
  | RangeOverflow
  | RangeUnderflow
  | StepMismatch
  | BadInput

derive instance eqMatcher :: Eq Matcher

-- | Whether the given declared matcher's HTML validity flag is currently set on the
-- | control (upstream reads validityStateToObject; this maps each modelled matcher to
-- | its `ValidityState` accessor). Returned in `Effect` since the flags are read live.
matcherFails :: ValidityState -> Matcher -> Effect Boolean
matcherFails vs = case _ of
  ValueMissing -> ValidityState.valueMissing vs
  TypeMismatch -> ValidityState.typeMismatch vs
  PatternMismatch -> ValidityState.patternMismatch vs
  TooLong -> ValidityState.tooLong vs
  TooShort -> ValidityState.tooShort vs
  RangeOverflow -> ValidityState.rangeOverflow vs
  RangeUnderflow -> ValidityState.rangeUnderflow vs
  StepMismatch -> ValidityState.stepMismatch vs
  BadInput -> ValidityState.badInput vs

type Message =
  { match :: Matcher
  , forceMatch :: Boolean   -- render unconditionally (registers aria-describedby on first paint)
  , customMatch :: Maybe (String -> Boolean)  -- a custom matcher predicate over the control value
                                              -- (FormCustomMessage); when set, `match` is ignored
                                              -- and the field is invalid via setCustomValidity.
  , text :: Array HH.PlainHTML
  }

type Field =
  { name :: String
  , label :: Array HH.PlainHTML
  , inputType :: String         -- the control's `type` (e.g. "email")
  , required :: Boolean
  , serverInvalid :: Boolean
  , messages :: Array Message
  }

defaultField :: Field
defaultField =
  { name: ""
  , label: []
  , inputType: "text"
  , required: false
  , serverInvalid: false
  , messages: []
  }

type Style =
  { root :: ClassNames
  , field :: ClassNames
  , label :: ClassNames
  , control :: ClassNames
  , message :: ClassNames
  , submit :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-form"
  , field: cn "rdx-form-field"
  , label: cn "rdx-form-label"
  , control: cn "rdx-form-control"
  , message: cn "rdx-form-message"
  , submit: cn "rdx-form-submit"
  }

type Input =
  { fields :: Array Field
  , submitLabel :: Array HH.PlainHTML
  -- Wave-D: when non-empty, render a `<button type=reset>` after Submit (the form-reset
  -- path clears each field's validity). Empty ⇒ no reset button (the default stories).
  , resetLabel :: Array HH.PlainHTML
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { fields: []
  , submitLabel: []
  , resetLabel: []
  , style: defaultStyle
  }

data Output = Submitted

data Query a = GetFailed (Map String (Array Matcher) -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { fields :: Array Field
  , submitLabel :: Array HH.PlainHTML
  , resetLabel :: Array HH.PlainHTML
  , style :: Style
  -- minted ids, keyed by field index
  , controlIds :: Map Int String
  , msgIds :: Map Int (Array String)       -- one id per message of field i
  , failed :: Map Int (Array Matcher)      -- currently-failing built-in matchers per field
  , customFails :: Map Int (Array Int)     -- message indices whose custom predicate failed, per field
  , validPassed :: Map Int Boolean         -- field i has run validation AND passed (validity.valid===true)
  }

data Action
  = Initialize
  | Receive Input
  | ControlInvalid Int
  | ControlInput Int          -- native input clears the field's failed set (radix re-validates)
  | ControlChange Int         -- native `change` re-reads validity (radix's revalidate trigger)
  | FormSubmit Event.Event
  -- Wave-D: form reset clears every field's failed-matcher set + validated-valid record
  -- (radix: each control listens for the form `reset` and clears its validity/customValidity,
  -- so the Messages unmount and aria-describedby is dropped). The native reset clears the
  -- input VALUES; this clears the derived validity state the Messages render off.
  | FormReset

controlRef :: Int -> H.RefLabel
controlRef i = H.RefLabel ("form-control-" <> show i)

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
  { fields: input.fields
  , submitLabel: input.submitLabel
  , resetLabel: input.resetLabel
  , style: input.style
  , controlIds: Map.empty
  , msgIds: Map.empty
  , failed: Map.empty
  , customFails: Map.empty
  , validPassed: Map.empty
  }

-- | Failed matchers for field index `i`.
failedOf :: State -> Int -> Array Matcher
failedOf st i = fromMaybe [] (Map.lookup i st.failed)

-- | The lowest field index that is currently invalid (serverInvalid or a failed matcher) — the
-- | "first invalid control" focused on a blocked submit (form.tsx getFirstInvalidControl).
firstInvalidIndex :: State -> Maybe Int
firstInvalidIndex st = findIndex identity (mapWithIndex (\i f -> fieldInvalid st i f) st.fields)

-- | The built-in matchers declared by field `f` (custom-matcher messages excluded — their
-- | `match` is ignored; they validate via their predicate, not ValidityState).
builtinMatchers :: Field -> Array Matcher
builtinMatchers f = map _.match (filter (isNothing <<< _.customMatch) f.messages)

-- | Message indices whose CUSTOM predicate currently fails for field `i`.
customFailsOf :: State -> Int -> Array Int
customFailsOf st i = fromMaybe [] (Map.lookup i st.customFails)

-- | Does field `i` count as invalid? (serverInvalid OR a failed built-in OR a failed custom matcher.)
fieldInvalid :: State -> Int -> Field -> Boolean
fieldInvalid st i f = f.serverInvalid || not (null (failedOf st i)) || not (null (customFailsOf st i))

-- | The Messages of field `i` that should currently render (forceMatch OR matched),
-- | paired with their minted id.
visibleMessages :: State -> Int -> Field -> Array { id :: String, text :: Array HH.PlainHTML }
visibleMessages st i f =
  let
    fails = failedOf st i
    cfails = customFailsOf st i
    ids = fromMaybe [] (Map.lookup i st.msgIds)
  in
    filter (\m -> m.id /= "")
      ( mapWithIndex
          ( \j m ->
              if m.forceMatch
                || (if isJust m.customMatch then j `elem` cfails else m.match `elem` fails)
                -- a Message with NO children falls back to the default built-in message text
                -- for its matcher (radix DEFAULT_BUILT_IN_MESSAGES).
                then { id: fromMaybe "" (ids !! j), text: if null m.text then [ HH.text (defaultBuiltInMessage m.match) ] else m.text }
                else { id: "", text: [] }
          )
          f.messages
      )

-- | radix DEFAULT_BUILT_IN_MESSAGES — the fallback text a Message with no children renders.
defaultBuiltInMessage :: Matcher -> String
defaultBuiltInMessage = case _ of
  ValueMissing -> "This value is missing"
  TypeMismatch -> "This value does not match the required type"
  PatternMismatch -> "This value does not match the required pattern"
  TooLong -> "This value is too long"
  TooShort -> "This value is too short"
  RangeOverflow -> "This value is too large"
  RangeUnderflow -> "This value is too small"
  StepMismatch -> "This value does not match the required step"
  BadInput -> "This value is not valid"

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.form
    [ classes st.style.root
    , HE.onSubmit FormSubmit
    , HE.onReset (const FormReset)
    ]
    ( mapWithIndex (renderField st) st.fields
        <> [ renderSubmit st ]
        <> (if null st.resetLabel then [] else [ renderReset st ])
    )

renderField :: forall m. State -> Int -> Field -> H.ComponentHTML Action () m
renderField st i f =
  let
    invalid = fieldInvalid st i f
    -- data-valid="true" iff validation has RUN and passed (validity.valid===true) AND the field
    -- is not serverInvalid (radix getValidAttribute). Absent until validation runs.
    valid = fromMaybe false (Map.lookup i st.validPassed) && not f.serverInvalid
    cid = fromMaybe "" (Map.lookup i st.controlIds)
    msgs = visibleMessages st i f
    describedBy = joinWith " " (map _.id msgs)
    invalidAttr :: forall r. Array (HH.IProp r Action)
    invalidAttr = if invalid then [ dataAttr "invalid" "true" ] else []
    validAttr :: forall r. Array (HH.IProp r Action)
    validAttr = if valid then [ dataAttr "valid" "true" ] else []
  in
    HH.div
      ( [ classes st.style.field ] <> validAttr <> invalidAttr )
      ( [ HH.label
            ( [ classes st.style.label
              , HP.attr (HH.AttrName "for") cid
              ] <> validAttr <> invalidAttr
            )
            (map HH.fromPlainHTML f.label)
        , HH.input
            ( [ HP.ref (controlRef i)
              , HP.attr (HH.AttrName "type") f.inputType
              , HP.id cid
              , HP.name f.name
              , HP.attr (HH.AttrName "title") ""
              , classes st.style.control
              , HE.onInput \_ -> ControlInput i
              , HE.onChange \_ -> ControlChange i
              ]
                <> (if f.required then [ HP.attr (HH.AttrName "required") "" ] else [])
                <> validAttr
                <> invalidAttr
                <> (if f.serverInvalid then [ aria "invalid" "true" ] else [])
                <> (if describedBy /= "" then [ aria "describedby" describedBy ] else [])
            )
        ]
          <> map (renderMessage st) msgs
      )

renderMessage :: forall m. State -> { id :: String, text :: Array HH.PlainHTML } -> H.ComponentHTML Action () m
renderMessage st m =
  HH.span
    [ classes st.style.message
    , HP.id m.id
    ]
    (map HH.fromPlainHTML m.text)

renderSubmit :: forall m. State -> H.ComponentHTML Action () m
renderSubmit st =
  HH.button
    [ HP.type_ HP.ButtonSubmit
    , classes st.style.submit
    ]
    (map HH.fromPlainHTML st.submitLabel)

-- | A native `<button type=reset>`; clicking it fires the form's reset event (handled by
-- | FormReset, which clears every field's derived validity). Rendered only when resetLabel
-- | is non-empty.
renderReset :: forall m. State -> H.ComponentHTML Action () m
renderReset st =
  HH.button
    [ HP.type_ HP.ButtonReset ]
    (map HH.fromPlainHTML st.resetLabel)

-- | Run the field's CUSTOM matcher predicates against the live control value: collect the failing
-- | message indices, mirror them onto the native control via setCustomValidity (so submit blocks
-- | and `data-invalid` stamps), and record them in `customFails` (FormCustomMessage validation).
evalCustomFor :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
evalCustomFor i = do
  st <- H.get
  for_ (st.fields !! i) \f -> do
    mel <- H.getHTMLElementRef (controlRef i)
    for_ (mel >>= HTMLInputElement.fromHTMLElement) \inp -> do
      v <- liftEffect (HTMLInputElement.value inp)
      let
        cfails = catMaybes (mapWithIndex (\j m -> case m.customMatch of
                     Just p | p v -> Just j
                     _ -> Nothing) f.messages)
      liftEffect (HTMLInputElement.setCustomValidity (if null cfails then "" else "invalid") inp)
      H.modify_ \s -> s { customFails = if null cfails then Map.delete i s.customFails else Map.insert i cfails s.customFails }

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    st <- H.get
    -- mint a stable id per control + per message (deterministic, normalizer-canonicalized).
    cids <- for (mapWithIndex (\i f -> { i, f }) st.fields) \{ i } -> do
      cid <- useId
      pure { i, cid }
    mids <- for (mapWithIndex (\i f -> { i, f }) st.fields) \{ i, f } -> do
      ids <- for f.messages \_ -> useId
      pure { i, ids }
    H.modify_ _
      { controlIds = Map.fromFoldable (map (\r -> Tuple r.i r.cid) cids)
      , msgIds = Map.fromFoldable (map (\r -> Tuple r.i r.ids) mids)
      }
    -- bind the native `invalid` event on each control (Submit → native validation →
    -- `invalid` fires on a required-empty/typeMismatch control; radix uses the NATIVE
    -- validity event, not Halogen onChange which is the `input` event).
    st' <- H.get
    for_ (mapWithIndex (\i f -> { i, f }) st'.fields) \{ i } -> do
      mel <- H.getHTMLElementRef (controlRef i)
      for_ mel \el -> do
        let target = HTMLElement.toEventTarget el
        void $ H.subscribe (eventListener (EventType "invalid") target (\_ -> Just (ControlInvalid i)))
        -- radix revalidates on the native `change` (NOT input): re-read validity so an
        -- invalid→valid recovery stamps data-valid and clears the failed set.
        void $ H.subscribe (eventListener (EventType "change") target (\_ -> Just (ControlChange i)))
    -- serverInvalid fields focus their control on mount (form.tsx:382-390 useEffect). Focus the
    -- FIRST serverInvalid control, if any.
    for_ (findIndex _.serverInvalid st'.fields) \i -> do
      mel <- H.getHTMLElementRef (controlRef i)
      for_ mel (liftEffect <<< HTMLElement.focus)
  Receive input ->
    H.modify_ \st -> st
      { fields = input.fields
      , submitLabel = input.submitLabel
      , resetLabel = input.resetLabel
      , style = input.style
      }
  ControlInvalid i -> do
    st <- H.get
    -- the native `invalid` event fired — read the control's LIVE ValidityState and keep
    -- the field's declared matchers whose flag is set (upstream form.tsx:290-352 reads the
    -- full validityStateToObject, not just valueMissing) — so e.g. a typeMismatch on the
    -- email control mounts its TypeMismatch Message too.
    fails <- case st.fields !! i of
      Nothing -> pure []
      Just f -> do
        mel <- H.getHTMLElementRef (controlRef i)
        case mel >>= HTMLInputElement.fromHTMLElement of
          Nothing -> pure (filter (\m -> m == ValueMissing) (builtinMatchers f))
          Just input -> liftEffect do
            vs <- HTMLInputElement.validity input
            Array.filterA (\m -> matcherFails vs m) (builtinMatchers f)
    -- a failed control is no longer "validated valid".
    H.modify_ _ { failed = Map.insert i fails st.failed, validPassed = Map.delete i st.validPassed }
  ControlInput i -> do
    -- typing clears the field's failed set (radix re-validates on input). It does NOT stamp
    -- data-valid — that is the `change`-driven path (validity recorded on change, not input).
    H.modify_ \st -> st { failed = Map.delete i st.failed, validPassed = Map.delete i st.validPassed }
    evalCustomFor i
  ControlChange i -> do
    -- the native `change` fired — re-read the control's LIVE ValidityState (radix
    -- updateControlValidity). If valid, record validPassed (→ data-valid) + clear failed;
    -- if invalid, recompute the failed matcher set off the live flags.
    st <- H.get
    case st.fields !! i of
      Nothing -> pure unit
      Just f -> do
        mel <- H.getHTMLElementRef (controlRef i)
        case mel >>= HTMLInputElement.fromHTMLElement of
          Nothing -> pure unit
          Just input -> do
            vs <- liftEffect (HTMLInputElement.validity input)
            isValid <- liftEffect (ValidityState.valid vs)
            if isValid then
              H.modify_ \s -> s
                { validPassed = Map.insert i true s.validPassed
                , failed = Map.delete i s.failed
                }
            else do
              fails <- liftEffect (Array.filterA (\m -> matcherFails vs m) (builtinMatchers f))
              H.modify_ \s -> s
                { validPassed = Map.delete i s.validPassed
                , failed = Map.insert i fails s.failed
                }
    evalCustomFor i
  FormSubmit ev -> do
    -- prevent the native navigation; if all controls are valid, raise Submitted. The
    -- native `invalid` events (bound above) fire BEFORE submit for invalid controls.
    liftEffect (preventDefault ev)
    st <- H.get
    -- a field is invalid via a built-in matcher, a custom matcher, OR serverInvalid (firstInvalidIndex).
    case firstInvalidIndex st of
      Nothing -> H.raise Submitted
      -- onInvalid focuses the FIRST invalid control (form.tsx:167-173 getFirstInvalidControl).
      Just i -> do
        mel <- H.getHTMLElementRef (controlRef i)
        for_ mel (liftEffect <<< HTMLElement.focus)
  FormReset ->
    -- clear all derived validity (failed matchers + validated-valid). The Messages unmount
    -- and aria-describedby is dropped, returning the form to its pristine rest-valid DOM.
    H.modify_ _ { failed = Map.empty, customFails = Map.empty, validPassed = Map.empty }

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  GetFailed reply -> do
    st <- H.get
    let byName = Map.fromFoldable (mapWithIndex (\i f -> Tuple f.name (failedOf st i)) st.fields)
    pure (Just (reply byName))
