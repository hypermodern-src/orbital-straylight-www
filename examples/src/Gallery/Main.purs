-- | Hydrogen.Radix gallery — reproductions of radix-ui/primitives' Storybook
-- | (MIT, (c) WorkOS) rendered with the ported Halogen primitives, for
-- | pixel-perfect comparison against the captured goldens (testing/playwright).
-- |
-- | The facade that makes Playwright an implementation detail: each story is a
-- | self-contained component in `Gallery.Story.<Name>` (it owns its own internal
-- | slots), listed ONCE in `stories` below. The gallery routes on `?story=<id>`
-- | (one story per page, so each diffs in isolation), mounts the selected story
-- | through a single uniform slot, and on the index renders a machine-readable
-- | manifest of ids the (fixed, generic) test spec reads. Adding a story = a new
-- | module + one line here; the TS harness never changes.
module Gallery.Main where

import Prelude

import Data.Array (filter, find)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (drop, indexOf, splitAt) as Str
import Data.String.Pattern (Pattern(..))
import Data.Void (Void)
import Effect (Effect)
import Effect.Aff (Aff)
import Gallery.Story (GallerySlots, Story, _story)
import Gallery.Story.Checkbox as Checkbox
import Gallery.Story.Collapsible as Collapsible
import Gallery.Story.AlertDialog as AlertDialog
import Gallery.Story.ContextMenu as ContextMenu
import Gallery.Story.Dialog as Dialog
import Gallery.Story.DropdownMenu as DropdownMenu
import Gallery.Story.HoverCard as HoverCard
import Gallery.Story.Label as Label
import Gallery.Story.Popover as Popover
import Gallery.Story.Select as Select
import Gallery.Story.Tooltip as Tooltip
import Gallery.Story.Separator as Separator
import Gallery.Story.Switch as Switch
import Gallery.Story.Toggle as Toggle
import Gallery.Story.TogglePresets as TogglePresets
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Web.HTML as HTML
import Web.HTML.Location as Location
import Web.HTML.Window as Window

-- ─────────────────────────────────────────────────────────────────────────────
-- The story manifest — the one place a story is registered
-- ─────────────────────────────────────────────────────────────────────────────

stories :: Array Story
stories =
  [ Checkbox.story
  , Separator.story
  , Label.story
  , Toggle.story
  , Switch.story
  , Collapsible.story
  , Dialog.story
  , Popover.story
  , AlertDialog.story
  , Tooltip.story
  , HoverCard.story
  , DropdownMenu.story
  , ContextMenu.story
  , Select.story
  , TogglePresets.story
  ]

-- | Stories that are NOT pixel-diffed (no golden png) — reachable by id for non-pixel
-- | gates only (e.g. the behavioral-invariance gate drives `?story=toggle-presets`).
-- | Excluded from the manifest the pixel spec enumerates.
nonPixel :: Array String
nonPixel = [ "toggle-presets" ]

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

render :: String -> H.ComponentHTML Void GallerySlots Aff
render selected = case find (\s -> s.id == selected) stories of
  -- A single story, isolated (this is the page the pixel diff screenshots).
  Just s -> HH.slot_ _story s.id s.component unit
  -- The index: a human-facing showcase (chrome scoped under .gallery-index, so the
  -- isolated story pages above are untouched and stay pixel-identical).
  Nothing -> index

index :: H.ComponentHTML Void GallerySlots Aff
index =
  HH.div
    [ HP.class_ (HH.ClassName "gallery-index") ]
    [ HH.header_
        [ HH.h1_ [ HH.text "Hydrogen.Radix" ]
        , HH.p_
            [ HH.text "Halogen reproductions of the radix-ui primitives — each pixel-checked against radix's own Storybook render." ]
        ]
    , manifest
    , HH.main_ (map card stories)
    ]
  where
  card s =
    HH.section
      [ HP.class_ (HH.ClassName "gallery-card") ]
      [ HH.h2_ [ HH.a [ HP.href ("?story=" <> s.id) ] [ HH.text s.id ] ]
      , HH.slot_ _story s.id s.component unit
      ]

-- | The story index — clickable nav AND the machine-readable manifest the generic
-- | spec reads (`#gallery-manifest li[data-story]`); the `<a>` is just navigation.
manifest :: H.ComponentHTML Void GallerySlots Aff
manifest =
  HH.ul [ HP.id "gallery-manifest", HP.class_ (HH.ClassName "gallery-toc") ]
    ( map
        ( \s ->
            HH.li [ HP.attr (HH.AttrName "data-story") s.id ]
              [ HH.a [ HP.href ("?story=" <> s.id) ] [ HH.text s.id ] ]
        )
        (filter (\s -> not (elemStr s.id nonPixel)) stories)
    )

elemStr :: String -> Array String -> Boolean
elemStr x = case _ of
  xs -> case find (_ == x) xs of
    Just _ -> true
    Nothing -> false

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
