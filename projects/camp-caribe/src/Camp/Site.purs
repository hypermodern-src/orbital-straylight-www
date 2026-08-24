module Camp.Site
  ( Language(..)
  , pageSlug
  , renderPage
  ) where

import Prelude

import Camp.Content (Capability, Fact, Localized, NavItem, Operation, Page, Photo, SiteData, Space, Use, Video)
import Data.Array (find, mapWithIndex)
import Data.Maybe (Maybe(..), maybe)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Runtime.SSG as SSG

data Language
  = English
  | Spanish

derive instance eqLanguage :: Eq Language

localized :: forall a. Language -> Localized a -> a
localized English value = value.en
localized Spanish value = value.es

languageCode :: Language -> String
languageCode English = "en"
languageCode Spanish = "es"

otherLanguage :: Language -> Language
otherLanguage English = Spanish
otherLanguage Spanish = English

pageSlug :: Language -> Page -> String
pageSlug language page = localized language page.slug

pagePath :: String -> String
pagePath "" = "/"
pagePath slug = "/" <> slug <> "/"

className :: forall r i. String -> HH.IProp r i
className value = HP.attr (HH.AttrName "class") value

attribute :: forall r i. String -> String -> HH.IProp r i
attribute name = HP.attr (HH.AttrName name)

