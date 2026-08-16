-- | sensenet//build Product Page
-- | Typed Build System with Formal Verification
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetBuild where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetBuildPage :: forall q i o m. H.Component q i o m
sensenetBuildPage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-rose-400/10 border border-rose-400/20 rounded-full text-rose-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-rose-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Build systems that"
            , HH.br_
            , HH.span [ cls [ "text-rose-400" ] ] [ HH.text "prove" ]
            , HH.text " themselves correct"
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Typed Dhall configurations. Lean4-proven derivations. Hermetic reproducibility with cryptographic attestation. Your build graph is a theorem." ]
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
                    , HH.text "curl -fsSL sensenet.straylight.software/build | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#fda4af] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/sensenet-build"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#fda4af] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-rose-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "Bazel, Buck2, Nix expressions"
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
                [ HH.text "Why sensenet//build?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for engineers who demand mathematical certainty from their build infrastructure." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "λ" "Dhall configuration"
                "Total functions, no Turing-completeness, no escape hatches. Your config terminates or it doesn't typecheck. Import resolution with integrity checks."
            , featureCard "∀" "Lean4 proofs"
                "Derivation semantics formalized in Lean4. 47 theorems, 0 sorry. Build correctness is a proven property, not a hope."
            , featureCard "□" "Hermetic builds"
                "Content-addressed filesystem sandbox. No network, no ambient state. Inputs are hashed, outputs are deterministic. Always."
            , featureCard "⇉" "Distributed execution"
                "Remote build cluster with capability-based scheduling. Work-stealing, speculative execution, automatic retries. Linear scaling to 10k cores."
            , featureCard "*" "Language-agnostic"
                "First-class support for Rust, Go, Haskell, PureScript, TypeScript, C++, Python. Unified dependency graph across all languages."
            , featureCard "=" "Reproducibility guarantees"
                "Bit-for-bit identical outputs. Cryptographic attestation chain from source to artifact. Audit any build from any point in history."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-rose-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-rose-400 mb-4 font-mono" ] ]
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
                        , HH.th [ cls [ "py-4 text-center text-rose-400 font-bold" ] ] [ HH.text "sensenet//build" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Bazel" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Buck2" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Pants" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Nix" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Config language" "Dhall (typed)" "Starlark" "Starlark" "Python" "Nix expr"
                    , comparisonRow "Termination" "guaranteed" "no" "no" "no" "no"
                    , comparisonRow "Formal proofs" "47 Lean4" "no" "no" "no" "no"
                    , comparisonRow "Hermeticity" "enforced" "partial" "partial" "partial" "enforced"
                    , comparisonRow "Remote execution" "native" "yes" "yes" "yes" "hydra"
                    , comparisonRow "Incremental" "content-hash" "mtime" "content" "content" "hash"
                    , comparisonRow "Multi-language" "unified DAG" "per-rule" "per-rule" "per-rule" "derivation"
                    , comparisonRow "Attestation" "post-quantum" "no" "no" "no" "no"
                    , comparisonRow "Reproducibility" "bit-exact" "best-effort" "best-effort" "best-effort" "bit-exact"
                    , comparisonRow "Learning curve" "1 day" "weeks" "weeks" "days" "weeks"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on public documentation and real-world usage patterns." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us bazel buck2 pants nix =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-rose-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell bazel ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell buck2 ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell pants ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell nix ]
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
                [ HH.text "Get started in 60 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install via Nix"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-build"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://sensenet.straylight.software/build/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Initialize project"
            , codeLine "$ " "sensenet init"
            , HH.text "\n"
            , codeLine "# " "Define a target in build.dhall"
            , codeLine "" "let Build = https://sensenet.straylight.software/build/prelude.dhall"
            , codeLine "" ""
            , codeLine "" "in Build.rust.binary {"
            , codeLine "" "  name = \"myapp\","
            , codeLine "" "  srcs = Build.glob \"src/**/*.rs\","
            , codeLine "" "  deps = [ Build.crate \"tokio\" \"1.0\" ]"
            , codeLine "" "}"
            , HH.text "\n"
            , codeLine "# " "Build with proof verification"
            , codeLine "$ " "sensenet build //myapp --verify"
            , HH.text "\n"
            , codeLine "# " "Run distributed build"
            , codeLine "$ " "sensenet build //... --remote"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/build/docs"
                , cls [ "text-rose-400 hover:text-rose-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide \x2192" ]
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
            [ HH.text "Ready for builds you can trust?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "sensenet//build is in private beta. Join the waitlist for early access to proven build infrastructure." ]
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-rose-400 text-background font-medium rounded-md hover:bg-rose-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
