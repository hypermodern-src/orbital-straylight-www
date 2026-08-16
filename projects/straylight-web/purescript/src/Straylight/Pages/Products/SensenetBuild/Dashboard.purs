-- | sensenet//build Dashboard Page
module Straylight.Pages.Products.SensenetBuild.Dashboard where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

dashboardPage :: forall q i o m. H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const { activeTab: "overview" }, render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction } }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header, tabs state, content state ]

header :: forall w i. HH.HTML w i
header = HH.div [ cls [ "mb-8" ] ]
    [ HH.h1 [ cls [ "text-2xl font-bold text-text mb-2" ] ] [ HH.text "sensenet//build Dashboard" ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Manage builds, jobs, and proofs." ] ]

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state = HH.div [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton state "overview" "Overview", tabButton state "builds" "Builds"
    , tabButton state "jobs" "Jobs", tabButton state "proofs" "Proofs", tabButton state "usage" "Usage" ]

tabButton :: forall m. State -> String -> String -> H.ComponentHTML Action () m
tabButton state value label = HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px cursor-pointer"
          , if state.activeTab == value then "text-green-400 border-b-2 border-green-400" else "text-muted-foreground hover:text-text" ]
    , HP.type_ HP.ButtonButton ] [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "builds" -> buildsTab
  "jobs" -> jobsTab
  "proofs" -> proofsTab
  "usage" -> usageTab
  _ -> overviewTab

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall w i. HH.HTML w i
overviewTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Builds Today" "47" "12 verified"
        , statCard "Success Rate" "98.2%" "Last 7 days"
        , statCard "Avg Build Time" "2m 34s" "↓ 12% from last week"
        , statCard "Proofs Generated" "156" "This month" ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-6" ] ]
        [ recentBuildsCard
        , proofStatusCard
        ]
    ]

recentBuildsCard :: forall w i. HH.HTML w i
recentBuildsCard = HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Recent Builds" ]
    , HH.div [ cls [ "space-y-3" ] ]
        [ buildRow "//app:main" "verified" "2m 14s" "3 min ago"
        , buildRow "//lib:core" "verified" "45s" "12 min ago"
        , buildRow "//tests:integration" "passed" "5m 32s" "28 min ago"
        , buildRow "//deploy:prod" "verified" "1m 08s" "1 hr ago"
        , buildRow "//lib:utils" "cached" "0s" "2 hr ago"
        ]
    ]

buildRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
buildRow target status duration time =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-mono" ] ] [ HH.text target ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
        ]
    , HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text duration ]
        , statusBadge status
        ]
    ]

proofStatusCard :: forall w i. HH.HTML w i
proofStatusCard = HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Proof Status" ]
    , HH.div [ cls [ "space-y-3" ] ]
        [ proofRow "derivation_deterministic" "proven" "47 uses"
        , proofRow "content_addressing_injective" "proven" "23 uses"
        , proofRow "build_graph_acyclic" "proven" "156 uses"
        , proofRow "sandbox_isolation" "proven" "89 uses"
        , proofRow "output_reproducibility" "proven" "34 uses"
        ]
    ]

proofRow :: forall w i. String -> String -> String -> HH.HTML w i
proofRow theorem status uses =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text theorem ]
    , HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text uses ]
        , statusBadge status
        ]
    ]

-- ============================================================
-- BUILDS TAB
-- ============================================================

buildsTab :: forall w i. HH.HTML w i
buildsTab = HH.div_
    [ HH.div [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-xl font-semibold text-text" ] ] [ HH.text "Build History" ]
        , HH.div [ cls [ "flex gap-2" ] ]
            [ filterButton "All" true
            , filterButton "Verified" false
            , filterButton "Failed" false
            ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.table [ cls [ "w-full" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border bg-background/50" ] ]
                    [ HH.th [ cls [ "text-left py-3 px-4 text-sm font-medium text-muted-foreground" ] ] [ HH.text "Target" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-sm font-medium text-muted-foreground" ] ] [ HH.text "Status" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-sm font-medium text-muted-foreground" ] ] [ HH.text "Duration" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-sm font-medium text-muted-foreground" ] ] [ HH.text "Cache" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-sm font-medium text-muted-foreground" ] ] [ HH.text "Time" ]
                    ]
                ]
            , HH.tbody_
                [ buildTableRow "//app:main" "verified" "2m 14s" "87%" "3 min ago"
                , buildTableRow "//lib:core" "verified" "45s" "100%" "12 min ago"
                , buildTableRow "//tests:integration" "passed" "5m 32s" "62%" "28 min ago"
                , buildTableRow "//deploy:prod" "verified" "1m 08s" "94%" "1 hr ago"
                , buildTableRow "//lib:utils" "cached" "0s" "100%" "2 hr ago"
                , buildTableRow "//app:worker" "verified" "3m 41s" "78%" "3 hr ago"
                , buildTableRow "//tests:unit" "passed" "1m 22s" "91%" "4 hr ago"
                , buildTableRow "//lib:crypto" "failed" "0s" "0%" "5 hr ago"
                ]
            ]
        ]
    ]

