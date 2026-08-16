module Orbital.Pages.Verification (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "v-hero"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "The verification path"
            ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "For software where one bug is the whole budget."
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Some teams buy tooling on speed and price. Others answer to auditors, regulators, or physics. If you build software for defense, aerospace, medical devices, or payments infrastructure, this page is your way in: not a signup form, a conversation with a founder."
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "cta"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "#"
                ]
                [ HH.text "Talk to a founder"
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn ghost"
                , HP.attr (HH.AttrName "href") "index.html"
                ]
                [ HH.text "Or explore the products"
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sh"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "n"
            ]
            [ HH.text "01"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "What we mean by verified"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "pull"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.text "Testing tries some inputs and hopes. Formal verification is a mathematical proof, checked by a computer, that the software does what its specification says for all inputs."
        , HH.element (HH.ElemName "cite")
            []
            [ HH.text "Why it matters when the cost of failure is existential"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "metalist"
        , HP.attr (HH.AttrName "data-reveal") ""
        , HP.attr (HH.AttrName "style") "margin-top:2rem"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Storage"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "CACHE"
                    ]
                , HH.text " re-verifies every artifact on every fetch. For an auditor, that is a checkable chain of custody for every binary that entered a build."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Builds"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "BUILD"
                    ]
                , HH.text " makes the assembly of your software a typed, machine-checked description instead of a script someone once wrote. What passed the check is what ran."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Evidence"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "The point of both, for this audience, is the paper trail: verifiable evidence of what was built, from what, and how, produced as a byproduct of your normal pipeline."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sh"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "n"
            ]
            [ HH.text "02"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "Who this is for"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sectors"
        , HP.attr (HH.AttrName "data-reveal-stagger") "60"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass sector"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "sk"
                ]
                [ HH.text "Defense"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Supply-chain integrity requirements that ordinary artifact stores were never designed to meet."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass sector"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "sk"
                ]
                [ HH.text "Aerospace"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Certification regimes where evidence of process is as load-bearing as the code itself."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass sector"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "sk"
                ]
                [ HH.text "Medical devices"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Software changes that must be traceable end to end, release after release."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass sector"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "sk"
                ]
                [ HH.text "Payments"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Financial infrastructure where a tampered dependency is a headline, not a bug ticket."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sh"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "n"
            ]
            [ HH.text "03"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "What we sell today, plainly"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "how"
        , HP.attr (HH.AttrName "data-reveal-stagger") "70"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "a"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Where specifications exist"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Our verification work today is for teams that already maintain formal or near-formal specifications and invariants. If you have the spec, we can check code against it by machine."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "b"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Scoped pilots first"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Engagements start as paid pilots with defined scope and success criteria, before general availability. You know exactly what is being proven and what is not."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "c"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "No inflated claims"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "We do not promise fully general, push-button proof of arbitrary code. When a capability is a target rather than a shipped fact, we say so, here and in contracts."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sh"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "n"
            ]
            [ HH.text "04"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "How it starts"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "metalist"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Step 1"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "A conversation with a founder. This sale is founder-led on purpose; you will not be handed to a sequence of account executives."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Step 2"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "A scoped, paid pilot against one of your real specifications, with agreed success criteria."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Step 3"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "If the pilot proves out, a contract shaped to your certification and procurement reality."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "Bring us a specification."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "Founder-led, scoped, and honest about what is proven versus promised."
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "cta"
            ]
            [ HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "#"
                ]
                [ HH.text "Talk to a founder"
                ]
            ]
        ]
    ]