element :: forall r w i. String -> Array (HH.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
element name = HH.element (HH.ElemName name)

renderPage :: SiteData -> Language -> Page -> String
renderPage siteData language page =
  SSG.renderPage (documentConfig siteData language) (pageMeta siteData language page)
    (siteView siteData language page)

documentConfig :: SiteData -> Language -> SSG.DocConfig
documentConfig siteData language =
  SSG.defaultDocConfig
    { lang = languageCode language
    , siteName = siteData.site.name
    , themeColor = Just "#071e2b"
    , favicon = Just "/favicon.svg"
    , stylesheets = [ "/style.css" ]
    , scripts = [ "/site.js" ]
    }

pageMeta :: SiteData -> Language -> Page -> SSG.PageMeta
pageMeta siteData language page =
  let
    slug = pageSlug language page
    path = pagePath slug
    title =
      if page.key == "home" then
        siteData.site.name <> " — " <> localized language page.title
      else
        localized language page.title <> " — " <> siteData.site.name
  in
    { title
    , description: localized language page.description
    , path: siteData.site.canonical <> path
    , ogImage: Just (siteData.site.canonical <> "/images/hero-aerial.webp")
    , canonicalUrl: Just (siteData.site.canonical <> path)
    }

siteView :: forall w i. SiteData -> Language -> Page -> HH.HTML w i
siteView siteData language page =
  HH.div
    [ className "camp-site"
    , attribute "data-page" page.key
    ]
    ( [ skipLink language
      , navigation siteData language page
      , HH.main
          [ HP.id "main-content" ]
          (case page.key of
            "venue" -> venueView siteData language
            "missions" -> missionsView siteData language
            "gallery" -> galleryView siteData language
            "contact" -> contactView siteData language
            _ -> homeView siteData language
          )
      , footerView siteData language
      ]
        <> if page.key == "gallery" then [ lightbox language ] else []
    )

skipLink :: forall w i. Language -> HH.HTML w i
skipLink language =
  HH.a
    [ HP.href "#main-content"
    , className "skip-link"
    ]
    [ HH.text (if language == English then "Skip to content" else "Saltar al contenido") ]

navigation :: forall w i. SiteData -> Language -> Page -> HH.HTML w i
navigation siteData language page =
  let
    other = otherLanguage language
    switchLabel = if language == English then "Español" else "English"
    contactHref = routeFor language siteData.nav "contact"
  in
    HH.header
      [ className "site-header"
      , attribute "data-site-header" ""
      ]
      [ HH.div
          [ className "header-inner" ]
          [ HH.a
              [ HP.href (routeFor language siteData.nav "home")
              , className "brand"
              , attribute "aria-label" (siteData.site.name <> " home")
              ]
              [ HH.img
                  [ HP.src "/images/camp-caribe-logo.webp"
                  , HP.alt siteData.site.name
                  , attribute "width" "214"
                  , attribute "height" "80"
                  ]
              ]
          , HH.div
              [ className "header-location" ]
              [ HH.span [ className "location-dot", attribute "aria-hidden" "true" ] []
              , HH.span_ [ HH.text "18.05° N" ]
              , HH.span [ className "header-location-name" ] [ HH.text (localized language siteData.site.location) ]
              ]
          , HH.button
              [ className "menu-toggle"
              , attribute "type" "button"
              , attribute "aria-expanded" "false"
              , attribute "aria-controls" "primary-navigation"
              , attribute "aria-label" (if language == English then "Open site navigation" else "Abrir navegación del sitio")
              , attribute "data-menu-open-label" (if language == English then "Open site navigation" else "Abrir navegación del sitio")
              , attribute "data-menu-close-label" (if language == English then "Close site navigation" else "Cerrar navegación del sitio")
              , attribute "data-menu-toggle" ""
              ]
              [ HH.span [ className "menu-label" ] [ HH.text (if language == English then "Explore" else "Explore") ]
              , HH.span [ className "menu-lines", attribute "aria-hidden" "true" ]
                  [ HH.span_ []
                  , HH.span_ []
                  ]
              ]
          , HH.nav
              [ HP.id "primary-navigation"
              , className "primary-nav"
              , attribute "aria-label" (if language == English then "Primary navigation" else "Navegación principal")
              , attribute "data-primary-nav" ""
              ]
              [ HH.div
                  [ className "nav-intro" ]
                  [ HH.span_ [ HH.text "CAMP / CARIBE" ]
                  , HH.p_ [ HH.text (if language == English then "One group. The whole coast." else "Un grupo. Toda la costa.") ]
                  ]
              , HH.div
                  [ className "nav-links" ]
                  (map (navLink language page) siteData.nav)
              , HH.div
                  [ className "nav-actions" ]
                  [ HH.a
                      [ HP.href (pagePath (pageSlug other page))
                      , className "language-link"
                      , attribute "lang" (languageCode other)
                      ]
                      [ HH.text switchLabel ]
                  , HH.a
                      [ HP.href contactHref
                      , className "button button-small button-sun"
                      ]
                      [ HH.span_ [ HH.text (if language == English then "Plan a stay" else "Planifique") ]
                      , HH.span [ className "button-arrow", attribute "aria-hidden" "true" ] [ HH.text "↗" ]
                      ]
                  ]
              ]
          ]
      , HH.div [ className "header-progress", attribute "aria-hidden" "true" ]
          [ HH.span [ attribute "data-scroll-progress" "" ] [] ]
      ]

navLink :: forall w i. Language -> Page -> NavItem -> HH.HTML w i
navLink language page item =
  HH.a
    ( [ HP.href (pagePath (localized language item.slug)) ]
        <> if page.key == item.key then
          [ className "is-active", attribute "aria-current" "page" ]
        else
          []
    )
    [ HH.span [ className "nav-index", attribute "aria-hidden" "true" ] [ HH.text (navIndex item.key) ]
    , HH.span_ [ HH.text (localized language item.label) ]
    ]

navIndex :: String -> String
navIndex key = case key of
  "home" -> "00"
  "venue" -> "01"
  "missions" -> "02"
  "gallery" -> "03"
  _ -> "04"

routeFor :: Language -> Array NavItem -> String -> String
routeFor language items key =
  maybe "/" (pagePath <<< localized language <<< _.slug) (find (_.key >>> (_ == key)) items)

homeView :: forall w i. SiteData -> Language -> Array (HH.HTML w i)
homeView siteData language =
  [ homeHero siteData language
  , factsView siteData.facts language
  , HH.section
      [ className "section section-intro"
      , attribute "data-reveal" ""
      ]
      [ HH.div [ className "section-rule" ] [ HH.text "00 / THE PREMISE" ]
      , HH.div [ className "intro-heading" ]
          [ eyebrow (localized language siteData.home.intro.eyebrow)
          , HH.h2_ [ HH.text (localized language siteData.home.intro.title) ]
          ]
      , HH.div [ className "intro-copy" ]
          [ HH.p_ [ HH.text (localized language siteData.home.intro.body) ]
          , textLink (routeFor language siteData.nav "venue")
              (if language == English then "Walk the property" else "Recorra la propiedad")
          ]
      , HH.figure [ className "intro-art" ]
          [ image "/images/shoreline-morning-black-sand.avif"
              (if language == English then "Black-sand shoreline at Camp Caribe" else "Costa de arena negra en Camp Caribe")
              "lazy"
          , HH.figcaption_
              [ HH.span_ [ HH.text "18.05° N" ]
              , HH.span_ [ HH.text (if language == English then "Black sand / Caribbean Sea" else "Arena negra / Mar Caribe") ]
              ]
          ]
      ]
  , HH.section
      [ className "statement"
      , attribute "data-reveal" ""
      ]
      [ HH.div [ className "statement-media" ]
          [ image "/images/shoreline-sunset-red.avif"
              (if language == English then "Sunset at the Camp Caribe shoreline" else "Atardecer en la costa de Camp Caribe")
              "lazy"
          , HH.span [ className "statement-coordinate" ] [ HH.text "SOUTH COAST / 18:42" ]
          ]
      , HH.div [ className "statement-copy" ]
          [ HH.span [ className "statement-index", attribute "aria-hidden" "true" ] [ HH.text "CC—01" ]
          , eyebrow (localized language siteData.home.statement.eyebrow)
          , HH.h2_ [ HH.text (localized language siteData.home.statement.title) ]
          , HH.p_ [ HH.text (localized language siteData.home.statement.body) ]
          ]
      ]
  , HH.section
      [ className "section section-capabilities" ]
      [ sectionHeading "01 / 04" (localized language siteData.home.capabilitiesEyebrow)
          (localized language siteData.home.capabilitiesTitle)
      , HH.div
          [ className "capability-grid" ]
          (map (capabilityCard language) siteData.home.capabilities)
      ]
  , HH.section
      [ className "section location-section"
      , attribute "data-reveal" ""
      ]
      [ HH.div [ className "location-image" ]
          [ image "/images/campus-entrance.avif"
              (if language == English then "Camp Caribe entrance" else "Entrada de Camp Caribe")
              "lazy"
          , HH.span [ className "image-coordinate" ] [ HH.text "18.05° N / 66.51° W" ]
          , HH.div [ className "location-crosshair", attribute "aria-hidden" "true" ] []
          ]
      , HH.div [ className "location-copy" ]
          [ sectionHeading "02 / 04" (localized language siteData.home.locationEyebrow)
              (localized language siteData.home.locationTitle)
          , HH.p_ [ HH.text (localized language siteData.home.locationBody) ]
          , textLink (routeFor language siteData.nav "contact")
              (if language == English then "Start a private briefing" else "Comience una consulta privada")
          ]
      ]
  , callout siteData language
  ]

homeHero :: forall w i. SiteData -> Language -> HH.HTML w i
homeHero siteData language =
  HH.section
    [ className "home-hero" ]
    [ element "picture"
        [ className "hero-picture" ]
        [ element "source"
            [ attribute "media" "(max-width: 700px)"
            , attribute "srcset" "/images/hero-aerial-mobile.webp"
            , attribute "type" "image/webp"
            ]
            []
        , element "source"
            [ attribute "srcset" "/images/hero-aerial.webp"
            , attribute "type" "image/webp"
            ]
            []
        , HH.img
            [ HP.src "/images/aerial-overview.avif"
            , HP.alt (if language == English then "Aerial view of Camp Caribe and the Caribbean coast" else "Vista aérea de Camp Caribe y la costa del mar Caribe")
            , attribute "loading" "eager"
            , attribute "decoding" "async"
            , attribute "fetchpriority" "high"
            ]
        ]
    , HH.div [ className "hero-overlay" ] []
    , HH.div [ className "hero-grid", attribute "aria-hidden" "true" ] []
    , HH.div [ className "hero-sun", attribute "aria-hidden" "true" ] []
    , HH.div
        [ className "hero-content" ]
        [ HH.div [ className "hero-title-block" ]
            [ eyebrow (localized language siteData.home.hero.eyebrow)
            , heroTitle language
            ]
        , HH.div [ className "hero-brief" ]
            [ HH.p [ className "hero-deck" ] [ HH.text (localized language siteData.home.hero.deck) ]
            , HH.div [ className "hero-actions" ]
                [ HH.a
                    [ HP.href (routeFor language siteData.nav "contact")
                    , className "button button-sun"
                    ]
                    [ HH.span_ [ HH.text (localized language siteData.home.hero.primary) ]
                    , HH.span [ className "button-arrow", attribute "aria-hidden" "true" ] [ HH.text "↗" ]
                    ]
                , HH.a
                    [ HP.href (routeFor language siteData.nav "venue")
                    , className "button button-ghost"
                    ]
                    [ HH.text (localized language siteData.home.hero.secondary) ]
                ]
            ]
        ]
    , HH.div [ className "hero-register", attribute "aria-hidden" "true" ]
        [ HH.span_ [ HH.text (if language == English then "PRIVATE COASTAL CAMPUS" else "CAMPUS COSTERO PRIVADO") ]
        , HH.span [ className "hero-scroll" ]
            [ HH.text (if language == English then "Enter the property" else "Entre a la propiedad")
            , HH.span_ [ HH.text "↓" ]
            ]
        ]
    ]

heroTitle :: forall w i. Language -> HH.HTML w i
heroTitle language =
  HH.h1
    [ className "hero-title" ]
    [ HH.span_ [ HH.text (if language == English then "The coast" else "La costa") ]
    , element "em" [] [ HH.text (if language == English then "is yours." else "es suya.") ]
    ]

factsView :: forall w i. Array Fact -> Language -> HH.HTML w i
factsView facts language =
  HH.section
    [ className "fact-band"
    , attribute "aria-label" (if language == English then "Venue facts" else "Datos del recinto")
    ]
    [ HH.div [ className "fact-intro" ]
        [ HH.span_ [ HH.text (if language == English then "PROPERTY / AT A GLANCE" else "PROPIEDAD / EN RESUMEN") ]
        , HH.p_ [ HH.text (if language == English then "A complete operating environment at the edge of the Caribbean." else "Un entorno operacional completo al borde del Caribe.") ]
        ]
    , HH.div [ className "fact-grid" ] (mapWithIndex (factView language) facts)
    ]

factView :: forall w i. Language -> Int -> Fact -> HH.HTML w i
factView language index fact =
  HH.div
    [ className "fact" ]
    [ HH.span [ className "fact-index" ] [ HH.text ("0" <> show (index + 1)) ]
    , HH.strong_ [ HH.text fact.value ]
    , HH.span_ [ HH.text (localized language fact.label) ]
    ]

venueView :: forall w i. SiteData -> Language -> Array (HH.HTML w i)
venueView siteData language =
  [ pageHero "01" (localized language siteData.venue.eyebrow)
      (localized language siteData.venue.title)
      (localized language siteData.venue.deck)
      "/images/campus-from-tower.avif"
      (if language == English then "Camp Caribe campus from the tower" else "Campus de Camp Caribe desde la torre")
  , HH.section
      [ className "section prose-section"
      , attribute "data-reveal" ""
      ]
      [ HH.div [ className "section-rule" ] [ HH.text "01 / OVERVIEW" ]
      , HH.h2_ [ HH.text (localized language siteData.venue.introTitle) ]
      , HH.div [ className "prose-columns" ]
          (map (\paragraph -> HH.p_ [ HH.text paragraph ]) (localized language siteData.venue.introBody))
      ]
  , HH.section
      [ className "section spaces-section" ]
      [ sectionHeading "02 / INVENTORY" (localized language siteData.venue.spacesEyebrow)
          (localized language siteData.venue.spacesTitle)
      , HH.div [ className "space-list" ] (map (spaceView language) siteData.venue.spaces)
      ]
  , HH.section
      [ className "section operations-section" ]
      [ sectionHeading "03 / POSITION" (localized language siteData.venue.operationsEyebrow)
          (localized language siteData.venue.operationsTitle)
      , HH.div [ className "operation-grid" ] (mapWithIndex (operationView language) siteData.venue.operations)
      ]
  , callout siteData language
  ]

spaceView :: forall w i. Language -> Space -> HH.HTML w i
spaceView language space =
  HH.article
    [ className "space-row"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "space-media" ]
        [ image ("/images/" <> space.image) (localized language space.alt) "lazy" ]
    , HH.div [ className "space-copy" ]
        [ HH.span [ className "space-index" ] [ HH.text space.index ]
        , HH.h3_ [ HH.text (localized language space.title) ]
        , HH.p_ [ HH.text (localized language space.body) ]
        ]
    ]

