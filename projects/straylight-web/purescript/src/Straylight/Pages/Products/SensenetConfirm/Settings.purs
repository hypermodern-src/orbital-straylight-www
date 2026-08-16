-- | sensenet//confirm Settings Page
-- | Account settings, billing, team management
module Straylight.Pages.Products.SensenetConfirm.Settings where

import Prelude

import Effect.Aff.Class (class MonadAff)
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

type Slots :: Row Type
type Slots = ()

data Action
  = SetTab String

-- ============================================================
-- COMPONENT
-- ============================================================

settingsPage :: forall q i o m. MonadAff m => H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const initialState
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      }
  }

initialState :: State
initialState =
  { activeTab: "account"
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
    [ headerSection
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state
        , content state
        ]
    ]

headerSection :: forall m. MonadAff m => H.ComponentHTML Action Slots m
headerSection =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text" ] ]
        [ HH.text "Settings" ]
    ]

sidebar :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
sidebar state =
  HH.div
    [ cls [ "space-y-1" ] ]
    [ sidebarButton state "account" "Account"
    , sidebarButton state "pipelines" "Pipeline Config"
    , sidebarButton state "proofs" "Proof Requirements"
    , sidebarButton state "integrations" "Integrations"
    , sidebarButton state "billing" "Billing"
    , sidebarButton state "team" "Team"
    , sidebarButton state "notifications" "Notifications"
    ]

sidebarButton :: forall m. MonadAff m => State -> String -> String -> H.ComponentHTML Action Slots m
sidebarButton state value label =
  HH.button
    [ cls [ "w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value
              then "bg-amber-400/10 text-amber-400 font-medium"
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

content :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
content state = case state.activeTab of
  "account" -> accountTab
  "pipelines" -> pipelinesTab
  "proofs" -> proofsTab
  "integrations" -> integrationsTab
  "billing" -> billingTab
  "team" -> teamTab
  "notifications" -> notificationsTab
  _ -> accountTab

-- ============================================================
-- ACCOUNT TAB
-- ============================================================

accountTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
accountTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Profile section
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Profile" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Name" 
                ( HH.input
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ]
                    , HP.placeholder "Your name"
                    ]
                )
            , formField "Email"
                ( HH.input
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ]
                    , HP.placeholder "you@example.com"
                    , HP.type_ HP.InputEmail
                    ]
                )
            ]
        , HH.div
            [ cls [ "mt-6" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Changes" ]
            ]
        ]
    
      -- Danger zone
    , HH.div
        [ cls [ "bg-card border border-red-500/30 rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-red-400 mb-4" ] ] [ HH.text "Danger Zone" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Once you delete your account, there is no going back. Please be certain." ]
        , HH.button
            [ cls [ "px-4 py-2 border border-red-500 text-red-400 text-sm font-medium rounded-md hover:bg-red-500/10 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Delete Account" ]
        ]
    ]

formField :: forall w i. String -> HH.HTML w i -> HH.HTML w i
formField label input =
  HH.div_
    [ HH.label [ cls [ "block text-sm font-medium text-muted-foreground mb-1" ] ] [ HH.text label ]
    , input
    ]

-- ============================================================
-- PIPELINES TAB
-- ============================================================

pipelinesTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
pipelinesTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Default pipeline settings
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Pipeline Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Pipeline file"
                ( HH.input
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm font-mono" ]
                    , HP.value "pipeline.dhall"
                    ]
                )
            , formField "Parallelism"
                ( HH.select
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ] ]
                    [ HH.option_ [ HH.text "4 cores" ]
                    , HH.option_ [ HH.text "8 cores" ]
                    , HH.option_ [ HH.text "16 cores" ]
                    , HH.option_ [ HH.text "32 cores" ]
                    ]
                )
            , formField "Timeout"
                ( HH.input
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ]
                    , HP.value "30m"
                    ]
                )
            ]
        , HH.div
            [ cls [ "mt-6" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Settings" ]
            ]
        ]
    
      -- Agent code settings
    , HH.div
        [ cls [ "bg-card border border-amber-400/30 rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text "Agent Code Detection" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Configure how AI-generated code is detected and handled in your pipelines." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ toggleSetting "Enable agent detection" "Automatically detect AI-generated commits" true
            , toggleSetting "Require elevated review" "Agent code requires additional approvals" true
            , toggleSetting "Block untrusted agents" "Reject commits from unknown AI sources" false
            ]
        ]
    
      -- Caching
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Caching" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ toggleSetting "Enable build caching" "Cache build outputs for faster rebuilds" true
            , toggleSetting "Content-addressed caching" "Use Nix-style content addressing" true
            , formField "Cache TTL"
                ( HH.input
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ]
                    , HP.value "7d"
                    ]
                )
            ]
        ]
    ]

