-- | sensenet//build Landing Page
module Straylight.Pages.Products.SensenetBuild.Home 
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-green-400/10 border border-green-400/20 rounded-full text-green-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-green-400 rounded-full animate-pulse" ] ] []
            , HH.text "Typed Build System"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Build systems that"
            , HH.br_
            , HH.span [ cls [ "text-green-400" ] ] [ HH.text "prove" ]
            , HH.text " themselves correct"
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Typed Dhall configurations. Lean4-proven derivations. Hermetic reproducibility with cryptographic attestation. Your build graph is a theorem." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/build/pricing" "Get started"
            , secondaryButton "/sensenet/build/docs" "Read the docs"
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-12 text-sm text-muted-foreground" ] ]
            [ HH.text "Replaces Bazel, Buck2, Nix expressions with mathematical certainty" ]
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
                [ HH.text "Why sensenet//build?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for engineers who demand mathematical certainty from their build infrastructure." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "lambda" "Dhall configuration" 
                "Total functions, no Turing-completeness, no escape hatches. Your config terminates or it doesn't typecheck."
            , featureCard "proof" "Lean4 proofs"
                "Derivation semantics formalized in Lean4. Build correctness is a proven property, not a hope."
            , featureCard "lock" "Hermetic builds"
                "Content-addressed filesystem sandbox. No network, no ambient state. Inputs are hashed, outputs are deterministic."
            , featureCard "parallel" "Distributed execution"
                "Remote build cluster with capability-based scheduling. Work-stealing, speculative execution, automatic retries."
            , featureCard "universal" "Language-agnostic"
                "First-class support for Rust, Go, Haskell, PureScript, TypeScript, C++, Python. Unified dependency graph."
            , featureCard "checkmark" "Reproducibility guarantees"
                "Bit-for-bit identical outputs. Cryptographic attestation chain from source to artifact."
            ]
        ]
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
                [ HH.text "Build systems, compared" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others give you configuration languages that can loop forever. We give you proofs." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-green-400 font-bold" ] ] [ HH.text "sensenet//build" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Bazel" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Buck2" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Nix" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Config language" "Dhall (typed)" "Starlark" "Starlark" "Nix expr"
                    , comparisonRow "Termination" "guaranteed" "no" "no" "no"
                    , comparisonRow "Formal proofs" "Lean4" "no" "no" "no"
                    , comparisonRow "Hermeticity" "enforced" "partial" "partial" "enforced"
                    , comparisonRow "Remote execution" "native" "yes" "yes" "hydra"
                    , comparisonRow "Reproducibility" "bit-exact" "best-effort" "best-effort" "bit-exact"
                    ]
                ]
            ]
        ]
    ]

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
            [ codeLine "# " "Install sensenet//build"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-build"
            , HH.text "\n"
            , codeLine "# " "Initialize project"
            , codeLine "$ " "sensenet init"
            , HH.text "\n"
            , codeLine "# " "Build with verification"
            , codeLine "$ " "sensenet build //myapp --verify"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/build/docs/quickstart"
                , cls [ "text-green-400 hover:text-green-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide ->" ]
            ]
        ]
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
            [ HH.text "Ready for builds you can trust?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start free. No credit card required. Unlimited local builds." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/build/pricing" "Get started free"
            , secondaryButton "/sensenet/build/features" "See all features"
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
    , cls [ "inline-flex items-center justify-center px-8 py-4 bg-green-400 text-background font-medium rounded-md hover:bg-green-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-green-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-green-400 mb-4 font-mono" ] ]
        [ HH.text $ iconSymbol icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

iconSymbol :: String -> String
iconSymbol = case _ of
  "lambda" -> "λ"
  "proof" -> "∀"
  "lock" -> "□"
  "parallel" -> "⇉"
  "universal" -> "*"
  "checkmark" -> "="
  _ -> ">"

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us bazel buck2 nix =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-green-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell bazel ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell buck2 ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell nix ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ if value == "no" then "text-muted-foreground/50" else "text-muted-foreground" ] ]
    [ HH.text value ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
