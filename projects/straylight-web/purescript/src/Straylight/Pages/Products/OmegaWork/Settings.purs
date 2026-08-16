-- | omega//work Settings Page
-- | Team management, SSO, integrations for teams
module Straylight.Pages.Products.OmegaWork.Settings where

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
  { activeTab: "team"
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
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state
        , content state
        ]
    ]

header :: forall w i. HH.HTML w i
header =
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
    [ sidebarButton "team" "Team Management" state.activeTab
    , sidebarButton "workspaces" "Workspaces" state.activeTab
    , sidebarButton "sso" "SSO / Security" state.activeTab
    , sidebarButton "integrations" "Integrations" state.activeTab
    , sidebarButton "billing" "Billing" state.activeTab
    ]

sidebarButton :: forall m. String -> String -> String -> H.ComponentHTML Action () m
sidebarButton value label activeTab =
  HH.button
    [ cls [ "w-full text-left px-3 py-2 rounded text-sm transition-colors"
          , if value == activeTab 
              then "bg-indigo-400/10 text-indigo-400 font-medium" 
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetActiveTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "team" -> teamTab
  "workspaces" -> workspacesTab
  "sso" -> ssoTab
  "integrations" -> integrationsTab
  "billing" -> billingTab
  _ -> teamTab

-- ============================================================
-- TEAM MANAGEMENT TAB
-- ============================================================

teamTab :: forall w i. HH.HTML w i
teamTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Team members section
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Members" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-indigo-400 text-background text-sm font-medium rounded-md hover:bg-indigo-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Invite Member" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ teamMemberRow "Sarah Chen" "sarah@company.com" "Admin" true
            , teamMemberRow "Mike Johnson" "mike@company.com" "Member" true
            , teamMemberRow "Lisa Park" "lisa@company.com" "Member" true
            , teamMemberRow "Tom Wilson" "tom@company.com" "Member" false
            , teamMemberRow "Emma Davis" "emma@company.com" "Viewer" true
            ]
        ]
    
      -- Pending invites
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Pending Invitations" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ pendingInviteRow "alex@company.com" "Member" "2 days ago"
            , pendingInviteRow "jordan@company.com" "Viewer" "5 days ago"
            ]
        ]
    
      -- Roles description
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Role Permissions" ]
        , HH.div
            [ cls [ "space-y-3 text-sm" ] ]
            [ roleDescription "Admin" "Full access to all settings, billing, and team management"
            , roleDescription "Member" "Create conversations, share to workspaces, use integrations"
            , roleDescription "Viewer" "View shared conversations only, no creation access"
            ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
teamMemberRow name email role active =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span 
            [ cls [ "w-2 h-2 rounded-full", if active then "bg-green-400" else "bg-muted-foreground" ] ] 
            []
        , HH.div_
            [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text email ]
            ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs px-2 py-1 rounded bg-indigo-400/10 text-indigo-400" ] ] [ HH.text role ]
        , HH.button
            [ cls [ "text-xs text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

pendingInviteRow :: forall w i. String -> String -> String -> HH.HTML w i
pendingInviteRow email role sentAgo =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text" ] ] [ HH.text email ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text $ "Sent " <> sentAgo ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text role ]
        , HH.button
            [ cls [ "text-xs text-indigo-400 hover:text-indigo-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Resend" ]
        , HH.button
            [ cls [ "text-xs text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Cancel" ]
        ]
    ]

roleDescription :: forall w i. String -> String -> HH.HTML w i
roleDescription role desc =
  HH.div
    [ cls [ "flex items-start gap-3 py-2" ] ]
    [ HH.span [ cls [ "text-indigo-400 font-medium w-20" ] ] [ HH.text role ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text desc ]
    ]

formField :: forall w i. String -> HH.HTML w i -> HH.HTML w i
formField label input =
  HH.div_
    [ HH.label [ cls [ "block text-sm font-medium text-text mb-1" ] ] [ HH.text label ]
    , input
    ]

-- ============================================================
-- WORKSPACES TAB
-- ============================================================

workspacesTab :: forall w i. HH.HTML w i
workspacesTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Workspaces list
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Workspaces" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-indigo-400 text-background text-sm font-medium rounded-md hover:bg-indigo-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Create Workspace" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ workspaceRow "Marketing" 5 "12 conversations this week" true
            , workspaceRow "Product" 4 "8 conversations this week" true
            , workspaceRow "Design" 3 "6 conversations this week" true
            , workspaceRow "Operations" 4 "4 conversations this week" false
            ]
        ]
    
      -- Workspace settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ settingToggle "Auto-share to workspace" "New conversations are automatically shared with workspace members" true
            , settingToggle "Allow external sharing" "Members can share conversations via link" false
            , settingToggle "Searchable history" "All shared conversations appear in workspace search" true
            ]
        ]
    ]

workspaceRow :: forall w i. String -> Int -> String -> Boolean -> HH.HTML w i
workspaceRow name members activity active =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text $ show members <> " members" ]
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text activity ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ if active 
            then HH.span [ cls [ "text-xs px-2 py-1 rounded bg-green-400/10 text-green-400" ] ] [ HH.text "Active" ]
            else HH.span [ cls [ "text-xs px-2 py-1 rounded bg-muted text-muted-foreground" ] ] [ HH.text "Quiet" ]
        , HH.button
            [ cls [ "text-xs text-indigo-400 hover:text-indigo-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Settings" ]
        ]
    ]

settingToggle :: forall w i. String -> String -> Boolean -> HH.HTML w i
settingToggle label description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full cursor-pointer transition-colors"
              , if enabled then "bg-indigo-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 bg-white rounded-full mt-1 transition-transform"
                  , if enabled then "translate-x-5" else "translate-x-1"
                  ]
            ]
            []
        ]
    ]

