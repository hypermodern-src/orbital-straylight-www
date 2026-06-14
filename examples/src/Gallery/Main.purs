-- | Hydrogen.Radix gallery — reproductions of radix-ui/primitives' Storybook
-- | (MIT, (c) WorkOS) rendered with the ported Halogen primitives, for
-- | pixel-perfect comparison against the captured golden (tests/playwright).
-- |
-- | This is the facade that makes Playwright an implementation detail: a story is
-- | declared HERE, in PureScript, as an `{ id, view }` pair in `stories`. The
-- | gallery routes on `?story=<id>` (one story per page, so each diffs in
-- | isolation) and, on the index, renders a machine-readable manifest of ids that
-- | the (fixed, generic) test spec reads to know what to diff. Adding a story is
-- | therefore pure PureScript — append to `stories`; the TS harness never changes.
module Gallery.Main where

import Prelude

import Data.Array (find)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (drop, indexOf, splitAt) as Str
import Data.String.Pattern (Pattern(..))
import Data.Void (Void)
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Radix.Checkbox as Checkbox
import Hydrogen.Radix.Foundation.Style (cn)
import Type.Proxy (Proxy(..))
import Web.HTML as HTML
import Web.HTML.Location as Location
import Web.HTML.Window as Window

-- ─────────────────────────────────────────────────────────────────────────────
-- The story manifest — the one place a story is declared (pure PureScript)
-- ─────────────────────────────────────────────────────────────────────────────

type Slots = ( checkbox :: Checkbox.Slot Int )

type Story = { id :: String, view :: H.ComponentHTML Void Slots Aff }

-- | Every reproduced story. The fan-out appends here; nothing else changes.
stories :: Array Story
stories =
  [ { id: "checkbox", view: checkboxStory }
  ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Mount: route on ?story=<id>, else render the manifest index
-- ─────────────────────────────────────────────────────────────────────────────

main :: Effect Unit
main = do
  q <- queryParam "story"
  HA.runHalogenAff do
    body <- HA.awaitBody
    void $ runUI (gallery q) unit body

-- | The `?story=<id>` value, or "" on the index.
queryParam :: String -> Effect String
queryParam key = do
  search <- HTML.window >>= Window.location >>= Location.search
  pure (lookupParam key search)

lookupParam :: String -> String -> String
lookupParam key search =
  let
    body = Str.drop 1 search -- strip leading '?'
    pairs = splitOn "&" body
    match p = case Str.indexOf (Pattern "=") p of
      Just i -> let kv = Str.splitAt i p in if kv.before == key then Just (Str.drop 1 kv.after) else Nothing
      Nothing -> Nothing
  in
    fromMaybe "" (firstJust (map match pairs))

gallery :: forall q i o. String -> H.Component q i o Aff
gallery selected =
  H.mkComponent
    { initialState: const unit
    , render: const (render selected)
    , eval: H.mkEval H.defaultEval
    }

render :: String -> H.ComponentHTML Void Slots Aff
render selected = case find (\s -> s.id == selected) stories of
  Just story -> story.view
  Nothing -> manifest

-- | Machine-readable list of story ids the generic spec reads from the index.
manifest :: H.ComponentHTML Void Slots Aff
manifest =
  HH.ul [ HP.id "gallery-manifest" ]
    (map (\s -> HH.li [ HP.attr (HH.AttrName "data-story") s.id ] [ HH.text s.id ]) stories)

-- ─────────────────────────────────────────────────────────────────────────────
-- Stories
-- ─────────────────────────────────────────────────────────────────────────────

_checkbox :: Proxy "checkbox"
_checkbox = Proxy

-- | radix Checkbox `Styled` story: seven variants — custom Label + checkbox,
-- | native label + checkbox, native checkbox, and the htmlFor forms. All
-- | uncontrolled (unchecked → empty 30×30 box).
checkboxStory :: H.ComponentHTML Void Slots Aff
checkboxStory =
  HH.div
    [ HP.style "display:contents" ]
    [ HH.p_ [ HH.text "This checkbox is nested inside a label. The state is uncontrolled." ]
    , HH.h1_ [ HH.text "Custom label" ]
    , HH.label_ [ HH.text "Label ", box 0 ]
    , HH.br_
    , HH.br_
    , HH.h1_ [ HH.text "Native label" ]
    , HH.label_ [ HH.text "Label ", box 1 ]
    , HH.h1_ [ HH.text "Native label + native checkbox" ]
    , HH.label_ [ HH.text "Label ", nativeBox ]
    , HH.h1_ [ HH.text "Custom label + htmlFor" ]
    , HH.label_ [ HH.text "Label" ]
    , box 2
    , HH.br_
    , HH.br_
    , HH.h1_ [ HH.text "Native label + htmlFor" ]
    , HH.label_ [ HH.text "Label" ]
    , box 3
    , HH.h1_ [ HH.text "Native label + native checkbox" ]
    , HH.label_ [ HH.text "Label" ]
    , nativeBox
    ]
  where
  box i = HH.slot_ _checkbox i Checkbox.component styledInput
  nativeBox = HH.input [ HP.type_ HP.InputCheckbox ]

styledInput :: Checkbox.Input
styledInput = Checkbox.defaultInput
  { style = { root: cn "root", indicator: cn "indicator" } }

-- ─────────────────────────────────────────────────────────────────────────────
-- Tiny pure string helpers (kept local; not worth a dependency)
-- ─────────────────────────────────────────────────────────────────────────────

splitOn :: String -> String -> Array String
splitOn sep s = case Str.indexOf (Pattern sep) s of
  Nothing -> [ s ]
  Just i -> let kv = Str.splitAt i s in [ kv.before ] <> splitOn sep (Str.drop 1 kv.after)

firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust = case _ of
  [] -> Nothing
  xs -> case find isJust xs of
    Just (Just a) -> Just a
    _ -> Nothing
  where
  isJust = case _ of
    Just _ -> true
    Nothing -> false
