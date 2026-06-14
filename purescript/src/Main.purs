-- | Straylight Web Entry Point
module Main where

import Prelude

import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Type.Proxy (Proxy(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH

import Halogen.Subscription as HS
import Halogen.VDom.Driver (runUI)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window (document)
import Web.Event.Event (preventDefault)
import Web.UIEvent.MouseEvent (MouseEvent, toEvent)

import Straylight.Auth as Auth
import Straylight.UI (cls, scanlineOverlay)
import Straylight.Router (Route(..), Product(..), ProductPage(..), parseRoute, routeToPath, pushState, getPathname, onPopState, interceptLinks)
import Straylight.Layout.Header as Header
import Straylight.Layout.Footer as Footer

-- Product pages - Home
import Straylight.Pages.Home as Home

-- SENSE//NET products
import Straylight.Pages.Products.SensenetCache.Home as SensenetCacheHome
import Straylight.Pages.Products.SensenetCache.Features as SensenetCacheFeatures
import Straylight.Pages.Products.SensenetCache.Pricing as SensenetCachePricing
import Straylight.Pages.Products.SensenetCache.Docs as SensenetCacheDocs
import Straylight.Pages.Products.SensenetCache.Dashboard as SensenetCacheDashboard
import Straylight.Pages.Products.SensenetCache.Settings as SensenetCacheSettings
import Straylight.Pages.Products.SensenetCache.Legal as SensenetCacheLegal

import Straylight.Pages.Products.SensenetBuild.Home as SensenetBuildHome
import Straylight.Pages.Products.SensenetBuild.Features as SensenetBuildFeatures
import Straylight.Pages.Products.SensenetBuild.Pricing as SensenetBuildPricing
import Straylight.Pages.Products.SensenetBuild.Docs as SensenetBuildDocs
import Straylight.Pages.Products.SensenetBuild.Dashboard as SensenetBuildDashboard
import Straylight.Pages.Products.SensenetBuild.Settings as SensenetBuildSettings
import Straylight.Pages.Products.SensenetBuild.Legal as SensenetBuildLegal

import Straylight.Pages.Products.SensenetConverge.Home as SensenetConvergeHome
import Straylight.Pages.Products.SensenetConverge.Features as SensenetConvergeFeatures
import Straylight.Pages.Products.SensenetConverge.Pricing as SensenetConvergePricing
import Straylight.Pages.Products.SensenetConverge.Docs as SensenetConvergeDocs
import Straylight.Pages.Products.SensenetConverge.Dashboard as SensenetConvergeDashboard
import Straylight.Pages.Products.SensenetConverge.Settings as SensenetConvergeSettings
import Straylight.Pages.Products.SensenetConverge.Legal as SensenetConvergeLegal

import Straylight.Pages.Products.SensenetConfirm.Home as SensenetConfirmHome
import Straylight.Pages.Products.SensenetConfirm.Features as SensenetConfirmFeatures
import Straylight.Pages.Products.SensenetConfirm.Pricing as SensenetConfirmPricing
import Straylight.Pages.Products.SensenetConfirm.Docs as SensenetConfirmDocs
import Straylight.Pages.Products.SensenetConfirm.Dashboard as SensenetConfirmDashboard
import Straylight.Pages.Products.SensenetConfirm.Settings as SensenetConfirmSettings
import Straylight.Pages.Products.SensenetConfirm.Legal as SensenetConfirmLegal

import Straylight.Pages.Products.SensenetForge.Home as SensenetForgeHome
import Straylight.Pages.Products.SensenetForge.Features as SensenetForgeFeatures
import Straylight.Pages.Products.SensenetForge.Pricing as SensenetForgePricing
import Straylight.Pages.Products.SensenetForge.Docs as SensenetForgeDocs
import Straylight.Pages.Products.SensenetForge.Dashboard as SensenetForgeDashboard
import Straylight.Pages.Products.SensenetForge.Settings as SensenetForgeSettings
import Straylight.Pages.Products.SensenetForge.Legal as SensenetForgeLegal

import Straylight.Pages.Products.SensenetPublish.Home as SensenetPublishHome
import Straylight.Pages.Products.SensenetPublish.Features as SensenetPublishFeatures
import Straylight.Pages.Products.SensenetPublish.Pricing as SensenetPublishPricing
import Straylight.Pages.Products.SensenetPublish.Docs as SensenetPublishDocs
import Straylight.Pages.Products.SensenetPublish.Dashboard as SensenetPublishDashboard
import Straylight.Pages.Products.SensenetPublish.Settings as SensenetPublishSettings
import Straylight.Pages.Products.SensenetPublish.Legal as SensenetPublishLegal

-- Ω products
import Straylight.Pages.Products.OmegaCode.Home as OmegaCodeHome
import Straylight.Pages.Products.OmegaCode.Features as OmegaCodeFeatures
import Straylight.Pages.Products.OmegaCode.Pricing as OmegaCodePricing
import Straylight.Pages.Products.OmegaCode.Docs as OmegaCodeDocs
import Straylight.Pages.Products.OmegaCode.Dashboard as OmegaCodeDashboard
import Straylight.Pages.Products.OmegaCode.Settings as OmegaCodeSettings
import Straylight.Pages.Products.OmegaCode.Legal as OmegaCodeLegal

import Straylight.Pages.Products.OmegaWork.Home as OmegaWorkHome
import Straylight.Pages.Products.OmegaWork.Features as OmegaWorkFeatures
import Straylight.Pages.Products.OmegaWork.Pricing as OmegaWorkPricing
import Straylight.Pages.Products.OmegaWork.Docs as OmegaWorkDocs
import Straylight.Pages.Products.OmegaWork.Dashboard as OmegaWorkDashboard
import Straylight.Pages.Products.OmegaWork.Settings as OmegaWorkSettings
import Straylight.Pages.Products.OmegaWork.Legal as OmegaWorkLegal

import Straylight.Pages.Products.OmegaProxy.Home as OmegaProxyHome
import Straylight.Pages.Products.OmegaProxy.Features as OmegaProxyFeatures
import Straylight.Pages.Products.OmegaProxy.Pricing as OmegaProxyPricing
import Straylight.Pages.Products.OmegaProxy.Docs as OmegaProxyDocs
import Straylight.Pages.Products.OmegaProxy.Dashboard as OmegaProxyDashboard
import Straylight.Pages.Products.OmegaProxy.Settings as OmegaProxySettings
import Straylight.Pages.Products.OmegaProxy.Legal as OmegaProxyLegal

import Straylight.Pages.Products.OmegaBoost.Home as OmegaBoostHome
import Straylight.Pages.Products.OmegaBoost.Features as OmegaBoostFeatures
import Straylight.Pages.Products.OmegaBoost.Pricing as OmegaBoostPricing
import Straylight.Pages.Products.OmegaBoost.Docs as OmegaBoostDocs
import Straylight.Pages.Products.OmegaBoost.Dashboard as OmegaBoostDashboard
import Straylight.Pages.Products.OmegaBoost.Settings as OmegaBoostSettings
import Straylight.Pages.Products.OmegaBoost.Legal as OmegaBoostLegal

-- Team pages
import Straylight.Pages.Team.About as TeamAbout
import Straylight.Pages.Plan as Plan
import Straylight.Pages.Lean as Lean
import Straylight.Pages.Razorgirl as Razorgirl
import Straylight.Pages.Software as Software

-- Community
import Straylight.Pages.Irc as Irc
import Straylight.Pages.Discord as Discord

-- ============================================================
-- MAIN ENTRY
-- ============================================================

main :: Effect Unit
main = launchAff_ do
  HA.awaitLoad
  -- Bring up the framework auth session (Supabase-backed via hydrogen's
  -- AuthProvider frame; SDK bundled transitively — STR-239).
  _ <- liftEffect Auth.initAuth
  doc <- liftEffect $ window >>= document
  let parent = HTMLDocument.toParentNode doc
  mbContainer <- liftEffect $ querySelector (QuerySelector "#straylight-app") parent
  case mbContainer >>= HTMLElement.fromElement of
    Nothing -> pure unit
    Just container -> void $ runUI appComponent unit container

-- ============================================================
-- APP COMPONENT
-- ============================================================

type AppState = { route :: Route, currentPath :: String }

data AppAction
  = Initialize
  | Navigate Route MouseEvent
  | RouteChanged String

type AppSlots =
  ( header :: H.Slot (Const Void) Void Unit
  , footer :: H.Slot (Const Void) Void Unit
  , page :: H.Slot (Const Void) Void String
  )

_header :: Proxy "header"
_header = Proxy

_footer :: Proxy "footer"
_footer = Proxy

_page :: Proxy "page"
_page = Proxy

appComponent :: forall q i o m. MonadAff m => H.Component q i o m
appComponent = H.mkComponent
  { initialState: const { route: Home, currentPath: "/" }
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      , initialize = Just Initialize
      }
  }

handleAction :: forall o m. MonadAff m => AppAction -> H.HalogenM AppState AppAction AppSlots o m Unit
handleAction = case _ of
  Initialize -> do
    path <- liftEffect getPathname
    H.modify_ _ { route = parseRoute path, currentPath = path }
    { emitter, listener } <- liftEffect HS.create
    liftEffect $ onPopState (\p -> HS.notify listener (RouteChanged p))
    liftEffect $ interceptLinks (\p -> HS.notify listener (RouteChanged p))
    void $ H.subscribe emitter
  
  Navigate route event -> do
    liftEffect $ preventDefault (toEvent event)
    liftEffect $ pushState $ routeToPath route
    H.modify_ _ { route = route }
  
  RouteChanged path -> do
    H.modify_ _ { route = parseRoute path, currentPath = path }

render :: forall m. MonadAff m => AppState -> H.ComponentHTML AppAction AppSlots m
render state =
  HH.div
    [ cls [ "min-h-screen bg-background text-muted-foreground text-[15px] leading-relaxed" ] ]
    [ scanlineOverlay
    , renderHeader state
    , HH.main
        [ cls [ mainMaxWidth state.route ] ]
        [ renderPage state.currentPath state.route ]
    , HH.slot_ _footer unit Footer.footer unit
    ]

mainMaxWidth :: Route -> String
mainMaxWidth = case _ of
  Home -> "max-w-[1100px] mx-auto px-8 py-12"
  ProductRoute _ _ -> "max-w-[1100px] mx-auto px-8 py-12"
  _ -> "max-w-[900px] mx-auto px-8 py-12"

renderPage :: forall m. MonadAff m => String -> Route -> H.ComponentHTML AppAction AppSlots m
renderPage key = case _ of
  Home -> HH.slot_ _page key Home.homePage unit
  
  -- SENSE//NET
  ProductRoute SensenetCache ProductHome -> HH.slot_ _page key SensenetCacheHome.homePage unit
  ProductRoute SensenetCache ProductFeatures -> HH.slot_ _page key SensenetCacheFeatures.featuresPage unit
  ProductRoute SensenetCache ProductPricing -> HH.slot_ _page key SensenetCachePricing.pricingPage unit
  ProductRoute SensenetCache ProductDocs -> HH.slot_ _page key (SensenetCacheDocs.docsPage) { path: key }
  ProductRoute SensenetCache ProductDashboard -> HH.slot_ _page key SensenetCacheDashboard.dashboardPage unit
  ProductRoute SensenetCache ProductSettings -> HH.slot_ _page key SensenetCacheSettings.settingsPage unit
  ProductRoute SensenetCache ProductLegal -> HH.slot_ _page key SensenetCacheLegal.privacyPage unit

  ProductRoute SensenetBuild ProductHome -> HH.slot_ _page key SensenetBuildHome.homePage unit
  ProductRoute SensenetBuild ProductFeatures -> HH.slot_ _page key SensenetBuildFeatures.featuresPage unit
  ProductRoute SensenetBuild ProductPricing -> HH.slot_ _page key SensenetBuildPricing.pricingPage unit
  ProductRoute SensenetBuild ProductDocs -> HH.slot_ _page key (SensenetBuildDocs.docsPage) { path: key }
  ProductRoute SensenetBuild ProductDashboard -> HH.slot_ _page key SensenetBuildDashboard.dashboardPage unit
  ProductRoute SensenetBuild ProductSettings -> HH.slot_ _page key SensenetBuildSettings.settingsPage unit
  ProductRoute SensenetBuild ProductLegal -> HH.slot_ _page key SensenetBuildLegal.privacyPage unit

  ProductRoute SensenetConverge ProductHome -> HH.slot_ _page key SensenetConvergeHome.homePage unit
  ProductRoute SensenetConverge ProductFeatures -> HH.slot_ _page key SensenetConvergeFeatures.featuresPage unit
  ProductRoute SensenetConverge ProductPricing -> HH.slot_ _page key SensenetConvergePricing.pricingPage unit
  ProductRoute SensenetConverge ProductDocs -> HH.slot_ _page key (SensenetConvergeDocs.docsPage) { path: key }
  ProductRoute SensenetConverge ProductDashboard -> HH.slot_ _page key SensenetConvergeDashboard.dashboardPage unit
  ProductRoute SensenetConverge ProductSettings -> HH.slot_ _page key SensenetConvergeSettings.settingsPage unit
  ProductRoute SensenetConverge ProductLegal -> HH.slot_ _page key SensenetConvergeLegal.privacyPage unit

  ProductRoute SensenetConfirm ProductHome -> HH.slot_ _page key SensenetConfirmHome.homePage unit
  ProductRoute SensenetConfirm ProductFeatures -> HH.slot_ _page key SensenetConfirmFeatures.featuresPage unit
  ProductRoute SensenetConfirm ProductPricing -> HH.slot_ _page key SensenetConfirmPricing.pricingPage unit
  ProductRoute SensenetConfirm ProductDocs -> HH.slot_ _page key (SensenetConfirmDocs.docsPage) { path: key }
  ProductRoute SensenetConfirm ProductDashboard -> HH.slot_ _page key SensenetConfirmDashboard.dashboardPage unit
  ProductRoute SensenetConfirm ProductSettings -> HH.slot_ _page key SensenetConfirmSettings.settingsPage unit
  ProductRoute SensenetConfirm ProductLegal -> HH.slot_ _page key SensenetConfirmLegal.privacyPage unit

  ProductRoute SensenetForge ProductHome -> HH.slot_ _page key SensenetForgeHome.homePage unit
  ProductRoute SensenetForge ProductFeatures -> HH.slot_ _page key SensenetForgeFeatures.featuresPage unit
  ProductRoute SensenetForge ProductPricing -> HH.slot_ _page key SensenetForgePricing.pricingPage unit
  ProductRoute SensenetForge ProductDocs -> HH.slot_ _page key (SensenetForgeDocs.docsPage) { path: key }
  ProductRoute SensenetForge ProductDashboard -> HH.slot_ _page key SensenetForgeDashboard.dashboardPage unit
  ProductRoute SensenetForge ProductSettings -> HH.slot_ _page key SensenetForgeSettings.settingsPage unit
  ProductRoute SensenetForge ProductLegal -> HH.slot_ _page key SensenetForgeLegal.privacyPage unit

  ProductRoute SensenetPublish ProductHome -> HH.slot_ _page key SensenetPublishHome.homePage unit
  ProductRoute SensenetPublish ProductFeatures -> HH.slot_ _page key SensenetPublishFeatures.featuresPage unit
  ProductRoute SensenetPublish ProductPricing -> HH.slot_ _page key SensenetPublishPricing.pricingPage unit
  ProductRoute SensenetPublish ProductDocs -> HH.slot_ _page key (SensenetPublishDocs.docsPage) { path: key }
  ProductRoute SensenetPublish ProductDashboard -> HH.slot_ _page key SensenetPublishDashboard.dashboardPage unit
  ProductRoute SensenetPublish ProductSettings -> HH.slot_ _page key SensenetPublishSettings.settingsPage unit
  ProductRoute SensenetPublish ProductLegal -> HH.slot_ _page key SensenetPublishLegal.privacyPage unit

  -- Ω
  ProductRoute OmegaCode ProductHome -> HH.slot_ _page key OmegaCodeHome.homePage unit
  ProductRoute OmegaCode ProductFeatures -> HH.slot_ _page key OmegaCodeFeatures.featuresPage unit
  ProductRoute OmegaCode ProductPricing -> HH.slot_ _page key OmegaCodePricing.pricingPage unit
  ProductRoute OmegaCode ProductDocs -> HH.slot_ _page key (OmegaCodeDocs.docsPage) { path: key }
  ProductRoute OmegaCode ProductDashboard -> HH.slot_ _page key OmegaCodeDashboard.dashboardPage unit
  ProductRoute OmegaCode ProductSettings -> HH.slot_ _page key OmegaCodeSettings.settingsPage unit
  ProductRoute OmegaCode ProductLegal -> HH.slot_ _page key OmegaCodeLegal.privacyPage unit

  ProductRoute OmegaWork ProductHome -> HH.slot_ _page key OmegaWorkHome.homePage unit
  ProductRoute OmegaWork ProductFeatures -> HH.slot_ _page key OmegaWorkFeatures.featuresPage unit
  ProductRoute OmegaWork ProductPricing -> HH.slot_ _page key OmegaWorkPricing.pricingPage unit
  ProductRoute OmegaWork ProductDocs -> HH.slot_ _page key (OmegaWorkDocs.docsPage) { path: key }
  ProductRoute OmegaWork ProductDashboard -> HH.slot_ _page key OmegaWorkDashboard.dashboardPage unit
  ProductRoute OmegaWork ProductSettings -> HH.slot_ _page key OmegaWorkSettings.settingsPage unit
  ProductRoute OmegaWork ProductLegal -> HH.slot_ _page key OmegaWorkLegal.privacyPage unit

  ProductRoute OmegaProxy ProductHome -> HH.slot_ _page key OmegaProxyHome.homePage unit
  ProductRoute OmegaProxy ProductFeatures -> HH.slot_ _page key OmegaProxyFeatures.featuresPage unit
  ProductRoute OmegaProxy ProductPricing -> HH.slot_ _page key OmegaProxyPricing.pricingPage unit
  ProductRoute OmegaProxy ProductDocs -> HH.slot_ _page key (OmegaProxyDocs.docsPage) { path: key }
  ProductRoute OmegaProxy ProductDashboard -> HH.slot_ _page key OmegaProxyDashboard.dashboardPage unit
  ProductRoute OmegaProxy ProductSettings -> HH.slot_ _page key OmegaProxySettings.settingsPage unit
  ProductRoute OmegaProxy ProductLegal -> HH.slot_ _page key OmegaProxyLegal.privacyPage unit

  ProductRoute OmegaBoost ProductHome -> HH.slot_ _page key OmegaBoostHome.homePage unit
  ProductRoute OmegaBoost ProductFeatures -> HH.slot_ _page key OmegaBoostFeatures.featuresPage unit
  ProductRoute OmegaBoost ProductPricing -> HH.slot_ _page key OmegaBoostPricing.pricingPage unit
  ProductRoute OmegaBoost ProductDocs -> HH.slot_ _page key (OmegaBoostDocs.docsPage) { path: key }
  ProductRoute OmegaBoost ProductDashboard -> HH.slot_ _page key OmegaBoostDashboard.dashboardPage unit
  ProductRoute OmegaBoost ProductSettings -> HH.slot_ _page key OmegaBoostSettings.settingsPage unit
  ProductRoute OmegaBoost ProductLegal -> HH.slot_ _page key OmegaBoostLegal.privacyPage unit

  -- Team pages
  Team -> HH.slot_ _page key TeamAbout.aboutPage unit
  Plan -> HH.slot_ _page key Plan.planPage unit
  Lean -> HH.slot_ _page key Lean.leanPage unit
  Razorgirl -> HH.slot_ _page key Razorgirl.razorgirlPage unit
  Software -> HH.slot_ _page key Software.softwarePage unit
  
  -- Community
  Irc -> HH.slot_ _page key Irc.ircPage unit
  Discord -> HH.slot_ _page key Discord.discordPage unit

-- ============================================================
-- HEADER
-- ============================================================

renderHeader :: forall m. MonadAff m => AppState -> H.ComponentHTML AppAction AppSlots m
renderHeader state =
  HH.slot_ _header unit Header.header 
    { currentPath: routeToPath state.route
    , themeLock: routeThemeLock state.route
    }

routeThemeLock :: Route -> Maybe String
routeThemeLock = case _ of
  Plan -> Just "ono-memphis"
  Lean -> Just "ono-memphis"
  ProductRoute SensenetCache _ -> Just "ono-sprawl"
  ProductRoute SensenetBuild _ -> Just "ono-sprawl"
  ProductRoute SensenetConverge _ -> Just "ono-sprawl"
  ProductRoute SensenetConfirm _ -> Just "ono-sprawl"
  ProductRoute SensenetForge _ -> Just "ono-sprawl"
  ProductRoute SensenetPublish _ -> Just "ono-sprawl"
  ProductRoute OmegaCode _ -> Just "ono-sprawl"
  ProductRoute OmegaWork _ -> Just "ono-github"
  ProductRoute OmegaProxy _ -> Just "ono-memphis"
  ProductRoute OmegaBoost _ -> Just "maas-neoform"
  _ -> Nothing
