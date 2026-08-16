-- | Client-side routing using Hydrogen.Router
module Straylight.Router 
  ( Route(..)
  , ProductPage(..)
  , Product(..)
  , module Hydrogen.Router
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), stripPrefix)
import Hydrogen.Router (class IsRoute, class RouteMetadata, parseRoute, routeToPath, getPathname, pushState, onPopState, navigate, normalizeTrailingSlash, interceptLinks)

-- ============================================================
-- PRODUCT & PAGE TYPES
-- ============================================================

data Product
  = SensenetCache
  | SensenetBuild
  | SensenetConverge
  | SensenetConfirm
  | SensenetForge
  | SensenetPublish
  | OmegaCode
  | OmegaWork
  | OmegaProxy
  | OmegaBoost

derive instance eqProduct :: Eq Product

data ProductPage
  = ProductHome
  | ProductFeatures
  | ProductPricing
  | ProductDocs
  | ProductDashboard
  | ProductSettings
  | ProductLegal

derive instance eqProductPage :: Eq ProductPage

-- ============================================================
-- ROUTES
-- ============================================================

data Route
  = Home
  -- Product routes (10 products × 7 pages = 70 routes)
  | ProductRoute Product ProductPage
  -- Team pages
  | Team
  | Plan
  | Lean
  | Razorgirl
  | Software
  -- Community
  | Irc
  | Discord

derive instance eqRoute :: Eq Route

-- ============================================================
-- HELPERS
-- ============================================================

productBasePath :: Product -> String
productBasePath = case _ of
  SensenetCache -> "/sensenet/cache"
  SensenetBuild -> "/sensenet/build"
  SensenetConverge -> "/sensenet/converge"
  SensenetConfirm -> "/sensenet/confirm"
  SensenetForge -> "/sensenet/forge"
  SensenetPublish -> "/sensenet/publish"
  OmegaCode -> "/omega/code"
  OmegaWork -> "/omega/work"
  OmegaProxy -> "/omega/proxy"
  OmegaBoost -> "/omega/boost"

pageSuffix :: ProductPage -> String
pageSuffix = case _ of
  ProductHome -> ""
  ProductFeatures -> "/features"
  ProductPricing -> "/pricing"
  ProductDocs -> "/docs"
  ProductDashboard -> "/dashboard"
  ProductSettings -> "/settings"
  ProductLegal -> "/legal"