toggleSetting :: forall w i. String -> String -> Boolean -> HH.HTML w i
toggleSetting title description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full transition-colors cursor-pointer"
              , if enabled then "bg-amber-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-background rounded-full mt-1 transition-transform"
                  , if enabled then "ml-5" else "ml-1"
                  ]
            ]
            []
        ]
    ]

-- ============================================================
-- PROOFS TAB
-- ============================================================

proofsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
proofsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Global proof requirements
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Global Proof Requirements" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "These proofs are required for all pipelines in your organization." ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ proofRequirement "testsPass" "All tests must pass" true
            , proofRequirement "noSecrets" "No secrets in code" true
            , proofRequirement "coverageMin(80)" "Minimum 80% test coverage" false
            , proofRequirement "noWarnings" "No compiler warnings" false
            ]
        , HH.button
            [ cls [ "mt-4 text-sm text-amber-400 hover:text-amber-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Add proof requirement" ]
        ]
    
      -- Agent code proofs
    , HH.div
        [ cls [ "bg-card border border-amber-400/30 rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text "Agent Code Proof Burden" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Additional requirements for AI-generated code." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Human approvals required"
                ( HH.select
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ] ]
                    [ HH.option_ [ HH.text "2 approvals" ]
                    , HH.option_ [ HH.text "3 approvals" ]
                    , HH.option_ [ HH.text "4 approvals" ]
                    ]
                )
            , toggleSetting "Require security review" "Agent commits need security team approval" true
            , toggleSetting "Require proof of correctness" "Agent code must include formal proofs" false
            ]
        ]
    
      -- Strict mode
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Proof Verification Mode" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ HH.label
                [ cls [ "flex items-start gap-3 p-3 rounded-lg border border-border hover:border-amber-400/30 cursor-pointer" ] ]
                [ HH.input [ HP.type_ HP.InputRadio, HP.name "proof-mode", HP.checked true, cls [ "mt-1" ] ]
                , HH.div_
                    [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text "Strict" ]
                    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "All proofs must pass. Failures block merge." ]
                    ]
                ]
            , HH.label
                [ cls [ "flex items-start gap-3 p-3 rounded-lg border border-border hover:border-amber-400/30 cursor-pointer" ] ]
                [ HH.input [ HP.type_ HP.InputRadio, HP.name "proof-mode", cls [ "mt-1" ] ]
                , HH.div_
                    [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text "Advisory" ]
                    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Proof failures are warnings only." ]
                    ]
                ]
            ]
        ]
    ]

proofRequirement :: forall w i. String -> String -> Boolean -> HH.HTML w i
proofRequirement name description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.code [ cls [ "text-sm font-mono text-amber-400" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full transition-colors cursor-pointer"
              , if enabled then "bg-amber-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-background rounded-full mt-1 transition-transform"
                  , if enabled then "ml-5" else "ml-1"
                  ]
            ]
            []
        ]
    ]

-- ============================================================
-- INTEGRATIONS TAB
-- ============================================================

integrationsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
integrationsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Connected integrations
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Connected Integrations" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ integrationCard "GitHub" "Connected" "github.com/my-org" true
            , integrationCard "Slack" "Connected" "#builds channel" true
            ]
        ]
    
      -- Available integrations
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Available Integrations" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ availableIntegration "GitLab" "Connect GitLab repositories"
            , availableIntegration "Jira" "Link builds to Jira tickets"
            , availableIntegration "PagerDuty" "Alert on build failures"
            , availableIntegration "Datadog" "Export build metrics"
            ]
        ]
    
      -- Webhooks
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Webhooks" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Webhook" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ webhookRow "https://api.example.com/builds" "build.completed, proof.verified"
            , webhookRow "https://hooks.slack.com/..." "build.failed"
            ]
        ]
    ]

