-- | Hydrogen.Radix.OneTimePasswordField — N single-char inputs with roving focus,
-- | auto-advance, and a hidden aggregate input (radix `OneTimePasswordField`).
-- |
-- | A RovingFocus consumer (like Tabs/RadioGroup) that owns an aggregate value as a
-- | per-slot char array via `Behavior.ControllableState`. Typing a valid char fills
-- | the focused slot and auto-advances focus; Backspace/arrows/Home/End move the
-- | cursor; a hidden `<input type=hidden>` carries `value.join("").trim()` for form
-- | submission. The char-mutation logic is kept pure (the `sanitize`/reducer helpers
-- | below); the HalogenM handler only calls the reducer, writes via ControllableState,
-- | focuses the target ref, and raises the value.
-- |
-- | UPSTREAM DOM CONTRACT (verified against the committed golden-dom oracles —
-- | otp.{filled,empty,typed}). No portal, no Presence, no minted ids:
-- |   * Root  → `<div role="group" data-orientation style="outline: none;" tabindex>`.
-- |     tabindex=0 at rest (a focusable group); items -1 until focus enters.
-- |   * Each slot → `<input type aria-label="Character {i+1} of {n}" value=char
-- |     inputmode pattern data-radix-otp-input data-radix-index={i} tabindex
-- |     data-orientation maxlength autocomplete …>`. The SINGLE "autocomplete input"
-- |     (autocomplete="one-time-code", maxlength={n}, and NO password-manager-ignore
-- |     attrs) is index 0 BEFORE focus enters, else the current roving tab stop; every
-- |     OTHER slot carries autocomplete="off", maxlength=1, and the four ignore attrs
-- |     (data-1p-ignore / data-bwignore / data-lpignore / data-protonpass-ignore).
-- |   * Hidden → `<input type="hidden" readonly value=(join) autocomplete=off
-- |     autocapitalize=off autocorrect=off autosave=off spellcheck=false>` (+ name).
module Hydrogen.Radix.OneTimePasswordField
  ( component
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , Validation(..)
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (deleteAt, length, mapWithIndex, replicate, take, updateAt, filter, (!!))
import Data.Ord (clamp)
import Data.Foldable (for_)
import Data.FoldableWithIndex (forWithIndex_)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (joinWith, trim)
import Data.String.CodeUnits (toCharArray)
import Data.String.CodeUnits as SCU
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Radix.Behavior.ControllableState (Controllable, controllable, current, change, isControlled, sync)
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Foundation.Dom (requestSubmit)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataOrientation, dataAttr, orientationName, role)
import Web.Event.Event (EventType(..), preventDefault)
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.HTMLFormElement as HTMLFormElement
import Web.HTML.HTMLInputElement as HTMLInputElement
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | The slot validation set: which chars are accepted + the emitted inputmode/pattern.
data Validation = Numeric | Alpha | Alphanumeric | NoValidation

derive instance eqValidation :: Eq Validation

type Style = { root :: ClassNames, input :: ClassNames }

defaultStyle :: Style
defaultStyle = { root: cn "rdx-otp", input: cn "rdx-otp-input" }

