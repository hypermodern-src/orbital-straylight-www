-- | omega//proxy Legal Pages
module Straylight.Pages.Products.OmegaProxy.Legal 
  ( privacyPage, termsPage, contactPage
  , renderPrivacy, renderTerms, renderContact
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

privacyPage :: forall q i o m. H.Component q i o m
privacyPage = H.mkComponent
  { initialState: const unit, render: const renderPrivacy, eval: H.mkEval H.defaultEval }

renderPrivacy :: forall w i. HH.HTML w i
renderPrivacy =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-8" ] ] [ HH.text "Privacy Policy" ]
    , HH.span [ cls [ "inline-block px-3 py-1 bg-orange-400/10 text-orange-400 text-sm rounded-full mb-8" ] ] [ HH.text "omega//proxy" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Overview" "omega//proxy is operated by Straylight Software. This privacy policy explains how we handle your data when using our verified inference proxy."
        , section "Data Processing" "omega//proxy processes inference requests in transit. SSE streams are translated to SIGIL frames in real-time. Request data is not stored beyond the active session."
        , section "SIGIL Frames" "SIGIL frames contain verified tokens and metadata. Verification data includes confidence scores but not user-identifiable information."
        , section "Reset-on-Ambiguity" "When ambiguity resets occur, context windows are cleared. No request content is retained after the session ends."
        , section "ZeroMQ Transport" "SIGIL frames transmitted over ZeroMQ are encrypted in transit. We do not log frame content."
        , section "Provider Data" "API keys for upstream providers (OpenAI, Anthropic, etc.) are stored encrypted and never logged."
        , section "Contact" "Questions? Email privacy@straylight.software"
        ]
    ]

termsPage :: forall q i o m. H.Component q i o m
termsPage = H.mkComponent
  { initialState: const unit, render: const renderTerms, eval: H.mkEval H.defaultEval }

renderTerms :: forall w i. HH.HTML w i
renderTerms =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-8" ] ] [ HH.text "Terms of Service" ]
    , HH.span [ cls [ "inline-block px-3 py-1 bg-orange-400/10 text-orange-400 text-sm rounded-full mb-8" ] ] [ HH.text "omega//proxy" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Service Description" "omega//proxy provides verified inference proxy with SSE to SIGIL translation over ZeroMQ. Features include reset-on-ambiguity, 200-600% wire compression, and automatic tool call repair."
        , section "Acceptable Use" "omega//proxy is intended for legitimate LLM inference workloads. You may not use the service to circumvent provider rate limits or terms of service."
        , section "Self-Hosted License" "The self-hosted version of omega//proxy is MIT licensed. You may modify and distribute it freely."
        , section "Managed Service" "Managed hosting is provided on a subscription basis. Service level agreements are defined per plan tier."
        , section "Verification Disclaimer" "While omega//proxy provides verified inference, we do not guarantee the accuracy of LLM responses. Reset-on-ambiguity reduces but does not eliminate errors."
        , section "Provider Keys" "You are responsible for your own LLM provider API keys. omega//proxy does not provide API keys for upstream providers."
        , section "Contact" "Questions? Email legal@straylight.software"
        ]
    ]

contactPage :: forall q i o m. H.Component q i o m
contactPage = H.mkComponent
  { initialState: const unit, render: const renderContact, eval: H.mkEval H.defaultEval }

renderContact :: forall w i. HH.HTML w i
renderContact =
  HH.div
    [ cls [ "max-w-[800px] mx-auto px-6 py-24 text-center" ] ]
    [ HH.span [ cls [ "inline-block px-3 py-1 bg-orange-400/10 text-orange-400 text-sm rounded-full mb-6" ] ] [ HH.text "omega//proxy" ]
    , HH.h1 [ cls [ "text-3xl font-bold text-text mb-4" ] ] [ HH.text "Contact" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Get in touch with the omega//proxy team." ]
    , HH.div [ cls [ "space-y-4" ] ]
        [ HH.div_
            [ HH.p [ cls [ "text-muted-foreground text-sm mb-1" ] ] [ HH.text "General inquiries" ]
            , HH.a [ HP.href "mailto:hello@straylight.software", cls [ "text-orange-400 hover:text-orange-300" ] ] 
                [ HH.text "hello@straylight.software" ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-muted-foreground text-sm mb-1" ] ] [ HH.text "Enterprise sales" ]
            , HH.a [ HP.href "mailto:enterprise@straylight.software", cls [ "text-orange-400 hover:text-orange-300" ] ] 
                [ HH.text "enterprise@straylight.software" ]
            ]
        , HH.div_
            [ HH.p [ cls [ "text-muted-foreground text-sm mb-1" ] ] [ HH.text "Technical support" ]
            , HH.a [ HP.href "mailto:support@straylight.software", cls [ "text-orange-400 hover:text-orange-300" ] ] 
                [ HH.text "support@straylight.software" ]
            ]
        ]
    ]

section :: forall w i. String -> String -> HH.HTML w i
section title content =
  HH.div_
    [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text content ]
    ]
