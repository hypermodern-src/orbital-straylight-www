-- | Header Component
module Straylight.Layout.Header where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String as Data.String
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

import Hydrogen.Surface as Surface
import Straylight.UI (cls, svgNS)

-- ============================================================
-- FFI
-- ============================================================

foreign import setThemeImpl :: String -> Effect Unit
foreign import getStoredThemeImpl :: String -> Effect String
foreign import navigateImpl :: String -> Effect Unit

-- ============================================================
-- TYPES
-- ============================================================

type State =
  { mobileMenuOpen :: Boolean
  , productMenuOpen :: Boolean
  , currentTheme :: String
  , themeLock :: Maybe String
  , currentPath :: String
  , surface :: Surface.SurfaceContext
  }

data Action
  = Initialize
  | Receive Input
  | ToggleMobileMenu
  | ToggleProductMenu
  | SelectProduct String String  -- path, theme

type Input =
  { currentPath :: String
  , themeLock :: Maybe String
  , surface :: Surface.SurfaceContext
  }

-- ============================================================
-- COMPONENT
-- ============================================================

header :: forall q o m. MonadAff m => H.Component q Input o m
header = H.mkComponent
  { initialState
  , render
  , eval: H.mkEval H.defaultEval 
      { handleAction = handleAction
      , initialize = Just Initialize
      , receive = Just <<< Receive
      }
  }

initialState :: Input -> State
initialState input =
  { mobileMenuOpen: false
  , productMenuOpen: false
  , currentTheme: "ono-tuned"
  , themeLock: input.themeLock
  , currentPath: input.currentPath
  , surface: input.surface
  }

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    case state.themeLock of
      Just lockedTheme -> do
        liftEffect $ setThemeImpl lockedTheme
        H.modify_ _ { currentTheme = lockedTheme }
      Nothing -> do
        theme <- liftEffect $ getStoredThemeImpl "ono-tuned"
        liftEffect $ setThemeImpl theme
        H.modify_ _ { currentTheme = theme }

  Receive input -> do
    -- Reflow: when the surface widens out of Compact, drop the mobile menu.
    let menuOpen = input.surface.class_ == Surface.Compact
    H.modify_ \s -> s
      { themeLock = input.themeLock
      , currentPath = input.currentPath
      , surface = input.surface
      , mobileMenuOpen = s.mobileMenuOpen && menuOpen
      }
    case input.themeLock of
      Just lockedTheme -> do
        liftEffect $ setThemeImpl lockedTheme
        H.modify_ _ { currentTheme = lockedTheme }
      Nothing -> do
        theme <- liftEffect $ getStoredThemeImpl "ono-tuned"
        liftEffect $ setThemeImpl theme
        H.modify_ _ { currentTheme = theme }

  ToggleMobileMenu -> 
    H.modify_ \s -> s { mobileMenuOpen = not s.mobileMenuOpen }
  
  ToggleProductMenu ->
    H.modify_ \s -> s { productMenuOpen = not s.productMenuOpen }
  
  SelectProduct path theme -> do
    liftEffect $ setThemeImpl theme
    liftEffect $ navigateImpl path
    H.modify_ _ { currentTheme = theme, productMenuOpen = false, currentPath = path }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.header
    [ cls [ "sticky top-0 z-50 bg-background border-b border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-8 py-4" ] ]
        [ HH.div
            [ cls [ "flex justify-between items-center" ] ]
            ( [ -- Product switcher (every surface)
                productSwitcher state
              ]
                <>
                  -- Surface-specific: Cozy/Roomy get the full nav + status;
                  -- Compact gets the hamburger. Driven by the Surface TYPE
                  -- (live reflow on resize), not CSS media queries.
                  if compact then
                    [ HH.button
                        [ cls [ "p-2 cursor-pointer text-text" ]
                        , HE.onClick \_ -> ToggleMobileMenu
                        , HP.type_ HP.ButtonButton
                        ]
                        [ if state.mobileMenuOpen then closeIcon else menuIcon ]
                    ]
                  else
                    [ HH.nav
                        [ cls [ "flex items-center gap-6" ] ]
                        (productNav state.currentPath)
                    , HH.div
                        [ cls [ "flex items-center gap-2 text-xs text-muted-foreground" ] ]
                        [ HH.span [ cls [ "w-2 h-2 bg-status inline-block status-pulse" ] ] []
                        , HH.text "NOMINAL"
                        ]
                    ]
            )
          -- Mobile menu (Compact only)
        , if compact && state.mobileMenuOpen then mobileMenu else HH.text ""
        ]
    ]
  where
  compact = state.surface.class_ == Surface.Compact

