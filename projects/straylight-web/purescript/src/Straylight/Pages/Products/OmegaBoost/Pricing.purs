-- | omega//boost Pricing Page
-- | Transparent pricing for managed inference with custom kernels
module Straylight.Pages.Products.OmegaBoost.Pricing 
  ( pricingPage
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

pricingPage :: forall q i o m. H.Component q i o m
pricingPage = H.mkComponent
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
    , plans
    , calculator
    , faq
    , enterprise
    ]

-- ============================================================
-- HERO
-- ============================================================

hero :: forall w i. HH.HTML w i
hero =
  HH.section
    [ cls [ "py-24" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6 text-center" ] ]
        [ HH.h1
            [ cls [ "text-4xl md:text-5xl font-bold text-text mb-6" ] ]
            [ HH.text "Pay per token, not per GPU" ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Custom CUTLASS kernels. BYOK co-location. No idle GPU costs. Transparent per-token pricing." ]
        ]
    ]

-- ============================================================
-- PLANS
-- ============================================================

plans :: forall w i. HH.HTML w i
plans =
  HH.section
    [ cls [ "pb-24" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ pricingCard
                { name: "Starter"
                , price: "$0"
                , period: "/month"
                , description: "Try managed inference"
                , features:
                    [ "1M tokens/month included"
                    , "$0.002/1k tokens after"
                    , "2 BYOK provider slots"
                    , "Basic latency metrics"
                    , "Community support"
                    ]
                , cta: "Get started"
                , ctaHref: "/omega/boost/dashboard"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$99"
                , period: "/month"
                , description: "For production workloads"
                , features:
                    [ "50M tokens/month included"
                    , "$0.001/1k tokens after"
                    , "Unlimited BYOK providers"
                    , "Full GPU/latency metrics"
                    , "Priority kernel scheduling"
                    , "Email support"
                    , "99.9% uptime SLA"
                    ]
                , cta: "Start Pro trial"
                , ctaHref: "/omega/boost/dashboard?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "Dedicated inference capacity"
                , features:
                    [ "Reserved GPU capacity"
                    , "Volume token discounts"
                    , "Dedicated kernel instances"
                    , "99.99% uptime SLA"
                    , "Custom model deployment"
                    , "SOC 2 Type II"
                    , "On-prem CUTLASS option"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/discord"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: CUTLASS 3.x kernels, BYOK co-location, evring HTTP stack, continuous batching" ]
        ]
    ]

type PricingTier =
  { name :: String
  , price :: String
  , period :: String
  , description :: String
  , features :: Array String
  , cta :: String
  , ctaHref :: String
  , highlighted :: Boolean
  }

pricingCard :: forall w i. PricingTier -> HH.HTML w i
pricingCard t =
  HH.div
    [ cls [ "p-6 bg-card border rounded-lg flex flex-col"
          , if t.highlighted then "border-yellow-400" else "border-border"
          ]
    ]
    [ -- Tier badge
      HH.div
        [ cls [ "mb-4" ] ]
        [ HH.span
            [ cls [ "text-sm font-medium"
                  , if t.highlighted then "text-yellow-400" else "text-muted-foreground"
                  ]
            ]
            [ HH.text t.name ]
        ]
    , -- Price
      HH.div
        [ cls [ "mb-4" ] ]
        [ HH.span [ cls [ "text-4xl font-bold text-text" ] ] [ HH.text t.price ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text t.period ]
        ]
    , -- Description
      HH.p
        [ cls [ "text-muted-foreground text-sm mb-6" ] ]
        [ HH.text t.description ]
    , -- Features
      HH.ul
        [ cls [ "space-y-3 mb-8 flex-grow" ] ]
        (map pricingFeature t.features)
    , -- CTA
      HH.a
        [ HP.href t.ctaHref
        , cls [ "inline-flex items-center justify-center px-6 py-3 font-medium rounded-md transition-colors text-center"
              , if t.highlighted 
                  then "bg-yellow-400 text-background hover:bg-yellow-400/90"
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text t.cta ]
    ]

pricingFeature :: forall w i. String -> HH.HTML w i
pricingFeature feature =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-yellow-400 mt-0.5" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text feature ]
    ]

-- ============================================================
-- CALCULATOR
-- ============================================================

calculator :: forall w i. HH.HTML w i
calculator =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6" ] ]
        [ HH.h2
            [ cls [ "text-2xl font-bold text-text mb-8 text-center" ] ]
            [ HH.text "Cost comparison" ]
        , HH.div
            [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
            [ HH.div
                [ cls [ "space-y-4" ] ]
                [ costRow "Self-hosted vLLM (8x H100)" "Reserved GPU + ops overhead" "$25,000/mo"
                , costRow "Raw provider APIs" "OpenAI/Anthropic direct" "$0.015/1k tokens"
                , costRow "omega//boost" "Custom kernels, BYOK co-location" "$0.001/1k tokens"
                ]
            , HH.div
                [ cls [ "mt-6 pt-6 border-t border-border" ] ]
                [ HH.div
                    [ cls [ "flex justify-between items-center" ] ]
                    [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text "Typical savings" ]
                    , HH.span [ cls [ "text-green-400 font-bold" ] ] [ HH.text "60-80% vs alternatives" ]
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-4" ] ]
            [ HH.text "No idle GPU costs. No ops overhead. Pay only for tokens processed." ]
        ]
    ]

costRow :: forall w i. String -> String -> String -> HH.HTML w i
costRow label description amount =
  HH.div
    [ cls [ "flex items-center justify-between" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.span [ cls [ "text-text font-mono" ] ] [ HH.text amount ]
    ]

-- ============================================================
-- FAQ
-- ============================================================

faq :: forall w i. HH.HTML w i
faq =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6" ] ]
        [ HH.h2
            [ cls [ "text-2xl font-bold text-text mb-12 text-center" ] ]
            [ HH.text "Frequently asked questions" ]
        , HH.div
            [ cls [ "space-y-8" ] ]
            [ faqItem 
                "How does BYOK pricing work?"
                "You bring your own API keys and continue paying your providers (OpenAI, Anthropic, etc.) directly. omega//boost charges only for our infrastructure - the custom kernels, co-location, and HTTP stack that optimize your inference."
            , faqItem
                "What are CUTLASS kernels?"
                "CUTLASS is NVIDIA's library for high-performance CUDA kernels. We build custom sm_120 kernels targeting H100/B200 GPUs that outperform stock vLLM by 40-60% on attention and GEMM operations."
            , faqItem
                "How does this compare to self-hosted vLLM?"
                "Self-hosted vLLM requires reserved GPU capacity (expensive), ops overhead (time-consuming), and manual tuning (complex). omega//boost gives you better performance with custom kernels, no ops burden, and pay-per-token pricing."
            , faqItem
                "Can I switch plans anytime?"
                "Yes. Upgrade or downgrade at any time. Changes take effect immediately. We prorate refunds for downgrades."
            , faqItem
                "What if I exceed my token limit?"
                "On Starter, you're billed $0.002/1k tokens over the limit. On Pro, it's $0.001/1k tokens. We notify you at 80% usage and before any overage charges."
            ]
        ]
    ]

faqItem :: forall w i. String -> String -> HH.HTML w i
faqItem question answer =
  HH.div_
    [ HH.h3
        [ cls [ "text-text font-medium mb-2" ] ]
        [ HH.text question ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text answer ]
    ]

-- ============================================================
-- ENTERPRISE
-- ============================================================

enterprise :: forall w i. HH.HTML w i
enterprise =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6 text-center" ] ]
        [ HH.h2
            [ cls [ "text-2xl font-bold text-text mb-4" ] ]
            [ HH.text "Need dedicated GPU capacity?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Reserved H100/B200 instances, custom model deployment, on-prem CUTLASS kernels. Let's talk." ]
        , HH.a
            [ HP.href "mailto:sales@straylight.dev"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-yellow-400 text-background font-medium rounded-md hover:bg-yellow-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
