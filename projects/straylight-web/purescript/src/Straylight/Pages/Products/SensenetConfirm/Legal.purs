-- | sensenet//confirm Legal Pages
-- | Privacy Policy, Terms of Service, and Contact
module Straylight.Pages.Products.SensenetConfirm.Legal 
  ( privacyPage
  , termsPage
  , contactPage
  -- For SSG
  , renderPrivacy
  , renderTerms
  , renderContact
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- PRIVACY PAGE
-- ============================================================

privacyPage :: forall q i o m. H.Component q i o m
privacyPage = H.mkComponent
  { initialState: const unit
  , render: const renderPrivacy
  , eval: H.mkEval H.defaultEval
  }

renderPrivacy :: forall w i. HH.HTML w i
renderPrivacy =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1
        [ cls [ "text-3xl font-bold text-text mb-8" ] ]
        [ HH.text "Privacy Policy" ]
    , HH.div
        [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Overview"
            "sensenet//confirm (\"we\", \"us\", \"our\") is operated by Straylight Software. This privacy policy explains how we collect, use, and protect your information when you use our CI service with proof obligations."
        , section "Information We Collect"
            "We collect information you provide directly: email address, name, and billing information when you create an account. We also collect usage data: build minutes, proof verification results, and API usage for billing and service improvement. Build logs and pipeline configurations are stored to enable reproducibility."
        , section "How We Use Your Information"
            "We use your information to: provide and maintain the service, process payments, send service notifications, verify proof obligations, and improve our product. We do not sell your personal information."
        , section "Data Storage"
            "Your pipeline configurations and build attestations are stored securely. We retain account data while your account is active. Build logs are retained for 90 days by default. You can request deletion of your data at any time."
        , section "Third-Party Services"
            "We use: Clerk for authentication, Stripe for payments, and secure cloud infrastructure for build execution. Each has their own privacy policy."
        , section "Security"
            "All build attestations are cryptographically signed. Communications are encrypted in transit and at rest. We implement industry-standard security measures to protect your data."
        , section "Contact"
            "Questions? Email privacy@straylight.software"
        ]
    ]

-- ============================================================
-- TERMS PAGE
-- ============================================================

termsPage :: forall q i o m. H.Component q i o m
termsPage = H.mkComponent
  { initialState: const unit
  , render: const renderTerms
  , eval: H.mkEval H.defaultEval
  }

renderTerms :: forall w i. HH.HTML w i
renderTerms =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1
        [ cls [ "text-3xl font-bold text-text mb-8" ] ]
        [ HH.text "Terms of Service" ]
    , HH.div
        [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Acceptance"
            "By using sensenet//confirm, you agree to these terms. If you don't agree, don't use the service."
        , section "Service Description"
            "sensenet//confirm provides CI with proof obligations, typed Dhall pipelines, and cryptographic attestation. We aim for high availability but don't guarantee 100% uptime."
        , section "Your Responsibilities"
            "You're responsible for: keeping your API keys secure, not using the service for malicious purposes, ensuring your pipelines don't contain harmful code, and paying for usage beyond free tier limits."
        , section "Proof Obligations"
            "Proof obligations are verified on a best-effort basis. While we strive for accuracy, proof verification does not constitute a guarantee of correctness. You remain responsible for the quality and security of your code."
        , section "Agent Code Review"
            "AI-generated code detection is provided as a tool to assist your review process. It does not replace human judgment or security audits."
        , section "Acceptable Use"
            "Don't use the service to: run malicious code, mine cryptocurrency, violate laws, abuse resources, or interfere with other users. We may suspend accounts that violate these terms."
        , section "Billing"
            "Paid plans are billed monthly. We'll notify you before charging. You can cancel anytime. Refunds are handled case-by-case."
        , section "Intellectual Property"
            "You retain ownership of your code and pipelines. We retain ownership of the service and its infrastructure. Build attestations belong to you."
        , section "Limitation of Liability"
            "We provide the service \"as is\". We're not liable for data loss, service interruptions, proof verification errors, or indirect damages."
        , section "Changes"
            "We may update these terms. Continued use after changes means you accept them."
        , section "Contact"
            "Questions? Email legal@straylight.software"
        ]
    ]

-- ============================================================
-- CONTACT PAGE
-- ============================================================

contactPage :: forall q i o m. H.Component q i o m
contactPage = H.mkComponent
  { initialState: const unit
  , render: const renderContact
  , eval: H.mkEval H.defaultEval
  }

renderContact :: forall w i. HH.HTML w i
renderContact =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-24" ] ]
    [ HH.div
        [ cls [ "text-center mb-12" ] ]
        [ HH.h1
            [ cls [ "text-3xl font-bold text-text mb-4" ] ]
            [ HH.text "Get in touch" ]
        , HH.p
            [ cls [ "text-muted-foreground" ] ]
            [ HH.text "We'd love to hear from you." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
        [ contactCard "General" "hello@straylight.software" "Questions, feedback, partnerships"
        , contactCard "Enterprise" "enterprise@straylight.software" "Custom deployments, SLAs, integrations"
        , contactCard "Support" "support@straylight.software" "Technical issues, billing questions"
        ]
    , HH.div
        [ cls [ "mt-16 text-center" ] ]
        [ HH.p
            [ cls [ "text-muted-foreground mb-4" ] ]
            [ HH.text "Or find us on:" ]
        , HH.div
            [ cls [ "flex justify-center gap-6" ] ]
            [ socialLink "https://github.com/straylight-software/sensenet-confirm" "GitHub"
            , socialLink "https://discord.gg/straylight" "Discord"
            , socialLink "https://twitter.com/straylightsw" "Twitter"
            ]
        ]
    ]

contactCard :: forall w i. String -> String -> String -> HH.HTML w i
contactCard title email description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.h3
        [ cls [ "text-lg font-semibold text-text mb-2" ] ]
        [ HH.text title ]
    , HH.a
        [ HP.href $ "mailto:" <> email
        , cls [ "text-amber-400 hover:text-amber-400/80 block mb-2" ]
        ]
        [ HH.text email ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground" ] ]
        [ HH.text description ]
    ]

socialLink :: forall w i. String -> String -> HH.HTML w i
socialLink href label =
  HH.a
    [ HP.href href
    , HP.target "_blank"
    , HP.rel "noopener noreferrer"
    , cls [ "text-muted-foreground hover:text-text transition-colors" ]
    ]
    [ HH.text label ]

-- ============================================================
-- HELPERS
-- ============================================================

section :: forall w i. String -> String -> HH.HTML w i
section title content =
  HH.div_
    [ HH.h2
        [ cls [ "text-lg font-semibold text-text mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text content ]
    ]
