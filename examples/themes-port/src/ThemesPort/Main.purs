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
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Button (button, disabled)
import Hydrogen.Themes.Card (card)
import Hydrogen.Themes.Checkbox (checkbox)
import Hydrogen.Themes.Layout (box, flex)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.TextField (textField, textFieldValue)
import Hydrogen.Themes.Theme (theme)
import Hydrogen.Themes.Typography (headingAs, text, textAs)
import Hydrogen.Themes.Avatar (avatar)
import Hydrogen.Themes.Badge (badge)
import Hydrogen.Themes.Blockquote (blockquote)
import Hydrogen.Themes.Callout (calloutRoot, calloutText)
import Hydrogen.Themes.Code (code)
import Hydrogen.Themes.DataList (dataListRoot, dataListItem, dataListLabel, dataListValue)
import Hydrogen.Themes.Inline (em, strong)
import Hydrogen.Themes.Kbd (kbd)
import Hydrogen.Themes.Link (link)
import Hydrogen.Themes.Progress (progress)
import Hydrogen.Themes.Quote (quote)
import Hydrogen.Themes.RadioGroup (radioGroup, radioItem)
import Hydrogen.Themes.Separator (separator)
import Hydrogen.Themes.Slider (slider)
import Hydrogen.Themes.Spinner (spinner)
import Hydrogen.Themes.Switch (switch) as Switch
import Hydrogen.Themes.Table (tableRoot, tableHeader, tableBody, tableRow, tableColumnHeaderCell, tableRowHeaderCell, tableCell)
import Hydrogen.Themes.Tabs (tabsRoot, tabsList, tabsTrigger)
import Hydrogen.Themes.TextArea (textArea)
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
  "checkbox" -> checkboxPage
  "textfield" -> textfieldPage
  "card" -> cardPage
  "signin" -> signinPage
  "switch" -> switchPage
  "textarea" -> textareaPage
  "badge" -> badgePage
  "callout" -> calloutPage
  "avatar" -> avatarPage
  "spinner" -> spinnerPage
  "progress" -> progressPage
  "separator" -> separatorPage
  "code" -> codePage
  "kbd" -> kbdPage
  "quote" -> quotePage
  "blockquote" -> blockquotePage
  "emstrong" -> emstrongPage
  "link" -> linkPage
  "radiogroup" -> radiogroupPage
  "slider" -> sliderPage
  "tabs" -> tabsPage
  "table" -> tablePage
  "datalist" -> datalistPage
  _ -> HH.div_ [ HH.text "pick a ?c=<component>" ]

-- Reproduces components-…--signin: the composed Sign-in card (the finished-product
-- target). Mirrors the golden JSX node for node.
signinPage :: forall w i. HH.HTML w i
signinPage =
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
                [ flex [ Gap "2", Align "center" ]
                    [ checkbox true false [], HH.text " Remember me" ]
                ]
            ]
        , flex [ Justify "end", Gap "3" ]
            [ button [ Variant "soft", Color "gray" ] [ HH.text "Create account" ]
            , button [] [ HH.text "Sign in" ]
            ]
        ]
    ]

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


-- Reproduces components-checkbox: checked / unchecked / disabled rows.
checkboxPage :: forall w i. HH.HTML w i
checkboxPage =
  flex [ Direction "column", Gap "2" ]
    [ row true false " Checked"
    , row false false " Unchecked"
    , row true true " Disabled"
    ]
  where
  row chk dis lbl =
    textAs "label" [ Size "2" ]
      [ flex [ Align "center", Gap "2" ]
          [ checkbox chk dis [], HH.text lbl ]
      ]

-- Reproduces components-textfield: a size-2 field + a size-3 field with a value.
textfieldPage :: forall w i. HH.HTML w i
textfieldPage =
  flex [ Direction "column", Gap "3", StyleProp "max-width" "320px" ]
    [ textField "Search the docs\x2026" []
    , textFieldValue "Larger field" "m@example.com" [ Size "3" ]
    ]

-- Reproduces components-card: a profile card.
cardPage :: forall w i. HH.HTML w i
cardPage =
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

-- Reproduces the golden's components-switch page: a row of switches at rest.
-- Switch.defaultChecked renders data-state=checked + the translated thumb; the
-- plain Switch renders unchecked; disabled adds disabled + data-disabled.
switchPage :: forall w i. HH.HTML w i
switchPage =
  flex [ Gap "4", Align "center" ]
    [ Switch.switch true false []
    , Switch.switch false false []
    , Switch.switch true true []
    , Switch.switch true false [ Size "1" ]
    , Switch.switch true false [ Size "3" ]
    ]