-- ============================================================
-- PRODUCT SWITCHER
-- ============================================================

productSwitcher :: forall m. State -> H.ComponentHTML Action () m
productSwitcher state =
  HH.div
    [ cls [ "relative flex items-center" ] ]
    [ HH.button
        [ cls [ "text-text font-medium text-sm transition-colors hover:text-primary cursor-pointer flex items-center gap-2" ]
        , HE.onClick \_ -> ToggleProductMenu
        , HP.type_ HP.ButtonButton
        ]
        [ HH.span [ cls [ "text-primary" ] ] [ HH.text "//" ]
        , HH.text $ " " <> currentProductName state.currentPath <> " "
        , HH.span [ cls [ "text-primary" ] ] [ HH.text "//" ]
        , HH.span [ cls [ "text-muted-foreground text-xs ml-1" ] ] [ HH.text "▼" ]
        ]
    , if state.productMenuOpen then productMenu state else HH.text ""
    ]

currentProductName :: String -> String
currentProductName path
  | path == "/" = "straylight"
  -- SENSE//NET
  | startsWith "/sensenet/cache" path = "sensenet//cache"
  | startsWith "/sensenet/build" path = "sensenet//build"
  | startsWith "/sensenet/converge" path = "sensenet//converge"
  | startsWith "/sensenet/confirm" path = "sensenet//confirm"
  | startsWith "/sensenet/forge" path = "sensenet//forge"
  | startsWith "/sensenet/publish" path = "sensenet//publish"
  -- Ω
  | startsWith "/omega/code" path = "omega//code"
  | startsWith "/omega/work" path = "omega//work"
  | startsWith "/omega/proxy" path = "omega//proxy"
  | startsWith "/omega/boost" path = "omega//boost"
  | startsWith "/team" path = "team"
  | otherwise = "straylight"

startsWith :: String -> String -> Boolean
startsWith prefix str = 
  str == prefix || case Data.String.stripPrefix (Data.String.Pattern (prefix <> "/")) str of
    Just _ -> true
    Nothing -> false

-- | Returns navigation links - product sub-pages when on a product, global nav otherwise
productNav :: forall w i. String -> Array (HH.HTML w i)
productNav path
  | startsWith "/sensenet/cache" path = productSubNav "/sensenet/cache" path
  | startsWith "/sensenet/build" path = productSubNav "/sensenet/build" path
  | startsWith "/sensenet/converge" path = productSubNav "/sensenet/converge" path
  | startsWith "/sensenet/confirm" path = productSubNav "/sensenet/confirm" path
  | startsWith "/sensenet/forge" path = productSubNav "/sensenet/forge" path
  | startsWith "/sensenet/publish" path = productSubNav "/sensenet/publish" path
  | startsWith "/omega/code" path = productSubNav "/omega/code" path
  | startsWith "/omega/work" path = productSubNav "/omega/work" path
  | startsWith "/omega/proxy" path = productSubNav "/omega/proxy" path
  | startsWith "/omega/boost" path = productSubNav "/omega/boost" path
  | otherwise = globalNav

globalNav :: forall w i. Array (HH.HTML w i)
globalNav =
  [ navLink "/team" "team"
  , navLink "/software" "software"
  , externalLink "https://github.com/straylight-software" "github"
  , navLink "/discord" "discord"
  ]

