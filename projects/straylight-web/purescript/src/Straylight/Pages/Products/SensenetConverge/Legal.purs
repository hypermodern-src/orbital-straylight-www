-- | sensenet//converge Legal Pages
-- | Privacy, Terms, Contact
module Straylight.Pages.Products.SensenetConverge.Legal 
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
        [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Last updated" "February 2026"
        
        , section "Overview" 
            "sensenet//converge is operated by Straylight Software. This policy describes how we collect, use, and protect your data when you use our typed infrastructure-as-code platform."
        
        , section "Infrastructure Data"
            "sensenet//converge processes infrastructure state by querying your cloud providers directly. Unlike traditional IaC tools, we do not maintain state files. Your infrastructure configuration is stored encrypted, and credentials never leave your environment."
        
        , section "No State Files"
            "A key differentiator of converge is that we query live infrastructure state rather than storing it. This means no sensitive data in state files, no state file corruption, and no drift from stored state."
        
        , section "Data We Collect"
            "We collect: account information (email, name), usage metrics (resource counts, convergence frequency), and audit logs (who changed what, when). We do not collect or store your cloud credentials or the actual values of your infrastructure resources."
        
        , section "Data Security"
            "All data is encrypted in transit (TLS 1.3) and at rest (AES-256). We are SOC 2 Type II certified. Enterprise customers can use their own encryption keys."
        
        , section "Data Retention"
            "Audit logs are retained according to your plan tier (7-90 days). You can export or delete your data at any time from the dashboard."
        
        , section "Contact"
            "Questions about privacy? Email privacy@straylight.software"
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
        [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Last updated" "February 2026"
        
        , section "Service Description"
            "sensenet//converge provides typed infrastructure-as-code with desired-state convergence. The service includes: infrastructure definition DSL, continuous convergence engine, drift detection and remediation, and multi-cloud provider support."
        
        , section "No State File Guarantee"
            "Converge queries infrastructure state live from your cloud providers. We guarantee that no state files are created or stored as part of normal operation. This eliminates state file corruption, drift from stored state, and sensitive data in state files."
        
        , section "Acceptable Use"
            "You agree to use converge only for lawful infrastructure management. You are responsible for ensuring your infrastructure configurations comply with your cloud providers' terms of service."
        
        , section "Service Availability"
            "We target 99.9% uptime for paid plans. The free tier is provided as-is without SLA. Scheduled maintenance will be announced 48 hours in advance."
        
        , section "Resource Limits"
            "Each plan tier includes specific resource limits. If you exceed your limit, we will notify you and work with you to upgrade or optimize. We do not automatically suspend service for overages."
        
        , section "Intellectual Property"
            "Your infrastructure configurations remain your property. We claim no ownership over your code or infrastructure definitions. The converge DSL, CLI, and platform are owned by Straylight Software."
        
        , section "Termination"
            "You may cancel your subscription at any time. Upon cancellation, your configurations are exportable for 30 days. We may terminate accounts for violation of these terms with 14 days notice."
        
        , section "Contact"
            "Questions about terms? Email legal@straylight.software"
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
            [ HH.text "Contact Us" ]
        , HH.p
            [ cls [ "text-muted-foreground" ] ]
            [ HH.text "Get in touch with the sensenet//converge team." ]
        ]
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
        [ contactCard "General Inquiries" "hello@straylight.software" "Questions about converge"
        , contactCard "Sales & Enterprise" "sales@straylight.software" "Custom plans, SLAs, self-hosted"
        , contactCard "Support" "support@straylight.software" "Technical issues, bug reports"
        ]
    , HH.div
        [ cls [ "mt-12 text-center" ] ]
        [ HH.p
            [ cls [ "text-muted-foreground mb-4" ] ]
            [ HH.text "Prefer to chat?" ]
        , HH.a
            [ HP.href "/discord"
            , cls [ "inline-flex items-center justify-center px-6 py-3 bg-purple-400 text-background font-medium rounded-md hover:bg-purple-400/90 transition-colors" ]
            ]
            [ HH.text "Join our Discord" ]
        ]
    ]

contactCard :: forall w i. String -> String -> String -> HH.HTML w i
contactCard title email description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.h3
        [ cls [ "text-text font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.a
        [ HP.href $ "mailto:" <> email
        , cls [ "text-purple-400 hover:text-purple-400/80 transition-colors" ]
        ]
        [ HH.text email ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground mt-2" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

section :: forall w i. String -> String -> HH.HTML w i
section title txt =
  HH.div_
    [ HH.h2
        [ cls [ "text-lg font-semibold text-text mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground" ] ]
        [ HH.text txt ]
    ]
