-- | sensenet//converge Dashboard Page
-- | Main admin portal for infrastructure management
module Straylight.Pages.Products.SensenetConverge.Dashboard where

import Prelude

import Data.Array (length)
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

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. MonadAff m => State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , tabs state
    , content state
    ]

header :: forall m. MonadAff m => H.ComponentHTML Action () m
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "sensenet//converge" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Manage your infrastructure, monitor drift, and track convergence." ]
    ]

tabs :: forall m. MonadAff m => State -> H.ComponentHTML Action () m
tabs state =
  HH.div
    [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton "overview" "Overview" state.activeTab
    , tabButton "resources" "Resources" state.activeTab
    , tabButton "drift" "Drift" state.activeTab
    , tabButton "history" "History" state.activeTab
    , tabButton "settings" "Settings" state.activeTab
    ]

tabButton :: forall m. MonadAff m => String -> String -> String -> H.ComponentHTML Action () m
tabButton value label activeTab =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px"
          , if value == activeTab 
              then "text-purple-400 border-b-2 border-purple-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HE.onClick \_ -> SetTab value
    , HP.type_ HP.ButtonButton
    ]
    [ HH.text label ]

content :: forall m. MonadAff m => State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "resources" -> resourcesTab
  "drift" -> driftTab
  "history" -> historyTab
  "settings" -> settingsTab
  _ -> overviewTab

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall m. MonadAff m => H.ComponentHTML Action () m
overviewTab =
  HH.div_
    [ -- Stats grid
      HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Resources" "47" "managed"
        , statCard "In Sync" "46" "converged"
        , statCard "Drifted" "1" "needs attention"
        , statCard "Last Converge" "2m ago" "successful"
        ]
    
      -- Quick actions
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-6 mb-8" ] ]
        [ -- Drift status
          HH.div
            [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text mb-4" ] ]
                [ HH.text "Drift Status" ]
            , HH.div
                [ cls [ "space-y-3" ] ]
                [ driftItem "aws.ec2.Instance.web" "in sync" true
                , driftItem "aws.ec2.SecurityGroup.web_sg" "drifted" false
                , driftItem "aws.rds.Instance.db" "in sync" true
                , driftItem "aws.s3.Bucket.assets" "in sync" true
                ]
            ]
        
          -- Quick start
        , HH.div
            [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text mb-4" ] ]
                [ HH.text "Quick Actions" ]
            , codeBlock
                [ codeLine "# " "Converge now"
                , codeLine "$ " "converge up"
                , HH.text "\n"
                , codeLine "# " "Watch for drift"
                , codeLine "$ " "converge watch"
                ]
            ]
        ]
    
      -- Recent activity
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Recent Activity" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ activityItem "Converge" "47 resources" "2 minutes ago"
            , activityItem "Drift detected" "aws.ec2.SecurityGroup.web_sg" "15 minutes ago"
            , activityItem "Resource added" "aws.s3.Bucket.logs" "1 hour ago"
            , activityItem "Converge" "46 resources" "2 hours ago"
            ]
        ]
    ]

driftItem :: forall w i. String -> String -> Boolean -> HH.HTML w i
driftItem name status synced =
  HH.div
    [ cls [ "flex items-center justify-between p-3 bg-background rounded" ] ]
    [ HH.span [ cls [ "text-sm font-mono text-text" ] ] [ HH.text name ]
    , HH.span 
        [ cls [ "text-xs px-2 py-1 rounded"
              , if synced then "bg-purple-400/20 text-purple-400" else "bg-yellow-500/20 text-yellow-500"
              ] 
        ] 
        [ HH.text status ]
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

activityItem :: forall w i. String -> String -> String -> HH.HTML w i
activityItem action detail time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded font-medium bg-purple-400/20 text-purple-400" ] ]
            [ HH.text action ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text detail ]
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]

-- ============================================================
-- RESOURCES TAB
-- ============================================================

resourcesTab :: forall m. MonadAff m => H.ComponentHTML Action () m
resourcesTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Managed Resources" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Add Resource" ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.table
            [ cls [ "w-full text-sm" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border bg-muted/50" ] ]
                    [ HH.th [ cls [ "py-3 px-4 text-left text-muted-foreground font-medium" ] ] [ HH.text "Resource" ]
                    , HH.th [ cls [ "py-3 px-4 text-left text-muted-foreground font-medium" ] ] [ HH.text "Type" ]
                    , HH.th [ cls [ "py-3 px-4 text-left text-muted-foreground font-medium" ] ] [ HH.text "Status" ]
                    , HH.th [ cls [ "py-3 px-4 text-left text-muted-foreground font-medium" ] ] [ HH.text "Last Sync" ]
                    ]
                ]
            , HH.tbody_
                [ resourceRow "web" "aws.ec2.Instance" true "2 min ago"
                , resourceRow "web_sg" "aws.ec2.SecurityGroup" false "15 min ago"
                , resourceRow "db" "aws.rds.Instance" true "2 min ago"
                , resourceRow "assets" "aws.s3.Bucket" true "2 min ago"
                , resourceRow "main" "aws.vpc.Vpc" true "2 min ago"
                ]
            ]
        ]
    ]