operationView :: forall w i. Language -> Int -> Operation -> HH.HTML w i
operationView language index operation =
  HH.article
    [ className "operation-card"
    , attribute "data-reveal" ""
    ]
    [ HH.span [ className "operation-index" ] [ HH.text ("0" <> show (index + 1)) ]
    , HH.h3_ [ HH.text (localized language operation.title) ]
    , HH.p_ [ HH.text (localized language operation.body) ]
    ]

missionsView :: forall w i. SiteData -> Language -> Array (HH.HTML w i)
missionsView siteData language =
  [ pageHero "02" (localized language siteData.missions.eyebrow)
      (localized language siteData.missions.title)
      (localized language siteData.missions.deck)
      "/images/parade-grounds.avif"
      (if language == English then "Open grounds at Camp Caribe" else "Terrenos abiertos de Camp Caribe")
  , HH.section
      [ className "section prose-section compact"
      , attribute "data-reveal" ""
      ]
      [ HH.div [ className "section-rule" ] [ HH.text "01 / FORMAT" ]
      , HH.h2_ [ HH.text (localized language siteData.missions.introTitle) ]
      , HH.p [ className "prose-lead" ] [ HH.text (localized language siteData.missions.introBody) ]
      ]
  , HH.section
      [ className "section use-section" ]
      [ HH.div [ className "use-grid" ] (map (useView language) siteData.missions.uses) ]
  , HH.section
      [ className "closing-panel"
      , attribute "data-reveal" ""
      ]
      [ HH.span [ className "closing-index" ] [ HH.text "06 / NEXT" ]
      , HH.h2_ [ HH.text (localized language siteData.missions.closingTitle) ]
      , HH.p_ [ HH.text (localized language siteData.missions.closingBody) ]
      , HH.a
          [ HP.href (routeFor language siteData.nav "contact")
          , className "button button-ink"
          ]
          [ HH.text (if language == English then "Request the property brief" else "Solicite la ficha de la propiedad") ]
      ]
  ]

