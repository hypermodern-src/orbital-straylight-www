-- | Storybook.Mount — the single FFI seam between Storybook and the Halogen
-- | `Hydrogen.Themes` components.
-- |
-- | `purs_browser_bundle` emits a self-running bundle, so `main` attaches a
-- | `mount(componentId, args, element)` function to `window.hydrogenStorybook`.
-- | Each Storybook story calls it with its component id + the live control `args`;
-- | `render` maps those args to the component's `Array Prop` (arg-driven, single
-- | instance) or, for the composite components, renders a representative demo.
-- | The `.radix-themes` Theme wrapper + the Radix stylesheet are supplied by the
-- | Storybook preview decorator, so a story renders identically to the goldens.
module Storybook.Mount (main) where

import Prelude

import Data.Array (elem)
import Data.Function.Uncurried (Fn3, mkFn3)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Avatar (avatar)
import Hydrogen.Themes.Badge (badge)
import Hydrogen.Themes.Blockquote (blockquote)
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Callout (calloutRoot, calloutText)
import Hydrogen.Themes.Card (card)
import Hydrogen.Themes.Checkbox (checkbox)
import Hydrogen.Themes.Code (code)
import Hydrogen.Themes.DataList (dataListItem, dataListLabel, dataListRoot, dataListValue)
import Hydrogen.Themes.Inline (em, strong)
import Hydrogen.Themes.Kbd (kbd)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Link (link)
import Hydrogen.Themes.Progress (progress)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Quote (quote)
import Hydrogen.Themes.RadioGroup (radioGroup, radioItem)
import Hydrogen.Themes.Separator (separator)
import Hydrogen.Themes.Slider (slider)
import Hydrogen.Themes.Spinner (spinner)
import Hydrogen.Themes.Switch (switch)
import Hydrogen.Themes.Table (tableBody, tableCell, tableColumnHeaderCell, tableHeader, tableRoot, tableRow, tableRowHeaderCell)
import Hydrogen.Themes.Tabs (tabsList, tabsRoot, tabsTrigger)
import Hydrogen.Themes.TextArea (textArea)
import Hydrogen.Themes.TextField (textField, textFieldValue)
import Hydrogen.Themes.Typography (headingAs, text, textAs)
import Storybook.Showcase as Showcase
import Web.DOM (Element)
import Web.HTML.HTMLElement (fromElement)

-- | An opaque handle to the JS Storybook `args` object (control values).
foreign import data Args :: Type

foreign import argStr :: String -> String -> Args -> String
foreign import argBool :: String -> Boolean -> Args -> Boolean
foreign import argInt :: String -> Int -> Args -> Int

-- | Install `window.hydrogenStorybook = { mount }`.
foreign import attach :: Fn3 String Args Element (Effect Unit) -> Effect Unit

main :: Effect Unit
main = attach (mkFn3 mount)

mount :: String -> Args -> Element -> Effect Unit
mount cid args el = case fromElement el of
  Nothing -> pure unit
  -- stateful Radix primitives mount as live child components (Showcase slot-host); the
  -- display Themes components render as static HTML.
  Just he
    | cid `elem` Showcase.ids -> HA.runHalogenAff (void (runUI Showcase.component cid he))
    | otherwise -> HA.runHalogenAff (void (runUI (static (render cid args)) unit he))
  where
  static html =
    H.mkComponent
      { initialState: const unit
      , render: const html
      , eval: H.mkEval H.defaultEval
      }

-- | An enum control → its Prop, dropped when the control is empty/unset.
optEnum :: String -> (String -> Prop) -> Args -> Array Prop
optEnum key ctor args = let v = argStr key "" args in if v == "" then [] else [ ctor v ]

-- | The common variant/size/color controls.
common :: Args -> Array Prop
common a = optEnum "variant" Variant a <> optEnum "size" Size a <> optEnum "color" Color a

-- | Map a component id + control args to the rendered component.
render :: forall w i. String -> Args -> HH.HTML w i
render cid a = case cid of
  -- ── arg-driven singles ───────────────────────────────────────────────────
  "button" -> button (common a) [ HH.text (argStr "label" "Button" a) ]
  "badge" -> badge (common a) [ HH.text (argStr "label" "Badge" a) ]
  "switch" -> switch (argBool "checked" true a) (argBool "disabled" false a) []
  "checkbox" ->
    textAs "label" [ Size "2" ]
      [ flex [ Align "center", Gap "2" ]
          [ checkbox (argBool "checked" true a) (argBool "disabled" false a) []
          , HH.text (" " <> argStr "label" "Accept terms" a)
          ]
      ]
  "code" -> code (optEnum "variant" Variant a <> optEnum "size" Size a) [ HH.text (argStr "label" "npm install" a) ]
  "kbd" -> kbd (optEnum "size" Size a) [ HH.text (argStr "label" "Shift + Tab" a) ]
  "link" -> link "#" (optEnum "size" Size a) [ HH.text (argStr "label" "documentation" a) ]
  "avatar" -> avatar (argStr "fallback" "RT" a) (common a)
  "spinner" -> spinner (optEnum "size" Size a)
  "progress" -> progress (argInt "value" 60 a) (optEnum "variant" Variant a <> optEnum "color" Color a)
  "slider" -> box [ StyleProp "max-width" "320px" ] [ slider (argInt "value" 40 a) [] ]
  "callout" ->
    box [ StyleProp "max-width" "420px" ]
      [ calloutRoot (optEnum "color" Color a)
          [ calloutText [] [ HH.text (argStr "text" "You will need admin privileges to install this app." a) ] ]
      ]
  "textfield" -> box [ StyleProp "max-width" "320px" ] [ textField (argStr "placeholder" "Search the docs…" a) (optEnum "size" Size a) ]
  "textarea" -> box [ StyleProp "max-width" "320px" ] [ textArea (argStr "placeholder" "Reply to comment…" a) (optEnum "size" Size a) ]
  "blockquote" -> box [ StyleProp "max-width" "360px" ] [ blockquote (optEnum "size" Size a) [ HH.text (argStr "text" "Perfect is the enemy of good." a) ] ]
  "quote" -> text [ Size "3" ] [ quote [] [ HH.text (argStr "text" "Design is not just what it looks like." a) ] ]
  -- ── composite demos ─────────────────────────────────────────────────────
  "separator" -> separatorDemo
  "emstrong" -> emstrongDemo
  "card" -> cardDemo
  "radiogroup" -> radiogroupDemo
  "tabs" -> tabsDemo
  "table" -> tableDemo
  "datalist" -> datalistDemo
  "signin" -> signinDemo
  _ -> HH.text ("unknown component: " <> cid)

