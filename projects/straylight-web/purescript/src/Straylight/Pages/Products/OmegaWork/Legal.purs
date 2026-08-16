-- | omega//work Legal Pages
-- | Privacy Policy and Terms of Service
module Straylight.Pages.Products.OmegaWork.Legal 
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
            "omega//work (\"we\", \"us\", \"our\") is operated by Straylight Software. This privacy policy explains how we collect, use, and protect your information when you use our desktop application."
        , section "Information We Collect"
            "We collect information you provide directly: email address, name, and billing information when you create an account. Usage data includes conversation metadata (not content) for sync features and app improvement."
        , section "Local-First Design"
            "omega//work is designed with privacy as a core principle. Your project files and conversation content are stored locally on your device. Only metadata necessary for sync is transmitted when you enable cloud features."
        , section "How We Use Your Information"
            "We use your information to: provide and maintain the service, process payments, send service notifications, and improve the app. We do not sell your personal information or train AI models on your data."
        , section "Data Storage"
            "Project files remain on your local device. Cloud sync data (conversation metadata, settings) is encrypted in transit and at rest. You can delete synced data at any time."
        , section "Third-Party Services"
            "We use: Clerk for authentication, Stripe for payments. When you bring your own API key, your requests go directly to the AI provider."
        , section "Your Rights"
            "You can export, delete, or modify your data at any time through the app settings. Contact us for data access requests."
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
            "By using omega//work, you agree to these terms. If you don't agree, don't use the service."
        , section "Service Description"
            "omega//work is a desktop application that provides AI-assisted workflows. The app runs locally on your device with optional cloud sync features."
        , section "Your Responsibilities"
            "You're responsible for: keeping your account secure, the content you create or modify using the app, and ensuring you have rights to any files you process."
        , section "Acceptable Use"
            "Don't use the service to: create harmful content, violate laws, abuse AI resources, or interfere with other users. We may suspend accounts that violate these terms."
        , section "Subscriptions and Billing"
            "Paid plans are billed monthly or annually. You can cancel anytime; access continues until the end of your billing period. Refunds are handled case-by-case."
        , section "Intellectual Property"
            "You retain ownership of content you create. We retain ownership of the app and its infrastructure. The AI outputs are yours to use as you see fit."
        , section "Limitation of Liability"
            "We provide the service \"as is\". We're not liable for data loss, service interruptions, or indirect damages. Always keep backups of important work."
        , section "Changes"
            "We may update these terms. Continued use after changes means you accept them. We'll notify you of significant changes."
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
            [ HH.text "Have questions about omega//work? We'd love to hear from you." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
        [ contactCard "General" "hello@straylight.software" "Questions, feedback, partnerships"
        , contactCard "Sales" "sales@straylight.software" "Enterprise plans, volume licensing"
        , contactCard "Support" "support@straylight.software" "Technical issues, billing questions"
        ]
    , HH.div
        [ cls [ "mt-16 text-center" ] ]
        [ HH.p
            [ cls [ "text-muted-foreground mb-4" ] ]
            [ HH.text "Or find us on:" ]
        , HH.div
            [ cls [ "flex justify-center gap-6" ] ]
            [ socialLink "https://github.com/straylight-software" "GitHub"
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
        , cls [ "text-indigo-400 hover:text-indigo-400/80 block mb-2" ]
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
