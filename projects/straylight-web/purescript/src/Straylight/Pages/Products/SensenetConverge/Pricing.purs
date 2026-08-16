-- | sensenet//converge Pricing Page
module Straylight.Pages.Products.SensenetConverge.Pricing 
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
            [ HH.text "Pay for resources managed. No hidden fees. No surprise bills. Cancel anytime." ]
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
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" ] ]
            [ pricingCard
                { name: "Free"
                , price: "$0"
                , period: "/month"
                , description: "For personal projects and experiments."
                , features:
                    [ "10 managed resources"
                    , "1 environment"
                    , "Drift detection"
                    , "Community support"
                    , "7-day history"
                    ]
                , cta: "Get started"
                , ctaHref: "/signup?product=converge"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$49"
                , period: "/month"
                , description: "For individual developers and small projects."
                , features:
                    [ "100 managed resources"
                    , "5 environments"
                    , "Real-time drift alerts"
                    , "Email support"
                    , "30-day history"
                    , "Slack integration"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/signup?product=converge&plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Team"
                , price: "$199"
                , period: "/month"
                , description: "For teams managing production infrastructure."
                , features:
                    [ "500 managed resources"
                    , "Unlimited environments"
                    , "Auto-remediation"
                    , "Priority support"
                    , "90-day history"
                    , "SSO/SAML"
                    , "Audit logs"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/signup?product=converge&plan=team"
                , highlighted: false
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with compliance needs."
                , features:
                    [ "Unlimited resources"
                    , "Unlimited environments"
                    , "Dedicated support"
                    , "SLA guarantee"
                    , "Self-hosted option"
                    , "Custom integrations"
                    , "Policy-as-code"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/discord"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: Type system, multi-cloud support, CLI, REST API, Git integration" ]
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
          , if props.highlighted then "border-purple-400" else "border-border"
          ]
    ]
    [ -- Header
      HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text props.name ]
        , HH.div
            [ cls [ "flex items-baseline gap-1" ] ]
            [ HH.span [ cls [ "text-3xl font-bold text-text" ] ] [ HH.text props.price ]
            , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text props.period ]
            ]
        , HH.p [ cls [ "text-sm text-muted-foreground mt-2" ] ] [ HH.text props.description ]
        ]
    -- Features
    , HH.ul
        [ cls [ "space-y-3 mb-6" ] ]
        (map featureItem props.features)
    -- CTA
    , HH.a
        [ HP.href props.ctaHref
        , cls [ "block w-full py-3 text-center font-medium rounded-md transition-colors"
              , if props.highlighted 
                  then "bg-purple-400 text-background hover:bg-purple-400/90" 
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text props.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "+" ]
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
                "What counts as a managed resource?"
                "Any infrastructure resource managed by converge: EC2 instances, S3 buckets, RDS databases, Kubernetes deployments, etc. Data sources and computed values don't count."
            , faqItem
                "Can I migrate from Terraform?"
                "Yes. Our CLI includes an import command that reads your Terraform state and generates converge configs. Zero downtime migration."
            , faqItem
                "What happens if I exceed my resource limit?"
                "We don't cut you off. You'll get a notification and we'll work with you to upgrade or optimize. No surprise bills."
            , faqItem
                "Is convergence safe for production?"
                "Yes. Converge uses transactions and rollback for multi-resource changes. You can also configure manual approval for specific resources."
            , faqItem
                "Do you support self-hosted deployment?"
                "Enterprise plans include a self-hosted option. Run converge entirely within your VPC."
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
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-purple-400 text-background font-medium rounded-md hover:bg-purple-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