separatorDemo :: forall w i. HH.HTML w i
separatorDemo =
  flex [ Direction "column", Gap "3", StyleProp "max-width" "240px" ]
    [ text [ Size "2" ] [ HH.text "Above" ]
    , separator [ Size "4" ]
    , text [ Size "2" ] [ HH.text "Below" ]
    ]

emstrongDemo :: forall w i. HH.HTML w i
emstrongDemo =
  text [ Size "3" ]
    [ HH.text "The ", strong [] [ HH.text "quick" ], HH.text " brown fox is ", em [] [ HH.text "remarkably" ], HH.text " fast." ]

cardDemo :: forall w i. HH.HTML w i
cardDemo =
  box [ StyleProp "max-width" "320px" ]
    [ card []
        [ flex [ Gap "3", Align "center" ]
            [ box []
                [ textAs "div" [ Size "2", Weight "bold" ] [ HH.text "Teodros Girmay" ]
                , textAs "div" [ Size "2", Color "gray" ] [ HH.text "Engineering" ]
                ]
            ]
        ]
    ]

radiogroupDemo :: forall w i. HH.HTML w i
radiogroupDemo =
  radioGroup []
    [ flex [ Direction "column", Gap "2" ]
        [ radioRow true "1" "Default", radioRow false "2" "Comfortable", radioRow false "3" "Compact" ]
    ]
  where
  radioRow chk val lbl =
    textAs "label" [ Size "2" ]
      [ flex [ Gap "2", Align "center" ] [ radioItem chk val [], HH.text (" " <> lbl) ] ]

tabsDemo :: forall w i. HH.HTML w i
tabsDemo =
  tabsRoot []
    [ tabsList []
        [ tabsTrigger true [] [ HH.text "Account" ]
        , tabsTrigger false [] [ HH.text "Documents" ]
        , tabsTrigger false [] [ HH.text "Settings" ]
        ]
    ]

tableDemo :: forall w i. HH.HTML w i
tableDemo =
  box [ StyleProp "max-width" "480px" ]
    [ tableRoot []
        [ tableHeader []
            [ tableRow []
                [ tableColumnHeaderCell [] [ HH.text "Name" ], tableColumnHeaderCell [] [ HH.text "Email" ] ]
            ]
        , tableBody []
            [ tableRow []
                [ tableRowHeaderCell [] [ HH.text "Danilo" ], tableCell [] [ HH.text "danilo@example.com" ] ]
            , tableRow []
                [ tableRowHeaderCell [] [ HH.text "Zahra" ], tableCell [] [ HH.text "zahra@example.com" ] ]
            ]
        ]
    ]

datalistDemo :: forall w i. HH.HTML w i
datalistDemo =
  dataListRoot []
    [ dataListItem []
        [ dataListLabel [] [ HH.text "Status" ], dataListValue [] [ badge [ Color "jade" ] [ HH.text "Authorized" ] ] ]
    , dataListItem []
        [ dataListLabel [] [ HH.text "Name" ], dataListValue [] [ HH.text "Vlad Moroz" ] ]
    ]

signinDemo :: forall w i. HH.HTML w i
signinDemo =
  box [ Width "400px" ]
    [ card [ Size "4" ]
        [ headingAs "h3" [ Size "6", Trim "start", Mb "5" ] [ HH.text "Sign in" ]
        , box [ Mb "5" ]
            [ flex [ Direction "column", Gap "1" ]
                [ textAs "label" [ Size "2", Weight "medium" ] [ HH.text "Email address" ]
                , textField "you@example.com" []
                ]
            ]
        , box [ Mb "5" ]
            [ flex [ Direction "column", Gap "1" ]
                [ flex [ Justify "between" ]
                    [ textAs "label" [ Size "2", Weight "medium" ] [ HH.text "Password" ]
                    , text [ Size "2" ] [ HH.a [ HP.href "#" ] [ HH.text "Forgot password?" ] ]
                    ]
                , textField "Enter your password" []
                ]
            ]
        , flex [ Align "center", Gap "2", Mb "5" ]
            [ textAs "label" [ Size "2" ]
                [ flex [ Gap "2", Align "center" ] [ checkbox true false [], HH.text " Remember me" ] ]
            ]
        , flex [ Justify "end", Gap "3" ]
            [ button [ Variant "soft", Color "gray" ] [ HH.text "Create account" ], button [] [ HH.text "Sign in" ] ]
        ]
    ]
