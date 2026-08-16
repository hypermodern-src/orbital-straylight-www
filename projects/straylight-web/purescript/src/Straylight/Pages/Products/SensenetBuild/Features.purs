-- | sensenet//build Features Page
-- | Complete feature showcase for the typed build system
module Straylight.Pages.Products.SensenetBuild.Features 
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
    , dhallConfig
    , leanProofs
    , hermeticBuilds
    , distributedExec
    , languageSupport
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
            [ HH.text "Formally verified"
            , HH.br_
            , HH.text "build infrastructure"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Dhall configurations. Lean4 proofs. Hermetic execution. Everything you need for builds you can mathematically trust." ]
        ]
    ]

-- ============================================================
-- DHALL CONFIGURATION
-- ============================================================

dhallConfig :: forall w i. HH.HTML w i
dhallConfig =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Configuration"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Dhall: configs that can't fail" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Unlike Starlark or Nix expressions, Dhall is a total language. Every expression terminates. No infinite loops, no runtime errors, no surprises. If it typechecks, it works." ]
                , featureList
                    [ "Total functions - guaranteed termination"
                    , "Type inference with full type safety"
                    , "Import resolution with integrity checks"
                    , "Native records, unions, and functions"
                    , "IDE support with hover types"
                    ]
                ]
              -- Right: code example
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ codeBlock
                    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "-- build.dhall" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "let Build = ./prelude.dhall" ]
                    , HH.text "\n\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "in Build.rust.binary {" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  name = \"myapp\"," ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  edition = Build.rust.Edition.E2021," ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  srcs = Build.glob \"src/**/*.rs\"," ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  deps = [" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "    Build.crate \"tokio\" \"1.0\"," ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "    Build.crate \"serde\" \"1.0\"" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  ]" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- LEAN4 PROOFS
-- ============================================================

leanProofs :: forall w i. HH.HTML w i
leanProofs =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1 bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ proofItem "derivation_deterministic" "proven"
                    , proofItem "content_addressing_injective" "proven"
                    , proofItem "build_graph_acyclic" "proven"
                    , proofItem "sandbox_isolation" "proven"
                    , proofItem "output_reproducibility" "proven"
                    ]
                , HH.p
                    [ cls [ "text-sm text-muted-foreground mt-6 text-center" ] ]
                    [ HH.text "47 theorems, 0 sorry" ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Formal Verification"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Proofs, not promises" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "sensenet//build's core semantics are formalized in Lean4. We've proven 47 theorems about derivation behavior, content addressing, and reproducibility. Build correctness is a mathematical property." ]
                , featureList
                    [ "Derivation semantics fully specified"
                    , "Content addressing proven injective"
                    , "Build graph guaranteed acyclic"
                    , "Sandbox isolation verified"
                    , "Reproducibility formally proven"
                    ]
                ]
            ]
        ]
    ]

proofItem :: forall w i. String -> String -> HH.HTML w i
proofItem theorem status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.code [ cls [ "text-sm text-text font-mono" ] ] [ HH.text theorem ]
    , HH.span 
        [ cls [ "text-xs px-2 py-0.5 rounded bg-green-400/20 text-green-400" ] ] 
        [ HH.text status ]
    ]

-- ============================================================
-- HERMETIC BUILDS
-- ============================================================

hermeticBuilds :: forall w i. HH.HTML w i
hermeticBuilds =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Hermeticity"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Complete build isolation" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every build runs in a content-addressed filesystem sandbox. No network access, no ambient state, no system dependencies. Inputs are cryptographically hashed, outputs are deterministic." ]
                , featureList
                    [ "Content-addressed inputs"
                    , "Filesystem sandbox with overlayfs"
                    , "Network isolation by default"
                    , "No access to system packages"
                    , "Bit-for-bit reproducible outputs"
                    , "Post-quantum attestation chains"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "text-center" ] ]
                    [ HH.p [ cls [ "text-sm text-muted-foreground mb-4" ] ] [ HH.text "Build environment" ]
                    , HH.div
                        [ cls [ "grid grid-cols-2 gap-4" ] ]
                        [ isolationBadge "Network" "blocked"
                        , isolationBadge "Filesystem" "sandboxed"
                        , isolationBadge "System" "isolated"
                        , isolationBadge "Time" "fixed"
                        ]
                    ]
                ]
            ]
        ]
    ]

isolationBadge :: forall w i. String -> String -> HH.HTML w i
isolationBadge label status =
  HH.div
    [ cls [ "bg-background border border-border rounded-lg p-3 text-center" ] ]
    [ HH.p [ cls [ "text-xs text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-green-400 font-medium" ] ] [ HH.text status ]
    ]

-- ============================================================
-- DISTRIBUTED EXECUTION
-- ============================================================

distributedExec :: forall w i. HH.HTML w i
distributedExec =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Distributed Builds"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Scale to 10,000 cores" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "sensenet//build includes a distributed execution engine. Offload builds to remote clusters with work-stealing, speculative execution, and automatic retries." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ execCard "Work stealing" "Dynamic load balancing"
            , execCard "Speculative exec" "Parallel redundant builds"
            , execCard "Auto retry" "Transparent failure recovery"
            , execCard "Linear scaling" "10k+ concurrent cores"
            ]
        , HH.div
            [ cls [ "mt-12" ] ]
            [ codeBlock
                [ codeLine "# " "Run distributed build"
                , codeLine "$ " "sensenet build //... --remote"
                , HH.text "\n"
                , codeLine "" "Connecting to cluster..."
                , codeLine "" "Scheduled 247 actions across 64 workers"
                , codeLine "" "Build completed in 23s (was 12m locally)"
                ]
            ]
        ]
    ]

execCard :: forall w i. String -> String -> HH.HTML w i
execCard title desc =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-green-400/50 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text desc ]
    ]

-- ============================================================
-- LANGUAGE SUPPORT
-- ============================================================

languageSupport :: forall w i. HH.HTML w i
languageSupport =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Language Support"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "One build system, every language" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "First-class support for all major languages. Unified dependency graph. No polyglot pain." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4" ] ]
            [ langCard "Rust"
            , langCard "Go"
            , langCard "Haskell"
            , langCard "PureScript"
            , langCard "TypeScript"
            , langCard "C++"
            , langCard "Python"
            ]
        ]
    ]

langCard :: forall w i. String -> HH.HTML w i
langCard name =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center hover:border-green-400/30 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium text-sm" ] ] [ HH.text name ] ]

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
            [ HH.text "Ready for proven builds?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start with unlimited local builds. Scale to distributed clusters when you need them." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/build/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-green-400 text-background font-medium rounded-md hover:bg-green-400/90 transition-colors" ]
                ]
                [ HH.text "Get started free" ]
            , HH.a
                [ HP.href "/sensenet/build/docs"
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
    [ cls [ "inline-block px-3 py-1 bg-green-400/10 border border-green-400/20 rounded-full text-green-400 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-green-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