productSubNav :: forall w i. String -> String -> Array (HH.HTML w i)
productSubNav base currentPath =
  [ subNavLink (base) "home" currentPath
  , subNavLink (base <> "/features") "features" currentPath
  , subNavLink (base <> "/pricing") "pricing" currentPath
  , subNavLink (base <> "/docs") "docs" currentPath
  ]

subNavLink :: forall w i. String -> String -> String -> HH.HTML w i
subNavLink href label currentPath =
  HH.a
    [ HP.href href
    , cls [ "text-[13px] transition-colors link-trace"
          , if isActive href currentPath
              then "text-primary"
              else "text-muted-foreground hover:text-text"
          ]
    ]
    [ HH.text label ]

isActive :: String -> String -> Boolean
isActive href currentPath
  | href == currentPath = true
  | href <> "/" == currentPath = true
  -- For base product path, only active if exactly on home
  | not (Data.String.contains (Data.String.Pattern "/features") href) 
    && not (Data.String.contains (Data.String.Pattern "/pricing") href)
    && not (Data.String.contains (Data.String.Pattern "/docs") href)
    && (currentPath == href || currentPath == href <> "/") = true
  -- For sub-pages, check prefix
  | Data.String.contains (Data.String.Pattern "/docs") href 
    && startsWith href currentPath = true
  | otherwise = currentPath == href

productMenu :: forall m. State -> H.ComponentHTML Action () m
productMenu state =
  HH.div
    [ cls [ "absolute top-full left-0 mt-2 bg-card border border-border rounded-lg p-4 min-w-[380px] z-50 shadow-lg" ] ]
    [ -- SENSE//NET - Build infrastructure
      HH.div
        [ cls [ "mb-4" ] ]
        [ HH.div
            [ cls [ "text-[9px] text-cyan-400 uppercase tracking-wider mb-2 flex items-center gap-2" ] ]
            [ HH.span [ cls [ "w-1.5 h-1.5 bg-cyan-400 inline-block" ] ] []
            , HH.text "SENSE // NET · BUILD INFRASTRUCTURE"
            ]
        , HH.div
            [ cls [ "flex flex-col gap-1" ] ]
            [ productOption state "/sensenet/cache" "sensenet//cache" "Binary cache & artifact store" "ono-sprawl"
            , productOption state "/sensenet/build" "sensenet//build" "Typed build system" "ono-sprawl"
            , productOption state "/sensenet/converge" "sensenet//converge" "Infrastructure-as-code" "ono-sprawl"
            , productOption state "/sensenet/confirm" "sensenet//confirm" "CI with proof obligations" "ono-sprawl"
            , productOption state "/sensenet/forge" "sensenet//forge" "Code hosting + review" "ono-sprawl"
            , productOption state "/sensenet/publish" "sensenet//publish" "Scope-graph documentation" "ono-sprawl"
            ]
        ]
    
      -- Ω - Agent infrastructure
    , HH.div
        [ cls [ "mb-4" ] ]
        [ HH.div
            [ cls [ "text-[9px] text-blue-300 uppercase tracking-wider mb-2 flex items-center gap-2" ] ]
            [ HH.span [ cls [ "w-1.5 h-1.5 bg-blue-300 inline-block" ] ] []
            , HH.text "// Ω // AGENT INFRASTRUCTURE"
            ]
        , HH.div
            [ cls [ "flex flex-col gap-1" ] ]
            [ productOption state "/omega/code" "omega//code" "Native terminal AI agent" "ono-sprawl"
            , productOption state "/omega/work" "omega//work" "Desktop app for teams" "ono-github"
            , productOption state "/omega/proxy" "omega//proxy" "Verified inference proxy" "ono-memphis"
            , productOption state "/omega/boost" "omega//boost" "Managed inference" "maas-neoform"
            ]
        ]
    
      -- Navigation
    , HH.div_
        [ HH.div
            [ cls [ "text-[9px] text-status uppercase tracking-wider mb-2 flex items-center gap-2" ] ]
            [ HH.span [ cls [ "w-1.5 h-1.5 bg-status inline-block" ] ] []
            , HH.text "NAVIGATION"
            ]
        , HH.div
            [ cls [ "flex flex-col gap-1" ] ]
            [ productOption state "/" "product map" "All products overview" "ono-tuned"
            , productOption state "/team" "team" "The continuity project" "ono-tuned"
            ]
        ]
    
    , HH.div
        [ cls [ "mt-4 pt-3 border-t border-border" ] ]
        [ HH.div
            [ cls [ "text-[8px] text-muted-foreground uppercase tracking-wider" ] ]
            [ HH.text "each product · its own theme" ]
        ]
    ]

