module Orbital.Route
  ( Route(..)
  , allRoutes
  , fileName
  , canonicalUrl
  , pageStylesheet
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Hydrogen.Runtime.Router (class IsRoute, class RouteMetadata)

data Route
  = Overview
  | Cache
  | Build
  | Infer
  | Pricing
  | Verification
  | Journal
  | Papers
  | Publication
  | About
  | Thanks

derive instance eqRoute :: Eq Route

allRoutes :: Array Route
allRoutes =
  [ Overview
  , Cache
  , Build
  , Infer
  , Pricing
  , Verification
  , Journal
  , Papers
  , Publication
  , About
  , Thanks
  ]

fileName :: Route -> String
fileName Overview = "index.html"
fileName Cache = "cache.html"
fileName Build = "build.html"
fileName Infer = "infer.html"
fileName Pricing = "pricing.html"
fileName Verification = "verification.html"
fileName Journal = "journal.html"
fileName Papers = "papers.html"
fileName Publication = "publication.html"
fileName About = "about.html"
fileName Thanks = "thanks.html"

pageStylesheet :: Route -> String
pageStylesheet Overview = "styles/pages/index.css"
pageStylesheet Cache = "styles/pages/cache.css"
pageStylesheet Build = "styles/pages/build.css"
pageStylesheet Infer = "styles/pages/infer.css"
pageStylesheet Pricing = "styles/pages/pricing.css"
pageStylesheet Verification = "styles/pages/verification.css"
pageStylesheet Journal = "styles/pages/publications.css"
pageStylesheet Papers = "styles/pages/publications.css"
pageStylesheet Publication = "styles/pages/publications.css"
pageStylesheet About = "styles/pages/about.css"
pageStylesheet Thanks = "styles/pages/thanks.css"

canonicalUrl :: Route -> String
canonicalUrl Overview = "https://orbital.foo/"
canonicalUrl route = "https://orbital.foo/" <> fileName route

instance isRouteRoute :: IsRoute Route where
  parseRoute "/" = Overview
  parseRoute "/index.html" = Overview
  parseRoute "/cache.html" = Cache
  parseRoute "/build.html" = Build
  parseRoute "/infer.html" = Infer
  parseRoute "/pricing.html" = Pricing
  parseRoute "/verification.html" = Verification
  parseRoute "/journal.html" = Journal
  parseRoute "/papers.html" = Papers
  parseRoute "/publication.html" = Publication
  parseRoute "/about.html" = About
  parseRoute "/thanks.html" = Thanks
  parseRoute _ = Overview

  routeToPath Overview = "/"
  routeToPath route = "/" <> fileName route

instance routeMetadataRoute :: RouteMetadata Route where
  isProtected _ = false
  isStaticRoute _ = true

  routeTitle Overview = "Orbital · Infrastructure that proves itself"
  routeTitle Cache = "CACHE · Verified binary storage · Orbital"
  routeTitle Build = "BUILD · The typed build system, and the platform behind it · Orbital"
  routeTitle Infer = "INFER · Native inference for language and diffusion models · Orbital"
  routeTitle Pricing = "Pricing · One subscription, every product · Orbital"
  routeTitle Verification = "Verification · For regulated and safety-critical teams · Orbital"
  routeTitle Journal = "Journal · Orbital"
  routeTitle Papers = "Research papers · Orbital"
  routeTitle Publication = "Publication · Orbital"
  routeTitle About = "About · Orbital"
  routeTitle Thanks = "You are on the list · Orbital"

  routeDescription Overview = "Orbital builds verified developer infrastructure: CACHE for binary storage, BUILD for typed builds, and INFER for native language and diffusion inference."
  routeDescription Cache = "ORBITAL CACHE is verified binary storage: a content-addressed artifact store that re-verifies every artifact each time it is fetched. Start free, no credit card."
  routeDescription Build = "ORBITAL BUILD is free to use. An Orbital account adds the platform: team-shared verified caching, scale, retention, and guarantees. Start free, upgrade on your own numbers."
  routeDescription Infer = "ORBITAL INFER is a native inference engine for language and diffusion models, with no Python runtime and a purpose-built binary protocol."
  routeDescription Pricing = "One Orbital subscription covers every product. Tiers gate throughput, retention, and enterprise controls, never which products you may use. Seats free, SSO included."
  routeDescription Verification = "Orbital's verification path for regulated and safety-critical software: machine-checked guarantees for teams whose specifications already exist. Founder-led. Talk to us."
  routeDescription Journal = "Engineering dispatches, product decisions, and field notes from the people building Orbital."
  routeDescription Papers = "Technical papers, specifications, and results behind Orbital's verified infrastructure."
  routeDescription Publication = "A publication from the Orbital journal and research archive."
  routeDescription About = "Orbital builds verified developer infrastructure in San Juan, Puerto Rico. Meet the team and see CACHE, BUILD, INFER, and the Orbital Confirm runner."
  routeDescription Thanks = "Your place on the Orbital early-access list is confirmed."

  routeOgImage _ = Nothing
