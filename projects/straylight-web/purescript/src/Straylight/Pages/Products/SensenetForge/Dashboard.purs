-- | sensenet//forge Dashboard Page
-- | Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design.
module Straylight.Pages.Products.SensenetForge.Dashboard where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- TYPES
-- ============================================================

type State =
  { activeTab :: String
  }

data Action
  = SetTab String

-- ============================================================
-- COMPONENT
-- ============================================================

dashboardPage :: forall q i o m. H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const { activeTab: "repos" }
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      }
  }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , tabs state.activeTab
    , content state
    ]

header :: forall w i. HH.HTML w i
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "Dashboard" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Manage your repositories, diffs, and reviews." ]
    ]

tabs :: forall w i. String -> HH.HTML w i
tabs activeTab =
  HH.div
    [ cls [ "flex gap-1 p-1 bg-muted/30 rounded-lg w-fit mb-8" ] ]
    [ tabButton "repos" "Repositories" activeTab
    , tabButton "diffs" "Diffs" activeTab
    , tabButton "reviews" "Reviews" activeTab
    , tabButton "activity" "Activity" activeTab
    ]

tabButton :: forall w i. String -> String -> String -> HH.HTML w i
tabButton value label activeTab =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium rounded-md transition-colors"
          , if value == activeTab 
              then "bg-card text-text shadow-sm" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "repos" -> reposTab
  "diffs" -> diffsTab
  "reviews" -> reviewsTab
  "activity" -> activityTab
  _ -> reposTab

-- ============================================================
-- REPOS TAB
-- ============================================================

reposTab :: forall w i. HH.HTML w i
reposTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Your Repositories" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ New Repository" ]
        ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ repoCard 
            { name: "straylight-web"
            , description: "Main web application"
            , visibility: "private"
            , diffs: 3
            , lastUpdate: "2 hours ago"
            }
        , repoCard 
            { name: "forge-cli"
            , description: "Command-line interface for forge"
            , visibility: "public"
            , diffs: 7
            , lastUpdate: "1 day ago"
            }
        , repoCard 
            { name: "sensenet-core"
            , description: "Core infrastructure libraries"
            , visibility: "private"
            , diffs: 12
            , lastUpdate: "3 days ago"
            }
        ]
    ]

type RepoConfig =
  { name :: String
  , description :: String
  , visibility :: String
  , diffs :: Int
  , lastUpdate :: String
  }

repoCard :: forall w i. RepoConfig -> HH.HTML w i
repoCard config =
  HH.a
    [ HP.href $ "/sensenet/forge/repo/" <> config.name
    , cls [ "block bg-card border border-border rounded-lg p-4 hover:border-rose-400/50 transition-colors" ]
    ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text config.name ]
            , HH.span
                [ cls [ "text-xs px-2 py-0.5 rounded"
                      , if config.visibility == "private" 
                          then "bg-muted text-muted-foreground" 
                          else "bg-rose-400/20 text-rose-400"
                      ]
                ]
                [ HH.text config.visibility ]
            ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text config.lastUpdate ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-3" ] ]
        [ HH.text config.description ]
    , HH.div
        [ cls [ "flex items-center gap-4 text-xs text-muted-foreground" ] ]
        [ HH.span_ [ HH.text $ show config.diffs <> " open diffs" ]
        ]
    ]

-- ============================================================
-- DIFFS TAB
-- ============================================================

