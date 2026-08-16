-- | omega//proxy Features Page
-- | Complete feature showcase for the verified inference proxy
module Straylight.Pages.Products.OmegaProxy.Features 
  ( featuresPage
  , render
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

featuresPage :: forall q i o m. H.Component q i o m
featuresPage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall w i. HH.HTML w i
render =
  HH.div_
    [ hero
    , sseToSigil
    , resetOnAmbiguity
    , zeromqTransport
    , providerSupport
    , observability
    , cta
    ]

-- ============================================================
-- HERO
-- ============================================================

hero :: forall w i. HH.HTML w i
hero =
  HH.section
    [ cls [ "py-24 md:py-32" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6 text-center" ] ]
        [ HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Every feature,"
            , HH.br_
            , HH.text "verified"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "SSE to SIGIL translation. Reset-on-ambiguity. ZeroMQ transport. Provider-agnostic verified inference with cryptographic attestation." ]
        ]
    ]

-- ============================================================
-- SSE TO SIGIL
-- ============================================================

sseToSigil :: forall w i. HH.HTML w i
sseToSigil =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "SSE to SIGIL"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Stream directly to SIGIL" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Server-Sent Events from LLM providers are translated in real-time to SIGIL frames. No intermediate buffering. Each token is verified as it arrives, then immediately forwarded over ZeroMQ." ]
                , featureList
                    [ "Real-time token-by-token translation"
                    , "Zero-copy streaming pipeline"
                    , "SIGIL schema validation at the edge"
                    , "Backpressure-aware flow control"
                    , "Automatic reconnection on disconnect"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4 font-mono text-sm" ] ]
                    [ flowStep "1" "SSE Event" "data: {\"content\": \"Hello\"}"
                    , flowArrow
                    , flowStep "2" "SIGIL Frame" "(token :content \"Hello\" :verified true)"
                    , flowArrow
                    , flowStep "3" "ZeroMQ" "PUB tcp://*:5555"
                    ]
                ]
            ]
        ]
    ]

flowStep :: forall w i. String -> String -> String -> HH.HTML w i
flowStep num label content =
  HH.div
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-orange-400 font-bold" ] ] [ HH.text num ]
    , HH.div_
        [ HH.p [ cls [ "text-muted-foreground text-xs mb-1" ] ] [ HH.text label ]
        , HH.code [ cls [ "text-text" ] ] [ HH.text content ]
        ]
    ]

flowArrow :: forall w i. HH.HTML w i
flowArrow =
  HH.div [ cls [ "text-center text-muted-foreground" ] ] [ HH.text "|" ]

-- ============================================================
-- RESET ON AMBIGUITY
-- ============================================================

resetOnAmbiguity :: forall w i. HH.HTML w i
resetOnAmbiguity =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual (code)
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "# " "Ambiguous response detected"
                    , codeLine "" "[WARN] Token probability below threshold: 0.23"
                    , codeLine "" "[WARN] Multiple valid parse paths detected"
                    , HH.text "\n"
                    , codeLine "# " "Automatic state reset"
                    , codeLine "" "[INFO] Resetting context window"
                    , codeLine "" "[INFO] Re-prompting with disambiguation"
                    , HH.text "\n"
                    , codeLine "# " "Clean recovery"
                    , codeLine "" "[INFO] Response verified: confidence 0.97"
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Reset-on-Ambiguity"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "No corrupt context propagation" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "When the proxy detects ambiguous responses - low confidence tokens, multiple valid parses, or schema mismatches - it automatically resets state and re-prompts. Your agents never see corrupted data." ]
                , featureList
                    [ "Token probability monitoring"
                    , "Multi-path parse detection"
                    , "Automatic context window reset"
                    , "Configurable confidence thresholds"
                    , "Audit trail of all resets"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- ZEROMQ TRANSPORT
-- ============================================================

zeromqTransport :: forall w i. HH.HTML w i
zeromqTransport =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "ZeroMQ Transport"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "High-performance messaging" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "SIGIL frames are distributed over ZeroMQ for maximum throughput and minimum latency. PUB/SUB for broadcasts, REQ/REP for synchronous calls, PUSH/PULL for work distribution." ]
                , featureList
                    [ "Multiple socket patterns supported"
                    , "Sub-millisecond latency"
                    , "Automatic reconnection"
                    , "Message filtering by topic"
                    , "Cross-language bindings"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "grid grid-cols-3 gap-4 text-center" ] ]
                    [ socketPattern "PUB/SUB" "Broadcast"
                    , socketPattern "REQ/REP" "Sync"
                    , socketPattern "PUSH/PULL" "Workers"
                    ]
                ]
            ]
        ]
    ]

