-- | sensenet//forge Legal Pages
-- | Privacy Policy, Terms of Service, and Contact
module Straylight.Pages.Products.SensenetForge.Legal 
  ( privacyPage
  , termsPage
  , contactPage
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
            "sensenet//forge (\"we\", \"us\", \"our\") is operated by Straylight Software. This privacy policy explains how we collect, use, and protect your information when you use our code hosting and review platform."
        , section "Information We Collect"
            "We collect information you provide directly: email address, username, SSH keys, and billing information when you create an account. We also collect code you push to repositories, review comments, and usage data necessary for service operation."
        , section "How We Use Your Information"
            "We use your information to: provide code hosting and review services, enable collaboration features, process payments, send service notifications, and improve our platform. We do not sell your personal information."
        , section "Code and Repository Data"
            "Your code repositories are stored on our servers. Private repositories are only accessible to authorized collaborators. We do not access your code except when required for service operation, support requests, or legal compliance."
        , section "Agent Attestation Data"
            "When using agent attestation features, we store cryptographic metadata about AI-generated code including model identifiers and prompt hashes. This data enables verification but does not include actual prompt content."
        , section "Data Retention"
            "We retain account data while your account is active. Repository data is retained according to your plan. Deleted repositories are purged within 90 days. You can request complete data deletion at any time."
        , section "Third-Party Services"
            "We use: Clerk for authentication, Stripe for payments. For self-hosted deployments, you control all data storage."
        , section "Security"
            "All data is encrypted in transit (TLS) and at rest. We support SSH-based access and cryptographic signing for commits."
        , section "Contact"
            "Questions? Email privacy@sensenet.dev"
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
            "By using sensenet//forge, you agree to these terms. If you don't agree, don't use the service."
        , section "Service Description"
            "sensenet//forge provides code hosting and review services with stacked diffs, jujutsu support, and agent attestation. We aim for high availability but don't guarantee 100% uptime."
        , section "Your Responsibilities"
            "You're responsible for: keeping your account and SSH keys secure, the code you push to repositories, ensuring you have rights to the code you host, and compliance with applicable laws."
        , section "Code Ownership"
            "You retain all rights to code you push to forge. We do not claim ownership of your code. For public repositories, you grant others the right to view and clone according to any license you specify."
        , section "Acceptable Use"
            "Don't use the service to: host malware or malicious code, violate laws or export controls, abuse resources, harass other users, or circumvent access controls. We may suspend accounts that violate these terms."
        , section "Open Source Software"
            "Public repositories must comply with any licenses of included dependencies. You are responsible for license compliance."
        , section "Agent-Generated Code"
            "When using AI agents with forge, you are responsible for reviewing and verifying agent-generated code. Attestation metadata provides provenance information but does not constitute a warranty."
        , section "Billing"
            "Paid plans are billed monthly. We'll notify you before charging. You can cancel anytime. Refunds are handled case-by-case."
        , section "Self-Hosted Deployments"
            "Enterprise self-hosted deployments are governed by separate license agreements."
        , section "Limitation of Liability"
            "We provide the service \"as is\". We're not liable for data loss, service interruptions, code defects, or indirect damages. Maintain your own backups."
        , section "Changes"
            "We may update these terms. Continued use after changes means you accept them. We'll notify you of significant changes."
        , section "Contact"
            "Questions? Email legal@sensenet.dev"
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
            [ HH.text "Have questions about sensenet//forge? We'd love to hear from you." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
        [ contactCard "General" "hello@sensenet.dev" "Questions, feedback, partnerships"
        , contactCard "Enterprise" "enterprise@sensenet.dev" "Self-hosted deployments, custom SLAs"
        , contactCard "Support" "support@sensenet.dev" "Technical issues, billing questions"
        ]
    , HH.div
        [ cls [ "mt-16 text-center" ] ]
        [ HH.p
            [ cls [ "text-muted-foreground mb-4" ] ]
            [ HH.text "Or find us on:" ]
        , HH.div
            [ cls [ "flex justify-center gap-6" ] ]
            [ socialLink "https://github.com/sensenet" "GitHub"
            , socialLink "https://discord.gg/sensenet" "Discord"
            , socialLink "https://twitter.com/sensenetdev" "Twitter"
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
        , cls [ "text-rose-400 hover:text-rose-400/80 block mb-2" ]
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
