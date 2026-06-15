-- | Hydrogen.Themes port — the Halogen reproduction of Radix Themes, rendered
-- | under the SAME `?c=<id>` route contract and the SAME compiled stylesheet as
-- | the golden source (testing/golden/themes). Pixel-diffing the two therefore
-- | reduces to "does our DOM + rt-* classes match upstream's" — no CSS of ours.
module ThemesPort.Main where

import Prelude

import Data.Array (find)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (drop, indexOf, splitAt) as Str
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Button (button, disabled)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Theme (theme)
import Web.HTML as HTML
import Web.HTML.Location as Location
import Web.HTML.Window as Window

main :: Effect Unit
main = do
  c <- queryParam "c"
  HA.runHalogenAff do
    body <- HA.awaitBody
    void $ runUI (app c) unit body

app :: forall q i o. String -> H.Component q i o Aff
app c =
  H.mkComponent
    { initialState: const unit
    , render: const (theme [ box [ P "6" ] [ page c ] ])
    , eval: H.mkEval H.defaultEval
    }

page :: forall w i. String -> HH.HTML w i
page = case _ of
  "button" -> buttonPage
  _ -> HH.div_ [ HH.text "pick a ?c=<component>" ]

-- Reproduces components-button page of the golden (variant row + size/disabled row).
buttonPage :: forall w i. HH.HTML w i
buttonPage =
  flex [ Direction "column", Gap "3", Align "start" ]
    [ flex [ Gap "3", Align "center" ]
        [ button [ Variant "solid" ] [ HH.text "Solid" ]
        , button [ Variant "soft" ] [ HH.text "Soft" ]
        , button [ Variant "outline" ] [ HH.text "Outline" ]
        , button [ Variant "surface" ] [ HH.text "Surface" ]
        , button [ Variant "ghost" ] [ HH.text "Ghost" ]
        ]
    , flex [ Gap "3", Align "center" ]
        [ button [ Size "1" ] [ HH.text "Size 1" ]
        , button [ Size "2" ] [ HH.text "Size 2" ]
        , button [ Size "3" ] [ HH.text "Size 3" ]
        , button disabled [ HH.text "Disabled" ]
        ]
    ]

-- | The `?c=<id>` value, or "" when absent.
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
      Just i ->
        let kv = Str.splitAt i p
        in if kv.before == key then Just (Str.drop 1 kv.after) else Nothing
      Nothing -> Nothing
  in
    fromMaybe "" (firstJust (map match pairs))

splitOn :: String -> String -> Array String
splitOn sep s = case Str.indexOf (Pattern sep) s of
  Nothing -> [ s ]
  Just i -> let kv = Str.splitAt i s in [ kv.before ] <> splitOn sep (Str.drop 1 kv.after)

firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust xs = case find isJust xs of
  Just (Just a) -> Just a
  _ -> Nothing
  where
  isJust = case _ of
    Just _ -> true
    Nothing -> false
