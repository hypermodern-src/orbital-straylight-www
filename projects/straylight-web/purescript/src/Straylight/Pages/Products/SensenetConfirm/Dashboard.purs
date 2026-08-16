-- | sensenet//confirm Dashboard Page
-- | Main admin portal for CI management
module Straylight.Pages.Products.SensenetConfirm.Dashboard where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- TYPES
-- ============================================================

type State =
  { activeTab :: String
  }

type Slots :: Row Type
type Slots = ()

data Action
  = SetTab String

-- ============================================================
-- COMPONENT
-- ============================================================

dashboardPage :: forall q i o m. MonadAff m => H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const initialState
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      }
  }

initialState :: State
initialState =
  { activeTab: "overview"
  }

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action Slots o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , tabs state
    , agentReviewBanner
    , content state
    ]

header :: forall m. MonadAff m => H.ComponentHTML Action Slots m
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "Dashboard" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Manage your pipelines, builds, and proofs." ]
    ]

tabs :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
tabs state =
  HH.div
    [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton state "overview" "Overview"
    , tabButton state "builds" "Builds"
    , tabButton state "pipelines" "Pipelines"
    , tabButton state "proofs" "Proofs"
    , tabButton state "reviews" "Agent Reviews"
    , tabButton state "apikeys" "API Keys"
    ]

tabButton :: forall m. MonadAff m => State -> String -> String -> H.ComponentHTML Action Slots m
tabButton state value label =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors cursor-pointer -mb-px"
          , if state.activeTab == value
              then "text-amber-400 border-b-2 border-amber-400"
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

agentReviewBanner :: forall m. MonadAff m => H.ComponentHTML Action Slots m
agentReviewBanner =
  HH.div
    [ cls [ "mb-6 p-4 bg-amber-400/10 border border-amber-400/20 rounded-lg flex items-center justify-between" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-amber-400 font-mono text-lg" ] ] [ HH.text "!" ]
        , HH.div_
            [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text "3 agent-generated commits pending review" ]
            , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Higher review burden required for AI-generated code" ]
            ]
        ]
    , HH.a
        [ HP.href "/sensenet/confirm/dashboard/reviews"
        , cls [ "text-sm text-amber-400 hover:text-amber-400/80" ]
        ]
        [ HH.text "Review now ->" ]
    ]

content :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
content state = case state.activeTab of
  "overview" -> overviewTab
  "builds" -> buildsTab
  "pipelines" -> pipelinesTab
  "proofs" -> proofsTab
  "reviews" -> agentReviewsTab
  "apikeys" -> apiKeysTab
  _ -> overviewTab

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
overviewTab =
  HH.div_
    [ -- Stats grid
      HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Build Minutes" "4,521" "of 5,000 this month"
        , statCard "Success Rate" "94.2%" "last 30 days"
        , statCard "Proofs Verified" "1,247" "this month"
        , statCard "Active Pipelines" "12" "across repos"
        ]
      -- Agent code alert
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 mb-8" ] ]
        [ HH.div
            [ cls [ "bg-card border border-amber-400/30 rounded-lg p-4" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-2 mb-2" ] ]
                [ HH.span [ cls [ "text-amber-400 font-mono" ] ] [ HH.text "!" ]
                , HH.span [ cls [ "text-sm font-medium text-text" ] ] [ HH.text "Agent Code Reviews Pending" ]
                ]
            , HH.p [ cls [ "text-2xl font-bold text-amber-400" ] ] [ HH.text "3" ]
            , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "AI-generated commits awaiting elevated review" ]
            ]
        , HH.div
            [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-2 mb-2" ] ]
                [ HH.span [ cls [ "text-green-400 font-mono" ] ] [ HH.text "=" ]
                , HH.span [ cls [ "text-sm font-medium text-text" ] ] [ HH.text "Attestations Issued" ]
                ]
            , HH.p [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "847" ]
            , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Post-quantum signed this month" ]
            ]
        ]
    
      -- Recent builds
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-8" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Recent Builds" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ buildRow "main" "abc123" "passed" "2m 34s" "5 min ago"
            , buildRow "feature/auth" "def456" "passed" "3m 12s" "12 min ago"
            , buildRow "fix/typo" "ghi789" "failed" "1m 45s" "1 hour ago"
            , buildRow "main" "jkl012" "passed" "2m 58s" "2 hours ago"
            ]
        ]
    
      -- Quick start
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Quick Start" ]
        , codeBlock
            [ codeLine "# " "Run your pipeline"
            , codeLine "$ " "confirm run"
            , HH.text "\n"
            , codeLine "# " "Run with proof verification"
            , codeLine "$ " "confirm run --verify"
            ]
        ]
    ]

