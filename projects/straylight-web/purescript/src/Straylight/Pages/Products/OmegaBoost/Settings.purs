-- | omega//boost Settings Page
-- | Model configs, scaling rules, BYOK credentials
module Straylight.Pages.Products.OmegaBoost.Settings where

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

settingsPage :: forall q i o m. H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const initialState
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      }
  }

initialState :: State
initialState =
  { activeTab: "models"
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
    [ headerSection
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state
        , content state
        ]
    ]

headerSection :: forall w i. HH.HTML w i
headerSection =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text" ] ]
        [ HH.text "Settings" ]
    ]

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state =
  HH.nav
    [ cls [ "space-y-1" ] ]
    [ sidebarLink "models" "Model Configs" state.activeTab
    , sidebarLink "scaling" "Scaling Rules" state.activeTab
    , sidebarLink "byok" "BYOK Credentials" state.activeTab
    , sidebarLink "billing" "Billing" state.activeTab
    , sidebarLink "team" "Team" state.activeTab
    , sidebarLink "security" "Security" state.activeTab
    ]

sidebarLink :: forall m. String -> String -> String -> H.ComponentHTML Action () m
sidebarLink value label activeTab =
  HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors"
          , if value == activeTab 
              then "bg-yellow-400/10 text-yellow-400 font-medium" 
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetActiveTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "models" -> modelsTab
  "scaling" -> scalingTab
  "byok" -> byokTab
  "billing" -> billingTab
  "team" -> teamTab
  "security" -> securityTab
  _ -> modelsTab

-- ============================================================
-- MODELS TAB
-- ============================================================

modelsTab :: forall w i. HH.HTML w i
modelsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Model configs
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Model Configurations" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ modelConfigRow "gpt-4-turbo" "OpenAI" "auto" true
            , modelConfigRow "claude-3-opus" "Anthropic" "eager" true
            , modelConfigRow "llama-70b" "Together AI" "throughput" false
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Model" ]
            ]
        ]
    
      -- Default settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Kernel Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Batch Mode" "auto" false
            , formField "Batch Window (ms)" "10" false
            , formField "Priority" "normal" false
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Defaults" ]
            ]
        ]
    ]

modelConfigRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
modelConfigRow model provider batchMode enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-text font-mono text-sm" ] ] [ HH.text model ]
        , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground" ] ] 
            [ HH.text provider ]
        , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-400/20 text-yellow-400" ] ] 
            [ HH.text batchMode ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs"
                  , if enabled then "text-green-400" else "text-muted-foreground"
                  ]
            ]
            [ HH.text $ if enabled then "enabled" else "disabled" ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

formField :: forall w i. String -> String -> Boolean -> HH.HTML w i
formField label value disabled =
  HH.div_
    [ HH.label
        [ cls [ "block text-sm font-medium text-text mb-2" ] ]
        [ HH.text label ]
    , HH.input
        [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400 disabled:opacity-50" ]
        , HP.value value
        , HP.disabled disabled
        ]
    ]

-- ============================================================
-- SCALING TAB
-- ============================================================

scalingTab :: forall w i. HH.HTML w i
scalingTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Scaling rules
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Auto-Scaling Rules" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ scalingRuleRow "Queue depth > 100" "Scale up" true
            , scalingRuleRow "GPU util < 50% for 5m" "Scale down" true
            , scalingRuleRow "p99 latency > 10ms" "Scale up" true
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Rule" ]
            ]
        ]
    
      -- Capacity limits
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Capacity Limits" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Min GPU instances" "1" false
            , formField "Max GPU instances" "8" false
            , formField "Target utilization (%)" "85" false
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Limits" ]
            ]
        ]
    
      -- Current status
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Current Status" ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ statusStat "GPU Instances" "3"
            , statusStat "Queue Depth" "42"
            , statusStat "Avg Utilization" "94%"
            , statusStat "p99 Latency" "4.2ms"
            ]
        ]
    ]

scalingRuleRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
scalingRuleRow condition action enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-text text-sm" ] ] [ HH.text condition ]
        , HH.span [ cls [ "text-yellow-400 text-sm" ] ] [ HH.text "->" ]
        , HH.span [ cls [ "text-text text-sm font-medium" ] ] [ HH.text action ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full cursor-pointer transition-colors"
              , if enabled then "bg-yellow-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-background rounded-full mt-1 transition-transform"
                  , if enabled then "translate-x-5 ml-1" else "translate-x-1"
                  ]
            ]
            []
        ]
    ]

statusStat :: forall w i. String -> String -> HH.HTML w i
statusStat label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-lg text-text font-bold" ] ] [ HH.text value ]
    ]

-- ============================================================
-- BYOK TAB
-- ============================================================

byokTab :: forall w i. HH.HTML w i
byokTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- BYOK credentials
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "BYOK Credentials" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Provider" ]
            ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ byokCredentialRow "OpenAI" "sk-***...abc" "us-east-1" "co-located"
            , byokCredentialRow "Anthropic" "sk-ant-***...xyz" "us-east-1" "co-located"
            , byokCredentialRow "Together AI" "tok-***...def" "us-west-2" "routing"
            ]
        ]
    
      -- Security
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Key Security" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "All BYOK credentials are encrypted at rest using AES-256-GCM. Keys are decrypted only during request processing in isolated secure enclaves." ]
        , HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-xs px-2 py-1 rounded bg-green-500/20 text-green-400" ] ] 
                [ HH.text "AES-256-GCM" ]
            , HH.span [ cls [ "text-xs px-2 py-1 rounded bg-green-500/20 text-green-400" ] ] 
                [ HH.text "Secure Enclave" ]
            , HH.span [ cls [ "text-xs px-2 py-1 rounded bg-green-500/20 text-green-400" ] ] 
                [ HH.text "Zero Logging" ]
            ]
        ]
    ]

byokCredentialRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
byokCredentialRow provider key region status =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text provider ]
        , HH.code [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text key ]
        , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text region ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-400/20 text-yellow-400" ] ] 
            [ HH.text status ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Rotate" ]
        , HH.button
            [ cls [ "text-sm text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Remove" ]
        ]
    ]

-- ============================================================
-- BILLING TAB
-- ============================================================

billingTab :: forall w i. HH.HTML w i
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
                [ HP.href "/omega/boost/pricing"
                , cls [ "text-sm text-yellow-400 hover:text-yellow-400/80" ]
                ]
                [ HH.text "View all plans" ]
            ]
        , HH.div
            [ cls [ "flex items-baseline gap-2 mb-4" ] ]
            [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Pro" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "$99/month" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ planStat "Tokens" "50M/month"
            , planStat "Overage" "$0.001/1k"
            , planStat "BYOK Providers" "Unlimited"
            , planStat "Kernels" "CUTLASS 3.x"
            ]
        ]
    
      -- Payment method
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Payment Method" ]
        , HH.div
            [ cls [ "flex items-center justify-between p-3 bg-background rounded-md" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-3" ] ]
                [ HH.span [ cls [ "text-text" ] ] [ HH.text "**** **** **** 4242" ]
                , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Expires 12/25" ]
                ]
            , HH.button
                [ cls [ "text-sm text-yellow-400 hover:text-yellow-400/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Update" ]
            ]
        ]
    
      -- Billing history
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Billing History" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ invoiceRow "Feb 2026" "$99.00" "Paid"
            , invoiceRow "Jan 2026" "$99.00" "Paid"
            , invoiceRow "Dec 2025" "$99.00" "Paid"
            ]
        ]
    
      -- Upgrade options
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Upgrade to Enterprise" ]
        , HH.p [ cls [ "text-muted-foreground mb-4" ] ] 
            [ HH.text "Reserved GPU capacity, dedicated kernel instances, 99.99% SLA, and on-prem CUTLASS option." ]
        , HH.a
            [ HP.href "/discord"
            , cls [ "inline-block px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors" ]
            ]
            [ HH.text "Contact Sales" ]
        ]
    ]