resourceRow :: forall w i. String -> String -> Boolean -> String -> HH.HTML w i
resourceRow name resType synced lastSync =
  HH.tr
    [ cls [ "border-b border-border last:border-0 hover:bg-muted/30" ] ]
    [ HH.td [ cls [ "py-3 px-4 font-mono text-text" ] ] [ HH.text name ]
    , HH.td [ cls [ "py-3 px-4 text-muted-foreground" ] ] [ HH.text resType ]
    , HH.td [ cls [ "py-3 px-4" ] ] 
        [ HH.span 
            [ cls [ "text-xs px-2 py-1 rounded"
                  , if synced then "bg-purple-400/20 text-purple-400" else "bg-yellow-500/20 text-yellow-500"
                  ] 
            ]
            [ HH.text $ if synced then "in sync" else "drifted" ]
        ]
    , HH.td [ cls [ "py-3 px-4 text-muted-foreground" ] ] [ HH.text lastSync ]
    ]

-- ============================================================
-- DRIFT TAB
-- ============================================================

driftTab :: forall m. MonadAff m => H.ComponentHTML Action () m
driftTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Drift Detection" ]
        , HH.div
            [ cls [ "flex gap-2" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Scan Now" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Remediate All" ]
            ]
        ]
    
    -- Stats
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-6" ] ]
        [ statCard "In Sync" "46" "resources"
        , statCard "Drifted" "1" "needs attention"
        , statCard "Watch Mode" "Active" "checking every 30s"
        ]
    
    -- Drifted resource detail
    , HH.div
        [ cls [ "bg-card border border-yellow-500/30 rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-3" ] ]
                [ HH.span [ cls [ "text-yellow-500" ] ] [ HH.text "!" ]
                , HH.span [ cls [ "text-text font-mono" ] ] [ HH.text "aws.ec2.SecurityGroup.web_sg" ]
                ]
            , HH.button
                [ cls [ "px-3 py-1 bg-purple-400 text-background text-sm font-medium rounded hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Remediate" ]
            ]
        , HH.div
            [ cls [ "bg-background rounded p-4 font-mono text-sm" ] ]
            [ HH.div
                [ cls [ "text-danger" ] ]
                [ HH.text "- ingress[0].cidr = \"10.0.0.0/8\"" ]
            , HH.div
                [ cls [ "text-purple-400" ] ]
                [ HH.text "+ ingress[0].cidr = \"0.0.0.0/0\"" ]
            ]
        , HH.p
            [ cls [ "text-xs text-muted-foreground mt-4" ] ]
            [ HH.text "Drifted 15 minutes ago. Someone likely modified this in the AWS console." ]
        ]
    ]

-- ============================================================
-- HISTORY TAB
-- ============================================================

historyTab :: forall m. MonadAff m => H.ComponentHTML Action () m
historyTab =
  HH.div_
    [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-6" ] ] [ HH.text "Convergence History" ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ historyEntry "Converge #47" "Success" "2 minutes ago" "47 resources, 0 changes"
        , historyEntry "Drift Remediation" "Success" "15 minutes ago" "1 resource fixed"
        , historyEntry "Converge #46" "Success" "2 hours ago" "47 resources, 1 added"
        , historyEntry "Converge #45" "Success" "1 day ago" "46 resources, 2 changed"
        , historyEntry "Converge #44" "Failed" "1 day ago" "AWS API error"
        ]
    ]

historyEntry :: forall w i. String -> String -> String -> String -> HH.HTML w i
historyEntry name status time detail =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span 
                [ cls [ "text-xs px-2 py-0.5 rounded"
                      , if status == "Success" then "bg-purple-400/20 text-purple-400" else "bg-danger/20 text-danger"
                      ] 
                ]
                [ HH.text status ]
            ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
        ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text detail ]
    ]

-- ============================================================
-- SETTINGS TAB
-- ============================================================

settingsTab :: forall m. MonadAff m => H.ComponentHTML Action () m
settingsTab =
  HH.div_
    [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-6" ] ] [ HH.text "Project Settings" ]
    
    -- Drift settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-6" ] ]
        [ HH.h3 [ cls [ "text-text font-medium mb-4" ] ] [ HH.text "Drift Detection" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ settingRow "Watch Interval" "30 seconds"
            , settingRow "Default Policy" "Auto-remediate"
            , settingRow "Notifications" "Slack #infra-alerts"
            ]
        ]
    
    -- API Keys
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-text font-medium" ] ] [ HH.text "API Keys" ]
            , HH.button
                [ cls [ "px-3 py-1 text-sm text-purple-400 hover:text-purple-400/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ New Key" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ apiKeyRow "CI Pipeline" "cvg_live_abc***" "Created 2 weeks ago"
            , apiKeyRow "Local Dev" "cvg_live_xyz***" "Created 1 month ago"
            ]
        ]
    ]

settingRow :: forall w i. String -> String -> HH.HTML w i
settingRow label value =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text label ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text value ]
    ]

apiKeyRow :: forall w i. String -> String -> String -> HH.HTML w i
apiKeyRow name key created =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text key ]
        ]
    , HH.div
        [ cls [ "text-right" ] ]
        [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text created ]
        , HH.button
            [ cls [ "text-xs text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    ]
