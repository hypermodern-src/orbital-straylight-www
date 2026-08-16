module Orbital.Pages.Pricing (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "pr-hero"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Pricing"
            ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "One subscription. Every product."
            ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Billing is platform-level: one Orbital account, one subscription, usage metered across products and itemized per product on your bill. Tiers change how much account you get, never which products you may use. Adopting a second product is a config line, not a purchase."
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "tiers"
        , HP.attr (HH.AttrName "data-reveal-stagger") "80"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass tier"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tn"
                ]
                [ HH.text "Free"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tp"
                ]
                [ HH.text "$0"
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "per"
                    ]
                    [ HH.text "forever"
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tt"
                ]
                [ HH.text "Every product, full-featured. Gated on how much you use, never on what you get."
                ]
            , HH.element (HH.ElemName "ul")
                []
                [ HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "All products"
                        ]
                    , HH.text " included"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Usage allowance:"
                        ]
                    , HH.text " TBD"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Retention:"
                        ]
                    , HH.text " TBD"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "SSO and audit logs included"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "Unlimited seats"
                    ]
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "index.html#early-access"
                ]
                [ HH.text "Get early access"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass tier hot"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tn"
                ]
                [ HH.text "Team"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tp"
                ]
                [ HH.text "$TBD"
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "per"
                    ]
                    [ HH.text "/ month + usage"
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tt"
                ]
                [ HH.text "Higher throughput and longer retention for teams shipping every day."
                ]
            , HH.element (HH.ElemName "ul")
                []
                [ HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "All products"
                        ]
                    , HH.text " included"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Throughput:"
                        ]
                    , HH.text " TBD"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Retention:"
                        ]
                    , HH.text " TBD"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "SSO and audit logs included"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "Unlimited seats"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "Usage itemized per product"
                    ]
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn primary"
                , HP.attr (HH.AttrName "href") "index.html#early-access"
                ]
                [ HH.text "Get early access"
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass tier"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tn"
                ]
                [ HH.text "Enterprise"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tp"
                ]
                [ HH.text "Custom"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tt"
                ]
                [ HH.text "Scale guarantees and enterprise controls, priced to your footprint."
                ]
            , HH.element (HH.ElemName "ul")
                []
                [ HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "All products"
                        ]
                    , HH.text " included"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Throughput and retention:"
                        ]
                    , HH.text " custom"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "SSO and audit logs included, like every tier"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "SLAs: TBD"
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.text "Deployment options: TBD"
                    ]
                ]
            , HH.element (HH.ElemName "a")
                [ HP.attr (HH.AttrName "class") "btn"
                , HP.attr (HH.AttrName "href") "verification.html"
                ]
                [ HH.text "Talk to a founder"
                ]
            ]
        ]
    , HH.element (HH.ElemName "p")
        [ HP.attr (HH.AttrName "class") "ph-note"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.text "Prices and allowances marked TBD are being finalized against measured cost data and publish before general availability. We do not print a number here until it is real."
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
            [ HH.text "How the bill works"
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
                [ HH.text "Products"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Every tier includes "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "every product"
                    ]
                , HH.text ". Tiers gate account-level things: throughput, retention, guarantees. Never features, never products."
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
                    [ HH.text "Free, always."
                    ]
                , HH.text " Add your whole team; you pay for what the account uses, not who logs in."
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
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Usage"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "Metered across products, "
                , HH.element (HH.ElemName "b")
                    []
                    [ HH.text "itemized per product"
                    ]
                , HH.text " on one bill. You always see which product spent what."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metarow"
            ]
            [ HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "my"
                ]
                [ HH.text "Receipts"
                ]
            , HH.element (HH.ElemName "span")
                [ HP.attr (HH.AttrName "class") "mt"
                ]
                [ HH.text "When you approach a limit, you see what Orbital measured for your account that month: what it saved you, in your numbers. Measured from your usage, never estimated."
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
            [ HH.text "Questions"
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "every"
        , HP.attr (HH.AttrName "data-reveal-stagger") "60"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "Do I subscribe per product?"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "No. One subscription covers CACHE, BUILD, INFER, and every Orbital product that ships after them. Adding a product to your account is a configuration change, not a checkout."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "What does the free tier hold back?"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Nothing functional. It is capped on consumption: how much you store, transfer, and run. Every feature, every product, SSO and audit logs included."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "What happens at the limit?"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "You get a usage receipt showing what the account used and what Orbital measured it saved you, and you choose whether to upgrade. Builds are never silently degraded."
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass feat"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "I have compliance requirements."
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "The verification path is for regulated and safety-critical teams: machine-checked guarantees, evidence for auditors, founder contact. "
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "href") "verification.html"
                    , HP.attr (HH.AttrName "style") "color:var(--accent)"
                    ]
                    [ HH.text "Start here"
                    ]
                , HH.text "."
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "ctaband"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "h2")
            []
            [ HH.text "Start free at launch. Upgrade when the usage says so."
            ]
        , HH.element (HH.ElemName "p")
            []
            [ HH.text "No credit card, no feature gates, unlimited seats. Early access opens before the public release."
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
                , HP.attr (HH.AttrName "href") "verification.html"
                ]
                [ HH.text "Talk to a founder"
                ]
            ]
        ]
    ]
