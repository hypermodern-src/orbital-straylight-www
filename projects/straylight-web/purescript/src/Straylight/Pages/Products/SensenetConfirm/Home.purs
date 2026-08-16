-- | sensenet//confirm Home Page
-- | CI with proof obligations landing page
module Straylight.Pages.Products.SensenetConfirm.Home 
  ( homePage
  , render
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

homePage :: forall q i o m. H.Component q i o m
homePage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-amber-400/10 border border-amber-400/20 rounded-full text-amber-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-amber-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "CI that "
            , HH.span [ cls [ "text-amber-400" ] ] [ HH.text "proves" ]
            , HH.br_
            , HH.text "correctness"
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Typed Dhall pipelines. Proof obligations on every merge. Agent-generated code faces higher review burden. Not another YAML parser with retry logic." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/confirm/pricing" "Start for free"
            , secondaryButton "/sensenet/confirm/docs" "Read the docs"
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-12 text-sm text-muted-foreground" ] ]
            [ HH.text "Trusted by teams who care about correctness" ]
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
                [ HH.text "Why sensenet//confirm?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built by engineers who understand that CI is a security boundary, not a script runner." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "?" "Proof obligations" 
                "Every pipeline step carries preconditions and postconditions. Proofs checked at merge time."
            , featureCard "{}" "Typed Dhall pipelines"
                "No YAML. No string interpolation bugs. Dhall's type system catches pipeline errors before they run."
            , featureCard "!" "Agent code review"
                "AI-generated commits face stricter review burden. Automatic taint tracking for untrusted sources."
            , featureCard "#" "Cryptographic attestation"
                "Every build step signed. Reproducible outputs anchored to input hashes. Post-quantum signatures."
            , featureCard "||" "Parallel execution"
                "Dependency-aware parallelization. Share-nothing isolation per job. Linear scaling to 256 cores."
            , featureCard "=" "Reproducible CI"
                "Hermetic builds by default. Nix integration. Content-addressed caching."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-amber-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-amber-400 mb-4 font-mono" ] ]
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
                [ HH.text "The provable CI platform" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others run YAML and hope for the best. We verify correctness before deployment." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-amber-400 font-bold" ] ] [ HH.text "confirm" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "GH Actions" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "CircleCI" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Jenkins" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Pipeline language" "Typed Dhall" "YAML" "YAML" "Groovy"
                    , comparisonRow "Proof obligations" "built-in" "no" "no" "no"
                    , comparisonRow "Agent code review" "automatic" "no" "no" "no"
                    , comparisonRow "Build attestation" "post-quantum" "SLSA" "no" "no"
                    , comparisonRow "Reproducibility" "hermetic" "best-effort" "best-effort" "no"
                    , comparisonRow "Type checking" "compile-time" "runtime" "runtime" "runtime"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on default configurations as of Feb 2026." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us gha circleci jenkins =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-amber-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell gha ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell circleci ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell jenkins ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ if value == "no" then "text-muted-foreground/50" else "text-muted-foreground" ] ]
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
                [ HH.text "Get started in 60 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install the CLI"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-confirm"
            , HH.text "\n"
            , codeLine "# " "Initialize pipeline"
            , codeLine "$ " "confirm init"
            , HH.text "\n"
            , codeLine "# " "Define typed pipeline (pipeline.dhall)"
            , codeLine "" "let Pipeline = ./types.dhall"
            , codeLine "" "in Pipeline.build {"
            , codeLine "" "  steps = [ Pipeline.step { name = \"test\", run = \"cargo test\" } ],"
            , codeLine "" "  proofs = [ Pipeline.proof.testsPass ]"
            , codeLine "" "}"
            , HH.text "\n"
            , codeLine "# " "Run with proof checking"
            , codeLine "$ " "confirm run --verify"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/confirm/docs/quickstart"
                , cls [ "text-amber-400 hover:text-amber-400/80 transition-colors" ]
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
            [ HH.text "Ready for CI that actually works?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Free tier includes unlimited public repos. No credit card required." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/confirm/pricing" "Create free account"
            , secondaryButton "/sensenet/confirm/pricing" "See all plans"
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
    , cls [ "inline-flex items-center justify-center px-8 py-4 bg-amber-400 text-background font-medium rounded-md hover:bg-amber-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