useView :: forall w i. Language -> Use -> HH.HTML w i
useView language use =
  HH.article
    [ className "use-card"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "use-media" ]
        [ image ("/images/" <> use.image) (localized language use.alt) "lazy" ]
    , HH.div [ className "use-copy" ]
        [ HH.span [ className "use-index" ] [ HH.text use.index ]
        , HH.h2_ [ HH.text (localized language use.title) ]
        , HH.p_ [ HH.text (localized language use.body) ]
        ]
    ]

galleryView :: forall w i. SiteData -> Language -> Array (HH.HTML w i)
galleryView siteData language =
  [ pageHero "03" (localized language siteData.gallery.eyebrow)
      (localized language siteData.gallery.title)
      (localized language siteData.gallery.deck)
      "/images/shoreline-sunset-red.avif"
      (if language == English then "Caribbean sunset from Camp Caribe" else "Atardecer caribeño desde Camp Caribe")
  , HH.section
      [ className "section video-section" ]
      [ sectionHeading "01 / MOTION" (localized language siteData.gallery.videoEyebrow)
          (localized language siteData.gallery.videoTitle)
      , HH.div [ className "video-grid" ] (map (videoView language) siteData.gallery.videos)
      ]
  , HH.section
      [ className "section photo-section" ]
      [ sectionHeading "02 / STILLS" (localized language siteData.gallery.photoEyebrow)
          (localized language siteData.gallery.photoTitle)
      , HH.div [ className "photo-grid" ] (mapWithIndex (photoView language) siteData.gallery.photos)
      ]
  , callout siteData language
  ]