type Input =
  { length :: Int
  , value :: Maybe String          -- controlled aggregate value (Nothing = uncontrolled)
  , defaultValue :: String         -- initial aggregate value when uncontrolled
  , validation :: Validation
  , orientation :: Orientation
  , dir :: Dir
  , name :: Maybe String           -- hidden input's form name
  , password :: Boolean            -- type=password masks every slot input
  , disabled :: Boolean            -- disables every slot + drops them from the roving order
  , readOnly :: Boolean            -- stamps readonly on every slot input
  , autoSubmit :: Boolean          -- when all slots fill, raise AutoSubmitted + form.requestSubmit
  , autoFocus :: Boolean           -- focus the first fillable slot on mount
  , placeholder :: Maybe String    -- per-slot placeholder char (shown when the slot is empty)
  , sanitize :: String -> String   -- custom sanitizer, applied only when validation = NoValidation
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { length: 6
  , value: Nothing
  , defaultValue: ""
  , validation: Numeric
  , orientation: Horizontal
  , dir: LTR
  , name: Nothing
  , password: false
  , disabled: false
  , readOnly: false
  , autoSubmit: false
  , autoFocus: false
  , placeholder: Nothing
  , sanitize: identity
  , style: defaultStyle
  }

-- | `ValueChanged` on every value mutation; `AutoSubmitted` fires (before requestSubmit) once
-- | every slot is filled while `autoSubmit` is set — upstream's onAutoSubmit callback.
data Output = ValueChanged String | AutoSubmitted String

data Query a
  = SetValue String a
  | GetValue (String -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { len :: Int
  , chars :: Controllable (Array String)   -- per-slot chars, normalized to `len`
  , validation :: Validation
  , orientation :: Orientation
  , dir :: Dir
  , name :: Maybe String
  , password :: Boolean
  , disabled :: Boolean
  , readOnly :: Boolean
  , autoSubmit :: Boolean
  , autoFocus :: Boolean
  , placeholder :: Maybe String
  , sanitize :: String -> String
  , style :: Style
  , cursor :: Int          -- roving cursor over the slots
  , focusEntered :: Boolean -- false ⇒ all slots -1 (root holds the tab stop), autocomplete on slot 0
  }

data Action
  = Initialize
  | Receive Input
  | SlotInput Int String
  | SlotKeyDown Int KE.KeyboardEvent
  | SlotFocused Int
  | FormReset

slotRef :: Int -> H.RefLabel
slotRef i = H.RefLabel ("otp-slot-" <> show i)

hiddenRef :: H.RefLabel
hiddenRef = H.RefLabel "otp-hidden"

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

-- | Normalize an aggregate string to exactly `len` per-slot chars.
toSlots :: Int -> String -> Array String
toSlots len s =
  let cs = map SCU.singleton (toCharArray s)
  in take len (cs <> replicate len "")

-- | Normalize an aggregate string to `len` per-slot chars, sanitized by the validation set
-- | (upstream `sanitizeValue`: strip whitespace + drop rejected chars). Applied to the initial
-- | controlled value AND defaultValue, mirroring upstream's `sanitizeValue(valueProp/defaultValue)`.
sanitizedSlots :: Validation -> (String -> String) -> Int -> String -> Array String
sanitizedSlots v customF len s = toSlots len (sanitizePaste v customF s)

initialState :: Input -> State
initialState input =
  { len: input.length
  , chars: controllable (map (sanitizedSlots input.validation input.sanitize input.length) input.value) (sanitizedSlots input.validation input.sanitize input.length input.defaultValue)
  , validation: input.validation
  , orientation: input.orientation
  , dir: input.dir
  , name: input.name
  , password: input.password
  , disabled: input.disabled
  , readOnly: input.readOnly
  , autoSubmit: input.autoSubmit
  , autoFocus: input.autoFocus
  , placeholder: input.placeholder
  , sanitize: input.sanitize
  , style: input.style
  , cursor: 0
  , focusEntered: false
  }

-- | The slot that owns the autocomplete affordance: index 0 before focus enters,
-- | else the current roving tab stop (upstream `supportsAutoComplete`).
autoCompleteIndex :: State -> Int
autoCompleteIndex st = if st.focusEntered then st.cursor else 0

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    [ role "group"
    , dataOrientation st.orientation
    , HP.style "outline: none;"
    -- RovingFocusGroup root tab stop: tabindex=0 while there is a focusable item; when the
    -- field is disabled EVERY slot is non-focusable, so the group itself drops to tabindex=-1.
    , HP.tabIndex (if st.disabled then (-1) else 0)
    , classes st.style.root
    ]
    ( mapWithIndex (renderSlot st) (current st.chars)
        <> [ renderHidden st ]
    )

renderSlot :: forall m. State -> Int -> String -> H.ComponentHTML Action () m
renderSlot st idx ch =
  let
    acIdx = autoCompleteIndex st
    isAuto = idx == acIdx
    -- A disabled field drops EVERY slot from the roving order (radix focusable=!disabled), so
    -- no slot is the tab stop and all carry tabindex=-1; the group root keeps its tabindex=0.
    tab =
      if st.disabled then (-1)
      else if st.focusEntered then tabIndexFor st.cursor idx
      else (-1)
  in
    HH.input
      ( [ HP.type_ (if st.password then HP.InputPassword else HP.InputText)
        , HP.ref (slotRef idx)
        , HP.attr (HH.AttrName "aria-label") ("Character " <> show (idx + 1) <> " of " <> show st.len)
        , HP.attr (HH.AttrName "value") ch
        , HP.attr (HH.AttrName "maxlength") (show (if isAuto then st.len else 1))
        , HP.attr (HH.AttrName "autocomplete") (if isAuto then "one-time-code" else "off")
        , dataOrientation st.orientation
        , dataAttr "radix-collection-item" ""
        , dataAttr "radix-otp-input" ""
        , dataAttr "radix-index" (show idx)
        , HP.tabIndex tab
        , classes st.style.input
        , HE.onValueInput (SlotInput idx)
        , HE.onKeyDown (SlotKeyDown idx)
        , HE.onFocus (const (SlotFocused idx))
        ]
          <> validationAttrs st.validation
          -- Upstream stamps placeholder only on the autocomplete slot (the one that also carries
          -- autocomplete=one-time-code), not every slot — verified against the golden.
          <> (case st.placeholder of
                Just ph | isAuto -> [ HP.attr (HH.AttrName "placeholder") ph ]
                _ -> [])
          <> (if st.disabled then [ HP.attr (HH.AttrName "disabled") "" ] else [])
          <> (if st.readOnly then [ HP.attr (HH.AttrName "readonly") "" ] else [])
          <> (if isAuto then [] else passwordManagerIgnore)
      )

-- | inputmode + pattern for the slot validation set (absent for NoValidation).
validationAttrs :: forall r i. Validation -> Array (HH.IProp r i)
validationAttrs = case _ of
  Numeric -> [ HP.attr (HH.AttrName "inputmode") "numeric", HP.attr (HH.AttrName "pattern") "\\d{1}" ]
  Alpha -> [ HP.attr (HH.AttrName "inputmode") "text", HP.attr (HH.AttrName "pattern") "[a-zA-Z]{1}" ]
  Alphanumeric -> [ HP.attr (HH.AttrName "inputmode") "text", HP.attr (HH.AttrName "pattern") "[a-zA-Z0-9]{1}" ]
  NoValidation -> []

-- | The four password-manager-ignore attrs upstream stamps on every NON-autocomplete slot.
passwordManagerIgnore :: forall r i. Array (HH.IProp r i)
passwordManagerIgnore =
  [ dataAttr "1p-ignore" "true"
  , dataAttr "lpignore" "true"
  , dataAttr "protonpass-ignore" "true"
  , dataAttr "bwignore" "true"
  ]

renderHidden :: forall m. State -> H.ComponentHTML Action () m
renderHidden st =
  HH.input
    ( [ HP.type_ HP.InputHidden
      , HP.ref hiddenRef
      , HP.attr (HH.AttrName "readonly") ""
      , HP.value (aggregate st)
      , HP.attr (HH.AttrName "autocomplete") "off"
      , HP.attr (HH.AttrName "autocapitalize") "off"
      , HP.attr (HH.AttrName "autocorrect") "off"
      , HP.attr (HH.AttrName "autosave") "off"
      , HP.attr (HH.AttrName "spellcheck") "false"
      ]
        <> (case st.name of
              Just n -> [ HP.name n ]
              Nothing -> [])
    )

aggregate :: State -> String
aggregate st = trim (joinWith "" (current st.chars))

-- | Whether a char is accepted by the validation set.
accepts :: Validation -> String -> Boolean
accepts v s = case v of
  NoValidation -> true
  _ -> case SCU.uncons s of
    Nothing -> false
    Just { head: c } -> case v of
      Numeric -> c >= '0' && c <= '9'
      Alpha -> isAlpha c
      Alphanumeric -> isAlpha c || (c >= '0' && c <= '9')
      NoValidation -> true
  where
  isAlpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

-- | Locate the enclosing <form> off the hidden aggregate input (its `.form` property) and run
-- | `k` with it. Mirrors upstream `locateForm` (hidden-input branch). No form ⇒ no-op, so the
-- | bare/labelled stories without a form are unaffected.
withForm
  :: forall m
   . MonadEffect m
  => (HTMLFormElement.HTMLFormElement -> H.HalogenM State Action () Output m Unit)
  -> H.HalogenM State Action () Output m Unit
withForm k = do
  mel <- H.getHTMLElementRef hiddenRef
  for_ (mel >>= HTMLInputElement.fromHTMLElement) \inp -> do
    mform <- liftEffect (HTMLInputElement.form inp)
    for_ mform k

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    -- Subscribe to the enclosing form's `reset` so the field clears with the form (upstream
    -- form.addEventListener('reset', …) → dispatch CLEAR). No form ⇒ no subscription.
    withForm \form -> do
      let target = HTMLFormElement.toEventTarget form
      void $ H.subscribe (eventListener (EventType "reset") target \_ -> Just FormReset)
    -- NOTE: `autoFocus` is accepted but inert, matching the oracle — @radix-ui/themes does NOT
    -- forward autoFocus to the slot inputs (verified: golden mounts with focus on <body>, no
    -- autofocus attr). The primitives package focuses the first input, but the themed face we tie
    -- out against drops it, so the port drops it too (no mount focus).
    pure unit
  FormReset -> do
    -- CLEAR: empty every slot, return the cursor to slot 0, and focus it (otp.tsx:419-426).
    st <- H.get
    let cleared = replicate st.len ""
    H.modify_ \s -> s { chars = (change cleared s.chars).next, cursor = 0, focusEntered = false }
    H.raise (ValueChanged "")
    syncSlotValues cleared
  Receive input ->
    H.modify_ \st ->
      let
        synced = sync (map (sanitizedSlots input.validation input.sanitize input.length) input.value) st.chars
        -- re-validate when the validation type changes (otp.tsx:379-389): re-sanitize the current
        -- uncontrolled value under the new set, dropping chars it now rejects.
        revalidated =
          if input.validation /= st.validation
            then synced { uncontrolled = sanitizedSlots input.validation input.sanitize input.length (joinWith "" synced.uncontrolled) }
            else synced
      in st
      { len = input.length
      , chars = revalidated
      , validation = input.validation
      , orientation = input.orientation
      , dir = input.dir
      , name = input.name
      , password = input.password
      , disabled = input.disabled
      , readOnly = input.readOnly
      , autoSubmit = input.autoSubmit
      , placeholder = input.placeholder
      , sanitize = input.sanitize
      , style = input.style
      }
  SlotFocused idx -> do
    st <- H.get
    -- onPointerDown clamps focus to min(index, lastSelectableIndex) (otp.tsx:886-891): focusing an
    -- unreachable slot (past the filled prefix) bounces to the last selectable slot instead.
    let lastSelectable = clamp 0 (st.len - 1) (SCU.length (aggregate st))
    if idx > lastSelectable then do
      H.modify_ _ { cursor = lastSelectable, focusEntered = true }
      focusAt lastSelectable
    else do
      H.modify_ _ { cursor = idx, focusEntered = true }
      -- onFocus selects the slot's current value so the next keystroke REPLACES it (otp.tsx:670-672).
      mel <- H.getHTMLElementRef (slotRef idx)
      for_ (mel >>= HTMLInputElement.fromHTMLElement) (liftEffect <<< HTMLInputElement.select)
  SlotInput idx raw -> do
    st <- H.get
    -- An input event delivering MORE THAN ONE char is a paste / password-manager autofill
    -- (radix onInput: `value.length > 1` ⇒ dispatch PASTE). The PASTE reducer sanitizes the
    -- whole pasted string (strip whitespace + chars the validation set rejects), slices it to
    -- the slot count, REPLACES the value from index 0, and focuses the last filled slot. This
    -- runs regardless of WHICH slot received the dump (radix sets value3 directly, not offset).
    if (not st.disabled && not st.readOnly && length (toCharArray raw) > 1) then do
      let
        sanitized = sanitizePaste st.validation st.sanitize raw
        next = toSlots st.len sanitized
        filled = length (filter (_ /= "") next)
        focusIdx = clampIdx st.len (filled - 1)
      when (sanitized /= "") do
        H.modify_ \s -> s { chars = (change next s.chars).next, cursor = focusIdx, focusEntered = true }
        H.raise (ValueChanged (trim (joinWith "" next)))
        maybeAutoSubmit next
        -- The pasted dump left a DIRTY value property on the receiving <input> (the browser
        -- keeps "456" on slot 0). Upstream's controlled React value resets each slot's property
        -- to its single char; mirror that imperatively so the property matches the per-slot
        -- char (the value ATTRIBUTE the DOM oracle reads is already correct via render).
        syncSlotValues next
        focusAt focusIdx
    else if (not st.disabled && not st.readOnly && raw == "") then
      -- An empty input event with no preceding keydown handler is a Cut (Backspace/Delete are
      -- handled + preventDefaulted in SlotKeyDown): upstream's onCut → CLEAR_CHAR reason Cut
      -- removes the char and keeps focus on the same slot.
      clearCharCompact idx false
    else do
      -- Single-char input: take the LAST typed char (handles the slot already holding a value),
      -- accept it only if valid; fill the slot and auto-advance focus to the next slot. A disabled
      -- or read-only field never mutates (radix gates the SET_CHAR dispatch on both).
      let
        typed = lastChar raw
      if (not st.disabled && not st.readOnly && typed /= "" && accepts st.validation typed) then do
        let
          cur = current st.chars
          next = fromMaybe cur (updateAt idx typed cur)
          res = change next st.chars
          nextCursor = min (idx + 1) (st.len - 1)
        H.modify_ \s -> s { chars = res.next, cursor = nextCursor, focusEntered = true }
        H.raise (ValueChanged (trim (joinWith "" next)))
        if isControlled st.chars
          -- Controlled: the value is parent-owned and did NOT change, but the native keystroke
          -- left a dirty property on the slot. Reset the DOM to the controlled value (React does
          -- this via the fixed value prop); don't advance focus or auto-submit on an ignored edit.
          then syncSlotValues (current res.next)
          else do
            focusAt nextCursor
            maybeAutoSubmit next
      else
        -- A rejected char (e.g. Space, or a digit under Alpha validation) left a DIRTY value
        -- PROPERTY on the native <input> even though state did not change. Upstream's onChange
        -- invalid branch resets the value AND re-selects it (rAF select) so the next keystroke
        -- replaces. Mirror both: resync this slot's property to its state char, then re-select.
        for_ (current st.chars !! idx) \ch -> do
          mel <- H.getHTMLElementRef (slotRef idx)
          for_ (mel >>= HTMLInputElement.fromHTMLElement) \inp -> liftEffect do
            HTMLInputElement.setValue ch inp
            HTMLInputElement.select inp
  SlotKeyDown idx ke -> do
    st <- H.get
    let key = KE.key ke
    let
      clearing = KE.ctrlKey ke || KE.metaKey ke
      atIdx = fromMaybe "" (current st.chars !! idx)
      editable = not st.disabled && not st.readOnly
    case key of
      -- Clear key, or Ctrl/Meta+Backspace, clears the ENTIRE value (otp.tsx:781-784, CLEAR).
      "Clear" | editable -> liftEffect (preventDefault (KE.toEvent ke)) *> clearAllSlots
      "Backspace" | editable && clearing -> liftEffect (preventDefault (KE.toEvent ke)) *> clearAllSlots
      -- Backspace: remove the char + compact, focus the PREVIOUS slot; on an empty slot just
      -- retreat. preventDefault so no native deletion races the compaction (otp.tsx:775-790).
      "Backspace" | editable -> do
        liftEffect (preventDefault (KE.toEvent ke))
        if atIdx /= "" then clearCharCompact idx true
        else do
          let prev = max 0 (idx - 1)
          H.modify_ _ { cursor = prev, focusEntered = true }
          focusAt prev
      -- Delete: remove the char + compact, focus stays; an empty slot is a no-op (otp.tsx:778-779).
      "Delete" | editable -> do
        liftEffect (preventDefault (KE.toEvent ke))
        when (atIdx /= "") (clearCharCompact idx false)
      "Enter" -> do
        -- Enter submits the enclosing form (otp.tsx:813-816): preventDefault + form.requestSubmit().
        liftEffect (preventDefault (KE.toEvent ke))
        withForm (liftEffect <<< requestSubmit)
      -- mid-selection insert (otp.tsx:836-862): a printable accepted char typed into a NON-empty,
      -- not-fully-selected, non-last slot. A collapsed cursor at the start writes the CURRENT slot,
      -- elsewhere the NEXT slot — preventDefault so the over-long autocomplete slot doesn't treat
      -- the second char as a paste. A FULL selection falls through to the input path (replace).
      _ | editable && atIdx /= "" && idx < st.len - 1 && SCU.length key == 1 && accepts st.validation key -> do
        mel <- H.getHTMLElementRef (slotRef idx)
        for_ (mel >>= HTMLInputElement.fromHTMLElement) \inp -> do
          selStart <- liftEffect (HTMLInputElement.selectionStart inp)
          selEnd <- liftEffect (HTMLInputElement.selectionEnd inp)
          let fullySelected = selStart == 0 && selEnd >= 1
          when (not fullySelected) do
            liftEffect (preventDefault (KE.toEvent ke))
            let
              targetIdx = if selStart == 0 then idx else idx + 1
              cur = current st.chars
              next = fromMaybe cur (updateAt targetIdx key cur)
              nextCursor = min (targetIdx + 1) (st.len - 1)
            H.modify_ \s -> s { chars = (change next s.chars).next, cursor = nextCursor, focusEntered = true }
            H.raise (ValueChanged (trim (joinWith "" next)))
            focusAt nextCursor
            maybeAutoSubmit next
      _ -> do
        let
          cfg = { orientation: st.orientation, dir: st.dir, loop: false }
          pos = { count: st.len, current: idx }
          -- isFocusable gating (otp.tsx:631-634): only slots up to lastSelectableIndex are
          -- reachable, so a move can never land past it (End on an empty field stays put).
          lastSelectable = clamp 0 (st.len - 1) (SCU.length (aggregate st))
        case navigate cfg pos key of
          Stay -> pure unit
          MoveTo target -> do
            let clamped = min target lastSelectable
            when (clamped /= idx) do
              H.modify_ _ { cursor = clamped, focusEntered = true }
              focusAt clamped

-- | radix `sanitizeValue`: strip whitespace, then either drop every char the validation set
-- | rejects (keep-only-accepted, the inverse of `replace(validation.regexp,"")`), OR — when
-- | validation is `NoValidation` — apply the consumer's custom `sanitize` function (otp.tsx:233-249).
sanitizePaste :: Validation -> (String -> String) -> String -> String
sanitizePaste v customF s =
  case v of
    NoValidation -> customF noWhitespace
    _ -> joinWith "" (filter (accepts v) (map SCU.singleton (toCharArray noWhitespace)))
  where
  noWhitespace = joinWith "" (filter notWs (map SCU.singleton (toCharArray s)))
  notWs c = c /= " " && c /= "\t" && c /= "\n" && c /= "\r"

-- | clamp an index into [0, len-1] (a paste of zero accepted chars never reaches here).
clampIdx :: Int -> Int -> Int
clampIdx len i = clamp 0 (max 0 (len - 1)) i

lastChar :: String -> String
lastChar s = case length cs of
  0 -> ""
  n -> fromMaybe "" (cs !! (n - 1))
  where
  cs = map SCU.singleton (toCharArray s)

-- | Imperatively set each slot input's `value` PROPERTY to its per-slot char (after a paste
-- | dump the receiving input holds the full string as a dirty property; the per-slot value
-- | attribute is correct via render but the property must be reset to match React).
syncSlotValues :: forall m. MonadEffect m => Array String -> H.HalogenM State Action () Output m Unit
syncSlotValues slots =
  forWithIndex_ slots \i ch -> do
    mel <- H.getHTMLElementRef (slotRef i)
    for_ (mel >>= HTMLInputElement.fromHTMLElement) (liftEffect <<< HTMLInputElement.setValue ch)

