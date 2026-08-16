-- | sensenet//cache Dashboard Page
module Straylight.Pages.Products.SensenetCache.Dashboard where

import Prelude
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

dashboardPage :: forall q i o m. H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const { activeTab: "overview" }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , tabs state
    , content state
    ]

-- ============================================================
-- HEADER
-- ============================================================

header :: forall w i. HH.HTML w i
header =
  HH.div [ cls [ "mb-8" ] ]
    [ HH.div [ cls [ "flex items-center justify-between" ] ]
        [ HH.div_
            [ HH.h1 [ cls [ "text-2xl font-bold text-text mb-2" ] ] 
                [ HH.text "sensenet//cache Dashboard" ]
            , HH.p [ cls [ "text-muted-foreground" ] ] 
                [ HH.text "Manage caches, view attestations, and monitor usage." ]
            ]
        , HH.div [ cls [ "flex gap-3" ] ]
            [ HH.a
                [ HP.href "/sensenet/cache/docs"
                , cls [ "px-4 py-2 border border-border text-text rounded-md text-sm hover:bg-card transition-colors" ]
                ]
                [ HH.text "Docs" ]
            , HH.a
                [ HP.href "/sensenet/cache/settings"
                , cls [ "px-4 py-2 bg-cyan-400 text-background rounded-md text-sm hover:bg-cyan-400/90 transition-colors" ]
                ]
                [ HH.text "Settings" ]
            ]
        ]
    ]

-- ============================================================
-- TABS
-- ============================================================

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state =
  HH.div [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton state "overview" "Overview"
    , tabButton state "caches" "Caches"
    , tabButton state "artifacts" "Artifacts"
    , tabButton state "attestations" "Attestations"
    , tabButton state "usage" "Usage"
    ]

tabButton :: forall m. State -> String -> String -> H.ComponentHTML Action () m
tabButton state value label =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px cursor-pointer"
          , if state.activeTab == value 
              then "text-cyan-400 border-b-2 border-cyan-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

-- ============================================================
-- CONTENT
-- ============================================================

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "caches" -> cachesTab
  "artifacts" -> artifactsTab
  "attestations" -> attestationsTab
  "usage" -> usageTab
  _ -> overviewTab

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall w i. HH.HTML w i
overviewTab =
  HH.div_
    [ -- Stats cards
      HH.div [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Storage Used" "12.4 GB" "of 100 GB" (Just 12)
        , statCard "Transfer" "45.2 GB" "this month" (Just 45)
        , statCard "Attestations" "1,247" "verified" Nothing
        , statCard "Cache Hit Rate" "94.2%" "last 7 days" Nothing
        ]
    -- Recent uploads
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-6" ] ]
        [ recentUploadsCard
        , quickActionsCard
        ]
    ]

statCard :: forall w i. String -> String -> String -> Maybe Int -> HH.HTML w i
statCard label value subtitle maybePercent =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold text-text mb-1" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text subtitle ]
    , case maybePercent of
        Just pct -> 
          HH.div [ cls [ "mt-3 h-1.5 bg-border rounded-full overflow-hidden" ] ]
            [ HH.div 
                [ cls [ "h-full bg-cyan-400 rounded-full" ]
                , HP.style ("width: " <> show pct <> "%")
                ] 
                []
            ]
        Nothing -> HH.text ""
    ]

recentUploadsCard :: forall w i. HH.HTML w i
recentUploadsCard =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] 
        [ HH.text "Recent Uploads" ]
    , HH.div [ cls [ "space-y-3" ] ]
        [ uploadItem "blake3://7f83b165..." "mypackage-1.2.0" "2 min ago" "14.2 MB"
        , uploadItem "blake3://a1b2c3d4..." "libfoo-3.1.4" "15 min ago" "892 KB"
        , uploadItem "blake3://e5f6g7h8..." "devshell" "1 hour ago" "156 MB"
        , uploadItem "blake3://i9j0k1l2..." "ci-tools-2.0" "3 hours ago" "45.3 MB"
        , uploadItem "blake3://m3n4o5p6..." "webapp-frontend" "5 hours ago" "23.1 MB"
        ]
    , HH.a
        [ HP.href "#"
        , cls [ "block text-center text-sm text-cyan-400 hover:text-cyan-300 mt-4" ]
        ]
        [ HH.text "View all uploads ->" ]
    ]

uploadItem :: forall w i. String -> String -> String -> String -> HH.HTML w i
uploadItem hash name time size =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text hash ]
        ]
    , HH.div [ cls [ "text-right" ] ]
        [ HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text size ]
        ]
    ]

