-- | sensenet//forge Pricing Page
-- | Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design.
module Straylight.Pages.Products.SensenetForge.Pricing 
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
            [ HH.text "Simple, honest pricing" ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Free for open source. Pay only for what you use on private repos." ]
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
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
            [ pricingCard
                { name: "Free"
                , price: "$0"
                , period: "/month"
                , description: "Free forever for public repositories."
                , features:
                    [ "Unlimited public repos"
                    , "Unlimited collaborators"
                    , "Stacked diffs"
                    , "jujutsu native support"
                    , "Git compatibility"
                    , "Community support"
                    ]
                , cta: "Get started"
                , ctaHref: "/sensenet/forge/dashboard"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$19"
                , period: "/user/month"
                , description: "For teams shipping production software."
                , features:
                    [ "Everything in Free"
                    , "Unlimited private repos"
                    , "Agent attestation"
                    , "Semantic code search"
                    , "SSO/SAML"
                    , "Audit logs"
                    , "Priority email support"
                    , "API access"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/sensenet/forge/dashboard?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with compliance and self-hosting needs."
                , features:
                    [ "Everything in Pro"
                    , "Self-hosted deployment"
                    , "Air-gapped environments"
                    , "Custom agent policies"
                    , "Dedicated support"
                    , "Custom SLA"
                    , "Professional services"
                    , "Advanced security controls"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/sensenet/forge/legal"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: Stacked diffs, jujutsu native support, REST API, CLI access" ]
        ]
    ]

type PricingCardConfig =
  { name :: String
  , price :: String
  , period :: String
  , description :: String
  , features :: Array String
  , cta :: String
  , ctaHref :: String
  , highlighted :: Boolean
  }

pricingCard :: forall w i. PricingCardConfig -> HH.HTML w i
pricingCard config =
  HH.div
    [ cls [ "bg-card border rounded-lg p-6 flex flex-col"
          , if config.highlighted then "border-rose-400" else "border-border"
          ]
    ]
    [ -- Header
      HH.div
        [ cls [ "mb-4" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-1" ] ] [ HH.text config.name ]
        , HH.div
            [ cls [ "flex items-baseline gap-1" ] ]
            [ HH.span [ cls [ "text-3xl font-bold text-text" ] ] [ HH.text config.price ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text config.period ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground mt-2" ] ] [ HH.text config.description ]
        ]
      -- Features
    , HH.ul
        [ cls [ "space-y-2 mb-6 flex-1" ] ]
        (map featureItem config.features)
      -- CTA
    , HH.a
        [ HP.href config.ctaHref
        , cls [ "w-full py-2 text-center font-medium rounded-md transition-colors block"
              , if config.highlighted 
                  then "bg-rose-400 text-background hover:bg-rose-400/90"
                  else "border border-border text-text hover:bg-muted"
              ]
        ]
        [ HH.text config.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-rose-400" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
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
                "Can I use sensenet//forge with Git?"
                "Yes. While jujutsu is first-class, we provide full Git compatibility. Push from git, pull to git. Your team can migrate gradually."
            , faqItem
                "How does agent attestation work?"
                "When an AI agent creates a commit, forge captures the model, version, and prompt hash. This metadata is cryptographically signed and embedded in the commit. Reviewers see provenance at a glance."
            , faqItem
                "What's included in the free tier?"
                "Unlimited public repositories with unlimited collaborators. Stacked diffs, jujutsu support, and community support. Perfect for open source."
            , faqItem
                "Can I self-host?"
                "Enterprise customers can deploy forge on their own infrastructure, including air-gapped environments. Contact sales for details."
            , faqItem
                "How does semantic search work?"
                "We index your codebase with embedding models. When you search, we find code by meaning — 'functions that handle errors' finds try/catch, Result types, error callbacks, etc."
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
            [ HH.text "We work with enterprises on custom deployments, compliance requirements, and integrations. Let's talk." ]
        , HH.a
            [ HP.href "mailto:enterprise@sensenet.dev"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-rose-400 text-background font-medium rounded-md hover:bg-rose-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
