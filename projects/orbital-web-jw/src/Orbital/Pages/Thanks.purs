module Orbital.Pages.Thanks (content) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow"
    ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "tk-hero"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Early access"
            ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "You are on the list."
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "tk-pos"
            , HP.attr (HH.AttrName "data-reveal") ""
            , HP.attr (HH.AttrName "id") "tkPos"
            , HP.attr (HH.AttrName "hidden") ""
            ]
            []
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text "Expect a handful of emails between now and launch: what we are building, how the benchmarks are run, and one early-access offer before the public release. Reply to any of them; a founder reads the replies. Unsubscribe anytime."
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "tk-grid"
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass tk-card"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "Move up by bringing your team"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "Your personal link, for the teammates who share your build. Rewards stack as they join:"
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tk-linkrow"
                ]
                [ HH.element (HH.ElemName "code")
                    [ HP.attr (HH.AttrName "id") "tkLink"
                    ]
                    []
                , HH.element (HH.ElemName "button")
                    [ HP.attr (HH.AttrName "class") "copybtn"
                    , HP.attr (HH.AttrName "id") "tkCopyLink"
                    ]
                    [ HH.text "Copy"
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "tk-prog"
                ]
                [ HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "tk-track"
                    ]
                    [ HH.element (HH.ElemName "div")
                        [ HP.attr (HH.AttrName "class") "tk-fill"
                        , HP.attr (HH.AttrName "id") "tkFill"
                        ]
                        []
                    ]
                , HH.element (HH.ElemName "div")
                    [ HP.attr (HH.AttrName "class") "tk-marks"
                    ]
                    [ HH.element (HH.ElemName "span")
                        []
                        [ HH.text "0"
                        ]
                    , HH.element (HH.ElemName "span")
                        []
                        [ HH.text "1"
                        ]
                    , HH.element (HH.ElemName "span")
                        []
                        [ HH.text "2"
                        ]
                    , HH.element (HH.ElemName "span")
                        []
                        [ HH.text "3+"
                        ]
                    ]
                ]
            , HH.element (HH.ElemName "ul")
                [ HP.attr (HH.AttrName "class") "tk-rewards"
                , HP.attr (HH.AttrName "id") "tkRewards"
                ]
                [ HH.element (HH.ElemName "li")
                    [ HP.attr (HH.AttrName "data-at") "1"
                    ]
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "1 referral:"
                        ]
                    , HH.text " a boosted free-tier allowance for your first month at launch. Exact allowance publishes with pricing."
                    ]
                , HH.element (HH.ElemName "li")
                    [ HP.attr (HH.AttrName "data-at") "3"
                    ]
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "3 referrals:"
                        ]
                    , HH.text " access ahead of the public release, and a priority slot for the proof bot, which opens a pull request against your repo and reports before and after times measured on your own code. The proof bot is in development; planned, not yet shipped."
                    ]
                , HH.element (HH.ElemName "li")
                    []
                    [ HH.element (HH.ElemName "b")
                        []
                        [ HH.text "Both sides win:"
                        ]
                    , HH.text " rewards apply to the teammate who joins through your link too, not only to you. Details publish with pricing."
                    ]
                ]
            ]
        , HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "glass tk-card"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.element (HH.ElemName "h3")
                []
                [ HH.text "Tell the thread that sent you"
                ]
            , HH.element (HH.ElemName "p")
                []
                [ HH.text "If you found us where build pain was being discussed, this is ready to paste:"
                ]
            , HH.element (HH.ElemName "textarea")
                [ HP.attr (HH.AttrName "class") "tk-share"
                , HP.attr (HH.AttrName "id") "tkShare"
                , HP.attr (HH.AttrName "readonly") ""
                , HP.attr (HH.AttrName "rows") "4"
                ]
                []
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "ea-row"
                ]
                [ HH.element (HH.ElemName "button")
                    [ HP.attr (HH.AttrName "class") "copybtn"
                    , HP.attr (HH.AttrName "id") "tkCopyShare"
                    ]
                    [ HH.text "Copy text"
                    ]
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "copybtn"
                    , HP.attr (HH.AttrName "id") "tkShareX"
                    , HP.attr (HH.AttrName "target") "_blank"
                    , HP.attr (HH.AttrName "rel") "noopener"
                    ]
                    [ HH.text "Post on X"
                    ]
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "copybtn"
                    , HP.attr (HH.AttrName "id") "tkShareHn"
                    , HP.attr (HH.AttrName "target") "_blank"
                    , HP.attr (HH.AttrName "rel") "noopener"
                    ]
                    [ HH.text "Hacker News"
                    ]
                , HH.element (HH.ElemName "a")
                    [ HP.attr (HH.AttrName "class") "copybtn"
                    , HP.attr (HH.AttrName "id") "tkShareLi"
                    , HP.attr (HH.AttrName "target") "_blank"
                    , HP.attr (HH.AttrName "rel") "noopener"
                    ]
                    [ HH.text "LinkedIn"
                    ]
                ]
            ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.attr (HH.AttrName "class") "tk-next"
        , HP.attr (HH.AttrName "data-reveal") ""
        ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "metalist"
            ]
            [ HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "metarow"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "my"
                    ]
                    [ HH.text "Next"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "mt"
                    ]
                    [ HH.text "Watch for the first email; it confirms your spot and repeats your referral link."
                    ]
                ]
            , HH.element (HH.ElemName "div")
                [ HP.attr (HH.AttrName "class") "metarow"
                ]
                [ HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "my"
                    ]
                    [ HH.text "Sooner"
                    ]
                , HH.element (HH.ElemName "span")
                    [ HP.attr (HH.AttrName "class") "mt"
                    ]
                    [ HH.text "Regulated or safety-critical team? Skip the line: "
                    , HH.element (HH.ElemName "a")
                        [ HP.attr (HH.AttrName "href") "verification.html"
                        , HP.attr (HH.AttrName "style") "color:var(--accent)"
                        ]
                        [ HH.text "talk to a founder"
                        ]
                    , HH.text "."
                    ]
                ]
            ]
        ]
    ]