quickActionsCard :: forall w i. HH.HTML w i
quickActionsCard =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] 
        [ HH.text "Quick Actions" ]
    , HH.div [ cls [ "space-y-3" ] ]
        [ actionButton "Push artifact" "sensenet-cache push ./result"
        , actionButton "Verify attestation" "sensenet-cache verify <hash>"
        , actionButton "Generate API key" "Settings > API Keys > New"
        , actionButton "Invite team member" "Settings > Team > Invite"
        ]
    , HH.div [ cls [ "mt-6 p-4 bg-cyan-400/5 border border-cyan-400/20 rounded-lg" ] ]
        [ HH.p [ cls [ "text-sm text-cyan-400 font-medium mb-1" ] ] 
            [ HH.text "Substituter config" ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] 
            [ HH.text "https://cache.sensenet.dev/acme-corp" ]
        ]
    ]

actionButton :: forall w i. String -> String -> HH.HTML w i
actionButton label hint =
  HH.div [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text label ]
    , HH.span [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text hint ]
    ]

-- ============================================================
-- CACHES TAB
-- ============================================================

cachesTab :: forall w i. HH.HTML w i
cachesTab =
  HH.div_
    [ HH.div [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Your Caches" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-cyan-400 text-background rounded-md text-sm hover:bg-cyan-400/90 transition-colors" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ New Cache" ]
        ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ cacheCard "acme-corp" "Private" "8.2 GB" "1,024" true
        , cacheCard "acme-oss" "Public" "4.2 GB" "223" true
        , cacheCard "staging" "Private" "156 MB" "47" false
        ]
    ]

cacheCard :: forall w i. String -> String -> String -> String -> Boolean -> HH.HTML w i
cacheCard name visibility storage artifacts isActive =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.div [ cls [ "flex items-start justify-between" ] ]
        [ HH.div_
            [ HH.div [ cls [ "flex items-center gap-3 mb-2" ] ]
                [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text name ]
                , HH.span 
                    [ cls [ "px-2 py-0.5 text-xs rounded-full"
                          , if visibility == "Public" 
                              then "bg-green-400/10 text-green-400" 
                              else "bg-cyan-400/10 text-cyan-400"
                          ] 
                    ] 
                    [ HH.text visibility ]
                , if isActive
                    then HH.span [ cls [ "w-2 h-2 bg-green-400 rounded-full" ] ] []
                    else HH.text ""
                ]
            , HH.p [ cls [ "text-sm text-muted-foreground font-mono" ] ] 
                [ HH.text ("https://cache.sensenet.dev/" <> name) ]
            ]
        , HH.button
            [ cls [ "text-muted-foreground hover:text-text transition-colors" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "..." ]
        ]
    , HH.div [ cls [ "flex gap-6 mt-4 pt-4 border-t border-border" ] ]
        [ HH.div_
            [ HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "Storage" ]
            , HH.p [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text storage ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "Artifacts" ]
            , HH.p [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text artifacts ]
            ]
        ]
    ]

-- ============================================================
-- ARTIFACTS TAB
-- ============================================================

artifactsTab :: forall w i. HH.HTML w i
artifactsTab =
  HH.div_
    [ HH.div [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Artifacts" ]
        , HH.div [ cls [ "flex gap-2" ] ]
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "Search by hash or name..."
                , cls [ "px-4 py-2 bg-background border border-border rounded-md text-sm text-text placeholder:text-muted-foreground w-64" ]
                ]
            ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.table [ cls [ "w-full" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border" ] ]
                    [ HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Hash" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Name" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Size" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Uploaded" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "SLSA" ]
                    ]
                ]
            , HH.tbody_
                [ artifactRow "blake3://7f83b165..." "mypackage-1.2.0" "14.2 MB" "2 min ago" 3
                , artifactRow "blake3://a1b2c3d4..." "libfoo-3.1.4" "892 KB" "15 min ago" 3
                , artifactRow "blake3://e5f6g7h8..." "devshell" "156 MB" "1 hour ago" 2
                , artifactRow "blake3://i9j0k1l2..." "ci-tools-2.0" "45.3 MB" "3 hours ago" 3
                , artifactRow "blake3://m3n4o5p6..." "webapp-frontend" "23.1 MB" "5 hours ago" 3
                ]
            ]
        ]
    ]

