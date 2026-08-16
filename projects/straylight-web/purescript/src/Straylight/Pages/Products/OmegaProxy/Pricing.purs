-- | omega//proxy Pricing Page
module Straylight.Pages.Products.OmegaProxy.Pricing 
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
            [ HH.text "Simple, transparent pricing" ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Self-host for free. Use managed hosting for convenience. Pay only for what you use." ]
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
                , period: "/forever"
                , description: "Self-host omega//proxy on your infrastructure."
                , features:
                    [ "Unlimited requests"
                    , "All features included"
                    , "SSE to SIGIL translation"
                    , "Reset-on-ambiguity"
                    , "Docker & Nix deployment"
                    , "Community support"
                    ]
                , cta: "View source"
                , ctaHref: "https://github.com/straylight-software/omega-proxy"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$79"
                , period: "/month"
                , description: "Managed hosting with high throughput."
                , features:
                    [ "25M requests/month"
                    , "500GB bandwidth/month"
                    , "200-600% wire compression"
                    , "99.9% uptime SLA"
                    , "Provider health monitoring"
                    , "Priority support"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/omega/proxy/dashboard"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "Unlimited scale with compliance."
                , features:
                    [ "Unlimited requests"
                    , "Unlimited bandwidth"
                    , "Dedicated ZeroMQ clusters"
                    , "Custom verification rules"
                    , "SSO/SAML integration"
                    , "On-premise deployment"
                    ]
                , cta: "Contact sales"
                , ctaHref: "mailto:enterprise@straylight.software"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: SSE to SIGIL, reset-on-ambiguity, ZeroMQ transport, verified inference" ]
        ]
    ]

type PricingCardProps =
  { name :: String
  , price :: String
  , period :: String
  , description :: String
  , features :: Array String
  , cta :: String
  , ctaHref :: String
  , highlighted :: Boolean
  }

pricingCard :: forall w i. PricingCardProps -> HH.HTML w i
pricingCard props =
  HH.div
    [ cls [ "bg-card border rounded-lg p-6"
          , if props.highlighted then "border-orange-400" else "border-border"
          ]
    ]
    [ if props.highlighted
        then HH.div
          [ cls [ "text-xs text-orange-400 font-medium mb-4" ] ]
          [ HH.text "MOST POPULAR" ]
        else HH.text ""
    , HH.h3
        [ cls [ "text-xl font-bold text-text mb-2" ] ]
        [ HH.text props.name ]
    , HH.div
        [ cls [ "flex items-baseline gap-1 mb-4" ] ]
        [ HH.span [ cls [ "text-3xl font-bold text-text" ] ] [ HH.text props.price ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text props.period ]
        ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm mb-6" ] ]
        [ HH.text props.description ]
    , HH.ul
        [ cls [ "space-y-3 mb-8" ] ]
        (map featureItem props.features)
    , HH.a
        [ HP.href props.ctaHref
        , cls [ "block w-full py-3 text-center font-medium rounded-md transition-colors"
              , if props.highlighted 
                  then "bg-orange-400 text-background hover:bg-orange-400/90"
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text props.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text text ]
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
                "What's included in self-hosted?"
                "Everything. The full source code with all features: SSE to SIGIL translation, reset-on-ambiguity, ZeroMQ transport, verified inference, all provider integrations. MIT licensed, no strings attached."
            , faqItem
                "How does managed hosting work?"
                "We run omega//proxy for you on dedicated infrastructure. You get an endpoint URL, configure your agents to use it, and we handle scaling, uptime, and maintenance."
            , faqItem
                "What happens if I exceed my request limit?"
                "You'll get a notification at 80% usage. If you exceed the limit, we'll work with you on a custom plan. We don't cut you off mid-request."
            , faqItem
                "Can I migrate between plans?"
                "Yes. Move from self-hosted to managed (or vice versa) anytime. Your configuration exports cleanly between environments."
            , faqItem
                "Is verified inference available on all plans?"
                "Yes. Cryptographic attestation is a core feature, not a premium add-on. Every request through omega//proxy is verified."
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
            [ HH.text "Need something custom?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "We work with enterprises on custom deployments, SLAs, and integrations. Let's talk." ]
        , HH.a
            [ HP.href "mailto:enterprise@straylight.software"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-orange-400 text-background font-medium rounded-md hover:bg-orange-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