videoView :: forall w i. Language -> Video -> HH.HTML w i
videoView language video =
  HH.figure
    [ className "video-card"
    , attribute "data-reveal" ""
    ]
    [ HH.video
        [ HP.src ("/video/" <> video.source)
        , HP.controls true
        , attribute "preload" "metadata"
        , attribute "playsinline" ""
        , attribute "poster" ("/images/" <> video.poster)
        ]
        [ HH.text (if language == English then "Your browser cannot play this video." else "Su navegador no puede reproducir este video.") ]
    , HH.figcaption_ [ HH.text (localized language video.title) ]
    ]

photoView :: forall w i. Language -> Int -> Photo -> HH.HTML w i
photoView language index photo =
  HH.button
    [ className ("photo-card photo-card-" <> show ((index `mod` 7) + 1))
    , attribute "type" "button"
    , attribute "data-lightbox-src" ("/images/" <> photo.image)
    , attribute "data-lightbox-alt" (localized language photo.label)
    , attribute "data-reveal" ""
    ]
    [ image ("/images/" <> photo.image) (localized language photo.label) "lazy"
    , HH.span [ className "photo-caption" ]
        [ HH.span [ className "photo-number" ] [ HH.text (padIndex (index + 1)) ]
        , HH.span_ [ HH.text (localized language photo.label) ]
        ]
    ]

