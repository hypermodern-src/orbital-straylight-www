-- | omega//boost Dashboard Page
-- | User dashboard for inference metrics, latency, throughput, GPU utilization
module Straylight.Pages.Products.OmegaBoost.Dashboard where

import Prelude

import Data.Maybe (Maybe(..))
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
  , showNewKeyModal :: Boolean
  , newKeyName :: String
  , createdKey :: Maybe String
  }

data Action
  = SetActiveTab String
  | OpenNewKeyModal
  | CloseNewKeyModal
  | SetNewKeyName String
  | CreateApiKey

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
  , showNewKeyModal: false
  , newKeyName: ""
  , createdKey: Nothing
  }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetActiveTab tab -> H.modify_ _ { activeTab = tab }
  OpenNewKeyModal -> H.modify_ _ { showNewKeyModal = true, createdKey = Nothing }
  CloseNewKeyModal -> H.modify_ _ { showNewKeyModal = false, newKeyName = "", createdKey = Nothing }
  SetNewKeyName name -> H.modify_ _ { newKeyName = name }
  CreateApiKey -> do
    state <- H.get
    let fakeKey = "boost_live_" <> state.newKeyName <> "_abc123xyz789"
    H.modify_ _ { createdKey = Just fakeKey }

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
    , if state.showNewKeyModal then newKeyModal state else HH.text ""
    ]

header :: forall w i. HH.HTML w i
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.h1
        [ cls [ "text-2xl font-bold text-text mb-2" ] ]
        [ HH.text "Dashboard" ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text "Monitor inference metrics, latency, throughput, and GPU utilization." ]
    ]

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state =
  HH.div
    [ cls [ "flex gap-1 border-b border-border mb-8" ] ]
    [ tabButton "overview" "Overview" state.activeTab
    , tabButton "keys" "API Keys" state.activeTab
    , tabButton "providers" "BYOK Providers" state.activeTab
    , tabButton "analytics" "Metrics" state.activeTab
    , tabButton "usage" "Usage" state.activeTab
    ]

tabButton :: forall m. String -> String -> String -> H.ComponentHTML Action () m
tabButton value label activeTab =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px"
          , if value == activeTab 
              then "text-yellow-400 border-b-2 border-yellow-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetActiveTab value
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "keys" -> keysTab state
  "providers" -> providersTab
  "analytics" -> analyticsTab
  "usage" -> usageTab
  _ -> overviewTab

-- ============================================================
-- NEW KEY MODAL
-- ============================================================

newKeyModal :: forall m. State -> H.ComponentHTML Action () m
newKeyModal state =
  HH.div
    [ cls [ "fixed inset-0 bg-background/80 flex items-center justify-center z-50" ] ]
    [ HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 w-full max-w-md" ] ]
        [ case state.createdKey of
            Nothing -> newKeyForm state
            Just key -> newKeySuccess key
        ]
    ]

