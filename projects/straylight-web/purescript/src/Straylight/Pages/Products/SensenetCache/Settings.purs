-- | sensenet//cache Settings Page
module Straylight.Pages.Products.SensenetCache.Settings where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

settingsPage :: forall q i o m. H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const { activeTab: "account" }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ HH.div [ cls [ "mb-8" ] ]
        [ HH.h1 [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Settings" ] ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state
        , content state
        ]
    ]

-- ============================================================
-- SIDEBAR
-- ============================================================

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state =
  HH.nav [ cls [ "space-y-1" ] ]
    [ sidebarLink state "account" "Account"
    , sidebarLink state "api-keys" "API Keys"
    , sidebarLink state "team" "Team"
    , sidebarLink state "billing" "Billing"
    , sidebarLink state "security" "Security"
    , sidebarLink state "notifications" "Notifications"
    ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label =
  HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value 
              then "bg-cyan-400/10 text-cyan-400 font-medium" 
              else "text-muted-foreground hover:text-text hover:bg-card"
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
  "account" -> accountTab
  "api-keys" -> apiKeysTab
  "team" -> teamTab
  "billing" -> billingTab
  "security" -> securityTab
  "notifications" -> notificationsTab
  _ -> accountTab

-- ============================================================
-- ACCOUNT TAB
-- ============================================================

accountTab :: forall w i. HH.HTML w i
accountTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Account Information"
        [ formField "Organization name" "acme-corp" "text"
        , formField "Email" "admin@acme-corp.com" "email"
        , formField "Organization URL" "https://acme-corp.com" "url"
        ]
    , settingsCard "Cache Namespace"
        [ HH.div [ cls [ "mb-4" ] ]
            [ HH.label [ cls [ "block text-sm font-medium text-text mb-2" ] ] 
                [ HH.text "Namespace" ]
            , HH.div [ cls [ "flex items-center gap-2" ] ]
                [ HH.span [ cls [ "text-muted-foreground" ] ] 
                    [ HH.text "https://cache.sensenet.dev/" ]
                , HH.input
                    [ HP.type_ HP.InputText
                    , HP.value "acme-corp"
                    , cls [ "px-3 py-2 bg-background border border-border rounded-md text-sm text-text w-40" ]
                    ]
                ]
            , HH.p [ cls [ "text-xs text-muted-foreground mt-2" ] ] 
                [ HH.text "This is your organization's unique namespace for all caches." ]
            ]
        ]
    , settingsCard "Danger Zone"
        [ HH.div [ cls [ "flex items-center justify-between" ] ]
            [ HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text "Delete organization" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                    [ HH.text "Permanently delete all caches, artifacts, and data." ]
                ]
            , HH.button
                [ cls [ "px-4 py-2 bg-red-500/10 text-red-400 border border-red-500/20 rounded-md text-sm hover:bg-red-500/20 transition-colors" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Delete organization" ]
            ]
        ]
    ]

-- ============================================================
-- API KEYS TAB
-- ============================================================

apiKeysTab :: forall w i. HH.HTML w i
apiKeysTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ HH.div [ cls [ "flex items-center justify-between" ] ]
        [ HH.div_
            [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "API Keys" ]
            , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                [ HH.text "Manage API keys for programmatic access to sensenet//cache." ]
            ]
        , HH.button
            [ cls [ "px-4 py-2 bg-cyan-400 text-background rounded-md text-sm hover:bg-cyan-400/90 transition-colors" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Create API Key" ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.table [ cls [ "w-full" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border" ] ]
                    [ HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Name" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Key" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Permissions" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Last used" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "" ]
                    ]
                ]
            , HH.tbody_
                [ apiKeyRow "CI Production" "snc_prod_****7f8a" "read, write" "2 hours ago"
                , apiKeyRow "CI Staging" "snc_stg_****3b2c" "read, write" "1 day ago"
                , apiKeyRow "Read-only" "snc_ro_****9d4e" "read" "3 days ago"
                ]
            ]
        ]
    , HH.div [ cls [ "p-4 bg-cyan-400/5 border border-cyan-400/20 rounded-lg" ] ]
        [ HH.p [ cls [ "text-sm text-cyan-400 font-medium mb-1" ] ] 
            [ HH.text "Security tip" ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text "Use separate API keys for different environments. Rotate keys regularly and never commit them to version control." ]
        ]
    ]

apiKeyRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
apiKeyRow name key permissions lastUsed =
  HH.tr [ cls [ "border-b border-border last:border-0 hover:bg-card/50" ] ]
    [ HH.td [ cls [ "py-3 px-4 text-sm text-text font-medium" ] ] [ HH.text name ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground font-mono" ] ] [ HH.text key ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text permissions ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text lastUsed ]
    , HH.td [ cls [ "py-3 px-4" ] ]
        [ HH.button
            [ cls [ "text-red-400 hover:text-red-300 text-sm" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    ]

-- ============================================================
-- TEAM TAB
-- ============================================================

teamTab :: forall w i. HH.HTML w i
teamTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ HH.div [ cls [ "flex items-center justify-between" ] ]
        [ HH.div_
            [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Members" ]
            , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                [ HH.text "3 of 5 seats used on your Pro plan." ]
            ]
        , HH.button
            [ cls [ "px-4 py-2 bg-cyan-400 text-background rounded-md text-sm hover:bg-cyan-400/90 transition-colors" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Invite member" ]
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
        [ HH.table [ cls [ "w-full" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border" ] ]
                    [ HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Member" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Role" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "Joined" ]
                    , HH.th [ cls [ "text-left py-3 px-4 text-xs font-medium text-muted-foreground uppercase" ] ] [ HH.text "" ]
                    ]
                ]
            , HH.tbody_
                [ teamMemberRow "alice@acme-corp.com" "Owner" "Jan 2025" false
                , teamMemberRow "bob@acme-corp.com" "Admin" "Jan 2025" true
                , teamMemberRow "charlie@acme-corp.com" "Member" "Feb 2026" true
                ]
            ]
        ]
    , settingsCard "Roles"
        [ HH.div [ cls [ "space-y-3" ] ]
            [ roleDescription "Owner" "Full access. Can delete organization and manage billing."
            , roleDescription "Admin" "Can manage caches, API keys, and team members."
            , roleDescription "Member" "Can push and pull artifacts. Cannot manage settings."
            ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
teamMemberRow email role joined canRemove =
  HH.tr [ cls [ "border-b border-border last:border-0 hover:bg-card/50" ] ]
    [ HH.td [ cls [ "py-3 px-4 text-sm text-text" ] ] [ HH.text email ]
    , HH.td [ cls [ "py-3 px-4" ] ] 
        [ HH.span 
            [ cls [ "px-2 py-0.5 text-xs rounded-full"
                  , case role of
                      "Owner" -> "bg-cyan-400/10 text-cyan-400"
                      "Admin" -> "bg-green-400/10 text-green-400"
                      _ -> "bg-muted-foreground/10 text-muted-foreground"
                  ] 
            ] 
            [ HH.text role ]
        ]
    , HH.td [ cls [ "py-3 px-4 text-sm text-muted-foreground" ] ] [ HH.text joined ]
    , HH.td [ cls [ "py-3 px-4" ] ]
        [ if canRemove
            then HH.button
                [ cls [ "text-red-400 hover:text-red-300 text-sm" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Remove" ]
            else HH.text ""
        ]
    ]

roleDescription :: forall w i. String -> String -> HH.HTML w i
roleDescription role description =
  HH.div [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-cyan-400 font-medium text-sm w-20" ] ] [ HH.text role ]
    , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- BILLING TAB
-- ============================================================

billingTab :: forall w i. HH.HTML w i
billingTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Current Plan"
        [ HH.div [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.div_
                [ HH.div [ cls [ "flex items-center gap-2 mb-1" ] ]
                    [ HH.h3 [ cls [ "text-xl font-bold text-text" ] ] [ HH.text "Pro" ]
                    , HH.span [ cls [ "px-2 py-0.5 text-xs rounded-full bg-cyan-400/10 text-cyan-400" ] ] 
                        [ HH.text "Active" ]
                    ]
                , HH.p [ cls [ "text-muted-foreground" ] ] 
                    [ HH.text "$29/month - 100GB storage, 500GB transfer, 5 seats" ]
                ]
            , HH.button
                [ cls [ "px-4 py-2 border border-border text-text rounded-md text-sm hover:bg-card transition-colors" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Change plan" ]
            ]
        , HH.div [ cls [ "grid grid-cols-3 gap-4 pt-4 border-t border-border" ] ]
            [ usageMetric "Storage" "12.4 GB" "100 GB"
            , usageMetric "Transfer" "45.2 GB" "500 GB"
            , usageMetric "Seats" "3" "5"
            ]
        ]
    , settingsCard "Payment Method"
        [ HH.div [ cls [ "flex items-center justify-between" ] ]
            [ HH.div [ cls [ "flex items-center gap-3" ] ]
                [ HH.div [ cls [ "w-12 h-8 bg-card border border-border rounded flex items-center justify-center" ] ]
                    [ HH.span [ cls [ "text-xs font-bold text-text" ] ] [ HH.text "VISA" ] ]
                , HH.div_
                    [ HH.p [ cls [ "text-text text-sm" ] ] [ HH.text "**** **** **** 4242" ]
                    , HH.p [ cls [ "text-muted-foreground text-xs" ] ] [ HH.text "Expires 12/2028" ]
                    ]
                ]
            , HH.button
                [ cls [ "text-cyan-400 hover:text-cyan-300 text-sm" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Update" ]
            ]
        ]
    , settingsCard "Billing History"
        [ HH.div [ cls [ "space-y-3" ] ]
            [ invoiceRow "February 2026" "$29.00" "Paid"
            , invoiceRow "January 2026" "$29.00" "Paid"
            , invoiceRow "December 2025" "$29.00" "Paid"
            ]
        ]
    ]

usageMetric :: forall w i. String -> String -> String -> HH.HTML w i
usageMetric label used total =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-text font-medium" ] ] 
        [ HH.text used
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text (" / " <> total) ]
        ]
    ]

invoiceRow :: forall w i. String -> String -> String -> HH.HTML w i
invoiceRow date amount status =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text date ]
    , HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text amount ]
        , HH.span [ cls [ "px-2 py-0.5 text-xs rounded-full bg-green-400/10 text-green-400" ] ] 
            [ HH.text status ]
        , HH.button
            [ cls [ "text-cyan-400 hover:text-cyan-300 text-sm" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Download" ]
        ]
    ]

-- ============================================================
-- SECURITY TAB
-- ============================================================

securityTab :: forall w i. HH.HTML w i
securityTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Signing Keys"
        [ HH.div [ cls [ "mb-4" ] ]
            [ HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
                [ HH.text "Your organization's SPHINCS+ public key for artifact verification." ]
            , HH.div [ cls [ "p-3 bg-background border border-border rounded-md font-mono text-xs text-text overflow-x-auto" ] ]
                [ HH.text "acme-corp.cache.sensenet.dev:sph256s1q2w3e4r5t6y7u8i9o0p..." ]
            ]
        , HH.div [ cls [ "flex gap-3" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 border border-border text-text rounded-md text-sm hover:bg-card transition-colors" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Copy public key" ]
            , HH.button
                [ cls [ "px-4 py-2 border border-border text-text rounded-md text-sm hover:bg-card transition-colors" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Rotate keys" ]
            ]
        ]
    , settingsCard "Two-Factor Authentication"
        [ HH.div [ cls [ "flex items-center justify-between" ] ]
            [ HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text "2FA enabled" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                    [ HH.text "Require two-factor authentication for all team members." ]
                ]
            , HH.div [ cls [ "flex items-center" ] ]
                [ HH.span [ cls [ "text-green-400 text-sm mr-2" ] ] [ HH.text "Enabled" ]
                , HH.div [ cls [ "w-10 h-6 bg-green-400 rounded-full relative cursor-pointer" ] ]
                    [ HH.div [ cls [ "w-4 h-4 bg-white rounded-full absolute right-1 top-1" ] ] [] ]
                ]
            ]
        ]
    , settingsCard "Audit Logs"
        [ HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "90-day retention of all API access and configuration changes." ]
        , HH.div [ cls [ "space-y-2" ] ]
            [ auditLogRow "API key created: CI Production" "alice@acme-corp.com" "2 hours ago"
            , auditLogRow "Artifact pushed: blake3://7f83b165..." "CI Production" "2 hours ago"
            , auditLogRow "Team member invited: charlie@acme-corp.com" "alice@acme-corp.com" "3 days ago"
            ]
        , HH.a
            [ HP.href "#"
            , cls [ "block text-center text-sm text-cyan-400 hover:text-cyan-300 mt-4" ]
            ]
            [ HH.text "View full audit log ->" ]
        ]
    , settingsCard "SSO Configuration"
        [ HH.div [ cls [ "flex items-center justify-between" ] ]
            [ HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text "SAML SSO" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                    [ HH.text "Configure SAML-based single sign-on for your organization." ]
                ]
            , HH.span [ cls [ "px-2 py-0.5 text-xs rounded-full bg-muted-foreground/10 text-muted-foreground" ] ] 
                [ HH.text "Enterprise" ]
            ]
        ]
    ]

auditLogRow :: forall w i. String -> String -> String -> HH.HTML w i
auditLogRow action actor time =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text action ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text actor ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- NOTIFICATIONS TAB
-- ============================================================

notificationsTab :: forall w i. HH.HTML w i
notificationsTab =
  HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Email Notifications"
        [ HH.div [ cls [ "space-y-4" ] ]
            [ notificationToggle "Usage alerts" "Get notified when you reach 80% and 95% of your limits." true
            , notificationToggle "Security alerts" "Failed attestation verifications and suspicious activity." true
            , notificationToggle "Weekly digest" "Summary of cache usage, top artifacts, and team activity." false
            , notificationToggle "Product updates" "New features, improvements, and maintenance notices." true
            ]
        ]
    , settingsCard "Webhook Notifications"
        [ HH.div [ cls [ "mb-4" ] ]
            [ HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
                [ HH.text "Send real-time notifications to your own endpoints." ]
            , HH.div [ cls [ "flex gap-2" ] ]
                [ HH.input
                    [ HP.type_ HP.InputUrl
                    , HP.placeholder "https://api.example.com/webhooks/sensenet"
                    , cls [ "flex-1 px-3 py-2 bg-background border border-border rounded-md text-sm text-text placeholder:text-muted-foreground" ]
                    ]
                , HH.button
                    [ cls [ "px-4 py-2 bg-cyan-400 text-background rounded-md text-sm hover:bg-cyan-400/90 transition-colors" ]
                    , HP.type_ HP.ButtonButton
                    ]
                    [ HH.text "Add webhook" ]
                ]
            ]
        ]
    ]

notificationToggle :: forall w i. String -> String -> Boolean -> HH.HTML w i
notificationToggle label description enabled =
  HH.div [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium text-sm" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div 
        [ cls [ "w-10 h-6 rounded-full relative cursor-pointer"
              , if enabled then "bg-cyan-400" else "bg-border"
              ] 
        ]
        [ HH.div 
            [ cls [ "w-4 h-4 bg-white rounded-full absolute top-1"
                  , if enabled then "right-1" else "left-1"
                  ] 
            ] 
            []
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

settingsCard :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
settingsCard title children =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    ( [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text title ] ]
      <> children
    )

formField :: forall w i. String -> String -> String -> HH.HTML w i
formField label value inputType =
  HH.div [ cls [ "mb-4" ] ]
    [ HH.label [ cls [ "block text-sm font-medium text-text mb-2" ] ] 
        [ HH.text label ]
    , HH.input
        [ HP.type_ (case inputType of
            "email" -> HP.InputEmail
            "url" -> HP.InputUrl
            _ -> HP.InputText)
        , HP.value value
        , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-sm text-text" ]
        ]
    ]
