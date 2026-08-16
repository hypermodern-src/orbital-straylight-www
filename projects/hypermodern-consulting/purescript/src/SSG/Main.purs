-- | Static generator: one document, the whole deck, readable without JS.
module SSG.Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Runtime.SSG as SSG
import Site.Deck as Deck
import Site.Types (initialState)
import SSG.Node (mkdirp, writeTextFile)

docConfig :: SSG.DocConfig
docConfig = SSG.defaultDocConfig
  { siteName = "Hypermodern LLC"
  , stylesheets =
      [ "https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;1,300;1,400&family=IBM+Plex+Mono:wght@400;500;600&display=swap"
      , "/orbital-deck.css"
      ]
  , scripts = [ "/deck.js" ]
  -- replay the persisted onosendai choice before first paint (the mock
  -- applies it from a body-end script; we do one better)
  , extraHead =
      [ HH.script []
          [ HH.text "try{var t=localStorage.getItem('orbital-theme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}" ]
      ]
  }

pageMeta :: SSG.PageMeta
pageMeta =
  { title: "Hypermodern LLC — Consulting for the technically serious"
  , description: "AI-native infrastructure consulting. We build alongside you — and we teach the methodology so it outlasts the engagement."
  , path: "/"
  , ogImage: Nothing
  , canonicalUrl: Nothing
  }

main :: Effect Unit
main = do
  mkdirp "dist"
  writeTextFile "dist/index.html" html
  log "ssg: dist/index.html"
  where
  html =
    SSG.renderPage docConfig pageMeta
      (HH.div [ HP.id "app" ] [ Deck.view initialState ])
