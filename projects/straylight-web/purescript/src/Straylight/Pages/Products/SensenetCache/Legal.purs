-- | sensenet//cache Legal Pages
module Straylight.Pages.Products.SensenetCache.Legal 
  ( privacyPage, termsPage, contactPage, renderPrivacy, renderTerms, renderContact ) where

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
  HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-2" ] ] 
        [ HH.text "Privacy Policy" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Last updated: February 2026" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Overview"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "sensenet//cache is operated by Straylight Software, Inc. This privacy policy explains how we collect, use, and protect your data when you use our attestation-aware binary cache service." ]
            ]
        , section "Information We Collect"
            [ HH.p [ cls [ "text-muted-foreground mb-4" ] ]
                [ HH.text "We collect the following types of information:" ]
            , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.span [ cls [ "text-text" ] ] [ HH.text "Account information: " ], HH.text "Email address, organization name, and billing details when you create an account." ]
                , HH.li_ [ HH.span [ cls [ "text-text" ] ] [ HH.text "Artifact metadata: " ], HH.text "Blake3 hashes, attestation records, upload timestamps, and file sizes for artifacts you push to the cache." ]
                , HH.li_ [ HH.span [ cls [ "text-text" ] ] [ HH.text "Usage data: " ], HH.text "API access logs, bandwidth consumption, and cache hit/miss statistics." ]
                , HH.li_ [ HH.span [ cls [ "text-text" ] ] [ HH.text "Technical data: " ], HH.text "IP addresses, browser type, and device information for security and debugging purposes." ]
                ]
            ]
        , section "How We Use Your Data"
            [ HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "Provide and maintain the sensenet//cache service" ]
                , HH.li_ [ HH.text "Verify artifact integrity and attestation chains" ]
                , HH.li_ [ HH.text "Enforce storage and transfer limits based on your plan" ]
                , HH.li_ [ HH.text "Send service notifications (usage alerts, security alerts)" ]
                , HH.li_ [ HH.text "Improve our service through aggregated, anonymized analytics" ]
                , HH.li_ [ HH.text "Comply with legal obligations" ]
                ]
            ]
        , section "Data Storage & Security"
            [ HH.p [ cls [ "text-muted-foreground mb-4" ] ]
                [ HH.text "Your data is protected by:" ]
            , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "Content-addressed storage with Blake3 cryptographic hashing" ]
                , HH.li_ [ HH.text "Post-quantum SPHINCS+ signatures on all artifacts" ]
                , HH.li_ [ HH.text "Encryption in transit (TLS 1.3) and at rest (AES-256-GCM)" ]
                , HH.li_ [ HH.text "SOC 2 Type II certified infrastructure" ]
                , HH.li_ [ HH.text "Geographic redundancy across multiple data centers" ]
                ]
            ]
        , section "Data Retention"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "Cached artifacts are retained as long as your account is active. Attestation records are retained for verification purposes. Audit logs are retained for 90 days. When you delete your account, all artifacts and associated data are permanently deleted within 30 days." ]
            ]
        , section "Third-Party Services"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "We use the following third-party services to operate sensenet//cache:" ]
            , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mt-4" ] ]
                [ HH.li_ [ HH.text "Stripe for payment processing" ]
                , HH.li_ [ HH.text "Cloudflare for DDoS protection and CDN" ]
                , HH.li_ [ HH.text "AWS/GCP for infrastructure (self-hosted option available for Enterprise)" ]
                ]
            ]
        , section "Your Rights"
            [ HH.p [ cls [ "text-muted-foreground mb-4" ] ]
                [ HH.text "You have the right to:" ]
            , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "Access your personal data" ]
                , HH.li_ [ HH.text "Correct inaccurate data" ]
                , HH.li_ [ HH.text "Delete your account and associated data" ]
                , HH.li_ [ HH.text "Export your artifact metadata and attestation records" ]
                , HH.li_ [ HH.text "Opt out of marketing communications" ]
                ]
            ]
        , section "Contact"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "For privacy-related inquiries, contact us at "
                , HH.a [ HP.href "mailto:privacy@straylight.software", cls [ "text-cyan-400 hover:text-cyan-300" ] ] 
                    [ HH.text "privacy@straylight.software" ]
                , HH.text "."
                ]
            ]
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
  HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-2" ] ] 
        [ HH.text "Terms of Service" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Last updated: February 2026" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Acceptance of Terms"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "By accessing or using sensenet//cache, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the service." ]
            ]
        , section "Service Description"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "sensenet//cache is an attestation-aware binary cache service that provides content-addressed artifact storage, post-quantum cryptographic signatures, and attestation verification. The service is designed for software build artifacts, Nix store paths, and general-purpose binary distribution." ]
            ]
        , section "Account Responsibilities"
            [ HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "You are responsible for maintaining the security of your account credentials and API keys." ]
                , HH.li_ [ HH.text "You must provide accurate account information and keep it up to date." ]
                , HH.li_ [ HH.text "You are responsible for all activity that occurs under your account." ]
                , HH.li_ [ HH.text "You must notify us immediately of any unauthorized access to your account." ]
                ]
            ]
        , section "Acceptable Use"
            [ HH.p [ cls [ "text-muted-foreground mb-4" ] ]
                [ HH.text "You agree not to:" ]
            , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "Store or distribute malware, viruses, or malicious code" ]
                , HH.li_ [ HH.text "Store illegal content or content that infringes on intellectual property rights" ]
                , HH.li_ [ HH.text "Attempt to circumvent usage limits or access controls" ]
                , HH.li_ [ HH.text "Use the service for cryptocurrency mining or resource-intensive non-cache workloads" ]
                , HH.li_ [ HH.text "Share API keys or account credentials with unauthorized parties" ]
                , HH.li_ [ HH.text "Interfere with or disrupt the service or its infrastructure" ]
                ]
            ]
        , section "Service Levels & Limits"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "Each plan includes specific storage and transfer limits. Exceeding limits may result in throttling of uploads (downloads are never affected). Enterprise plans include custom SLAs with uptime guarantees." ]
            ]
        , section "Payment Terms"
            [ HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2" ] ]
                [ HH.li_ [ HH.text "Paid plans are billed monthly in advance." ]
                , HH.li_ [ HH.text "You authorize us to charge your payment method on file for recurring fees." ]
                , HH.li_ [ HH.text "All fees are non-refundable except as required by law or stated in our refund policy." ]
                , HH.li_ [ HH.text "We may change pricing with 30 days notice; you may cancel before the change takes effect." ]
                ]
            ]
        , section "Intellectual Property"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "You retain all rights to artifacts you upload to sensenet//cache. By uploading artifacts, you grant us a license to store, distribute, and process them as necessary to provide the service. We claim no ownership over your content." ]
            ]
        , section "Limitation of Liability"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "To the maximum extent permitted by law, Straylight Software shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of sensenet//cache. Our total liability shall not exceed the amount you paid us in the 12 months preceding the claim." ]
            ]
        , section "Termination"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "You may cancel your account at any time. We may suspend or terminate your account for violation of these terms. Upon termination, your artifacts will be deleted within 30 days unless legally required to retain them." ]
            ]
        , section "Governing Law"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "These terms are governed by the laws of the State of Delaware, USA, without regard to conflict of law principles." ]
            ]
        , section "Contact"
            [ HH.p [ cls [ "text-muted-foreground" ] ]
                [ HH.text "For questions about these terms, contact us at "
                , HH.a [ HP.href "mailto:legal@straylight.software", cls [ "text-cyan-400 hover:text-cyan-300" ] ] 
                    [ HH.text "legal@straylight.software" ]
                , HH.text "."
                ]
            ]
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
  HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-24" ] ]
    [ HH.div [ cls [ "text-center mb-12" ] ]
        [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-4" ] ] 
            [ HH.text "Contact Us" ]
        , HH.p [ cls [ "text-muted-foreground" ] ] 
            [ HH.text "We're here to help with questions about sensenet//cache." ]
        ]
    , HH.div [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
        [ contactCard "General Inquiries" "hello@straylight.software" "Questions about sensenet//cache, partnerships, or just saying hi."
        , contactCard "Sales & Enterprise" "enterprise@sensenet.dev" "Custom deployments, volume pricing, and enterprise features."
        , contactCard "Support" "support@sensenet.dev" "Technical issues, bug reports, and account assistance."
        ]
    , HH.div [ cls [ "mt-12 grid grid-cols-1 md:grid-cols-2 gap-6" ] ]
        [ contactCard "Security" "security@straylight.software" "Report security vulnerabilities or concerns. PGP key available on request."
        , contactCard "Legal & Privacy" "legal@straylight.software" "Privacy inquiries, data requests, and legal matters."
        ]
    , HH.div [ cls [ "mt-16 text-center" ] ]
        [ HH.div [ cls [ "inline-block p-6 bg-card border border-border rounded-lg" ] ]
            [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] 
                [ HH.text "Straylight Software, Inc." ]
            , HH.p [ cls [ "text-muted-foreground text-sm" ] ] 
                [ HH.text "Distributed team. No physical office." ]
            , HH.p [ cls [ "text-muted-foreground text-sm mt-2" ] ] 
                [ HH.text "Incorporated in Delaware, USA" ]
            ]
        ]
    , HH.div [ cls [ "mt-12 text-center" ] ]
        [ HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] 
            [ HH.text "Looking for documentation?" ]
        , HH.a 
            [ HP.href "/sensenet/cache/docs"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-cyan-400 text-background font-medium rounded-md hover:bg-cyan-400/90 transition-colors" ]
            ] 
            [ HH.text "Read the docs" ]
        ]
    ]

contactCard :: forall w i. String -> String -> String -> HH.HTML w i
contactCard title email description =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-cyan-400/30 transition-colors" ] ]
    [ HH.h3 [ cls [ "text-text font-semibold mb-2" ] ] [ HH.text title ]
    , HH.a 
        [ HP.href ("mailto:" <> email)
        , cls [ "text-cyan-400 hover:text-cyan-300 text-sm font-mono block mb-3" ]
        ] 
        [ HH.text email ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

section :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
section title children =
  HH.div_
    ( [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-3" ] ] [ HH.text title ] ]
      <> children
    )