filterButton :: forall w i. String -> Boolean -> HH.HTML w i
filterButton label active =
  HH.button
    [ cls [ "px-3 py-1 text-sm rounded-md transition-colors"
          , if active then "bg-green-400/10 text-green-400" else "text-muted-foreground hover:text-text"
          ] ]
    [ HH.text label ]

buildTableRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
buildTableRow target status duration cache time =
  HH.tr [ cls [ "border-b border-border last:border-0 hover:bg-card/50" ] ]
    [ HH.td [ cls [ "py-3 px-4" ] ] [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text target ] ]
    , HH.td [ cls [ "py-3 px-4" ] ] [ statusBadge status ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text duration ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text cache ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- JOBS TAB
-- ============================================================

jobsTab :: forall w i. HH.HTML w i
jobsTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-8" ] ]
        [ statCard "Active Jobs" "3" "2 remote, 1 local"
        , statCard "Queue Depth" "12" "Est. 4 min"
        , statCard "Workers Online" "8" "64 cores total"
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Jobs" ]
        , HH.div [ cls [ "space-y-4" ] ]
            [ jobCard "//app:main" "Building" "Worker 3" "1m 42s" 68
            , jobCard "//lib:parser" "Compiling" "Worker 7" "32s" 45
            , jobCard "//tests:e2e" "Linking" "Local" "4m 12s" 89
            ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Job Queue" ]
        , HH.div [ cls [ "space-y-2" ] ]
            [ queueItem "//lib:network" "Pending" "Est. 45s"
            , queueItem "//lib:storage" "Pending" "Est. 1m 20s"
            , queueItem "//app:api" "Pending" "Est. 2m 10s"
            ]
        ]
    ]

jobCard :: forall w i. String -> String -> String -> String -> Int -> HH.HTML w i
jobCard target phase worker elapsed progress =
  HH.div [ cls [ "border border-border rounded-lg p-4" ] ]
    [ HH.div [ cls [ "flex items-center justify-between mb-3" ] ]
        [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text target ]
        , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-green-400/20 text-green-400" ] ] [ HH.text phase ]
        ]
    , HH.div [ cls [ "w-full bg-background rounded-full h-2 mb-3" ] ]
        [ HH.div [ cls [ "bg-green-400 h-2 rounded-full" ]
                 , HP.style $ "width: " <> show progress <> "%" ] []
        ]
    , HH.div [ cls [ "flex items-center justify-between text-xs text-muted-foreground" ] ]
        [ HH.span_ [ HH.text worker ]
        , HH.span_ [ HH.text $ elapsed <> " elapsed" ]
        ]
    ]

queueItem :: forall w i. String -> String -> String -> HH.HTML w i
queueItem target status estimate =
  HH.div [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.code [ cls [ "text-sm text-muted-foreground font-mono" ] ] [ HH.text target ]
    , HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text estimate ]
        , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-background text-muted-foreground" ] ] [ HH.text status ]
        ]
    ]

-- ============================================================
-- PROOFS TAB
-- ============================================================

proofsTab :: forall w i. HH.HTML w i
proofsTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-8" ] ]
        [ statCard "Theorems" "47" "0 sorry"
        , statCard "Verifications" "1,247" "This month"
        , statCard "Coverage" "100%" "All derivations"
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Lean4 Proof Library" ]
        , HH.div [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ proofCategoryCard "Derivation Semantics" 
                [ "derivation_deterministic"
                , "derivation_composable"
                , "derivation_idempotent"
                ]
            , proofCategoryCard "Content Addressing"
                [ "content_addressing_injective"
                , "hash_collision_resistant"
                , "address_uniqueness"
                ]
            , proofCategoryCard "Build Graph"
                [ "build_graph_acyclic"
                , "dependency_resolution"
                , "topological_ordering"
                ]
            , proofCategoryCard "Sandbox Isolation"
                [ "sandbox_isolation"
                , "filesystem_hermetic"
                , "network_blocked"
                ]
            ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Recent Verifications" ]
        , HH.div [ cls [ "space-y-3" ] ]
            [ verificationRow "//app:main" "derivation_deterministic" "3 min ago"
            , verificationRow "//lib:core" "content_addressing_injective" "12 min ago"
            , verificationRow "//deploy:prod" "sandbox_isolation" "1 hr ago"
            ]
        ]
    ]

