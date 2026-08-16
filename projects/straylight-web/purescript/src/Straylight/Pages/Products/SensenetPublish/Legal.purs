-- | sensenet//publish Legal Pages
-- | Privacy, terms
module Straylight.Pages.Products.SensenetPublish.Legal 
  ( privacyPage, termsPage, contactPage, renderPrivacy, renderTerms, renderContact ) where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

privacyPage :: forall q i o m. H.Component q i o m
privacyPage = H.mkComponent { initialState: const unit, render: const renderPrivacy, eval: H.mkEval H.defaultEval }

renderPrivacy :: forall w i. HH.HTML w i
renderPrivacy = HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-8" ] ] [ HH.text "Privacy Policy" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "sensenet//publish by Straylight Software" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Last updated" "February 2026"
        , section "Overview" "sensenet//publish is a scope-graph documentation service operated by Straylight Software. This policy describes how we handle your data when you use our service."
        , section "Source Code Processing" "When you build documentation, your source code is analyzed to construct scope graphs. Source code is processed in memory and is not persisted after the build completes. Only the generated documentation and scope-graph metadata are stored."
        , section "Scope Graph Data" "Scope graphs contain semantic information about your code structure: definitions, references, and their relationships. This data is stored to enable features like incremental builds, version pinning, and reference analytics."
        , section "Build Artifacts" "Generated documentation (HTML, JSON-LD, OpenAPI specs) is stored according to your plan. You can delete build artifacts at any time from the dashboard."
        , section "Usage Analytics" "We collect aggregate usage data: build counts, reference resolution rates, and error frequencies. This data is used to improve the service and is not shared with third parties."
        , section "Data Retention" "Build artifacts and scope-graph data are retained according to your plan. When you delete a project, all associated data is permanently deleted within 30 days."
        , section "Contact" "Questions about privacy? Email privacy@straylight.software"
        ] ]

termsPage :: forall q i o m. H.Component q i o m
termsPage = H.mkComponent { initialState: const unit, render: const renderTerms, eval: H.mkEval H.defaultEval }

renderTerms :: forall w i. HH.HTML w i
renderTerms = HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-8" ] ] [ HH.text "Terms of Service" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "sensenet//publish by Straylight Software" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-8" ] ]
        [ section "Last updated" "February 2026"
        , section "Service Description" "sensenet//publish provides scope-graph documentation generation with verified reference resolution. References that cannot be resolved cause the build to fail, ensuring documentation accuracy."
        , section "Acceptable Use" "You may use sensenet//publish to generate documentation for code you own or have rights to. You may not use the service to process code without authorization or to generate documentation for malicious purposes."
        , section "Service Availability" "We strive for high availability but do not guarantee uninterrupted service. Scheduled maintenance windows will be announced in advance. Enterprise customers receive SLA guarantees as specified in their contracts."
        , section "Intellectual Property" "You retain all rights to your source code and generated documentation. Straylight Software retains rights to the sensenet//publish software and service."
        , section "Limitation of Liability" "sensenet//publish is provided as-is. We are not liable for any damages arising from use of the service, including but not limited to documentation errors, build failures, or service interruptions."
        , section "Plan Limits" "Each plan has limits on projects and builds. Exceeding limits may result in throttled builds or service suspension until you upgrade or reduce usage."
        , section "Termination" "Either party may terminate the agreement at any time. Upon termination, you may export your documentation. Data is deleted according to our retention policy."
        , section "Contact" "Questions about terms? Email legal@straylight.software"
        ] ]

contactPage :: forall q i o m. H.Component q i o m
contactPage = H.mkComponent { initialState: const unit, render: const renderContact, eval: H.mkEval H.defaultEval }

renderContact :: forall w i. HH.HTML w i
renderContact = HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-24 text-center" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-4" ] ] [ HH.text "Contact" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Get in touch with the sensenet//publish team" ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ HH.div_
            [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text "General inquiries" ]
            , HH.a [ HP.href "mailto:hello@straylight.software", cls [ "text-teal-400 hover:text-teal-300" ] ] 
                [ HH.text "hello@straylight.software" ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text "Enterprise sales" ]
            , HH.a [ HP.href "mailto:enterprise@sensenet.dev", cls [ "text-teal-400 hover:text-teal-300" ] ] 
                [ HH.text "enterprise@sensenet.dev" ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text "Support" ]
            , HH.a [ HP.href "mailto:support@sensenet.dev", cls [ "text-teal-400 hover:text-teal-300" ] ] 
                [ HH.text "support@sensenet.dev" ]
            ]
        ]
    ]

section :: forall w i. String -> String -> HH.HTML w i
section title txt = HH.div_
    [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text txt ] ]
