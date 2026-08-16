-- | sensenet//confirm Features Page
-- | CI with proof obligations - feature showcase
module Straylight.Pages.Products.SensenetConfirm.Features 
  ( featuresPage
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

featuresPage :: forall q i o m. H.Component q i o m
featuresPage = H.mkComponent
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
    , proofObligations
    , typedPipelines
    , agentReview
    , attestation
    , parallelExecution
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
        [ HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Everything CI,"
            , HH.br_
            , HH.text "nothing broken"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Typed Dhall pipelines. Proof obligations. Agent code review. Cryptographic attestation. All backed by reproducible builds." ]
        ]
    ]

-- ============================================================
-- PROOF OBLIGATIONS
-- ============================================================

proofObligations :: forall w i. HH.HTML w i
proofObligations =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Proof Obligations"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Verify before merge" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every pipeline step carries preconditions and postconditions. Proofs are checked at merge time, not after deployment. If the proof doesn't hold, the merge is blocked." ]
                , featureList
                    [ "Preconditions and postconditions on every step"
                    , "Automatic proof checking at merge time"
                    , "Integration with formal verification tools"
                    , "Custom proof obligations for domain-specific invariants"
                    , "Proof caching for faster incremental builds"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ codeBlock
                    [ codeLine "" "Pipeline.step {"
                    , codeLine "" "  name = \"deploy\","
                    , codeLine "" "  run = \"kubectl apply -f manifests/\","
                    , codeLine "" "  "
                    , codeLine "  -- " "Preconditions"
                    , codeLine "" "  requires = ["
                    , codeLine "" "    Proof.testsPass,"
                    , codeLine "" "    Proof.imageScanned,"
                    , codeLine "" "    Proof.reviewApproved 2"
                    , codeLine "" "  ],"
                    , codeLine "" "  "
                    , codeLine "  -- " "Postconditions"
                    , codeLine "" "  ensures = ["
                    , codeLine "" "    Proof.healthCheckPasses,"
                    , codeLine "" "    Proof.metricsStable 5m"
                    , codeLine "" "  ]"
                    , codeLine "" "}"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- TYPED PIPELINES
-- ============================================================

typedPipelines :: forall w i. HH.HTML w i
typedPipelines =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "-- " "pipeline.dhall"
                    , codeLine "" "let Pipeline = ./types.dhall"
                    , codeLine "" ""
                    , codeLine "" "let testStep : Pipeline.Step = Pipeline.step {"
                    , codeLine "" "  name = \"test\","
                    , codeLine "" "  run = \"cargo test --all-features\","
                    , codeLine "" "  cache = Pipeline.cache.cargo"
                    , codeLine "" "}"
                    , codeLine "" ""
                    , codeLine "" "let buildStep : Pipeline.Step = Pipeline.step {"
                    , codeLine "" "  name = \"build\","
                    , codeLine "" "  run = \"cargo build --release\","
                    , codeLine "" "  needs = [ testStep ]"
                    , codeLine "" "}"
                    , codeLine "" ""
                    , codeLine "" "in Pipeline.workflow {"
                    , codeLine "" "  steps = [ testStep, buildStep ]"
                    , codeLine "" "}"
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Typed Dhall Pipelines"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "No more YAML bugs" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Dhall's type system catches pipeline errors before they run. No string interpolation bugs. No indentation errors. Full IDE support with autocompletion and type checking." ]
                , featureList
                    [ "Compile-time type checking"
                    , "No string interpolation vulnerabilities"
                    , "Import and compose pipeline fragments"
                    , "IDE support with LSP"
                    , "Generate to YAML/JSON for migration"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- AGENT CODE REVIEW
-- ============================================================

agentReview :: forall w i. HH.HTML w i
agentReview =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Agent Code Review"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Higher burden for AI code" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "AI-generated commits are automatically detected and face stricter review requirements. Taint tracking follows code through the system. Untrusted sources require additional proof obligations." ]
                , featureList
                    [ "Automatic detection of AI-generated code"
                    , "Configurable review burden by source"
                    , "Taint tracking across the codebase"
                    , "Higher proof thresholds for untrusted sources"
                    , "Audit trail of code provenance"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ reviewStatus "Human commit" "standard" "2 approvals"
                    , reviewStatus "AI commit (Copilot)" "elevated" "3 approvals + security review"
                    , reviewStatus "External contributor" "elevated" "2 approvals + CLA"
                    , reviewStatus "Bot commit" "restricted" "4 approvals + proof"
                    ]
                ]
            ]
        ]
    ]

reviewStatus :: forall w i. String -> String -> String -> HH.HTML w i
reviewStatus source level requirement =
  HH.div
    [ cls [ "p-4 bg-background rounded-lg" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between mb-2" ] ]
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text source ]
        , HH.span
            [ cls [ "text-xs px-2 py-0.5 rounded"
                  , case level of
                      "standard" -> "bg-green-500/20 text-green-400"
                      "elevated" -> "bg-amber-400/20 text-amber-400"
                      _ -> "bg-red-500/20 text-red-400"
                  ]
            ]
            [ HH.text level ]
        ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text requirement ]
    ]

-- ============================================================
-- ATTESTATION
-- ============================================================

attestation :: forall w i. HH.HTML w i
attestation =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Cryptographic Attestation"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Every build is signed" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Post-quantum signatures on every artifact. Reproducible outputs anchored to input hashes. Full provenance chain from source to deployment." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ attestCard "Build Signing" "Every build step produces a signed attestation with post-quantum algorithms."
            , attestCard "Reproducibility" "Same inputs always produce same outputs. Content-addressed artifacts."
            , attestCard "Provenance Chain" "Full audit trail from commit to deployment with cryptographic proofs."
            ]
        ]
    ]

attestCard :: forall w i. String -> String -> HH.HTML w i
attestCard title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.h3 [ cls [ "text-text font-semibold mb-2" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- PARALLEL EXECUTION
-- ============================================================

parallelExecution :: forall w i. HH.HTML w i
parallelExecution =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Parallel Execution"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Scale to 256 cores" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Dependency-aware parallelization. Share-nothing isolation per job. CoW filesystem snapshots. Linear scaling without coordination overhead." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ statCard "256" "max cores"
            , statCard "< 100ms" "job startup"
            , statCard "0" "shared state"
            , statCard "CoW" "isolation"
            ]
        ]
    ]

statCard :: forall w i. String -> String -> HH.HTML w i
statCard value label =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.p [ cls [ "text-2xl font-bold text-amber-400 mb-1" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text label ]
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
            [ HH.text "Ready for provable CI?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start free. No credit card required. Unlimited public repos." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/confirm/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-amber-400 text-background font-medium rounded-md hover:bg-amber-400/90 transition-colors" ]
                ]
                [ HH.text "Get started free" ]
            , HH.a
                [ HP.href "/sensenet/confirm/docs"
                , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
                ]
                [ HH.text "Read the docs" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-amber-400/10 border border-amber-400/20 rounded-full text-amber-400 text-sm font-medium mb-4" ] ]
    [ HH.text label ]

featureList :: forall w i. Array String -> HH.HTML w i
featureList items =
  HH.ul
    [ cls [ "space-y-3" ] ]
    (map featureItem items)

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-amber-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