proofCategoryCard :: forall w i. String -> Array String -> HH.HTML w i
proofCategoryCard title theorems =
  HH.div [ cls [ "border border-border rounded-lg p-4" ] ]
    [ HH.h4 [ cls [ "text-sm font-medium text-text mb-3" ] ] [ HH.text title ]
    , HH.ul [ cls [ "space-y-1" ] ]
        (map theoremItem theorems)
    ]

theoremItem :: forall w i. String -> HH.HTML w i
theoremItem name =
  HH.li [ cls [ "flex items-center gap-2" ] ]
    [ HH.span [ cls [ "text-green-400 text-xs" ] ] [ HH.text "✓" ]
    , HH.code [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text name ]
    ]

verificationRow :: forall w i. String -> String -> String -> HH.HTML w i
verificationRow target theorem time =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text target ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text $ "Verified: " <> theorem ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- USAGE TAB
-- ============================================================

usageTab :: forall w i. HH.HTML w i
usageTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Builds" "1,247" "This month"
        , statCard "Remote Hours" "42.3 hrs" "of 100 hrs"
        , statCard "Cache Hits" "89%" "Saved 127 hrs"
        , statCard "Artifacts" "3.2 GB" "Content-addressed"
        ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6" ] ]
        [ HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Build Volume" ]
            , HH.div [ cls [ "space-y-3" ] ]
                [ usageBar "Mon" 45
                , usageBar "Tue" 62
                , usageBar "Wed" 78
                , usageBar "Thu" 54
                , usageBar "Fri" 89
                , usageBar "Sat" 23
                , usageBar "Sun" 12
                ]
            ]
        , HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Cache Performance" ]
            , HH.div [ cls [ "space-y-4" ] ]
                [ cacheMetric "Local Cache" "94%" "2.1 GB"
                , cacheMetric "Remote Cache" "87%" "1.1 GB"
                , cacheMetric "Total Savings" "127 hrs" "This month"
                ]
            ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Plan Usage" ]
        , HH.div [ cls [ "mb-4" ] ]
            [ HH.div [ cls [ "flex items-center justify-between mb-2" ] ]
                [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "Remote build hours" ]
                , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text "42.3 / 100 hrs" ]
                ]
            , HH.div [ cls [ "w-full bg-background rounded-full h-2" ] ]
                [ HH.div [ cls [ "bg-green-400 h-2 rounded-full" ]
                         , HP.style "width: 42%" ] []
                ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text "Resets in 8 days. "
            , HH.a [ cls [ "text-green-400 hover:text-green-300" ] ] [ HH.text "Upgrade plan" ]
            ]
        ]
    ]

usageBar :: forall w i. String -> Int -> HH.HTML w i
usageBar day value =
  HH.div [ cls [ "flex items-center gap-3" ] ]
    [ HH.span [ cls [ "w-8 text-xs text-muted-foreground" ] ] [ HH.text day ]
    , HH.div [ cls [ "flex-1 bg-background rounded-full h-2" ] ]
        [ HH.div [ cls [ "bg-green-400/60 h-2 rounded-full" ]
                 , HP.style $ "width: " <> show value <> "%" ] []
        ]
    , HH.span [ cls [ "w-8 text-xs text-muted-foreground text-right" ] ] [ HH.text $ show value ]
    ]

cacheMetric :: forall w i. String -> String -> String -> HH.HTML w i
cacheMetric label value detail =
  HH.div [ cls [ "flex items-center justify-between" ] ]
    [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text label ]
    , HH.div [ cls [ "text-right" ] ]
        [ HH.span [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text value ]
        , HH.span [ cls [ "text-xs text-muted-foreground ml-2" ] ] [ HH.text detail ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

statCard :: forall w i. String -> String -> String -> HH.HTML w i
statCard label value subtitle = HH.div [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text subtitle ] ]

statusBadge :: forall w i. String -> HH.HTML w i
statusBadge status =
  HH.span
    [ cls [ "text-xs px-2 py-0.5 rounded"
          , case status of
              "verified" -> "bg-green-400/20 text-green-400"
              "passed" -> "bg-green-400/20 text-green-400"
              "cached" -> "bg-blue-400/20 text-blue-400"
              "failed" -> "bg-red-400/20 text-red-400"
              "proven" -> "bg-green-400/20 text-green-400"
              _ -> "bg-muted text-muted-foreground"
          ]
    ]
    [ HH.text status ]