-- ============================================================
-- SSO / SECURITY TAB
-- ============================================================

ssoTab :: forall w i. HH.HTML w i
ssoTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- SSO configuration
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Single Sign-On (SSO)" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Configure SAML-based SSO for your organization. Available on Enterprise plan." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Identity Provider" 
                (HH.select
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm" ] ]
                    [ HH.option_ [ HH.text "Okta" ]
                    , HH.option_ [ HH.text "Azure AD" ]
                    , HH.option_ [ HH.text "Google Workspace" ]
                    , HH.option_ [ HH.text "OneLogin" ]
                    , HH.option_ [ HH.text "Other SAML 2.0" ]
                    ])
            , formField "SSO URL" 
                (HH.input 
                    [ HP.type_ HP.InputText
                    , HP.placeholder "https://your-idp.com/saml/sso"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400" ]
                    ])
            , formField "Certificate" 
                (HH.textarea
                    [ HP.placeholder "Paste your SAML certificate here"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm h-24 focus:outline-none focus:ring-2 focus:ring-indigo-400" ]
                    ])
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-indigo-400 text-background text-sm font-medium rounded-md hover:bg-indigo-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save SSO Configuration" ]
            ]
        ]
    
      -- Security settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Security Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ settingToggle "Require SSO for all users" "Users must sign in via SSO, no password login allowed" false
            , settingToggle "Enforce 2FA" "All team members must enable two-factor authentication" true
            , settingToggle "Session timeout" "Automatically sign out inactive users after 8 hours" true
            ]
        ]
    
      -- Audit logs
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Audit Logs" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Track team activity for compliance and security. Enterprise plan required." ]
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "View Audit Logs" ]
        ]
    ]

-- ============================================================
-- INTEGRATIONS TAB
-- ============================================================

integrationsTab :: forall w i. HH.HTML w i
integrationsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Connected integrations
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Connected Integrations" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ integrationRow "Slack" "Connected to #general, #product" true
            , integrationRow "Notion" "Syncing 3 databases" true
            , integrationRow "Google Workspace" "Connected as team@company.com" true
            ]
        ]
    
      -- Available integrations
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Available Integrations" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ availableIntegration "Linear" "Create issues from conversations"
            , availableIntegration "Jira" "Link to tickets and projects"
            , availableIntegration "Figma" "Import designs as context"
            , availableIntegration "Confluence" "Sync with your wiki"
            , availableIntegration "GitHub" "Access repo files"
            , availableIntegration "Airtable" "Connect databases"
            ]
        ]
    
      -- API access
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "API Access" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Build custom integrations with the omega//work API. Enterprise plan required." ]
        , HH.a
            [ HP.href "/omega/work/docs/api"
            , cls [ "text-sm text-indigo-400 hover:text-indigo-400/80" ]
            ]
            [ HH.text "View API Documentation ->" ]
        ]
    ]

integrationRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
integrationRow name status connected =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text status ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "w-2 h-2 rounded-full bg-green-400" ] ] []
        , HH.button
            [ cls [ "text-xs text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Configure" ]
        , HH.button
            [ cls [ "text-xs text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Disconnect" ]
        ]
    ]

availableIntegration :: forall w i. String -> String -> HH.HTML w i
availableIntegration name description =
  HH.div
    [ cls [ "flex items-center justify-between p-4 border border-border rounded-lg hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.button
        [ cls [ "px-3 py-1 text-xs bg-indigo-400/10 text-indigo-400 rounded-md hover:bg-indigo-400/20 transition-colors cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Connect" ]
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
                [ HP.href "/omega/work/pricing"
                , cls [ "text-sm text-indigo-400 hover:text-indigo-400/80" ]
                ]
                [ HH.text "Change plan" ]
            ]
        , HH.div
            [ cls [ "flex items-center gap-4 mb-4" ] ]
            [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Team" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "$25/seat/month" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "(12 seats = $300/month)" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ planDetail "Seats" "12 active"
            , planDetail "Conversations" "Unlimited"
            , planDetail "Workspaces" "Unlimited"
            , planDetail "Support" "Priority"
            ]
        ]
    
      -- Seat management
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Seat Management" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Add or remove seats. Changes take effect immediately and are prorated." ]
        , HH.div
            [ cls [ "flex items-center gap-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Remove Seat" ]
            , HH.button
                [ cls [ "px-4 py-2 bg-indigo-400 text-background text-sm font-medium rounded-md hover:bg-indigo-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Add Seat ($25/month)" ]
            ]
        ]
    
      -- Payment method
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Payment Method" ]
        , HH.div
            [ cls [ "flex items-center justify-between p-3 border border-border rounded-md" ] ]
            [ HH.div
                [ cls [ "flex items-center gap-3" ] ]
                [ HH.span [ cls [ "text-text" ] ] [ HH.text "Visa ending in 4242" ]
                , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Expires 12/26" ]
                ]
            , HH.button
                [ cls [ "text-sm text-indigo-400 hover:text-indigo-400/80 cursor-pointer" ]
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
            [ cls [ "space-y-2" ] ]
            [ invoiceRow "Feb 1, 2026" "$300.00" "Paid"
            , invoiceRow "Jan 1, 2026" "$275.00" "Paid"
            , invoiceRow "Dec 1, 2025" "$250.00" "Paid"
            ]
        ]
    ]

planDetail :: forall w i. String -> String -> HH.HTML w i
planDetail label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text value ]
    ]

invoiceRow :: forall w i. String -> String -> String -> HH.HTML w i
invoiceRow date amount status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text date ]
    , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text amount ]
    , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/10 text-green-400" ] ] [ HH.text status ]
    ]