integrationCard :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
integrationCard name status details connected =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2 mb-1" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span
                [ cls [ "text-xs px-2 py-0.5 rounded"
                      , if connected then "bg-green-500/20 text-green-400" else "bg-muted text-muted-foreground"
                      ]
                ]
                [ HH.text status ]
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text details ]
        ]
    , HH.button
        [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Disconnect" ]
    ]

availableIntegration :: forall w i. String -> String -> HH.HTML w i
availableIntegration name description =
  HH.div
    [ cls [ "flex items-center justify-between p-4 bg-background rounded-lg" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.button
        [ cls [ "px-3 py-1 text-sm border border-amber-400 text-amber-400 rounded hover:bg-amber-400/10 transition-colors cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Connect" ]
    ]

webhookRow :: forall w i. String -> String -> HH.HTML w i
webhookRow url events =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.code [ cls [ "text-sm font-mono text-text" ] ] [ HH.text url ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text events ]
        ]
    , HH.button
        [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Delete" ]
    ]

-- ============================================================
-- BILLING TAB
-- ============================================================

billingTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
billingTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Current plan
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Current Plan" ]
            , HH.a
                [ HP.href "/sensenet/confirm/pricing"
                , cls [ "text-sm text-amber-400 hover:text-amber-400/80" ]
                ]
                [ HH.text "View all plans" ]
            ]
        , HH.div
            [ cls [ "flex items-center gap-4 mb-4" ] ]
            [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Pro" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "$29/month" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ planStat "Build Minutes" "4,521 / 5,000"
            , planStat "Repos" "Unlimited"
            , planStat "Team Seats" "1"
            , planStat "Proofs" "Full"
            ]
        ]
    
      -- Usage
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Usage This Month" ]
        , usageBar "Build Minutes" 4521 5000
        ]
    
      -- Payment
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Payment Method" ]
        , HH.div
            [ cls [ "flex items-center justify-between" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-3" ] ]
                [ HH.span [ cls [ "text-text" ] ] [ HH.text "**** **** **** 4242" ]
                , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "Expires 12/27" ]
                ]
            , HH.button
                [ cls [ "text-sm text-amber-400 hover:text-amber-400/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Update" ]
            ]
        ]
    ]

planStat :: forall w i. String -> String -> HH.HTML w i
planStat label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text value ]
    ]

usageBar :: forall w i. String -> Int -> Int -> HH.HTML w i
usageBar label used total =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text label ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text $ show used <> " / " <> show total ]
        ]
    , HH.div
        [ cls [ "h-2 bg-muted rounded-full overflow-hidden" ] ]
        [ HH.div
            [ cls [ "h-full bg-amber-400 rounded-full" ]
            , HP.style $ "width: " <> show ((used * 100) / total) <> "%"
            ]
            []
        ]
    ]

-- ============================================================
-- TEAM TAB
-- ============================================================

teamTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
teamTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Members" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-amber-400 text-background text-sm font-medium rounded-md hover:bg-amber-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Invite Member" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ teamMemberRow "You" "you@example.com" "Owner"
            ]
        , HH.p
            [ cls [ "mt-4 text-sm text-muted-foreground" ] ]
            [ HH.text "Upgrade to Team plan to invite more members." ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> String -> HH.HTML w i
teamMemberRow name email role =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text email ]
        ]
    , HH.span
        [ cls [ "text-xs px-2 py-1 rounded bg-muted text-muted-foreground" ] ]
        [ HH.text role ]
    ]

-- ============================================================
-- NOTIFICATIONS TAB
-- ============================================================

notificationsTab :: forall m. MonadAff m => H.ComponentHTML Action Slots m
notificationsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Email Notifications" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ notificationToggle "Build failures" "Get notified when a build fails" true
            , notificationToggle "Proof failures" "Get notified when a proof obligation fails" true
            , notificationToggle "Weekly summary" "Receive a weekly summary of your pipeline activity" false
            ]
        ]
    ]

notificationToggle :: forall w i. String -> String -> Boolean -> HH.HTML w i
notificationToggle title description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full transition-colors cursor-pointer"
              , if enabled then "bg-amber-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-background rounded-full mt-1 transition-transform"
                  , if enabled then "ml-5" else "ml-1"
                  ]
            ]
            []
        ]
    ]
