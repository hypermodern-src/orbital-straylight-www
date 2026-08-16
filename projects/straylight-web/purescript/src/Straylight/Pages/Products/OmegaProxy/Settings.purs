-- | omega//proxy Settings Page
module Straylight.Pages.Products.OmegaProxy.Settings where

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
  { initialState: const { activeTab: "providers" }
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
    [ HH.div [ cls [ "mb-8" ] ] [ HH.h1 [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Settings" ] ]
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ]
        [ sidebar state, content state ]
    ]

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state =
  HH.nav
    [ cls [ "space-y-1" ] ]
    [ sidebarLink state "providers" "Providers"
    , sidebarLink state "verification" "Verification"
    , sidebarLink state "ratelimits" "Rate Limits"
    , sidebarLink state "zeromq" "ZeroMQ"
    , sidebarLink state "account" "Account"
    ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label =
  HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value
              then "bg-orange-400/10 text-orange-400 font-medium"
              else "text-muted-foreground hover:text-text hover:bg-card"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "providers" -> providersTab
  "verification" -> verificationTab
  "ratelimits" -> rateLimitsTab
  "zeromq" -> zeromqTab
  "account" -> accountTab
  _ -> providersTab

providersTab :: forall w i. HH.HTML w i
providersTab =
  HH.div
    [ cls [ "space-y-6" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Provider Configuration" ]
        , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Configure API keys and settings for each LLM provider." ]
        , HH.div [ cls [ "space-y-4" ] ]
            [ providerConfig "OpenAI" "OPENAI_API_KEY" true
            , providerConfig "Anthropic" "ANTHROPIC_API_KEY" true
            , providerConfig "Google" "GOOGLE_API_KEY" false
            , providerConfig "Ollama" "http://localhost:11434" true
            ]
        ]
    ]

providerConfig :: forall w i. String -> String -> Boolean -> HH.HTML w i
providerConfig name keyHint configured =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-muted-foreground text-sm font-mono" ] ] [ HH.text keyHint ]
        ]
    , HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded"
                  , if configured then "bg-green-400/10 text-green-400" else "bg-muted text-muted-foreground"
                  ]
            ]
            [ HH.text (if configured then "Configured" else "Not configured") ]
        , HH.button
            [ cls [ "text-sm text-orange-400 hover:text-orange-300" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    ]

verificationTab :: forall w i. HH.HTML w i
verificationTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Verification Rules" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Configure reset-on-ambiguity thresholds and verification behavior." ]
    , HH.div [ cls [ "space-y-6" ] ]
        [ settingRow "Ambiguity Threshold" "0.30" "Confidence below this triggers reset"
        , settingRow "Max Reset Attempts" "3" "Maximum retries before failing"
        , settingRow "Tool Call Repair" "Enabled" "Automatically fix malformed tool calls"
        , settingRow "Schema Validation" "Strict" "Validate responses against SIGIL schema"
        ]
    ]

settingRow :: forall w i. String -> String -> String -> HH.HTML w i
settingRow label value description =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
        ]
    , HH.div
        [ cls [ "bg-background border border-border rounded px-3 py-1.5 text-text text-sm font-mono" ] ]
        [ HH.text value ]
    ]

rateLimitsTab :: forall w i. HH.HTML w i
rateLimitsTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Rate Limits" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Configure request rate limits per provider and globally." ]
    , HH.div [ cls [ "space-y-6" ] ]
        [ settingRow "Global Rate Limit" "1000 req/min" "Maximum requests per minute across all providers"
        , settingRow "Per-Provider Limit" "500 req/min" "Maximum requests per provider per minute"
        , settingRow "Burst Limit" "50 req/sec" "Maximum burst requests per second"
        , settingRow "Backpressure" "Enabled" "Apply backpressure when limits approached"
        ]
    ]

zeromqTab :: forall w i. HH.HTML w i
zeromqTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "ZeroMQ Configuration" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Configure SIGIL frame transport over ZeroMQ." ]
    , HH.div [ cls [ "space-y-6" ] ]
        [ settingRow "PUB Socket" "tcp://*:5555" "SIGIL frame broadcast address"
        , settingRow "REP Socket" "tcp://*:5556" "Synchronous request/reply address"
        , settingRow "High Water Mark" "10000" "Maximum queued messages"
        , settingRow "Reconnect Interval" "1000ms" "Automatic reconnection delay"
        ]
    ]

accountTab :: forall w i. HH.HTML w i
accountTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Account Settings" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Manage your omega//proxy account and API keys." ]
    , HH.div [ cls [ "space-y-6" ] ]
        [ settingRow "API Key" "op_live_xxxx...xxxx" "Your omega//proxy API key"
        , settingRow "Endpoint" "https://proxy.straylight.software" "Your managed proxy endpoint"
        , settingRow "Plan" "Pro" "Current subscription plan"
        ]
    ]