socketPattern :: forall w i. String -> String -> HH.HTML w i
socketPattern pattern label =
  HH.div
    [ cls [ "p-4 bg-background rounded-lg" ] ]
    [ HH.p [ cls [ "text-orange-400 font-mono font-bold mb-1" ] ] [ HH.text pattern ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text label ]
    ]

-- ============================================================
-- PROVIDER SUPPORT
-- ============================================================

providerSupport :: forall w i. HH.HTML w i
providerSupport =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Provider Support"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Every provider, one API" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Unified interface across all major providers. Hot-swap between them without changing your code." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ providerCard "OpenAI" "GPT-4, GPT-4o"
            , providerCard "Anthropic" "Claude 3.5"
            , providerCard "Google" "Gemini"
            , providerCard "Mistral" "Mistral Large"
            , providerCard "Meta" "Llama 3"
            , providerCard "Ollama" "Local models"
            , providerCard "Together" "Open models"
            , providerCard "Custom" "Your endpoint"
            ]
        ]
    ]

providerCard :: forall w i. String -> String -> HH.HTML w i
providerCard name models =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-orange-400/50 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text models ]
    ]

-- ============================================================
-- OBSERVABILITY
-- ============================================================

observability :: forall w i. HH.HTML w i
observability =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Observability"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Full visibility" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "OpenTelemetry traces, Prometheus metrics, structured logs. See exactly what your proxy is doing." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ obsCard "Tracing" "OpenTelemetry"
                "Distributed traces across the entire request path. Jaeger and Zipkin compatible."
            , obsCard "Metrics" "Prometheus"
                "Request latency, token counts, error rates. Pre-built Grafana dashboards."
            , obsCard "Logs" "Structured JSON"
                "Every request and response captured. ELK-ready formatting."
            ]
        ]
    ]

obsCard :: forall w i. String -> String -> String -> HH.HTML w i
obsCard title tech description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
        [ HH.div
            [ cls [ "flex items-center gap-2 mb-3" ] ]
            [ HH.h3 [ cls [ "text-text font-semibold" ] ] [ HH.text title ]
            , HH.span [ cls [ "text-xs px-2 py-0.5 bg-orange-400/20 text-orange-400 rounded" ] ] [ HH.text tech ]
        ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- CTA
-- ============================================================

cta :: forall w i. HH.HTML w i
cta =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6 text-center" ] ]
        [ HH.h2
            [ cls [ "text-3xl font-bold text-text mb-4" ] ]
            [ HH.text "Ready for verified inference?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Deploy omega//proxy today. Open source and free to self-host." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/omega/proxy/docs"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-orange-400 text-background font-medium rounded-md hover:bg-orange-400/90 transition-colors" ]
                ]
                [ HH.text "Get started" ]
            , HH.a
                [ HP.href "/omega/proxy/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
                ]
                [ HH.text "View pricing" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-orange-400/10 border border-orange-400/20 rounded-full text-orange-400 text-sm font-medium mb-4" ] ]
    [ HH.text label ]

featureList :: forall w i. Array String -> HH.HTML w i
featureList items =
  HH.ul
    [ cls [ "space-y-3" ] ]
    (map featureItem items)

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-orange-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
