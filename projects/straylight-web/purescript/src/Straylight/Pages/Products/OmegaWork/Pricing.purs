-- | omega//work Pricing Page
-- | 3 tiers: Free individual, Team @ $25/seat, Enterprise
module Straylight.Pages.Products.OmegaWork.Pricing 
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
    , comparison
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
            [ HH.text "Pricing for every team" ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Start free as an individual. Scale to your whole team when you're ready." ]
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
                { name: "Free"
                , price: "$0"
                , period: "/month"
                , description: "For individuals exploring AI assistance."
                , features:
                    [ "Full desktop app"
                    , "50 conversations/month"
                    , "Basic agent capabilities"
                    , "Local-only storage"
                    , "Community support"
                    ]
                , cta: "Download free"
                , ctaHref: "/omega/work/dashboard"
                , highlighted: false
                }
            , pricingCard
                { name: "Team"
                , price: "$25"
                , period: "/seat/month"
                , description: "For teams who work better together."
                , features:
                    [ "Everything in Free"
                    , "Unlimited conversations"
                    , "Team workspaces"
                    , "Shared conversation history"
                    , "Cloud sync across devices"
                    , "Integrations (Slack, Notion, etc.)"
                    , "Admin dashboard"
                    , "Priority support"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/omega/work/dashboard?plan=team"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with advanced needs."
                , features:
                    [ "Everything in Team"
                    , "SSO/SAML authentication"
                    , "Advanced permissions"
                    , "Audit logs"
                    , "Dedicated success manager"
                    , "Custom integrations"
                    , "SLA guarantee"
                    , "On-premise option"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/omega/work/contact"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: Native app for macOS, Windows, and Linux. 14-day free trial for Team plan." ]
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
          , if props.highlighted then "border-indigo-400" else "border-border"
          ]
    ]
    [ if props.highlighted
        then HH.div
            [ cls [ "text-xs text-indigo-400 font-medium mb-4" ] ]
            [ HH.text "MOST POPULAR" ]
        else HH.text ""
    , HH.h3
        [ cls [ "text-lg font-semibold text-text mb-2" ] ]
        [ HH.text props.name ]
    , HH.div
        [ cls [ "mb-4" ] ]
        [ HH.span [ cls [ "text-3xl font-bold text-text" ] ] [ HH.text props.price ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text props.period ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mb-6" ] ]
        [ HH.text props.description ]
    , HH.ul
        [ cls [ "space-y-2 mb-6" ] ]
        (map featureItem props.features)
    , HH.a
        [ HP.href props.ctaHref
        , cls [ "block w-full py-3 text-center font-medium rounded-md transition-colors"
              , if props.highlighted 
                  then "bg-indigo-400 text-background hover:bg-indigo-400/90" 
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text props.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem feature =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-indigo-400" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text feature ]
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
        [ HH.h2
            [ cls [ "text-2xl font-bold text-text mb-12 text-center" ] ]
            [ HH.text "Compare plans" ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[600px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Free" ]
                        , HH.th [ cls [ "py-4 text-center text-indigo-400 font-bold" ] ] [ HH.text "Team" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Enterprise" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Conversations" "50/month" "Unlimited" "Unlimited"
                    , comparisonRow "Team members" "1" "Unlimited" "Unlimited"
                    , comparisonRow "Workspaces" "1 personal" "Unlimited team" "Unlimited + org-wide"
                    , comparisonRow "Shared history" "-" "Yes" "Yes"
                    , comparisonRow "Cloud sync" "-" "Yes" "Yes"
                    , comparisonRow "Integrations" "-" "All" "All + custom"
                    , comparisonRow "SSO/SAML" "-" "-" "Yes"
                    , comparisonRow "Audit logs" "-" "-" "Yes"
                    , comparisonRow "Support" "Community" "Priority" "Dedicated"
                    ]
                ]
            ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> HH.HTML w i
comparisonRow feature free team enterprise =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text free ]
    , HH.td [ cls [ "py-3 text-center text-indigo-400 font-semibold" ] ] [ HH.text team ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text enterprise ]
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
                "Is the Free plan really free?"
                "Yes! The Free plan is completely free with 50 conversations per month. Perfect for trying omega//work or light personal use."
            , faqItem
                "How does team billing work?"
                "Team plans are billed per seat. Add or remove seats anytime. You're only charged for active users each billing cycle."
            , faqItem
                "Can I switch from Free to Team?"
                "Yes, upgrade anytime. Your conversations and settings carry over. Start a 14-day free trial of Team before committing."
            , faqItem
                "What's included in the free trial?"
                "The 14-day Team trial includes everything: unlimited conversations, team workspaces, integrations, and priority support."
            , faqItem
                "Do you offer nonprofit or education discounts?"
                "Yes! Contact us for special pricing for nonprofits, educational institutions, and open source projects."
            , faqItem
                "What platforms are supported?"
                "omega//work runs natively on macOS (Intel and Apple Silicon), Windows 10/11, and Linux (Ubuntu, Fedora, Arch)."
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
            [ HH.text "Need enterprise features?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "SSO, audit logs, custom integrations, dedicated support, and more. Let's design a plan that fits your organization." ]
        , HH.a
            [ HP.href "mailto:enterprise@straylight.software"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-indigo-400 text-background font-medium rounded-md hover:bg-indigo-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