-- Reproduces components-textarea: a maxWidth:320 Box wrapping the bare TextArea.
textareaPage :: forall w i. HH.HTML w i
textareaPage =
  box [ StyleProp "max-width" "320px" ]
    [ textArea "Reply to comment…" [] ]

-- Reproduces components-…--badge: a Flex of Badges (the golden JSX node).
badgePage :: forall w i. HH.HTML w i
badgePage =
  flex [ Gap "2", Align "center" ]
    [ badge [ Color "green" ] [ HH.text "Complete" ]
    , badge [ Color "orange" ] [ HH.text "In progress" ]
    , badge [ Color "red" ] [ HH.text "Failed" ]
    , badge [ Variant "solid" ] [ HH.text "Solid" ]
    ]

-- Reproduces components-callout: a Box(maxWidth 420) wrapping Callout.Root>Callout.Text.
calloutPage :: forall w i. HH.HTML w i
calloutPage =
  box [ StyleProp "max-width" "420px" ]
    [ calloutRoot []
        [ calloutText []
            [ HH.text "You will need admin privileges to install and access this application." ]
        ]
    ]

-- Reproduces components-…--avatar: a Flex of four fallback avatars (no image src),
-- exercising the defaults plus color="indigo", variant="solid", and size="5".
avatarPage :: forall w i. HH.HTML w i
avatarPage =
  flex [ Gap "3", Align "center" ]
    [ avatar "A" []
    , avatar "TG" [ Color "indigo" ]
    , avatar "RT" [ Variant "solid" ]
    , avatar "L" [ Size "5" ]
    ]

-- Reproduces the golden's spinner page: a Flex (gap 4, align center) of three
-- spinners at sizes 1/2/3. Each renders span.rt-Spinner with eight rt-SpinnerLeaf.
spinnerPage :: forall w i. HH.HTML w i
spinnerPage =
  flex [ Gap "4", Align "center" ]
    [ spinner [ Size "1" ]
    , spinner [ Size "2" ]
    , spinner [ Size "3" ]
    ]

-- Reproduces the golden's "progress" page: a 320px-max flex column of three
-- Progress bars (default surface/size-2 at 25%, a cyan one at 60%, a soft one at
-- 90%). Each bar renders its at-rest DOM (data-state="loading").
progressPage :: forall w i. HH.HTML w i
progressPage =
  flex [ Direction "column", Gap "4", StyleProp "max-width" "320px" ]
    [ progress 25 []
    , progress 60 [ Color "cyan" ]
    , progress 90 [ Variant "soft" ]
    ]

-- Reproduces components-separator page of the golden: a column with Text above,
-- a size-4 Separator, and Text below.
separatorPage :: forall w i. HH.HTML w i
separatorPage =
  flex [ Direction "column", Gap "3", StyleProp "max-width" "240px" ]
    [ text [ Size "2" ] [ HH.text "Above" ]
    , separator [ Size "4" ]
    , text [ Size "2" ] [ HH.text "Below" ]
    ]

-- Reproduces components-code page of the golden: a size-3 sentence with two
-- inline <Code> spans (default soft, then explicit solid).
codePage :: forall w i. HH.HTML w i
codePage =
  text [ Size "3" ]
    [ HH.text "Run "
    , code [] [ HH.text "npm install" ]
    , HH.text " then "
    , code [ Variant "solid" ] [ HH.text "npm start" ]
    , HH.text "."
    ]

kbdPage :: forall w i. HH.HTML w i
kbdPage =
  text [ Size "3" ]
    [ HH.text "Press "
    , kbd [] [ HH.text "Shift + Tab" ]
    , HH.text " to go back."
    ]

quotePage :: forall w i. HH.HTML w i
quotePage =
  text [ Size "3" ]
    [ quote [] [ HH.text "Design is not just what it looks like and feels like." ] ]

-- Reproduces the golden's blockquote page: a Box (max-width 360) wrapping a single
-- Blockquote. Upstream node:
--   <Box style={{ maxWidth: 360 }}><Blockquote>…</Blockquote></Box>
blockquotePage :: forall w i. HH.HTML w i
blockquotePage =
  box [ StyleProp "max-width" "360px" ]
    [ blockquote []
        [ HH.text "Perfect is the enemy of good. Ship the thing, then make it better." ]
    ]

