module Ponce.Site
  ( Language(..)
  , languageCode
  , pageSlug
  , renderPage
  ) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..), maybe)
import Data.String as String
import Data.String.Pattern (Pattern(..), Replacement(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Runtime.SSG as SSG
import Ponce.Content (Footer, Localized, NavItem, Page, Section, SiteData, Stat, Turn)
import Ponce.Track as Track

data Language
  = English
  | Spanish

derive instance eqLanguage :: Eq Language

languageCode :: Language -> String
languageCode English = "en"
languageCode Spanish = "es"

otherLanguage :: Language -> Language
otherLanguage English = Spanish
otherLanguage Spanish = English

localized :: forall a. Language -> Localized a -> a
localized English value = value.en
localized Spanish value = value.es

pageSlug :: Language -> Page -> String
pageSlug language page = localized language page.slug

assetRoot :: String -> String
assetRoot "" = "."
assetRoot slug = String.joinWith "/" (map (const "..") (String.split (Pattern "/") slug))

hrefFrom :: String -> String -> String
hrefFrom from to =
  assetRoot from <> "/" <> if to == "" then "" else to <> "/"

className :: forall r i. String -> HH.IProp r i
className value = HP.attr (HH.AttrName "class") value

attribute :: forall r i. String -> String -> HH.IProp r i
attribute name = HP.attr (HH.AttrName name)

element :: forall r w i. String -> Array (HH.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
element name = HH.element (HH.ElemName name)

renderPage :: SiteData -> Language -> Page -> String
renderPage siteData language page =
  SSG.renderPage (documentConfig siteData language page) (pageMeta siteData language page)
    (siteView siteData language page)

documentConfig :: SiteData -> Language -> Page -> SSG.DocConfig
documentConfig siteData language page =
  let
    slug = pageSlug language page
    root = assetRoot slug
  in
    SSG.defaultDocConfig
      { lang = languageCode language
      , siteName = siteData.site.name
      , themeColor = Just "#11100f"
      , stylesheets = [ root <> "/style.css" ]
      , scripts =
          [ root <> "/motion.js" ]
            <> if page.hero.gl then [ root <> "/hero-gl.js" ] else []
      }

pageMeta :: SiteData -> Language -> Page -> SSG.PageMeta
pageMeta siteData language page =
  let
    slug = pageSlug language page
    home = page.slug.en == ""
    title =
      if home then
        siteData.site.name <> " — " <> localized language siteData.site.tagline
      else
        localized language page.title <> " — " <> siteData.site.name
  in
    { title
    , description: localized language siteData.site.description
    , path: if slug == "" then "/" else "/" <> slug <> "/"
    , ogImage: Nothing
    , canonicalUrl: Nothing
    }

siteView :: forall w i. SiteData -> Language -> Page -> HH.HTML w i
siteView siteData language page =
  HH.div
    [ className "ponce-site" ]
    [ navigation siteData.nav language page
    , HH.main_
        ( [ hero language page ]
            <> (if page.slug.en == "" then [ statsView siteData.stats language ] else [])
            <> map (sectionView siteData language (pageSlug language page)) page.sections
        )
    , footerView siteData.footer language
    ]

navigation :: forall w i. Array NavItem -> Language -> Page -> HH.HTML w i
navigation navItems language page =
  let
    slug = pageSlug language page
    homeSlug = if language == English then "" else "es"
    other = otherLanguage language
  in
    HH.header
      [ className "nav" ]
      [ HH.a
          [ HP.href (hrefFrom slug homeSlug)
          , className "brand"
          ]
          [ HH.text "PONCE "
          , HH.span_ [ HH.text "International Speedway" ]
          ]
      , HH.nav_
          ( map (navLink language slug page) navItems
              <> [ HH.a
                    [ HP.href (hrefFrom slug (pageSlug other page))
                    , className "lang"
                    ]
                    [ HH.text (if other == Spanish then "ES" else "EN") ]
                ]
          )
      ]

navLink :: forall w i. Language -> String -> Page -> NavItem -> HH.HTML w i
navLink language currentSlug page item =
  let
    target = localized language item.slug
    properties =
      [ HP.href (hrefFrom currentSlug target) ]
        <> if pageSlug language page == target then [ className "active" ] else []
  in
    HH.a properties [ HH.text (localized language item.label) ]

hero :: forall w i. Language -> Page -> HH.HTML w i
hero language page =
  let
    root = assetRoot (pageSlug language page)
  in
    HH.div
      [ className "hero" ]
      [ HH.div
          [ className "hero-bg"
          , HP.style ("background-image:url('" <> root <> "/images/" <> page.hero.image <> "')")
          ]
          []
      , HH.div
          [ className "hero-inner" ]
          [ HH.div [ className "kicker" ] [ HH.text (localized language page.hero.kicker) ]
          , HH.h1_ [ HH.text (localized language page.heroHeadline) ]
          , HH.p_ [ HH.text (localized language page.heroSub) ]
          ]
      ]

statsView :: forall w i. Array Stat -> Language -> HH.HTML w i
statsView stats language =
  HH.section
    [ className "stats" ]
    ( map
        ( \stat ->
            HH.div
              [ className "stat" ]
              [ HH.div [ className "value" ] [ HH.text stat.value ]
              , HH.div [ className "label" ] [ HH.text (localized language stat.label) ]
              ]
        )
        stats
    )

sectionView :: forall w i. SiteData -> Language -> String -> Section -> HH.HTML w i
sectionView siteData language slug section = case section.quote of
  Just quote ->
    HH.section
      [ className "quoteband" ]
      [ HH.blockquote_ [ HH.text ("“" <> localized language quote <> "”") ] ]
  Nothing ->
    let
      body = sectionContents siteData language slug section
    in
      case section.image of
        Just image ->
          HH.section
            [ className "split" ]
            [ HH.div [ className "split-text" ] body
            , HH.div
                [ className "split-image"
                , HP.style ("background-image:url('" <> assetRoot slug <> "/images/" <> image <> "')")
                ]
                []
            ]
        Nothing -> HH.section_ body

sectionContents :: forall w i. SiteData -> Language -> String -> Section -> Array (HH.HTML w i)
sectionContents siteData language slug section =
  maybe [] (\heading -> [ HH.h2_ [ HH.text (localized language heading) ] ]) section.heading
    <> maybe [] (paragraphs <<< localized language) section.body
    <> maybe [] (\items -> [ listView (localized language items) ]) section.list
    <> maybe [] (\specs -> [ specsView language specs ]) section.specs
    <> maybe [] (\entries -> [ timelineView language entries ]) section.timeline
    <> maybe [] (map (faqView language)) section.faq
    <> if section.map then [ Track.trackMap (languageCode language) ] else []
    <> if section.turns then [ turnsView siteData.turns language ] else []
    <> maybe [] (\contact -> [ contactView contact.email contact.phone ]) section.contact
    <> maybe [] (\cta -> [ ctaView language slug cta ]) section.cta
    <> if section.signup then [ signupView language ] else []
    <> maybe [] (\cards -> [ cardsView language slug cards ]) section.cards

paragraphs :: forall w i. String -> Array (HH.HTML w i)
paragraphs value =
  map (\paragraph -> HH.p_ [ HH.text (String.trim paragraph) ])
    (String.split (Pattern "\n\n") (String.trim value))

listView :: forall w i. Array String -> HH.HTML w i
listView items = HH.ul_ (map (\item -> HH.li_ [ HH.text item ]) items)

specsView :: forall w i. Language -> Array { k :: Localized String, v :: Localized String } -> HH.HTML w i
specsView language specs =
  HH.dl
    [ className "specs" ]
    ( map
        ( \spec ->
            HH.div_
              [ HH.dt_ [ HH.text (localized language spec.k) ]
              , HH.dd_ [ HH.text (localized language spec.v) ]
              ]
        )
        specs
    )

timelineView
  :: forall w i
   . Language
  -> Array { when :: Localized String, what :: Localized String }
  -> HH.HTML w i
timelineView language entries =
  HH.ol
    [ className "timeline" ]
    ( map
        ( \entry ->
            HH.li_
              [ HH.div [ className "when" ] [ HH.text (localized language entry.when) ]
              , HH.div [ className "what" ] [ HH.text (localized language entry.what) ]
              ]
        )
        entries
    )

faqView
  :: forall w i
   . Language
  -> { q :: Localized String, a :: Localized String }
  -> HH.HTML w i
faqView language faq =
  element "details" [ className "faq" ]
    [ element "summary" [] [ HH.text (localized language faq.q) ]
    , HH.p_ [ HH.text (localized language faq.a) ]
    ]

turnsView :: forall w i. Array Turn -> Language -> HH.HTML w i
turnsView turns language =
  HH.ol
    [ className "turns" ]
    ( mapWithIndex
        ( \index turn ->
            HH.li_
              [ HH.div
                  [ className "turn-head" ]
                  [ HH.span [ className "turn-no" ] [ HH.text (show (index + 1)) ]
                  , HH.h3_ [ HH.text turn.name ]
                  ]
              , HH.p_ [ HH.text (localized language turn.desc) ]
              ]
        )
        turns
    )

contactView :: forall w i. String -> String -> HH.HTML w i
contactView email phone =
  HH.p
    [ className "contact" ]
    [ HH.a [ HP.href ("mailto:" <> email) ] [ HH.text email ]
    , HH.text " · "
    , HH.a [ HP.href ("tel:+1" <> phoneDigits phone) ] [ HH.text phone ]
    ]

phoneDigits :: String -> String
phoneDigits =
  String.replaceAll (Pattern "-") (Replacement "")
    <<< String.replaceAll (Pattern " ") (Replacement "")
    <<< String.replaceAll (Pattern ")") (Replacement "")
    <<< String.replaceAll (Pattern "(") (Replacement "")

ctaView
  :: forall w i
   . Language
  -> String
  -> { label :: Localized String, slug :: Localized String }
  -> HH.HTML w i
ctaView language slug cta =
  HH.p_
    [ HH.a
        [ HP.href (hrefFrom slug (localized language cta.slug))
        , className "button"
        ]
        [ HH.text (localized language cta.label) ]
    ]

signupView :: forall w i. Language -> HH.HTML w i
signupView language =
  HH.form
    [ className "signup"
    , attribute "action" "mailto:info@poncespeedway.com"
    , attribute "method" "get"
    ]
    [ HH.input
        [ attribute "type" "email"
        , attribute "name" "email"
        , HP.placeholder (if language == English then "Email address" else "Correo electrónico")
        , attribute "required" ""
        ]
    , HH.button
        [ className "button"
        , attribute "type" "submit"
        ]
        [ HH.text (if language == English then "Sign Up" else "Regístrate") ]
    ]

cardsView
  :: forall w i
   . Language
  -> String
  -> Array
       { title :: Localized String
       , text :: Localized String
       , slug :: Maybe (Localized String)
       }
  -> HH.HTML w i
cardsView language slug cards =
  HH.div
    [ className "cards" ]
    ( map
        ( \card ->
            let
              content =
                [ HH.h3_ [ HH.text (localized language card.title) ]
                , HH.p_ [ HH.text (localized language card.text) ]
                ]
            in
              case card.slug of
                Just target ->
                  HH.a
                    [ className "card"
                    , HP.href (hrefFrom slug (localized language target))
                    ]
                    content
                Nothing -> HH.div [ className "card" ] content
        )
        cards
    )

footerView :: forall w i. Footer -> Language -> HH.HTML w i
footerView footer language =
  HH.footer_
    [ HH.p_ [ HH.text (localized language footer.blurb) ]
    , HH.div
        [ className "powered" ]
        ( map
            ( \partner ->
                HH.div_
                  [ HH.strong_ [ HH.text partner.name ]
                  , HH.br_
                  , HH.text partner.line
                  ]
            )
            footer.poweredBy
        )
    , HH.p
        [ className "fine" ]
        [ HH.text "© 2026 PONCE International Speedway Park · Ponce, Puerto Rico" ]
    ]
