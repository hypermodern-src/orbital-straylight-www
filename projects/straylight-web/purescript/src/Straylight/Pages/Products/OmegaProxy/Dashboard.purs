-- | omega//proxy Dashboard Page
module Straylight.Pages.Products.OmegaProxy.Dashboard where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

dashboardPage :: forall q i o m. H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const { activeTab: "overview" }
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
    [ header, tabs state, content state ]

header :: forall w i. HH.HTML w i
header =
  HH.div
    [ cls [ "mb-8" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-2" ] ]
        [ HH.h1 [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "omega//proxy Dashboard" ]
        , HH.span [ cls [ "px-2 py-0.5 bg-orange-400/10 text-orange-400 text-xs rounded-full" ] ] [ HH.text "Verified" ]
        ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Request metrics, compression ratios, and provider health." ]
    ]

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state =
  HH.div
    [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton state "overview" "Overview"
    , tabButton state "requests" "Requests"
    , tabButton state "compression" "Compression"
    , tabButton state "providers" "Providers"
    , tabButton state "resets" "Resets"
    ]

tabButton :: forall m. State -> String -> String -> H.ComponentHTML Action () m
tabButton state value label =
  HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px cursor-pointer"
          , if state.activeTab == value 
              then "text-orange-400 border-b-2 border-orange-400" 
              else "text-muted-foreground hover:text-text"
          ]
    , HP.type_ HP.ButtonButton
    ]
    [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "requests" -> requestsTab
  "compression" -> compressionTab
  "providers" -> providersTab
  "resets" -> resetsTab
  _ -> overviewTab

overviewTab :: forall w i. HH.HTML w i
overviewTab =
  HH.div_
    [ HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Requests Today" "12,847" "↑ 8% from yesterday"
        , statCard "Compression Ratio" "4.2x" "Avg wire savings"
        , statCard "Provider Health" "100%" "All providers up"
        , statCard "Ambiguity Resets" "3" "Last 24 hours"
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-6" ] ]
        [ -- Request metrics
          HH.div
            [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Request Metrics" ]
            , HH.div [ cls [ "space-y-3" ] ]
                [ metricRow "Total requests (24h)" "12,847"
                , metricRow "Verified responses" "12,844 (99.98%)"
                , metricRow "Tool calls repaired" "23"
                , metricRow "Avg latency" "23ms (p99: 89ms)"
                ]
            ]
          -- Compression stats
        , HH.div
            [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Wire Compression" ]
            , HH.div [ cls [ "space-y-3" ] ]
                [ metricRow "Bytes received (SSE)" "847.2 MB"
                , metricRow "Bytes sent (SIGIL)" "201.7 MB"
                , metricRow "Compression ratio" "4.2x"
                , metricRow "Bandwidth saved" "645.5 MB"
                ]
            ]
        ]
    ]

requestsTab :: forall w i. HH.HTML w i
requestsTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Request History" ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ requestRow "gpt-4o" "chat.completions" "verified" "23ms" "2 min ago"
        , requestRow "claude-3-5-sonnet" "chat.completions" "verified" "45ms" "5 min ago"
        , requestRow "gpt-4" "tool.call" "repaired" "67ms" "8 min ago"
        , requestRow "claude-3-5-sonnet" "chat.completions" "verified" "38ms" "12 min ago"
        ]
    ]

requestRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
requestRow model endpoint status latency time =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-text font-mono text-sm" ] ] [ HH.text model ]
        , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text endpoint ]
        ]
    , HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span 
            [ cls [ "text-xs px-2 py-0.5 rounded"
                  , if status == "verified" then "bg-green-400/10 text-green-400" else "bg-orange-400/10 text-orange-400"
                  ] 
            ] 
            [ HH.text status ]
        , HH.span [ cls [ "text-muted-foreground text-sm w-16 text-right" ] ] [ HH.text latency ]
        , HH.span [ cls [ "text-muted-foreground text-xs w-20 text-right" ] ] [ HH.text time ]
        ]
    ]

compressionTab :: forall w i. HH.HTML w i
compressionTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Compression Analytics" ]
    , HH.div [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6 mb-6" ] ]
        [ compressionStat "Today" "4.2x" "645 MB saved"
        , compressionStat "This Week" "3.8x" "4.2 GB saved"
        , compressionStat "This Month" "4.1x" "18.7 GB saved"
        ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] 
        [ HH.text "SIGIL protocol achieves 200-600% compression by optimizing token representation and eliminating SSE overhead." ]
    ]

compressionStat :: forall w i. String -> String -> String -> HH.HTML w i
compressionStat period ratio saved =
  HH.div
    [ cls [ "text-center p-4 bg-background rounded-lg" ] ]
    [ HH.p [ cls [ "text-muted-foreground text-sm mb-1" ] ] [ HH.text period ]
    , HH.p [ cls [ "text-2xl font-bold text-orange-400" ] ] [ HH.text ratio ]
    , HH.p [ cls [ "text-muted-foreground text-xs" ] ] [ HH.text saved ]
    ]

providersTab :: forall w i. HH.HTML w i
providersTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Provider Health" ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ providerRow "OpenAI" "healthy" "23ms" "5,432"
        , providerRow "Anthropic" "healthy" "45ms" "4,891"
        , providerRow "Google" "healthy" "67ms" "1,203"
        , providerRow "Ollama (local)" "healthy" "12ms" "1,321"
        ]
    ]

providerRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
providerRow name status latency requests =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "w-2 h-2 rounded-full bg-green-400" ] ] []
        , HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        ]
    , HH.div [ cls [ "flex items-center gap-6 text-sm" ] ]
        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text (latency <> " avg") ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text (requests <> " reqs") ]
        ]
    ]

resetsTab :: forall w i. HH.HTML w i
resetsTab =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text "Reset-on-Ambiguity Events" ]
    , HH.p [ cls [ "text-muted-foreground text-sm mb-6" ] ] 
        [ HH.text "Automatic context resets triggered when response confidence drops below threshold." ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ resetRow "Low confidence" "0.23" "gpt-4" "2 hours ago"
        , resetRow "Multiple parse paths" "0.31" "claude-3-5-sonnet" "6 hours ago"
        , resetRow "Schema mismatch" "0.28" "gpt-4o" "18 hours ago"
        ]
    ]

resetRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
resetRow reason confidence model time =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text reason ]
        , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text model ]
        ]
    , HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-orange-400 font-mono text-sm" ] ] [ HH.text confidence ]
        , HH.span [ cls [ "text-muted-foreground text-xs" ] ] [ HH.text time ]
        ]
    ]

metricRow :: forall w i. String -> String -> HH.HTML w i
metricRow label value =
  HH.div
    [ cls [ "flex items-center justify-between" ] ]
    [ HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text label ]
    , HH.span [ cls [ "text-text font-medium" ] ] [ HH.text value ]
    ]

statCard :: forall w i. String -> String -> String -> HH.HTML w i
statCard label value subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text subtitle ]
    ]