padIndex :: Int -> String
padIndex index = if index < 10 then "0" <> show index else show index

contactView :: forall w i. SiteData -> Language -> Array (HH.HTML w i)
contactView siteData language =
  [ pageHero "04" (localized language siteData.contact.eyebrow)
      (localized language siteData.contact.title)
      (localized language siteData.contact.deck)
      "/images/campus-entrance.avif"
      (if language == English then "Camp Caribe entrance and campus" else "Entrada y campus de Camp Caribe")
  , HH.section
      [ className "section contact-section" ]
      [ HH.div
          [ className "direct-contact"
          , attribute "data-reveal" ""
          ]
          [ HH.span [ className "section-rule" ] [ HH.text "01 / DIRECT" ]
          , HH.h2_ [ HH.text (localized language siteData.contact.directTitle) ]
          , HH.p_ [ HH.text (localized language siteData.contact.directBody) ]
          , HH.div [ className "contact-methods" ]
              [ HH.a [ HP.href ("tel:" <> siteData.site.phoneHref) ]
                  [ HH.span_ [ HH.text (if language == English then "Call" else "Llame") ]
                  , HH.strong_ [ HH.text siteData.site.phoneDisplay ]
                  ]
              , HH.a [ HP.href ("mailto:" <> siteData.site.email) ]
                  [ HH.span_ [ HH.text (if language == English then "Write" else "Escriba") ]
                  , HH.strong_ [ HH.text siteData.site.email ]
                  ]
              ]
          , HH.div [ className "arrival-note" ]
              [ HH.h3_ [ HH.text (localized language siteData.contact.arrivalTitle) ]
              , HH.p_ [ HH.text (localized language siteData.contact.arrivalBody) ]
              ]
          ]
      , briefingForm siteData language
      ]
  ]

briefingForm :: forall w i. SiteData -> Language -> HH.HTML w i
briefingForm siteData language =
  HH.div
    [ className "briefing-panel"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "briefing-heading" ]
        [ HH.span [ className "section-rule" ] [ HH.text "02 / BRIEF" ]
        , HH.h2_ [ HH.text (localized language siteData.contact.formTitle) ]
        , HH.p_ [ HH.text (localized language siteData.contact.formBody) ]
        ]
    , HH.form
        [ HP.id "briefing-form"
        , className "briefing-form"
        , attribute "action" ("mailto:" <> siteData.site.email)
        , attribute "method" "get"
        , attribute "data-recipient" siteData.site.email
        , attribute "data-language" (languageCode language)
        ]
        [ HH.div [ className "form-grid" ]
            [ formField "name" "text" (localized language siteData.contact.fields.name) "name" true
            , formField "organization" "text" (localized language siteData.contact.fields.organization) "organization" false
            , formField "email" "email" (localized language siteData.contact.fields.email) "email" true
            , formField "phone" "tel" (localized language siteData.contact.fields.phone) "tel" false
            , formField "group-size" "number" (localized language siteData.contact.fields.groupSize) "off" true
            , formField "dates" "text" (localized language siteData.contact.fields.dates) "off" true
            ]
        , element "label" [ className "field field-wide" ]
            [ HH.span_ [ HH.text (localized language siteData.contact.fields.purpose) ]
            , HH.select
                [ HP.id "purpose"
                , HP.name "purpose"
                , attribute "required" ""
                ]
                (mapWithIndex purposeOption (localized language siteData.contact.purposeOptions))
            ]
        , element "label" [ className "field field-wide" ]
            [ HH.span_ [ HH.text (localized language siteData.contact.fields.message) ]
            , HH.textarea
                [ HP.id "message"
                , HP.name "message"
                , attribute "rows" "5"
                ]
            ]
        , HH.button
            [ className "button button-sun form-submit"
            , attribute "type" "submit"
            ]
            [ HH.text (localized language siteData.contact.fields.submit) ]
        , HH.p
            [ className "form-status"
            , attribute "data-form-status" ""
            , attribute "aria-live" "polite"
            ]
            []
        ]
    ]

