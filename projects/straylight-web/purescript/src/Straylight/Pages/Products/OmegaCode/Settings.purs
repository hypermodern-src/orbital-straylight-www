-- | omega//code Settings Page
-- | Account settings, billing, team management
module Straylight.Pages.Products.OmegaCode.Settings where

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
  = SetTab String

-- ============================================================
-- COMPONENT
-- ============================================================

settingsPage :: forall q i o m. H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const { activeTab: "account" }
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
    [ sidebarLink state "account" "Account"
    , sidebarLink state "providers" "Providers"
    , sidebarLink state "models" "Models"
    , sidebarLink state "sigil" "SIGIL"
    , sidebarLink state "billing" "Billing"
    , sidebarLink state "team" "Team"
    , sidebarLink state "security" "Security"
    ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label =
  HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value
              then "bg-blue-300/10 text-blue-300 font-medium"
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "account" -> accountTab
  "providers" -> providersTab
  "models" -> modelsTab
  "sigil" -> sigilTab
  "billing" -> billingTab
  "team" -> teamTab
  "security" -> securityTab
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
            [ cls [ "flex items-center gap-4 mb-4" ] ]
            [ HH.div
                [ cls [ "w-16 h-16 rounded-full bg-blue-300/20 flex items-center justify-center" ] ]
                [ HH.span [ cls [ "text-blue-300 text-2xl font-bold" ] ] [ HH.text "U" ] ]
            , HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] 
                    [ HH.text "User" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
                    [ HH.text "user@example.com" ]
                ]
            ]
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit Profile" ]
        ]
    
      -- API Key section
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "API Key" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Your API key for programmatic access to omega//code." ]
        , HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.code
                [ cls [ "flex-1 bg-background border border-border rounded px-3 py-2 text-sm font-mono text-muted-foreground" ] ]
                [ HH.text "omega_key_•••••••••••••••••••" ]
            , HH.button
                [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Regenerate" ]
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

-- ============================================================
-- PROVIDERS TAB
-- ============================================================

providersTab :: forall w i. HH.HTML w i
providersTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Active provider
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Provider" ]
        , HH.div
            [ cls [ "flex items-center gap-3 p-4 bg-blue-400/10 border border-blue-400/30 rounded-lg mb-4" ] ]
            [ HH.div
                [ cls [ "w-10 h-10 rounded bg-blue-400/20 flex items-center justify-center" ] ]
                [ HH.span [ cls [ "text-blue-400 font-bold" ] ] [ HH.text "A" ] ]
            , HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text "Anthropic" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "claude-sonnet-4-20250514" ]
                ]
            , HH.span
                [ cls [ "ml-auto text-xs px-2 py-0.5 rounded bg-green-500/20 text-green-400" ] ]
                [ HH.text "Connected" ]
            ]
        ]
    
      -- API Keys
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "API Keys" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "Configure your LLM provider API keys for BYOK mode." ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ apiKeyRow "Anthropic" "ANTHROPIC_API_KEY" true
            , apiKeyRow "OpenAI" "OPENAI_API_KEY" false
            , apiKeyRow "OpenRouter" "OPENROUTER_API_KEY" false
            , apiKeyRow "Groq" "GROQ_API_KEY" false
            ]
        ]
    
      -- Available providers
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Supported Providers" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ providerCard "Anthropic" "Claude models" true
            , providerCard "OpenAI" "GPT-4, GPT-4o" false
            , providerCard "OpenRouter" "Multi-provider gateway" false
            , providerCard "Groq" "Fast inference" false
            , providerCard "Together AI" "Open models" false
            , providerCard "Ollama" "Local models" false
            ]
        ]
    ]

apiKeyRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
apiKeyRow provider envVar configured =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text provider ]
        , HH.code [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text envVar ]
        ]
    , HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ if configured
            then HH.span
              [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/20 text-green-400" ] ]
              [ HH.text "Configured" ]
            else HH.span
              [ cls [ "text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground" ] ]
              [ HH.text "Not set" ]
        , HH.button
            [ cls [ "text-sm text-blue-400 hover:text-blue-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

providerCard :: forall w i. String -> String -> Boolean -> HH.HTML w i
providerCard name description active =
  HH.div
    [ cls [ "p-4 border rounded-lg"
          , if active then "border-blue-400/50 bg-blue-400/5" else "border-border"
          ]
    ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-1" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , if active
            then HH.span
              [ cls [ "text-xs px-2 py-0.5 rounded bg-blue-400/20 text-blue-400" ] ]
              [ HH.text "Active" ]
            else HH.text ""
        ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text description ]
    ]

-- ============================================================
-- MODELS TAB
-- ============================================================

modelsTab :: forall w i. HH.HTML w i
modelsTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- Default model
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Default Model" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "The model used for all omega//code sessions by default." ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ modelOption "claude-sonnet-4-20250514" "Anthropic" "Best balance of speed and capability" true
            , modelOption "claude-opus-4-20250514" "Anthropic" "Most capable, best for complex tasks" false
            , modelOption "gpt-4o" "OpenAI" "Fast, multimodal" false
            , modelOption "gpt-4-turbo" "OpenAI" "Strong reasoning" false
            ]
        ]
    
      -- Model settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Model Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ settingRow "Temperature" "0.0" "Controls randomness. Lower = more deterministic."
            , settingRow "Max Tokens" "8192" "Maximum tokens per response."
            , settingRow "Context Window" "200000" "Maximum context length."
            ]
        ]
    
      -- Crew model preferences
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Crew Mode Models" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ]
            [ HH.text "Different models can be assigned to different agents in Crew mode." ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ crewModelRow "Agent 1" "claude-sonnet-4-20250514"
            , crewModelRow "Agent 2" "claude-sonnet-4-20250514"
            , crewModelRow "Agent 3" "claude-sonnet-4-20250514"
            ]
        , HH.button
            [ cls [ "mt-4 text-sm text-blue-400 hover:text-blue-400/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Add agent configuration" ]
        ]
    ]