statCard :: forall w i. String -> String -> String -> HH.HTML w i
statCard label value subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.p
        [ cls [ "text-sm text-muted-foreground mb-1" ] ]
        [ HH.text label ]
    , HH.p
        [ cls [ "text-2xl font-bold text-text" ] ]
        [ HH.text value ]
    , HH.p
        [ cls [ "text-xs text-muted-foreground" ] ]
        [ HH.text subtitle ]
    ]

buildRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
buildRow branch commit status duration time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded font-medium"
                  , case status of
                      "passed" -> "bg-green-500/20 text-green-400"
                      "failed" -> "bg-red-500/20 text-red-400"
                      _ -> "bg-amber-400/20 text-amber-400"
                  ]
            ]
            [ HH.text status ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text branch ]
        , HH.span [ cls [ "text-sm text-muted-foreground font-mono" ] ] [ HH.text commit ]
        ]
    , HH.div
        [ cls [ "text-right" ] ]
        [ HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text duration ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
        ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]

-- ============================================================
-- BUILDS TAB
-- ============================================================

buildsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
buildsTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Build History" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Trigger Build" ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-6 gap-4 px-4 py-3 border-b border-border bg-muted/50 text-xs font-medium text-muted-foreground uppercase tracking-wider" ] ]
            [ HH.span_ [ HH.text "Status" ]
            , HH.span [ cls [ "col-span-2" ] ] [ HH.text "Build" ]
            , HH.span_ [ HH.text "Duration" ]
            , HH.span_ [ HH.text "Proofs" ]
            , HH.span_ [ HH.text "" ]
            ]
        , HH.div_
            [ fullBuildRow "passed" "main" "abc123" "2m 34s" 3 "/sensenet/confirm/builds/1"
            , fullBuildRow "passed" "feature/auth" "def456" "3m 12s" 2 "/sensenet/confirm/builds/2"
            , fullBuildRow "failed" "fix/typo" "ghi789" "1m 45s" 0 "/sensenet/confirm/builds/3"
            , fullBuildRow "passed" "main" "jkl012" "2m 58s" 3 "/sensenet/confirm/builds/4"
            ]
        ]
    ]

fullBuildRow :: forall w i. String -> String -> String -> String -> Int -> String -> HH.HTML w i
fullBuildRow status branch commit duration proofs logUrl =
  HH.div
    [ cls [ "grid grid-cols-6 gap-4 px-4 py-3 border-b border-border last:border-0 hover:bg-muted/30" ] ]
    [ HH.span
        [ cls [ "flex items-center" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded font-medium"
                  , case status of
                      "passed" -> "bg-green-500/20 text-green-400"
                      "failed" -> "bg-red-500/20 text-red-400"
                      _ -> "bg-amber-400/20 text-amber-400"
                  ]
            ]
            [ HH.text status ]
        ]
    , HH.div
        [ cls [ "col-span-2" ] ]
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text branch ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text commit ]
        ]
    , HH.span [ cls [ "flex items-center text-sm text-muted-foreground" ] ] [ HH.text duration ]
    , HH.span [ cls [ "flex items-center text-sm text-amber-400" ] ] [ HH.text $ show proofs <> " verified" ]
    , HH.span
        [ cls [ "flex items-center justify-end" ] ]
        [ HH.a
            [ HP.href logUrl
            , cls [ "text-xs text-amber-400 hover:underline" ]
            ]
            [ HH.text "View logs" ]
        ]
    ]

-- ============================================================
-- PIPELINES TAB
-- ============================================================

pipelinesTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
pipelinesTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Pipelines" ]
        ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ pipelineCard "my-app" "main" "pipeline.dhall" "5 min ago" true
        , pipelineCard "api-service" "main" "ci/pipeline.dhall" "1 hour ago" true
        , pipelineCard "docs" "main" "pipeline.dhall" "2 days ago" false
        ]
    ]

pipelineCard :: forall w i. String -> String -> String -> String -> Boolean -> HH.HTML w i
pipelineCard repo branch file lastRun active =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text repo ]
            , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text branch ]
            ]
        , HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded"
                  , if active then "bg-green-500/20 text-green-400" else "bg-muted text-muted-foreground"
                  ]
            ]
            [ HH.text $ if active then "active" else "inactive" ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4 text-sm text-muted-foreground" ] ]
        [ HH.span [ cls [ "font-mono" ] ] [ HH.text file ]
        , HH.span_ [ HH.text $ "Last run: " <> lastRun ]
        ]
    ]

