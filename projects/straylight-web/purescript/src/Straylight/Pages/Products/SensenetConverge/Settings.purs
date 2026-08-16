-- | sensenet//converge Settings Page
-- | Cloud credentials, environments, team access
module Straylight.Pages.Products.SensenetConverge.Settings where

import Prelude

import Data.String as String
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

settingsPage :: forall q i o m. H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const { activeTab: "credentials" }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ header
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state
        , content state
        ]
    ]

header :: forall m. H.ComponentHTML Action () m
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "Settings" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Configure cloud credentials, environments, and team access." ]
    ]

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state =
  HH.nav
    [ cls [ "space-y-1" ] ]
    [ sidebarLink state "credentials" "Cloud Credentials"
    , sidebarLink state "environments" "Environments"
    , sidebarLink state "team" "Team Access"
    , sidebarLink state "api" "API Keys"
    , sidebarLink state "notifications" "Notifications"
    ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label =
  HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value
              then "bg-purple-400/10 text-purple-400 font-medium"
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "credentials" -> credentialsContent
  "environments" -> environmentsContent
  "team" -> teamContent
  "api" -> apiContent
  "notifications" -> notificationsContent
  _ -> credentialsContent

-- ============================================================
-- CLOUD CREDENTIALS
-- ============================================================

credentialsContent :: forall m. H.ComponentHTML Action () m
credentialsContent =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text" ] ]
                [ HH.text "Cloud Credentials" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Provider" ]
            ]
        , HH.p
            [ cls [ "text-muted-foreground mb-6" ] ]
            [ HH.text "Credentials are stored encrypted and never leave your environment. Converge uses these to query live infrastructure state." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ credentialCard "AWS" "Production Account" "arn:aws:iam::123456789:role/converge" true
            , credentialCard "AWS" "Staging Account" "arn:aws:iam::987654321:role/converge" true
            , credentialCard "GCP" "Main Project" "converge-sa@my-project.iam.gserviceaccount.com" true
            , credentialCard "Kubernetes" "Production Cluster" "eks-prod-cluster" false
            ]
        ]
    , HH.div
        [ cls [ "bg-purple-400/10 border border-purple-400/20 rounded-lg p-4" ] ]
        [ HH.p
            [ cls [ "text-sm text-purple-400" ] ]
            [ HH.text "No state files. Credentials are used for live queries only - never stored in state." ]
        ]
    ]

credentialCard :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
credentialCard provider name identifier verified =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.div
            [ cls [ "w-10 h-10 rounded bg-purple-400/20 flex items-center justify-center" ] ]
            [ HH.span
                [ cls [ "text-purple-400 font-mono text-sm font-bold" ] ]
                [ HH.text $ case provider of
                    "AWS" -> "aws"
                    "GCP" -> "gcp"
                    "Kubernetes" -> "k8s"
                    _ -> "?"
                ]
            ]
        , HH.div_
            [ HH.p
                [ cls [ "text-text font-medium" ] ]
                [ HH.text name ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground font-mono" ] ]
                [ HH.text identifier ]
            ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-1 rounded"
                  , if verified then "bg-purple-400/20 text-purple-400" else "bg-yellow-500/20 text-yellow-500"
                  ]
            ]
            [ HH.text $ if verified then "verified" else "pending" ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

-- ============================================================
-- ENVIRONMENTS
-- ============================================================

environmentsContent :: forall m. H.ComponentHTML Action () m
environmentsContent =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text" ] ]
                [ HH.text "Environments" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ New Environment" ]
            ]
        , HH.p
            [ cls [ "text-muted-foreground mb-6" ] ]
            [ HH.text "Environments isolate infrastructure configs and convergence settings. Each environment can have its own credentials and drift policies." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ environmentCard "production" "47 resources" "Converging" "auto-remediate"
            , environmentCard "staging" "32 resources" "Watching" "alert"
            , environmentCard "development" "15 resources" "Idle" "ignore"
            ]
        ]
    ]

environmentCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
environmentCard name resources status driftPolicy =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.div
            [ cls [ "w-3 h-3 rounded-full"
                  , case name of
                      "production" -> "bg-purple-400"
                      "staging" -> "bg-yellow-500"
                      _ -> "bg-muted-foreground"
                  ]
            ]
            []
        , HH.div_
            [ HH.p
                [ cls [ "text-text font-medium" ] ]
                [ HH.text name ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground" ] ]
                [ HH.text resources ]
            ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-6" ] ]
        [ HH.div
            [ cls [ "text-right" ] ]
            [ HH.p
                [ cls [ "text-sm text-text" ] ]
                [ HH.text status ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground" ] ]
                [ HH.text $ "Drift: " <> driftPolicy ]
            ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Configure" ]
        ]
    ]

-- ============================================================
-- TEAM ACCESS
-- ============================================================

teamContent :: forall m. H.ComponentHTML Action () m
teamContent =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text" ] ]
                [ HH.text "Team Members" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Invite Member" ]
            ]
        , HH.p
            [ cls [ "text-muted-foreground mb-6" ] ]
            [ HH.text "Manage who can view, edit, and deploy infrastructure. Supports SSO via SAML/OIDC on Team and Enterprise plans." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ teamMemberCard "you@company.com" "Owner" "All environments"
            , teamMemberCard "alice@company.com" "Admin" "All environments"
            , teamMemberCard "bob@company.com" "Developer" "staging, development"
            , teamMemberCard "carol@company.com" "Viewer" "production (read-only)"
            ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Roles" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ roleRow "Owner" "Full access, billing, team management"
            , roleRow "Admin" "All environments, cannot manage billing"
            , roleRow "Developer" "Converge and edit assigned environments"
            , roleRow "Viewer" "Read-only access to assigned environments"
            ]
        ]
    ]

teamMemberCard :: forall w i. String -> String -> String -> HH.HTML w i
teamMemberCard email role environments =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.div
            [ cls [ "w-10 h-10 rounded-full bg-purple-400/20 flex items-center justify-center" ] ]
            [ HH.span
                [ cls [ "text-purple-400 font-medium" ] ]
                [ HH.text $ String.toUpper $ String.take 1 email ]
            ]
        , HH.div_
            [ HH.p
                [ cls [ "text-text font-medium" ] ]
                [ HH.text email ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground" ] ]
                [ HH.text environments ]
            ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-1 rounded bg-purple-400/20 text-purple-400" ] ]
            [ HH.text role ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

roleRow :: forall w i. String -> String -> HH.HTML w i
roleRow role description =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.span
        [ cls [ "text-text font-medium" ] ]
        [ HH.text role ]
    , HH.span
        [ cls [ "text-sm text-muted-foreground" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- API KEYS
-- ============================================================

apiContent :: forall m. H.ComponentHTML Action () m
apiContent =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-6" ] ]
            [ HH.h3
                [ cls [ "text-lg font-semibold text-text" ] ]
                [ HH.text "API Keys" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-purple-400 text-background text-sm font-medium rounded-md hover:bg-purple-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ New Key" ]
            ]
        , HH.p
            [ cls [ "text-muted-foreground mb-6" ] ]
            [ HH.text "API keys for CI/CD pipelines and programmatic access. Keys can be scoped to specific environments." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ apiKeyCard "CI Pipeline" "cvg_live_abc***def" "All environments" "2 weeks ago"
            , apiKeyCard "GitHub Actions" "cvg_live_xyz***789" "staging" "1 month ago"
            , apiKeyCard "Local Development" "cvg_test_loc***456" "development" "3 months ago"
            ]
        ]
    ]

apiKeyCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
apiKeyCard name key scope created =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div_
        [ HH.p
            [ cls [ "text-text font-medium" ] ]
            [ HH.text name ]
        , HH.p
            [ cls [ "text-xs text-muted-foreground font-mono" ] ]
            [ HH.text key ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-6" ] ]
        [ HH.div
            [ cls [ "text-right" ] ]
            [ HH.p
                [ cls [ "text-sm text-muted-foreground" ] ]
                [ HH.text scope ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground" ] ]
                [ HH.text $ "Created " <> created ]
            ]
        , HH.button
            [ cls [ "text-sm text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    ]

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

notificationsContent :: forall m. H.ComponentHTML Action () m
notificationsContent =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-6" ] ]
            [ HH.text "Notification Channels" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-6" ] ]
            [ HH.text "Get notified when drift is detected, convergence fails, or resources change." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ notificationCard "Slack" "#infra-alerts" true
            , notificationCard "PagerDuty" "Production Service" true
            , notificationCard "Email" "team@company.com" false
            ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Notification Settings" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ settingRow "Drift detected" "All channels"
            , settingRow "Convergence failed" "Slack, PagerDuty"
            , settingRow "Convergence succeeded" "Slack only"
            , settingRow "Resource added/removed" "Email only"
            ]
        ]
    ]

notificationCard :: forall w i. String -> String -> Boolean -> HH.HTML w i
notificationCard channel target enabled =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg border border-border" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.div
            [ cls [ "w-10 h-10 rounded bg-purple-400/20 flex items-center justify-center" ] ]
            [ HH.span
                [ cls [ "text-purple-400 text-sm" ] ]
                [ HH.text $ case channel of
                    "Slack" -> "#"
                    "PagerDuty" -> "!"
                    _ -> "@"
                ]
            ]
        , HH.div_
            [ HH.p
                [ cls [ "text-text font-medium" ] ]
                [ HH.text channel ]
            , HH.p
                [ cls [ "text-xs text-muted-foreground" ] ]
                [ HH.text target ]
            ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-1 rounded"
                  , if enabled then "bg-purple-400/20 text-purple-400" else "bg-muted text-muted-foreground"
                  ]
            ]
            [ HH.text $ if enabled then "enabled" else "disabled" ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Configure" ]
        ]
    ]

settingRow :: forall w i. String -> String -> HH.HTML w i
settingRow event channels =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.span
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text event ]
    , HH.span
        [ cls [ "text-sm text-text" ] ]
        [ HH.text channels ]
    ]