formField :: forall w i. String -> String -> String -> String -> Boolean -> HH.HTML w i
formField fieldId fieldType label autocomplete required =
  element "label" [ className "field" ]
    [ HH.span_ [ HH.text label ]
    , HH.input
        ( [ HP.id fieldId
          , HP.name fieldId
          , attribute "type" fieldType
          , attribute "autocomplete" autocomplete
          ]
            <> if required then [ attribute "required" "" ] else []
        )
    ]

purposeOption :: forall w i. Int -> String -> HH.HTML w i
purposeOption index option =
  HH.option
    ( [ HP.value (if index == 0 then "" else option) ]
        <> if index == 0 then [ attribute "disabled" "", attribute "selected" "" ] else []
    )
    [ HH.text option ]

pageHero :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
pageHero index label title deck source alt =
  HH.section
    [ className "page-hero" ]
    [ HH.div [ className "page-hero-content" ]
        [ HH.span [ className "page-index" ] [ HH.text ("CC—" <> index) ]
        , eyebrow label
        , HH.h1_ [ HH.text title ]
        , HH.p_ [ HH.text deck ]
        , HH.div [ className "page-hero-register", attribute "aria-hidden" "true" ]
            [ HH.span_ [ HH.text "18.05° N" ]
            , HH.span_ [ HH.text "66.51° W" ]
            ]
        ]
    , HH.div [ className "page-hero-media" ]
        [ image source alt "eager"
        , HH.span [ className "page-hero-caption" ] [ HH.text (index <> " / CAMP CARIBE") ]
        ]
    , HH.div [ className "page-hero-grid", attribute "aria-hidden" "true" ] []
    ]

capabilityCard :: forall w i. Language -> Capability -> HH.HTML w i
capabilityCard language capability =
  HH.article
    [ className "capability-card"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "capability-media" ]
        [ image ("/images/" <> capability.image) (localized language capability.alt) "lazy" ]
    , HH.div [ className "capability-copy" ]
        [ HH.span [ className "capability-index" ] [ HH.text capability.index ]
        , HH.h3_ [ HH.text (localized language capability.title) ]
        , HH.p_ [ HH.text (localized language capability.body) ]
        ]
    ]

sectionHeading :: forall w i. String -> String -> String -> HH.HTML w i
sectionHeading index label title =
  HH.div
    [ className "section-heading"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "section-rule" ] [ HH.text index ]
    , HH.div_
        [ eyebrow label
        , HH.h2_ [ HH.text title ]
        ]
    ]

eyebrow :: forall w i. String -> HH.HTML w i
eyebrow label =
  HH.p
    [ className "eyebrow" ]
    [ HH.span [ attribute "aria-hidden" "true" ] []
    , HH.text label
    ]

image :: forall w i. String -> String -> String -> HH.HTML w i
image source alt loading =
  HH.img
    [ HP.src source
    , HP.alt alt
    , attribute "loading" loading
    , attribute "decoding" "async"
    ]

