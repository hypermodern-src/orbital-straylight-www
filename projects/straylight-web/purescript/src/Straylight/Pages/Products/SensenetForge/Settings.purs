-- | sensenet//forge Settings Page
-- | Account settings, billing, team management
module Straylight.Pages.Products.SensenetForge.Settings where

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
  { activeTab: "account"
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
    [ cls [ "space-y-6" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2" ] ] 
            [ HH.text "Account" ]
        , HH.div
            [ cls [ "space-y-1" ] ]
            [ sidebarButton "account" "Profile" state.activeTab
            , sidebarButton "billing" "Billing" state.activeTab
            , sidebarButton "security" "Security" state.activeTab
            ]
        ]
    , HH.div_
        [ HH.p [ cls [ "text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2" ] ] 
            [ HH.text "Organization" ]
        , HH.div
            [ cls [ "space-y-1" ] ]
            [ sidebarButton "team" "Team" state.activeTab
            , sidebarButton "repos" "Repositories" state.activeTab
            , sidebarButton "policies" "Branch Policies" state.activeTab
            , sidebarButton "integrations" "Integrations" state.activeTab
            ]
        ]
    ]

sidebarButton :: forall m. String -> String -> String -> H.ComponentHTML Action () m
sidebarButton value label activeTab =
  HH.button
    [ cls [ "w-full text-left px-3 py-2 rounded text-sm transition-colors"
          , if value == activeTab 
              then "bg-rose-400/10 text-rose-400 font-medium" 
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetActiveTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "account" -> accountTab
  "billing" -> billingTab
  "team" -> teamTab
  "security" -> securityTab
  "repos" -> reposTab
  "policies" -> policiesTab
  "integrations" -> integrationsTab
  _ -> accountTab

-- ============================================================
-- ACCOUNT TAB
-- ============================================================

accountTab :: forall w i. HH.HTML w i
accountTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Profile section
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Profile" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Username" 
                (HH.input 
                    [ HP.type_ HP.InputText
                    , HP.value "alice"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ]
                    ])
            , formField "Display Name" 
                (HH.input 
                    [ HP.type_ HP.InputText
                    , HP.value "Alice Chen"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ]
                    ])
            , formField "Email" 
                (HH.input 
                    [ HP.type_ HP.InputEmail
                    , HP.value "alice@example.com"
                    , HP.disabled true
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-muted-foreground text-sm" ]
                    ])
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Changes" ]
            ]
        ]
    
      -- SSH Keys
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "SSH Keys" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Key" ]
            ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ sshKeyRow "MacBook Pro" "SHA256:abc123..." "Added Feb 10, 2026"
            , sshKeyRow "Work Desktop" "SHA256:def456..." "Added Jan 5, 2026"
            ]
        ]
    
      -- Danger zone
    , HH.div
        [ cls [ "bg-card border border-red-500/30 rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-red-400 mb-4" ] ] [ HH.text "Danger Zone" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Once you delete your account, all your repositories and diffs will be permanently deleted." ]
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
    [ HH.label [ cls [ "block text-sm font-medium text-text mb-1" ] ] [ HH.text label ]
    , input
    ]

sshKeyRow :: forall w i. String -> String -> String -> HH.HTML w i
sshKeyRow name fingerprint added =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text fingerprint ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text added ]
        , HH.button
            [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
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
                [ HP.href "/sensenet/forge/pricing"
                , cls [ "text-sm text-rose-400 hover:text-rose-400/80" ]
                ]
                [ HH.text "Change plan" ]
            ]
        , HH.div
            [ cls [ "flex items-center gap-4 mb-4" ] ]
            [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Pro" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "$15/user/month" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ planDetail "Private Repos" "Unlimited"
            , planDetail "Collaborators" "Unlimited"
            , planDetail "Attestation" "Included"
            , planDetail "Support" "Email"
            ]
        ]
    
      -- Usage
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Usage This Month" ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ usageStat "Diffs Created" "127"
            , usageStat "Stacks Landed" "42"
            , usageStat "Reviews Completed" "89"
            , usageStat "Search Queries" "1.2k"
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
                [ cls [ "text-sm text-rose-400 hover:text-rose-400/80 cursor-pointer" ]
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
            [ invoiceRow "Feb 1, 2026" "$45.00" "Paid"
            , invoiceRow "Jan 1, 2026" "$45.00" "Paid"
            , invoiceRow "Dec 1, 2025" "$30.00" "Paid"
            ]
        ]
    ]