productOption :: forall m. State -> String -> String -> String -> String -> H.ComponentHTML Action () m
productOption state path name desc theme =
  HH.button
    [ cls [ "text-left px-3 py-2 rounded transition-colors flex items-center justify-between group cursor-pointer w-full"
          , if startsWith path state.currentPath
              then "bg-primary/10 text-text" 
              else "hover:bg-card text-muted-foreground hover:text-text"
          ]
    , HE.onClick \_ -> SelectProduct path theme
    , HP.type_ HP.ButtonButton
    ]
    [ HH.div_
        [ HH.div [ cls [ "text-[12px] font-medium" ] ] [ HH.text name ]
        , HH.div [ cls [ "text-[10px] text-muted-foreground" ] ] [ HH.text desc ]
        ]
    , HH.span 
        [ cls [ "text-[9px] text-muted-foreground font-mono" ] ] 
        [ HH.text theme ]
    ]

navLink :: forall w i. String -> String -> HH.HTML w i
navLink href label =
  HH.a
    [ HP.href href
    , cls [ "text-muted-foreground text-[13px] hover:text-text transition-colors link-trace" ]
    ]
    [ HH.text label ]

externalLink :: forall w i. String -> String -> HH.HTML w i
externalLink href label =
  HH.a
    [ HP.href href
    , HP.target "_blank"
    , HP.rel "noopener noreferrer"
    , cls [ "text-muted-foreground text-[13px] hover:text-text transition-colors link-trace" ]
    ]
    [ HH.text label ]

mobileMenu :: forall m. H.ComponentHTML Action () m
mobileMenu =
  HH.div
    [ cls [ "md:hidden py-4 border-t border-border mt-4" ] ]
    [ HH.div
        [ cls [ "flex flex-col gap-4" ] ]
        [ navLink "/omega/code" "omega//code"
        , navLink "/omega/work" "omega//work"
        , navLink "/omega/proxy" "omega//proxy"
        , navLink "/omega/boost" "omega//boost"
        , navLink "/team" "team"
        , navLink "/software" "software"
        , externalLink "https://github.com/straylight-software" "github"
        , navLink "/discord" "discord"
        ]
    ]

-- ============================================================
-- ICONS
-- ============================================================

menuIcon :: forall w i. HH.HTML w i
menuIcon =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ cls [ "w-6 h-6" ]
    , HP.attr (HH.AttrName "fill") "none"
    , HP.attr (HH.AttrName "stroke") "currentColor"
    , HP.attr (HH.AttrName "viewBox") "0 0 24 24"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "stroke-linecap") "round"
        , HP.attr (HH.AttrName "stroke-linejoin") "round"
        , HP.attr (HH.AttrName "stroke-width") "2"
        , HP.attr (HH.AttrName "d") "M4 6h16M4 12h16M4 18h16"
        ]
        []
    ]

closeIcon :: forall w i. HH.HTML w i
closeIcon =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ cls [ "w-6 h-6" ]
    , HP.attr (HH.AttrName "fill") "none"
    , HP.attr (HH.AttrName "stroke") "currentColor"
    , HP.attr (HH.AttrName "viewBox") "0 0 24 24"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "stroke-linecap") "round"
        , HP.attr (HH.AttrName "stroke-linejoin") "round"
        , HP.attr (HH.AttrName "stroke-width") "2"
        , HP.attr (HH.AttrName "d") "M6 18L18 6M6 6l12 12"
        ]
        []
    ]