modelOption :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
modelOption model provider description selected =
  HH.div
    [ cls [ "flex items-center justify-between p-3 border rounded-lg cursor-pointer transition-colors"
          , if selected then "border-blue-400 bg-blue-400/10" else "border-border hover:bg-card"
          ]
    ]
    [ HH.div_
        [ HH.div
            [ cls [ "flex items-center gap-2" ] ]
            [ HH.span [ cls [ "text-text font-mono text-sm" ] ] [ HH.text model ]
            , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text $ "(" <> provider <> ")" ]
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground mt-0.5" ] ] [ HH.text description ]
        ]
    , if selected
        then HH.span [ cls [ "text-blue-400" ] ] [ HH.text "✓" ]
        else HH.text ""
    ]

settingRow :: forall w i. String -> String -> String -> HH.HTML w i
settingRow label value description =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.input
        [ HP.type_ HP.InputText
        , HP.value value
        , cls [ "w-24 px-3 py-1.5 bg-background border border-border rounded text-sm text-text text-right font-mono" ]
        ]
    ]

crewModelRow :: forall w i. String -> String -> HH.HTML w i
crewModelRow agent model =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text agent ]
    , HH.code [ cls [ "text-sm text-muted-foreground font-mono" ] ] [ HH.text model ]
    ]

-- ============================================================
-- SIGIL TAB
-- ============================================================

sigilTab :: forall w i. HH.HTML w i
sigilTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ -- SIGIL status
      HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "SIGIL Protocol" ]
        , HH.div
            [ cls [ "flex items-center gap-3 p-4 bg-blue-400/10 border border-blue-400/30 rounded-lg mb-4" ] ]
            [ HH.span [ cls [ "text-2xl" ] ] [ HH.text "✓" ]
            , HH.div_
                [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text "SIGIL Enabled" ]
                , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "18 Lean4 proofs verified" ]
                ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ]
            [ HH.text "SIGIL provides formally verified tool call parsing. Corrupted parse states cannot propagate to agents." ]
        ]
    
      -- Verification settings
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Verification Settings" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ toggleRow "Strict Mode" true "Reject any tool call that fails verification"
            , toggleRow "Stream Validation" true "Validate incrementally during streaming"
            , toggleRow "Recovery Mode" true "Attempt automatic recovery from malformed input"
            ]
        ]
    
      -- Protocol stats
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Protocol Statistics" ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ statBox "Tool Calls" "12,847"
            , statBox "Verified" "12,847"
            , statBox "Recovered" "23"
            , statBox "Rejected" "0"
            ]
        ]
    
      -- Proof status
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Lean4 Proof Status" ]
        , HH.div
            [ cls [ "space-y-2" ] ]
            [ proofRow "StreamWellFormed" "verified"
            , proofRow "ParseComplete" "verified"
            , proofRow "NoCorruptionPropagation" "verified"
            , proofRow "RecoveryTerminates" "verified"
            , proofRow "IncrementalConsistent" "verified"
            ]
        , HH.p [ cls [ "text-xs text-muted-foreground mt-4" ] ]
            [ HH.text "All proofs verified. 0 sorry statements." ]
        ]
    ]

toggleRow :: forall w i. String -> Boolean -> String -> HH.HTML w i
toggleRow label enabled description =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "w-10 h-6 rounded-full cursor-pointer transition-colors"
              , if enabled then "bg-blue-400" else "bg-muted"
              ]
        ]
        [ HH.div
            [ cls [ "w-4 h-4 mt-1 rounded-full bg-white transition-transform"
                  , if enabled then "ml-5" else "ml-1"
                  ]
            ]
            []
        ]
    ]

