-- | omega//work Dashboard Page
-- | Team activity, shared conversations, usage stats for non-coders
module Straylight.Pages.Products.OmegaWork.Dashboard where

import Prelude


import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- TYPES
-- ============================================================

type State =
  { activeTab :: String
  }

data Action
  = SetActiveTab String

-- ============================================================
-- COMPONENT
-- ============================================================

dashboardPage :: forall q i o m. H.Component q i o m
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

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetActiveTab tab -> H.modify_ _ { activeTab = tab }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , tabs state
    , content state
    ]

header :: forall w i. HH.HTML w i
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "Team Dashboard" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Monitor team activity, shared conversations, and workspace usage." ]
    ]

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state =
  HH.div
    [ cls [ "flex gap-1 border-b border-border mb-8" ] ]
    [ tabButton "overview" "Overview" state.activeTab
    , tabButton "activity" "Team Activity" state.activeTab
    , tabButton "conversations" "Shared Conversations" state.activeTab
    , tabButton "usage" "Usage Stats" state.activeTab
    ]

tabButton :: forall m. String -> String -> String -> H.ComponentHTML Action () m
tabButton value label activeTab =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px"
          , if value == activeTab 
              then "text-indigo-400 border-b-2 border-indigo-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetActiveTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "activity" -> activityTab
  "conversations" -> conversationsTab
  "usage" -> usageTab
  _ -> overviewTab

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall w i. HH.HTML w i
overviewTab =
  HH.div_
    [ -- Stats grid
      HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Plan" "Team" "12 seats"
        , statCard "Team Members" "12" "Active"
        , statCard "Workspaces" "4" "Marketing, Product, Design, Ops"
        , statCard "Conversations" "847" "This month"
        ]
    
      -- Quick actions
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-8" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Quick Actions" ]
        , HH.div
            [ cls [ "flex flex-wrap gap-3" ] ]
            [ actionButton "Invite Team Member" "/omega/work/settings#team"
            , actionButton "Create Workspace" "/omega/work/settings#workspaces"
            , actionButton "View Docs" "/omega/work/docs"
            , actionButton "Manage Billing" "/omega/work/settings#billing"
            ]
        ]
    
      -- Recent team activity
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Recent Team Activity" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ activityItem "Sarah" "Shared conversation 'Q1 Planning Brief'" "2 hours ago"
            , activityItem "Mike" "Created workspace 'Brand Guidelines'" "Yesterday"
            , activityItem "Lisa" "Generated report 'Monthly Metrics'" "Yesterday"
            , activityItem "Tom" "Added context 'Style Guide v2' to Design workspace" "2 days ago"
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

actionButton :: forall w i. String -> String -> HH.HTML w i
actionButton label href =
  HH.a
    [ HP.href href
    , cls [ "px-4 py-2 bg-indigo-400/10 text-indigo-400 text-sm font-medium rounded-md hover:bg-indigo-400/20 transition-colors" ]
    ]
    [ HH.text label ]

activityItem :: forall w i. String -> String -> String -> HH.HTML w i
activityItem member description time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded font-medium bg-indigo-400/10 text-indigo-400" ] ]
            [ HH.text member ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text description ]
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- TEAM ACTIVITY TAB
-- ============================================================

activityTab :: forall w i. HH.HTML w i
activityTab =
  HH.div_
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Team Activity Feed" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ teamActivityRow "Sarah Chen" "PM" "Shared 'Product Roadmap Q2' to Product workspace" "10 min ago"
            , teamActivityRow "Mike Johnson" "Designer" "Created conversation 'Homepage Redesign Ideas'" "1 hour ago"
            , teamActivityRow "Lisa Park" "Analyst" "Exported 'Monthly Revenue Report' to Google Docs" "2 hours ago"
            , teamActivityRow "Tom Wilson" "Ops" "Updated shared context 'SOP Templates'" "3 hours ago"
            , teamActivityRow "Emma Davis" "PM" "Invited Alex to Marketing workspace" "Yesterday"
            , teamActivityRow "James Lee" "Designer" "Shared 'Brand Color Exploration' with team" "Yesterday"
            ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Active Team Members" ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ memberCard "Sarah Chen" "PM" true
            , memberCard "Mike Johnson" "Designer" true
            , memberCard "Lisa Park" "Analyst" false
            , memberCard "Tom Wilson" "Ops" true
            ]
        ]
    ]

teamActivityRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
teamActivityRow name role action time =
  HH.div
    [ cls [ "flex items-start justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2 mb-1" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-indigo-400/10 text-indigo-400" ] ] [ HH.text role ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text action ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground whitespace-nowrap" ] ] [ HH.text time ]
    ]

memberCard :: forall w i. String -> String -> Boolean -> HH.HTML w i
memberCard name role online =
  HH.div
    [ cls [ "p-3 bg-card border border-border rounded-lg" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-2" ] ]
        [ HH.span 
            [ cls [ "w-2 h-2 rounded-full", if online then "bg-green-400" else "bg-muted-foreground" ] ] 
            []
        , HH.span [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        ]
    , HH.p [ cls [ "text-xs text-muted-foreground mt-1" ] ] [ HH.text role ]
    ]

-- ============================================================
-- SHARED CONVERSATIONS TAB
-- ============================================================

conversationsTab :: forall w i. HH.HTML w i
conversationsTab =
  HH.div_
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Shared Conversations" ]
            , HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "Search conversations..."
                , cls [ "px-3 py-2 bg-background border border-border rounded-md text-sm text-text w-64" ]
                ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ sharedConvoRow "Q1 Planning Brief" "Sarah Chen" "Product" "2 hours ago"
            , sharedConvoRow "Homepage Redesign Ideas" "Mike Johnson" "Design" "5 hours ago"
            , sharedConvoRow "Monthly Metrics Analysis" "Lisa Park" "Marketing" "Yesterday"
            , sharedConvoRow "Customer Feedback Summary" "Emma Davis" "Product" "2 days ago"
            , sharedConvoRow "Social Media Calendar Draft" "Tom Wilson" "Marketing" "3 days ago"
            ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Recently Viewed" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ sharedConvoRow "Brand Guidelines v2" "Mike Johnson" "Design" "Viewed 1 hour ago"
            , sharedConvoRow "Onboarding Checklist" "Tom Wilson" "Ops" "Viewed yesterday"
            ]
        ]
    ]

sharedConvoRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
sharedConvoRow title author workspace time =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0 cursor-pointer hover:bg-card/50" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text title ]
        , HH.div
            [ cls [ "flex items-center gap-2 text-xs text-muted-foreground" ] ]
            [ HH.span_ [ HH.text author ]
            , HH.span_ [ HH.text "in" ]
            , HH.span [ cls [ "text-indigo-400" ] ] [ HH.text workspace ]
            ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- USAGE STATS TAB
-- ============================================================

usageTab :: forall w i. HH.HTML w i
usageTab =
  HH.div_
    [ HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6 mb-8" ] ]
        [ usageCard "Team Conversations" 847 (-1) "this month"
        , usageCard "Shared Contexts" 23 (-1) "files"
        , usageCard "Integrations Used" 156 (-1) "syncs this week"
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Usage by Workspace" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ workspaceUsageRow "Marketing" 312 37
            , workspaceUsageRow "Product" 245 29
            , workspaceUsageRow "Design" 178 21
            , workspaceUsageRow "Operations" 112 13
            ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Usage by Team Member" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ memberUsageRow "Sarah Chen" 156 18
            , memberUsageRow "Mike Johnson" 134 16
            , memberUsageRow "Lisa Park" 98 12
            , memberUsageRow "Tom Wilson" 87 10
            ]
        ]
    ]

workspaceUsageRow :: forall w i. String -> Int -> Int -> HH.HTML w i
workspaceUsageRow name conversations percentage =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text name ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text $ show conversations <> " conversations" ]
        , HH.span [ cls [ "text-sm text-indigo-400" ] ] 
            [ HH.text $ show percentage <> "%" ]
        ]
    ]

memberUsageRow :: forall w i. String -> Int -> Int -> HH.HTML w i
memberUsageRow name conversations percentage =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text name ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text $ show conversations <> " conversations" ]
        , HH.span [ cls [ "text-sm text-indigo-400" ] ] 
            [ HH.text $ show percentage <> "%" ]
        ]
    ]

usageCard :: forall w i. String -> Int -> Int -> String -> HH.HTML w i
usageCard label current limit unit =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.span [ cls [ "text-sm font-medium text-text" ] ] [ HH.text label ]
        ]
    , HH.div
        [ cls [ "flex items-baseline gap-2" ] ]
        [ HH.span [ cls [ "text-2xl font-bold text-indigo-400" ] ] [ HH.text $ show current ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text unit ]
        ]
    ]


