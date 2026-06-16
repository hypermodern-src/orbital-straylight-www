-- | Hydrogen.Themes interactive port — the INTERACTIVE Radix Themes components (Dialog,
-- | …) as styled wrappers over the `Hydrogen.Radix` primitives: the primitive supplies
-- | the behavior + anatomy, a themed `Style` (the rt-* classes) supplies the look, and
-- | the content is built from the at-rest `Hydrogen.Themes.*` components. Routed `?c=<id>`
-- | + the same compiled `themes.css` as the golden, so the open-state DOM/screenshot diff
-- | reduces to "our themed overlay == upstream's".
module ThemesInteractive.Main where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (drop, indexOf, splitAt) as Str
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Radix.Dialog as Dialog
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.TextField (textField)
import Hydrogen.Themes.Typography (textAs)
import Type.Proxy (Proxy(..))
import Web.HTML as HTML
import Web.HTML.Location as Location
import Web.HTML.Window as Window

type Slots = (dialog :: Dialog.Slot Unit)

_dialog :: Proxy "dialog"
_dialog = Proxy

main :: Effect Unit
main = do
  c <- queryParam "c"
  HA.runHalogenAff do
    body <- HA.awaitBody
    void (runUI (root c) unit body)

root :: forall q i o. String -> H.Component q i o Aff
root c =
  H.mkComponent
    { initialState: const unit
    , render: const (view c)
    , eval: H.mkEval H.defaultEval
    }

view :: String -> H.ComponentHTML Void Slots Aff
view = case _ of
  "dialog" -> HH.slot_ _dialog unit Dialog.component dialogInput
  _ -> HH.div_ [ HH.text "pick a ?c=<component> (e.g. ?c=dialog)" ]

-- | The themed Dialog: the Radix primitive driven open, with the rt-* Style + content
-- | built from the at-rest Themes components. `defaultOpen` so the open state renders.
dialogInput :: Dialog.Input
dialogInput = Dialog.defaultInput
  { defaultOpen = true
  , style = dialogStyle
  , contentStyle = "max-width: 450px"
  , trigger = [ HH.text "Edit profile" ]
  , title = [ HH.text "Edit profile" ]
  , description = [ HH.text "Make changes to your profile." ]
  , content =
      [ box [ Mb "4" ]
          [ flex [ Direction "column", Gap "1" ]
              [ textAs "label" [ Size "2", Weight "bold" ] [ HH.text "Name" ]
              , textField "Enter your full name" []
              ]
          ]
      , flex [ Gap "3", Mt "4", Justify "end" ]
          [ button [ Variant "soft", Color "gray" ] [ HH.text "Cancel" ]
          , button [] [ HH.text "Save" ]
          ]
      ]
  }

-- | Radix Themes' Dialog class vocabulary (from the open-state golden).
dialogStyle :: Dialog.Style
dialogStyle =
  { trigger: cn "rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-solid"
  , overlay: cn "rt-BaseDialogOverlay rt-DialogOverlay"
  , scroll: cn "rt-BaseDialogScroll rt-DialogScroll"
  , scrollPadding: cn "rt-BaseDialogScrollPadding rt-DialogScrollPadding rt-r-align-center"
  , content: cn "rt-BaseDialogContent rt-DialogContent rt-r-size-3"
  , title: cn "rt-Heading rt-r-size-5 rt-r-mb-3"
  , description: cn "rt-Text rt-r-size-2 rt-r-mb-4 rt-r-color-gray"
  }

-- ── ?c=<id> query param ─────────────────────────────────────────────────────────
queryParam :: String -> Effect String
queryParam key = do
  search <- HTML.window >>= Window.location >>= Location.search
  pure (lookupParam key search)

lookupParam :: String -> String -> String
lookupParam key search =
  let
    body = Str.drop 1 search
    pairs = splitOn "&" body
    match p = case Str.indexOf (Pattern "=") p of
      Just i -> let kv = Str.splitAt i p in if kv.before == key then Just (Str.drop 1 kv.after) else Nothing
      Nothing -> Nothing
  in
    fromMaybe "" (firstJust (map match pairs))

splitOn :: String -> String -> Array String
splitOn sep s = case Str.indexOf (Pattern sep) s of
  Nothing -> [ s ]
  Just i -> let kv = Str.splitAt i s in [ kv.before ] <> splitOn sep (Str.drop 1 kv.after)

firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust = case _ of
  [] -> Nothing
  xs -> case Array.find isJust xs of
    Just (Just a) -> Just a
    _ -> Nothing
  where
  isJust = case _ of
    Just _ -> true
    Nothing -> false
