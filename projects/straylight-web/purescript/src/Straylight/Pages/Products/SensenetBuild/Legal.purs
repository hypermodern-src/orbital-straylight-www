-- | sensenet//build Legal Pages
module Straylight.Pages.Products.SensenetBuild.Legal 
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
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Overview" "sensenet//build is operated by Straylight Software."
        , section "Contact" "Questions? Email privacy@straylight.software" ] ]

termsPage :: forall q i o m. H.Component q i o m
termsPage = H.mkComponent { initialState: const unit, render: const renderTerms, eval: H.mkEval H.defaultEval }

renderTerms :: forall w i. HH.HTML w i
renderTerms = HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-12" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-8" ] ] [ HH.text "Terms of Service" ]
    , HH.div [ cls [ "prose prose-invert max-w-none space-y-6" ] ]
        [ section "Last updated" "February 2026"
        , section "Service Description" "sensenet//build provides typed build system with formal verification."
        , section "Contact" "Questions? Email legal@straylight.software" ] ]

contactPage :: forall q i o m. H.Component q i o m
contactPage = H.mkComponent { initialState: const unit, render: const renderContact, eval: H.mkEval H.defaultEval }

renderContact :: forall w i. HH.HTML w i
renderContact = HH.div [ cls [ "max-w-[800px] mx-auto px-6 py-24 text-center" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-4" ] ] [ HH.text "Contact" ]
    , HH.a [ HP.href "mailto:hello@straylight.software", cls [ "text-green-400 hover:text-green-300" ] ] 
        [ HH.text "hello@straylight.software" ] ]

section :: forall w i. String -> String -> HH.HTML w i
section title txt = HH.div_
    [ HH.h2 [ cls [ "text-lg font-semibold text-text mb-2" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text txt ] ]