parseProductPage :: String -> Maybe ProductPage
parseProductPage = case _ of
  "" -> Just ProductHome
  "/features" -> Just ProductFeatures
  "/pricing" -> Just ProductPricing
  "/docs" -> Just ProductDocs
  "/dashboard" -> Just ProductDashboard
  "/settings" -> Just ProductSettings
  "/legal" -> Just ProductLegal
  rest -> 
    -- Handle sub-paths: /docs/*, /legal/*
    if hasPrefix "/docs/" rest then Just ProductDocs
    else if hasPrefix "/legal/" rest then Just ProductLegal
    else Nothing

hasPrefix :: String -> String -> Boolean
hasPrefix prefix str = case stripPrefix (Pattern prefix) str of
  Just _ -> true
  Nothing -> false

parseProduct :: String -> Maybe { product :: Product, rest :: String }
parseProduct path = 
  tryParse SensenetCache "/sensenet/cache"
  <|> tryParse SensenetBuild "/sensenet/build"
  <|> tryParse SensenetConverge "/sensenet/converge"
  <|> tryParse SensenetConfirm "/sensenet/confirm"
  <|> tryParse SensenetForge "/sensenet/forge"
  <|> tryParse SensenetPublish "/sensenet/publish"
  <|> tryParse OmegaCode "/omega/code"
  <|> tryParse OmegaWork "/omega/work"
  <|> tryParse OmegaProxy "/omega/proxy"
  <|> tryParse OmegaBoost "/omega/boost"
  where
  tryParse product prefix = 
    if path == prefix then Just { product, rest: "" }
    else case stripPrefix (Pattern (prefix <> "/")) path of
      Just rest -> Just { product, rest: "/" <> rest }
      Nothing -> Nothing

infixl 3 alt as <|>

alt :: forall a. Maybe a -> Maybe a -> Maybe a
alt (Just x) _ = Just x
alt Nothing y = y

-- ============================================================
-- ISROUTE INSTANCE
-- ============================================================

instance isRouteRoute :: IsRoute Route where
  parseRoute path = 
    let normalized = normalizeTrailingSlash path
    in case normalized of
      "/" -> Home
      "/team" -> Team
      "/team/plan" -> Plan
      "/team/plan/lean" -> Lean
      "/plan" -> Plan
      "/plan/lean" -> Lean
      "/razorgirl" -> Razorgirl
      "/software" -> Software
      "/irc" -> Irc
      "/discord" -> Discord
      _ -> case parseProduct normalized of
        Just { product, rest } -> case parseProductPage rest of
          Just page -> ProductRoute product page
          Nothing -> Home
        Nothing -> Home

  routeToPath = case _ of
    Home -> "/"
    ProductRoute product page -> productBasePath product <> pageSuffix page
    Team -> "/team"
    Plan -> "/team/plan"
    Lean -> "/team/plan/lean"
    Razorgirl -> "/razorgirl"
    Software -> "/software"
    Irc -> "/irc"
    Discord -> "/discord"

-- ============================================================
-- ROUTE METADATA (for SSG support)
-- ============================================================

productName :: Product -> String
productName = case _ of
  SensenetCache -> "sensenet//cache"
  SensenetBuild -> "sensenet//build"
  SensenetConverge -> "sensenet//converge"
  SensenetConfirm -> "sensenet//confirm"
  SensenetForge -> "sensenet//forge"
  SensenetPublish -> "sensenet//publish"
  OmegaCode -> "omega//code"
  OmegaWork -> "omega//work"
  OmegaProxy -> "omega//proxy"
  OmegaBoost -> "omega//boost"

productTagline :: Product -> String
productTagline = case _ of
  SensenetCache -> "Attestation-aware Binary Cache"
  SensenetBuild -> "Typed Build System"
  SensenetConverge -> "Typed Infrastructure-as-Code"
  SensenetConfirm -> "CI with Proof Obligations"
  SensenetForge -> "Code Hosting + Review"
  SensenetPublish -> "Scope-graph Documentation"
  OmegaCode -> "Native Terminal AI Coding Agent"
  OmegaWork -> "Desktop AI for Teams"
  OmegaProxy -> "Verified Inference Proxy"
  OmegaBoost -> "Managed Inference"

productDescription :: Product -> String
productDescription = case _ of
  SensenetCache -> "Attestation-aware binary cache & artifact store. Content-addressed. Post-quantum signatures."
  SensenetBuild -> "Typed build system with formal verification. Dhall configs. Lean4-proven derivations."
  SensenetConverge -> "Typed infrastructure-as-code. Desired-state convergence. No state files, no drift."
  SensenetConfirm -> "CI with proof obligations. Typed Dhall pipelines. Agent code faces higher review burden."
  SensenetForge -> "Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design."
  SensenetPublish -> "Scope-graph documentation. References resolve or the build fails. Cross-language. Machine-readable."
  OmegaCode -> "Native terminal AI coding agent. Haskell + Brick TUI. io_uring event loop. 509k req/s. SIGIL-native."
  OmegaWork -> "Electron desktop app for non-coders. Same agent engine, GUI surface."
  OmegaProxy -> "Verified inference proxy. SSE → SIGIL over ZeroMQ. Reset-on-ambiguity."
  OmegaBoost -> "Managed inference co-located with BYOK vendor. evring HTTP stack."

pageName :: ProductPage -> String
pageName = case _ of
  ProductHome -> ""
  ProductFeatures -> "Features"
  ProductPricing -> "Pricing"
  ProductDocs -> "Docs"
  ProductDashboard -> "Dashboard"
  ProductSettings -> "Settings"
  ProductLegal -> "Legal"

instance routeMetadataRoute :: RouteMetadata Route where
  isProtected = case _ of
    ProductRoute _ ProductDashboard -> true
    ProductRoute _ ProductSettings -> true
    _ -> false
  
  isStaticRoute = case _ of
    ProductRoute _ ProductDashboard -> false
    ProductRoute _ ProductSettings -> false
    _ -> true
  
  routeTitle = case _ of
    Home -> "Straylight Software — Product Map"
    ProductRoute product ProductHome -> productName product <> " — " <> productTagline product
    ProductRoute product page -> pageName page <> " | " <> productName product
    Team -> "Team | Straylight"
    Plan -> "The Plan | Straylight"
    Lean -> "Lean | Straylight"
    Razorgirl -> "Razorgirl | Straylight"
    Software -> "Software | Straylight"
    Irc -> "IRC | Straylight"
    Discord -> "Discord | Straylight"
  
  routeDescription = case _ of
    Home -> "Two product families. Ten external products. One attestation layer."
    ProductRoute product _ -> productDescription product
    Team -> "The Straylight team and philosophy"
    Plan -> "The Straylight plan"
    Lean -> "Lean methodology at Straylight"
    Razorgirl -> "Razorgirl project"
    Software -> "Straylight software portfolio"
    Irc -> "Join Straylight on IRC"
    Discord -> "Join Straylight on Discord"
  
  routeOgImage _ = Nothing