-- | When `autoSubmit` is set and the just-applied `next` has filled every slot, raise
-- | `AutoSubmitted` (upstream onAutoSubmit) then submit the enclosing form (otp.tsx:431-442).
-- | The callback fires whether or not a form is located; requestSubmit is best-effort.
maybeAutoSubmit :: forall m. MonadEffect m => Array String -> H.HalogenM State Action () Output m Unit
maybeAutoSubmit next = do
  st <- H.get
  when (st.autoSubmit && length next == st.len && length (filter (_ /= "") next) == st.len) do
    H.raise (AutoSubmitted (joinWith "" next))
    withForm (liftEffect <<< requestSubmit)

-- | CLEAR_CHAR (otp.tsx:327-344): REMOVE the char at `idx` and compact — upstream does
-- | `value.filter((_, i) => i !== index)`, so "123" minus index 1 becomes "13" (not "1_3").
-- | `retreat` picks the focus target: Backspace focuses the previous slot, Delete/Cut the same.
-- | The DOM properties are resynced so a deferred/duplicate native event can't revert the shift.
clearCharCompact :: forall m. MonadEffect m => Int -> Boolean -> H.HalogenM State Action () Output m Unit
clearCharCompact idx retreat = do
  st <- H.get
  let cur = current st.chars
  when (fromMaybe "" (cur !! idx) /= "") do
    let
      next = fromMaybe cur (deleteAt idx cur) <> [ "" ]   -- drop idx, re-pad to len
      focusIdx = if retreat then max 0 (idx - 1) else idx
    H.modify_ \s -> s { chars = (change next s.chars).next, cursor = focusIdx, focusEntered = true }
    H.raise (ValueChanged (trim (joinWith "" next)))
    syncSlotValues next
    focusAt focusIdx

-- | CLEAR: empty every slot, keeping focus where it is (otp.tsx CLEAR reason Backspace). Used by
-- | the Clear key and Ctrl/Meta+Backspace.
clearAllSlots :: forall m. MonadEffect m => H.HalogenM State Action () Output m Unit
clearAllSlots = do
  st <- H.get
  let cleared = replicate st.len ""
  H.modify_ \s -> s { chars = (change cleared s.chars).next, focusEntered = true }
  H.raise (ValueChanged "")
  syncSlotValues cleared

focusAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusAt idx = do
  mel <- H.getHTMLElementRef (slotRef idx)
  for_ mel (liftEffect <<< HTMLElement.focus)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetValue v a -> do
    H.modify_ \st -> st { chars = (change (toSlots st.len v) st.chars).next }
    pure (Just a)
  GetValue reply -> do
    st <- H.get
    pure (Just (reply (aggregate st)))
