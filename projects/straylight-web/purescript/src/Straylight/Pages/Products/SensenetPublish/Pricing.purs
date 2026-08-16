-- | sensenet//publish Pricing Page
module Straylight.Pages.Products.SensenetPublish.Pricing 
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
            [ HH.text "Free for open source. Pay for what you need as you scale." ]
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
                , description: "For open source and personal projects."
                , features:
                    [ "3 projects"
                    , "100 builds/month"
                    , "All languages supported"
                    , "Full scope-graph analysis"
                    , "HTML + JSON output"
                    , "Community support"
                    ]
                , cta: "Get started"
                , ctaHref: "/sensenet/publish/docs/quickstart"
                , highlighted: false
                }
            , pricingCard
                { name: "Team"
                , price: "$79"
                , period: "/month"
                , description: "For teams shipping production software."
                , features:
                    [ "25 projects"
                    , "Unlimited builds"
                    , "Cross-language refs"
                    , "All output formats"
                    , "CI/CD integration"
                    , "Version pinning"
                    , "Email support"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/sensenet/publish/signup?plan=team"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with compliance needs."
                , features:
                    [ "Unlimited projects"
                    , "Unlimited builds"
                    , "Self-hosted option"
                    , "Custom output formats"
                    , "API access"
                    , "SSO/SAML"
                    , "Dedicated support & SLA"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/sensenet/publish/contact"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: CLI access, CI integration, scope-graph caching, incremental builds" ]
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
          , if props.highlighted then "border-teal-400" else "border-border"
          ]
    ]
    [ if props.highlighted
        then HH.span 
          [ cls [ "text-xs text-teal-400 font-medium uppercase tracking-wider" ] ] 
          [ HH.text "Most Popular" ]
        else HH.text ""
    , HH.h3
        [ cls [ "text-xl font-bold text-text mt-2" ] ]
        [ HH.text props.name ]
    , HH.div
        [ cls [ "mt-4 mb-6" ] ]
        [ HH.span
            [ cls [ "text-4xl font-bold text-text" ] ]
            [ HH.text props.price ]
        , HH.span
            [ cls [ "text-muted-foreground" ] ]
            [ HH.text props.period ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-6" ] ]
        [ HH.text props.description ]
    , HH.ul
        [ cls [ "space-y-3 mb-8" ] ]
        (map featureItem props.features)
    , HH.a
        [ HP.href props.ctaHref
        , cls [ "block w-full py-3 text-center font-medium rounded-md transition-colors"
              , if props.highlighted 
                  then "bg-teal-400 text-background hover:bg-teal-400/90" 
                  else "border border-border text-text hover:bg-muted"
              ]
        ]
        [ HH.text props.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-center gap-2 text-sm text-muted-foreground" ] ]
    [ HH.span [ cls [ "text-teal-400" ] ] [ HH.text "+" ]
    , HH.text text
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
                "What counts as a repository?"
                "Each Git repository counts as one project. Monorepos with multiple packages are still one repository."
            , faqItem
                "Can I use it with private forks of open source projects?"
                "Yes, but private forks count against your private repository limit unless the upstream project is public."
            , faqItem
                "What counts as a build?"
                "Each invocation of sensenet-publish build or check counts as one build. Incremental builds that use cached scope graphs still count."
            , faqItem
                "Is the CLI open source?"
                "Yes, the CLI and core scope-graph engine are MIT licensed. The hosted service adds features like version pinning, analytics, and priority builds."
            , faqItem
                "Can I self-host?"
                "Enterprise plans include self-hosted deployment options with full scope-graph analysis. Contact sales for details."
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
            [ HH.text "We work with enterprises on custom deployments, integrations, and SLAs. Let's talk." ]
        , HH.a
            [ HP.href "mailto:enterprise@sensenet.dev"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-teal-400 text-background font-medium rounded-md hover:bg-teal-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