diffsTab :: forall w i. HH.HTML w i
diffsTab =
  HH.div_
    [ -- Active stacks section
      HH.div
        [ cls [ "mb-8" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Stacks" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ stackCard
                { name: "Auth improvements"
                , repo: "straylight-web"
                , diffs:
                    [ { id: "D042", title: "Add rate limiting", status: "needs_review" }
                    , { id: "D041", title: "Refactor auth module", status: "approved" }
                    , { id: "D040", title: "Add OAuth support", status: "needs_review" }
                    ]
                }
            , stackCard
                { name: "CLI enhancements"
                , repo: "forge-cli"
                , diffs:
                    [ { id: "D045", title: "Add verbose output", status: "needs_review" }
                    , { id: "D044", title: "Improve error messages", status: "approved" }
                    ]
                }
            ]
        ]
      -- Individual diffs section
    , HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "All Diffs" ]
        , HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ filterButton "all" "All" true
            , filterButton "needs_review" "Needs Review" false
            , filterButton "approved" "Approved" false
            , filterButton "landed" "Landed" false
            ]
        ]
    , HH.div
        [ cls [ "space-y-3" ] ]
        [ diffRow
            { id: "D042"
            , title: "Add rate limiting to API endpoints"
            , repo: "straylight-web"
            , status: "needs_review"
            , author: "claude-opus-4"
            , isAgent: true
            , updated: "10 minutes ago"
            }
        , diffRow
            { id: "D041"
            , title: "Refactor authentication module"
            , repo: "straylight-web"
            , status: "approved"
            , author: "alice"
            , isAgent: false
            , updated: "2 hours ago"
            }
        , diffRow
            { id: "D040"
            , title: "Add OAuth support"
            , repo: "straylight-web"
            , status: "needs_review"
            , author: "alice"
            , isAgent: false
            , updated: "5 hours ago"
            }
        , diffRow
            { id: "D039"
            , title: "Fix session timeout handling"
            , repo: "forge-cli"
            , status: "landed"
            , author: "bob"
            , isAgent: false
            , updated: "1 day ago"
            }
        ]
    ]

-- Stack visualization card
type StackConfig =
  { name :: String
  , repo :: String
  , diffs :: Array { id :: String, title :: String, status :: String }
  }

stackCard :: forall w i. StackConfig -> HH.HTML w i
stackCard config =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 hover:border-rose-400/50 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-3" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text config.name ]
        , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text config.repo ]
        ]
    , HH.div
        [ cls [ "space-y-2" ] ]
        (map stackDiffItem config.diffs)
    ]

stackDiffItem :: forall w i. { id :: String, title :: String, status :: String } -> HH.HTML w i
stackDiffItem diff =
  HH.div
    [ cls [ "flex items-center gap-3 pl-3 border-l-2 border-rose-400/30" ] ]
    [ HH.span [ cls [ "text-rose-400 font-mono text-xs" ] ] [ HH.text diff.id ]
    , HH.span [ cls [ "text-sm text-muted-foreground flex-1 truncate" ] ] [ HH.text diff.title ]
    , stackStatusDot diff.status
    ]

stackStatusDot :: forall w i. String -> HH.HTML w i
stackStatusDot status =
  HH.span
    [ cls [ "w-2 h-2 rounded-full", statusDotColor status ] ]
    []

statusDotColor :: String -> String
statusDotColor = case _ of
  "needs_review" -> "bg-yellow-400"
  "approved" -> "bg-green-400"
  "landed" -> "bg-muted-foreground"
  "changes_requested" -> "bg-red-400"
  _ -> "bg-muted-foreground"

filterButton :: forall w i. String -> String -> Boolean -> HH.HTML w i
filterButton _ label active =
  HH.button
    [ cls [ "px-3 py-1 text-xs font-medium rounded-md transition-colors"
          , if active 
              then "bg-rose-400/20 text-rose-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    ]
    [ HH.text label ]

type DiffConfig =
  { id :: String
  , title :: String
  , repo :: String
  , status :: String
  , author :: String
  , isAgent :: Boolean
  , updated :: String
  }

diffRow :: forall w i. DiffConfig -> HH.HTML w i
diffRow config =
  HH.a
    [ HP.href $ "/sensenet/forge/diff/" <> config.id
    , cls [ "block bg-card border border-border rounded-lg p-4 hover:border-rose-400/50 transition-colors" ]
    ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-rose-400 font-mono text-sm" ] ] [ HH.text config.id ]
            , HH.span [ cls [ "text-text font-medium" ] ] [ HH.text config.title ]
            ]
        , statusBadge config.status
        ]
    , HH.div
        [ cls [ "flex items-center gap-4 text-xs text-muted-foreground" ] ]
        [ HH.span_ [ HH.text config.repo ]
        , HH.div
            [ cls [ "flex items-center gap-1" ] ]
            [ if config.isAgent 
                then HH.span [ cls [ "px-1.5 py-0.5 rounded bg-rose-400/20 text-rose-400" ] ] [ HH.text "agent" ]
                else HH.text ""
            , HH.span_ [ HH.text config.author ]
            ]
        , HH.span_ [ HH.text config.updated ]
        ]
    ]

statusBadge :: forall w i. String -> HH.HTML w i
statusBadge status =
  HH.span
    [ cls [ "text-xs px-2 py-0.5 rounded font-medium", statusColor status ] ]
    [ HH.text $ statusLabel status ]