-- ============================================================
-- PROOFS TAB
-- ============================================================

proofsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
proofsTab =
  HH.div_
    [ HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text "Proof Obligations" ]
        , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "Track proof verification across your pipelines." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-8" ] ]
        [ proofStatCard "Verified" "1,247" "text-green-400"
        , proofStatCard "Failed" "23" "text-red-400"
        , proofStatCard "Skipped" "15" "text-muted-foreground"
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-text font-medium mb-4" ] ] [ HH.text "Recent Proof Results" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ proofRow "testsPass" "my-app" "verified" "5 min ago"
            , proofRow "noWarnings" "my-app" "verified" "5 min ago"
            , proofRow "coverageMin(80)" "api-service" "failed" "1 hour ago"
            , proofRow "testsPass" "api-service" "verified" "1 hour ago"
            ]
        ]
    ]

proofStatCard :: forall w i. String -> String -> String -> HH.HTML w i
proofStatCard label value color =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold", color ] ] [ HH.text value ]
    ]

proofRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
proofRow proof repo status time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-sm font-mono text-amber-400" ] ] [ HH.text proof ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text repo ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded"
                  , if status == "verified" then "bg-green-500/20 text-green-400" else "bg-red-500/20 text-red-400"
                  ]
            ]
            [ HH.text status ]
        , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
        ]
    ]

-- ============================================================
-- API KEYS TAB
-- ============================================================

apiKeysTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
apiKeysTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "API Keys" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ New Key" ]
        ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ apiKeyCard "CI Pipeline" "confirm_live_ci_***" "push, build" "2 days ago"
        , apiKeyCard "Local Dev" "confirm_live_dev_***" "build" "1 week ago"
        ]
    ]

apiKeyCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
apiKeyCard name prefix scopes lastUsed =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.button
            [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    , HH.code [ cls [ "block text-sm font-mono text-muted-foreground mb-2" ] ] [ HH.text prefix ]
    , HH.div
        [ cls [ "flex items-center gap-4 text-xs text-muted-foreground" ] ]
        [ HH.span_ [ HH.text $ "Scopes: " <> scopes ]
        , HH.span_ [ HH.text $ "Last used: " <> lastUsed ]
        ]
    ]

-- ============================================================
-- AGENT REVIEWS TAB
-- ============================================================

agentReviewsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
agentReviewsTab =
  HH.div_
    [ HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text "Agent Code Reviews" ]
        , HH.p [ cls [ "text-muted-foreground text-sm" ] ] 
            [ HH.text "AI-generated commits face higher review burden. Approve or reject pending changes." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-8" ] ]
        [ agentStatCard "Pending Review" "3" "text-amber-400"
        , agentStatCard "Approved" "42" "text-green-400"
        , agentStatCard "Rejected" "7" "text-red-400"
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-text font-medium mb-4" ] ] [ HH.text "Pending Agent Reviews" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ agentReviewCard "feat: add user authentication" "Copilot" "my-app" "abc123" "4 approvals required"
            , agentReviewCard "fix: resolve null pointer exception" "Claude" "api-service" "def456" "3 approvals + security review"
            , agentReviewCard "refactor: optimize database queries" "Copilot" "backend" "ghi789" "3 approvals required"
            ]
        ]
    ]

agentStatCard :: forall w i. String -> String -> String -> HH.HTML w i
agentStatCard label value color =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold", color ] ] [ HH.text value ]
    ]

agentReviewCard :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
agentReviewCard title source repo commit requirement =
  HH.div
    [ cls [ "p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-3" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span
                [ cls [ "text-xs px-2 py-0.5 rounded bg-amber-400/20 text-amber-400" ] ]
                [ HH.text source ]
            , HH.span [ cls [ "text-sm text-text font-medium" ] ] [ HH.text title ]
            ]
        , HH.span [ cls [ "text-xs font-mono text-muted-foreground" ] ] [ HH.text commit ]
        ]
    , HH.div
        [ cls [ "flex items-center justify-between" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text repo ]
            , HH.span [ cls [ "text-xs text-amber-400" ] ] [ HH.text requirement ]
            ]
        , HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.button
                [ cls [ "px-3 py-1 text-xs border border-green-500 text-green-400 rounded hover:bg-green-500/10 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Approve" ]
            , HH.button
                [ cls [ "px-3 py-1 text-xs border border-red-500 text-red-400 rounded hover:bg-red-500/10 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Reject" ]
            ]
        ]
    ]