newKeyForm :: forall m. State -> H.ComponentHTML Action () m
newKeyForm state =
  HH.div_
    [ HH.h3
        [ cls [ "text-lg font-semibold text-text mb-4" ] ]
        [ HH.text "Create API Key" ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-4" ] ]
        [ HH.text "Give your API key a name to help you identify it later." ]
    , HH.div
        [ cls [ "mb-4" ] ]
        [ HH.label
            [ cls [ "block text-sm font-medium text-text mb-2" ] ]
            [ HH.text "Key Name" ]
        , HH.input
            [ cls [ "w-full px-3 py-2 bg-background border border-border rounded-md text-text text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-yellow-400" ]
            , HP.placeholder "e.g., Production, Development"
            , HP.value state.newKeyName
            , HE.onValueInput SetNewKeyName
            ]
        ]
    , HH.div
        [ cls [ "flex justify-end gap-3" ] ]
        [ HH.button
            [ cls [ "px-4 py-2 text-sm font-medium text-muted-foreground hover:text-text transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            , HE.onClick \_ -> CloseNewKeyModal
            ]
            [ HH.text "Cancel" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed" ]
            , HP.type_ HP.ButtonButton
            , HP.disabled (state.newKeyName == "")
            , HE.onClick \_ -> CreateApiKey
            ]
            [ HH.text "Create Key" ]
        ]
    ]

newKeySuccess :: forall m. String -> H.ComponentHTML Action () m
newKeySuccess key =
  HH.div_
    [ HH.h3
        [ cls [ "text-lg font-semibold text-text mb-4" ] ]
        [ HH.text "API Key Created" ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-3" ] ]
        [ HH.text "Your API key has been created. Copy it now - you won't be able to see it again!" ]
    , HH.div
        [ cls [ "p-3 bg-background border border-yellow-400/30 rounded-md mb-4" ] ]
        [ HH.code
            [ cls [ "text-sm font-mono text-yellow-400 break-all" ] ]
            [ HH.text key ]
        ]
    , HH.p
        [ cls [ "text-xs text-muted-foreground mb-4" ] ]
        [ HH.text "Store this key securely. For security, it will only be shown once." ]
    , HH.div
        [ cls [ "flex justify-end" ] ]
        [ HH.button
            [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            , HE.onClick \_ -> CloseNewKeyModal
            ]
            [ HH.text "Done" ]
        ]
    ]

-- ============================================================
-- OVERVIEW TAB
-- ============================================================

overviewTab :: forall w i. HH.HTML w i
overviewTab =
  HH.div_
    [ -- Stats grid
      HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Tokens" "12.4M" "This month"
        , statCard "TTFT" "4.2ms" "p99 latency"
        , statCard "Throughput" "11.8k" "tok/s avg"
        , statCard "GPU Util" "94%" "Last 24h"
        ]
    
      -- Quick start
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-8" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Quick Start" ]
        , codeBlock
            [ codeLine "# " "Replace vLLM or raw provider API"
            , codeLine "" "client = OpenAI(base_url=\"https://boost.omega.dev/v1\")"
            , HH.text "\n"
            , codeLine "# " "CUTLASS kernels handle inference optimization"
            , codeLine "" "response = client.chat.completions.create(...)"
            ]
        ]
    
      -- Recent activity
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Recent Inference" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ activityItem "Inference" "gpt-4-turbo (1.2k tok)" "2 min ago" "batched"
            , activityItem "Inference" "claude-3-opus (856 tok)" "5 min ago" "priority"
            , activityItem "Inference" "llama-70b (2.1k tok)" "8 min ago" "batched"
            , activityItem "BYOK Added" "Anthropic API Key" "1 hour ago" ""
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

activityItem :: forall w i. String -> String -> String -> String -> HH.HTML w i
activityItem type_ description time status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded font-medium bg-yellow-400/10 text-yellow-400" ] ]
            [ HH.text type_ ]
        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text description ]
        , if status /= ""
            then HH.span
              [ cls [ "text-xs px-2 py-0.5 rounded"
                    , case status of
                        "batched" -> "bg-green-500/20 text-green-400"
                        "priority" -> "bg-yellow-500/20 text-yellow-400"
                        _ -> "bg-muted text-muted-foreground"
                    ]
              ]
              [ HH.text status ]
            else HH.text ""
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
    ]

-- ============================================================
-- KEYS TAB
-- ============================================================

keysTab :: forall m. State -> H.ComponentHTML Action () m
keysTab _ =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "API Keys" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            , HE.onClick \_ -> OpenNewKeyModal
            ]
            [ HH.text "+ New Key" ]
        ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ apiKeyCard "Production" "boost_live_prod_***abc" "inference" "2 hours ago"
        , apiKeyCard "Development" "boost_live_dev_***xyz" "inference" "Yesterday"
        , apiKeyCard "CI Pipeline" "boost_live_ci_***def" "metrics" "3 days ago"
        ]
    ]

apiKeyCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
apiKeyCard name keyPrefix scopes lastUsed =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span
                [ cls [ "text-xs px-1.5 py-0.5 rounded bg-muted text-muted-foreground" ] ]
                [ HH.text scopes ]
            ]
        , HH.button
            [ cls [ "text-sm text-danger hover:text-danger/80 cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Revoke" ]
        ]
    , HH.code
        [ cls [ "block text-sm font-mono text-muted-foreground mb-2" ] ]
        [ HH.text keyPrefix ]
    , HH.p
        [ cls [ "text-xs text-muted-foreground" ] ]
        [ HH.text $ "Last used: " <> lastUsed ]
    ]

-- ============================================================
-- PROVIDERS TAB
-- ============================================================

providersTab :: forall w i. HH.HTML w i
providersTab =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-6" ] ]
        [ HH.h2 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "BYOK Providers" ]
        , HH.button
            [ cls [ "px-4 py-2 bg-yellow-400 text-background text-sm font-medium rounded-md hover:bg-yellow-400/90 transition-colors cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "+ Add Provider" ]
        ]
    , HH.div
        [ cls [ "space-y-4" ] ]
        [ providerCard "OpenAI" "sk-***...abc" "co-located" "4.2M tokens"
        , providerCard "Anthropic" "sk-ant-***...xyz" "co-located" "7.8M tokens"
        , providerCard "Together AI" "tok-***...def" "routing" "312k tokens"
        ]
    , HH.div
        [ cls [ "mt-8 p-4 bg-card border border-border rounded-lg" ] ]
        [ HH.h3 [ cls [ "text-sm font-medium text-text mb-2" ] ] [ HH.text "Co-location" ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text "Your BYOK keys are co-located with our CUTLASS kernels in the same region as your provider. Sub-millisecond network hops." ]
        ]
    ]

providerCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
providerCard name keyPreview status usage =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-3" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
            , HH.span
                [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-400/20 text-yellow-400" ] ]
                [ HH.text status ]
            ]
        , HH.button
            [ cls [ "text-sm text-muted-foreground hover:text-text cursor-pointer" ]
            , HP.type_ HP.ButtonButton
            ]
            [ HH.text "Edit" ]
        ]
    , HH.code
        [ cls [ "block text-sm font-mono text-muted-foreground mb-2" ] ]
        [ HH.text keyPreview ]
    , HH.p
        [ cls [ "text-xs text-muted-foreground" ] ]
        [ HH.text usage ]
    ]

-- ============================================================
-- ANALYTICS TAB
-- ============================================================

analyticsTab :: forall w i. HH.HTML w i
analyticsTab =
  HH.div_
    [ -- Metrics grid
      HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-6 mb-8" ] ]
        [ metricsCard "Token Throughput" "11.8k/s" "+18% vs last week"
        , metricsCard "p99 TTFT" "4.2ms" "2.1x faster than vLLM"
        ]
    
      -- GPU Metrics
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-8" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "GPU Utilization" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ breakdownRow "Compute" 94 "CUTLASS kernel active"
            , breakdownRow "Memory" 78 "PagedAttention KV cache"
            , breakdownRow "Tensor Core" 89 "sm_120 utilization"
            ]
        ]
    
      -- By model
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Tokens by Model" ]
        , HH.div
            [ cls [ "space-y-3" ] ]
            [ modelRow "gpt-4-turbo" 5842000 "47%"
            , modelRow "claude-3-opus" 4231000 "34%"
            , modelRow "llama-70b" 2327000 "19%"
            ]
        ]
    ]

metricsCard :: forall w i. String -> String -> String -> HH.HTML w i
metricsCard label value change =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-2" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-3xl font-bold text-text mb-1" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-sm text-green-400" ] ] [ HH.text change ]
    ]