statusColor :: String -> String
statusColor = case _ of
  "needs_review" -> "bg-yellow-500/20 text-yellow-400"
  "approved" -> "bg-green-500/20 text-green-400"
  "landed" -> "bg-muted text-muted-foreground"
  "changes_requested" -> "bg-red-500/20 text-red-400"
  _ -> "bg-muted text-muted-foreground"

statusLabel :: String -> String
statusLabel = case _ of
  "needs_review" -> "Needs Review"
  "approved" -> "Approved"
  "landed" -> "Landed"
  "changes_requested" -> "Changes Requested"
  s -> s

-- ============================================================
-- REVIEWS TAB
-- ============================================================

reviewsTab :: forall w i. HH.HTML w i
reviewsTab =
  HH.div_
    [ HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Pending Reviews" ] ]
    , HH.div
        [ cls [ "space-y-3" ] ]
        [ reviewRow
            { id: "D045"
            , title: "Add GraphQL subscriptions"
            , repo: "straylight-web"
            , author: "carol"
            , isAgent: false
            , requestedAt: "1 hour ago"
            }
        , reviewRow
            { id: "D044"
            , title: "Implement webhook handlers"
            , repo: "forge-cli"
            , author: "gpt-4"
            , isAgent: true
            , requestedAt: "3 hours ago"
            }
        ]
    , HH.div
        [ cls [ "mt-12 mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Your Reviews" ] ]
    , HH.div
        [ cls [ "space-y-3" ] ]
        [ reviewHistoryRow "D041" "Approved" "2 hours ago"
        , reviewHistoryRow "D038" "Commented" "1 day ago"
        , reviewHistoryRow "D035" "Approved" "3 days ago"
        ]
    ]

type ReviewConfig =
  { id :: String
  , title :: String
  , repo :: String
  , author :: String
  , isAgent :: Boolean
  , requestedAt :: String
  }

reviewRow :: forall w i. ReviewConfig -> HH.HTML w i
reviewRow config =
  HH.a
    [ HP.href $ "/sensenet/forge/diff/" <> config.id
    , cls [ "block bg-card border border-border rounded-lg p-4 hover:border-rose-400/50 transition-colors" ]
    ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-rose-400 font-mono text-sm" ] ] [ HH.text config.id ]
            , HH.span [ cls [ "text-text font-medium" ] ] [ HH.text config.title ]
            ]
        , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-500/20 text-yellow-400" ] ] 
            [ HH.text "Review Requested" ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4 text-xs text-muted-foreground" ] ]
        [ HH.span_ [ HH.text config.repo ]
        , HH.div
            [ cls [ "flex items-center gap-1" ] ]
            [ if config.isAgent 
                then HH.span [ cls [ "px-1.5 py-0.5 rounded bg-rose-400/20 text-rose-400" ] ] [ HH.text "agent" ]
                else HH.text ""
            , HH.span_ [ HH.text $ "by " <> config.author ]
            ]
        , HH.span_ [ HH.text $ "requested " <> config.requestedAt ]
        ]
    ]

reviewHistoryRow :: forall w i. String -> String -> String -> HH.HTML w i
reviewHistoryRow diffId action time =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-rose-400 font-mono text-sm" ] ] [ HH.text diffId ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text action ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- ACTIVITY TAB
-- ============================================================

activityTab :: forall w i. HH.HTML w i
activityTab =
  HH.div_
    [ HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Recent Activity" ] ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ activityItem "D042" "created" "claude-opus-4" "10 minutes ago" true
        , activityItem "D041" "approved" "bob" "2 hours ago" false
        , activityItem "D040" "updated" "alice" "5 hours ago" false
        , activityItem "D039" "landed" "bob" "1 day ago" false
        , activityItem "D038" "commented" "carol" "1 day ago" false
        , activityItem "D037" "landed" "alice" "2 days ago" false
        ]
    ]

activityItem :: forall w i. String -> String -> String -> String -> Boolean -> HH.HTML w i
activityItem diffId action actor time isAgent =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-rose-400 font-mono text-sm" ] ] [ HH.text diffId ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text action ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text "by" ]
        , HH.div
            [ cls [ "flex items-center gap-1" ] ]
            [ if isAgent 
                then HH.span [ cls [ "px-1.5 py-0.5 rounded bg-rose-400/20 text-rose-400 text-xs" ] ] [ HH.text "agent" ]
                else HH.text ""
            , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text actor ]
            ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]
