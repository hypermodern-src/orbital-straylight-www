module Orbital.Pages.Build (content) where

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
                    [ HH.text "build"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "badge2 is-accent"
                    , HP.attr (HH.AttrName "data-orbital") "badge"
                    ]
                    [ HH.element (HH.ElemName "span")
                        [ HP.attr (HH.AttrName "class") "badge2-dot"
                        ]
                        []
                    , HH.text "public release Sep 2026, target"
                    ]
                ]
            , HH.element (HH.ElemName "h1")
                [ HP.attr (HH.AttrName "data-reveal") ""
                ]
                [ HH.text "You have the build system. This is the platform behind it."
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
                    [ HH.text "BUILD"
                    ]
                , HH.text ", the typed build system, is free to use and always will be. An Orbital account connects it to the platform: verified artifacts your whole team reuses, capacity that grows past one machine, and guarantees when the stakes ask for them."
                ]
            , HH.element (HH.ElemName "form")
                [ HP.attr (HH.AttrName "class") "ea-form"
                , HP.attr (HH.AttrName "id") "early-access"
                , HP.attr (HH.AttrName "data-waitlist") "build"
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
                        , HP.attr (HH.AttrName "href") "pricing.html"
                        ]
                        [ HH.text "See pricing"
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
                [ HH.text "Launches September 2026, target. Every feature on every tier; you pay for capacity, never capability."
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
                , HH.element (HH.ElemName "span")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Docs"
                        ]
                    , HH.text " one click away"
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
                        [ HH.text "Connect your account, one line"
                        ]
                    , HH.element (HH.ElemName "div")
                        [ HP.attr (HH.AttrName "class") "clone-tabs"
                        ]
                        [ HH.element (HH.ElemName "button")
                            [ HP.attr (HH.AttrName "class") "on"
                            , HP.attr (HH.AttrName "data-pane") "cli"
                            ]
                            [ HH.text "cli"
                            ]
                        , HH.element (HH.ElemName "button")
                            [ HP.attr (HH.AttrName "data-pane") "ci"
                            ]
                            [ HH.text "ci"
                            ]
                        ]
                    ]
                , HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "clone-body"
                    , HP.attr (HH.AttrName "data-pane-for") "cli"
                    ]
                    [ HH.element (HH.ElemName "code")
                        []
                        [ HH.text "orbital login"
                        ]
                    , HH.element (HH.ElemName "button")
                        [ HP.attr (HH.AttrName "class") "copybtn"
                        ]
                        [ HH.text "Copy"
                        ]
                    ]
                , HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "clone-body"
                    , HP.attr (HH.AttrName "data-pane-for") "ci"
                    , HP.attr (HH.AttrName "hidden") ""
                    ]
                    [ HH.element (HH.ElemName "code")
                        []
                        [ HH.text "run: orbital build"
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
        [ HP.attr (HH.AttrName "class") "gh-strip"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "span")
            [ HP.attr (HH.AttrName "class") "gk"
            ]
            [ HH.text "Coming from GitHub?"
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "Everything in the repository stays free. Nothing on this page takes features away from the tool you already run; an account adds the hosted layer around it."
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
            [ HH.text "What an account adds"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "plusgrid"
        , HP.attr (HH.AttrName "data-reveal-stagger") "70"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass plus"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pk"
                ]
                [ HH.element (HH.ElemName "h3")
                    []
                    [ HH.text "Your team stops rebuilding each other's work"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "tier-tag"
                    ]
                    [ HH.text "free and up"
                    ]
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Connect BUILD to "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "CACHE"
                    ]
                , HH.text ", verified binary storage, and an artifact any teammate or CI job has built, nobody builds again: everyone else pulls it in seconds, re-verified on every fetch so nothing tampered with ever enters a build. This is the speedup the tool alone cannot give you; it only exists with an account."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Free tier:"
                    ]
                , HH.text " usage allowance TBD · paid tiers raise it"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass plus"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pk"
                ]
                [ HH.element (HH.ElemName "h3")
                    []
                    [ HH.text "Capacity that grows with you"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "tier-tag"
                    ]
                    [ HH.text "team"
                    ]
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "The free tier is sized for individuals and small projects. Paid tiers raise throughput and concurrency so busy repositories never queue behind their own success: more simultaneous builds, more transfer, no feature differences."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Allowances:"
                    ]
                , HH.text " TBD, publish before general availability"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass plus"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pk"
                ]
                [ HH.element (HH.ElemName "h3")
                    []
                    [ HH.text "History that stays around"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "tier-tag"
                    ]
                    [ HH.text "team"
                    ]
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Paid tiers keep artifacts and build history longer. When a release from months ago needs rebuilding, auditing, or bisecting, the evidence is still there instead of aged out."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Retention windows:"
                    ]
                , HH.text " TBD, publish before general availability"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass plus"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pk"
                ]
                [ HH.element (HH.ElemName "h3")
                    []
                    [ HH.text "Guarantees in writing"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "tier-tag"
                    ]
                    [ HH.text "enterprise"
                    ]
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "When builds are on the critical path of your business, Enterprise adds service-level agreements, priority support, and enterprise controls, priced to your footprint rather than a rate card."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "pfoot"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Also:"
                    ]
                , HH.text " the "
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "href") "verification.html"
                    , HP.attr (HH.AttrName "style") "color:var(--accent)"
                    ]
                    [ HH.text "verification path"
                    ]
                , HH.text " for regulated and safety-critical teams"
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
            [ HH.text "What we never charge for"
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
                [ HH.text "The tool"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "BUILD itself."
                    ]
                , HH.text " The typed build system you cloned is complete. There is no crippled community edition; the paid product is the platform around it, not a better binary."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Features"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Every feature, every tier."
                    ]
                , HH.text " Tiers change how much account you get: throughput, retention, guarantees. Never which capabilities you may use."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Seats"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "Unlimited, free."
                    ]
                , HH.text " Add your whole team on day one; you pay for what the account uses, not who logs in."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Security"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.element (HH.ElemName "b")
                    []
                    [ HH.text "No SSO tax."
                    ]
                , HH.text " Single sign-on and audit logs are included at every tier, including Free. Security basics are not an upsell."
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
            [ HH.text "Upgrade on your own numbers"
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
                [ HH.text "Receipts, not pressure"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "When you approach the free allowance, Orbital shows what it measured for your account that month: hours of rebuilding avoided, what that usage would cost on each tier. Measured from your builds, never estimated."
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
                [ HH.text "Advice from your build graph"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "BUILD sees which artifacts you rebuild that you could be fetching. When caching or more capacity would actually save you time, it says so inside the product, with your own figures attached."
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
                [ HH.text "Nothing degrades silently"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Hitting a limit never corrupts or slows a build behind your back. You see the receipt, you decide. Downgrading is as easy as upgrading, and your tool keeps working either way."
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
                [ HH.text "Clean build, reference repo"
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
                [ HH.text "Incremental rebuild"
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
                [ HH.text "Check time"
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
                [ HH.text "Cache hit rate, with CACHE"
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
                [ HH.text "Figures publish with the September release. Each will be labeled "
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
            [ HH.text "05"
            ]
        , HH.element (HH.ElemName "h2")
            []
            [ HH.text "From clone to connected"
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
                [ HH.text "Free, no credit card. One Orbital account covers BUILD, CACHE, and every Orbital product that follows."
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
                [ HH.text "Connect your repository"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Point the tool you already run at your account. Existing build descriptions keep working unchanged."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "codeblk"
                , HP.attr (HH.AttrName "data-lang") "shell"
                ]
                [ HH.element (HH.ElemName "code")
                    []
                    [ HH.text "orbital build init"
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
                [ HH.text "Build once, as a team"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "From the next build on, verified artifacts are shared: what any teammate or CI job built, everyone else fetches."
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "codeblk"
                , HP.attr (HH.AttrName "data-lang") "shell"
                ]
                [ HH.element (HH.ElemName "code")
                    []
                    [ HH.text "orbital build"
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
            [ HH.text "06"
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
                [ HH.text "The source you came from, and the issue tracker."
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
                [ HH.text "What is open and under which license."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "Keep the tool. Add the platform."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "Shipping September 2026, target. Join the early-access list; upgrade later only when your own receipts say it pays."
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
                [ HH.text "Compare tiers"
                ]
            ]
        ]
    ]