planDetail :: forall w i. String -> String -> HH.HTML w i
planDetail label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text value ]
    ]

usageStat :: forall w i. String -> String -> HH.HTML w i
usageStat label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-xl font-bold text-rose-400" ] ] [ HH.text value ]
    ]

invoiceRow :: forall w i. String -> String -> String -> HH.HTML w i
invoiceRow date amount status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text date ]
    , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text amount ]
    , HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/10 text-green-400" ] ] [ HH.text status ]
    ]

-- ============================================================
-- TEAM TAB
-- ============================================================

teamTab :: forall w i. HH.HTML w i
teamTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Team members
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Team Members" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Invite Member" ]
            ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ teamMemberRow "Alice Chen" "alice@example.com" "Owner"
            , teamMemberRow "Bob Wilson" "bob@example.com" "Admin"
            , teamMemberRow "Carol Davis" "carol@example.com" "Member"
            ]
        ]
    
      -- Pending invites
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Pending Invites" ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ pendingInviteRow "dave@example.com" "Sent 2 days ago"
            ]
        ]
    
      -- Organization settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Organization" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Organization Name" 
                (HH.input 
                    [ HP.type_ HP.InputText
                    , HP.value "straylight"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ]
                    ])
            , formField "Organization URL" 
                (HH.input 
                    [ HP.type_ HP.InputText
                    , HP.value "forge.sensenet.dev/straylight"
                    , HP.disabled true
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-muted-foreground text-sm" ]
                    ])
            ]
        , HH.div
            [ cls [ "mt-4" ] ]
            [ HH.button
                [ cls [ "px-4 py-2 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Save Changes" ]
            ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> String -> HH.HTML w i
teamMemberRow name email role =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text email ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground" ] ] [ HH.text role ]
        , if role /= "Owner"
            then HH.button
                [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Edit" ]
            else HH.text ""
        ]
    ]

pendingInviteRow :: forall w i. String -> String -> HH.HTML w i
pendingInviteRow email sentTime =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text email ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text sentTime ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-2" ] ]
        [ HH.button
            [ cls [ "text-sm text-rose-400 hover:text-rose-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Resend" ]
        , HH.button
            [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    ]

-- ============================================================
-- SECURITY TAB
-- ============================================================

securityTab :: forall w i. HH.HTML w i
securityTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Two-factor auth
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Two-Factor Authentication" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Add an extra layer of security to your account." ]
        , HH.div
            [ cls [ "flex items-center gap-4" ] ]
            [ HH.span [ cls [ "text-sm text-green-400" ] ] [ HH.text "Enabled" ]
            , HH.button
                [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Manage" ]
            ]
        ]
    
      -- Signing keys
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Signing Keys" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Generate Key" ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Keys used to sign your commits and diffs for attestation." ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ signingKeyRow "ed25519" "SHA256:xyz789..." "Primary" true
            ]
        ]
    
      -- Active sessions
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Sessions" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Manage your active sessions across devices." ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ sessionRow "MacBook Pro" "San Francisco, US" "Active now" true
            , sessionRow "Windows Desktop" "San Francisco, US" "2 hours ago" false
            ]
        , HH.button
            [ cls [ "mt-4 text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Sign out all other sessions" ]
        ]
    
      -- Audit log
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Audit Log" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Recent security events for your account." ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ auditRow "Login" "MacBook Pro" "2 hours ago"
            , auditRow "SSH key added" "Work Desktop" "3 days ago"
            , auditRow "Password changed" "MacBook Pro" "1 week ago"
            ]
        ]
    ]

signingKeyRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
signingKeyRow keyType fingerprint label isPrimary =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-sm text-text font-medium" ] ] [ HH.text keyType ]
            , if isPrimary 
                then HH.span [ cls [ "text-xs px-1.5 py-0.5 rounded bg-rose-400/10 text-rose-400" ] ] 
                    [ HH.text label ]
                else HH.text ""
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text fingerprint ]
        ]
    , HH.button
        [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Revoke" ]
    ]

sessionRow :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
sessionRow device location time current =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text device ]
            , if current 
                then HH.span [ cls [ "text-xs px-1.5 py-0.5 rounded bg-green-500/10 text-green-400" ] ] 
                    [ HH.text "Current" ]
                else HH.text ""
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text location ]
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]

auditRow :: forall w i. String -> String -> String -> HH.HTML w i
auditRow action device time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text action ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text device ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- REPOS TAB
-- ============================================================

reposTab :: forall w i. HH.HTML w i
reposTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Default settings
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Repository Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ toggleSetting "Require attestation" "All commits must have valid attestation signatures" true
            , toggleSetting "Auto-rebase stacks" "Automatically rebase dependent diffs when base changes" true
            , toggleSetting "Squash on land" "Squash all commits in a diff when landing" false
            ]
        ]
    
      -- Visibility defaults
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Visibility" ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ radioOption "visibility" "private" "Private" "Only collaborators can access" true
            , radioOption "visibility" "public" "Public" "Anyone can view and clone" false
            ]
        ]
    
      -- jujutsu settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "jujutsu Configuration" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "Configure default jj settings for new repositories." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Default branch name"
                (HH.input
                    [ HP.type_ HP.InputText
                    , HP.value "main"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ]
                    ])
            , toggleSetting "Git compatibility mode" "Enable Git colocated workspace by default" true
            ]
        ]
    ]

toggleSetting :: forall w i. String -> String -> Boolean -> HH.HTML w i
toggleSetting title description enabled =
  HH.div
    [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full cursor-pointer transition-colors"
              , if enabled then "bg-rose-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 rounded-full bg-white mt-1 transition-transform"
                  , if enabled then "ml-5" else "ml-1"
                  ]
            ]
            []
        ]
    ]

radioOption :: forall w i. String -> String -> String -> String -> Boolean -> HH.HTML w i
radioOption _ _ title description selected =
  HH.div
    [ cls [ "flex items-start gap-3 p-3 rounded-lg cursor-pointer transition-colors"
          , if selected then "bg-rose-400/10 border border-rose-400/20" else "border border-border hover:bg-card"
          ]
    ]
    [ HH.div
        [ cls [ "w-4 h-4 rounded-full border-2 mt-0.5"
              , if selected then "border-rose-400 bg-rose-400" else "border-muted-foreground"
              ]
        ]
        [ if selected 
            then HH.div [ cls [ "w-1.5 h-1.5 rounded-full bg-white m-auto mt-0.5" ] ] []
            else HH.text ""
        ]
    , HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    ]

-- ============================================================
-- POLICIES TAB
-- ============================================================

policiesTab :: forall w i. HH.HTML w i
policiesTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Branch protection
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Branch Protection Rules" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Rule" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ branchRule "main" [ "Require review", "Require attestation", "No force push" ]
            , branchRule "release/*" [ "Require 2 reviews", "Require CI pass" ]
            ]
        ]
    
      -- Review requirements
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Review Requirements" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ formField "Minimum reviewers"
                (HH.select
                    [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ] ]
                    [ HH.option_ [ HH.text "1" ]
                    , HH.option_ [ HH.text "2" ]
                    , HH.option_ [ HH.text "3" ]
                    ])
            , toggleSetting "Dismiss stale reviews" "Require re-review after new changes are pushed" true
            , toggleSetting "Require code owners" "Require approval from code owners for relevant paths" false
            ]
        ]
    
      -- Agent policies
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Agent Policies" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "Control how AI-generated code is handled in your repositories." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ toggleSetting "Require attestation for agent commits" "All agent-generated commits must include valid attestation" true
            , toggleSetting "Require human review for agent code" "Agent-generated diffs always need human approval" true
            , formField "Allowed agent models"
                (HH.input
                    [ HP.type_ HP.InputText
                    , HP.value "claude-*, gpt-4*"
                    , HP.placeholder "claude-*, gpt-4*"
                    , cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm focus:outline-none focus:ring-2 focus:ring-rose-400" ]
                    ])
            ]
        ]
    ]

