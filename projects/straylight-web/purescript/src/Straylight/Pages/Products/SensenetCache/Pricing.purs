-- | sensenet//cache Pricing Page
module Straylight.Pages.Products.SensenetCache.Pricing 
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
            [ HH.text "Pay for what you use. No hidden fees. Post-quantum security included at every tier." ]
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
                , description: "For individuals and open source projects."
                , features:
                    [ "5GB storage"
                    , "50GB transfer/month"
                    , "1 private cache"
                    , "Unlimited public caches"
                    , "Post-quantum signatures"
                    , "Blake3 content-addressing"
                    , "Community support"
                    ]
                , cta: "Get started free"
                , ctaHref: "/signup"
                , highlighted: false
                }
            , pricingCard
                { name: "Pro"
                , price: "$29"
                , period: "/month"
                , description: "For teams shipping production software."
                , features:
                    [ "100GB storage"
                    , "500GB transfer/month"
                    , "10 private caches"
                    , "5 team seats included"
                    , "Attestation reports & exports"
                    , "Cache analytics dashboard"
                    , "Priority email support"
                    , "Webhook integrations"
                    ]
                , cta: "Start 14-day trial"
                , ctaHref: "/signup?plan=pro"
                , highlighted: true
                }
            , pricingCard
                { name: "Enterprise"
                , price: "Custom"
                , period: ""
                , description: "For organizations with compliance and scale requirements."
                , features:
                    [ "Unlimited storage"
                    , "Unlimited transfer"
                    , "Unlimited team seats"
                    , "SSO/SAML authentication"
                    , "Audit logs (90-day retention)"
                    , "SLA guarantee (99.9% uptime)"
                    , "Self-hosted deployment option"
                    , "Dedicated support engineer"
                    , "Custom integrations"
                    ]
                , cta: "Contact sales"
                , ctaHref: "mailto:enterprise@sensenet.dev"
                , highlighted: false
                }
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "All plans include: Post-quantum SPHINCS+ signatures, Blake3 hashing, full attestation metadata, REST API access, Nix substituter support" ]
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
          , if config.highlighted then "border-cyan-400" else "border-border"
          ]
    ]
    [ if config.highlighted
        then HH.div
          [ cls [ "text-center text-cyan-400 text-xs font-medium mb-4 -mt-2" ] ]
          [ HH.text "MOST POPULAR" ]
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
        [ cls [ "space-y-2 flex-grow mb-6" ] ]
        (map featureItem config.features)
    , HH.a
        [ HP.href config.ctaHref
        , cls [ "block text-center py-3 rounded-md font-medium transition-colors"
              , if config.highlighted
                  then "bg-cyan-400 text-background hover:bg-cyan-400/90"
                  else "border border-border text-text hover:bg-card"
              ]
        ]
        [ HH.text config.cta ]
    ]

featureItem :: forall w i. String -> HH.HTML w i
featureItem feature =
  HH.li
    [ cls [ "flex items-start gap-2 text-sm" ] ]
    [ HH.span [ cls [ "text-cyan-400 mt-0.5" ] ] [ HH.text "+" ]
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
                "What are post-quantum signatures?"
                "SPHINCS+ is a hash-based signature algorithm standardized by NIST that remains secure against quantum computers. We sign all artifacts with SPHINCS+-256s, providing 128-bit post-quantum security. Your supply chain stays protected even when large-scale quantum computers exist."
            , faqItem
                "Can I migrate from Cachix or S3?"
                "Yes. Our CLI includes migration commands for both. Run `sensenet-cache migrate --from cachix` or `sensenet-cache migrate --from s3` to pull your existing artifacts and re-upload with attestation metadata. Most migrations complete in under an hour with zero downtime."
            , faqItem
                "How does content-addressed storage save money?"
                "Every artifact is identified by its Blake3 hash. Same content = same address, regardless of who uploaded it or when. This means automatic deduplication across your entire organization. Teams typically see 40-60% storage reduction compared to naive artifact storage."
            , faqItem
                "What happens if I exceed my storage or transfer limits?"
                "We don't cut you off or surprise you with overage bills. You'll receive a notification at 80% and 95% usage. If you exceed limits, you have 7 days to either upgrade or clean up old artifacts before we throttle uploads. Downloads are never affected."
            , faqItem
                "Is self-hosting available?"
                "Yes, on the Enterprise plan. We provide Docker images, Kubernetes Helm charts, and NixOS modules for on-premise deployment. Self-hosted instances can optionally connect to our managed attestation registry for cross-organization verification."
            , faqItem
                "How do attestations work?"
                "Every artifact upload captures provenance metadata: who built it, when, from what source commit, on which system. This metadata is cryptographically signed and stored alongside the artifact. Consumers can verify the complete chain of custody before using any artifact."
            , faqItem
                "Do you support private caches with public fallback?"
                "Yes. Configure multiple caches with priority ordering. Your CI pushes to your private cache, and Nix fetches from your private cache first, falling back to public caches like cache.nixos.org if needed. Full control over your supply chain."
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
            [ HP.href "mailto:enterprise@sensenet.dev"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-cyan-400 text-background font-medium rounded-md hover:bg-cyan-400/90 transition-colors" ]
            ]
            [ HH.text "Contact sales" ]
        ]
    ]
