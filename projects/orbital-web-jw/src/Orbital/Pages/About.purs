module Orbital.Pages.About (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "ab-hero"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "The company"
            ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Software infrastructure that proves what it ships."
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "b")
                []
                [ HH.text "Orbital"
                ]
            , HH.text " builds developer infrastructure for the age of AI-written software: storage that re-verifies every build artifact it serves, a build system whose own logic is machine-checked, and a CI runner to follow. Founded in 2026, based in San Juan, Puerto Rico."
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
            [ HH.text "The problem we work on"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ab-prose"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "p")
            []
            [ HH.text "AI writes code fast now, but the pipeline that assembles, tests, and checks that code was built for human speed. That pipeline has become the industry's bottleneck: too slow for agent output, increasingly expensive, and it still ships bugs, because conventional testing only samples behavior rather than proving it. The build-and-test tooling market is roughly $2.1B, growing about 21% a year (industry analyst estimates), and agent-written code multiplies the demand on it."
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "style") "margin-top:1rem"
            ]
            [ HH.text "Orbital's answer is infrastructure that verifies instead of trusts. Our tools are for two audiences: software teams who want faster, cheaper builds that they can adopt by changing one line of configuration, and regulated or safety-critical organizations, in fields like aerospace, medical devices, and payments, for whom evidence of what was built and how is a compliance requirement, served through a "
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "href") "verification.html"
                , HP.attr (HH.AttrName "style") "color:var(--accent)"
                ]
                [ HH.text "dedicated verification path"
                ]
            , HH.text "."
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
                [ HH.text "Founded"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "2026"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Based"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "San Juan, Puerto Rico"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Stage"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Products built and in private development; early access open now; first public releases target August and September 2026."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Industry"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Developer tools; continuous integration, build systems, and software verification."
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
            [ HH.text "The team"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "team"
        , HP.attr (HH.AttrName "data-reveal-stagger") "80"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass member"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mn"
                ]
                [ HH.text "Jesse Wilson"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mr"
                ]
                [ HH.text "Chief Executive Officer"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Fifteen-plus years scaling consumer software businesses. At Avast, grew a mobile portfolio from $1.8M to $100M in annual revenue, served on the four-person executive team that integrated a $1.4B acquisition, and held enterprise contracts with Verizon, AT&T, and T-Mobile. Previously VP of Product at Grindr, where revenue grew from $3M to $20M, and a Principal Group Program Manager at Microsoft, where his organization shipped AI writing features ahead of Salesforce and Adobe. Has directed more than 500 engineers across his career."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mfoot"
                ]
                [ HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "link-cta"
                    , HP.attr (HH.AttrName "href") "https://www.linkedin.com/in/jessewilsonusc/"
                    , HP.attr (HH.AttrName "target") "_blank"
                    , HP.attr (HH.AttrName "rel") "noopener"
                    ]
                    [ HH.text "LinkedIn"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass member"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mn"
                ]
                [ HH.text "Ben Reesman"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mr"
                ]
                [ HH.text "Chief Technology Officer"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Eight years as a senior engineer and engineering manager at Facebook through its hypergrowth years, building infrastructure credited with more than $50B in attributed revenue and managing more than 30 engineers. Has built trading systems measured in millionths of a second. Creator of Orbital's entire technical foundation, with an active working relationship with NVIDIA's deep-learning leadership."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "mfoot"
                ]
                [ HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "link-cta"
                    , HP.attr (HH.AttrName "href") "https://www.linkedin.com/in/benreesman/"
                    , HP.attr (HH.AttrName "target") "_blank"
                    , HP.attr (HH.AttrName "rel") "noopener"
                    ]
                    [ HH.text "LinkedIn"
                    ]
                ]
            ]
        ]
    , HH.element (HH.ElemName "p")
        [ HP.attr (HH.AttrName "class") "team-note"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.text "Career figures are founder-reported."
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
            [ HH.text "What we are building"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "prow"
            , HP.attr (HH.AttrName "href") "cache.html"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pn"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "ns"
                    ]
                    [ HH.text "ORBITAL"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "sep"
                    ]
                    [ HH.text "//"
                    ]
                , HH.text "cache"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Verified binary storage: an artifact store that re-verifies content every time it is fetched, so nothing tampered with ever enters a build. Built; public release targets August 2026."
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pl"
                ]
                [ HH.text "Details →"
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "prow"
            , HP.attr (HH.AttrName "href") "build.html"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pn"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "ns"
                    ]
                    [ HH.text "ORBITAL"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "sep"
                    ]
                    [ HH.text "//"
                    ]
                , HH.text "build"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "The typed build system: describes how software is assembled, with the build logic itself machine-checked before it runs. Built; public release targets September 2026."
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pl"
                ]
                [ HH.text "Details →"
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "prow"
            , HP.attr (HH.AttrName "href") "index.html"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pn"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "ns"
                    ]
                    [ HH.text "ORBITAL"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "sep"
                    ]
                    [ HH.text "//"
                    ]
                , HH.text "confirm"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Orbital Confirm"
                    ]
                , HH.text ", a drop-in CI runner for existing GitHub Actions workflows. Built; public release targets late 2026."
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "pl"
                ]
                [ HH.text "Overview →"
                ]
            ]
        ]
    , HH.element (HH.ElemName "p")
        [ HP.attr (HH.AttrName "class") "team-note"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.text "Each product page carries feature detail, a quickstart, and the benchmark methodology. Product screenshots are being prepared and will appear there."
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "See it from the developer's side."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "Early access is open ahead of the first public release."
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "cta"
            ]
            [ HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "index.html#early-access"
                ]
                [ HH.text "Get early access"
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn"
                , HP.attr (HH.AttrName "href") "cache.html"
                ]
                [ HH.text "Explore CACHE"
                ]
            ]
        ]
    ]
