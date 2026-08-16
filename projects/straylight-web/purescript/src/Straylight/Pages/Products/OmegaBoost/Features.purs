-- | omega//boost Features Page
-- | Complete feature showcase for managed inference with custom CUTLASS kernels
module Straylight.Pages.Products.OmegaBoost.Features 
  ( featuresPage
  , render
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

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
    , cutlassKernels
    , byokArchitecture
    , evringStack
    , batching
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
            [ HH.text "Custom kernels,"
            , HH.br_
            , HH.text "managed infrastructure"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "CUTLASS 3.x sm_120 kernels. evring HTTP/1.1+2+3 stack. BYOK co-location. Auto-scaling. Replace self-hosted vLLM." ]
        ]
    ]

-- ============================================================
-- CUTLASS KERNELS
-- ============================================================

cutlassKernels :: forall w i. HH.HTML w i
cutlassKernels =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "CUTLASS 3.x Kernels"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Custom sm_120 CUDA kernels" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "We build custom inference kernels on NVIDIA's CUTLASS 3.x library, targeting sm_120 architecture (H100, B200). Our kernels outperform stock vLLM by 40-60% on attention and GEMM operations." ]
                , featureList
                    [ "Optimized for H100/B200 Tensor Cores"
                    , "Custom attention kernels with FlashAttention-3"
                    , "Fused MoE kernels for Mixtral/DBRX"
                    , "Async copy and warp-specialized pipelines"
                    , "Continuous batching with PagedAttention"
                    ]
                ]
            , -- Right: visual
              HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ kernelMetric "Attention" "2.1x" "vs stock vLLM"
                    , kernelMetric "GEMM" "1.8x" "vs cuBLAS"
                    , kernelMetric "TTFT" "<5ms" "p99 latency"
                    , kernelMetric "Throughput" "12k" "tok/s/GPU"
                    ]
                , HH.p
                    [ cls [ "text-sm text-muted-foreground mt-6 text-center" ] ]
                    [ HH.text "Benchmarked on H100 SXM5 80GB" ]
                ]
            ]
        ]
    ]

kernelMetric :: forall w i. String -> String -> String -> HH.HTML w i
kernelMetric label value note =
  HH.div
    [ cls [ "flex items-center justify-between p-3 bg-background rounded-md" ] ]
    [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text label ]
    , HH.div
        [ cls [ "flex items-center gap-2" ] ]
        [ HH.span [ cls [ "text-yellow-400 font-bold font-mono" ] ] [ HH.text value ]
        , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text note ]
        ]
    ]

-- ============================================================
-- BYOK ARCHITECTURE
-- ============================================================

byokArchitecture :: forall w i. HH.HTML w i
byokArchitecture =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1 bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ vendorRow "OpenAI" "sk-***...abc" "co-located"
                    , vendorRow "Anthropic" "sk-ant-***...xyz" "co-located"
                    , vendorRow "Google" "AIza***...def" "routing"
                    ]
                , HH.p
                    [ cls [ "text-sm text-muted-foreground mt-6 text-center" ] ]
                    [ HH.text "Your keys, our optimized infrastructure" ]
                ]
            , -- Right: content
              HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "BYOK Co-location"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Your keys, our kernels" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Bring your existing API keys. We co-locate our CUTLASS-optimized inference in the same regions as your providers, routing requests through our custom kernels for maximum performance with minimal latency." ]
                , featureList
                    [ "Sub-millisecond network hops to providers"
                    , "Encrypted key storage with AES-256-GCM"
                    , "Automatic failover between regions"
                    , "Per-provider routing optimization"
                    , "Keep your existing billing relationships"
                    ]
                ]
            ]
        ]
    ]

vendorRow :: forall w i. String -> String -> String -> HH.HTML w i
vendorRow vendor key status =
  HH.div
    [ cls [ "flex items-center justify-between p-3 bg-background rounded-md" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text vendor ]
        , HH.code [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text key ]
        ]
    , HH.span
        [ cls [ "text-xs px-2 py-0.5 rounded bg-yellow-400/20 text-yellow-400" ] ]
        [ HH.text status ]
    ]

-- ============================================================
-- EVRING STACK
-- ============================================================