textLink :: forall w i. String -> String -> HH.HTML w i
textLink href label =
  HH.a
    [ HP.href href
    , className "text-link"
    ]
    [ HH.span_ [ HH.text label ]
    , HH.span [ attribute "aria-hidden" "true" ] [ HH.text "↗" ]
    ]

callout :: forall w i. SiteData -> Language -> HH.HTML w i
callout siteData language =
  HH.section
    [ className "callout"
    , attribute "data-reveal" ""
    ]
    [ HH.div [ className "callout-orbit", attribute "aria-hidden" "true" ]
        [ HH.span_ [ HH.text "18" ]
        , HH.span_ [ HH.text "N" ]
        ]
    , HH.div [ className "callout-register", attribute "aria-hidden" "true" ] [ HH.text "CC / 18.05 N / 66.51 W" ]
    , HH.div [ className "callout-copy" ]
        [ eyebrow (if language == English then "Your dates. Your people. Your coast." else "Sus fechas. Su gente. Su costa.")
        , HH.h2_ [ HH.text (if language == English then "Make the first call." else "Comience la conversación.") ]
        ]
    , HH.a
        [ HP.href (routeFor language siteData.nav "contact")
        , className "button button-ink"
        ]
        [ HH.span_ [ HH.text (if language == English then "Request a private briefing" else "Solicite una consulta privada") ]
        , HH.span [ className "button-arrow", attribute "aria-hidden" "true" ] [ HH.text "↗" ]
        ]
    ]

footerView :: forall w i. SiteData -> Language -> HH.HTML w i
footerView siteData language =
  HH.footer
    [ className "site-footer" ]
    [ HH.div [ className "footer-wordmark", attribute "aria-hidden" "true" ]
        [ HH.span_ [ HH.text "CAMP" ]
        , element "em" [] [ HH.text "CARIBE" ]
        ]
    , HH.div [ className "footer-main" ]
        [ HH.div [ className "footer-brand" ]
            [ HH.img
                [ HP.src "/images/camp-caribe-logo.webp"
                , HP.alt siteData.site.name
                , attribute "width" "294"
                , attribute "height" "110"
                ]
            , HH.p [ className "footer-tagline" ] [ HH.text (localized language siteData.footer.tagline) ]
            , HH.p_ [ HH.text (localized language siteData.footer.summary) ]
            ]
        , HH.div [ className "footer-nav" ]
            [ HH.p [ className "footer-label" ] [ HH.text (if language == English then "Navigate" else "Navegue") ]
            , HH.div_ (map (\item -> HH.a [ HP.href (pagePath (localized language item.slug)) ] [ HH.text (localized language item.label) ]) siteData.nav)
            ]
        , HH.address_
            [ HH.p [ className "footer-label" ] [ HH.text (if language == English then "Direct" else "Directo") ]
            , HH.p_ [ HH.text (localized language siteData.site.location) ]
            , HH.a [ HP.href ("tel:" <> siteData.site.phoneHref) ] [ HH.text siteData.site.phoneDisplay ]
            , HH.a [ HP.href ("mailto:" <> siteData.site.email) ] [ HH.text siteData.site.email ]
            ]
        ]
    , HH.div [ className "footer-bottom" ]
        [ HH.p_ [ HH.text ("© 2026 " <> siteData.site.name <> ". " <> localized language siteData.footer.rights) ]
        , HH.p_ [ HH.text "18.05° N / JUANA DÍAZ / PUERTO RICO / CARIBBEAN SEA" ]
        ]
    ]

lightbox :: forall w i. Language -> HH.HTML w i
lightbox language =
  element "dialog"
    [ HP.id "gallery-lightbox"
    , className "lightbox"
    , attribute "aria-label" (if language == English then "Expanded photograph" else "Fotografía ampliada")
    ]
    [ HH.button
        [ className "lightbox-close"
        , attribute "type" "button"
        , attribute "data-lightbox-close" ""
        ]
        [ HH.text (if language == English then "Close" else "Cerrar") ]
    , HH.img
        [ HP.src "/images/aerial-overview.avif"
        , HP.alt ""
        , attribute "loading" "lazy"
        , attribute "data-lightbox-image" ""
        ]
    , HH.p [ className "lightbox-caption", attribute "data-lightbox-caption" "" ] []
    ]