breakdownRow :: forall w i. String -> Int -> String -> HH.HTML w i
breakdownRow label percentage note =
  HH.div_
    [ HH.div
        [ cls [ "flex items-center justify-between mb-1" ] ]
        [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text label ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text $ show percentage <> "%" ]
        ]
    , HH.div
        [ cls [ "h-2 bg-muted rounded-full overflow-hidden mb-1" ] ]
        [ HH.div
            [ cls [ "h-full bg-yellow-400 rounded-full" ]
            , HP.style $ "width: " <> show percentage <> "%"
            ]
            []
        ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text note ]
    ]

modelRow :: forall w i. String -> Int -> String -> HH.HTML w i
modelRow name tokens percentage =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text font-mono" ] ] [ HH.text name ]
    , HH.div
        [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text $ formatNumber tokens <> " tokens" ]
        , HH.span [ cls [ "text-sm text-yellow-400" ] ] [ HH.text percentage ]
        ]
    ]

formatNumber :: Int -> String
formatNumber n = show n -- TODO: add thousand separators

-- ============================================================
-- USAGE TAB
-- ============================================================

usageTab :: forall w i. HH.HTML w i
usageTab =
  HH.div_
    [ HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-6 mb-8" ] ]
        [ usageCard "Tokens" 12400000 50000000 "this month"
        , usageCard "Overage" 0 0 "no overage"
        ]
    
      -- Cost breakdown
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6 mb-8" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-4" ] ]
            [ HH.text "Cost Breakdown" ]
        , HH.div
            [ cls [ "space-y-4" ] ]
            [ costRow "omega//boost fee" "$12.40" "$0.001/1k tokens"
            , costRow "Estimated vs self-hosted" "$2,500/mo" "8x H100 equivalent"
            , costRow "Estimated vs raw APIs" "$186.00" "OpenAI + Anthropic direct"
            ]
        , HH.div
            [ cls [ "mt-6 pt-4 border-t border-border flex items-center justify-between" ] ]
            [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text "Savings vs alternatives" ]
            , HH.span [ cls [ "text-green-400 font-bold text-xl" ] ] [ HH.text "93%" ]
            ]
        ]
    
      -- Plan info
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Current Plan: Pro" ]
        , HH.p [ cls [ "text-muted-foreground mb-4" ] ] 
            [ HH.text "50M tokens/month included. $0.001/1k tokens after. CUTLASS kernels on H100." ]
        , HH.a
            [ HP.href "/omega/boost/settings"
            , cls [ "inline-block px-4 py-2 border border-border text-text text-sm font-medium rounded-md hover:bg-card transition-colors" ]
            ]
            [ HH.text "Manage Plan" ]
        ]
    ]

usageCard :: forall w i. String -> Int -> Int -> String -> HH.HTML w i
usageCard label current limit unit =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-4" ] ]
        [ HH.span [ cls [ "text-sm font-medium text-text" ] ] [ HH.text label ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] 
            [ HH.text $ formatNumber current <> " / " <> formatNumber limit <> " " <> unit ]
        ]
    , HH.div
        [ cls [ "h-2 bg-muted rounded-full overflow-hidden" ] ]
        [ HH.div
            [ cls [ "h-full bg-yellow-400 rounded-full" ]
            , HP.style $ "width: " <> show (if limit == 0 then 0 else (current * 100) / limit) <> "%"
            ]
            []
        ]
    ]

costRow :: forall w i. String -> String -> String -> HH.HTML w i
costRow label amount note =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text note ]
        ]
    , HH.span 
        [ cls [ "font-mono"
              , if (take 1 amount) == "-" then "text-green-400" else "text-text"
              ]
        ] 
        [ HH.text amount ]
    ]
  where
  take :: Int -> String -> String
  take _ "" = ""
  take n s = if n <= 0 then "" else s

-- ============================================================
-- HELPERS
-- ============================================================

codeBlock :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
codeBlock children =
  HH.pre
    [ cls [ "bg-background border border-border p-4 rounded-lg overflow-x-auto text-sm leading-relaxed" ] ]
    children

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prefix content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prefix ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
