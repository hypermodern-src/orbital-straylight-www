-- | sensenet//confirm Pricing Page
-- | CI with proof obligations - pricing plans
module Straylight.Pages.Products.SensenetConfirm.Pricing 
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
            [ HH.text "Pay for what you use. No hidden fees. No surprise bills. Cancel anytime." ]
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
                , description: "For open source and personal projects."
                , features:
                    [ "Unlimited public repos"
                    , "2,000 build minutes/month"
                    , "10 proof verifications/day"
                    , "Basic agent code detection"
                    , "Dhall pipelines"
                    , "Community support"
                    , "Build attestation (SHA-256)"
                    ]
                , cta: "Get started free"
                , ctaHref: "/sensenet/confirm/signup"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$49"
                , period: "/seat/month"
                , description: "For teams with proof obligations."
                , features:
                    [ "Unlimited private repos"
                    , "10,000 build minutes/month"
                    , "Unlimited proof verifications"
                    , "Full agent code review"
                    , "Custom proof obligations"
                    , "Post-quantum attestation"
                    , "Priority email support"
                    , "Audit logs"
                    ]
                , cta: "Start 14-day trial"
                , ctaHref: "/sensenet/confirm/signup?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with compliance needs."
                , features:
                    [ "Everything in Pro"
                    , "Unlimited build minutes"
                    , "Unlimited seats"
                    , "Self-hosted deployment"
                    , "SSO/SAML/SCIM"
                    , "Dedicated support + SLA"
                    , "Custom integrations"
                    , "Formal verification tools"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/sensenet/confirm/contact"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: Typed Dhall pipelines, Nix integration, REST API, GitHub/GitLab integration" ]
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
          , if config.highlighted then "border-amber-400" else "border-border"
          ]
    ]
    [ if config.highlighted
        then HH.div
          [ cls [ "text-xs text-amber-400 font-medium mb-4 uppercase tracking-wider" ] ]
          [ HH.text "Most popular" ]
        else HH.text ""
    , HH.h3
        [ cls [ "text-lg font-semibold text-text mb-2" ] ]
        [ HH.text config.name ]
    , HH.div
        [ cls [ "mb-4" ] ]
        [ HH.span [ cls [ "text-3xl font-bold text-text" ] ] [ HH.text config.price ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text config.period ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-6" ] ]
        [ HH.text config.description ]
    , HH.ul
        [ cls [ "space-y-3 mb-8 flex-grow" ] ]
        (map planFeature config.features)
    , HH.a
        [ HP.href config.ctaHref
        , cls [ "block text-center py-3 rounded-md font-medium transition-colors"
              , if config.highlighted
                  then "bg-amber-400 text-background hover:bg-amber-400/90"
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text config.cta ]
    ]

planFeature :: forall w i. String -> HH.HTML w i
planFeature feature =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-amber-400 mt-0.5" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text feature ]
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
                "What are proof obligations?"
                "Proof obligations are preconditions and postconditions attached to pipeline steps. They must be satisfied before a merge is allowed. This catches errors before deployment instead of after."
            , faqItem
                "Why Dhall instead of YAML?"
                "Dhall is a typed configuration language. The type system catches errors at compile time, not runtime. No more indentation bugs, no string interpolation vulnerabilities."
            , faqItem
                "What is agent code review?"
                "AI-generated code (from Copilot, Claude, etc.) is automatically detected and faces stricter review requirements. This prevents untrusted code from slipping through."
            , faqItem
                "Can I migrate from GitHub Actions?"
                "Yes. We provide a migration tool that converts your YAML workflows to typed Dhall. Most pipelines convert automatically."
            , faqItem
                "How are build minutes counted?"
                "Build minutes count wall-clock time from job start to completion. Parallel jobs run simultaneously, so 4 parallel jobs for 1 minute uses 4 build minutes. Caching reduces build times significantly."
            , faqItem
                "What counts as a proof verification?"
                "Each proof obligation checked counts as one verification. Built-in proofs (testsPass, noSecrets) and custom proofs are counted the same way. Pro and Enterprise plans have unlimited verifications."
            , faqItem
                "Is the server open source?"
                "The core pipeline engine is MIT licensed on GitHub. You can self-host or use our managed service."
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
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-amber-400 text-background font-medium rounded-md hover:bg-amber-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