artifactRow :: forall w i. String -> String -> String -> String -> Int -> HH.HTML w i
artifactRow hash name size uploaded slsa =
  HH.tr [ cls [ "border-b border-border hover:bg-card/50" ] ]
    [ HH.td [ cls [ "py-3 px-4 font-mono text-sm text-cyan-400" ] ] [ HH.text hash ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-text" ] ] [ HH.text name ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text size ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text uploaded ]
    , HH.td [ cls [ "py-3 px-4" ] ] 
        [ HH.span 
            [ cls [ "px-2 py-0.5 text-xs rounded-full bg-green-400/10 text-green-400" ] ] 
            [ HH.text ("L" <> show slsa) ]
        ]
    ]

-- ============================================================
-- ATTESTATIONS TAB
-- ============================================================

attestationsTab :: forall w i. HH.HTML w i
attestationsTab =
  HH.div_
    [ HH.div [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Attestations" ]
        , HH.div [ cls [ "flex gap-4 text-sm text-muted-foreground" ] ]
            [ HH.span_ [ HH.text "1,247 total" ]
            , HH.span [ cls [ "text-green-400" ] ] [ HH.text "1,245 valid" ]
            , HH.span [ cls [ "text-red-400" ] ] [ HH.text "2 failed" ]
            ]
        ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ attestationCard "blake3://7f83b165..." "mypackage-1.2.0" "ci.acme-corp.com" "github.com/acme/mypackage@abc123" 3 true
        , attestationCard "blake3://a1b2c3d4..." "libfoo-3.1.4" "ci.acme-corp.com" "github.com/acme/libfoo@def456" 3 true
        , attestationCard "blake3://e5f6g7h8..." "devshell" "local" "github.com/acme/devshell@ghi789" 2 true
        , attestationCard "blake3://x9y8z7w6..." "legacy-tool" "unknown" "unknown" 0 false
        ]
    ]

attestationCard :: forall w i. String -> String -> String -> String -> Int -> Boolean -> HH.HTML w i
attestationCard hash name builder source slsa valid =
  HH.div 
    [ cls [ "bg-card border rounded-lg p-6"
          , if valid then "border-border" else "border-red-400/50"
          ] 
    ]
    [ HH.div [ cls [ "flex items-start justify-between mb-4" ] ]
        [ HH.div_
            [ HH.h3 [ cls [ "text-text font-semibold mb-1" ] ] [ HH.text name ]
            , HH.p [ cls [ "text-sm text-cyan-400 font-mono" ] ] [ HH.text hash ]
            ]
        , HH.div [ cls [ "flex items-center gap-2" ] ]
            [ HH.span 
                [ cls [ "px-2 py-0.5 text-xs rounded-full"
                      , if slsa >= 3 then "bg-green-400/10 text-green-400"
                        else if slsa >= 1 then "bg-yellow-400/10 text-yellow-400"
                        else "bg-red-400/10 text-red-400"
                      ] 
                ] 
                [ HH.text ("SLSA L" <> show slsa) ]
            , HH.span 
                [ cls [ "px-2 py-0.5 text-xs rounded-full"
                      , if valid then "bg-green-400/10 text-green-400" else "bg-red-400/10 text-red-400"
                      ] 
                ] 
                [ HH.text (if valid then "Valid" else "Invalid") ]
            ]
        ]
    , HH.div [ cls [ "grid grid-cols-2 gap-4 text-sm" ] ]
        [ HH.div_
            [ HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Builder" ]
            , HH.p [ cls [ "text-text" ] ] [ HH.text builder ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Source" ]
            , HH.p [ cls [ "text-text font-mono text-xs" ] ] [ HH.text source ]
            ]
        ]
    ]

-- ============================================================
-- USAGE TAB
-- ============================================================

usageTab :: forall w i. HH.HTML w i
usageTab =
  HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-6 mb-8" ] ]
        [ usageCard "Storage" "12.4 GB" "100 GB" 12
        , usageCard "Transfer" "45.2 GB" "500 GB" 9
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] 
            [ HH.text "Usage History" ]
        , HH.div [ cls [ "space-y-4" ] ]
            [ usageHistoryRow "February 2026" "45.2 GB transfer" "12.4 GB storage"
            , usageHistoryRow "January 2026" "38.7 GB transfer" "11.8 GB storage"
            , usageHistoryRow "December 2025" "52.1 GB transfer" "10.2 GB storage"
            , usageHistoryRow "November 2025" "41.3 GB transfer" "9.4 GB storage"
            ]
        ]
    , HH.div [ cls [ "mt-6 p-4 bg-cyan-400/5 border border-cyan-400/20 rounded-lg" ] ]
        [ HH.p [ cls [ "text-sm text-cyan-400 font-medium mb-1" ] ] 
            [ HH.text "Need more capacity?" ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text "Upgrade to Pro for 100GB storage and 500GB transfer. "
            , HH.a 
                [ HP.href "/sensenet/cache/pricing"
                , cls [ "text-cyan-400 hover:text-cyan-300" ]
                ] 
                [ HH.text "View plans ->" ]
            ]
        ]
    ]

usageCard :: forall w i. String -> String -> String -> Int -> HH.HTML w i
usageCard label used total percent =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.div [ cls [ "flex items-center justify-between mb-4" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text label ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text (show percent <> "% used") ]
        ]
    , HH.div [ cls [ "h-2 bg-border rounded-full overflow-hidden mb-4" ] ]
        [ HH.div 
            [ cls [ "h-full bg-cyan-400 rounded-full" ]
            , HP.style ("width: " <> show percent <> "%")
            ] 
            []
        ]
    , HH.div [ cls [ "flex items-baseline gap-1" ] ]
        [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text used ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text (" / " <> total) ]
        ]
    ]

usageHistoryRow :: forall w i. String -> String -> String -> HH.HTML w i
usageHistoryRow month transfer storage =
  HH.div [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text month ]
    , HH.div [ cls [ "flex gap-6 text-sm text-muted-foreground" ] ]
        [ HH.span_ [ HH.text transfer ]
        , HH.span_ [ HH.text storage ]
        ]
    ]
