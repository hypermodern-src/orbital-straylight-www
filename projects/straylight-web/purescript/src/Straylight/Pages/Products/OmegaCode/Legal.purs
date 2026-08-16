-- | omega//code Legal Pages
-- | Privacy Policy, Terms of Service, Contact
module Straylight.Pages.Products.OmegaCode.Legal 
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
            "omega//code (\"we\", \"us\", \"our\") is operated by Straylight Software. This privacy policy explains how we collect, use, and protect your information when you use our AI coding agent."
        , section "Information We Collect"
            "We collect information you provide directly: email address, name, and billing information when you create an account. Usage data includes agent interactions, session metadata, and attestation records for service improvement and security."
        , section "Code Privacy"
            "Your code is processed locally by default. When using cloud execution, code is processed in ephemeral sandboxes that are destroyed after each session. We do not train AI models on your code. Your code never persists on our servers beyond the active session."
        , section "Attestation Data"
            "omega//code creates cryptographic attestations for changes. These attestations are stored for audit purposes and are anchored using post-quantum signatures. Attestation data may include file hashes, timestamps, and agent decisions."
        , section "Third-Party Services"
            "We use: authentication providers for login, Stripe for payments, and LLM providers (configurable) for AI capabilities. Each has their own privacy policy."
        , section "Data Retention"
            "Account data is retained while your account is active. Session data is retained for 30 days. Attestation records are retained for 90 days or as required by your plan. You can request deletion of your data at any time."
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
            "By using omega//code, you agree to these terms. If you don't agree, don't use the service."
        , section "Service Description"
            "omega//code is a native terminal AI coding agent. We provide local execution by default and optional cloud execution for enhanced capabilities. We aim for high availability but don't guarantee 100% uptime."
        , section "Open Source"
            "omega//code is MIT licensed. You can run it on your own infrastructure. Cloud plans add managed hosting, support, team features, and enhanced capabilities."
        , section "Your Responsibilities"
            "You're responsible for: keeping your API keys secure, the code you instruct the agent to generate, and ensuring your use complies with applicable laws."
        , section "Acceptable Use"
            "Don't use the service to: generate malicious code, violate laws, abuse resources, circumvent security controls, or interfere with other users. We may suspend accounts that violate these terms."
        , section "LLM Provider Terms"
            "omega//code supports multiple LLM providers. Your use of these providers is subject to their terms. You are responsible for compliance with your chosen provider's acceptable use policies."
        , section "Attestation"
            "omega//code creates cryptographic attestations for changes made by agents. These attestations are provided as-is and should not be relied upon as the sole record of changes."
        , section "Billing"
            "Paid plans are billed monthly. We'll notify you before charging. You can cancel anytime. Refunds are handled case-by-case."
        , section "Intellectual Property"
            "You retain ownership of code you create using omega//code. We retain ownership of the service and its infrastructure. The omega//code CLI is MIT licensed."
        , section "Limitation of Liability"
            "We provide the service \"as is\". We're not liable for code generated by AI agents, data loss, service interruptions, or indirect damages."
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
        , contactCard "Enterprise" "enterprise@straylight.software" "Air-gapped deployments, custom integrations"
        , contactCard "Support" "support@straylight.software" "Technical issues, billing questions"
        ]
    , HH.div
        [ cls [ "mt-16 text-center" ] ]
        [ HH.p
            [ cls [ "text-muted-foreground mb-4" ] ]
            [ HH.text "Or find us on:" ]
        , HH.div
            [ cls [ "flex justify-center gap-6" ] ]
            [ socialLink "https://github.com/straylight-software/omega-code" "GitHub"
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
        , cls [ "text-blue-300 hover:text-blue-300/80 block mb-2" ]
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
