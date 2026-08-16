module Orbital.Pages.Index (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "hero-orb"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Verified developer infrastructure"
            ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-split") "char"
            , HP.attr (HH.AttrName "data-split-step") "36"
            ]
            [ HH.text "ORBITAL"
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "sub"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Infrastructure that proves itself."
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Most developer tools ask for your trust. Orbital products are built so they do not have to: storage that re-checks every artifact it hands you, and builds whose own logic is machine-checked. One account, one subscription, and every product available on every tier."
            ]
        , HH.element (HH.ElemName "form")
            [ HP.attr (HH.AttrName "class") "ea-form"
            , HP.attr (HH.AttrName "id") "early-access"
            , HP.attr (HH.AttrName "data-waitlist") "platform"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "ea-fields"
                ]
                [ HH.element (HH.ElemName "input")
                    [ HP.attr (HH.AttrName "type") "email"
                    , HP.attr (HH.AttrName "name") "email"
                    , HP.attr (HH.AttrName "autocomplete") "email"
                    , HP.attr (HH.AttrName "inputmode") "email"
                    , HP.attr (HH.AttrName "required") ""
                    , HP.attr (HH.AttrName "placeholder") "you@company.com"
                    , HP.attr (HH.AttrName "aria-label") "Work email"
                    ]
                    []
                , HH.element (HH.ElemName "select")
                    [ HP.attr (HH.AttrName "name") "builds-with"
                    , HP.attr (HH.AttrName "autocomplete") "off"
                    , HP.attr (HH.AttrName "aria-label") "What do you build with"
                    ]
                    [ HH.element (HH.ElemName "option")
                        [ HP.attr (HH.AttrName "value") ""
                        , HP.attr (HH.AttrName "disabled") ""
                        , HP.attr (HH.AttrName "selected") ""
                        ]
                        [ HH.text "What do you build with? (optional)"
                        ]
                    , HH.element (HH.ElemName "option")
                        []
                        [ HH.text "Nix"
                        ]
                    , HH.element (HH.ElemName "option")
                        []
                        [ HH.text "Bazel or Buck2"
                        ]
                    , HH.element (HH.ElemName "option")
                        []
                        [ HH.text "GitHub Actions"
                        ]
                    , HH.element (HH.ElemName "option")
                        []
                        [ HH.text "Something else"
                        ]
                    , HH.element (HH.ElemName "option")
                        []
                        [ HH.text "Compliance or safety-critical work"
                        ]
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "ea-row"
                ]
                [ HH.element (HH.ElemName "button")
                    [ HP.attr (HH.AttrName "type") "submit"
                    , HP.attr (HH.AttrName "class") "btn primary"
                    ]
                    [ HH.text "Get early access"
                    ]
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "link-cta"
                    , HP.attr (HH.AttrName "href") "verification.html"
                    ]
                    [ HH.text "For regulated teams"
                    ]
                ]
            , HH.element (HH.ElemName "p")
                [ HP.attr (HH.AttrName "class") "ea-hint"
                ]
                [ HH.text "Referrals unlock launch rewards, including access ahead of the release."
                ]
            , HH.element (HH.ElemName "p")
                [ HP.attr (HH.AttrName "class") "ea-msg"
                , HP.attr (HH.AttrName "hidden") ""
                ]
                [ HH.text "That did not go through. Check the address and try again."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "ea-count"
            , HP.attr (HH.AttrName "data-waitlist-count") ""
            , HP.attr (HH.AttrName "hidden") ""
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "b")
                []
                []
            , HH.text " signups on the early-access list"
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "cta"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn"
                , HP.attr (HH.AttrName "href") "cache.html"
                ]
                [ HH.text "Explore CACHE"
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn"
                , HP.attr (HH.AttrName "href") "build.html"
                ]
                [ HH.text "Explore BUILD"
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "fam"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "fn"
            ]
            [ HH.element (HH.ElemName "b")
                []
                [ HH.text "ORBITAL"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "sl"
                ]
                [ HH.text "//"
                ]
            , HH.text "products"
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "fd"
            ]
            [ HH.text "Each product does one job. Adopting the next one is a config line, not a purchase."
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "suite-grid"
        , HP.attr (HH.AttrName "data-reveal-stagger") "60"
        ]
        [ HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass prod orbital-lift orbital-sweep"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "cache.html"
            ]
            [ HH.element (HH.ElemName "div")
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
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pt"
                ]
                [ HH.text "Verified binary storage"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pd"
                ]
                [ HH.text "An artifact store that re-verifies content every time it is fetched, so nothing tampered with ever enters your build."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pmeta"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "badge2 is-accent"
                    , HP.attr (HH.AttrName "data-orbital") "badge"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "badge2-dot"
                        ]
                        []
                    , HH.text "Aug 2026 target"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "parrow"
                    ]
                    [ HH.text "→"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass prod orbital-lift orbital-sweep"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "build.html"
            ]
            [ HH.element (HH.ElemName "div")
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
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pt"
                ]
                [ HH.text "The typed build system"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pd"
                ]
                [ HH.text "Describes how your software is assembled, and the build logic itself is checked by machine before it runs."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pmeta"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "badge2 is-accent"
                    , HP.attr (HH.AttrName "data-orbital") "badge"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "badge2-dot"
                        ]
                        []
                    , HH.text "Sep 2026 target"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "parrow"
                    ]
                    [ HH.text "→"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass prod soon"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
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
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pt"
                ]
                [ HH.text "The CI runner"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pd"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Orbital Confirm"
                    ]
                , HH.text " runs your existing GitHub Actions jobs on Orbital's engine. Change one label in your workflow file."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pmeta"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "badge2 is-warn"
                    , HP.attr (HH.AttrName "data-orbital") "badge"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "badge2-dot"
                        ]
                        []
                    , HH.text "late 2026 target"
                    ]
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
            [ HH.text "Two ways in"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "paths"
        , HP.attr (HH.AttrName "data-reveal-stagger") "80"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass path"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "Developers"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Self-serve, free to start, no credit card. The free tier is gated on how much you use, never on which features you get. Docs are one click from everywhere, and the quickstart is designed to be measured in minutes, not afternoons."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "link-cta"
                    , HP.attr (HH.AttrName "href") "cache.html"
                    ]
                    [ HH.text "Start with CACHE"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass path"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "Regulated and safety-critical teams"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "If a single bug costs more than years of tooling spend, you buy differently. The verification path covers machine-checked guarantees, evidence for auditors, and a direct line to the founders."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "link-cta"
                    , HP.attr (HH.AttrName "href") "verification.html"
                    ]
                    [ HH.text "The verification path"
                    ]
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
            [ HH.text "Numbers you can check"
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
                [ HH.text "Rule"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Every number on this site is labeled "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "measured"
                    ]
                , HH.text ", "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "target"
                    ]
                , HH.text ", or "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "estimate"
                    ]
                , HH.text ", with its basis linked. If we have not measured it, we do not publish it."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Method"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Benchmarks ship with a reproducible methodology: pinned hardware, pinned workloads, raw logs. You can rerun them."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Planned"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "A proof bot that opens a pull request against your repository changing one line of config, runs your build both ways, and reports before and after times measured on your own code. In development; this page will say when it is live."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "Be first in when it ships."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "One Orbital account covers every product. Early access opens before the public release."
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "cta"
            ]
            [ HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "#early-access"
                ]
                [ HH.text "Get early access"
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn"
                , HP.attr (HH.AttrName "href") "pricing.html"
                ]
                [ HH.text "See pricing"
                ]
            ]
        ]
    ]