-- Reproduces the golden's `emstrong` node:
--   <Text size="3">The <Strong>quick</Strong> brown fox is <Em>remarkably</Em> fast.</Text>
emstrongPage :: forall w i. HH.HTML w i
emstrongPage =
  text [ Size "3" ]
    [ HH.text "The "
    , strong [] [ HH.text "quick" ]
    , HH.text " brown fox is "
    , em [] [ HH.text "remarkably" ]
    , HH.text " fast."
    ]

-- Reproduces components-…--link: a `<Text size="3">` sentence with an inline Link.
-- The Link itself takes no size/color, so its `<a>` carries only
-- `rt-reset rt-Link rt-Text rt-underline-auto`; the surrounding Text supplies
-- `rt-r-size-3`.
linkPage :: forall w i. HH.HTML w i
linkPage =
  text [ Size "3" ]
    [ HH.text "Read the "
    , link "#" [] [ HH.text "documentation" ]
    , HH.text " for more."
    ]

-- Reproduces components-radiogroup: a RadioGroup.Root (defaultValue="1") with
-- three labeled items (item value="1" selected). Each label is a Text as="label"
-- size="2" wrapping a Flex(gap 2, align center) holding the radio + trailing text.
radiogroupPage :: forall w i. HH.HTML w i
radiogroupPage =
  radioGroup []
    [ flex [ Direction "column", Gap "2" ]
        [ textAs "label" [ Size "2" ]
            [ flex [ Gap "2", Align "center" ]
                [ radioItem true "1" [], HH.text " Default" ]
            ]
        , textAs "label" [ Size "2" ]
            [ flex [ Gap "2", Align "center" ]
                [ radioItem false "2" [], HH.text " Comfortable" ]
            ]
        , textAs "label" [ Size "2" ]
            [ flex [ Gap "2", Align "center" ]
                [ radioItem false "3" [], HH.text " Compact" ]
            ]
        ]
    ]

-- Reproduces components-slider: a maxWidth:320 Box wrapping a single-value
-- Slider at rest (defaultValue={[40]}).
sliderPage :: forall w i. HH.HTML w i
sliderPage =
  box [ StyleProp "max-width" "320px" ]
    [ slider 40 [] ]

-- Reproduces components-tabs: a Tabs.Root (defaultValue="account") whose List holds
-- three triggers; the "account" trigger is the at-rest active tab.
tabsPage :: forall w i. HH.HTML w i
tabsPage =
  tabsRoot []
    [ tabsList []
        [ tabsTrigger true [] [ HH.text "Account" ]
        , tabsTrigger false [] [ HH.text "Documents" ]
        , tabsTrigger false [] [ HH.text "Settings" ]
        ]
    ]

-- Reproduces components-table: a maxWidth:480 Box wrapping Table.Root with a
-- two-column header (Name/Email) and two body rows (RowHeaderCell + Cell).
tablePage :: forall w i. HH.HTML w i
tablePage =
  box [ StyleProp "max-width" "480px" ]
    [ tableRoot []
        [ tableHeader []
            [ tableRow []
                [ tableColumnHeaderCell [] [ HH.text "Name" ]
                , tableColumnHeaderCell [] [ HH.text "Email" ]
                ]
            ]
        , tableBody []
            [ tableRow []
                [ tableRowHeaderCell [] [ HH.text "Danilo" ]
                , tableCell [] [ HH.text "danilo@example.com" ]
                ]
            , tableRow []
                [ tableRowHeaderCell [] [ HH.text "Zahra" ]
                , tableCell [] [ HH.text "zahra@example.com" ]
                ]
            ]
        ]
    ]

-- Reproduces components-datalist: a horizontal DataList with two items (Status →
-- jade Badge "Authorized", Name → "Vlad Moroz").
datalistPage :: forall w i. HH.HTML w i
datalistPage =
  dataListRoot []
    [ dataListItem []
        [ dataListLabel [] [ HH.text "Status" ]
        , dataListValue []
            [ badge [ Color "jade" ] [ HH.text "Authorized" ] ]
        ]
    , dataListItem []
        [ dataListLabel [] [ HH.text "Name" ]
        , dataListValue [] [ HH.text "Vlad Moroz" ]
        ]
    ]