branchRule :: forall w i. String -> Array String -> HH.HTML w i
branchRule pattern rules =
  HH.div
    [ cls [ "flex items-center justify-between p-3 border border-border rounded-lg" ] ]
    [ HH.div_
        [ HH.span [ cls [ "text-text font-mono text-sm" ] ] [ HH.text pattern ]
        , HH.div
            [ cls [ "flex gap-2 mt-1" ] ]
            (map (\rule -> HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-rose-400/10 text-rose-400" ] ] [ HH.text rule ]) rules)
        ]
    , HH.button
        [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Edit" ]
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
            [ cls [ "space-y-3" ] ]
            [ integrationRow "Slack" "Post notifications to #engineering" true
            , integrationRow "Linear" "Sync diff status with issues" true
            ]
        ]
    
      -- Available integrations
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Available Integrations" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ availableIntegration "Discord" "Post review notifications to Discord channels"
            , availableIntegration "Jira" "Link diffs to Jira issues"
            , availableIntegration "PagerDuty" "Alert on failed CI for protected branches"
            , availableIntegration "Datadog" "Send metrics and logs to Datadog"
            ]
        ]
    
      -- Webhooks
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Webhooks" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Add Webhook" ]
            ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ webhookRow "https://api.example.com/forge-webhook" [ "diff.created", "diff.landed" ]
            ]
        ]
    
      -- API Keys
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center justify-between mb-4" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "API Keys" ]
            , HH.button
                [ cls [ "px-3 py-1.5 bg-rose-400 text-background text-sm font-medium rounded-md hover:bg-rose-400/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Create Key" ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "API keys for programmatic access to sensenet//forge." ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ apiKeyRow "CI Pipeline" "forge_sk_...abc123" "Created Feb 15, 2026"
            , apiKeyRow "Agent Integration" "forge_sk_...def456" "Created Feb 10, 2026"
            ]
        ]
    ]

integrationRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
integrationRow name description connected =
  HH.div
    [ cls [ "flex items-center justify-between p-3 border border-border rounded-lg" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/10 text-green-400" ] ] 
            [ HH.text $ if connected then "Connected" else "Disconnected" ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Configure" ]
        ]
    ]

availableIntegration :: forall w i. String -> String -> HH.HTML w i
availableIntegration name description =
  HH.div
    [ cls [ "p-4 border border-border rounded-lg hover:border-rose-400/50 transition-colors cursor-pointer" ] ]
    [ HH.p [ cls [ "text-sm text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-xs text-muted-foreground mb-3" ] ] [ HH.text description ]
    , HH.button
        [ cls [ "text-sm text-rose-400 hover:text-rose-400/80" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Connect" ]
    ]

webhookRow :: forall w i. String -> Array String -> HH.HTML w i
webhookRow url events =
  HH.div
    [ cls [ "flex items-center justify-between p-3 border border-border rounded-lg" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-mono truncate max-w-md" ] ] [ HH.text url ]
        , HH.div
            [ cls [ "flex gap-2 mt-1" ] ]
            (map (\event -> HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground" ] ] [ HH.text event ]) events)
        ]
    , HH.button
        [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text "Delete" ]
    ]

apiKeyRow :: forall w i. String -> String -> String -> HH.HTML w i
apiKeyRow name key created =
  HH.div
    [ cls [ "flex items-center justify-between p-3 border border-border rounded-lg" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text key ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text created ]
        , HH.button
            [ cls [ "text-sm text-red-400 hover:text-red-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    ]
