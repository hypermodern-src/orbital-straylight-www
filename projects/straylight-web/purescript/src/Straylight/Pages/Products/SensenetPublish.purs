-- | sensenet//publish Product Page
-- | Scope-graph Documentation
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetPublish where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock, inlineCode)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetPublishPage :: forall q i o m. H.Component q i o m
sensenetPublishPage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER (armory shape)
-- ============================================================

render :: forall w i. HH.HTML w i
render =
  HH.div_
    [ hero
    , features
    , comparison
    , quickstart
    , cta
    ]

-- ============================================================
-- HERO
-- ============================================================

hero :: forall w i. HH.HTML w i
hero =
  HH.section
    [ cls [ "py-24 md:py-32" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6 text-center" ] ]
        [ -- Badge
          HH.div
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-sky-400/10 border border-sky-400/20 rounded-full text-sky-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-sky-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Documentation that"
            , HH.br_
            , HH.span [ cls [ "text-sky-400" ] ] [ HH.text "actually resolves" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Scope-graph documentation. References resolve or the build fails. Cross-language. Machine-readable. Not another string-matching doc generator." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "https://github.com/straylight-software" "View source"
            ]
        , -- install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL publish.sensenet.dev | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#80ccff] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/sensenet-publish"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#80ccff] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-sky-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "Rustdoc, Haddock, TypeDoc, Doxygen"
            ]
        ]
    ]

-- ============================================================
-- FEATURES
-- ============================================================

features :: forall w i. HH.HTML w i
features =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Why sensenet//publish?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built by engineers who got tired of dead links and stale documentation." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "G" "Scope-graph analysis"
                "Full semantic understanding via scope graphs. Every reference tracked from definition to usage. No regex heuristics."
            , featureCard "~>" "Reference resolution"
                "Every cross-reference in your docs is verified at build time. Broken links fail the build. Zero dead references in production."
            , featureCard "{ }" "Cross-language"
                "Rust, Haskell, TypeScript, C++, Python, and more. Unified scope-graph representation across all supported languages."
            , featureCard "{}" "Machine-readable output"
                "JSON-LD, OpenAPI, and custom formats. Structured output for IDE plugins, search indexes, and downstream tooling."
            , featureCard "!" "Build-integrated"
                "Runs in your CI pipeline. Docs are artifacts, not afterthoughts. Version-pinned references across releases."
            , featureCard "?" "Semantic search"
                "Query by type signature, scope, or relationship. Find all callers of a function. Trace data flow through your codebase."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-sky-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-sky-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- COMPARISON
-- ============================================================

comparison :: forall w i. HH.HTML w i
comparison =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Documentation that understands code" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others parse comments and hope for the best. We build a complete semantic model of your codebase." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-sky-400 font-bold" ] ] [ HH.text "sensenet//publish" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Rustdoc" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Haddock" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "TypeDoc" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Doxygen" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Semantic model" "Scope-graph" "AST" "AST" "AST" "AST"
                    , comparisonRow "Cross-language" "yes" "no" "no" "no" "partial"
                    , comparisonRow "Reference validation" "build fails" "warnings" "no" "no" "warnings"
                    , comparisonRow "Machine-readable" "JSON-LD/OpenAPI" "JSON" "Hoogle" "JSON" "XML"
                    , comparisonRow "Type-aware search" "yes" "partial" "yes" "no" "no"
                    , comparisonRow "Scope queries" "yes" "no" "no" "no" "no"
                    , comparisonRow "Cross-reference graph" "full DAG" "intra-crate" "intra-pkg" "intra-pkg" "call graph"
                    , comparisonRow "Version tracking" "pinned refs" "no" "no" "no" "no"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on default configurations. Some features may be available via plugins or extensions." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us rustdoc haddock typedoc doxygen =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-sky-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell rustdoc ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell haddock ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell typedoc ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell doxygen ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ case value of
              "no" -> "text-muted-foreground/50"
              _ -> "text-muted-foreground"
          ]
    ]
    [ HH.text value ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstart :: forall w i. HH.HTML w i
quickstart =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-12" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Get started in 30 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install (Nix)"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-publish"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://publish.sensenet.dev/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Initialize in your project"
            , codeLine "$ " "sensenet-publish init"
            , HH.text "\n"
            , codeLine "# " "Build scope graph and generate docs"
            , codeLine "$ " "sensenet-publish build"
            , HH.text "\n"
            , codeLine "# " "Validate all references (CI mode)"
            , codeLine "$ " "sensenet-publish check --strict"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/publish/docs"
                , cls [ "text-sky-400 hover:text-sky-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide ->" ]
            ]
        ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]

-- ============================================================
-- CTA
-- ============================================================

cta :: forall w i. HH.HTML w i
cta =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6 text-center" ] ]
        [ HH.h2
            [ cls [ "text-3xl font-bold text-text mb-4" ] ]
            [ HH.text "Ready for docs that don't lie?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "sensenet//publish is in private beta. Join the waitlist for early access." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "/team" "Meet the team"
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

primaryButton :: forall w i. String -> String -> HH.HTML w i
primaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-sky-400 text-background font-medium rounded-md hover:bg-sky-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
