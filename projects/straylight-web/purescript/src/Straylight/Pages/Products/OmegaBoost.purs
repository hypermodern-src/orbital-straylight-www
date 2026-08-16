-- | omega//boost Product Page
-- | Managed Inference - Straylight-hosted LLM inference optimized for coding agents
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.OmegaBoost where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- COMPONENT
-- ============================================================

omegaBoostPage :: forall q i o m. H.Component q i o m
omegaBoostPage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER (armory shape)
-- ============================================================

render :: forall w i. HH.HTML w i
render =
  HH.div_
    [ hero
    , features
    , comparison
    , pricing
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-orange-400/10 border border-orange-400/20 rounded-full text-orange-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-orange-400 rounded-full animate-pulse" ] ] []
            , HH.text "Now available"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Managed inference"
            , HH.br_
            , HH.text "for coding "
            , HH.span [ cls [ "text-orange-400" ] ] [ HH.text "agents" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "No API keys. No rate limits. Batching, speculative decoding, KV cache. Built on evring's 509k req/s infrastructure. Pay per token, not per hour." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/signup" "Start for free"
            , secondaryButton "/docs/boost" "Read the docs"
            ]
        , -- Key metrics
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-8" ] ]
            [ metricBadge "509k" "req/s"
            , metricBadge "99.99%" "uptime SLA"
            , metricBadge "0" "rate limits"
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-orange-400/60" ] ] [ HH.text "integrated with " ]
            , HH.text "omega//code, omega//work, and your existing stack"
            ]
        ]
    ]

metricBadge :: forall w i. String -> String -> HH.HTML w i
metricBadge value label =
  HH.div
    [ cls [ "flex items-baseline gap-2" ] ]
    [ HH.span [ cls [ "text-3xl font-bold text-orange-400" ] ] [ HH.text value ]
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
                [ HH.text "Stop managing API keys, rate limits, and inference infrastructure. Focus on building." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "~" "Managed infrastructure"
                "No API keys to rotate. No rate limits to hit. No provider dashboards to juggle. We handle it all."
            , featureCard ">>" "Agent-optimized"
                "Batching, speculative decoding, KV cache sharing. Purpose-built for high-throughput coding agents."
            , featureCard "$" "Pay per token"
                "Zero idle costs. No reserved capacity. Scale to zero, scale to millions. True usage-based pricing."
            , featureCard "!!" "509k req/s"
                "Built on evring infrastructure. io_uring event loop. Linear multi-core scaling. Same backend as omega//code."
            , featureCard "&&" "Deep integrations"
                "Native support in omega//code and omega//work. One-line setup. Automatic model routing."
            , featureCard "==" "SLA guarantees"
                "99.99% uptime. Priority routing. Dedicated support. Enterprise-grade reliability."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-orange-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-orange-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- COMPARISON
-- ============================================================

comparison :: forall w i. HH.HTML w i
comparison =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Inference without the overhead" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others give you an API and wish you luck. We give you managed infrastructure optimized for agents." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-orange-400 font-bold" ] ] [ HH.text "omega//boost" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "OpenAI API" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Anthropic API" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "AWS Bedrock" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Together.ai" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "API key mgmt" "none needed" "manual" "manual" "IAM" "manual"
                    , comparisonRow "Rate limits" "unlimited" "tier-based" "tier-based" "per-model" "tier-based"
                    , comparisonRow "Batching" "automatic" "manual" "no" "no" "manual"
                    , comparisonRow "Speculative decode" "yes" "no" "no" "no" "some models"
                    , comparisonRow "KV cache sharing" "yes" "prompt cache" "prompt cache" "no" "no"
                    , comparisonRow "Agent integration" "native" "DIY" "DIY" "DIY" "DIY"
                    , comparisonRow "Uptime SLA" "99.99%" "99.9%" "no" "99.9%" "99.9%"
                    , comparisonRow "Priority routing" "yes" "no" "no" "no" "no"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on publicly available documentation as of February 2026." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us openai anthropic bedrock together =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-orange-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell openai ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell anthropic ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell bedrock ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell together ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ case value of
              "no" -> "text-muted-foreground/50"
              "DIY" -> "text-muted-foreground/50"
              _ -> "text-muted-foreground"
          ]
    ]
    [ HH.text value ]

-- ============================================================
-- PRICING
-- ============================================================

pricing :: forall w i. HH.HTML w i
pricing =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Simple, transparent pricing" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Pay for what you use. No surprises. No hidden fees." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ pricingCard
                { tier: "Free"
                , price: "$0"
                , period: "forever"
                , description: "Perfect for trying omega//boost"
                , features:
                    [ "100k tokens/month"
                    , "Community support"
                    , "Standard routing"
                    , "omega//code integration"
                    ]
                , cta: "Get started"
                , ctaHref: "/signup"
                , highlighted: false
                }
            , pricingCard
                { tier: "Pro"
                , price: "$29"
                , period: "/month"
                , description: "For serious developers and small teams"
                , features:
                    [ "10M tokens/month included"
                    , "$2/M tokens after"
                    , "Email support"
                    , "Priority routing"
                    , "99.9% uptime SLA"
                    ]
                , cta: "Start Pro trial"
                , ctaHref: "/signup?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { tier: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For teams that need more"
                , features:
                    [ "Unlimited tokens"
                    , "Volume discounts"
                    , "Dedicated support"
                    , "99.99% uptime SLA"
                    , "Custom integrations"
                    , "SOC 2 compliance"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/discord"
                , highlighted: false
                }
            ]
        ]
    ]

type PricingTier =
  { tier :: String
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
          , if t.highlighted then "border-orange-400" else "border-border"
          ]
    ]
    [ -- Tier badge
      HH.div
        [ cls [ "mb-4" ] ]
        [ HH.span
            [ cls [ "text-sm font-medium"
                  , if t.highlighted then "text-orange-400" else "text-muted-foreground"
                  ]
            ]
            [ HH.text t.tier ]
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
      if t.highlighted
        then primaryButton t.ctaHref t.cta
        else secondaryButton t.ctaHref t.cta
    ]

pricingFeature :: forall w i. String -> HH.HTML w i
pricingFeature feature =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-orange-400 mt-0.5" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text feature ]
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
            [ HH.text "Stop managing inference infrastructure" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "omega//boost handles the complexity so you can focus on building. Start free, scale infinitely." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/signup" "Start for free"
            , secondaryButton "/docs/boost" "Read the docs"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-orange-400 text-background font-medium rounded-md hover:bg-orange-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