evringStack :: forall w i. HH.HTML w i
evringStack =
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
                    [ codeLine "// " "evring HTTP/1.1+2+3 stack"
                    , codeLine "" "io_uring event loop"
                    , codeLine "" "zero-copy buffers"
                    , codeLine "" "HTTP/3 QUIC support"
                    , HH.text "\n"
                    , codeLine "// " "Performance"
                    , codeLine "" "509,000 req/s per core"
                    , codeLine "" "< 5ms p99 TTFT"
                    , codeLine "" "99.99% uptime SLA"
                    ]
                ]
            , -- Right: content
              HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "evring HTTP/1.1+2+3"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Full HTTP stack, zero overhead" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "omega//boost runs on evring, our custom HTTP stack with full HTTP/1.1, HTTP/2, and HTTP/3 (QUIC) support. io_uring event loop, zero-copy buffers, and linear multi-core scaling." ]
                , featureList
                    [ "HTTP/1.1 + HTTP/2 multiplexing + HTTP/3 QUIC"
                    , "io_uring for async I/O without syscall overhead"
                    , "Zero-copy SSE streaming for token delivery"
                    , "509k req/s per core, linear multi-core scaling"
                    , "Global anycast with automatic failover"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- BATCHING
-- ============================================================

batching :: forall w i. HH.HTML w i
batching =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Continuous Batching"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Auto-scaling with custom kernels" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Our CUTLASS kernels implement continuous batching with PagedAttention. Dynamic request scheduling maximizes GPU utilization while maintaining low latency. No vLLM tuning required." ]
                , featureList
                    [ "Continuous batching with PagedAttention"
                    , "Dynamic request scheduling per-iteration"
                    , "Auto-scaling based on queue depth"
                    , "Priority queues for latency-sensitive requests"
                    , "Zero-downtime scaling events"
                    ]
                ]
            , -- Right: visual
              HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-3" ] ]
                    [ batchVisual "Batch 1" 85 "12 reqs"
                    , batchVisual "Batch 2" 92 "14 reqs"
                    , batchVisual "Batch 3" 78 "11 reqs"
                    ]
                , HH.div
                    [ cls [ "mt-4 pt-4 border-t border-border text-center" ] ]
                    [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "GPU utilization: " ]
                    , HH.span [ cls [ "text-sm text-yellow-400 ml-1" ] ] [ HH.text "94%" ]
                    ]
                ]
            ]
        ]
    ]

batchVisual :: forall w i. String -> Int -> String -> HH.HTML w i
batchVisual label size status =
  HH.div
    [ cls [ "flex items-center gap-3" ] ]
    [ HH.div
        [ cls [ "flex-1 h-8 bg-background rounded overflow-hidden" ] ]
        [ HH.div
            [ cls [ "h-full bg-yellow-400/30 rounded" ]
            , HP.style $ "width: " <> show size <> "%"
            ]
            []
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground w-20" ] ] [ HH.text label ]
    , HH.span [ cls [ "text-xs text-green-400" ] ] [ HH.text status ]
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
                [ HH.text "Full visibility into inference" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Real-time GPU metrics, latency percentiles, throughput analytics. Monitor your inference like production infrastructure." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" ] ]
            [ observabilityCard "<<" "GPU metrics" "Utilization, memory, kernel timing"
            , observabilityCard "$" "Cost analytics" "Per-token and aggregate cost tracking"
            , observabilityCard "!" "Latency percentiles" "TTFT, TBT, p50/p95/p99"
            , observabilityCard "=" "Throughput" "Tokens/sec, requests/sec, batching efficiency"
            ]
        ]
    ]

observabilityCard :: forall w i. String -> String -> String -> HH.HTML w i
observabilityCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-yellow-400/30 transition-colors" ] ]
    [ HH.div [ cls [ "text-2xl text-yellow-400 mb-3 font-mono" ] ] [ HH.text icon ]
    , HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text description ]
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
            [ HH.text "Ready for managed inference?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Custom CUTLASS kernels. BYOK co-location. Replace vLLM. Start in minutes." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/omega/boost/dashboard"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-yellow-400 text-background font-medium rounded-md hover:bg-yellow-400/90 transition-colors" ]
                ]
                [ HH.text "Get started" ]
            , HH.a
                [ HP.href "/omega/boost/docs"
                , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
                ]
                [ HH.text "Read the docs" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-yellow-400/10 border border-yellow-400/20 rounded-full text-yellow-400 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-yellow-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeBlock :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
codeBlock children =
  HH.pre
    [ cls [ "bg-card border border-border p-4 rounded-lg overflow-x-auto text-sm leading-relaxed" ] ]
    children

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prefix content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prefix ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
