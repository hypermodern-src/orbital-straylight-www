module Orbital.Pages.Cache (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "phero"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "phero-head"
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "eyebrow"
                , HP.attr (HH.AttrName "data-reveal") ""
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
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "nm"
                    ]
                    [ HH.text "cache"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "badge2 is-accent"
                    , HP.attr (HH.AttrName "data-orbital") "badge"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "badge2-dot"
                        ]
                        []
                    , HH.text "public release Aug 2026, target"
                    ]
                ]
            , HH.element (HH.ElemName "h1")
                [ HP.attr (HH.AttrName "data-reveal") ""
                ]
                [ HH.text "Storage that never takes an artifact's word for it."
                ]
            ]
        , HH.element (HH.ElemName "div")
            []
            [ HH.element (HH.ElemName "p")
                [ HP.attr (HH.AttrName "class") "sub"
                , HP.attr (HH.AttrName "data-reveal") ""
                , HP.attr (HH.AttrName "style") "margin-top:0"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "CACHE"
                    ]
                , HH.text " is verified binary storage: a store for build artifacts that re-verifies every artifact each time it is fetched, so nothing tampered with ever enters your build."
                ]
            , HH.element (HH.ElemName "form")
                [ HP.attr (HH.AttrName "class") "ea-form"
                , HP.attr (HH.AttrName "id") "early-access"
                , HP.attr (HH.AttrName "data-waitlist") "cache"
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
                [ HP.attr (HH.AttrName "class") "hero-note"
                , HP.attr (HH.AttrName "data-reveal") ""
                ]
                [ HH.text "Launches August 2026, target. At launch the free tier has every feature, gated on usage."
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
                [ HP.attr (HH.AttrName "class") "meta"
                , HP.attr (HH.AttrName "data-reveal") ""
                ]
                [ HH.element (HH.ElemName "span")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Docs"
                        ]
                    , HH.text " one click away"
                    ]
                , HH.element (HH.ElemName "span")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Seats"
                        ]
                    , HH.text " free"
                    ]
                , HH.element (HH.ElemName "span")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "SSO"
                        ]
                    , HH.text " included on every tier"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "hero-visual"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "clone"
                , HP.attr (HH.AttrName "data-orbital") "clone"
                ]
                [ HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "clone-h"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "lbl"
                        ]
                        [ HH.text "One line to adopt"
                        ]
                    , HH.element (HH.ElemName "div")
                        [ HP.attr (HH.AttrName "class") "clone-tabs"
                        ]
                        [ HH.element (HH.ElemName "button")
                            [ HP.attr (HH.AttrName "class") "on"
                            , HP.attr (HH.AttrName "data-pane") "nix"
                            ]
                            [ HH.text "nix"
                            ]
                        , HH.element (HH.ElemName "button")
                            [ HP.attr (HH.AttrName "data-pane") "bazel"
                            ]
                            [ HH.text "bazel"
                            ]
                        ]
                    ]
                , HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "clone-body"
                    , HP.attr (HH.AttrName "data-pane-for") "nix"
                    ]
                    [ HH.element (HH.ElemName "code")
                        []
                        [ HH.text "extra-substituters = https://cache.orbital.example"
                        ]
                    , HH.element (HH.ElemName "button")
                        [ HP.attr (HH.AttrName "class") "copybtn"
                        ]
                        [ HH.text "Copy"
                        ]
                    ]
                , HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "clone-body"
                    , HP.attr (HH.AttrName "data-pane-for") "bazel"
                    , HP.attr (HH.AttrName "hidden") ""
                    ]
                    [ HH.element (HH.ElemName "code")
                        []
                        [ HH.text "build --remote_cache=grpcs://cache.orbital.example"
                        ]
                    , HH.element (HH.ElemName "button")
                        [ HP.attr (HH.AttrName "class") "copybtn"
                        ]
                        [ HH.text "Copy"
                        ]
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "claim-slot"
                ]
                [ HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "ck"
                    ]
                    [ HH.text "Measured claim · pending"
                    ]
                , HH.element (HH.ElemName "p")
                    []
                    [ HH.text "This slot ships with one measured performance figure and a link to the methodology behind it. Benchmarks are being finalized for the public release; we do not publish numbers we have not measured."
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
            [ HH.text "Why verified storage"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "grid-cards3"
        , HP.attr (HH.AttrName "data-reveal-stagger") "70"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass card3 feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "a"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Checked on every fetch"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Most artifact stores verify an upload once, then trust the bytes forever. CACHE re-checks the cryptographic signature every single time an artifact is served. If storage was tampered with after upload, the fetch fails instead of your build."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass card3 feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "b"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Addressed by content"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Artifacts are named by what they contain, not where they sit. Identical outputs are stored once, references cannot silently change meaning, and two teams building the same thing share the same cache hit."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass card3 feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "fk"
                ]
                [ HH.text "c"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Drop-in"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "CACHE speaks the standard remote-cache interfaces of the tools you already run. Adopting it is one line of configuration; removing it is deleting that line. No migration project on either end."
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
            [ HH.text "Benchmarks"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "statband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "st"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "v"
                ]
                [ HH.text "TBD"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "k"
                ]
                [ HH.text "Cold fetch, p50"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "st"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "v"
                ]
                [ HH.text "TBD"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "k"
                ]
                [ HH.text "Warm fetch, p50"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "st"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "v"
                ]
                [ HH.text "TBD"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "k"
                ]
                [ HH.text "Upload throughput"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "st"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "v"
                ]
                [ HH.text "TBD"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "k"
                ]
                [ HH.text "Verification overhead"
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "metalist"
        , HP.attr (HH.AttrName "data-reveal") ""
        , HP.attr (HH.AttrName "style") "margin-top:1.2rem"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Status"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Figures publish with the August release. Each will be labeled "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "measured"
                    ]
                , HH.text " and link to its basis."
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
                [ HH.text "Published, reproducible methodology: pinned hardware, pinned workloads, raw logs, and the harness to rerun the whole suite yourself."
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
            [ HH.text "Quickstart"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "steps"
        , HP.attr (HH.AttrName "data-reveal-stagger") "70"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass step"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "sn"
                ]
                [ HH.text "1"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Create an account"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Sign up free, no credit card. One Orbital account covers CACHE and every other Orbital product."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "codeblk"
                , HP.attr (HH.AttrName "data-lang") "shell"
                ]
                [ HH.element (HH.ElemName "code")
                    []
                    [ HH.text "orbital login"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass step"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "sn"
                ]
                [ HH.text "2"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Add the config line"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Point your build tool at your cache. That is the whole integration."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "codeblk"
                , HP.attr (HH.AttrName "data-lang") "conf"
                ]
                [ HH.element (HH.ElemName "code")
                    []
                    [ HH.text "extra-substituters = https://cache.orbital.example"
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass step"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "sn"
                ]
                [ HH.text "3"
                ]
            , HH.element (HH.ElemName "h3")
                []
                [ HH.text "Build"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Your next build pushes and pulls verified artifacts. Every fetch is checked before it is handed to you."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "codeblk"
                , HP.attr (HH.AttrName "data-lang") "shell"
                ]
                [ HH.element (HH.ElemName "code")
                    []
                    [ HH.text "nix build # or: bazel build //..."
                    ]
                ]
            ]
        ]
    , HH.element (HH.ElemName "p")
        [ HP.attr (HH.AttrName "class") "qs-note"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.text "Commands shown are illustrative until the docs publish with the release; the final quickstart ships alongside them. "
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
            [ HH.text "Better together"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "glass xsell"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "xn"
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
            [ HH.element (HH.ElemName "b")
                []
                [ HH.text "BUILD"
                ]
            , HH.text ", the typed build system, uses CACHE natively: same account, same bill, one more config line. If you adopt BUILD later, it reads your real build graph and tells you, from your own data, where caching saves you the most."
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "link-cta"
            , HP.attr (HH.AttrName "href") "build.html"
            ]
            [ HH.text "See BUILD"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "sh"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "n"
            ]
            [ HH.text "05"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "Look for yourself"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "trust"
        , HP.attr (HH.AttrName "data-reveal-stagger") "60"
        ]
        [ HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass orbital-lift"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "https://github.com/sensenet-ai"
            , HP.attr (HH.AttrName "target") "_blank"
            , HP.attr (HH.AttrName "rel") "noopener"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "tk"
                ]
                [ HH.text "GitHub"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "td"
                ]
                [ HH.text "Source and issue tracker, in the open."
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass orbital-lift"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "#"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "tk"
                ]
                [ HH.text "Changelog"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "td"
                ]
                [ HH.text "Every release, public and dated."
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass orbital-lift"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "#"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "tk"
                ]
                [ HH.text "Status"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "td"
                ]
                [ HH.text "Live service status and incident history."
                ]
            ]
        , HH.element (HH.ElemName "a")
            [ HP.attr (HH.AttrName "class") "glass orbital-lift"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "href") "#"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "tk"
                ]
                [ HH.text "Licenses"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "td"
                ]
                [ HH.text "What is open source and under which license."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "One config line away."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "Shipping August 2026, target. Join the early-access list and be first in the door."
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