statBox :: forall w i. String -> String -> HH.HTML w i
statBox label value =
  HH.div
    [ cls [ "text-center p-4 bg-background rounded-lg" ] ]
    [ HH.p [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    ]

proofRow :: forall w i. String -> String -> HH.HTML w i
proofRow name status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text name ]
    , HH.span
        [ cls [ "text-xs px-2 py-0.5 rounded bg-blue-400/20 text-blue-400" ] ]
        [ HH.text status ]
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
            , HH.button
                [ cls [ "text-sm text-blue-300 hover:text-blue-300/80 cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "Manage Billing" ]
            ]
        , HH.div
            [ cls [ "inline-flex items-center gap-2 mb-4" ] ]
            [ HH.span [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Pro" ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "$49/mo" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ planStat "Agents" "10 concurrent"
            , planStat "Requests" "Unlimited"
            , planStat "Crew Mode" "Enabled"
            , planStat "Support" "Priority"
            ]
        ]
    
      -- Upgrade options
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Upgrade" ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
            [ upgradePlanCard "Team" "$199/mo" "Unlimited agents, team workspaces, SSO" false
            , upgradePlanCard "Enterprise" "Custom" "Air-gapped, custom integrations, SLA" true
            ]
        ]
    
      -- Billing history
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Billing History" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ billingRow "Feb 1, 2026" "Pro Plan" "$49.00" "Paid"
            , billingRow "Jan 1, 2026" "Pro Plan" "$49.00" "Paid"
            , billingRow "Dec 1, 2025" "Pro Plan" "$49.00" "Paid"
            ]
        ]
    ]

planStat :: forall w i. String -> String -> HH.HTML w i
planStat label value =
  HH.div_
    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text value ]
    ]

upgradePlanCard :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
upgradePlanCard name price description isContact =
  HH.div
    [ cls [ "border border-border rounded-lg p-4" ] ]
    [ HH.h4 [ cls [ "font-semibold text-text mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-sm text-muted-foreground mb-3" ] ] [ HH.text price ]
    , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] [ HH.text description ]
    , HH.button
        [ cls [ "w-full py-2 text-sm font-medium rounded transition-colors cursor-pointer"
              , if isContact
                  then "border border-border text-text hover:bg-card"
                  else "bg-blue-300 text-background hover:bg-blue-300/90"
              ]
        , HP.type_ HP.ButtonButton
        ]
        [ HH.text $ if isContact then "Contact Sales" else "Upgrade" ]
    ]

billingRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
billingRow date description amount status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text description ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text date ]
        ]
    , HH.div
        [ cls [ "text-right" ] ]
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text amount ]
        , HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/20 text-green-400" ] ]
            [ HH.text status ]
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
                [ cls [ "px-4 py-2 bg-blue-300 text-background text-sm font-medium rounded-md hover:bg-blue-300/90 transition-colors cursor-pointer" ]
                , HP.type_ HP.ButtonButton
                ]
                [ HH.text "+ Invite Member" ]
            ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ teamMemberRow "You" "you@example.com" "Owner"
            ]
        , HH.p
            [ cls [ "text-sm text-muted-foreground mt-4" ] ]
            [ HH.text "Upgrade to Team plan for additional seats and team workspaces." ]
        ]
    ]

teamMemberRow :: forall w i. String -> String -> String -> HH.HTML w i
teamMemberRow name email role =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.div
            [ cls [ "w-8 h-8 rounded-full bg-blue-300/20 flex items-center justify-center" ] ]
            [ HH.span [ cls [ "text-blue-300 text-sm font-medium" ] ] [ HH.text "U" ] ]
        , HH.div_
            [ HH.p [ cls [ "text-sm text-text font-medium" ] ] [ HH.text name ]
            , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text email ]
            ]
        ]
    , HH.span
        [ cls [ "text-xs px-2 py-1 rounded bg-muted text-muted-foreground" ] ]
        [ HH.text role ]
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
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Enable 2FA" ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Active Sessions" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Manage your active sessions across devices." ]
        , HH.div
            [ cls [ "space-y-3 mb-4" ] ]
            [ sessionRow "Current session" "Linux • Chrome" "Active now"
            , sessionRow "MacBook Pro" "macOS • Safari" "2 hours ago"
            ]
        , HH.button
            [ cls [ "px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Sign out all other sessions" ]
        ]
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Attestation Keys" ]
        , HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Post-quantum keys used for change attestation." ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ keyRow "ML-DSA (Primary)" "0x8f3a2b..." "Active"
            , keyRow "Ed25519 (Fallback)" "0x7c1d4e..." "Active"
            ]
        ]
    ]

sessionRow :: forall w i. String -> String -> String -> HH.HTML w i
sessionRow name device time =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text device ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text time ]
    ]

keyRow :: forall w i. String -> String -> String -> HH.HTML w i
keyRow name fingerprint status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text name ]
        , HH.code [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text fingerprint ]
        ]
    , HH.span
        [ cls [ "text-xs px-2 py-0.5 rounded bg-green-500/20 text-green-400" ] ]
        [ HH.text status ]
    ]
