-- | omega//code Pricing Page
module Straylight.Pages.Products.OmegaCode.Pricing 
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
            [ HH.text "Pay for compute. No hidden fees. No per-seat licensing. Cancel anytime." ]
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
                , period: "/forever"
                , description: "Bring your own keys. Full power, zero cost."
                , features:
                    [ "Unlimited local execution"
                    , "BYOK (Anthropic, OpenAI, etc.)"
                    , "Full CLI access"
                    , "SIGIL protocol"
                    , "Local attestation"
                    , "Community support"
                    , "MIT licensed"
                    ]
                , cta: "Download now"
                , ctaHref: "/omega/code/docs/installation"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$49"
                , period: "/month"
                , description: "Managed inference. No API keys needed."
                , features:
                    [ "Managed LLM inference"
                    , "No API keys required"
                    , "10 concurrent agents"
                    , "Crew mode (parallel agents)"
                    , "Cloud attestation sync"
                    , "Priority support"
                    , "Usage dashboard"
                    , "SSE streaming"
                    ]
                , cta: "Start free trial"
                , ctaHref: "/omega/code/signup?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "Air-gapped. On-prem. Your infrastructure."
                , features:
                    [ "Unlimited agents"
                    , "Air-gapped deployment"
                    , "On-premise installation"
                    , "Custom LLM integration"
                    , "SSO/SAML/OIDC"
                    , "Audit logs & compliance"
                    , "Dedicated support"
                    , "SLA guarantee"
                    ]
                , cta: "Contact sales"
                , ctaHref: "/omega/code/contact"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: MIT-licensed CLI, self-hosting option, SIGIL protocol, no vendor lock-in" ]
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
    [ cls [ "bg-card border rounded-lg p-6 flex flex-col"
          , if props.highlighted then "border-blue-300" else "border-border"
          ]
    ]
    [ -- Header
      HH.div
        [ cls [ "mb-6" ] ]
        [ HH.h3
            [ cls [ "text-lg font-semibold text-text mb-2" ] ]
            [ HH.text props.name ]
        , HH.div
            [ cls [ "flex items-baseline gap-1" ] ]
            [ HH.span
                [ cls [ "text-3xl font-bold text-text" ] ]
                [ HH.text props.price ]
            , HH.span
                [ cls [ "text-muted-foreground" ] ]
                [ HH.text props.period ]
            ]
        , HH.p
            [ cls [ "text-sm text-muted-foreground mt-2" ] ]
            [ HH.text props.description ]
        ]
    , -- Features
      HH.ul
        [ cls [ "space-y-3 flex-1 mb-6" ] ]
        (map featureItem props.features)
    , -- CTA
      HH.a
        [ HP.href props.ctaHref
        , cls [ "block text-center py-3 rounded-md font-medium transition-colors"
              , if props.highlighted 
                  then "bg-blue-300 text-background hover:bg-blue-300/90"
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text props.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-3 text-sm" ] ]
    [ HH.span [ cls [ "text-blue-300" ] ] [ HH.text "+" ]
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
                "What does BYOK mean?"
                "Bring Your Own Keys. On the Free plan, you provide your own API keys for Anthropic, OpenAI, or any compatible provider. You pay them directly, we charge nothing."
            , faqItem
                "What's the difference between Free and Pro?"
                "Free requires your own API keys. Pro includes managed inference \x2014 no keys needed, we handle the LLM providers. Pro also adds cloud attestation sync and priority support."
            , faqItem
                "What LLM providers are supported?"
                "Any OpenAI-compatible API. Anthropic Claude, OpenAI GPT-4, local models via Ollama, Groq, Together AI, or your own fine-tuned models."
            , faqItem
                "How does Crew mode work?"
                "Spawn multiple agents working on the same task with isolated CoW filesystems via bubblewrap. Compare approaches and merge the best result with attestation."
            , faqItem
                "What about data privacy?"
                "Your code never leaves your machine with local execution. Pro cloud features use ephemeral sandboxes destroyed after each session. We never train on your code."
            , faqItem
                "Can I switch between Free and Pro?"
                "Yes. Start with Free using your own keys. Upgrade to Pro anytime for managed inference. Downgrade back to Free whenever you want."
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
            [ HH.text "Enterprise deployments with air-gapped environments, custom integrations, and dedicated support. Let's talk." ]
        , HH.a
            [ HP.href "mailto:enterprise@straylight.software"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-blue-300 text-background font-medium rounded-md hover:bg-blue-300/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
