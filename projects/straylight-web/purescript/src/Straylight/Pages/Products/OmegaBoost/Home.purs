-- | omega//boost Home Page
-- | Managed inference co-located with BYOK vendor. Custom CUTLASS kernels.
module Straylight.Pages.Products.OmegaBoost.Home 
  ( homePage
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

homePage :: forall q i o m. H.Component q i o m
homePage = H.mkComponent
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
    , features
    , howItWorks
    , integration
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
        [ -- Badge
          HH.div
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-yellow-400/10 border border-yellow-400/20 rounded-full text-yellow-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-yellow-400 rounded-full animate-pulse" ] ] []
            , HH.text "Managed Inference"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Custom CUDA kernels,"
            , HH.br_
            , HH.span [ cls [ "text-yellow-400" ] ] [ HH.text "managed" ]
            , HH.text " for you"
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "CUTLASS 3.x sm_120 kernels co-located with your BYOK vendor. evring HTTP/1.1+2+3 stack. Replace self-hosted vLLM and raw provider APIs with our optimized infrastructure." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/boost/pricing" "View pricing"
            , secondaryButton "/omega/boost/docs" "Read the docs"
            ]
        , -- Key metrics
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-8" ] ]
            [ metricBadge "sm_120" "CUTLASS kernels"
            , metricBadge "BYOK" "co-located"
            , metricBadge "<5ms" "p99 TTFT"
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-yellow-400/60" ] ] [ HH.text "powered by " ]
            , HH.text "CUTLASS 3.x + evring"
            ]
        ]
    ]

metricBadge :: forall w i. String -> String -> HH.HTML w i
metricBadge value label =
  HH.div
    [ cls [ "flex items-baseline gap-2" ] ]
    [ HH.span [ cls [ "text-3xl font-bold text-yellow-400" ] ] [ HH.text value ]
    , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text label ]
    ]

-- ============================================================
-- FEATURES
-- ============================================================

features :: forall w i. HH.HTML w i
features =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Why omega//boost?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Custom CUDA kernels. Co-located infrastructure. Your keys, our performance." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "<<" "CUTLASS 3.x kernels"
                "Custom sm_120 CUDA kernels built on NVIDIA CUTLASS. Maximum throughput on H100/B200 GPUs. Faster than stock vLLM."
            , featureCard ">>" "Co-located with BYOK"
                "Your API keys, our infrastructure. We deploy in the same regions as your providers for sub-millisecond network hops."
            , featureCard "!!" "evring HTTP/1.1+2+3"
                "io_uring event loop with full HTTP/1.1, HTTP/2, and HTTP/3 support. 509k req/s per core. Zero-copy throughout."
            , featureCard "&&" "Replace self-hosted vLLM"
                "Stop managing GPU clusters. We handle scaling, failover, and optimization. Same API, better performance."
            , featureCard "==" "Intelligent batching"
                "Continuous batching with our custom kernels. Higher throughput than provider APIs without latency penalty."
            , featureCard "$" "Pay for what you use"
                "No idle GPU costs. No reserved capacity. Just inference at scale with transparent per-token pricing."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-yellow-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-yellow-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- HOW IT WORKS
-- ============================================================

howItWorks :: forall w i. HH.HTML w i
howItWorks =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "How it works" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Three steps to managed inference with custom kernels." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
            [ stepCard "01" "Connect your keys"
                "Add your OpenAI, Anthropic, or other provider API keys. We co-locate with your vendor for optimal routing."
            , stepCard "02" "Point to boost.omega.dev"
                "Replace your provider's base URL. Our CUTLASS kernels and evring stack handle the rest."
            , stepCard "03" "Scale without ops"
                "Auto-scaling, continuous batching, failover. No GPU clusters to manage. No vLLM configs to tune."
            ]
        ]
    ]

stepCard :: forall w i. String -> String -> String -> HH.HTML w i
stepCard step title description =
  HH.div
    [ cls [ "text-center" ] ]
    [ HH.div
        [ cls [ "text-5xl font-bold text-yellow-400/20 mb-4 font-mono" ] ]
        [ HH.text step ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- INTEGRATION
-- ============================================================

integration :: forall w i. HH.HTML w i
integration =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-12" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Drop-in replacement" ]
            ]
        , codeBlock
            [ codeLine "# " "Before: self-hosted vLLM or raw provider API"
            , codeLine "" "client = OpenAI(base_url=\"https://api.openai.com/v1\")"
            , HH.text "\n"
            , codeLine "# " "After: omega//boost with CUTLASS kernels"
            , codeLine "" "client = OpenAI(base_url=\"https://boost.omega.dev/v1\")"
            , HH.text "\n"
            , codeLine "# " "Same API. Custom kernels. Managed infrastructure."
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/omega/boost/docs"
                , cls [ "text-yellow-400 hover:text-yellow-400/80 transition-colors" ]
                ]
                [ HH.text "View full integration guide ->" ]
            ]
        ]
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
            [ HH.text "Custom CUTLASS kernels. BYOK co-location. No GPU ops. Start in minutes." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/boost/dashboard" "Get started"
            , secondaryButton "/omega/boost/pricing" "View pricing"
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

primaryButton :: forall w i. String -> String -> HH.HTML w i
primaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-yellow-400 text-background font-medium rounded-md hover:bg-yellow-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
