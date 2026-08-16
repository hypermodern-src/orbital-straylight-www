module Orbital.SSG (main, renderRoute) where

import Prelude

import Data.Foldable (traverse_)
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Pattern (Pattern(..), Replacement(..))
import Effect (Effect)
import Effect.Console (log)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Runtime.Router (routeDescription, routeTitle)
import Hydrogen.Runtime.SSG as SSG
import Orbital.Layout as Layout
import Orbital.Pages.About as About
import Orbital.Pages.Build as Build
import Orbital.Pages.Cache as Cache
import Orbital.Pages.Index as Index
import Orbital.Pages.Pricing as Pricing
import Orbital.Pages.Thanks as Thanks
import Orbital.Pages.Verification as Verification
import Orbital.Route (Route(..), allRoutes, canonicalUrl, fileName, pageStylesheet)
import Orbital.SSG.Node (mkdirp, outputDirectory, writeTextFile)

main :: Effect Unit
main = do
  output <- outputDirectory
  mkdirp output
  traverse_ (writeRoute output) allRoutes
  log "orbital-ssg: rendered 7 routes"

writeRoute :: String -> Route -> Effect Unit
writeRoute output route = do
  let destination = output <> "/" <> fileName route
  writeTextFile destination (renderRoute route)
  log ("orbital-ssg: " <> destination)

renderRoute :: Route -> String
renderRoute route =
  String.replace
    (Pattern "<body>")
    (Replacement "<body class=\"grain\" data-ambient>")
    (SSG.renderPage (docConfig route) (pageMeta route) (Layout.page route (content route)))

docConfig :: Route -> SSG.DocConfig
docConfig route =
  SSG.defaultDocConfig
    { siteName = "Orbital"
    , favicon = Just "favicon.svg"
    , stylesheets =
        [ "fonts.css"
        , "halogen-orbital/orbital.css"
        , "waitlist.css"
        , pageStylesheet route
        ]
    , scripts = routeScripts route
    , extraHead = preloadFonts
    }

pageMeta :: Route -> SSG.PageMeta
pageMeta route =
  { title: routeTitle route
  , description: routeDescription route
  , path: canonicalUrl route
  , ogImage: Nothing
  , canonicalUrl: Just (canonicalUrl route)
  }

content :: forall w i. Route -> HH.HTML w i
content Overview = Index.content
content Cache = Cache.content
content Build = Build.content
content Pricing = Pricing.content
content Verification = Verification.content
content About = About.content
content Thanks = Thanks.content

routeScripts :: Route -> Array String
routeScripts route =
  [ "halogen-orbital/orbital.js" ]
    <> waitlistScript route
    <> productScript route
    <> thanksScript route
    <> [ "halogen-orbital/orbital-theme.js" ]

waitlistScript :: Route -> Array String
waitlistScript Overview = [ "waitlist.js" ]
waitlistScript Cache = [ "waitlist.js" ]
waitlistScript Build = [ "waitlist.js" ]
waitlistScript Thanks = [ "waitlist.js" ]
waitlistScript _ = []

productScript :: Route -> Array String
productScript Cache = [ "scripts/product.js" ]
productScript Build = [ "scripts/product.js" ]
productScript _ = []

thanksScript :: Route -> Array String
thanksScript Thanks = [ "scripts/thanks.js" ]
thanksScript _ = []

preloadFonts :: Array HH.PlainHTML
preloadFonts =
  [ HH.link
      [ HP.rel "preload"
      , HP.href "fonts/CormorantGaramond-normal-300-latin.woff2"
      , HP.attr (HH.AttrName "as") "font"
      , HP.attr (HH.AttrName "type") "font/woff2"
      , HP.attr (HH.AttrName "crossorigin") ""
      ]
  , HH.link
      [ HP.rel "preload"
      , HP.href "fonts/IBMPlexMono-normal-400-latin.woff2"
      , HP.attr (HH.AttrName "as") "font"
      , HP.attr (HH.AttrName "type") "font/woff2"
      , HP.attr (HH.AttrName "crossorigin") ""
      ]
  ]