planStat :: forall w i. String -> String -> HH.HTML w i
planStat label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text value ]
    ]

invoiceRow :: forall w i. String -> String -> String -> HH.HTML w i
invoiceRow date amount status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text date ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text amount ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/20 text-green-400" ] ] 
            [ HH.text status ]
        , HH.a
            [ HP.href "#"
            , cls [ "text-xs text-yellow-400 hover:text-yellow-400/80" ]
            ]
            [ HH.text "Download" ]
        ]
    ]

-- ============================================================
-- TEAM TAB
-- ============================================================

teamTab :: forall w i. HH.HTML w i
teamTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Members" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Invite Member" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ teamMemberRow "user@example.com" "Owner" true
            , teamMemberRow "dev@example.com" "Admin" false
            , teamMemberRow "support@example.com" "Member" false
            ]
        ]
    
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Pending Invitations" ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "No pending invitations" ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
teamMemberRow email role isOwner =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.div
            [ cls [ "w-8 h-8 bg-yellow-400/20 rounded-full flex items-center justify-center" ] ]
            [ HH.span [ cls [ "text-yellow-400 text-sm font-medium" ] ] 
                [ HH.text $ take 1 email ]
            ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text email ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-1 rounded bg-muted text-muted-foreground" ] ]
            [ HH.text role ]
        , if not isOwner
            then HH.button
                [ cls [ "text-xs text-danger hover:text-danger/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Remove" ]
            else HH.text ""
        ]
    ]
  where
  take :: Int -> String -> String
  take _ "" = ""
  take n s = if n <= 0 then "" else s

-- ============================================================
-- NOTIFICATIONS TAB
-- ============================================================

notificationsTab :: forall w i. HH.HTML w i
notificationsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Email Notifications" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ notificationToggle "Usage alerts" "Get notified when you reach 80% of your quota" true
            , notificationToggle "Billing updates" "Receipts, payment failures, plan changes" true
            , notificationToggle "Product updates" "New features and improvements" false
            , notificationToggle "Security alerts" "Suspicious activity, new device logins" true
            ]
        ]
    
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Webhook Notifications" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Send notifications to your own endpoints." ]
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Add Webhook" ]
        ]
    ]

notificationToggle :: forall w i. String -> String -> Boolean -> HH.HTML w i
notificationToggle label description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text text-sm font-medium" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full cursor-pointer transition-colors"
              , if enabled then "bg-yellow-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-background rounded-full mt-1 transition-transform"
                  , if enabled then "translate-x-5 ml-1" else "translate-x-1"
                  ]
            ]
            []
        ]
    ]

-- ============================================================
-- SECURITY TAB
-- ============================================================

securityTab :: forall w i. HH.HTML w i
securityTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Two-Factor Authentication" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Add an extra layer of security to your account." ]
        , HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-xs px-2 py-1 rounded bg-green-500/20 text-green-400" ] ] 
                [ HH.text "Enabled" ]
            , HH.button
                [ cls [ "text-sm text-yellow-400 hover:text-yellow-400/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Configure" ]
            ]
        ]
    
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Sessions" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ sessionRow "Chrome on macOS" "San Francisco, CA" "Active now" true
            , sessionRow "Firefox on Windows" "New York, NY" "2 hours ago" false
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "text-sm text-danger hover:text-danger/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Sign out all other sessions" ]
            ]
        ]
    
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Password" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Last changed 3 months ago." ]
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Change Password" ]
        ]
    ]

sessionRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
sessionRow device location time current =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-text text-sm" ] ] [ HH.text device ]
            , if current
                then HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-400/10 text-yellow-400" ] ] 
                    [ HH.text "Current" ]
                else HH.text ""
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text location ]
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]
